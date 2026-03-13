// firestore_dilemmas_service.dart
//
// Reads and writes the `dilemmas` Firestore collection.
//
// Document schema:
// {
//   question:    String,
//   optionA:     { spotId?, name, category?, imageUrl?, district? },
//   optionB:     { spotId?, name, category?, imageUrl?, district? },
//   votesA:      List<String>  (user ids who voted A),
//   votesB:      List<String>  (user ids who voted B),
//   authorId:    String,
//   authorName:  String,
//   authorPhoto: String?,
//   status:      'active' | 'closed',
//   expiresAt:   Timestamp?  (null = open-ended),
//   createdAt:   Timestamp,
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/community_models.dart';

final firestoreDilemmasServiceProvider = Provider<FirestoreDilemmasService>(
  (_) => FirestoreDilemmasService(),
);

class FirestoreDilemmasService {
  final FirebaseFirestore _db;
  static const _col = 'dilemmas';

  FirestoreDilemmasService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(_col);

  // ── Watch (live stream) ───────────────────────────────────────────────────

  /// Live stream of active + recently-closed dilemmas, newest first.
  Stream<List<Dilemma>> watchDilemmas({int limit = 50}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Dilemma.fromFirestore(d)).toList());
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<String?> createDilemma({
    required String question,
    required DilemmaOption optionA,
    required DilemmaOption optionB,
    required String authorId,
    required String authorName,
    String? authorPhoto,
    Duration? duration, // null = open-ended
  }) async {
    try {
      final now = FieldValue.serverTimestamp();
      final expiresAt = duration != null
          ? Timestamp.fromDate(DateTime.now().add(duration))
          : null;

      await _collection.add({
        'question': question,
        'optionA': optionA.toMap(),
        'optionB': optionB.toMap(),
        'votesA': <String>[],
        'votesB': <String>[],
        'authorId': authorId,
        'authorName': authorName,
        if (authorPhoto != null && authorPhoto.isNotEmpty)
          'authorPhoto': authorPhoto,
        'status': 'active',
        // ignore: use_null_aware_elements
        if (expiresAt != null) 'expiresAt': expiresAt,
        'createdAt': now,
      });
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // ── Vote ──────────────────────────────────────────────────────────────────

  /// Toggle the user's vote.  Moves vote if switching sides, removes if same.
  Future<String?> vote({
    required String dilemmaId,
    required String userId,
    required String option, // 'A' | 'B'
  }) async {
    try {
      final docRef = _collection.doc(dilemmaId);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) return;
        final data = snap.data()!;

        final votesA = List<String>.from(data['votesA'] as List? ?? []);
        final votesB = List<String>.from(data['votesB'] as List? ?? []);

        // Remove from both first
        votesA.remove(userId);
        votesB.remove(userId);

        // Add to chosen side
        if (option == 'A') {
          votesA.add(userId);
        } else {
          votesB.add(userId);
        }

        tx.update(docRef, {'votesA': votesA, 'votesB': votesB});
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteDilemma(String dilemmaId) async {
    await _collection.doc(dilemmaId).delete();
  }

  // ── Close ────────────────────────────────────────────────────────────────

  Future<void> closeDilemma(String dilemmaId) async {
    await _collection.doc(dilemmaId).update({'status': 'closed'});
  }
}
