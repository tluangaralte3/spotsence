import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/spots_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/spot_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final featured = ref.watch(featuredSpotsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.bg,
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
                const Text(
                  'SpotSence',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.textSecondary,
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
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Search spots, restaurants...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
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
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
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
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
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

          // ── Featured section ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '✨ Featured',
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

          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: featured.when(
                loading: () => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) =>
                      const ShimmerBox(width: 280, height: 200, radius: 20),
                ),
                error: (_, __) => const EmptyState(
                  emoji: '😕',
                  title: 'Could not load featured spots',
                ),
                data: (spots) => spots.isEmpty
                    ? const EmptyState(
                        emoji: '🗺️',
                        title: 'No featured spots yet',
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: spots.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 0),
                        itemBuilder: (ctx, i) => FeaturedSpotCard(
                          spot: spots[i],
                          onTap: () =>
                              ctx.push(AppRoutes.spotDetailPath(spots[i].id)),
                        ),
                      ),
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
