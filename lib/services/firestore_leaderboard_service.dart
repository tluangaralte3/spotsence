// firestore_leaderboard_service.dart
//
// Reads the `place_leaderboard` Firestore collection and provides:
//   • a real-time stream of all entries sorted by avgRating desc
//   • a one-shot future fetch
//
// The collection is written by GlobalReviewsService._updateLeaderboard()
// whenever any review is submitted across any listing type.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreLeaderboardServiceProvider =
    Provider<FirestoreLeaderboardService>((_) => FirestoreLeaderboardService());

class PlaceLeaderboardEntry {
  final String placeId;
  final String placeName;
  final String category;
  final String heroImage;
  final double avgRating;
  final double totalRating;
  final int ratingCount;
  final DateTime? lastReviewAt;

  const PlaceLeaderboardEntry({
    required this.placeId,
    required this.placeName,
    required this.category,
    required this.heroImage,
    required this.avgRating,
    required this.totalRating,
    required this.ratingCount,
    this.lastReviewAt,
  });

  factory PlaceLeaderboardEntry.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return PlaceLeaderboardEntry(
      placeId: d['placeId']?.toString() ?? doc.id,
      placeName: d['placeName']?.toString() ?? '',
      category: d['category']?.toString() ?? '',
      heroImage: d['heroImage']?.toString() ?? '',
      avgRating: (d['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalRating: (d['totalRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
      lastReviewAt: (d['lastReviewAt'] as Timestamp?)?.toDate(),
    );
  }

  factory PlaceLeaderboardEntry.fromMap(Map<String, dynamic> d) =>
      PlaceLeaderboardEntry(
        placeId: d['placeId']?.toString() ?? '',
        placeName: d['placeName']?.toString() ?? '',
        category: d['category']?.toString() ?? '',
        heroImage: d['heroImage']?.toString() ?? '',
        avgRating: (d['avgRating'] as num?)?.toDouble() ?? 0.0,
        totalRating: (d['totalRating'] as num?)?.toDouble() ?? 0.0,
        ratingCount: (d['ratingCount'] as num?)?.toInt() ?? 0,
        lastReviewAt: (d['lastReviewAt'] as Timestamp?)?.toDate(),
      );
}

class FirestoreLeaderboardService {
  static const _col = 'place_leaderboard';
  final FirebaseFirestore _db;

  FirestoreLeaderboardService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  // ── Real-time stream (used by leaderboard screen) ─────────────────────────

  /// Streams all entries sorted by [avgRating] descending.
  /// Firestore returns at most [limit] entries; the screen takes the top-3
  /// per category from this list.
  Stream<List<PlaceLeaderboardEntry>> watchAll({int limit = 200}) {
    return _db
        .collection(_col)
        .orderBy('avgRating', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PlaceLeaderboardEntry.fromDoc(d))
              .where((e) => e.ratingCount > 0)
              .toList(),
        );
  }

  /// One-shot fetch — same ordering as the stream.
  Future<List<PlaceLeaderboardEntry>> getAll({int limit = 200}) async {
    final snap = await _db
        .collection(_col)
        .orderBy('avgRating', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => PlaceLeaderboardEntry.fromDoc(d))
        .where((e) => e.ratingCount > 0)
        .toList();
  }

  /// Top-[n] entries for a single [category].
  Future<List<PlaceLeaderboardEntry>> getTopForCategory(
    String category, {
    int n = 3,
  }) async {
    final snap = await _db
        .collection(_col)
        .where('category', isEqualTo: category)
        .orderBy('avgRating', descending: true)
        .limit(n)
        .get();
    return snap.docs
        .map((d) => PlaceLeaderboardEntry.fromDoc(d))
        .where((e) => e.ratingCount > 0)
        .toList();
  }
}
