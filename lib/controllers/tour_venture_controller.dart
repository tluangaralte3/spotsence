// lib/controllers/tour_package_controller.dart
//
// Riverpod providers for tour packages.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tour_venture_models.dart';
import '../services/tour_venture_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ventures collection — data saved by AdminVentureFormScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Stream ventures from the `ventures` Firestore collection.
/// Filters and sorts client-side to avoid a composite Firestore index.
final featuredVenturesProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) {
  return FirebaseFirestore.instance
      .collection('ventures')
      .limit(20)
      .snapshots()
      .map((snap) {
        final docs = snap.docs
            .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
            .where((d) {
              // Include docs where isAvailable is true or the field is absent
              final avail = d['isAvailable'];
              return avail == null || avail == true;
            })
            .toList();
        // Sort by createdAt descending; docs without it go last
        docs.sort((a, b) {
          final aTs = a['createdAt'];
          final bTs = b['createdAt'];
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          if (aTs is Timestamp && bTs is Timestamp) return bTs.compareTo(aTs);
          return 0;
        });
        return docs.take(10).toList();
      });
});

/// Single venture detail from the `ventures` collection.
final ventureByIdProvider =
    StreamProvider.family<Map<String, dynamic>?, String>((ref, id) {
      return FirebaseFirestore.instance
          .collection('ventures')
          .doc(id)
          .snapshots()
          .map((snap) {
            if (!snap.exists || snap.data() == null) return null;
            return <String, dynamic>{...snap.data()!, 'id': snap.id};
          });
    });

// ─────────────────────────────────────────────────────────────────────────────
// Service singleton
// ─────────────────────────────────────────────────────────────────────────────

final tourPackageServiceProvider = Provider<TourVentureService>(
  (_) => TourVentureService(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Featured packages stream (used on HomeScreen)
// ─────────────────────────────────────────────────────────────────────────────

final featuredPackagesStreamProvider = StreamProvider<List<TourVentureModel>>((
  ref,
) {
  return ref.watch(tourPackageServiceProvider).watchFeatured(limit: 6);
});

// ─────────────────────────────────────────────────────────────────────────────
// Packages filtered by category (used on TourPackagesScreen)
// ─────────────────────────────────────────────────────────────────────────────

final packagesByCategoryStreamProvider =
    StreamProvider.family<List<TourVentureModel>, PackageCategory?>(
      (ref, category) =>
          ref.watch(tourPackageServiceProvider).watchByCategory(category),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Packages filtered by season
// ─────────────────────────────────────────────────────────────────────────────

final packagesBySeasonStreamProvider =
    StreamProvider.family<List<TourVentureModel>, PackageSeason>(
      (ref, season) =>
          ref.watch(tourPackageServiceProvider).watchBySeason(season),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Single package detail (used on VentureDetailScreen)
// ─────────────────────────────────────────────────────────────────────────────

final packageDetailProvider = FutureProvider.family<TourVentureModel?, String>((
  ref,
  id,
) async {
  return ref.watch(tourPackageServiceProvider).fetchById(id);
});

// ─────────────────────────────────────────────────────────────────────────────
// Active filter state for TourPackagesScreen
// ─────────────────────────────────────────────────────────────────────────────

class PackageFilterState {
  final PackageCategory? category;
  final PackageSeason? season;
  final DifficultyLevel? difficulty;
  final String searchQuery;

  const PackageFilterState({
    this.category,
    this.season,
    this.difficulty,
    this.searchQuery = '',
  });

  PackageFilterState copyWith({
    PackageCategory? Function()? category,
    PackageSeason? Function()? season,
    DifficultyLevel? Function()? difficulty,
    String? searchQuery,
  }) => PackageFilterState(
    category: category != null ? category() : this.category,
    season: season != null ? season() : this.season,
    difficulty: difficulty != null ? difficulty() : this.difficulty,
    searchQuery: searchQuery ?? this.searchQuery,
  );
}

class PackageFilterNotifier extends Notifier<PackageFilterState> {
  @override
  PackageFilterState build() => const PackageFilterState();

  void setCategory(PackageCategory? c) =>
      state = state.copyWith(category: () => c);

  void setSeason(PackageSeason? s) => state = state.copyWith(season: () => s);

  void setDifficulty(DifficultyLevel? d) =>
      state = state.copyWith(difficulty: () => d);

  void setSearch(String q) => state = state.copyWith(searchQuery: q);

  void clearAll() => state = const PackageFilterState();
}

final packageFilterProvider =
    NotifierProvider<PackageFilterNotifier, PackageFilterState>(
      PackageFilterNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Derived: filtered package list
// ─────────────────────────────────────────────────────────────────────────────

final filteredPackagesProvider = StreamProvider<List<TourVentureModel>>((ref) {
  final filter = ref.watch(packageFilterProvider);

  return ref
      .watch(tourPackageServiceProvider)
      .watchByCategory(filter.category)
      .map((packages) {
        var result = packages;

        // Season filter (client-side refinement)
        if (filter.season != null) {
          result = result
              .where((p) => p.isAvailableInSeason(filter.season!))
              .toList();
        }

        // Difficulty filter (client-side)
        if (filter.difficulty != null) {
          result = result
              .where((p) => p.difficulty == filter.difficulty)
              .toList();
        }

        // Search query (client-side)
        if (filter.searchQuery.isNotEmpty) {
          final q = filter.searchQuery.toLowerCase();
          result = result.where((p) {
            return p.title.toLowerCase().contains(q) ||
                p.tagline.toLowerCase().contains(q) ||
                p.location.toLowerCase().contains(q) ||
                p.tags.any((t) => t.toLowerCase().contains(q));
          }).toList();
        }

        return result;
      });
});
