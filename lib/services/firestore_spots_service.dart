import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot_model.dart';
import 'firestore_place_rankings_service.dart';
import 'global_reviews_service.dart';

final firestoreSpotsServiceProvider = Provider<FirestoreSpotsService>((ref) {
  return FirestoreSpotsService(FirebaseFirestore.instance);
});

class FirestoreSpotsService {
  final FirebaseFirestore _db;
  static const String _collection = 'spots';

  FirestoreSpotsService(this._db);

  /// Fetch featured + approved spots, optionally filtered by [category].
  /// Results are sorted: featured first, then by popularity descending.
  Future<List<SpotModel>> getFeaturedSpots({
    String? category,
    int limit = 12,
  }) async {
    try {
      Query<Map<String, dynamic>> q = _db.collection(_collection).limit(50);

      if (category != null && category != 'all') {
        q = q.where('category', isEqualTo: category);
      }

      final snapshot = await q.get();

      List<SpotModel> spots = snapshot.docs
          .map((doc) => SpotModel.fromFirestore(doc))
          // keep only approved (case-insensitive)
          .where((s) => s.status.toLowerCase() == 'approved')
          .toList();

      // Featured first, then by popularity descending
      spots.sort((a, b) {
        if (a.featured && !b.featured) return -1;
        if (!a.featured && b.featured) return 1;
        return b.popularity.compareTo(a.popularity);
      });

      return spots.take(limit).toList();
    } catch (e) {
      // Return empty list on error; UI shows EmptyState
      return [];
    }
  }

  /// Stream version — auto-refreshes when Firestore data changes.
  Stream<List<SpotModel>> watchFeaturedSpots({
    String? category,
    int limit = 12,
  }) {
    Query<Map<String, dynamic>> q = _db.collection(_collection).limit(50);

    if (category != null && category != 'all') {
      q = q.where('category', isEqualTo: category);
    }

    return q.snapshots().map((snapshot) {
      List<SpotModel> spots = snapshot.docs
          .map((doc) => SpotModel.fromFirestore(doc))
          .where((s) => s.status.toLowerCase() == 'approved')
          .toList();

      spots.sort((a, b) {
        if (a.featured && !b.featured) return -1;
        if (!a.featured && b.featured) return 1;
        return b.popularity.compareTo(a.popularity);
      });

      return spots.take(limit).toList();
    });
  }

  /// Fetch a single spot by Firestore document ID.
  Future<SpotModel?> getSpotById(String id) async {
    try {
      final doc = await _db.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return SpotModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }

  // ── Reviews subcollection ─────────────────────────────────────────────────

  /// Live stream of reviews for a spot.
  Stream<List<Map<String, dynamic>>> watchReviews(
    String spotId, {
    int limit = 30,
  }) {
    return _db
        .collection(_collection)
        .doc(spotId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  /// Write a review to `spots/{id}/reviews` and update the running average.
  Future<void> submitReview({
    required String spotId,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) async {
    await _db
        .collection(_collection)
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

    // Best-effort: update running average on the parent doc.
    try {
      await _db.runTransaction((tx) async {
        final docRef = _db.collection(_collection).doc(spotId);
        final snap = await tx.get(docRef);
        if (!snap.exists) return;
        final data = snap.data() ?? {};
        final oldCount = (data['ratingsCount'] as num?)?.toInt() ?? 0;
        final oldRating =
            (data['averageRating'] ?? data['rating'] as num?)?.toDouble() ??
            0.0;
        final newCount = oldCount + 1;
        final newRating = ((oldRating * oldCount) + rating) / newCount;
        tx.update(docRef, {
          'averageRating': double.parse(newRating.toStringAsFixed(1)),
          'ratingsCount': newCount,
        });
      });

      // Rebuild the place_rankings entry for this spot.
      final spotDoc = await _db.collection(_collection).doc(spotId).get();
      if (spotDoc.exists) {
        final d = spotDoc.data() ?? {};
        final images = (d['imagesUrl'] as List<dynamic>?);
        final heroImg = images != null && images.isNotEmpty
            ? images.first.toString()
            : '';
        await FirestorePlaceRankingsService(_db).updateRankingAfterReview(
          category: 'spot',
          placeId: spotId,
          placeName: d['name']?.toString() ?? '',
          heroImage: heroImg,
          newRating: (d['averageRating'] as num?)?.toDouble() ?? 0.0,
          newRatingsCount: (d['ratingsCount'] as num?)?.toInt() ?? 0,
        );
        // Record in global_reviews + update place_leaderboard
        await GlobalReviewsService().recordReview(
          placeId: spotId,
          placeName: d['name']?.toString() ?? '',
          category: 'spot',
          heroImage: heroImg,
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          rating: rating,
          comment: comment,
        );
      }
    } catch (_) {
      // Non-critical — ignore if transaction fails.
    }
  }
}
