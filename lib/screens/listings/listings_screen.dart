import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../controllers/event_controller.dart';
import '../../controllers/listings_controller.dart';
import '../../core/providers/district_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../models/listing_models.dart' hide EventModel;
import '../../models/spot_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ListingsScreen — tabbed hub for all listing categories
// ─────────────────────────────────────────────────────────────────────────────

class ListingsScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const ListingsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ListingCategory.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, _tabs.length - 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.col.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: context.col.bg,
            floating: true,
            snap: true,
            pinned: false,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: _ExploreTitle(),
            actions: [
              IconButton(
                onPressed: () => context.push(AppRoutes.search),
                icon: Icon(
                  Icons.search_rounded,
                  color: context.col.textSecondary,
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelColor: AppColors.primary,
              unselectedLabelColor: context.col.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: _tabs
                  .map(
                    (t) => Tab(
                      child: Row(
                        children: [
                          Icon(t.icon, size: 15),
                          const SizedBox(width: 6),
                          Text(t.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _TouristSpotsTab(),
            _RestaurantsTab(),
            _AccommodationTab(),
            _CafesTab(),
            _AdventureTab(),
            _ShoppingTab(),
            _EventsTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated "Explore <District>" title — tappable district filter
// ─────────────────────────────────────────────────────────────────────────────

class _ExploreTitle extends ConsumerStatefulWidget {
  const _ExploreTitle();

  @override
  ConsumerState<_ExploreTitle> createState() => _ExploreTitleState();
}

class _ExploreTitleState extends ConsumerState<_ExploreTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  String _displayed = 'Mizoram';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.value = 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _animateTo(String newName) async {
    if (newName == _displayed) return;
    await _ctrl.reverse();
    if (mounted) setState(() => _displayed = newName);
    await _ctrl.forward();
  }

  void _showDistrictPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DistrictPickerSheet(
        currentFilter: ref.read(selectedDistrictProvider),
        nearestDistrict: ref.read(districtProvider).district,
        onSelected: (d) {
          ref.read(selectedDistrictProvider.notifier).select(d);
        },
        onClear: () {
          ref.read(selectedDistrictProvider.notifier).clear();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detectedState = ref.watch(districtProvider);
    final activeFilter = ref.watch(selectedDistrictProvider);

    if (!detectedState.loading && detectedState.district != _displayed) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _animateTo(detectedState.district),
      );
    }

    return GestureDetector(
      onTap: _showDistrictPicker,
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _fade,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Explore ',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              activeFilter ?? _displayed,
              style: TextStyle(
                color: activeFilter != null
                    ? AppColors.primary
                    : AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            // Drop-down caret or active-filter indicator
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: activeFilter != null
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                activeFilter != null
                    ? Icons.tune_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: activeFilter != null ? Colors.white : AppColors.primary,
              ),
            ),
            if (detectedState.loading) ...[
              const SizedBox(width: 6),
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// District picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DistrictPickerSheet extends ConsumerWidget {
  final String? currentFilter;
  final String nearestDistrict;
  final ValueChanged<String?> onSelected;
  final VoidCallback onClear;

  const _DistrictPickerSheet({
    required this.currentFilter,
    required this.nearestDistrict,
    required this.onSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 8,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by District',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Showing listings from the selected district',
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (currentFilter != null)
                TextButton.icon(
                  onPressed: () {
                    onClear();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // "All Mizoram" chip
          _DistrictChip(
            label: 'All Mizoram',
            icon: Iconsax.map,
            subtitle: 'Show every district',
            selected: currentFilter == null,
            isNearest: false,
            onTap: () {
              onClear();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),

          Text(
            'DISTRICTS',
            style: TextStyle(
              color: context.col.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),

          // District grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3.0,
            ),
            itemCount: kDistrictNames.length,
            itemBuilder: (context, i) {
              final name = kDistrictNames[i];
              return _DistrictChip(
                label: name,
                subtitle: name == nearestDistrict ? 'Near you' : null,
                selected: currentFilter == name,
                isNearest: name == nearestDistrict,
                onTap: () {
                  onSelected(name);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DistrictChip extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final bool isNearest;
  final VoidCallback onTap;
  final IconData? icon;

  const _DistrictChip({
    required this.label,
    required this.selected,
    required this.isNearest,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : context.col.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : isNearest
                ? AppColors.primary.withValues(alpha: 0.35)
                : context.col.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (selected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              )
            else if (isNearest)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.my_location_rounded,
                  size: 13,
                  color: AppColors.primary,
                ),
              )
            else if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  icon,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : context.col.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: isNearest
                            ? AppColors.primary
                            : context.col.textMuted,
                        fontSize: 10,
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
} // ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _ratingBadge(BuildContext context, double rating) => Container(
  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
  decoration: BoxDecoration(
    color: context.col.surface,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.star_rounded, size: 12, color: AppColors.star),
      SizedBox(width: 3),
      Text(
        rating.toStringAsFixed(1),
        style: TextStyle(
          color: context.col.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
);

Widget _priceBadge(String price) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
  decoration: BoxDecoration(
    color: AppColors.primary.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    price,
    style: const TextStyle(
      color: AppColors.primary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  ),
);

Widget _chip(BuildContext context, String label) => Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: context.col.surfaceElevated,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: context.col.border),
  ),
  child: Text(
    label,
    style: TextStyle(color: context.col.textSecondary, fontSize: 11),
  ),
);

Widget _featureDot(BuildContext context, IconData icon, String label) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(icon, size: 13, color: AppColors.primary),
    SizedBox(width: 4),
    Text(
      label,
      style: TextStyle(color: context.col.textSecondary, fontSize: 11),
    ),
  ],
);

class _HeroImage extends StatelessWidget {
  final String url;

  const _HeroImage({required this.url});

  static const double height = 160;
  static const double borderRadius = 12;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url.isEmpty
          ? Container(
              height: height,
              color: context.col.surfaceElevated,
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: context.col.textMuted,
                  size: 32,
                ),
              ),
            )
          : CachedNetworkImage(
              imageUrl: url,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  Container(height: height, color: context.col.surfaceElevated),
              errorWidget: (_, _, _) => Container(
                height: height,
                color: context.col.surfaceElevated,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: context.col.textMuted,
                  ),
                ),
              ),
            ),
    );
  }
}

/// Generic paginated list wrapper.
class _ListingList<T> extends StatefulWidget {
  final PaginatedState<T> state;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext, T) itemBuilder;
  final String emptyMessage;

  const _ListingList({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    required this.emptyMessage,
  });

  @override
  State<_ListingList<T>> createState() => _ListingListState<T>();
}

class _ListingListState<T> extends State<_ListingList<T>> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (widget.state.error != null && widget.state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: context.col.textMuted,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              widget.state.error!,
              style: TextStyle(color: context.col.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.state.items.isEmpty) {
      return Center(
        child: Text(
          widget.emptyMessage,
          style: TextStyle(color: context.col.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: context.col.surface,
      onRefresh: () async => widget.onRefresh(),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount:
            widget.state.items.length + (widget.state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          if (i >= widget.state.items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          return widget.itemBuilder(context, widget.state.items[i]);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual listing card widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ListingCard extends StatelessWidget {
  final String heroImageUrl;
  final String title;
  final String subtitle;
  final double rating;
  final String? priceRange;
  final List<Widget> chips;
  final List<Widget> featureDots;
  final VoidCallback? onTap;

  const _ListingCard({
    required this.heroImageUrl,
    required this.title,
    required this.subtitle,
    required this.rating,
    this.priceRange,
    this.chips = const [],
    this.featureDots = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.col.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _HeroImage(url: heroImageUrl),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _ratingBadge(context, rating),
                ),
                if (priceRange != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _priceBadge(priceRange!),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: context.col.textMuted,
                      ),
                      SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 4, children: chips),
                  ],
                  if (featureDots.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 16, children: featureDots),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Tourist Spots
// ─────────────────────────────────────────────────────────────────────────────

class _TouristSpotsTab extends ConsumerWidget {
  const _TouristSpotsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(touristSpotsProvider);
    final notifier = ref.read(touristSpotsProvider.notifier);
    final districtFilter = ref.watch(selectedDistrictProvider);
    final items = districtFilter == null
        ? state.items
        : state.items
              .where(
                (s) => s.district.toLowerCase() == districtFilter.toLowerCase(),
              )
              .toList();

    return _ListingList<SpotModel>(
      state: state.copyWith(items: items),
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: districtFilter != null
          ? 'No tourist spots in $districtFilter.'
          : 'No tourist spots found.',
      itemBuilder: (context, spot) => _ListingCard(
        heroImageUrl: spot.heroImage,
        title: spot.name,
        subtitle: spot.locationAddress.isNotEmpty
            ? spot.locationAddress
            : spot.district,
        rating: spot.averageRating,
        chips: [
          if (spot.category.isNotEmpty) _chip(context, spot.category),
          if (spot.district.isNotEmpty) _chip(context, spot.district),
        ],
        featureDots: [
          if (spot.views > 0)
            _featureDot(
              context,
              Icons.visibility_outlined,
              '${spot.views} views',
            ),
        ],
        onTap: () => context.push(AppRoutes.spotDetailPath(spot.id)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Restaurants
// ─────────────────────────────────────────────────────────────────────────────

class _RestaurantsTab extends ConsumerWidget {
  const _RestaurantsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restaurantsProvider);
    final notifier = ref.read(restaurantsProvider.notifier);
    final districtFilter = ref.watch(selectedDistrictProvider);
    final items = districtFilter == null
        ? state.items
        : state.items
              .where(
                (r) => r.district.toLowerCase() == districtFilter.toLowerCase(),
              )
              .toList();

    return _ListingList<RestaurantModel>(
      state: state.copyWith(items: items),
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: districtFilter != null
          ? 'No restaurants in $districtFilter.'
          : 'No restaurants found.',
      itemBuilder: (context, r) => _ListingCard(
        heroImageUrl: r.heroImage,
        title: r.name,
        subtitle: r.location,
        rating: r.rating,
        priceRange: r.priceRange,
        chips: r.cuisineTypes.take(3).map((c) => _chip(context, c)).toList(),
        featureDots: [
          if (r.hasDelivery)
            _featureDot(context, Icons.delivery_dining_rounded, 'Delivery'),
          if (r.hasReservation)
            _featureDot(context, Icons.calendar_today_outlined, 'Reservations'),
          if (r.openingHours.isNotEmpty)
            _featureDot(context, Icons.schedule_outlined, r.openingHours),
        ],
        onTap: () =>
            context.push(AppRoutes.listingDetailPath('restaurants', r.id)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Accommodation (Hotels + Homestays)
// ─────────────────────────────────────────────────────────────────────────────

class _AccommodationTab extends ConsumerStatefulWidget {
  const _AccommodationTab();

  @override
  ConsumerState<_AccommodationTab> createState() => _AccommodationTabState();
}

class _AccommodationTabState extends ConsumerState<_AccommodationTab>
    with SingleTickerProviderStateMixin {
  late TabController _inner;

  @override
  void initState() {
    super.initState();
    _inner = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: context.col.bg,
          child: TabBar(
            controller: _inner,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.col.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(icon: Icon(Iconsax.buildings, size: 16), text: 'Hotels'),
              Tab(icon: Icon(Iconsax.home_2, size: 16), text: 'Homestays'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _inner,
            children: const [
              _HotelsTabContent(),
              _HomestaysTabContent(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Hotels
// ─────────────────────────────────────────────────────────────────────────────

class _HotelsTabContent extends ConsumerWidget {
  const _HotelsTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hotelsProvider);
    final notifier = ref.read(hotelsProvider.notifier);
    final districtFilter = ref.watch(selectedDistrictProvider);
    final items = districtFilter == null
        ? state.items
        : state.items
              .where(
                (h) => h.district.toLowerCase() == districtFilter.toLowerCase(),
              )
              .toList();

    return _ListingList<HotelModel>(
      state: state.copyWith(items: items),
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: districtFilter != null
          ? 'No hotels in $districtFilter.'
          : 'No hotels found.',
      itemBuilder: (context, h) => _ListingCard(
        heroImageUrl: h.heroImage,
        title: h.name,
        subtitle: h.location,
        rating: h.rating,
        priceRange: h.priceRange,
        chips: h.amenities.take(3).map((a) => _chip(context, a)).toList(),
        featureDots: [
          if (h.hasWifi) _featureDot(context, Icons.wifi_rounded, 'Free WiFi'),
          if (h.hasParking)
            _featureDot(context, Icons.local_parking_rounded, 'Parking'),
          if (h.hasRestaurant)
            _featureDot(context, Icons.restaurant_menu_rounded, 'Restaurant'),
          if (h.hasPool) _featureDot(context, Icons.pool_rounded, 'Pool'),
        ],
        onTap: () => context.push(AppRoutes.listingDetailPath('hotels', h.id)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Cafes
// ─────────────────────────────────────────────────────────────────────────────

class _CafesTab extends ConsumerWidget {
  const _CafesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cafesProvider);
    final notifier = ref.read(cafesProvider.notifier);
    final districtFilter = ref.watch(selectedDistrictProvider);
    final items = districtFilter == null
        ? state.items
        : state.items
              .where(
                (c) => c.district.toLowerCase() == districtFilter.toLowerCase(),
              )
              .toList();

    return _ListingList<CafeModel>(
      state: state.copyWith(items: items),
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: districtFilter != null
          ? 'No cafes in $districtFilter.'
          : 'No cafes found.',
      itemBuilder: (context, c) => _ListingCard(
        heroImageUrl: c.heroImage,
        title: c.name,
        subtitle: c.location,
        rating: c.rating,
        priceRange: c.priceRange,
        chips: c.specialties.take(3).map((s) => _chip(context, s)).toList(),
        featureDots: [
          if (c.hasWifi) _featureDot(context, Icons.wifi_rounded, 'Free WiFi'),
          if (c.hasOutdoorSeating)
            _featureDot(context, Icons.deck_rounded, 'Outdoor Seating'),
          if (c.openingHours.isNotEmpty)
            _featureDot(context, Icons.schedule_outlined, c.openingHours),
        ],
        onTap: () => context.push(AppRoutes.listingDetailPath('cafes', c.id)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Homestays
// ─────────────────────────────────────────────────────────────────────────────

class _HomestaysTabContent extends ConsumerWidget {
  const _HomestaysTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homestaysProvider);
    final notifier = ref.read(homestaysProvider.notifier);
    final districtFilter = ref.watch(selectedDistrictProvider);
    final items = districtFilter == null
        ? state.items
        : state.items
              .where(
                (h) => h.district.toLowerCase() == districtFilter.toLowerCase(),
              )
              .toList();

    return _ListingList<HomestayModel>(
      state: state.copyWith(items: items),
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: districtFilter != null
          ? 'No homestays in $districtFilter.'
          : 'No homestays found.',
      itemBuilder: (context, h) => _ListingCard(
        heroImageUrl: h.heroImage,
        title: h.name,
        subtitle: h.location,
        rating: h.rating,
        priceRange: h.priceRange,
        chips: h.amenities.take(3).map((a) => _chip(context, a)).toList(),
        featureDots: [
          _featureDot(context, Icons.person_outline, 'Host: ${h.hostName}'),
          if (h.maxGuests > 0)
            _featureDot(
              context,
              Icons.group_outlined,
              '${h.maxGuests} guests max',
            ),
          if (h.hasBreakfast)
            _featureDot(context, Icons.free_breakfast_outlined, 'Breakfast'),
          if (h.hasFreePickup)
            _featureDot(context, Icons.directions_car_outlined, 'Free Pickup'),
        ],
        onTap: () =>
            context.push(AppRoutes.listingDetailPath('homestays', h.id)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Adventure
// ─────────────────────────────────────────────────────────────────────────────

Color _difficultyColor(BuildContext context, String d) {
  switch (d.toLowerCase()) {
    case 'easy':
      return AppColors.success;
    case 'moderate':
      return AppColors.warning;
    case 'challenging':
      return AppColors.error;
    case 'extreme':
      return AppColors.categoryPurple;
    default:
      return context.col.textSecondary;
  }
}

class _AdventureTab extends ConsumerWidget {
  const _AdventureTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adventureSpotsProvider);
    final notifier = ref.read(adventureSpotsProvider.notifier);
    final districtFilter = ref.watch(selectedDistrictProvider);
    final items = districtFilter == null
        ? state.items
        : state.items
              .where(
                (a) => a.district.toLowerCase() == districtFilter.toLowerCase(),
              )
              .toList();

    return _ListingList<AdventureSpotModel>(
      state: state.copyWith(items: items),
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: districtFilter != null
          ? 'No adventure spots in $districtFilter.'
          : 'No adventure spots found.',
      itemBuilder: (context, a) => _ListingCard(
        heroImageUrl: a.heroImage,
        title: a.name,
        subtitle: a.location,
        rating: a.rating,
        chips: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _difficultyColor(
                context,
                a.difficulty,
              ).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _difficultyColor(
                  context,
                  a.difficulty,
                ).withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '${AdventureSpotModel.difficultyEmoji(a.difficulty)} ${a.difficulty}',
              style: TextStyle(
                color: _difficultyColor(context, a.difficulty),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...a.activities.take(2).map((act) => _chip(context, act)),
        ],
        featureDots: [
          if (a.duration.isNotEmpty)
            _featureDot(context, Icons.timer_outlined, a.duration),
          if (a.bestSeason.isNotEmpty)
            _featureDot(context, Icons.wb_sunny_outlined, a.bestSeason),
          if (a.isPopular)
            _featureDot(context, Icons.trending_up_rounded, 'Popular'),
        ],
        onTap: () =>
            context.push(AppRoutes.listingDetailPath('adventure-spots', a.id)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Shopping
// ─────────────────────────────────────────────────────────────────────────────

class _ShoppingTab extends ConsumerWidget {
  const _ShoppingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shoppingAreasProvider);
    final notifier = ref.read(shoppingAreasProvider.notifier);
    final districtFilter = ref.watch(selectedDistrictProvider);
    final items = districtFilter == null
        ? state.items
        : state.items
              .where(
                (s) => s.district.toLowerCase() == districtFilter.toLowerCase(),
              )
              .toList();

    return _ListingList<ShoppingAreaModel>(
      state: state.copyWith(items: items),
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: districtFilter != null
          ? 'No shopping areas in $districtFilter.'
          : 'No shopping areas found.',
      itemBuilder: (context, s) => _ListingCard(
        heroImageUrl: s.heroImage,
        title: s.name,
        subtitle: s.location,
        rating: s.rating,
        priceRange: s.priceRange,
        chips: [
          _chip(context, s.type.toUpperCase()),
          ...s.products.take(2).map((p) => _chip(context, p)),
        ],
        featureDots: [
          if (s.hasParking)
            _featureDot(context, Icons.local_parking_rounded, 'Parking'),
          if (s.acceptsCards)
            _featureDot(context, Icons.credit_card_outlined, 'Cards accepted'),
          if (s.hasDelivery)
            _featureDot(context, Icons.delivery_dining_rounded, 'Delivery'),
          if (s.openingHours.isNotEmpty)
            _featureDot(context, Icons.schedule_outlined, s.openingHours),
        ],
        onTap: () =>
            context.push(AppRoutes.listingDetailPath('shopping-areas', s.id)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Events
// ─────────────────────────────────────────────────────────────────────────────

Color _eventTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'festival':
      return AppColors.accent;
    case 'cultural':
      return AppColors.secondary;
    case 'adventure':
      return AppColors.success;
    default:
      return AppColors.info;
  }
}

enum _EventViewMode { calendar, grid }

class _EventsTab extends ConsumerStatefulWidget {
  const _EventsTab();

  @override
  ConsumerState<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<_EventsTab> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;
  _EventViewMode _viewMode = _EventViewMode.calendar;
  bool _calendarVisible = true;

  // ── helpers ────────────────────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Set<DateTime> _eventDays(List<EventModel> events) => {
    for (final e in events)
      if (e.date != null) DateTime(e.date!.year, e.date!.month, e.date!.day),
  };

  List<EventModel> _eventsForDay(List<EventModel> events, DateTime day) =>
      events.where((e) => e.date != null && _isSameDay(e.date!, day)).toList();

  void _prevMonth() => setState(
    () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1),
  );

  void _nextMonth() => setState(
    () => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventControllerProvider);
    final notifier = ref.read(eventControllerProvider.notifier);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
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
              state.error!,
              style: TextStyle(color: context.col.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: notifier.refresh,
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    final allEvents = state.items;
    final eventDays = _eventDays(allEvents);
    final displayEvents = _selectedDay != null
        ? _eventsForDay(allEvents, _selectedDay!)
        : allEvents;
    final isGrid = _viewMode == _EventViewMode.grid;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: context.col.surface,
      onRefresh: () async => notifier.refresh(),
      child: CustomScrollView(
        slivers: [
          // ── Calendar (collapsible) ──────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 280),
              sizeCurve: Curves.easeInOut,
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeIn,
              crossFadeState: _calendarVisible
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: _EventCalendar(
                  focusedMonth: _focusedMonth,
                  selectedDay: _selectedDay,
                  eventDays: eventDays,
                  onPrevMonth: _prevMonth,
                  onNextMonth: _nextMonth,
                  onDaySelected: (day) => setState(() {
                    _selectedDay =
                        (_selectedDay != null && _isSameDay(_selectedDay!, day))
                        ? null
                        : day;
                  }),
                ),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ),

          // ── Section header with view toggle ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    _selectedDay != null
                        ? DateFormat('MMMM d').format(_selectedDay!)
                        : 'All Events',
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${displayEvents.length}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_selectedDay != null) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() => _selectedDay = null),
                      child: const Text(
                        'Show all',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // ── Calendar toggle ───────────────────────────────────────
                  GestureDetector(
                    onTap: () =>
                        setState(() => _calendarVisible = !_calendarVisible),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _calendarVisible
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : context.col.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _calendarVisible
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : context.col.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 13,
                            color: _calendarVisible
                                ? AppColors.primary
                                : context.col.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            duration: const Duration(milliseconds: 280),
                            turns: _calendarVisible ? 0 : 0.5,
                            child: Icon(
                              Icons.expand_less_rounded,
                              size: 14,
                              color: _calendarVisible
                                  ? AppColors.primary
                                  : context.col.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ── List / Grid toggle ────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: context.col.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.col.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ViewToggleBtn(
                          icon: Icons.view_list_rounded,
                          active: !isGrid,
                          onTap: () => setState(
                            () => _viewMode = _EventViewMode.calendar,
                          ),
                        ),
                        _ViewToggleBtn(
                          icon: Icons.grid_view_rounded,
                          active: isGrid,
                          onTap: () =>
                              setState(() => _viewMode = _EventViewMode.grid),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Empty state ───────────────────────────────────────────────────
          if (displayEvents.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        _selectedDay != null
                            ? 'No events on this day'
                            : 'No upcoming events found.',
                        style: TextStyle(color: context.col.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          // ── List view ─────────────────────────────────────────────────────
          else if (!isGrid)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverList.separated(
                itemCount: displayEvents.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _EventCard(
                  event: displayEvents[i],
                  onTap: () => context.push(
                    AppRoutes.eventDetailPath(displayEvents[i].id),
                  ),
                ),
              ),
            )
          // ── Grid view (2 columns) ─────────────────────────────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: displayEvents.length,
                itemBuilder: (context, i) => _EventGridCard(
                  event: displayEvents[i],
                  onTap: () => context.push(
                    AppRoutes.eventDetailPath(displayEvents[i].id),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Small icon toggle button used in the view switcher
class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ViewToggleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? Colors.white : context.col.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Event calendar widget
// ─────────────────────────────────────────────────────────────────────────────

class _EventCalendar extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Set<DateTime> eventDays;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDaySelected;

  const _EventCalendar({
    required this.focusedMonth,
    required this.selectedDay,
    required this.eventDays,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDaySelected,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasEvent(int day) {
    final d = DateTime(focusedMonth.year, focusedMonth.month, day);
    return eventDays.contains(d);
  }

  bool _isSelected(int day) {
    if (selectedDay == null) return false;
    return _isSameDay(
      selectedDay!,
      DateTime(focusedMonth.year, focusedMonth.month, day),
    );
  }

  bool _isToday(int day) => _isSameDay(
    DateTime.now(),
    DateTime(focusedMonth.year, focusedMonth.month, day),
  );

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    // weekday: Mon=1 … Sun=7; we want Sun=0 offset
    final startOffset = (firstDay.weekday % 7); // Sun=0, Mon=1, ..., Sat=6

    const weekLabels = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month header
          Row(
            children: [
              IconButton(
                onPressed: onPrevMonth,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: context.col.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(focusedMonth),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNextMonth,
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: context.col.textSecondary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Weekday labels
          Row(
            children: weekLabels
                .map(
                  (w) => Expanded(
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.col.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),

          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox.shrink();
              final day = index - startOffset + 1;
              final selected = _isSelected(day);
              final today = _isToday(day);
              final hasEvent = _hasEvent(day);

              return GestureDetector(
                onTap: () => onDaySelected(
                  DateTime(focusedMonth.year, focusedMonth.month, day),
                ),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : today
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : today
                              ? AppColors.primary
                              : context.col.textPrimary,
                          fontSize: 13,
                          fontWeight: today || selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      if (hasEvent)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.8)
                                : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            },
          ),

          // Legend
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Has events · tap to filter',
                style: TextStyle(color: context.col.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventGridCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const _EventGridCard({required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = _eventTypeColor(event.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.col.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image / coloured header
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: event.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        height: 110,
                        color: typeColor.withValues(alpha: 0.18),
                        child: Center(
                          child: Text(
                            EventModel.typeEmoji(event.type),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        height: 110,
                        color: typeColor.withValues(alpha: 0.18),
                        child: Center(
                          child: Text(
                            EventModel.typeEmoji(event.type),
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 110,
                      color: typeColor.withValues(alpha: 0.18),
                      child: Center(
                        child: Text(
                          EventModel.typeEmoji(event.type),
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
            ),

            // Date strip
            if (event.date != null)
              Container(
                width: double.infinity,
                color: typeColor.withValues(alpha: 0.10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  DateFormat('MMM d · yyyy').format(event.date!),
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        event.type.toUpperCase(),
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Title
                    Text(
                      event.title,
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: context.col.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              color: context.col.textSecondary,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (event.attendees > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 11,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${event.attendees} going',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onTap;

  const _EventCard({required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = _eventTypeColor(event.type);
    final formattedDate = event.date != null
        ? DateFormat('EEE, MMM d · yyyy').format(event.date!)
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.col.border),
        ),
        child: Row(
          children: [
            // Date sidebar
            Container(
              width: 70,
              height: 110,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    EventModel.typeEmoji(event.type),
                    style: const TextStyle(fontSize: 22),
                  ),
                  if (event.date != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM').format(event.date!).toUpperCase(),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      DateFormat('d').format(event.date!),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.type.toUpperCase(),
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      event.title,
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    if (formattedDate.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: context.col.textMuted,
                          ),
                          SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: context.col.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: context.col.textMuted,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              color: context.col.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (event.attendees > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.attendees} attending',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Arrow
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: context.col.textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
