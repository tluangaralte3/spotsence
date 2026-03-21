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

final analyticsSnapshotProvider = StreamProvider<AppAnalyticsSnapshot>((ref) {
  return ref.read(adminServiceProvider).watchAnalyticsSnapshot();
});

// ─────────────────────────────────────────────────────────────────────────────
// Users
// ─────────────────────────────────────────────────────────────────────────────

final adminUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.read(adminServiceProvider).watchAllUsers(limit: 200);
});

// ─────────────────────────────────────────────────────────────────────────────
// Listing Collection Streams
// ─────────────────────────────────────────────────────────────────────────────

final adminSpotsProvider = StreamProvider<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).watchSpots(),
);

final adminRestaurantsProvider = StreamProvider<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).watchRestaurants(),
);

final adminHotelsProvider = StreamProvider<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).watchHotels(),
);

final adminCafesProvider = StreamProvider<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).watchCafes(),
);

final adminHomestaysProvider = StreamProvider<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).watchHomestays(),
);

final adminAdventureSpotsProvider = StreamProvider<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).watchAdventureSpots(),
);

final adminShoppingAreasProvider = StreamProvider<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).watchShoppingAreas(),
);

final adminEventsProvider = StreamProvider<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).watchEvents(),
);

final adminVenturesProvider = StreamProvider<QuerySnapshot>(
  (ref) => ref.read(adminServiceProvider).watchVentures(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Selected listing tab (for AdminListingsScreen)
// ─────────────────────────────────────────────────────────────────────────────

enum ListingTab {
  spots,
  restaurants,
  hotels,
  cafes,
  homestays,
  adventure,
  shopping,
  events,
  ventures;

  String get label => switch (this) {
    ListingTab.spots => 'Spots',
    ListingTab.restaurants => 'Restaurants',
    ListingTab.hotels => 'Hotels',
    ListingTab.cafes => 'Cafes',
    ListingTab.homestays => 'Homestays',
    ListingTab.adventure => 'Adventure',
    ListingTab.shopping => 'Shopping',
    ListingTab.events => 'Events',
    ListingTab.ventures => 'Ventures',
  };

  String get collection => switch (this) {
    ListingTab.spots => 'spots',
    ListingTab.restaurants => 'restaurants',
    ListingTab.hotels => 'hotels',
    ListingTab.cafes => 'cafes',
    ListingTab.homestays => 'homestays',
    ListingTab.adventure => 'adventureSpots',
    ListingTab.shopping => 'shoppingAreas',
    ListingTab.events => 'events',
    ListingTab.ventures => 'tour_packages',
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
  const AdminCrudState({this.status = AdminCrudStatus.idle, this.message});
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
      state = const AdminCrudState(
        status: AdminCrudStatus.success,
        message: 'Listing created!',
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
      state = const AdminCrudState(
        status: AdminCrudStatus.success,
        message: 'Listing updated!',
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
      state = const AdminCrudState(
        status: AdminCrudStatus.success,
        message: 'Listing deleted.',
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
