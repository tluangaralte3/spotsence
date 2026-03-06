import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreShoppingService
// Reads from the `shoppingAreas` Firestore collection.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreShoppingService {
  final FirebaseFirestore _db;

  FirestoreShoppingService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('shoppingAreas');

  // ── List ──────────────────────────────────────────────────────────────────

  /// Fetches up to [limit] shopping areas. Client-side status filter.
  Future<List<ShoppingAreaModel>> getShoppingAreas({int limit = 100}) async {
    final snap = await _col.limit(limit * 2).get();
    return snap.docs
        .where((d) {
          final status = d.data()['status']?.toString();
          if (status == null || status.isEmpty) return true;
          return status.toLowerCase() == 'approved' ||
              status.toLowerCase() == 'active';
        })
        .map((d) => ShoppingAreaModel.fromFirestore(d))
        .take(limit)
        .toList();
  }

  /// Fetches shopping areas filtered by [type] (market / mall / street / boutique).
  Future<List<ShoppingAreaModel>> getByType({
    required String type,
    int limit = 100,
  }) async {
    final snap = await _col.where('type', isEqualTo: type).limit(limit).get();
    return snap.docs.map((d) => ShoppingAreaModel.fromFirestore(d)).toList();
  }

  // ── Single document ───────────────────────────────────────────────────────

  Future<ShoppingAreaModel?> getShoppingAreaById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ShoppingAreaModel.fromFirestore(doc);
  }

  // ── Stream (live) ─────────────────────────────────────────────────────────

  Stream<List<ShoppingAreaModel>> watchShoppingAreas({int limit = 100}) {
    return _col
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => ShoppingAreaModel.fromFirestore(d)).toList(),
        );
  }

  // ── Reviews subcollection ─────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchReviews(
    String areaId, {
    int limit = 30,
  }) {
    return _db
        .collection('shoppingAreas')
        .doc(areaId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<void> submitReview({
    required String areaId,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) async {
    await _db
        .collection('shoppingAreas')
        .doc(areaId)
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
        final docRef = _db.collection('shoppingAreas').doc(areaId);
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

final firestoreShoppingServiceProvider = Provider<FirestoreShoppingService>(
  (_) => FirestoreShoppingService(),
);
