import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreAdventureService
// Reads from the `adventureSpots` Firestore collection.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreAdventureService {
  final FirebaseFirestore _db;

  FirestoreAdventureService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('adventureSpots');

  // ── List ──────────────────────────────────────────────────────────────────

  /// Fetches up to [limit] adventure spots. Client-side status filter.
  Future<List<AdventureSpotModel>> getAdventureSpots({int limit = 100}) async {
    final snap = await _col.limit(limit * 2).get();
    return snap.docs
        .where((d) {
          final status = d.data()['status']?.toString();
          if (status == null || status.isEmpty) return true;
          return status.toLowerCase() == 'approved' ||
              status.toLowerCase() == 'active';
        })
        .map((d) => AdventureSpotModel.fromFirestore(d))
        .take(limit)
        .toList();
  }

  /// Fetches adventure spots filtered by [difficulty].
  Future<List<AdventureSpotModel>> getByDifficulty({
    required String difficulty,
    int limit = 100,
  }) async {
    final snap = await _col
        .where('difficulty', isEqualTo: difficulty)
        .limit(limit)
        .get();
    return snap.docs.map((d) => AdventureSpotModel.fromFirestore(d)).toList();
  }

  // ── Single document ───────────────────────────────────────────────────────

  Future<AdventureSpotModel?> getAdventureSpotById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return AdventureSpotModel.fromFirestore(doc);
  }

  // ── Stream (live) ─────────────────────────────────────────────────────────

  Stream<List<AdventureSpotModel>> watchAdventureSpots({int limit = 100}) {
    return _col
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AdventureSpotModel.fromFirestore(d))
              .toList(),
        );
  }

  // ── Reviews subcollection ─────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchReviews(
    String spotId, {
    int limit = 30,
  }) {
    return _db
        .collection('adventureSpots')
        .doc(spotId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<void> submitReview({
    required String spotId,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) async {
    await _db
        .collection('adventureSpots')
        .doc(spotId)
        .collection('reviews')
        .doc()
        .set({
          'userId': userId,
          'userName': userName,
          'userAvatar': userAvatar,
          'rating': rating,
          'comment': comment,
          'timestamp': FieldValue.serverTimestamp(),
        });

    try {
      await _db.runTransaction((tx) async {
        final docRef = _db.collection('adventureSpots').doc(spotId);
        final snap = await tx.get(docRef);
        if (!snap.exists) return;
        final data = snap.data() ?? {};
        final oldCount = (data['ratingsCount'] as num?)?.toInt() ?? 0;
        final oldRating =
            ((data['rating'] ?? data['averageRating']) as num?)?.toDouble() ??
            0.0;
        final newCount = oldCount + 1;
        final newRating = ((oldRating * oldCount) + rating) / newCount;
        tx.update(docRef, {
          'rating': double.parse(newRating.toStringAsFixed(1)),
          'ratingsCount': newCount,
        });
      });
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final firestoreAdventureServiceProvider = Provider<FirestoreAdventureService>(
  (_) => FirestoreAdventureService(),
);
