import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/spots_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/spot_model.dart';
import '../../widgets/shared_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: context.col.bg,
            expandedHeight: 0,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SpotSence',
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: context.col.textSecondary,
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting ──────────────────────────────────────────
                  if (user != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${user.displayName.split(' ').first} 👋',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Discover Mizoram\'s hidden gems',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        // XP chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt,
                                color: AppColors.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${user.points} XP',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text(
                      'Discover Mizoram',
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Explore waterfalls, mountains, cafes and more",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Quick search bar ──────────────────────────────────
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.search),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: context.col.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.col.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: context.col.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Search spots, restaurants...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: context.col.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Category pills ────────────────────────────────────
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Category horizontal scroll
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: AppConstants.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = AppConstants.categories[i];
                  return GestureDetector(
                    onTap: () =>
                        context.go('${AppRoutes.spots}?category=${cat['id']}'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.col.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.col.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat['emoji']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['label']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.col.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Browse Listings ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🗂️ Browse Listings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.listings),
                    child: const Text(
                      'See all',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: _ListingCategoryGrid()),

          // ── Featured Spots Section ────────────────────────────────────
          const SliverToBoxAdapter(child: _FeaturedSpotsSection()),

          // ── Quick stats (if signed in) ──────────────────────────────────
          if (user != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                child: _StatsRow(user: user),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _ListingCategoryGrid extends StatelessWidget {
  static const _items = [
    (emoji: '🗺️', label: 'Tourist\nSpots', tab: 0),
    (emoji: '🍽️', label: 'Restaurants', tab: 1),
    (emoji: '🏨', label: 'Hotels', tab: 2),
    (emoji: '☕', label: 'Cafes', tab: 3),
    (emoji: '🏡', label: 'Homestays', tab: 4),
    (emoji: '🧗', label: 'Adventure', tab: 5),
    (emoji: '🛍️', label: 'Shopping', tab: 6),
    (emoji: '📅', label: 'Events', tab: 7),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      crossAxisCount: 4,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.9,
      children: _items.map((item) {
        return GestureDetector(
          onTap: () => context.go('${AppRoutes.listings}?tab=${item.tab}'),
          child: Container(
            decoration: BoxDecoration(
              color: context.col.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.col.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final dynamic user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Progress', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
              icon: '⭐',
              label: 'Reviews',
              value: '${user.ratingsCount}',
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: '📍',
              label: 'Contributions',
              value: '${user.contributionsCount}',
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: '🏆',
              label: 'Badges',
              value: '${user.badgesEarned.length}',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.col.border),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: context.col.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: context.col.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Spots Section  (mirrors the web FeaturedSpotsSection component)
// ─────────────────────────────────────────────────────────────────────────────

class _FeaturedSpotsSection extends ConsumerStatefulWidget {
  const _FeaturedSpotsSection();

  @override
  ConsumerState<_FeaturedSpotsSection> createState() =>
      _FeaturedSpotsSectionState();
}

class _FeaturedSpotsSectionState extends ConsumerState<_FeaturedSpotsSection> {
  static const _tabs = [
    (id: 'all', label: 'Popular nearby', emoji: '🗺️'),
    (id: 'Mountains', label: 'Mountains', emoji: '⛰️'),
    (id: 'Waterfalls', label: 'Waterfalls', emoji: '💧'),
    (id: 'Cultural Sites', label: 'Cultural Sites', emoji: '🏛️'),
    (id: 'Viewpoints', label: 'Viewpoints', emoji: '👁️'),
    (id: 'Adventure', label: 'Adventure', emoji: '🧗'),
  ];

  String _selectedCategory = 'all';
  final _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    final sc = _scrollController;
    setState(() {
      _canScrollLeft = sc.offset > 0;
      _canScrollRight = sc.offset < sc.position.maxScrollExtent - 10;
    });
  }

  void _scroll(double delta) {
    _scrollController.animateTo(
      (_scrollController.offset + delta).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(
      featuredSpotsByCategoryStreamProvider(_selectedCategory),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore and unwind at\nMizoram\'s top spots',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: const [
                            TextSpan(text: 'Discover hidden gems. '),
                            TextSpan(
                              text: 'Now with SpotSence.',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go(AppRoutes.spots),
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'View All',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Filter tabs ──────────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final tab = _tabs[i];
                final selected = _selectedCategory == tab.id;
                return GestureDetector(
                  onTap: () {
                    if (_selectedCategory != tab.id) {
                      setState(() {
                        _selectedCategory = tab.id;
                        _canScrollLeft = false;
                        _canScrollRight = true;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : context.col.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : context.col.border,
                      ),
                    ),
                    child: Text(
                      '${tab.emoji}  ${tab.label}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : context.col.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Cards + scroll arrows ────────────────────────────────────────────
          Stack(
            children: [
              // Cards list
              SizedBox(
                height: 330,
                child: spotsAsync.when(
                  loading: () => ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) =>
                        const ShimmerBox(width: 260, height: 330, radius: 20),
                  ),
                  error: (_, __) => const Center(
                    child: EmptyState(
                      emoji: '😕',
                      title: 'Could not load spots',
                    ),
                  ),
                  data: (spots) => spots.isEmpty
                      ? const Center(
                          child: EmptyState(
                            emoji: '🗺️',
                            title: 'No spots found',
                          ),
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (_) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_scrollController.hasClients) {
                                _updateScrollButtons();
                              }
                            });
                            return false;
                          },
                          child: ListView.separated(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: spots.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (ctx, i) => _FeaturedCard(
                              spot: spots[i],
                              onTap: () => ctx.push(
                                AppRoutes.spotDetailPath(spots[i].id),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual rich card matching the web design.
class _FeaturedCard extends StatelessWidget {
  final SpotModel spot;
  final VoidCallback onTap;

  const _FeaturedCard({required this.spot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: 155,
                  width: double.infinity,
                  child: spot.heroImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: spot.heroImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const _CardImagePlaceholder(),
                          errorWidget: (_, __, ___) =>
                              const _CardImagePlaceholder(),
                        )
                      : const _CardImagePlaceholder(),
                ),
                if (spot.featured)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Featured',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Content ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.col.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              spot.locationAddress.isNotEmpty
                                  ? spot.locationAddress
                                  : spot.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.col.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (spot.averageRating > 0) ...[
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              spot.averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.col.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description / placeStory
                  Text(
                    spot.placeStory?.isNotEmpty == true
                        ? spot.placeStory!
                        : 'Explore the beauty of ${spot.name} in Mizoram.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.col.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 10),
                  Divider(height: 1, color: context.col.border),
                  const SizedBox(height: 10),

                  // Category + popularity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        spot.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (spot.popularity > 0)
                        Row(
                          children: [
                            Text(
                              '${spot.popularity}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: context.col.textPrimary,
                              ),
                            ),
                            Text(
                              '/10',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.col.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
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

class _CardImagePlaceholder extends StatelessWidget {
  const _CardImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.col.surfaceElevated,
      child: Center(
        child: Icon(Icons.image_outlined, size: 40, color: context.col.textMuted),
      ),
    );
  }
}
