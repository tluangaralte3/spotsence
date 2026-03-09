import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bucket_list_models.dart';
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
      final joinCode = _svc.generateJoinCode();
      final hostMember = BucketMember(
        userId: hostId,
        userName: hostName,
        userPhoto: hostPhoto,
        role: MemberRole.host,
        status: MemberStatus.approved,
        joinedAt: DateTime.now(),
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
