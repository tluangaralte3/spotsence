import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_models.dart';
import 'firestore_place_rankings_service.dart';
import 'global_reviews_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreHotelsService
// Reads from the `accommodations` Firestore collection.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreHotelsService {
  final FirebaseFirestore _db;

  FirestoreHotelsService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('accommodations');

  // ── List ──────────────────────────────────────────────────────────────────

  Future<List<HotelModel>> getHotels({int limit = 100}) async {
    final snap = await _col.limit(limit * 2).get();
    return snap.docs
        .where((d) {
          final type = d.data()['type']?.toString().toLowerCase();
          if (type != null && type.isNotEmpty && type != 'hotel') return false;
          final status = d.data()['status']?.toString();
          if (status == null || status.isEmpty) return true;
          return status.toLowerCase() == 'approved' ||
              status.toLowerCase() == 'active';
        })
        .map((d) => HotelModel.fromFirestore(d))
        .take(limit)
        .toList();
  }

  // ── Single document ───────────────────────────────────────────────────────

  Future<HotelModel?> getHotelById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return HotelModel.fromFirestore(doc);
  }

  // ── Stream (live) ─────────────────────────────────────────────────────────

  Stream<List<HotelModel>> watchHotels({int limit = 100}) {
    return _col
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => HotelModel.fromFirestore(d)).toList(),
        );
  }

  // ── Reviews subcollection ─────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchReviews(
    String hotelId, {
    int limit = 30,
  }) {
    return _db
        .collection('accommodations')
        .doc(hotelId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<bool> submitReview({
    required String hotelId,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) async {
    final reviewRef = _db
        .collection('accommodations')
        .doc(hotelId)
        .collection('reviews')
        .doc(userId); // deterministic ID — one review per user per place

    final existing = await reviewRef.get();
    final isNew = !existing.exists;

    await reviewRef.set({
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
        final docRef = _db.collection('accommodations').doc(hotelId);
        final snap = await tx.get(docRef);
        if (!snap.exists) return;
        final data = snap.data() ?? {};
        final oldCount = (data['ratingsCount'] as num?)?.toInt() ?? 0;
        final oldRating =
            (data['rating'] ?? data['averageRating'] as num?)?.toDouble() ??
            0.0;
        if (isNew) {
          final newCount = oldCount + 1;
          final newRating = ((oldRating * oldCount) + rating) / newCount;
          tx.update(docRef, {
            'rating': double.parse(newRating.toStringAsFixed(1)),
            'ratingsCount': newCount,
          });
        } else {
          final oldUserRating = (existing.data()?['rating'] as num?)?.toDouble() ?? rating;
          final newRating = oldCount > 0
              ? ((oldRating * oldCount) - oldUserRating + rating) / oldCount
              : rating;
          tx.update(docRef, {
            'rating': double.parse(newRating.toStringAsFixed(1)),
          });
        }
      });

      // Rebuild the place_rankings entry for this hotel.
      final hotelDoc = await _db
          .collection('accommodations')
          .doc(hotelId)
          .get();
      if (hotelDoc.exists) {
        final d = hotelDoc.data() ?? {};
        final images = d['images'] as List<dynamic>?;
        final heroImg = images != null && images.isNotEmpty
            ? images.first.toString()
            : '';
        await FirestorePlaceRankingsService(_db).updateRankingAfterReview(
          category: 'hotel',
          placeId: hotelId,
          placeName: d['name']?.toString() ?? '',
          heroImage: heroImg,
          newRating: (d['rating'] as num?)?.toDouble() ?? 0.0,
          newRatingsCount: (d['ratingsCount'] as num?)?.toInt() ?? 0,
        );
        // Record in global_reviews + update place_leaderboard
        await GlobalReviewsService().recordReview(
          placeId: hotelId,
          placeName: d['name']?.toString() ?? '',
          category: 'hotel',
          heroImage: heroImg,
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          rating: rating,
          comment: comment,
        );
      }
    } catch (_) {}
    return isNew;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod providers
// ─────────────────────────────────────────────────────────────────────────────

final firestoreHotelsServiceProvider = Provider<FirestoreHotelsService>(
  (_) => FirestoreHotelsService(),
);

final hotelDetailProvider = FutureProvider.family<HotelModel?, String>((
  ref,
  id,
) async {
  return ref.read(firestoreHotelsServiceProvider).getHotelById(id);
});

final hotelReviewsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
      (ref, hotelId) =>
          ref.watch(firestoreHotelsServiceProvider).watchReviews(hotelId),
    );
