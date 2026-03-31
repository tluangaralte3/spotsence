import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dare_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreDareService
// Collection: dares
// Subcollections: dares/{id}/proofs
// User subcollections: users/{uid}/scratchCards, users/{uid}/daremedals
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreDareService {
  final FirebaseFirestore _db;

  FirestoreDareService([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('dares');

  CollectionReference<Map<String, dynamic>> _userCol(String uid) =>
      _db.collection('users').doc(uid).collection('scratchCards');

  CollectionReference<Map<String, dynamic>> _medalsCol(String uid) =>
      _db.collection('users').doc(uid).collection('daremedals');

  // ── Join code ─────────────────────────────────────────────────────────────

  String generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<DareModel> create(DareModel model) async {
    try {
      final docRef = _col.doc();
      final data = model.toJson();
      data['createdAt'] = FieldValue.serverTimestamp();
      await docRef.set(data);
      final snap = await docRef.get();
      return DareModel.fromFirestore(snap);
    } catch (e, st) {
      debugPrint('FirestoreDareService.create error: $e\n$st');
      rethrow;
    }
  }

  // ── Read — user's own dares ───────────────────────────────────────────────

  Future<List<DareModel>> getMyDares(String userId) async {
    final created = await _col
        .where('creatorId', isEqualTo: userId)
        .get();

    final joined = await _col
        .where('memberIds', arrayContains: userId)
        .get();

    final pending = await _col
        .where('pendingMemberIds', arrayContains: userId)
        .get();

    final ids = <String>{};
    final list = <DareModel>[];

    for (final doc in [...created.docs, ...joined.docs, ...pending.docs]) {
      if (ids.add(doc.id)) list.add(DareModel.fromFirestore(doc));
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ── Read — discover (public dares) ────────────────────────────────────────

  Future<List<DareModel>> getPublicDares({int limit = 30}) async {
    final snap = await _col
        .where('visibility', isEqualTo: 'public')
        .limit(limit)
        .get();
    final list = snap.docs.map((d) => DareModel.fromFirestore(d)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ── Read — single ─────────────────────────────────────────────────────────

  Future<DareModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return DareModel.fromFirestore(doc);
  }

  Future<DareModel?> getByJoinCode(String code) async {
    final snap = await _col
        .where('joinCode', isEqualTo: code)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return DareModel.fromFirestore(snap.docs.first);
  }

  // ── Live stream ───────────────────────────────────────────────────────────

  Stream<DareModel?> watchById(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DareModel.fromFirestore(doc);
    });
  }

  Stream<List<DareModel>> watchCreatedDares(String userId) {
    return _col
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => DareModel.fromFirestore(d)).toList());
  }

  /// Merges three Firestore streams: dares the user created, is a member of,
  /// or has a pending join request for. Deduped and sorted in Dart.
  Stream<List<DareModel>> watchMyDares(String userId) {
    List<DareModel> created = [];
    List<DareModel> joined = [];
    List<DareModel> pending = [];
    StreamSubscription? s1, s2, s3;
    late StreamController<List<DareModel>> ctl;

    void emit() {
      if (ctl.isClosed) return;
      final ids = <String>{};
      final list = <DareModel>[];
      for (final d in [...created, ...joined, ...pending]) {
        if (ids.add(d.id)) list.add(d);
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      ctl.add(list);
    }

    ctl = StreamController<List<DareModel>>(
      onListen: () {
        s1 = _col
            .where('creatorId', isEqualTo: userId)
            .snapshots()
            .listen(
              (s) {
                created = s.docs.map(DareModel.fromFirestore).toList();
                emit();
              },
              onError: ctl.addError,
            );
        s2 = _col
            .where('memberIds', arrayContains: userId)
            .snapshots()
            .listen(
              (s) {
                joined = s.docs.map(DareModel.fromFirestore).toList();
                emit();
              },
              onError: ctl.addError,
            );
        s3 = _col
            .where('pendingMemberIds', arrayContains: userId)
            .snapshots()
            .listen(
              (s) {
                pending = s.docs.map(DareModel.fromFirestore).toList();
                emit();
              },
              onError: ctl.addError,
            );
      },
      onCancel: () {
        s1?.cancel();
        s2?.cancel();
        s3?.cancel();
      },
    );

    return ctl.stream;
  }

  // ── Join flow ─────────────────────────────────────────────────────────────

  Future<void> requestJoin({
    required String dareId,
    required String userId,
    required String userName,
    String? userPhoto,
    required bool isPublic,
  }) async {
    final docRef = _col.doc(dareId);
    final now = DateTime.now().toIso8601String();
    final member = {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'role': 'participant',
      'status': isPublic ? 'approved' : 'pending',
      'joinedAt': now,
      'approvedAt': isPublic ? now : null,
      'completedChallenges': 0,
      'totalXpEarned': 0,
    };

    // Use direct writes with arrayUnion — no tx.get() read needed, avoiding
    // permission issues for users who haven't yet been added to the dare.
    if (isPublic) {
      await docRef.update({
        'members': FieldValue.arrayUnion([member]),
        'memberIds': FieldValue.arrayUnion([userId]),
      });
    } else {
      await docRef.update({
        'joinRequests': FieldValue.arrayUnion([member]),
        'pendingMemberIds': FieldValue.arrayUnion([userId]),
      });
    }
  }

  Future<DareModel?> approveJoin({
    required String dareId,
    required String userId,
  }) async {
    final docRef = _col.doc(dareId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final requests = List<Map<String, dynamic>>.from(
        data['joinRequests'] ?? [],
      );
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      final memberIds = List<String>.from(data['memberIds'] ?? []);

      final idx = requests.indexWhere((r) => r['userId'] == userId);
      if (idx < 0) return;
      final approved = Map<String, dynamic>.from(requests[idx]);
      approved['status'] = 'approved';
      approved['approvedAt'] = DateTime.now().toIso8601String();

      requests.removeAt(idx);
      members.add(approved);
      if (!memberIds.contains(userId)) memberIds.add(userId);

      final pendingIds = List<String>.from(data['pendingMemberIds'] ?? []);
      pendingIds.remove(userId);

      tx.update(docRef, {
        'joinRequests': requests,
        'members': members,
        'memberIds': memberIds,
        'pendingMemberIds': pendingIds,
      });
    });
    return getById(dareId);
  }

  Future<DareModel?> declineJoin({
    required String dareId,
    required String userId,
  }) async {
    final docRef = _col.doc(dareId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final requests = List<Map<String, dynamic>>.from(
        data['joinRequests'] ?? [],
      );
      final pendingIds = List<String>.from(data['pendingMemberIds'] ?? []);
      requests.removeWhere((r) => r['userId'] == userId);
      pendingIds.remove(userId);
      tx.update(docRef, {
        'joinRequests': requests,
        'pendingMemberIds': pendingIds,
      });
    });
    return getById(dareId);
  }

  Future<void> leave({
    required String dareId,
    required String userId,
  }) async {
    final docRef = _col.doc(dareId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      members.removeWhere((m) => m['userId'] == userId);
      memberIds.remove(userId);
      tx.update(docRef, {'members': members, 'memberIds': memberIds});
    });
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> update(String dareId, Map<String, dynamic> fields) async {
    await _col.doc(dareId).update(fields);
  }

  Future<void> addChallenge(String dareId, DareChallenge challenge) async {
    final docRef = _col.doc(dareId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final challenges = List<Map<String, dynamic>>.from(
        snap.data()!['challenges'] ?? [],
      );
      challenges.add(challenge.toJson());
      tx.update(docRef, {'challenges': challenges});
    });
  }

  Future<void> updateChallenge(
    String dareId,
    DareChallenge updated,
  ) async {
    final docRef = _col.doc(dareId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final challenges = List<Map<String, dynamic>>.from(
        snap.data()!['challenges'] ?? [],
      );
      final idx = challenges.indexWhere((c) => c['id'] == updated.id);
      if (idx >= 0) challenges[idx] = updated.toJson();
      tx.update(docRef, {'challenges': challenges});
    });
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> delete(String dareId) async {
    await _col.doc(dareId).delete();
  }

  // ── Room cap ─────────────────────────────────────────────────────────────

  Future<int> countCreatedDares(String userId) async {
    final snap = await _col
        .where('creatorId', isEqualTo: userId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ── Proof submission ─────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _proofsCol(String dareId) =>
      _col.doc(dareId).collection('proofs');

  Future<ProofSubmission> submitProof({
    required String dareId,
    required String userId,
    required String userName,
    String? userPhoto,
    required String challengeId,
    required List<String> imageUrls,
    double? latitude,
    double? longitude,
    String? locationName,
    String? note,
  }) async {
    final docRef = _proofsCol(dareId).doc();
    final data = {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'challengeId': challengeId,
      'dareId': dareId,
      'imageUrls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'note': note,
      'submittedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'reviewNote': null,
    };
    await docRef.set(data);
    final snap = await docRef.get();
    return ProofSubmission.fromFirestore(snap);
  }

  Future<void> reviewProof({
    required String dareId,
    required String proofId,
    required ProofStatus status,
    String? reviewNote,
  }) async {
    await _proofsCol(dareId).doc(proofId).update({
      'status': status.name,
      'reviewNote': reviewNote,
    });
  }

  Stream<List<ProofSubmission>> watchProofsForDare(String dareId) {
    return _proofsCol(dareId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => ProofSubmission.fromFirestore(d))
                  .toList(),
        );
  }

  Stream<List<ProofSubmission>> watchMyProofs({
    required String dareId,
    required String userId,
  }) {
    return _proofsCol(dareId)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (s) {
            final list = s.docs
                .map((d) => ProofSubmission.fromFirestore(d))
                .toList()
              ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
            return list;
          },
        );
  }

  // ── Update challenge progress for a member ────────────────────────────────

  Future<DareModel?> markChallengeComplete({
    required String dareId,
    required String userId,
    required int xpEarned,
  }) async {
    final docRef = _col.doc(dareId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      final idx = members.indexWhere((m) => m['userId'] == userId);
      if (idx < 0) return;
      final updated = Map<String, dynamic>.from(members[idx]);
      updated['completedChallenges'] =
          ((updated['completedChallenges'] as num?) ?? 0) + 1;
      updated['totalXpEarned'] =
          ((updated['totalXpEarned'] as num?) ?? 0) + xpEarned;
      members[idx] = updated;
      tx.update(docRef, {'members': members});
    });
    return getById(dareId);
  }

  // ── Scratch cards ─────────────────────────────────────────────────────────

  Future<ScratchCard> createScratchCard({
    required String userId,
    required String dareId,
    required String dareTitle,
    required String challengeId,
    required String challengeTitle,
    required ScratchRewardType rewardType,
    required int xpAmount,
    MedalType? medal,
    String? badgeTitle,
    double? multiplier,
  }) async {
    final docRef = _userCol(userId).doc();
    final data = {
      'userId': userId,
      'dareId': dareId,
      'dareTitle': dareTitle,
      'challengeId': challengeId,
      'challengeTitle': challengeTitle,
      'rewardType': rewardType.name,
      'xpAmount': xpAmount,
      'medal': medal?.name,
      'badgeTitle': badgeTitle,
      'multiplier': multiplier,
      'isScratched': false,
      'earnedAt': FieldValue.serverTimestamp(),
      'scratchedAt': null,
    };
    await docRef.set(data);
    final snap = await docRef.get();
    return ScratchCard.fromFirestore(snap);
  }

  Future<void> scratchCard({
    required String userId,
    required String cardId,
  }) async {
    await _userCol(userId).doc(cardId).update({
      'isScratched': true,
      'scratchedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ScratchCard>> watchScratchCards(String userId) {
    return _userCol(userId)
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ScratchCard.fromFirestore(d)).toList(),
        );
  }

  // ── Medals ────────────────────────────────────────────────────────────────

  Future<DareMedalRecord> awardMedal({
    required String userId,
    required MedalType medalType,
    required String dareId,
    required String dareTitle,
    required String challengeTitle,
    String? bannerUrl,
  }) async {
    final docRef = _medalsCol(userId).doc();
    final data = {
      'medalType': medalType.name,
      'dareId': dareId,
      'dareTitle': dareTitle,
      'challengeTitle': challengeTitle,
      'bannerUrl': bannerUrl,
      'earnedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
    final snap = await docRef.get();
    return DareMedalRecord.fromFirestore(snap);
  }

  Stream<List<DareMedalRecord>> watchMedals(String userId) {
    return _medalsCol(userId)
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => DareMedalRecord.fromFirestore(d)).toList(),
        );
  }

  Future<List<DareMedalRecord>> getMedals(String userId) async {
    final snap = await _medalsCol(userId)
        .orderBy('earnedAt', descending: true)
        .get();
    return snap.docs.map((d) => DareMedalRecord.fromFirestore(d)).toList();
  }

  // ── Like a dare ────────────────────────────────────────────────────────────

  Future<void> toggleLike({
    required String dareId,
    required String userId,
  }) async {
    final docRef = _col.doc(dareId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final likedBy = List<String>.from(snap.data()!['likedBy'] ?? []);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        tx.update(docRef, {
          'likedBy': likedBy,
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        likedBy.add(userId);
        tx.update(docRef, {
          'likedBy': likedBy,
          'likeCount': FieldValue.increment(1),
        });
      }
    });
  }

  // ── Remove participant ────────────────────────────────────────────────────

  Future<DareModel?> removeMember({
    required String dareId,
    required String targetUserId,
  }) async {
    final docRef = _col.doc(dareId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      final memberIds = List<String>.from(data['memberIds'] ?? []);
      final removed = List<String>.from(data['removedUserIds'] ?? []);
      members.removeWhere((m) => m['userId'] == targetUserId);
      memberIds.remove(targetUserId);
      if (!removed.contains(targetUserId)) removed.add(targetUserId);
      tx.update(docRef, {
        'members': members,
        'memberIds': memberIds,
        'removedUserIds': removed,
      });
    });
    return getById(dareId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final firestoreDareServiceProvider = Provider<FirestoreDareService>(
  (_) => FirestoreDareService(),
);

// Generate a random scratch card reward
ScratchCard generateScratchCardReward({
  required String userId,
  required String dareId,
  required String dareTitle,
  required String challengeId,
  required String challengeTitle,
  required MedalType baseMedal,
}) {
  final rng = Random();
  final roll = rng.nextInt(100);

  ScratchRewardType rewardType;
  int xp;
  MedalType? medal;
  double? multiplier;

  if (roll < 40) {
    // 40% — XP reward
    rewardType = ScratchRewardType.xp;
    xp = [50, 100, 150, 200][rng.nextInt(4)];
  } else if (roll < 65) {
    // 25% — medal
    rewardType = ScratchRewardType.medal;
    medal = baseMedal;
    xp = 0;
  } else if (roll < 80) {
    // 15% — double XP multiplier
    rewardType = ScratchRewardType.multiplier;
    xp = 100;
    multiplier = 2.0;
  } else if (roll < 90) {
    // 10% — badge
    rewardType = ScratchRewardType.badge;
    xp = 50;
  } else {
    // 10% — nothing (common card)
    rewardType = ScratchRewardType.nothing;
    xp = 10;
  }

  return ScratchCard(
    id: '',
    userId: userId,
    dareId: dareId,
    dareTitle: dareTitle,
    challengeId: challengeId,
    challengeTitle: challengeTitle,
    rewardType: rewardType,
    xpAmount: xp,
    medal: medal,
    multiplier: multiplier,
    earnedAt: DateTime.now(),
  );
}
