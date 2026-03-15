import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../controllers/listings_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/listing_models.dart';
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
            title: Text(
              'Explore Mizoram',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
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
                          Text(t.emoji, style: const TextStyle(fontSize: 14)),
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
            _HotelsTab(),
            _CafesTab(),
            _HomestaysTab(),
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
  final double height;
  final double borderRadius;

  const _HeroImage({
    required this.url,
    this.height = 160,
    this.borderRadius = 12,
  });

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
              placeholder: (_, __) =>
                  Container(height: height, color: context.col.surfaceElevated),
              errorWidget: (_, __, ___) => Container(
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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
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

    return _ListingList<SpotModel>(
      state: state,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: 'No tourist spots found.',
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

    return _ListingList<RestaurantModel>(
      state: state,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: 'No restaurants found.',
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
// Tab: Hotels
// ─────────────────────────────────────────────────────────────────────────────

class _HotelsTab extends ConsumerWidget {
  const _HotelsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hotelsProvider);
    final notifier = ref.read(hotelsProvider.notifier);

    return _ListingList<HotelModel>(
      state: state,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: 'No hotels found.',
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

    return _ListingList<CafeModel>(
      state: state,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: 'No cafes found.',
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

class _HomestaysTab extends ConsumerWidget {
  const _HomestaysTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homestaysProvider);
    final notifier = ref.read(homestaysProvider.notifier);

    return _ListingList<HomestayModel>(
      state: state,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: 'No homestays found.',
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

    return _ListingList<AdventureSpotModel>(
      state: state,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: 'No adventure spots found.',
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

    return _ListingList<ShoppingAreaModel>(
      state: state,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: 'No shopping areas found.',
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

class _EventsTab extends ConsumerWidget {
  const _EventsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(eventsProvider);
    final notifier = ref.read(eventsProvider.notifier);

    return _ListingList<EventModel>(
      state: state,
      onRefresh: notifier.refresh,
      onLoadMore: notifier.loadMore,
      emptyMessage: 'No upcoming events found.',
      itemBuilder: (context, e) => _EventCard(
        event: e,
        onTap: () => context.push(AppRoutes.listingDetailPath('events', e.id)),
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
