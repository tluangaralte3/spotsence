import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/gamification_controller.dart';
import '../models/bucket_list_models.dart';
import '../models/gamification_models.dart';
import '../services/firestore_bucket_list_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class BucketListState {
  final List<BucketListModel> myLists;
  final List<BucketListModel> publicLists;
  final bool isLoading;
  final bool isLoadingPublic;
  final String? error;

  const BucketListState({
    this.myLists = const [],
    this.publicLists = const [],
    this.isLoading = false,
    this.isLoadingPublic = false,
    this.error,
  });

  BucketListState copyWith({
    List<BucketListModel>? myLists,
    List<BucketListModel>? publicLists,
    bool? isLoading,
    bool? isLoadingPublic,
    String? error,
  }) => BucketListState(
    myLists: myLists ?? this.myLists,
    publicLists: publicLists ?? this.publicLists,
    isLoading: isLoading ?? this.isLoading,
    isLoadingPublic: isLoadingPublic ?? this.isLoadingPublic,
    error: error,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class BucketListController extends Notifier<BucketListState> {
  FirestoreBucketListService get _svc =>
      ref.read(firestoreBucketListServiceProvider);

  @override
  BucketListState build() {
    return const BucketListState();
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadMyLists(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final lists = await _svc.getMyLists(userId);
      state = state.copyWith(isLoading: false, myLists: lists);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPublicLists() async {
    state = state.copyWith(isLoadingPublic: true);
    try {
      final lists = await _svc.getPublicLists();
      state = state.copyWith(isLoadingPublic: false, publicLists: lists);
    } catch (e) {
      state = state.copyWith(isLoadingPublic: false, error: e.toString());
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<BucketListModel?> create({
    required String title,
    required String description,
    required String bannerUrl,
    required BucketCategory category,
    String? customCategory,
    required BucketVisibility visibility,
    required int maxMembers,
    required String hostId,
    required String hostName,
    String? hostPhoto,
    int xpReward = 100,
    String? challengeTitle,
  }) async {
    try {
      // ── Cap check (free limit = kFreeRoomCap) ─────────────────────
      final hostedCount = await _svc.countHostedRooms(hostId);
      if (hostedCount >= kFreeRoomCap) {
        state = state.copyWith(
          error: 'You have reached the free room limit ($kFreeRoomCap rooms). '
              'Upgrade to MezoPro to create more.',
        );
        return null;
      }

      final joinCode = _svc.generateJoinCode();
      final hostMember = BucketMember(
        userId: hostId,
        userName: hostName,
        userPhoto: hostPhoto,
        role: MemberRole.host,
        status: MemberStatus.approved,
        joinedAt: DateTime.now(),
        approvedAt: DateTime.now(),
      );
      final model = BucketListModel(
        id: '',
        title: title,
        description: description,
        bannerUrl: bannerUrl,
        category: category,
        customCategory: customCategory,
        visibility: visibility,
        maxMembers: maxMembers,
        joinCode: joinCode,
        hostId: hostId,
        hostName: hostName,
        hostPhoto: hostPhoto,
        items: const [],
        members: [hostMember],
        createdAt: DateTime.now(),
        xpReward: xpReward,
        challengeTitle: challengeTitle,
      );
      final created = await _svc.create(model);
      state = state.copyWith(myLists: [created, ...state.myLists]);
      // ── Gamification ────────────────────────────────────────────────
      await ref
          .read(gamificationControllerProvider.notifier)
          .award(XpAction.createBucketList, relatedId: created.id);
      await ref
          .read(gamificationControllerProvider.notifier)
          .incrementCounter('bucketListsCreated');
      return created;
    } catch (e, st) {
      debugPrint('BucketListController.create ERROR: $e');
      debugPrint('$st');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // ── Add item ──────────────────────────────────────────────────────────────

  Future<void> addItem(String listId, BucketItem item) async {
    try {
      final idx = state.myLists.indexWhere((l) => l.id == listId);
      if (idx < 0) return;
      final updated = List<BucketItem>.from(state.myLists[idx].items)
        ..add(item);
      await _svc.update(listId, {
        'items': updated.map((i) => i.toJson()).toList(),
      });
      _updateLocal(listId, (l) {
        return BucketListModel(
          id: l.id,
          title: l.title,
          description: l.description,
          bannerUrl: l.bannerUrl,
          category: l.category,
          customCategory: l.customCategory,
          visibility: l.visibility,
          maxMembers: l.maxMembers,
          joinCode: l.joinCode,
          hostId: l.hostId,
          hostName: l.hostName,
          hostPhoto: l.hostPhoto,
          items: updated,
          members: l.members,
          joinRequests: l.joinRequests,
          createdAt: l.createdAt,
          completedAt: l.completedAt,
          xpReward: l.xpReward,
          badges: l.badges,
          challengeTitle: l.challengeTitle,
        );
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Toggle item ───────────────────────────────────────────────────────────

  Future<void> toggleItem({
    required String listId,
    required int itemIndex,
    required bool newChecked,
    required String userId,
    required String userName,
  }) async {
    try {
      await _svc.toggleItem(
        listId: listId,
        itemIndex: itemIndex,
        newChecked: newChecked,
        userId: userId,
        userName: userName,
      );
      // Refresh from Firestore
      final fresh = await _svc.getById(listId);
      if (fresh != null) _updateLocal(listId, (_) => fresh);
      // ── Gamification ────────────────────────────────────────────────
      if (newChecked) {
        await ref
            .read(gamificationControllerProvider.notifier)
            .award(XpAction.completeBucketItem, relatedId: listId);
        await ref
            .read(gamificationControllerProvider.notifier)
            .incrementCounter('bucketItemsCompleted');
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Join by code ──────────────────────────────────────────────────────────

  /// Returns the found list (or null + sets error).
  Future<BucketListModel?> lookupJoinCode(String code) async {
    try {
      return await _svc.getByJoinCode(code);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> requestJoin({
    required String listId,
    required String userId,
    required String userName,
    String? userPhoto,
    required bool isPublic,
  }) async {
    try {
      await _svc.requestJoin(
        listId: listId,
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        isPublic: isPublic,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> approveJoin({
    required String listId,
    required String userId,
  }) async {
    try {
      await _svc.approveJoin(listId: listId, userId: userId);
      final fresh = await _svc.getById(listId);
      if (fresh != null) _updateLocal(listId, (_) => fresh);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> declineJoin({
    required String listId,
    required String userId,
  }) async {
    try {
      await _svc.declineJoin(listId: listId, userId: userId);
      final fresh = await _svc.getById(listId);
      if (fresh != null) _updateLocal(listId, (_) => fresh);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> leave({required String listId, required String userId}) async {
    try {
      await _svc.leave(listId: listId, userId: userId);
      state = state.copyWith(
        myLists: state.myLists.where((l) => l.id != listId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> delete(String listId) async {
    try {
      await _svc.delete(listId);
      state = state.copyWith(
        myLists: state.myLists.where((l) => l.id != listId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update editable fields of a bucket list (host only).
  Future<bool> updateList({
    required String listId,
    required String title,
    required String description,
    required String bannerUrl,
    required BucketCategory category,
    String? customCategory,
    required BucketVisibility visibility,
    required int maxMembers,
    required int xpReward,
    String? challengeTitle,
  }) async {
    try {
      final fields = <String, dynamic>{
        'title': title,
        'description': description,
        'bannerUrl': bannerUrl,
        'category': category.name,
        'customCategory': customCategory,
        'visibility': visibility.name,
        'maxMembers': maxMembers,
        'xpReward': xpReward,
        'challengeTitle': challengeTitle,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      await _svc.update(listId, fields);
      _updateLocal(
        listId,
        (l) => l.copyWith(
          title: title,
          description: description,
          bannerUrl: bannerUrl,
          category: category,
          customCategory: customCategory,
          visibility: visibility,
          maxMembers: maxMembers,
          xpReward: xpReward,
          challengeTitle: challengeTitle,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _updateLocal(
    String listId,
    BucketListModel Function(BucketListModel) fn,
  ) {
    final idx = state.myLists.indexWhere((l) => l.id == listId);
    if (idx >= 0) {
      final updated = List<BucketListModel>.from(state.myLists);
      updated[idx] = fn(updated[idx]);
      state = state.copyWith(myLists: updated);
    } else {
      // also check publicLists
      final pidx = state.publicLists.indexWhere((l) => l.id == listId);
      if (pidx >= 0) {
        final updated = List<BucketListModel>.from(state.publicLists);
        updated[pidx] = fn(updated[pidx]);
        state = state.copyWith(publicLists: updated);
      }
    }
  }

  void clearError() => state = state.copyWith(error: null);

  // ── Room cap check ────────────────────────────────────────────────────────

  Future<bool> canCreateRoom(String userId) async {
    try {
      final count = await _svc.countHostedRooms(userId);
      return count < kFreeRoomCap;
    } catch (_) {
      return true;
    }
  }

  // ── Strike member ─────────────────────────────────────────────────────────

  Future<void> strikeMember({
    required String listId,
    required String targetUserId,
  }) async {
    try {
      final autoRemoved = await _svc.strikeMember(
        listId: listId,
        targetUserId: targetUserId,
      );
      final fresh = await _svc.getById(listId);
      if (fresh != null) _updateLocal(listId, (_) => fresh);
      if (autoRemoved) {
        state = state.copyWith(
          error: 'Member reached 3 strikes and was automatically removed.',
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Remove member ─────────────────────────────────────────────────────────

  Future<void> removeMember({
    required String listId,
    required String targetUserId,
  }) async {
    try {
      await _svc.removeMember(listId: listId, targetUserId: targetUserId);
      final fresh = await _svc.getById(listId);
      if (fresh != null) _updateLocal(listId, (_) => fresh);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Contact sharing ───────────────────────────────────────────────────────

  Future<void> setContactShared({
    required String listId,
    required String userId,
    required bool shared,
  }) async {
    try {
      await _svc.setContactShared(
        listId: listId,
        userId: userId,
        shared: shared,
      );
      final fresh = await _svc.getById(listId);
      if (fresh != null) _updateLocal(listId, (_) => fresh);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Poke ─────────────────────────────────────────────────────────────────

  Future<String?> poke({
    required String listId,
    required String fromId,
    required String fromName,
    required String toId,
    required String toName,
  }) async {
    try {
      await _svc.poke(
        listId: listId,
        fromId: fromId,
        fromName: fromName,
        toId: toId,
        toName: toName,
      );
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // ── Report member ─────────────────────────────────────────────────────────

  Future<void> reportMember({
    required String listId,
    required String reporterId,
    required String reporterName,
    required String targetId,
    required String targetName,
    required String reason,
  }) async {
    try {
      await _svc.reportMember(
        listId: listId,
        reporterId: reporterId,
        reporterName: reporterName,
        targetId: targetId,
        targetName: targetName,
        reason: reason,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final bucketListControllerProvider =
    NotifierProvider<BucketListController, BucketListState>(
      BucketListController.new,
    );

/// Watch a single bucket list live from Firestore.
final bucketListDetailProvider =
    StreamProvider.family<BucketListModel?, String>((ref, id) {
      return ref.read(firestoreBucketListServiceProvider).watchById(id);
    });

/// Stream pokes received by [userId] inside [listId].
/// Param is '$listId|$userId'.
final roomPokesProvider =
    StreamProvider.family<List<RoomPokeModel>, String>((ref, param) {
      final parts = param.split('|');
      if (parts.length != 2) return const Stream.empty();
      return ref
          .read(firestoreBucketListServiceProvider)
          .watchPokesReceived(listId: parts[0], userId: parts[1]);
    });

/// Stream reports for a room (host only). Param is listId.
final roomReportsProvider =
    StreamProvider.family<List<RoomReportModel>, String>((ref, listId) {
      return ref
          .read(firestoreBucketListServiceProvider)
          .watchReports(listId);
    });

/// Stream all rooms hosted by [userId] for the management screen.
final hostedRoomsProvider =
    StreamProvider.family<List<BucketListModel>, String>((ref, userId) {
      return ref
          .read(firestoreBucketListServiceProvider)
          .watchHostedRooms(userId);
    });
