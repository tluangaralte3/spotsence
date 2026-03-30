import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_models.dart';
import 'firestore_place_rankings_service.dart';
import 'global_reviews_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreHomestaysService
// Reads from the `accommodations` Firestore collection, type == "Homestay".
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreHomestaysService {
  final FirebaseFirestore _db;

  FirestoreHomestaysService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('accommodations');

  // ── List ──────────────────────────────────────────────────────────────────

  /// Fetches up to [limit] homestays. Client-side status filter.
  Future<List<HomestayModel>> getHomestays({int limit = 100}) async {
    final snap = await _col.limit(limit * 2).get();
    return snap.docs
        .where((d) {
          final type = d.data()['type']?.toString().toLowerCase();
          if (type != null && type.isNotEmpty && type != 'homestay') return false;
          final status = d.data()['status']?.toString();
          if (status == null || status.isEmpty) return true;
          return status.toLowerCase() == 'approved' ||
              status.toLowerCase() == 'active';
        })
        .map((d) => HomestayModel.fromFirestore(d))
        .take(limit)
        .toList();
  }

  // ── Single document ───────────────────────────────────────────────────────

  Future<HomestayModel?> getHomestayById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return HomestayModel.fromFirestore(doc);
  }

  // ── Stream (live) ─────────────────────────────────────────────────────────

  Stream<List<HomestayModel>> watchHomestays({int limit = 100}) {
    return _col
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((d) {
                final type = d.data()['type']?.toString().toLowerCase();
                return type == null || type.isEmpty || type == 'homestay';
              })
              .map((d) => HomestayModel.fromFirestore(d))
              .toList(),
        );
  }

  // ── Reviews subcollection ─────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> watchReviews(
    String homestayId, {
    int limit = 30,
  }) {
    return _db
        .collection('accommodations')
        .doc(homestayId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
        );
  }

  Future<void> submitReview({
    required String homestayId,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) async {
    await _db
        .collection('accommodations')
        .doc(homestayId)
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
        final docRef = _db.collection('accommodations').doc(homestayId);
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

      // Rebuild the place_rankings entry for this homestay.
      final homestayDoc = await _db
          .collection('accommodations')
          .doc(homestayId)
          .get();
      if (homestayDoc.exists) {
        final d = homestayDoc.data() ?? {};
        final images = d['images'] as List<dynamic>?;
        final heroImg = images != null && images.isNotEmpty
            ? images.first.toString()
            : '';
        await FirestorePlaceRankingsService(_db).updateRankingAfterReview(
          category: 'homestay',
          placeId: homestayId,
          placeName: d['name']?.toString() ?? '',
          heroImage: heroImg,
          newRating: (d['rating'] as num?)?.toDouble() ?? 0.0,
          newRatingsCount: (d['ratingsCount'] as num?)?.toInt() ?? 0,
        );
        // Record in global_reviews + update place_leaderboard
        await GlobalReviewsService().recordReview(
          placeId: homestayId,
          placeName: d['name']?.toString() ?? '',
          category: 'homestay',
          heroImage: heroImg,
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          rating: rating,
          comment: comment,
        );
      }
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final firestoreHomestaysServiceProvider = Provider<FirestoreHomestaysService>(
  (_) => FirestoreHomestaysService(),
);
