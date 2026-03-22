// lib/services/admin_service.dart
//
// Super Admin service — Firestore collection: `app_admins`
//
// ⚠️  IMPORTANT — Firebase Custom Claims
// Custom claims (superAdmin: true) CANNOT be set from client-side code.
// They MUST be set via the Firebase Admin SDK, e.g.:
//   • Firebase Cloud Function triggered on account creation
//   • Firebase Admin CLI: `firebase functions:shell` then
//     `admin.auth().setCustomUserClaims(uid, { superAdmin: true })`
// This service ONLY reads claims from the ID token for gate-keeping.
//
// The seeded super admin account:
//   Email   : hillstechadmin@spotsence.com
//   Password: #HillsTech2026#
//   UID is assigned by Firebase Auth at first sign-in.
//   You must call seedSuperAdmin() once after that first sign-in,
//   then manually set the claim via Firebase Console / Admin SDK.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_model.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

// ─────────────────────────────────────────────────────────────────────────────
// AdminService
// ─────────────────────────────────────────────────────────────────────────────

class AdminService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const _admins = 'app_admins';
  static const _users = 'users';
  static const _activity = 'activityLog';

  // Hardcoded super admin seed credentials
  static const seedEmail = 'hillstechadmin@spotsence.com';
  static const seedPassword = '#HillsTech2026#';

  AdminService(this._auth, this._db);

  // ── Custom Claim check ────────────────────────────────────────────────────

  /// Returns true if the current signed-in user holds the `superAdmin` custom
  /// claim.  Forces a token refresh so we always get the latest claims.
  Future<bool> checkSuperAdminClaim() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      final tokenResult = await user.getIdTokenResult(true); // forceRefresh
      return tokenResult.claims?['superAdmin'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── Admin Profile ─────────────────────────────────────────────────────────

  Future<AdminModel?> fetchAdminProfile(String uid) async {
    try {
      final doc = await _db.collection(_admins).doc(uid).get();
      if (!doc.exists) return null;
      return AdminModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  Stream<AdminModel?> watchAdminProfile(String uid) =>
      _db.collection(_admins).doc(uid).snapshots().map((snap) {
        if (!snap.exists) return null;
        return AdminModel.fromFirestore(snap);
      });

  // ── Seed Super Admin ─────────────────────────────────────────────────────

  /// Call this ONCE after the super admin signs in for the first time.
  /// It creates (or refreshes) the `app_admins/{uid}` Firestore document.
  /// You still need to set the custom claim separately via Firebase Admin SDK.
  Future<void> seedSuperAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _db.collection(_admins).doc(user.uid);
    final snap = await ref.get();

    final now = DateTime.now();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': seedEmail,
        'displayName': 'HillsTech Admin',
        'role': AdminRole.superAdmin.name,
        'permissions': const AdminPermissions.all().toJson(),
        'isActive': true,
        'lastLogin': Timestamp.fromDate(now),
        'createdAt': Timestamp.fromDate(now),
        'createdBy': 'system',
      });
    } else {
      // Just update lastLogin
      await ref.update({'lastLogin': Timestamp.fromDate(now)});
    }
  }

  /// Update lastLogin timestamp on every admin sign-in.
  Future<void> recordAdminLogin(String uid) async {
    await _db
        .collection(_admins)
        .doc(uid)
        .update({'lastLogin': Timestamp.fromDate(DateTime.now())})
        .catchError((_) {});
  }

  // ── Activity Log ─────────────────────────────────────────────────────────

  Future<void> logAdminActivity({
    required String action,
    required String targetCollection,
    String? targetId,
    String? detail,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection(_admins).doc(uid).collection(_activity).add({
      'action': action,
      'targetCollection': targetCollection,
      'targetId': targetId,
      'detail': detail,
      'timestamp': Timestamp.fromDate(DateTime.now()),
    });
  }

  Stream<QuerySnapshot> watchRecentActivity(
    String adminUid, {
    int limit = 50,
  }) => _db
      .collection(_admins)
      .doc(adminUid)
      .collection(_activity)
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots();

  // ── Analytics / Aggregate stats ──────────────────────────────────────────

  /// Fetches collection sizes from Firestore count aggregation queries.
  /// Falls back to 0 on error so the dashboard never crashes.
  Future<Map<String, int>> fetchCollectionCounts() async {
    final collections = [
      'users',
      'spots',
      'restaurants',
      'hotels',
      'cafes',
      'homestays',
      'adventureSpots',
      'shoppingAreas',
      'events',
      'tour_packages',
    ];

    final results = <String, int>{};

    for (final col in collections) {
      try {
        final snap = await _db.collection(col).count().get();
        results[col] = snap.count ?? 0;
      } catch (_) {
        results[col] = 0;
      }
    }
    return results;
  }

  Stream<AppAnalyticsSnapshot> watchAnalyticsSnapshot() => _db
      .collection('app_analytics')
      .doc('daily_snapshot')
      .snapshots()
      .map((snap) {
        if (!snap.exists) return const AppAnalyticsSnapshot();
        return AppAnalyticsSnapshot.fromFirestore(snap);
      });

  // ── Users management ─────────────────────────────────────────────────────

  Stream<List<UserModel>> watchAllUsers({int limit = 100}) => _db
      .collection(_users)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final q = query.trim().toLowerCase();
    // Firestore doesn't support full-text; we do a prefix match on displayName
    final snap = await _db
        .collection(_users)
        .orderBy('displayName')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .limit(50)
        .get();
    return snap.docs.map(UserModel.fromFirestore).toList();
  }

  Future<void> setUserActiveStatus(String uid, {required bool isActive}) async {
    await _db.collection(_users).doc(uid).update({'isActive': isActive});
    await logAdminActivity(
      action: isActive ? 'userActivated' : 'userSuspended',
      targetCollection: 'users',
      targetId: uid,
    );
  }

  // ── Generic listing helpers ───────────────────────────────────────────────

  /// Create a new document in any listing collection.
  Future<String> createListing(
    String collection,
    Map<String, dynamic> data,
  ) async {
    data['createdAt'] = Timestamp.fromDate(DateTime.now());
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    data['createdBy'] = _auth.currentUser?.uid ?? 'admin';
    final ref = await _db.collection(collection).add(data);
    await logAdminActivity(
      action: 'listingCreated',
      targetCollection: collection,
      targetId: ref.id,
      detail: data['name']?.toString(),
    );
    return ref.id;
  }

  /// Update an existing document in any listing collection.
  Future<void> updateListing(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    data['updatedAt'] = Timestamp.fromDate(DateTime.now());
    await _db.collection(collection).doc(docId).update(data);
    await logAdminActivity(
      action: 'listingUpdated',
      targetCollection: collection,
      targetId: docId,
      detail: data['name']?.toString(),
    );
  }

  /// Delete a document from any listing collection.
  Future<void> deleteListing(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
    await logAdminActivity(
      action: 'listingDeleted',
      targetCollection: collection,
      targetId: docId,
    );
  }

  /// Fetch all documents from a collection as raw maps.
  Stream<QuerySnapshot> watchCollection(
    String collection, {
    int limit = 200,
    String orderBy = 'createdAt',
    bool descending = true,
  }) => _db
      .collection(collection)
      .orderBy(orderBy, descending: descending)
      .limit(limit)
      .snapshots();

  // ── Specific collection streams (convenience) ─────────────────────────────

  Stream<QuerySnapshot> watchSpots({int limit = 100}) =>
      watchCollection('spots', limit: limit);

  Stream<QuerySnapshot> watchRestaurants({int limit = 100}) =>
      watchCollection('restaurants', limit: limit);

  Stream<QuerySnapshot> watchHotels({int limit = 100}) =>
      watchCollection('accommodations', limit: limit);

  Stream<QuerySnapshot> watchCafes({int limit = 100}) =>
      watchCollection('cafes', limit: limit);

  Stream<QuerySnapshot> watchHomestays({int limit = 100}) =>
      watchCollection('homestays', limit: limit);

  Stream<QuerySnapshot> watchAdventureSpots({int limit = 100}) =>
      watchCollection('adventureSpots', limit: limit);

  Stream<QuerySnapshot> watchShoppingAreas({int limit = 100}) =>
      watchCollection('shoppingAreas', limit: limit);

  Stream<QuerySnapshot> watchEvents({int limit = 100}) =>
      watchCollection('events', limit: limit);

  Stream<QuerySnapshot> watchVentures({int limit = 100}) =>
      watchCollection('ventures', limit: limit);
}
