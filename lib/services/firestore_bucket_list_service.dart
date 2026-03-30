import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bucket_list_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreBucketListService
// Collection: bucketLists
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreBucketListService {
  final FirebaseFirestore _db;

  FirestoreBucketListService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('bucketLists');

  // ── Join code ─────────────────────────────────────────────────────────────

  /// Generates a unique 6-char alphanumeric code.
  String generateJoinCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<BucketListModel> create(BucketListModel model) async {
    try {
      final ref = _col.doc();
      final data = model.toJson();
      data['id'] = ref.id;
      // Override with server-side timestamps (valid at top level, not in arrays)
      data['createdAt'] = FieldValue.serverTimestamp();
      data['completedAt'] = null;
      // Denormalized memberIds for efficient arrayContains queries
      data['memberIds'] = model.members
          .where((m) => m.isApproved)
          .map((m) => m.userId)
          .toList();
      await ref.set(data);
      final snap = await ref.get();
      return BucketListModel.fromFirestore(snap);
    } catch (e, st) {
      debugPrint('FirestoreBucketListService.create ERROR: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  // ── Read — user's own lists ───────────────────────────────────────────────

  /// All lists where the user is host or approved member.
  Future<List<BucketListModel>> getMyLists(String userId) async {
    // Lists hosted by the user
    final hosted = await _col
        .where('hostId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    // Lists where the user is an approved member (via denormalized memberIds)
    // Simple single-field arrayContains — no composite index needed
    final joinedSnap = await _col
        .where('memberIds', arrayContains: userId)
        .get();

    final ids = <String>{};
    final lists = <BucketListModel>[];

    for (final doc in hosted.docs) {
      if (ids.add(doc.id)) {
        lists.add(BucketListModel.fromFirestore(doc));
      }
    }
    // Add joined lists, skipping any the user is already the host of
    for (final doc in joinedSnap.docs) {
      final hostId = (doc.data())['hostId']?.toString() ?? '';
      if (hostId != userId && ids.add(doc.id)) {
        lists.add(BucketListModel.fromFirestore(doc));
      }
    }
    lists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return lists;
  }

  /// Public lists (for Discover tab)
  Future<List<BucketListModel>> getPublicLists({int limit = 30}) async {
    final snap = await _col
        .where('visibility', isEqualTo: 'public')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => BucketListModel.fromFirestore(d)).toList();
  }

  // ── Read — single ─────────────────────────────────────────────────────────

  Future<BucketListModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return BucketListModel.fromFirestore(doc);
  }

  /// Look up a list by its join code.
  Future<BucketListModel?> getByJoinCode(String code) async {
    final snap = await _col
        .where('joinCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return BucketListModel.fromFirestore(snap.docs.first);
  }

  // ── Live stream ───────────────────────────────────────────────────────────

  Stream<BucketListModel?> watchById(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BucketListModel.fromFirestore(doc);
    });
  }

  // ── Join flow ─────────────────────────────────────────────────────────────

  /// Public list: immediately approved (but host must still accept if `requiresApproval` is set).
  /// This implementation: public lists are immediately approved; private need host approval.
  Future<void> requestJoin({
    required String listId,
    required String userId,
    required String userName,
    String? userPhoto,
    required bool isPublic,
  }) async {
    final docRef = _col.doc(listId);
    final member = {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'role': 'member',
      'status': 'pending', // host must always approve
      'joinedAt': DateTime.now().toIso8601String(),
    };

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw Exception('List not found');
      final data = snap.data()!;

      // Check already member
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      if (members.any((m) => m['userId'] == userId)) return;

      final requests = List<Map<String, dynamic>>.from(
        data['joinRequests'] ?? [],
      );
      if (requests.any((r) => r['userId'] == userId)) return;

      tx.update(docRef, {
        'joinRequests': FieldValue.arrayUnion([member]),
      });
    });
  }

  /// Host approves a join request.
  Future<void> approveJoin({
    required String listId,
    required String userId,
  }) async {
    final docRef = _col.doc(listId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) throw Exception('List not found');
      final data = snap.data()!;

      final requests = List<Map<String, dynamic>>.from(
        data['joinRequests'] ?? [],
      );
      final req = requests.firstWhere(
        (r) => r['userId'] == userId,
        orElse: () => {},
      );
      if (req.isEmpty) return;

      final approvedMember = {...req, 'status': 'approved'};

      // Remove from requests, add to members + memberIds
      tx.update(docRef, {
        'joinRequests': FieldValue.arrayRemove([req]),
        'members': FieldValue.arrayUnion([approvedMember]),
        'memberIds': FieldValue.arrayUnion([userId]),
      });
    });
  }

  /// Host declines a join request.
  Future<void> declineJoin({
    required String listId,
    required String userId,
  }) async {
    final docRef = _col.doc(listId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final requests = List<Map<String, dynamic>>.from(
        data['joinRequests'] ?? [],
      );
      final req = requests.firstWhere(
        (r) => r['userId'] == userId,
        orElse: () => {},
      );
      if (req.isEmpty) return;
      tx.update(docRef, {
        'joinRequests': FieldValue.arrayRemove([req]),
      });
    });
  }

  // ── Check / uncheck item ─────────────────────────────────────────────────

  Future<void> toggleItem({
    required String listId,
    required int itemIndex,
    required bool newChecked,
    required String userId,
    required String userName,
  }) async {
    final docRef = _col.doc(listId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      if (itemIndex >= items.length) return;
      items[itemIndex] = {
        ...items[itemIndex],
        'isChecked': newChecked,
        'checkedByUserId': newChecked ? userId : null,
        'checkedByUserName': newChecked ? userName : null,
        'checkedAt': newChecked ? DateTime.now().toIso8601String() : null,
      };
      final Map<String, dynamic> update = {'items': items};
      // If all checked → mark completed with top-level FieldValue (valid here)
      if (newChecked && items.every((i) => i['isChecked'] == true)) {
        update['completedAt'] = FieldValue.serverTimestamp();
      }
      tx.update(docRef, update);
    });
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> update(String listId, Map<String, dynamic> fields) async {
    await _col.doc(listId).update(fields);
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> delete(String listId) async {
    await _col.doc(listId).delete();
  }

  // ── Leave ─────────────────────────────────────────────────────────────────

  Future<void> leave({required String listId, required String userId}) async {
    final docRef = _col.doc(listId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      final updated = members.where((m) => m['userId'] != userId).toList();
      tx.update(docRef, {
        'members': updated,
        'memberIds': FieldValue.arrayRemove([userId]),
      });
    });
  }

  // ── Room cap ─────────────────────────────────────────────────────────────

  /// Returns how many rooms the user currently hosts.
  Future<int> countHostedRooms(String userId) async {
    final snap = await _col
        .where('hostId', isEqualTo: userId)
        .count()
        .get();
    return snap.count ?? 0;
  }

  // ── Strike member ─────────────────────────────────────────────────────────

  /// Adds one strike to [targetUserId]. If strikes reach 3 the member is
  /// automatically removed from the room.
  Future<bool> strikeMember({
    required String listId,
    required String targetUserId,
  }) async {
    bool autoRemoved = false;
    final docRef = _col.doc(listId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      final idx = members.indexWhere((m) => m['userId'] == targetUserId);
      if (idx < 0) return;

      final newStrikes = ((members[idx]['strikes'] as num?)?.toInt() ?? 0) + 1;
      members[idx] = {...members[idx], 'strikes': newStrikes};

      final Map<String, dynamic> update = {'members': members};

      if (newStrikes >= 3) {
        // Auto-remove
        final removed = members.where((m) => m['userId'] != targetUserId).toList();
        update['members'] = removed;
        update['memberIds'] = FieldValue.arrayRemove([targetUserId]);
        update['removedUserIds'] = FieldValue.arrayUnion([targetUserId]);
        autoRemoved = true;
      }
      tx.update(docRef, update);
    });
    return autoRemoved;
  }

  // ── Remove member ─────────────────────────────────────────────────────────

  Future<void> removeMember({
    required String listId,
    required String targetUserId,
  }) async {
    final docRef = _col.doc(listId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      final updated = members.where((m) => m['userId'] != targetUserId).toList();
      tx.update(docRef, {
        'members': updated,
        'memberIds': FieldValue.arrayRemove([targetUserId]),
        'removedUserIds': FieldValue.arrayUnion([targetUserId]),
      });
    });
  }

  // ── Contact sharing ───────────────────────────────────────────────────────

  /// Toggles [userId]'s contactShared flag inside this room.
  Future<void> setContactShared({
    required String listId,
    required String userId,
    required bool shared,
  }) async {
    final docRef = _col.doc(listId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final members = List<Map<String, dynamic>>.from(data['members'] ?? []);
      final idx = members.indexWhere((m) => m['userId'] == userId);
      if (idx < 0) return;
      members[idx] = {...members[idx], 'contactShared': shared};
      tx.update(docRef, {'members': members});
    });
  }

  // ── Pokes (subcollection) ─────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _pokesCol(String listId) =>
      _col.doc(listId).collection('pokes');

  /// Send a poke. Enforces a 24-hour cooldown per sender→receiver pair
  /// by checking the most recent poke document. Throws if on cooldown.
  Future<void> poke({
    required String listId,
    required String fromId,
    required String fromName,
    required String toId,
    required String toName,
  }) async {
    // Check cooldown — one poke per sender-receiver pair per 24 h
    final recent = await _pokesCol(listId)
        .where('fromId', isEqualTo: fromId)
        .where('toId', isEqualTo: toId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (recent.docs.isNotEmpty) {
      final lastTs = recent.docs.first.data()['timestamp'];
      DateTime? lastPoke;
      if (lastTs is Timestamp) {
        lastPoke = lastTs.toDate();
      } else if (lastTs is String) {
        lastPoke = DateTime.tryParse(lastTs);
      }
      if (lastPoke != null &&
          DateTime.now().difference(lastPoke).inHours < 24) {
        throw Exception('You can only poke once every 24 hours');
      }
    }

    await _pokesCol(listId).add({
      'fromId': fromId,
      'fromName': fromName,
      'toId': toId,
      'toName': toName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of recent pokes received by [userId] in this room (last 20).
  Stream<List<RoomPokeModel>> watchPokesReceived({
    required String listId,
    required String userId,
  }) {
    return _pokesCol(listId)
        .where('toId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => RoomPokeModel.fromFirestore(d))
              .toList(),
        );
  }

  // ── Reports (subcollection) ───────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _reportsCol(String listId) =>
      _col.doc(listId).collection('reports');

  Future<void> reportMember({
    required String listId,
    required String reporterId,
    required String reporterName,
    required String targetId,
    required String targetName,
    required String reason,
  }) async {
    await _reportsCol(listId).add({
      'reporterId': reporterId,
      'reporterName': reporterName,
      'targetId': targetId,
      'targetName': targetName,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of reports for a room (host only — sorted newest first, max 50).
  Stream<List<RoomReportModel>> watchReports(String listId) {
    return _reportsCol(listId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => RoomReportModel.fromFirestore(d))
              .toList(),
        );
  }

  // ── Stream hosted rooms ───────────────────────────────────────────────────

  Stream<List<BucketListModel>> watchHostedRooms(String userId) {
    return _col
        .where('hostId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => BucketListModel.fromFirestore(d)).toList(),
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final firestoreBucketListServiceProvider = Provider<FirestoreBucketListService>(
  (_) => FirestoreBucketListService(),
);
