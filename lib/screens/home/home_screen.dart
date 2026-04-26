import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/banner_controller.dart';
import '../../controllers/dare_controller.dart';
import '../../controllers/gamification_controller.dart';
import '../../controllers/spots_controller.dart';
import '../../controllers/tour_venture_controller.dart';
import '../../models/gamification_models.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/banner_model.dart';
import '../../models/spot_model.dart';
import '../../models/tour_venture_models.dart';
import '../../widgets/shared_widgets.dart';
import '../../controllers/rental_controller.dart';
import '../../models/rental_models.dart';
import '../rentals/rentals_screen.dart';
import 'visitor_guide_screen.dart';
import '../../controllers/app_info_board_controller.dart';
import '../../models/app_info_board_model.dart';

/// Tracks which NE state the user has selected from the state picker.
class _NeStateNotifier extends Notifier<String> {
  @override
  String build() => 'Mizoram';
  void select(String stateName) => state = stateName;
}

final selectedNeStateProvider =
    NotifierProvider<_NeStateNotifier, String>(_NeStateNotifier.new);

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
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/xplooria_logo.png',
                  width: 32,
                  height: 32,
                ),
                const SizedBox(width: 8),
                Text(
                  'Xplooria',
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              _NotificationBell(userId: user?.id),
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
                                'Hello, ${user.displayName.split(' ').first},',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () => _showStatePicker(context),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Discover ${ref.watch(selectedNeStateProvider)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // XP chip
                        GestureDetector(
                          onTap: () => _showXpPerksSheet(context, user),
                          child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3),
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

                  // ── Banner Carousel ───────────────────────────────────
                  const _HomeBannerCarousel(),
                  const SizedBox(height: 20),

                ],
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
                  Row(
                    children: [
                      const Icon(
                        Iconsax.category,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Browse Listings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
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

          // ── Visitor Guide Section ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.travel_explore_rounded,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Visitor Guide',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _VisitorGuideCard(
                    stateName: ref.watch(selectedNeStateProvider),
                  ),
                ],
              ),
            ),
          ),

          // ── Featured Spots Section ────────────────────────────────────
          const SliverToBoxAdapter(child: _FeaturedSpotsSection()),

          // ── Tour Packages Section ─────────────────────────────────────
          const SliverToBoxAdapter(child: _TourVentureSection()),

          // ── Equipment Rentals Section ────────────────────────────────
          const SliverToBoxAdapter(child: _EquipmentRentalsSection()),

          // ── AI Travelling Planner (Coming Soon) ───────────────────────
          const SliverToBoxAdapter(child: _AppInfoBoardSection()),

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

// ─────────────────────────────────────────────────────────────────────────────
// Northeast India state picker — opens from subtitle tap
// ─────────────────────────────────────────────────────────────────────────────
// _NotificationBell — badge showing pending dare join requests
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  final String? userId;
  const _NotificationBell({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        userId == null ? 0 : ref.watch(pendingJoinCountProvider(userId!));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            count > 0
                ? Icons.notifications
                : Icons.notifications_outlined,
          ),
          color: count > 0
              ? AppColors.warning
              : context.col.textSecondary,
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 17,
              height: 17,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

typedef _StateItem = ({String name, String abbr, bool available});

const _kNeStates = <_StateItem>[
  (name: 'Mizoram', abbr: 'MZ', available: true),
  (name: 'Manipur', abbr: 'MN', available: false),
  (name: 'Meghalaya', abbr: 'ML', available: false),
  (name: 'Assam', abbr: 'AS', available: false),
  (name: 'Nagaland', abbr: 'NL', available: false),
  (name: 'Tripura', abbr: 'TR', available: false),
  (name: 'Arunachal', abbr: 'AR', available: false),
  (name: 'Sikkim', abbr: 'SK', available: false),
];

void _showStatePicker(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => const _StatePickerSheet(),
  );
}

class _StatePickerSheet extends ConsumerWidget {
  const _StatePickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.col.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore by State',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Northeast India',
                        style: TextStyle(
                          color: context.col.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '8 States',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: context.col.border),
          const SizedBox(height: 8),

          // ── State list ─────────────────────────────────────────────────
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _kNeStates.length,
            itemBuilder: (ctx, i) {
              final s = _kNeStates[i];
              return _StateListTile(
                item: s,
                onTap: s.available
                    ? () {
                        ref
                            .read(selectedNeStateProvider.notifier)
                            .select(s.name);
                        Navigator.pop(context);
                      }
                    : () {
                        // Capture everything BEFORE the pop so we never
                        // access BuildContext after an async gap.
                        final capturedContext = context;
                        Navigator.pop(context);
                        Future.delayed(
                          const Duration(milliseconds: 250),
                          // ignore: use_build_context_synchronously
                          () => _showComingSoon(capturedContext, s.name),
                        );
                      },
              );
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String stateName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.col.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).padding.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🚀', style: TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$stateName — Coming Soon!',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re working hard to bring Xplooria\nto $stateName. Stay tuned!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateListTile extends StatelessWidget {
  final _StateItem item;
  final VoidCallback onTap;
  const _StateListTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = item.available;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Abbr circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : context.col.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.primary : context.col.border,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  item.abbr,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isActive
                        ? AppColors.primary
                        : context.col.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Name + abbr
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: isActive
                          ? AppColors.primary
                          : context.col.textPrimary,
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive ? 'Currently active' : 'Coming soon',
                    style: TextStyle(
                      color: isActive
                          ? AppColors.primary.withValues(alpha: 0.7)
                          : context.col.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Right badge
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: context.col.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}

class _ListingCategoryGrid extends StatelessWidget {
  static const _items = [
    (icon: Iconsax.map_1, label: 'Tourist\nSpots', tab: 0),
    (icon: Iconsax.cup, label: 'Restaurants', tab: 1),
    (icon: Iconsax.buildings, label: 'Stay', tab: 2),
    (icon: Iconsax.coffee, label: 'Cafes', tab: 3),
    (icon: Iconsax.activity, label: 'Adventure', tab: 4),
    (icon: Iconsax.bag_2, label: 'Shopping', tab: 5),
    (icon: Iconsax.calendar, label: 'Events', tab: 6),
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
      children: [
        ..._items.map((item) {
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
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
        }),
        GestureDetector(
          onTap: () => context.go(AppRoutes.community),
          child: Container(
            decoration: BoxDecoration(
              color: context.col.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.col.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.people,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Community',
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
        ),
      ],
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
              icon: Iconsax.star_1,
              iconColor: const Color(0xFFFBBF24),
              label: 'Reviews',
              value: '${user.ratingsCount}',
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Iconsax.location,
              iconColor: AppColors.primary,
              label: 'Contributions',
              value: '${user.contributionsCount}',
            ),
            const SizedBox(width: 10),
            _StatCard(
              icon: Iconsax.award,
              iconColor: AppColors.secondary,
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
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatCard({
    required this.icon,
    required this.iconColor,
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
            Icon(icon, size: 26, color: iconColor),
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
              style: TextStyle(fontSize: 11, color: context.col.textSecondary),
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
    (id: 'all', label: 'Popular nearby', icon: Iconsax.discover),
    (id: 'Mountains', label: 'Mountains', icon: Iconsax.wind),
    (id: 'Waterfalls', label: 'Waterfalls', icon: Iconsax.drop),
    (id: 'Cultural Sites', label: 'Cultural Sites', icon: Iconsax.building),
    (id: 'Viewpoints', label: 'Viewpoints', icon: Iconsax.eye),
    (id: 'Adventure', label: 'Adventure', icon: Iconsax.activity),
  ];

  String _selectedCategory = 'all';
  final _scrollController = ScrollController();

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
    setState(() {});
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
                        'Explore and unwind at\n${ref.watch(selectedNeStateProvider)}\'s top spots',
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
                              text: 'Now with Xplooria.',
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
                  onPressed: () => context.go(AppRoutes.listings),
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
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final tab = _tabs[i];
                final selected = _selectedCategory == tab.id;
                return GestureDetector(
                  onTap: () {
                    if (_selectedCategory != tab.id) {
                      setState(() {
                        _selectedCategory = tab.id;
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
                        color: selected
                            ? AppColors.primary
                            : context.col.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 13,
                          color: selected
                              ? Colors.white
                              : context.col.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white
                                : context.col.textSecondary,
                          ),
                        ),
                      ],
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
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, _) =>
                        const ShimmerBox(width: 260, height: 330, radius: 20),
                  ),
                  error: (_, _) => const Center(
                    child: EmptyState(
                      icon: Iconsax.warning_2,
                      iconColor: AppColors.error,
                      title: 'Could not load spots',
                    ),
                  ),
                  data: (spots) => spots.isEmpty
                      ? const Center(
                          child: EmptyState(
                            icon: Iconsax.map_1,
                            iconColor: AppColors.primary,
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
                            separatorBuilder: (_, _) =>
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
              color: Colors.black.withValues(alpha: 0.07),
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
                          placeholder: (_, _) => const _CardImagePlaceholder(),
                          errorWidget: (_, _, _) =>
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
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: context.col.textMuted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Venture Section — live Firestore stream from `ventures` collection
// ─────────────────────────────────────────────────────────────────────────────

class _TourVentureSection extends ConsumerWidget {
  const _TourVentureSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venturesAsync = ref.watch(featuredVenturesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Row(
                    children: [
                      const Icon(
                        Iconsax.flash,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Venture',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Exclusive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Adventure & activity packages, only on Xplooria',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.col.textMuted,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.tourPackages),
                child: const Text(
                  'See all',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Card list ─────────────────────────────────────────────────
        venturesAsync.when(
          loading: () => SizedBox(
            height: 320,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, _) => const _VentureCardShimmer(),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.col.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.col.border),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Could not load ventures. Check Firestore index.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.col.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          data: (ventures) {
            if (ventures.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.col.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.col.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.tree,
                        size: 20,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No ventures yet — add some from the admin panel.',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.col.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SizedBox(
              height: 320,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: ventures.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (ctx, i) => _VentureCard(data: ventures[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── Shimmer placeholder ──────────────────────────────────────────────────────

class _VentureCardShimmer extends StatelessWidget {
  const _VentureCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: context.col.surfaceElevated,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 10, width: 70, color: context.col.border),
                const SizedBox(height: 6),
                Container(height: 14, width: 180, color: context.col.border),
                const SizedBox(height: 6),
                Container(height: 11, width: 200, color: context.col.border),
                const SizedBox(height: 4),
                Container(height: 11, width: 160, color: context.col.border),
                const SizedBox(height: 8),
                Container(height: 10, width: 120, color: context.col.border),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(height: 22, width: 60, decoration: BoxDecoration(color: context.col.border, borderRadius: BorderRadius.circular(20))),
                    const SizedBox(width: 6),
                    Container(height: 22, width: 60, decoration: BoxDecoration(color: context.col.border, borderRadius: BorderRadius.circular(20))),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 16, width: 90, color: context.col.border),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live card ────────────────────────────────────────────────────────────────

class _VentureCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _VentureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final String id = data['id'] as String? ?? '';
    final String title = data['title'] as String? ?? 'Untitled';
    final String tagline =
        (data['tagline'] as String? ?? data['description'] as String?) ?? '';
    final String category = data['category'] as String? ?? '';
    final String difficulty = data['difficulty'] as String? ?? '';
    final int days = data['durationDays'] is int
        ? data['durationDays'] as int
        : int.tryParse('${data['durationDays']}') ?? 1;
    final double price = data['startingPrice'] is double
        ? data['startingPrice'] as double
        : (data['startingPrice'] is int
              ? (data['startingPrice'] as int).toDouble()
              : double.tryParse('${data['startingPrice']}') ?? 0.0);

    // Image — prefer first item in `images` list, fall back to `imageUrl`
    final List<dynamic> images = (data['images'] is List)
        ? data['images'] as List<dynamic>
        : [];
    final String? imageUrl = images.isNotEmpty
        ? images.first as String?
        : data['imageUrl'] as String?;

    final cat = PackageCategory.fromString(category);
    final diffColor = _difficultyColor(difficulty);
    final durationLabel = days == 1 ? '1 Day' : '$days Days';

    final String location = data['location'] as String? ?? '';
    final String district = data['district'] as String? ?? '';
    final String locationText = [
      if (location.isNotEmpty) location,
      if (district.isNotEmpty) district,
    ].join(', ');

    return GestureDetector(
      onTap: () {
        if (id.isNotEmpty) context.push(AppRoutes.ventureDetailPath(id));
      },
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.col.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image / Emoji hero ───────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) =>
                                const _EmojiHero(),
                            placeholder: (_, _) =>
                                const _EmojiHero(),
                          )
                        : const _EmojiHero(),
                  ),
                ),
                // Category badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: _Chip(
                    label: cat.label,
                    bg: AppColors.primary,
                    fg: Colors.black,
                  ),
                ),
                // Duration badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: _Chip(
                    label: durationLabel,
                    bg: Colors.black54,
                    fg: Colors.white,
                  ),
                ),
              ],
            ),

            // ── Content ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category label text
                  if (cat.label.isNotEmpty)
                    Text(
                      cat.label.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  if (cat.label.isNotEmpty) const SizedBox(height: 4),

                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.col.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),

                  // Description / tagline
                  if (tagline.isNotEmpty)
                    Text(
                      tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: context.col.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  if (tagline.isNotEmpty) const SizedBox(height: 6),

                  // Location row
                  if (locationText.isNotEmpty) ...
                    [
                      Row(
                        children: [
                          Icon(
                            Iconsax.location,
                            size: 11,
                            color: context.col.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              locationText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.col.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                  // Labels: difficulty + duration
                  Row(
                    children: [
                      if (difficulty.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: diffColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            difficulty,
                            style: TextStyle(
                              fontSize: 10,
                              color: diffColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (difficulty.isNotEmpty) const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: context.col.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.col.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.clock,
                              size: 10,
                              color: context.col.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              durationLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: context.col.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Starting from',
                            style: TextStyle(
                              fontSize: 9,
                              color: context.col.textMuted,
                            ),
                          ),
                          Text(
                            price > 0
                                ? '₹${price.toStringAsFixed(0)}'
                                : 'Free',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      if (price > 0)
                        Text(
                          ' /person',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.col.textMuted,
                          ),
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

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return const Color(0xFF22C55E);
      case 'hard':
      case 'extreme':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Equipment Rentals Section — horizontal slider on home screen
// ─────────────────────────────────────────────────────────────────────────────

class _EquipmentRentalsSection extends ConsumerWidget {
  const _EquipmentRentalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentalsAsync = ref.watch(featuredRentalsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Iconsax.box,
                    size: 17,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Equipment Rentals',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Gear up for your adventure',
                        style: TextStyle(
                          color: context.col.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RentalsScreen(),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'See all',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Iconsax.arrow_right_3,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Slider ───────────────────────────────────────────────────────
          rentalsAsync.when(
            loading: () => SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 3,
                itemBuilder: (_, _) => const _RentalCardShimmer(),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (items) {
              final available =
                  items.where((i) => i.isAvailable).toList();
              if (available.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: available.length,
                  itemBuilder: (ctx, i) => _RentalSliderCard(
                    item: available[i],
                    onSeeAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RentalsScreen(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RentalSliderCard extends StatelessWidget {
  final RentalItem item;
  final VoidCallback onSeeAll;

  const _RentalSliderCard({required this.item, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSeeAll,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.col.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ──────────────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 116,
                width: double.infinity,
                child: item.firstImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: item.firstImageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            _RentalImagePlaceholder(),
                      )
                    : _RentalImagePlaceholder(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.category.label,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Iconsax.tag,
                        size: 12,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${item.pricePerDay.toStringAsFixed(0)}/day',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (item.location.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Iconsax.location,
                          size: 11,
                          color: context.col.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.col.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RentalImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary.withValues(alpha: 0.06),
      child: const Center(
        child: Icon(Iconsax.box, size: 32, color: AppColors.secondary),
      ),
    );
  }
}

class _RentalCardShimmer extends StatelessWidget {
  const _RentalCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 116,
            decoration: BoxDecoration(
              color: context.col.surfaceElevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 10,
                  decoration: BoxDecoration(
                    color: context.col.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: context.col.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: context.col.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmojiHero extends StatelessWidget {
  const _EmojiHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(
          Iconsax.discover,
          size: 52,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Chip({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Visitor Guide card — tappable card on home screen
// ─────────────────────────────────────────────────────────────────────────────

class _VisitorGuideCard extends StatelessWidget {
  final String stateName;
  const _VisitorGuideCard({required this.stateName});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisitorGuideScreen(stateName: stateName),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.25),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                color: AppColors.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Visitor Guide',
                        style: TextStyle(
                          color: context.col.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Dos & don\'ts · tips for visiting $stateName',
                    style: TextStyle(
                      color: context.col.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right_rounded,
              color: context.col.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Banner Carousel
// Reads `home_banners` from Firestore via [activeBannersProvider].
// Hidden when sectionVisible == false (admin toggle).
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBannerCarousel extends ConsumerStatefulWidget {
  const _HomeBannerCarousel();

  @override
  ConsumerState<_HomeBannerCarousel> createState() =>
      _HomeBannerCarouselState();
}

class _HomeBannerCarouselState
    extends ConsumerState<_HomeBannerCarousel> {
  int _currentIndex = 0;

  void _handleTap(BuildContext context, BannerModel banner) {
    switch (banner.linkType) {
      case BannerLinkType.internalRoute:
        if (banner.linkValue != null && banner.linkValue!.isNotEmpty) {
          context.go(banner.linkValue!);
        }
      case BannerLinkType.externalUrl:
        if (banner.linkValue != null && banner.linkValue!.isNotEmpty) {
          final uri = Uri.tryParse(banner.linkValue!);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      case BannerLinkType.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(bannerSectionConfigProvider);
    final bannersAsync = ref.watch(activeBannersProvider);

    // Respect admin visibility toggle
    final config = configAsync.asData?.value;
    if (config != null && !config.sectionVisible) {
      return const SizedBox.shrink();
    }

    return bannersAsync.when(
      loading: () => _BannerSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: banners.length,
              options: CarouselOptions(
                height: 160,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                autoPlay: banners.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration:
                    const Duration(milliseconds: 600),
                autoPlayCurve: Curves.easeInOut,
                onPageChanged: (index, _) =>
                    setState(() => _currentIndex = index),
              ),
              itemBuilder: (_, i, _) {
                final banner = banners[i];
                return GestureDetector(
                  onTap: () => _handleTap(context, banner),
                  child: _BannerCard(banner: banner),
                );
              },
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: 10),
              AnimatedSmoothIndicator(
                activeIndex: _currentIndex,
                count: banners.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 6,
                  dotWidth: 6,
                  activeDotColor: AppColors.primary,
                  dotColor: AppColors.primary.withValues(alpha: 0.25),
                  expansionFactor: 3,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    final hasImage = banner.imageUrl.isNotEmpty;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primary,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image ─────────────────────────────────────────
          if (hasImage)
            CachedNetworkImage(
              imageUrl: banner.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),

          // ── Gradient overlay for readability ─────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),

          // ── Text content ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (banner.title.isNotEmpty)
                  Text(
                    banner.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                if (banner.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
                // Tap hint for linked banners
                if (banner.linkType != BannerLinkType.none) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tap to explore',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// XP Perks Sheet — opens when tapping the XP chip on the home screen
// ─────────────────────────────────────────────────────────────────────────────

void _showXpPerksSheet(BuildContext context, dynamic user) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (_) => _XpPerksSheet(user: user),
  );
}

class _XpPerksSheet extends ConsumerWidget {
  final dynamic user;
  const _XpPerksSheet({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(xpEventsProvider);
    final isDark = context.col.isDark;

    // Level progress
    final currentLevelPts = LevelInfo.levels
        .firstWhere((l) => l.level == user.level,
            orElse: () => LevelInfo.levels.first)
        .minPoints;
    final nextLevelPts = user.level < 10
        ? LevelInfo.levels[user.level].minPoints
        : user.points;
    final progress = nextLevelPts > currentLevelPts
        ? ((user.points - currentLevelPts) /
                (nextLevelPts - currentLevelPts))
            .clamp(0.0, 1.0)
        : 1.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: context.col.bg,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // ── Drag handle ─────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── XP Balance header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.bolt,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.points} XP',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${user.levelTitle} · Level ${user.level}',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.col.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'LVL',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${user.level}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Level progress bar ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor:
                          context.col.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation(
                          AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${user.points} XP earned',
                        style: TextStyle(
                            fontSize: 11,
                            color: context.col.textSecondary),
                      ),
                      if (user.level < 10)
                        Text(
                          '${user.xpToNextLevel} XP to Level ${user.level + 1}',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.col.textSecondary),
                        )
                      else
                        const Text(
                          'MAX LEVEL 🏆',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.gold),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── MezoPerks Banner ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF12103A)
                      : AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Iconsax.gift,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                'MezoPerks',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Where Loyalty Gets Smart',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Your XP is more than a score — it\'s your\npassport to real-world rewards. Redeem\npoints for exclusive discounts, loyalty\ncoupons & local experiences.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Coming Soon — Stay Tuned!',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.ticket_discount,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${user.points}\nXP',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                        const Text(
                          'ready',
                          style: TextStyle(
                              color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Recent Earnings header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Iconsax.activity,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Earnings',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: context.col.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(height: 1, color: context.col.border),

            // ── Events list ───────────────────────────────────────────────
            Expanded(
              child: eventsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Error: $e')),
                data: (events) {
                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.activity,
                              size: 40,
                              color: context.col.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No earnings yet',
                            style: TextStyle(
                                color: context.col.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start exploring to earn XP!',
                            style: TextStyle(
                                color: context.col.textMuted,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: events.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 2),
                    itemBuilder: (ctx, i) {
                      final e = events[i];
                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(e.action.icon,
                              size: 18,
                              color: AppColors.accent),
                        ),
                        title: Text(e.action.label,
                            style: Theme.of(ctx).textTheme.bodyMedium),
                        trailing: Text(
                          '+${e.xpEarned} XP',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          _fmtDate(e.createdAt),
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(
                height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Travelling Planner & Companion — dynamic, admin-controlled section
// ─────────────────────────────────────────────────────────────────────────────

class _AppInfoBoardSection extends ConsumerWidget {
  const _AppInfoBoardSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionAsync = ref.watch(appInfoBoardSectionProvider);

    return sectionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (section) {
        if (!section.sectionVisible) return const SizedBox.shrink();
        return _AppInfoBoardCard(section: section);
      },
    );
  }
}

class _AppInfoBoardCard extends StatelessWidget {
  final AppInfoBoardModel section;
  const _AppInfoBoardCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final col = context.col;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──────────────────────────────────────────────
          Row(
            children: [
              const Icon(Iconsax.cpu, size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                section.sectionTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Card ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: context.col.surface,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // ── Decorative circle (top-right) ──────────────────────────
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.secondary.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                // ── Decorative circle (bottom-left) ───────────────────────
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.10),
                    ),
                  ),
                ),

                // ── Main content ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + title + optional lock badge
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Iconsax.routing,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: col.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  section.subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Lock badge — shown only when isLocked == true
                          if (section.isLocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: col.surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: col.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 12,
                                    color: col.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Locked',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: col.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Description
                      Text(
                        section.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: col.textSecondary,
                          height: 1.6,
                        ),
                      ),

                      if (section.features.isNotEmpty) ...
                      [
                        const SizedBox(height: 20),

                        // Feature chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: section.features
                              .map((f) => _AiFeatureChip(
                                    icon: f.iconData,
                                    label: f.label,
                                  ))
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // CTA pill
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: col.surfaceElevated,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: col.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rocket_launch_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              section.ctaText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AiFeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: col.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.secondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: col.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
