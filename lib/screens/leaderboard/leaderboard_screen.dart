import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/gamification_models.dart';
import '../../widgets/gamification_widgets.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    'Leaderboard',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1025), AppColors.bg],
                  ),
                ),
              ),
            ),
          ),

          leaderboardAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      err.toString(),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(leaderboardProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (entries) =>
                _LeaderboardContent(entries: entries, currentUser: currentUser),
          ),
        ],
      ),
    );
  }
}

// ─── Leaderboard Content (data slice) ────────────────────────────────────────

class _LeaderboardContent extends ConsumerWidget {
  final List<LeaderboardEntry> entries;
  final dynamic currentUser; // UserModel?

  const _LeaderboardContent({required this.entries, this.currentUser});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingsAsync = ref.watch(placeRankingsProvider);

    if (entries.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'No leaderboard data yet 🏜️',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // Podium — top 3
        if (entries.length >= 3)
          _PodiumWidget(
            entries: entries.take(3).toList(),
            currentUserId: currentUser?.id,
          ),

        // Your rank card
        if (currentUser != null)
          _MyRankCard(entries: entries, currentUserId: currentUser!.id),

        // ─── Place Rankings ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              const Text('🏖️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Place Rankings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        rankingsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Could not load rankings: $e',
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
          data: (rankings) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: [
                _PlaceCategoryRanking(
                  icon: '🏔️',
                  label: 'Top Spots',
                  color: const Color(0xFF4CAF50),
                  entries: rankings.spots,
                ),
                const SizedBox(height: 10),
                _PlaceCategoryRanking(
                  icon: '☕',
                  label: 'Top Cafés',
                  color: const Color(0xFF8D6E63),
                  entries: rankings.cafes,
                ),
                const SizedBox(height: 10),
                _PlaceCategoryRanking(
                  icon: '🍽️',
                  label: 'Top Restaurants',
                  color: const Color(0xFFEF5350),
                  entries: rankings.restaurants,
                ),
                const SizedBox(height: 10),
                _PlaceCategoryRanking(
                  icon: '🏨',
                  label: 'Top Hotels',
                  color: AppColors.secondary,
                  entries: rankings.hotels,
                ),
                const SizedBox(height: 10),
                _PlaceCategoryRanking(
                  icon: '🏠',
                  label: 'Top Homestays',
                  color: AppColors.warning,
                  entries: rankings.homestays,
                ),
              ],
            ),
          ),
        ),

        // ─── Explorer Rankings (user list) ────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            children: [
              const Text('👥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Explorer Rankings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          child: Column(
            children: entries
                .asMap()
                .entries
                .map(
                  (e) => _LeaderboardTile(
                    entry: e.value,
                    isMe: e.value.userId == currentUser?.id,
                    index: e.key,
                  ),
                )
                .toList(),
          ),
        ),
      ]),
    );
  }
}

// ─── Place Category Ranking card ─────────────────────────────────────────────

class _PlaceCategoryRanking extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final List<PlaceRankEntry> entries;

  const _PlaceCategoryRanking({
    required this.icon,
    required this.label,
    required this.color,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'Top 3',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          // Entries
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No ratings yet',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            )
          else
            ...entries.asMap().entries.map((e) {
              final rank = e.key + 1;
              final place = e.value;
              final medalColor = switch (rank) {
                1 => AppColors.gold,
                2 => const Color(0xFFC0C0C0),
                _ => const Color(0xFFCD7F32),
              };
              final medal = switch (rank) {
                1 => '🥇',
                2 => '🥈',
                _ => '🥉',
              };
              return _PlaceRankTile(
                    place: place,
                    rank: rank,
                    medal: medal,
                    medalColor: medalColor,
                    accentColor: color,
                    isLast: rank == entries.length,
                  )
                  .animate(delay: Duration(milliseconds: rank * 60))
                  .fadeIn()
                  .slideX(begin: 0.05);
            }),
        ],
      ),
    );
  }
}

class _PlaceRankTile extends StatelessWidget {
  final PlaceRankEntry place;
  final int rank;
  final String medal;
  final Color medalColor;
  final Color accentColor;
  final bool isLast;

  const _PlaceRankTile({
    required this.place,
    required this.rank,
    required this.medal,
    required this.medalColor,
    required this.accentColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Medal
            SizedBox(
              width: 28,
              child: Text(medal, style: const TextStyle(fontSize: 18)),
            ),
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: place.heroImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: place.heroImage,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _PlaceholderThumb(color: accentColor),
                    )
                  : _PlaceholderThumb(color: accentColor),
            ),
            const SizedBox(width: 12),
            // Name + review count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (place.ratingsCount > 0)
                    Text(
                      '${place.ratingsCount} review${place.ratingsCount != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            // Star rating
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: medalColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, color: medalColor, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    place.rating.toStringAsFixed(1),
                    style: TextStyle(
                      color: medalColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  final Color color;
  const _PlaceholderThumb({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: color.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Icon(Icons.place_rounded, color: color, size: 22),
    );
  }
}

// ─── Podium ─────────────────────────────────────────────────────────────────

class _PodiumWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? currentUserId;

  const _PodiumWidget({required this.entries, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final first = entries[0];
    final second = entries[1];
    final third = entries[2];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _PodiumItem(
            entry: second,
            medal: '🥈',
            medalColor: const Color(0xFFC0C0C0),
            height: 100,
            isMe: second.userId == currentUserId,
          ).animate().slideY(begin: 0.3, delay: 100.ms),
          _PodiumItem(
            entry: first,
            medal: '🥇',
            medalColor: AppColors.gold,
            height: 130,
            isMe: first.userId == currentUserId,
            large: true,
          ).animate().slideY(begin: 0.3),
          _PodiumItem(
            entry: third,
            medal: '🥉',
            medalColor: const Color(0xFFCD7F32),
            height: 80,
            isMe: third.userId == currentUserId,
          ).animate().slideY(begin: 0.3, delay: 200.ms),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final String medal;
  final Color medalColor;
  final double height;
  final bool isMe;
  final bool large;

  const _PodiumItem({
    required this.entry,
    required this.medal,
    required this.medalColor,
    required this.height,
    this.isMe = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = large ? 64.0 : 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal
        Text(medal, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),

        // Avatar
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isMe ? AppColors.primary : medalColor,
              width: large ? 3 : 2,
            ),
          ),
          child: ClipOval(
            child: entry.userPhoto != null
                ? CachedNetworkImage(
                    imageUrl: entry.userPhoto!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _InitialAvatar(name: entry.userName, size: avatarSize),
                  )
                : _InitialAvatar(name: entry.userName, size: avatarSize),
          ),
        ),
        const SizedBox(height: 6),

        // Name
        SizedBox(
          width: 80,
          child: Text(
            entry.userName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: large ? 13 : 11,
              fontWeight: large ? FontWeight.w700 : FontWeight.w600,
              color: isMe ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),

        // Points
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${entry.points} pts',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: medalColor,
            ),
          ),
        ),

        // Level
        const SizedBox(height: 4),
        LevelBadge(level: entry.level, small: !large),
      ],
    );
  }
}

// ─── My Rank ────────────────────────────────────────────────────────────────

class _MyRankCard extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String currentUserId;

  const _MyRankCard({required this.entries, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final myEntry = entries.where((e) => e.userId == currentUserId).firstOrNull;
    if (myEntry == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_pin_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Text(
            'Your Rank',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '#${myEntry.rank}',
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${myEntry.points} pts',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tile ────────────────────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  final int index;

  const _LeaderboardTile({
    required this.entry,
    required this.isMe,
    required this.index,
  });

  Color get _rankColor {
    switch (entry.rank) {
      case 1:
        return AppColors.gold;
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isMe
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              // Rank number
              SizedBox(
                width: 32,
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _rankColor,
                  ),
                ),
              ),

              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surface,
                backgroundImage: entry.userPhoto != null
                    ? CachedNetworkImageProvider(entry.userPhoto!)
                    : null,
                child: entry.userPhoto == null
                    ? Text(
                        entry.userName.isNotEmpty
                            ? entry.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name + level
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.userName + (isMe ? ' (You)' : ''),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isMe ? AppColors.primary : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        LevelBadge(level: entry.level, small: true),
                        if (entry.badgesCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '🏅 ${entry.badgesCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.points}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: entry.rank <= 3
                          ? _rankColor
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'pts',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: index * 40))
        .fadeIn()
        .slideX(begin: 0.08);
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _InitialAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _InitialAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }
}
