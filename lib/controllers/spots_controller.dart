import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot_model.dart';
import '../services/spots_service.dart';
import '../services/api_client.dart';

// ── Featured Spots ────────────────────────────────────────────────────────────

final featuredSpotsProvider =
    AsyncNotifierProvider<FeaturedSpotsNotifier, List<SpotModel>>(
      FeaturedSpotsNotifier.new,
    );

class FeaturedSpotsNotifier extends AsyncNotifier<List<SpotModel>> {
  @override
  Future<List<SpotModel>> build() async {
    final result = await ref
        .read(spotsServiceProvider)
        .getFeaturedSpots(limit: 8);
    return result.when(ok: (list) => list, err: (_) => []);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(spotsServiceProvider)
          .getFeaturedSpots(limit: 8)
          .then((r) => r.when(ok: (l) => l, err: (_) => [])),
    );
  }
}

// ── Spots List (paginated) ────────────────────────────────────────────────────

class SpotsState {
  final List<SpotModel> spots;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? selectedCategory;
  final String? error;

  const SpotsState({
    this.spots = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.selectedCategory,
    this.error,
  });

  SpotsState copyWith({
    List<SpotModel>? spots,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? selectedCategory,
    String? error,
  }) => SpotsState(
    spots: spots ?? this.spots,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    page: page ?? this.page,
    selectedCategory: selectedCategory ?? this.selectedCategory,
    error: error,
  );
}

class SpotsController extends Notifier<SpotsState> {
  SpotsService get _service => ref.read(spotsServiceProvider);

  @override
  SpotsState build() {
    Future.microtask(() => loadMore());
    return const SpotsState();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getSpots(
      category: state.selectedCategory,
      page: state.page,
    );

    result.when(
      ok: (newSpots) {
        state = state.copyWith(
          spots: [...state.spots, ...newSpots],
          isLoading: false,
          hasMore: result.meta?.hasMore ?? false,
          page: state.page + 1,
        );
      },
      err: (msg) => state = state.copyWith(isLoading: false, error: msg),
    );
  }

  Future<void> setCategory(String? category) async {
    state = SpotsState(selectedCategory: category);
    await loadMore();
  }

  Future<void> refresh() async {
    state = SpotsState(selectedCategory: state.selectedCategory);
    await loadMore();
  }
}

final spotsControllerProvider = NotifierProvider<SpotsController, SpotsState>(
  SpotsController.new,
);

// ── Spot Detail ───────────────────────────────────────────────────────────────

final spotDetailProvider = FutureProvider.family<SpotModel?, String>((
  ref,
  spotId,
) async {
  final result = await ref.read(spotsServiceProvider).getSpotDetail(spotId);
  return result.when(ok: (spot) => spot, err: (_) => null);
});

// ── Search ────────────────────────────────────────────────────────────────────

class SearchState {
  final String query;
  final List<SpotModel> results;
  final bool isSearching;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<SpotModel>? results,
    bool? isSearching,
    String? error,
  }) => SearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    isSearching: isSearching ?? this.isSearching,
    error: error,
  );
}

class SearchController extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      state = state.copyWith(query: query, results: []);
      return;
    }
    state = state.copyWith(query: query, isSearching: true, error: null);
    final result = await ref.read(spotsServiceProvider).search(query);
    result.when(
      ok: (spots) => state = state.copyWith(results: spots, isSearching: false),
      err: (msg) => state = state.copyWith(isSearching: false, error: msg),
    );
  }

  void clear() => state = const SearchState();
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);

// ── Bookmarks ─────────────────────────────────────────────────────────────────

final bookmarksProvider = FutureProvider.family<List<SpotModel>, String>((
  ref,
  userId,
) async {
  final result = await ref.read(spotsServiceProvider).getBookmarks(userId);
  return result.when(ok: (list) => list, err: (_) => []);
});
