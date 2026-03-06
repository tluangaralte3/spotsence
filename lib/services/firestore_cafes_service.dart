import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreCafesService
// Reads from the `cafes` Firestore collection.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreCafesService {
  final FirebaseFirestore _db;

  FirestoreCafesService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('cafes');

  // ── List ──────────────────────────────────────────────────────────────────

  Future<List<CafeModel>> getCafes({int limit = 100}) async {
    final snap = await _col.limit(limit * 2).get();
    return snap.docs
        .where((d) {
          final status = d.data()['status']?.toString();
          if (status == null || status.isEmpty) return true;
          return status.toLowerCase() == 'approved' ||
              status.toLowerCase() == 'active';
        })
        .map((d) => CafeModel.fromFirestore(d))
        .take(limit)
        .toList();
  }

  // ── Single document ───────────────────────────────────────────────────────

  Future<CafeModel?> getCafeById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return CafeModel.fromFirestore(doc);
  }

  // ── Reviews subcollection ─────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchReviews(
    String cafeId, {
    int limit = 30,
  }) {
    return _db
        .collection('cafes')
        .doc(cafeId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<void> submitReview({
    required String cafeId,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) async {
    await _db.collection('cafes').doc(cafeId).collection('reviews').doc().set({
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Best-effort: update running average on the parent doc.
    try {
      await _db.runTransaction((tx) async {
        final docRef = _db.collection('cafes').doc(cafeId);
        final snap = await tx.get(docRef);
        if (!snap.exists) return;
        final data = snap.data() ?? {};
        final oldCount = (data['ratingsCount'] as num?)?.toInt() ?? 0;
        final oldRating =
            (data['rating'] ?? data['averageRating'] as num?)?.toDouble() ??
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
// Riverpod providers
// ─────────────────────────────────────────────────────────────────────────────

final firestoreCafesServiceProvider = Provider<FirestoreCafesService>(
  (_) => FirestoreCafesService(),
);

final cafeDetailProvider = FutureProvider.family<CafeModel?, String>((
  ref,
  id,
) async {
  return ref.read(firestoreCafesServiceProvider).getCafeById(id);
});

final cafeReviewsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
      (ref, cafeId) =>
          ref.watch(firestoreCafesServiceProvider).watchReviews(cafeId),
    );
