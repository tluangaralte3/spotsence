import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot_model.dart';

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
}
