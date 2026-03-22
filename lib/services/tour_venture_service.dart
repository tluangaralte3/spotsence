// lib/services/tour_venture_service.dart
//
// Firestore service for the `adventureSpots` collection.
// Provides streaming, filtering, single-doc fetch, registration, and feedback.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tour_venture_models.dart';

class TourVentureService {
  final FirebaseFirestore _db;

  TourVentureService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('adventureSpots');

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

  // ── Registration (sub-collection) ────────────────────────────────────────

  /// Register a user for a venture.
  /// Returns the new registration document id.
  Future<String> submitRegistration({
    required String ventureId,
    required String userId,
    required String userName,
    required String userPhone,
    required String userEmail,
    required String tierId,
    required String tierName,
    required int numberOfPersons,
    required DateTime preferredDate,
    required String slotId,
    List<String> selectedAddonIds = const [],
    String notes = '',
  }) async {
    final ref = _col.doc(ventureId).collection('registrations').doc();
    final registration = VentureRegistration(
      id: ref.id,
      ventureId: ventureId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      tierId: tierId,
      tierName: tierName,
      selectedAddonIds: selectedAddonIds,
      numberOfPersons: numberOfPersons,
      preferredDate: preferredDate,
      slotId: slotId,
      notes: notes,
    );
    await ref.set(registration.toFirestore());
    // Increment registrations count
    await _col.doc(ventureId).update({
      'registrationsCount': FieldValue.increment(1),
    });
    return ref.id;
  }

  // ── Feedback (sub-collection) ─────────────────────────────────────────────

  /// Submit a post-experience review.
  Future<String> submitFeedback({
    required String ventureId,
    required String userId,
    required String userName,
    String userAvatarUrl = '',
    required double rating,
    String comment = '',
    List<String> tags = const [],
    List<String> photoUrls = const [],
    List<String> completedChallengeIds = const [],
    List<String> earnedMedalIds = const [],
  }) async {
    final ref = _col.doc(ventureId).collection('feedback').doc();
    final feedback = VentureFeedback(
      id: ref.id,
      ventureId: ventureId,
      userId: userId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      rating: rating,
      comment: comment,
      tags: tags,
      photoUrls: photoUrls,
      completedChallengeIds: completedChallengeIds,
      earnedMedalIds: earnedMedalIds,
    );
    await ref.set(feedback.toFirestore());
    // Update average rating
    final snap = await _col.doc(ventureId).get();
    if (snap.exists) {
      final data = snap.data()!;
      final oldCount = (data['ratingsCount'] as num?)?.toInt() ?? 0;
      final oldAvg = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
      final newCount = oldCount + 1;
      final newAvg = ((oldAvg * oldCount) + rating) / newCount;
      await _col.doc(ventureId).update({
        'ratingsCount': newCount,
        'averageRating': double.parse(newAvg.toStringAsFixed(1)),
      });
    }
    return ref.id;
  }

  /// Stream all feedback for a venture.
  Stream<List<VentureFeedback>> watchFeedback(
    String ventureId, {
    int limit = 20,
  }) {
    return _col
        .doc(ventureId)
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => VentureFeedback.fromJson({...d.data(), 'id': d.id}))
              .toList(),
        );
  }

  /// Stream all registrations for a venture (admin use).
  Stream<List<VentureRegistration>> watchRegistrations(String ventureId) {
    return _col
        .doc(ventureId)
        .collection('registrations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) => VentureRegistration.fromJson({...d.data(), 'id': d.id}),
              )
              .toList(),
        );
  }

  /// Stream a user's own registrations across all ventures.
  Stream<List<VentureRegistration>> watchUserRegistrations(String userId) {
    return _db
        .collectionGroup('registrations')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map(
                (d) => VentureRegistration.fromJson({...d.data(), 'id': d.id}),
              )
              .toList(),
        );
  }

  // ── Admin CRUD ────────────────────────────────────────────────────────────

  Future<String> createVenture(Map<String, dynamic> data) async {
    final ref = _col.doc();
    await ref.set({
      ...data,
      'id': ref.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'averageRating': 0.0,
      'ratingsCount': 0,
      'bookingsCount': 0,
      'registrationsCount': 0,
    });
    return ref.id;
  }

  Future<void> updateVenture(String id, Map<String, dynamic> data) async {
    await _col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteVenture(String id) async {
    await _col.doc(id).delete();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  List<TourVentureModel> _mapDocs(QuerySnapshot<Map<String, dynamic>> snap) {
    return snap.docs
        .map((d) => TourVentureModel.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }
}
