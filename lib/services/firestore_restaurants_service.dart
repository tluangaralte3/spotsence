import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreRestaurantsService
// Reads from the `restaurants` Firestore collection.
// Status filter is client-side (case-insensitive) to tolerate casing
// variations in the database.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreRestaurantsService {
  final FirebaseFirestore _db;

  FirestoreRestaurantsService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('restaurants');

  // ── List ──────────────────────────────────────────────────────────────────

  /// Fetches up to [limit] restaurants. Client-side status filter.
  Future<List<RestaurantModel>> getRestaurants({int limit = 100}) async {
    final snap = await _col.limit(limit * 2).get();
    return snap.docs
        .where((d) {
          final status = d.data()['status']?.toString();
          if (status == null || status.isEmpty) return true;
          return status.toLowerCase() == 'approved' ||
              status.toLowerCase() == 'active';
        })
        .map((d) => RestaurantModel.fromFirestore(d))
        .take(limit)
        .toList();
  }

  // ── Single document ───────────────────────────────────────────────────────

  Future<RestaurantModel?> getRestaurantById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return RestaurantModel.fromFirestore(doc);
  }

  // ── Stream (live) ─────────────────────────────────────────────────────────

  Stream<List<RestaurantModel>> watchRestaurants({int limit = 100}) {
    return _col
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => RestaurantModel.fromFirestore(d)).toList(),
        );
  }

  // ── Reviews subcollection ─────────────────────────────────────────────────

  /// Live stream of reviews for a restaurant.
  Stream<List<Map<String, dynamic>>> watchReviews(
    String restaurantId, {
    int limit = 30,
  }) {
    return _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  /// Write a review to `restaurants/{id}/reviews`.
  Future<void> submitReview({
    required String restaurantId,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) async {
    final batch = _db.batch();

    // 1. Write the review document.
    final reviewRef = _db
        .collection('restaurants')
        .doc(restaurantId)
        .collection('reviews')
        .doc();
    batch.set(reviewRef, {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Update the running average on the restaurant document.
    // We read the current count and average, then recalculate.
    // This is done outside the batch since we need to read first.
    await batch.commit();

    // Best-effort: update average rating on the parent doc.
    try {
      await _db.runTransaction((tx) async {
        final docRef = _db.collection('restaurants').doc(restaurantId);
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
    } catch (_) {
      // Non-critical — ignore if transaction fails.
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final firestoreRestaurantsServiceProvider =
    Provider<FirestoreRestaurantsService>((_) => FirestoreRestaurantsService());

// Provider for the list (used by the notifier / tab).
final restaurantsStreamProvider = StreamProvider<List<RestaurantModel>>((ref) {
  return ref
      .watch(firestoreRestaurantsServiceProvider)
      .watchRestaurants(limit: 100);
});

// Provider for a single restaurant.
final restaurantDetailProvider =
    FutureProvider.family<RestaurantModel?, String>((ref, id) async {
      return ref
          .read(firestoreRestaurantsServiceProvider)
          .getRestaurantById(id);
    });

// Provider for live reviews of a restaurant.
final restaurantReviewsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
      (ref, restaurantId) => ref
          .watch(firestoreRestaurantsServiceProvider)
          .watchReviews(restaurantId),
    );
