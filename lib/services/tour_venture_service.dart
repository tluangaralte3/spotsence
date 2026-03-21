// lib/services/tour_package_service.dart
//
// Firestore service for the `tour_packages` collection.
// Provides read-only listing, streaming, filtering, and single-doc fetch.
// Booking enquiry is sent via a sub-collection `bookingRequests`.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tour_venture_models.dart';

class TourVentureService {
  final FirebaseFirestore _db;

  TourVentureService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('tour_packages');

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Stream all active, featured packages (home section).
  Stream<List<TourVentureModel>> watchFeatured({int limit = 6}) {
    return _col
        .where('status', isEqualTo: 'active')
        .where('isFeatured', isEqualTo: true)
        .orderBy('bookingsCount', descending: true)
        .limit(limit)
        .snapshots()
        .map(_mapDocs);
  }

  /// Stream packages filtered by category. Pass null for all active.
  Stream<List<TourVentureModel>> watchByCategory(
    PackageCategory? category, {
    int limit = 20,
  }) {
    Query<Map<String, dynamic>> q = _col.where('status', isEqualTo: 'active');

    if (category != null) {
      q = q.where('category', isEqualTo: category.name);
    }

    return q
        .orderBy('averageRating', descending: true)
        .limit(limit)
        .snapshots()
        .map(_mapDocs);
  }

  /// Stream packages available in a specific season.
  Stream<List<TourVentureModel>> watchBySeason(
    PackageSeason season, {
    int limit = 20,
  }) {
    return _col
        .where('status', isEqualTo: 'active')
        .where('seasons', arrayContainsAny: [season.name, 'allYear'])
        .limit(limit)
        .snapshots()
        .map(_mapDocs);
  }

  // ── Fetch (one-shot) ──────────────────────────────────────────────────────

  /// Fetch a single package by document id.
  Future<TourVentureModel?> fetchById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return TourVentureModel.fromJson({...snap.data()!, 'id': snap.id});
  }

  /// Fetch all active packages for the listings page.
  Future<List<TourVentureModel>> fetchAll({
    PackageCategory? category,
    PackageSeason? season,
    int limit = 40,
  }) async {
    Query<Map<String, dynamic>> q = _col.where('status', isEqualTo: 'active');
    if (category != null) {
      q = q.where('category', isEqualTo: category.name);
    }
    final snap = await q.limit(limit).get();
    return snap.docs
        .map((d) => TourVentureModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  // ── Booking request ───────────────────────────────────────────────────────

  /// Submit a booking enquiry to `tour_packages/{packageId}/bookingRequests`.
  /// Returns the new request document id on success, or throws on error.
  Future<String> submitBookingRequest({
    required String packageId,
    required String userId,
    required String userName,
    required String userPhone,
    required String userEmail,
    required String tierId,
    required String tierName,
    required int numberOfPersons,
    required DateTime preferredDate,
    required String slotId,
    String notes = '',
  }) async {
    final ref = _col.doc(packageId).collection('bookingRequests').doc();
    await ref.set({
      'id': ref.id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'tierId': tierId,
      'tierName': tierName,
      'numberOfPersons': numberOfPersons,
      'preferredDate': Timestamp.fromDate(preferredDate),
      'slotId': slotId,
      'notes': notes,
      'status': 'pending', // pending | confirmed | cancelled
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  List<TourVentureModel> _mapDocs(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map((d) => TourVentureModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }
}
