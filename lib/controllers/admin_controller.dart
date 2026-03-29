// lib/controllers/admin_controller.dart
//
// Riverpod providers and notifiers for the Super Admin feature.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart';
import '../services/admin_service.dart';
import 'auth_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Auth / claim gate
// ─────────────────────────────────────────────────────────────────────────────

/// Whether the current user holds the `superAdmin` custom claim.
/// Forces a token refresh each time it's read.
/// Watches [firebaseAuthStreamProvider] so it automatically re-evaluates
/// after sign-in / sign-out, ensuring the router redirect always has fresh data.
final isSuperAdminProvider = FutureProvider<bool>((ref) async {
  // Re-run whenever the Firebase Auth user changes (sign in / sign out)
  final authUser = await ref.watch(firebaseAuthStreamProvider.future);
  if (authUser == null) return false;
  final service = ref.read(adminServiceProvider);
  return service.checkSuperAdminClaim();
});

// ─────────────────────────────────────────────────────────────────────────────
// Admin Profile
// ─────────────────────────────────────────────────────────────────────────────

final adminProfileProvider = StreamProvider<AdminModel?>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value(null);
  return ref.read(adminServiceProvider).watchAdminProfile(uid);
});

// ─────────────────────────────────────────────────────────────────────────────
// App Stats (dashboard)
// ─────────────────────────────────────────────────────────────────────────────

final collectionCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  return ref.read(adminServiceProvider).fetchCollectionCounts();
});

final analyticsSnapshotProvider = FutureProvider<AppAnalyticsSnapshot>((ref) {
  return ref.read(adminServiceProvider).fetchLiveStats();
});

// ─────────────────────────────────────────────────────────────────────────────
// Users
// ─────────────────────────────────────────────────────────────────────────────

final adminUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.read(adminServiceProvider).watchAllUsers(limit: 200);
});

// ─────────────────────────────────────────────────────────────────────────────
// Listing Collection — autoDispose FutureProviders
// ─────────────────────────────────────────────────────────────────────────────
//
// FutureProvider.autoDispose means:
//   1. One-shot GET (no persistent WebSocket = no per-change read billing)
//   2. Auto-cancelled when no widget is watching (e.g. navigating away)
//   3. Re-fetched only when the tab is re-visited or ref.invalidate() is called

final adminSpotsProvider = FutureProvider.autoDispose<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).fetchCollection('spots'),
);

final adminRestaurantsProvider = FutureProvider.autoDispose<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).fetchCollection('restaurants'),
);

final adminAccommodationsProvider = FutureProvider.autoDispose<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).fetchCollection('accommodations'),
);

final adminCafesProvider = FutureProvider.autoDispose<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).fetchCollection('cafes'),
);

final adminHomestaysProvider = FutureProvider.autoDispose<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).fetchCollection('homestays'),
);

final adminAdventureSpotsProvider = FutureProvider.autoDispose<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).fetchCollection('adventureSpots'),
);

final adminShoppingAreasProvider = FutureProvider.autoDispose<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).fetchCollection('shoppingAreas'),
);

final adminEventsProvider = FutureProvider.autoDispose<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).fetchCollection('events'),
);

final adminVenturesProvider = FutureProvider.autoDispose<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).fetchCollection('ventures'),
);

/// Invalidates the autoDispose FutureProvider for the given Firestore
/// collection name, triggering a fresh GET on next watch.
void invalidateListingProvider(WidgetRef ref, String? collection) {
  switch (collection) {
    case 'spots':
      ref.invalidate(adminSpotsProvider);
    case 'restaurants':
      ref.invalidate(adminRestaurantsProvider);
    case 'accommodations':
      ref.invalidate(adminAccommodationsProvider);
    case 'homestays':
      ref.invalidate(adminHomestaysProvider);
    case 'cafes':
      ref.invalidate(adminCafesProvider);
    case 'adventureSpots':
      ref.invalidate(adminAdventureSpotsProvider);
    case 'shoppingAreas':
      ref.invalidate(adminShoppingAreasProvider);
    case 'events':
      ref.invalidate(adminEventsProvider);
    case 'ventures':
      ref.invalidate(adminVenturesProvider);
    default:
      break;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected listing tab (for AdminListingsScreen)
// ─────────────────────────────────────────────────────────────────────────────

enum ListingTab {
  spots,
  restaurants,
  accommodations,
  cafes,
  adventure,
  shopping,
  events,
  ventures;

  String get label => switch (this) {
    ListingTab.spots => 'Spots',
    ListingTab.restaurants => 'Restaurants',
    ListingTab.accommodations => 'Accommodations',
    ListingTab.cafes => 'Cafes',
    ListingTab.adventure => 'Adventure',
    ListingTab.shopping => 'Shopping',
    ListingTab.events => 'Events',
    ListingTab.ventures => 'Ventures',
  };

  String get collection => switch (this) {
    ListingTab.spots => 'spots',
    ListingTab.restaurants => 'restaurants',
    ListingTab.accommodations => 'accommodations',
    ListingTab.cafes => 'cafes',
    ListingTab.adventure => 'adventureSpots',
    ListingTab.shopping => 'shoppingAreas',
    ListingTab.events => 'events',
    ListingTab.ventures => 'ventures',
  };
}

class _ListingTabNotifier extends Notifier<ListingTab> {
  @override
  ListingTab build() => ListingTab.spots;
  void set(ListingTab tab) => state = tab;
}

final selectedListingTabProvider =
    NotifierProvider<_ListingTabNotifier, ListingTab>(_ListingTabNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Admin Listing CRUD Notifier
// ─────────────────────────────────────────────────────────────────────────────

enum AdminCrudStatus { idle, loading, success, error }

class AdminCrudState {
  final AdminCrudStatus status;
  final String? message;
  /// The Firestore collection affected by the last CRUD operation.
  /// Used to invalidate only the relevant FutureProvider after success.
  final String? affectedCollection;
  const AdminCrudState({
    this.status = AdminCrudStatus.idle,
    this.message,
    this.affectedCollection,
  });
  bool get isLoading => status == AdminCrudStatus.loading;
  bool get isSuccess => status == AdminCrudStatus.success;
  bool get isError => status == AdminCrudStatus.error;
}

class AdminListingNotifier extends Notifier<AdminCrudState> {
  @override
  AdminCrudState build() => const AdminCrudState();

  AdminService get _service => ref.read(adminServiceProvider);

  Future<bool> createListing(
    String collection,
    Map<String, dynamic> data,
  ) async {
    state = const AdminCrudState(status: AdminCrudStatus.loading);
    try {
      await _service.createListing(collection, data);
      state = AdminCrudState(
        status: AdminCrudStatus.success,
        message: 'Listing created!',
        affectedCollection: collection,
      );
      return true;
    } catch (e) {
      state = AdminCrudState(
        status: AdminCrudStatus.error,
        message: e.toString(),
      );
      return false;
    }
  }

  Future<bool> updateListing(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    state = const AdminCrudState(status: AdminCrudStatus.loading);
    try {
      await _service.updateListing(collection, docId, data);
      state = AdminCrudState(
        status: AdminCrudStatus.success,
        message: 'Listing updated!',
        affectedCollection: collection,
      );
      return true;
    } catch (e) {
      state = AdminCrudState(
        status: AdminCrudStatus.error,
        message: e.toString(),
      );
      return false;
    }
  }

  Future<bool> deleteListing(String collection, String docId) async {
    state = const AdminCrudState(status: AdminCrudStatus.loading);
    try {
      await _service.deleteListing(collection, docId);
      state = AdminCrudState(
        status: AdminCrudStatus.success,
        message: 'Listing deleted.',
        affectedCollection: collection,
      );
      return true;
    } catch (e) {
      state = AdminCrudState(
        status: AdminCrudStatus.error,
        message: e.toString(),
      );
      return false;
    }
  }

  void reset() => state = const AdminCrudState();
}

final adminListingNotifierProvider =
    NotifierProvider<AdminListingNotifier, AdminCrudState>(
      AdminListingNotifier.new,
    );

// ─────────────────────────────────────────────────────────────────────────────
// User management notifier
// ─────────────────────────────────────────────────────────────────────────────

class AdminUserNotifier extends Notifier<AdminCrudState> {
  @override
  AdminCrudState build() => const AdminCrudState();

  AdminService get _service => ref.read(adminServiceProvider);

  Future<void> setUserActive(String uid, {required bool isActive}) async {
    state = const AdminCrudState(status: AdminCrudStatus.loading);
    try {
      await _service.setUserActiveStatus(uid, isActive: isActive);
      state = AdminCrudState(
        status: AdminCrudStatus.success,
        message: isActive ? 'User activated.' : 'User suspended.',
      );
    } catch (e) {
      state = AdminCrudState(
        status: AdminCrudStatus.error,
        message: e.toString(),
      );
    }
  }

  void reset() => state = const AdminCrudState();
}

final adminUserNotifierProvider =
    NotifierProvider<AdminUserNotifier, AdminCrudState>(AdminUserNotifier.new);
