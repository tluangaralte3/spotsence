// global_reviews_service.dart
//
// Writes every review across all listing types into a single top-level
// `global_reviews` Firestore collection AND maintains an aggregated
// `place_leaderboard` doc so the leaderboard can be built with a single
// lightweight Firestore query.
//
// ──────────────────────────────────────────────────────────────────────────────
// Firestore layout
// ──────────────────────────────────────────────────────────────────────────────
//
// global_reviews/{autoId}
//   placeId       : String   — Firestore doc-id in the source collection
//   placeName     : String
//   category      : String   — 'spot' | 'cafe' | 'restaurant' | 'hotel' | 'homestay'
//   heroImage     : String
//   userId        : String
//   userName      : String
//   userAvatar    : String
//   rating        : double
//   comment       : String
//   timestamp     : Timestamp
//
// place_leaderboard/{placeId}
//   placeId       : String
//   placeName     : String
//   category      : String
//   heroImage     : String
//   avgRating     : double   — running weighted average
//   totalRating   : double   — sum of all ratings
//   ratingCount   : int      — number of reviews
//   lastReviewAt  : Timestamp

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final globalReviewsServiceProvider = Provider<GlobalReviewsService>(
  (_) => GlobalReviewsService(),
);

class GlobalReviewsService {
  final FirebaseFirestore _db;

  static const _reviewsCol = 'global_reviews';
  static const _leaderboardCol = 'place_leaderboard';

  GlobalReviewsService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Called by every listing-service `submitReview`.
  ///
  /// Does two things in parallel:
  ///   1. Appends a document to `global_reviews`
  ///   2. Upserts + updates the running average in `place_leaderboard`
  Future<void> recordReview({
    required String placeId,
    required String placeName,
    required String category,
    required String heroImage,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) async {
    try {
      await Future.wait([
        _writeGlobalReview(
          placeId: placeId,
          placeName: placeName,
          category: category,
          heroImage: heroImage,
          userId: userId,
          userName: userName,
          userAvatar: userAvatar,
          rating: rating,
          comment: comment,
        ),
        _updateLeaderboard(
          placeId: placeId,
          placeName: placeName,
          category: category,
          heroImage: heroImage,
          rating: rating,
        ),
      ]);
    } catch (_) {
      // Best-effort — never block the primary review write.
    }
  }

  Future<void> _writeGlobalReview({
    required String placeId,
    required String placeName,
    required String category,
    required String heroImage,
    required String userId,
    required String userName,
    required String userAvatar,
    required double rating,
    required String comment,
  }) {
    return _db.collection(_reviewsCol).add({
      'placeId': placeId,
      'placeName': placeName,
      'category': category,
      'heroImage': heroImage,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateLeaderboard({
    required String placeId,
    required String placeName,
    required String category,
    required String heroImage,
    required double rating,
  }) {
    final ref = _db.collection(_leaderboardCol).doc(placeId);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        tx.set(ref, {
          'placeId': placeId,
          'placeName': placeName,
          'category': category,
          'heroImage': heroImage,
          'totalRating': rating,
          'ratingCount': 1,
          'avgRating': double.parse(rating.toStringAsFixed(2)),
          'lastReviewAt': FieldValue.serverTimestamp(),
        });
      } else {
        final d = snap.data()!;
        final oldTotal = (d['totalRating'] as num?)?.toDouble() ?? 0.0;
        final oldCount = (d['ratingCount'] as num?)?.toInt() ?? 0;
        final newTotal = oldTotal + rating;
        final newCount = oldCount + 1;
        final newAvg = double.parse((newTotal / newCount).toStringAsFixed(2));
        tx.update(ref, {
          // Keep latest name / image in case they were updated
          'placeName': placeName,
          'heroImage': heroImage,
          'totalRating': newTotal,
          'ratingCount': newCount,
          'avgRating': newAvg,
          'lastReviewAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // ── Read helpers ──────────────────────────────────────────────────────────

  /// Returns the last [limit] global reviews for a specific place.
  Stream<List<GlobalReview>> watchReviewsForPlace(
    String placeId, {
    int limit = 20,
  }) {
    return _db
        .collection(_reviewsCol)
        .where('placeId', isEqualTo: placeId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GlobalReview.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  /// Returns the last [limit] reviews across all places (global feed).
  Stream<List<GlobalReview>> watchLatestReviews({int limit = 50}) {
    return _db
        .collection(_reviewsCol)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GlobalReview.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // ── Rebuild (admin / first-run) ───────────────────────────────────────────

  /// Rebuilds the entire `place_leaderboard` collection by reading aggregated
  /// rating fields from all 5 source collections, with a fallback to crawling
  /// the per-place `reviews` subcollection if the aggregated fields are absent.
  ///
  /// Returns a human-readable summary string, e.g.
  ///   "Written 34 entries: 8 spots, 7 cafes, 6 restaurants, 8 hotels, 5 homestays"
  Future<String> rebuildLeaderboard() async {
    final fs = _db;
    final results = await Future.wait([
      _seedCategory(fs, 'spot', 'spots', 'imagesUrl', isArray: true),
      _seedCategory(fs, 'cafe', 'cafes', 'images', isArray: true),
      _seedCategory(fs, 'restaurant', 'restaurants', 'images', isArray: true),
      _seedCategory(fs, 'hotel', 'accommodations', 'images', isArray: true),
      _seedCategory(fs, 'homestay', 'homestays', 'images', isArray: true),
    ]);
    final total = results.fold(0, (a, b) => a + b);
    return 'Written $total entries: '
        '${results[0]} spots, ${results[1]} cafes, '
        '${results[2]} restaurants, ${results[3]} hotels, '
        '${results[4]} homestays';
  }

  Future<int> _seedCategory(
    FirebaseFirestore fs,
    String category,
    String collection,
    String imageField, {
    required bool isArray,
  }) async {
    final snap = await fs.collection(collection).limit(300).get();
    int written = 0;
    for (final doc in snap.docs) {
      final d = doc.data();

      // Try aggregated fields first
      final cnt =
          (d['ratingsCount'] as num?)?.toInt() ??
          (d['ratingCount'] as num?)?.toInt() ??
          (d['reviewCount'] as num?)?.toInt() ??
          0;
      final avg =
          (d['averageRating'] as num?)?.toDouble() ??
          (d['rating'] as num?)?.toDouble() ??
          (d['avgRating'] as num?)?.toDouble() ??
          0.0;

      int finalCnt = cnt;
      double finalAvg = avg;

      // Fall back to subcollection crawl if aggregated data is absent
      if (cnt == 0 || avg == 0.0) {
        final revs = await fs
            .collection(collection)
            .doc(doc.id)
            .collection('reviews')
            .get();
        if (revs.docs.isEmpty) continue;
        double total = 0;
        int c = 0;
        for (final r in revs.docs) {
          final v = (r.data()['rating'] as num?)?.toDouble();
          if (v != null && v > 0) {
            total += v;
            c++;
          }
        }
        if (c == 0) continue;
        finalCnt = c;
        finalAvg = total / c;
      }

      String heroImg = '';
      final img = d[imageField];
      if (isArray && img is List && img.isNotEmpty) {
        heroImg = img.first?.toString() ?? '';
      } else if (img is String) {
        heroImg = img;
      }

      await fs.collection(_leaderboardCol).doc(doc.id).set({
        'placeId': doc.id,
        'placeName': d['name']?.toString() ?? '',
        'category': category,
        'heroImage': heroImg,
        'totalRating': double.parse((finalAvg * finalCnt).toStringAsFixed(2)),
        'ratingCount': finalCnt,
        'avgRating': double.parse(finalAvg.toStringAsFixed(2)),
        'lastReviewAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      written++;
    }
    return written;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class GlobalReview {
  final String id;
  final String placeId;
  final String placeName;
  final String category;
  final String heroImage;
  final String userId;
  final String userName;
  final String userAvatar;
  final double rating;
  final String comment;
  final DateTime? timestamp;

  const GlobalReview({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.category,
    required this.heroImage,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    this.timestamp,
  });

  factory GlobalReview.fromMap(String id, Map<String, dynamic> d) =>
      GlobalReview(
        id: id,
        placeId: d['placeId']?.toString() ?? '',
        placeName: d['placeName']?.toString() ?? '',
        category: d['category']?.toString() ?? '',
        heroImage: d['heroImage']?.toString() ?? '',
        userId: d['userId']?.toString() ?? '',
        userName: d['userName']?.toString() ?? '',
        userAvatar: d['userAvatar']?.toString() ?? '',
        rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
        comment: d['comment']?.toString() ?? '',
        timestamp: (d['timestamp'] as Timestamp?)?.toDate(),
      );
}
