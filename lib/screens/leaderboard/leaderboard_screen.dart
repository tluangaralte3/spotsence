import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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
                  const Icon(Iconsax.star_1, size: 22, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Top Rated',
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
    final shopping = _cat('shopping');
    final events = _cat('event');

    final categories = [
      (
        icon: Iconsax.map_1,
        label: 'Top Spots',
        color: const Color(0xFF4CAF50),
        entries: spots,
      ),
      (
        icon: Iconsax.coffee,
        label: 'Top Cafés',
        color: const Color(0xFF8D6E63),
        entries: cafes,
      ),
      (
        icon: Iconsax.reserve,
        label: 'Top Restaurants',
        color: const Color(0xFFEF5350),
        entries: restaurants,
      ),
      (
        icon: Iconsax.buildings,
        label: 'Top Hotels',
        color: AppColors.secondary,
        entries: hotels,
      ),
      (
        icon: Iconsax.home_2,
        label: 'Top Homestays',
        color: AppColors.warning,
        entries: homestays,
      ),
      (
        icon: Iconsax.bag_2,
        label: 'Top Shopping',
        color: const Color(0xFF9C27B0),
        entries: shopping,
      ),
      (
        icon: Iconsax.calendar,
        label: 'Top Events',
        color: const Color(0xFF2196F3),
        entries: events,
      ),
    ];

    final hasAny = categories.any((c) => c.entries.isNotEmpty);

    return SliverList(
      delegate: SliverChildListDelegate([
        // ── Top-rated carousel (all categories, auto-slide) ─────────────
        if (entries.isNotEmpty)
          _TopRatedCarousel(
            entries: entries,
          ).animate().fadeIn(duration: 400.ms),

        // ── Section header ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              const Icon(Iconsax.award, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Best by Category',
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
                  Icon(Iconsax.document_text_1, size: 40, color: context.col.textMuted),
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
        content: Text('Rebuilding top ratings from Firestore reviews…'),
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
// Top-rated podium carousel — one slide per category, auto-slide every 4 s
// Each slide shows the top-3 podium: gold centre (tallest), silver left,
// bronze right. Empty positions show grey placeholders until data arrives.
// ─────────────────────────────────────────────────────────────────────────────

class _TopRatedCarousel extends StatefulWidget {
  final List<PlaceLeaderboardEntry> entries;
  const _TopRatedCarousel({required this.entries});

  @override
  State<_TopRatedCarousel> createState() => _TopRatedCarouselState();
}

class _TopRatedCarouselState extends State<_TopRatedCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final categoryDefs = [
      (
        key: 'spot',
        label: 'Top Spots',
        icon: Iconsax.map_1,
        color: const Color(0xFF4CAF50),
      ),
      (
        key: 'cafe',
        label: 'Top Cafés',
        icon: Iconsax.coffee,
        color: const Color(0xFF8D6E63),
      ),
      (
        key: 'restaurant',
        label: 'Top Restaurants',
        icon: Iconsax.reserve,
        color: const Color(0xFFEF5350),
      ),
      (
        key: 'hotel',
        label: 'Top Hotels',
        icon: Iconsax.buildings,
        color: AppColors.secondary,
      ),
      (
        key: 'homestay',
        label: 'Top Homestays',
        icon: Iconsax.home_2,
        color: AppColors.warning,
      ),
      (
        key: 'shopping',
        label: 'Top Shopping',
        icon: Iconsax.bag_2,
        color: const Color(0xFF9C27B0),
      ),
      (
        key: 'event',
        label: 'Top Events',
        icon: Iconsax.calendar,
        color: const Color(0xFF2196F3),
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.col.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Podium carousel ───────────────────────────────────────────
          CarouselSlider.builder(
            itemCount: categoryDefs.length,
            options: CarouselOptions(
              height: 320,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayAnimationDuration: const Duration(milliseconds: 700),
              autoPlayCurve: Curves.easeInOut,
              onPageChanged: (i, _) => setState(() => _current = i),
            ),
            itemBuilder: (context, index, _) {
              final def = categoryDefs[index];
              final catEntries = widget.entries
                  .where((e) => e.category == def.key)
                  .take(3)
                  .toList();
              final first = catEntries.isNotEmpty ? catEntries[0] : null;
              final second = catEntries.length > 1 ? catEntries[1] : null;
              final third = catEntries.length > 2 ? catEntries[2] : null;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Column(
                  children: [
                    // ── Category label pill ───────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: def.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: def.color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(def.icon, color: def.color, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            def.label,
                            style: TextStyle(
                              color: def.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ── Podium: silver left | gold centre | bronze right
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // #2 Silver — left
                          _PodiumItem(
                            entry: second,
                            rank: 2,
                            medalColor: second != null
                                ? AppColors.silverMedal
                                : Colors.grey.shade300,
                            medalIcon: Iconsax.medal,
                            platformHeight: 52,
                            avatarSize: 62,
                            accentColor: def.color,
                          ),
                          const SizedBox(width: 6),
                          // #1 Gold — centre, tallest
                          _PodiumItem(
                            entry: first,
                            rank: 1,
                            medalColor: first != null
                                ? AppColors.gold
                                : Colors.grey.shade300,
                            medalIcon: Iconsax.medal_star,
                            platformHeight: 72,
                            avatarSize: 78,
                            accentColor: def.color,
                            isTop: true,
                          ),
                          const SizedBox(width: 6),
                          // #3 Bronze — right
                          _PodiumItem(
                            entry: third,
                            rank: 3,
                            medalColor: third != null
                                ? AppColors.bronzeMedal
                                : Colors.grey.shade300,
                            medalIcon: Iconsax.medal,
                            platformHeight: 38,
                            avatarSize: 62,
                            accentColor: def.color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Dot indicator ─────────────────────────────────────────────
          Container(
            color: context.col.surface,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: AnimatedSmoothIndicator(
              activeIndex: _current,
              count: categoryDefs.length,
              effect: ExpandingDotsEffect(
                dotHeight: 6,
                dotWidth: 6,
                activeDotColor: AppColors.primary,
                dotColor: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual podium item — circle avatar + medal icon + name + rating + platform
// ─────────────────────────────────────────────────────────────────────────────

class _PodiumItem extends StatelessWidget {
  final PlaceLeaderboardEntry? entry;
  final int rank;
  final Color medalColor;
  final IconData medalIcon;
  final double platformHeight;
  final double avatarSize;
  final Color accentColor;
  final bool isTop;

  const _PodiumItem({
    required this.entry,
    required this.rank,
    required this.medalColor,
    required this.medalIcon,
    required this.platformHeight,
    required this.avatarSize,
    required this.accentColor,
    this.isTop = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = entry == null;
    final platformColor = isEmpty
        ? Colors.grey.shade100
        : (rank == 1
            ? AppColors.gold.withValues(alpha: 0.18)
            : rank == 2
                ? AppColors.silverMedal.withValues(alpha: 0.18)
                : AppColors.bronzeMedal.withValues(alpha: 0.18));

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ── Circle avatar ─────────────────────────────────────────────
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isEmpty ? Colors.grey.shade300 : medalColor,
                width: isTop ? 3 : 2,
              ),
              boxShadow: isEmpty
                  ? null
                  : [
                      BoxShadow(
                        color: medalColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ClipOval(
              child: isEmpty
                  ? Container(
                      color: Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: Colors.grey.shade400,
                        size: avatarSize * 0.42,
                      ),
                    )
                  : entry!.heroImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: entry!.heroImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: accentColor.withValues(alpha: 0.15),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_outlined,
                              color: accentColor,
                              size: avatarSize * 0.38,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: accentColor.withValues(alpha: 0.15),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_outlined,
                              color: accentColor,
                              size: avatarSize * 0.38,
                            ),
                          ),
                        )
                      : Container(
                          color: accentColor.withValues(alpha: 0.15),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.place_rounded,
                            color: accentColor,
                            size: avatarSize * 0.42,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 5),
          // ── Medal icon ────────────────────────────────────────────────
          Icon(medalIcon, color: medalColor, size: 18),
          const SizedBox(height: 3),
          // ── Place name ────────────────────────────────────────────────
          Text(
            isEmpty ? '—' : entry!.placeName,
            style: TextStyle(
              color: isEmpty ? context.col.textMuted : context.col.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: isTop ? 12 : 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          // ── Rating or "No ratings" ────────────────────────────────────
          if (!isEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: medalColor, size: 11),
                const SizedBox(width: 2),
                Text(
                  entry!.avgRating.toStringAsFixed(1),
                  style: TextStyle(
                    color: medalColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            )
          else
            Text(
              'No ratings',
              style: TextStyle(color: context.col.textMuted, fontSize: 9),
            ),
          const SizedBox(height: 5),
          // ── Platform base ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            height: platformHeight,
            decoration: BoxDecoration(
              color: platformColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            alignment: Alignment.center,
            child: isEmpty
                ? Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.grey.shade400,
                    size: 18,
                  )
                : Text(
                    '#$rank',
                    style: TextStyle(
                      color: medalColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category card — table/list of top places
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final IconData icon;
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
                  child: Icon(icon, size: 16, color: color),
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
            const medals = [Iconsax.medal_star, Iconsax.medal, Iconsax.medal];
            const medalColors = [
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
  final IconData medal;
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
              child: Icon(medal, color: medalColor, size: 20),
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
            Icon(Iconsax.emoji_sad, size: 52, color: context.col.textMuted),
            const SizedBox(height: 16),
            Text(
              'No ratings yet',
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
