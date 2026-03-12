// firestore_place_rankings_service.dart
//
// Maintains a `place_rankings` Firestore collection.
// Each document has the id = category (spot | cafe | restaurant | hotel | homestay)
// and stores the top-N ranked places for that category.
//
// Schema of each document:
// {
//   "updatedAt": Timestamp,
//   "entries": [
//     {
//       "id":          String,
//       "name":        String,
//       "heroImage":   String,
//       "rating":      double,
//       "ratingsCount": int,
//       "category":    String,
//     },
//     ...
//   ]
// }
//
// Called by every submitReview in the 5 listing services so rankings
// stay up-to-date without any Cloud Function.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/community_controller.dart';

final placeRankingsServiceProvider = Provider<FirestorePlaceRankingsService>(
  (_) => FirestorePlaceRankingsService(),
);

class FirestorePlaceRankingsService {
  final FirebaseFirestore _db;
  static const _col = 'place_rankings';
  static const int _topN = 10; // keep top-10 per category so UI can show top-3

  FirestorePlaceRankingsService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Fetch the pre-computed top-[_topN] list for [category].
  /// Returns empty list if the document doesn't exist yet.
  Future<List<PlaceRankEntry>> getTopForCategory(String category) async {
    try {
      final doc = await _db.collection(_col).doc(category).get();
      if (!doc.exists) return [];
      final data = doc.data() ?? {};
      final raw = data['entries'] as List<dynamic>? ?? [];
      return raw
          .map(
            (e) => PlaceRankEntry(
              id: e['id']?.toString() ?? '',
              name: e['name']?.toString() ?? '',
              heroImage: e['heroImage']?.toString() ?? '',
              rating: (e['rating'] as num?)?.toDouble() ?? 0.0,
              ratingsCount: (e['ratingsCount'] as num?)?.toInt() ?? 0,
              category: e['category']?.toString() ?? category,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Write (called after every review submission) ──────────────────────────

  /// Re-computes the top-[_topN] ranking for [category] in a transaction
  /// by inserting the newly rated [entry] and keeping the top-N sorted list.
  ///
  /// [ratingField] is the Firestore field name used for rating in the source
  /// collection (e.g. 'averageRating' for spots, 'rating' for the rest).
  /// [sourceCollection] is the Firestore collection name to re-query when
  /// the rankings document does not yet exist.
  Future<void> updateRankingAfterReview({
    required String category,
    required String placeId,
    required String placeName,
    required String heroImage,
    required double newRating,
    required int newRatingsCount,
  }) async {
    try {
      final docRef = _db.collection(_col).doc(category);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        List<Map<String, dynamic>> entries = [];

        if (snap.exists) {
          final raw = (snap.data()?['entries'] as List<dynamic>?) ?? [];
          entries = raw
              .whereType<Map<String, dynamic>>()
              .where((e) => e['id']?.toString() != placeId) // remove old entry
              .toList();
        }

        // Insert updated entry
        entries.add({
          'id': placeId,
          'name': placeName,
          'heroImage': heroImage,
          'rating': newRating,
          'ratingsCount': newRatingsCount,
          'category': category,
        });

        // Sort by rating desc, then ratingsCount desc
        entries.sort((a, b) {
          final ratingCmp = ((b['rating'] as num?)?.toDouble() ?? 0).compareTo(
            (a['rating'] as num?)?.toDouble() ?? 0,
          );
          if (ratingCmp != 0) return ratingCmp;
          return ((b['ratingsCount'] as num?)?.toInt() ?? 0).compareTo(
            (a['ratingsCount'] as num?)?.toInt() ?? 0,
          );
        });

        // Keep top N
        if (entries.length > _topN) {
          entries = entries.sublist(0, _topN);
        }

        tx.set(docRef, {
          'entries': entries,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (_) {
      // Best-effort — never let ranking update failure block the review.
    }
  }

  // ── Seed / Rebuild ────────────────────────────────────────────────────────

  /// Rebuilds the rankings for all 5 categories by querying each collection
  /// ordered by their rating field descending.
  /// Call this once from a debug/admin screen or on first-launch if rankings
  /// collection is empty.
  Future<void> rebuildAllRankings() async {
    final futures = <Future>[
      _rebuildCategory(
        category: 'spot',
        collection: 'spots',
        ratingField: 'averageRating',
        nameField: 'name',
        imageField: 'imagesUrl', // array — take first element
      ),
      _rebuildCategory(
        category: 'cafe',
        collection: 'cafes',
        ratingField: 'rating',
        nameField: 'name',
        imageField: 'images',
      ),
      _rebuildCategory(
        category: 'restaurant',
        collection: 'restaurants',
        ratingField: 'rating',
        nameField: 'name',
        imageField: 'images',
      ),
      _rebuildCategory(
        category: 'hotel',
        collection: 'accommodations',
        ratingField: 'rating',
        nameField: 'name',
        imageField: 'images',
      ),
      _rebuildCategory(
        category: 'homestay',
        collection: 'homestays',
        ratingField: 'rating',
        nameField: 'name',
        imageField: 'images',
      ),
    ];
    await Future.wait(futures);
  }

  Future<void> _rebuildCategory({
    required String category,
    required String collection,
    required String ratingField,
    required String nameField,
    required String imageField,
  }) async {
    try {
      final snap = await _db
          .collection(collection)
          .orderBy(ratingField, descending: true)
          .limit(_topN)
          .get();

      final entries = snap.docs.map((doc) {
        final d = doc.data();
        // Resolve hero image (may be an array or a string)
        String heroImg = '';
        final imgRaw = d[imageField];
        if (imgRaw is List && imgRaw.isNotEmpty) {
          heroImg = imgRaw.first?.toString() ?? '';
        } else if (imgRaw is String) {
          heroImg = imgRaw;
        }
        return {
          'id': doc.id,
          'name': d[nameField]?.toString() ?? '',
          'heroImage': heroImg,
          'rating': (d[ratingField] as num?)?.toDouble() ?? 0.0,
          'ratingsCount': (d['ratingsCount'] as num?)?.toInt() ?? 0,
          'category': category,
        };
      }).toList();

      await _db.collection(_col).doc(category).set({
        'entries': entries,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }
}
