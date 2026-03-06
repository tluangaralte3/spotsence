import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_models.dart';
import '../models/spot_model.dart';
import '../services/firestore_restaurants_service.dart';
import '../services/firestore_spots_service.dart';
import '../services/listings_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Generic paginated state
// ─────────────────────────────────────────────────────────────────────────────

class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) => PaginatedState<T>(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMore: hasMore ?? this.hasMore,
    error: error,
    currentPage: currentPage ?? this.currentPage,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tourist Spots
// ─────────────────────────────────────────────────────────────────────────────

class TouristSpotsNotifier extends Notifier<PaginatedState<SpotModel>> {
  @override
  PaginatedState<SpotModel> build() {
    Future.microtask(loadFirst);
    return const PaginatedState(isLoading: true);
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final spots = await ref
          .read(firestoreSpotsServiceProvider)
          .getFeaturedSpots(limit: 100);
      state = state.copyWith(
        isLoading: false,
        items: spots,
        currentPage: 1,
        hasMore: false, // Firestore fetches all at once
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {} // No-op: all loaded at once

  Future<void> refresh() => loadFirst();
}

final touristSpotsProvider =
    NotifierProvider<TouristSpotsNotifier, PaginatedState<SpotModel>>(
      TouristSpotsNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Restaurants
// ─────────────────────────────────────────────────────────────────────────────

class RestaurantsNotifier extends Notifier<PaginatedState<RestaurantModel>> {
  @override
  PaginatedState<RestaurantModel> build() {
    Future.microtask(loadFirst);
    return const PaginatedState(isLoading: true);
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final restaurants = await ref
          .read(firestoreRestaurantsServiceProvider)
          .getRestaurants(limit: 100);
      state = state.copyWith(
        isLoading: false,
        items: restaurants,
        currentPage: 1,
        hasMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {} // No-op: all loaded at once

  Future<void> refresh() => loadFirst();
}

final restaurantsProvider =
    NotifierProvider<RestaurantsNotifier, PaginatedState<RestaurantModel>>(
      RestaurantsNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Hotels
// ─────────────────────────────────────────────────────────────────────────────

class HotelsNotifier extends Notifier<PaginatedState<HotelModel>> {
  @override
  PaginatedState<HotelModel> build() {
    Future.microtask(loadFirst);
    return const PaginatedState(isLoading: true);
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(listingsServiceProvider).getHotels(page: 1);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoading: false,
        items: items,
        currentPage: 1,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoading: false, error: e),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    final result = await ref
        .read(listingsServiceProvider)
        .getHotels(page: nextPage);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...items],
        currentPage: nextPage,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoadingMore: false, error: e),
    );
  }

  Future<void> refresh() => loadFirst();
}

final hotelsProvider =
    NotifierProvider<HotelsNotifier, PaginatedState<HotelModel>>(
      HotelsNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Cafes
// ─────────────────────────────────────────────────────────────────────────────

class CafesNotifier extends Notifier<PaginatedState<CafeModel>> {
  @override
  PaginatedState<CafeModel> build() {
    Future.microtask(loadFirst);
    return const PaginatedState(isLoading: true);
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref.read(listingsServiceProvider).getCafes(page: 1);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoading: false,
        items: items,
        currentPage: 1,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoading: false, error: e),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    final result = await ref
        .read(listingsServiceProvider)
        .getCafes(page: nextPage);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...items],
        currentPage: nextPage,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoadingMore: false, error: e),
    );
  }

  Future<void> refresh() => loadFirst();
}

final cafesProvider =
    NotifierProvider<CafesNotifier, PaginatedState<CafeModel>>(
      CafesNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Homestays
// ─────────────────────────────────────────────────────────────────────────────

class HomestaysNotifier extends Notifier<PaginatedState<HomestayModel>> {
  @override
  PaginatedState<HomestayModel> build() {
    Future.microtask(loadFirst);
    return const PaginatedState(isLoading: true);
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref
        .read(listingsServiceProvider)
        .getHomestays(page: 1);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoading: false,
        items: items,
        currentPage: 1,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoading: false, error: e),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    final result = await ref
        .read(listingsServiceProvider)
        .getHomestays(page: nextPage);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...items],
        currentPage: nextPage,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoadingMore: false, error: e),
    );
  }

  Future<void> refresh() => loadFirst();
}

final homestaysProvider =
    NotifierProvider<HomestaysNotifier, PaginatedState<HomestayModel>>(
      HomestaysNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Adventure Spots
// ─────────────────────────────────────────────────────────────────────────────

class AdventureSpotsNotifier
    extends Notifier<PaginatedState<AdventureSpotModel>> {
  @override
  PaginatedState<AdventureSpotModel> build() {
    Future.microtask(loadFirst);
    return const PaginatedState(isLoading: true);
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref
        .read(listingsServiceProvider)
        .getAdventureSpots(page: 1);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoading: false,
        items: items,
        currentPage: 1,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoading: false, error: e),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    final result = await ref
        .read(listingsServiceProvider)
        .getAdventureSpots(page: nextPage);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...items],
        currentPage: nextPage,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoadingMore: false, error: e),
    );
  }

  Future<void> refresh() => loadFirst();
}

final adventureSpotsProvider =
    NotifierProvider<
      AdventureSpotsNotifier,
      PaginatedState<AdventureSpotModel>
    >(AdventureSpotsNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Shopping Areas
// ─────────────────────────────────────────────────────────────────────────────

class ShoppingAreasNotifier
    extends Notifier<PaginatedState<ShoppingAreaModel>> {
  @override
  PaginatedState<ShoppingAreaModel> build() {
    Future.microtask(loadFirst);
    return const PaginatedState(isLoading: true);
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref
        .read(listingsServiceProvider)
        .getShoppingAreas(page: 1);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoading: false,
        items: items,
        currentPage: 1,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoading: false, error: e),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    final result = await ref
        .read(listingsServiceProvider)
        .getShoppingAreas(page: nextPage);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...items],
        currentPage: nextPage,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoadingMore: false, error: e),
    );
  }

  Future<void> refresh() => loadFirst();
}

final shoppingAreasProvider =
    NotifierProvider<ShoppingAreasNotifier, PaginatedState<ShoppingAreaModel>>(
      ShoppingAreasNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Events
// ─────────────────────────────────────────────────────────────────────────────

class EventsNotifier extends Notifier<PaginatedState<EventModel>> {
  @override
  PaginatedState<EventModel> build() {
    Future.microtask(loadFirst);
    return const PaginatedState(isLoading: true);
  }

  Future<void> loadFirst() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await ref
        .read(listingsServiceProvider)
        .getEvents(page: 1, upcomingOnly: true);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoading: false,
        items: items,
        currentPage: 1,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoading: false, error: e),
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    final result = await ref
        .read(listingsServiceProvider)
        .getEvents(page: nextPage, upcomingOnly: true);
    result.when(
      ok: (items) => state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...items],
        currentPage: nextPage,
        hasMore: items.length >= 20,
      ),
      err: (e) => state = state.copyWith(isLoadingMore: false, error: e),
    );
  }

  Future<void> refresh() => loadFirst();
}

final eventsProvider =
    NotifierProvider<EventsNotifier, PaginatedState<EventModel>>(
      EventsNotifier.new,
    );
