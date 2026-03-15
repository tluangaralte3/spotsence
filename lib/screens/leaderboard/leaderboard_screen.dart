import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/community_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firestore_leaderboard_service.dart';
import '../../services/global_reviews_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LeaderboardScreen
// ─────────────────────────────────────────────────────────────────────────────

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(leaderboardStreamProvider);

    return Scaffold(
      backgroundColor: context.col.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: context.col.bg,
            foregroundColor: context.col.textPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    'Leaderboard',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              background: Builder(
                builder: (context) {
                  final isDark = context.col.isDark;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withValues(alpha: 0.15),
                                context.col.bg,
                              ],
                            )
                          : null,
                      color: isDark ? null : context.col.bg,
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          stream.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: _ErrorState(error: err.toString(), ref: ref),
            ),
            data: (entries) => entries.isEmpty
                ? SliverFillRemaining(child: _EmptyState(ref: ref))
                : _LeaderboardBody(entries: entries, ref: ref),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body — splits entries by category and renders ranked cards
// ─────────────────────────────────────────────────────────────────────────────

class _LeaderboardBody extends StatelessWidget {
  final List<PlaceLeaderboardEntry> entries;
  final WidgetRef ref;
  const _LeaderboardBody({required this.entries, required this.ref});

  List<PlaceLeaderboardEntry> _cat(String c) =>
      entries.where((e) => e.category == c).take(3).toList();

  @override
  Widget build(BuildContext context) {
    final spots = _cat('spot');
    final cafes = _cat('cafe');
    final restaurants = _cat('restaurant');
    final hotels = _cat('hotel');
    final homestays = _cat('homestay');

    final categories = [
      (
        icon: '🏔️',
        label: 'Top Spots',
        color: const Color(0xFF4CAF50),
        entries: spots,
      ),
      (
        icon: '☕',
        label: 'Top Cafés',
        color: const Color(0xFF8D6E63),
        entries: cafes,
      ),
      (
        icon: '🍽️',
        label: 'Top Restaurants',
        color: const Color(0xFFEF5350),
        entries: restaurants,
      ),
      (
        icon: '🏨',
        label: 'Top Hotels',
        color: AppColors.secondary,
        entries: hotels,
      ),
      (
        icon: '🏠',
        label: 'Top Homestays',
        color: AppColors.warning,
        entries: homestays,
      ),
    ];

    final hasAny = categories.any((c) => c.entries.isNotEmpty);

    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Top-3 all-category podium ──────────────────────────────────
        if (entries.length >= 3)
          _TopThreePodium(
            top: entries.take(3).toList(),
          ).animate().fadeIn(duration: 400.ms),

        // ── Section header ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              const Text('🏖️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Rankings by Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.col.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              // Rebuild seed button (admin utility)
              GestureDetector(
                onTap: () => _rebuild(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.col.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.col.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 13,
                        color: context.col.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rebuild',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.col.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (!hasAny)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Text('📭', style: const TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'No rating data yet.\nTap Rebuild to seed from Firestore reviews.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.col.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: categories
                  .where((c) => c.entries.isNotEmpty)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: EdgeInsets.only(
                        bottom: e.key < categories.length - 1 ? 10 : 0,
                      ),
                      child:
                          _CategoryCard(
                                icon: e.value.icon,
                                label: e.value.label,
                                color: e.value.color,
                                entries: e.value.entries,
                              )
                              .animate(
                                delay: Duration(milliseconds: e.key * 80),
                              )
                              .fadeIn()
                              .slideY(begin: 0.06),
                    ),
                  )
                  .toList(),
            ),
          ),

        const SizedBox(height: 100),
      ]),
    );
  }

  Future<void> _rebuild(BuildContext context, WidgetRef ref) async {
    final svc = GlobalReviewsService();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Rebuilding leaderboard from Firestore reviews…'),
        duration: Duration(seconds: 30),
      ),
    );
    try {
      final result = await svc.rebuildLeaderboard();
      ref.invalidate(leaderboardStreamProvider);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ $result'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-3 all-category podium
// ─────────────────────────────────────────────────────────────────────────────

class _TopThreePodium extends StatelessWidget {
  final List<PlaceLeaderboardEntry> top;
  const _TopThreePodium({required this.top});

  Color _catColor(String cat) => switch (cat) {
    'spot' => const Color(0xFF4CAF50),
    'cafe' => const Color(0xFF8D6E63),
    'restaurant' => const Color(0xFFEF5350),
    'hotel' => AppColors.secondary,
    _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final first = top[0];
    final second = top.length > 1 ? top[1] : null;
    final third = top.length > 2 ? top[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        gradient: context.col.isDark
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.10),
                  AppColors.secondary.withValues(alpha: 0.06),
                ],
              )
            : null,
        color: context.col.isDark ? null : context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (second != null)
            _PodiumItem(
              entry: second,
              medal: '🥈',
              medalColor: AppColors.silverMedal,
              catColor: _catColor(second.category),
              height: 100,
            ).animate().slideY(begin: 0.3, delay: 100.ms),
          _PodiumItem(
            entry: first,
            medal: '🥇',
            medalColor: AppColors.gold,
            catColor: _catColor(first.category),
            height: 130,
            large: true,
          ).animate().slideY(begin: 0.3),
          if (third != null)
            _PodiumItem(
              entry: third,
              medal: '🥉',
              medalColor: AppColors.bronzeMedal,
              catColor: _catColor(third.category),
              height: 80,
            ).animate().slideY(begin: 0.3, delay: 200.ms),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final PlaceLeaderboardEntry entry;
  final String medal;
  final Color medalColor;
  final Color catColor;
  final double height;
  final bool large;

  const _PodiumItem({
    required this.entry,
    required this.medal,
    required this.medalColor,
    required this.catColor,
    required this.height,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final imgSize = large ? 68.0 : 54.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(medal, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 6),
        Container(
          width: imgSize,
          height: imgSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: medalColor, width: large ? 3 : 2),
          ),
          child: ClipOval(
            child: entry.heroImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: entry.heroImage,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _Placeholder(color: catColor, size: imgSize),
                  )
                : _Placeholder(color: catColor, size: imgSize),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 80,
          child: Text(
            entry.placeName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.w700,
              color: context.col.textPrimary,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, color: medalColor, size: 12),
              const SizedBox(width: 2),
              Text(
                entry.avgRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: medalColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category card
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final List<PlaceLeaderboardEntry> entries;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
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
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  'Top ${entries.length}',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: context.col.border, height: 1),
          ...entries.asMap().entries.map((e) {
            final rank = e.key + 1;
            final place = e.value;
            final medals = ['🥇', '🥈', '🥉'];
            final medalColors = [
              AppColors.gold,
              AppColors.silverMedal,
              AppColors.bronzeMedal,
            ];
            return _PlaceRow(
                  place: place,
                  rank: rank,
                  medal: medals[e.key],
                  medalColor: medalColors[e.key],
                  accentColor: color,
                  isLast: rank == entries.length,
                )
                .animate(delay: Duration(milliseconds: rank * 60))
                .fadeIn()
                .slideX(begin: 0.04);
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Place row inside a category card
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceRow extends StatelessWidget {
  final PlaceLeaderboardEntry place;
  final int rank;
  final String medal;
  final Color medalColor;
  final Color accentColor;
  final bool isLast;

  const _PlaceRow({
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
            : Border(bottom: BorderSide(color: context.col.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(medal, style: const TextStyle(fontSize: 18)),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: place.heroImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: place.heroImage,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _Placeholder(color: accentColor, size: 48),
                    )
                  : _Placeholder(color: accentColor, size: 48),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.placeName,
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${place.ratingCount} review${place.ratingCount != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: context.col.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
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
                    place.avgRating.toStringAsFixed(1),
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

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder image
// ─────────────────────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  final Color color;
  final double size;
  const _Placeholder({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(Icons.place_rounded, color: color, size: size * 0.42),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty + Error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final WidgetRef ref;
  const _EmptyState({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏜️', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              'Leaderboard is empty',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No review ratings have been synced yet.\nTap below to build from existing Firestore reviews.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.col.textSecondary, height: 1.55),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _rebuild(context, ref),
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Build from Reviews'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rebuild(BuildContext context, WidgetRef ref) async {
    final svc = GlobalReviewsService();
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Syncing from Firestore reviews…'),
        duration: Duration(seconds: 30),
      ),
    );
    try {
      final result = await svc.rebuildLeaderboard();
      ref.invalidate(leaderboardStreamProvider);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ $result'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final WidgetRef ref;
  const _ErrorState({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: context.col.textMuted,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: TextStyle(color: context.col.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.invalidate(leaderboardStreamProvider),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
