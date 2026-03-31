import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dare_models.dart';
import '../services/firestore_dare_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class DareState {
  final List<DareModel> myDares;
  final List<DareModel> publicDares;
  final bool isLoading;
  final bool isLoadingPublic;
  final String? error;

  const DareState({
    this.myDares = const [],
    this.publicDares = const [],
    this.isLoading = false,
    this.isLoadingPublic = false,
    this.error,
  });

  DareState copyWith({
    List<DareModel>? myDares,
    List<DareModel>? publicDares,
    bool? isLoading,
    bool? isLoadingPublic,
    String? error,
  }) => DareState(
    myDares: myDares ?? this.myDares,
    publicDares: publicDares ?? this.publicDares,
    isLoading: isLoading ?? this.isLoading,
    isLoadingPublic: isLoadingPublic ?? this.isLoadingPublic,
    error: error,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────

class DareController extends Notifier<DareState> {
  FirestoreDareService get _svc => ref.read(firestoreDareServiceProvider);

  @override
  DareState build() => const DareState();

  // ── Load ──────────────────────────────────────────────────────────────

  Future<void> loadMyDares(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dares = await _svc.getMyDares(userId);
      state = state.copyWith(isLoading: false, myDares: dares);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPublicDares() async {
    state = state.copyWith(isLoadingPublic: true);
    try {
      final dares = await _svc.getPublicDares();
      state = state.copyWith(isLoadingPublic: false, publicDares: dares);
    } catch (e) {
      state = state.copyWith(isLoadingPublic: false, error: e.toString());
    }
  }

  // ── Create ────────────────────────────────────────────────────────────

  Future<DareModel?> create({
    required String title,
    required String description,
    String? bannerUrl,
    required DareCategory category,
    String? customCategory,
    required DareVisibility visibility,
    required int maxParticipants,
    required String creatorId,
    required String creatorName,
    String? creatorPhoto,
    DateTime? deadline,
    int xpReward = 100,
    bool requiresProof = true,
    List<String> tags = const [],
  }) async {
    try {
      // Check dare cap
      final canCreate = await canCreateDare(creatorId);
      if (!canCreate) {
        state = state.copyWith(
          error:
              'You have reached the free dare limit ($kFreeDareCap). Please complete or delete an existing dare.',
        );
        return null;
      }

      final joinCode = _svc.generateJoinCode();
      final creator = DareMember(
        userId: creatorId,
        userName: creatorName,
        userPhoto: creatorPhoto,
        role: DareMemberRole.creator,
        status: DareMemberStatus.approved,
        joinedAt: DateTime.now(),
        approvedAt: DateTime.now(),
      );

      final model = DareModel(
        id: '',
        title: title,
        description: description,
        bannerUrl: bannerUrl,
        category: category,
        customCategory: customCategory,
        visibility: visibility,
        maxParticipants: maxParticipants,
        joinCode: joinCode,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorPhoto: creatorPhoto,
        challenges: const [],
        members: [creator],
        createdAt: DateTime.now(),
        deadline: deadline,
        xpReward: xpReward,
        requiresProof: requiresProof,
        tags: tags,
      );

      final created = await _svc.create(model);
      state = state.copyWith(myDares: [created, ...state.myDares]);
      return created;
    } catch (e, st) {
      debugPrint('DareController.create error: $e\n$st');
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  // ── Add challenge ─────────────────────────────────────────────────────

  Future<void> addChallenge(String dareId, DareChallenge challenge) async {
    try {
      await _svc.addChallenge(dareId, challenge);
      // refresh the dare locally
      final fresh = await _svc.getById(dareId);
      if (fresh != null) _updateLocal(dareId, (_) => fresh);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Update challenge ───────────────────────────────────────────────────

  Future<void> updateChallenge(
    String dareId,
    DareChallenge challenge,
  ) async {
    try {
      await _svc.updateChallenge(dareId, challenge);
      final fresh = await _svc.getById(dareId);
      if (fresh != null) _updateLocal(dareId, (_) => fresh);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Join ──────────────────────────────────────────────────────────────

  Future<DareModel?> lookupJoinCode(String code) async {
    try {
      return await _svc.getByJoinCode(code);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> requestJoin({
    required String dareId,
    required String userId,
    required String userName,
    String? userPhoto,
    required bool isPublic,
  }) async {
    try {
      await _svc.requestJoin(
        dareId: dareId,
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        isPublic: isPublic,
      );
      // myDaresStreamProvider handles the live update automatically.
      // We do NOT mutate state here to avoid rebuilding the widget tree
      // while a dialog dismiss animation is still running.
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> approveJoin({
    required String dareId,
    required String userId,
  }) async {
    try {
      final fresh = await _svc.approveJoin(dareId: dareId, userId: userId);
      if (fresh != null) _updateLocal(dareId, (_) => fresh);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> declineJoin({
    required String dareId,
    required String userId,
  }) async {
    try {
      final fresh = await _svc.declineJoin(dareId: dareId, userId: userId);
      if (fresh != null) _updateLocal(dareId, (_) => fresh);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> leave({
    required String dareId,
    required String userId,
  }) async {
    try {
      await _svc.leave(dareId: dareId, userId: userId);
      state = state.copyWith(
        myDares: state.myDares.where((d) => d.id != dareId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> delete(String dareId) async {
    try {
      await _svc.delete(dareId);
      state = state.copyWith(
        myDares: state.myDares.where((d) => d.id != dareId).toList(),
        publicDares: state.publicDares.where((d) => d.id != dareId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> updateDare({
    required String dareId,
    required String title,
    required String description,
    String? bannerUrl,
    required DareCategory category,
    String? customCategory,
    required DareVisibility visibility,
    required int maxParticipants,
    int? xpReward,
    DateTime? deadline,
    bool? requiresProof,
    List<String>? tags,
  }) async {
    try {
      await _svc.update(dareId, {
        'title': title,
        'description': description,
        'bannerUrl': bannerUrl,
        'category': category.name,
        'customCategory': customCategory,
        'visibility': visibility.name,
        'maxParticipants': maxParticipants,
        if (xpReward != null) 'xpReward': xpReward,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
        if (requiresProof != null) 'requiresProof': requiresProof,
        if (tags != null) 'tags': tags,
      });
      final fresh = await _svc.getById(dareId);
      if (fresh != null) _updateLocal(dareId, (_) => fresh);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Proof ─────────────────────────────────────────────────────────────

  Future<ProofSubmission?> submitProof({
    required String dareId,
    required String userId,
    required String userName,
    String? userPhoto,
    required String challengeId,
    required List<String> imageUrls,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    try {
      return await _svc.submitProof(
        dareId: dareId,
        userId: userId,
        userName: userName,
        userPhoto: userPhoto,
        challengeId: challengeId,
        imageUrls: imageUrls,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> reviewProof({
    required String dareId,
    required String proofId,
    required ProofStatus status,
    String? reviewNote,
    // If approved — award scratch card & medal to participant
    String? participantUserId,
    String? challengeTitle,
    String? dareTitle,
    MedalType? medalType,
    int? xpReward,
    String? bannerUrl,
    String? challengeId,
  }) async {
    try {
      await _svc.reviewProof(
        dareId: dareId,
        proofId: proofId,
        status: status,
        reviewNote: reviewNote,
      );

      if (status == ProofStatus.approved &&
          participantUserId != null &&
          challengeTitle != null &&
          dareTitle != null) {
        // Award scratch card
        final card = generateScratchCardReward(
          userId: participantUserId,
          dareId: dareId,
          dareTitle: dareTitle,
          challengeId: challengeId ?? '',
          challengeTitle: challengeTitle,
          baseMedal: medalType ?? MedalType.bronze,
        );
        await _svc.createScratchCard(
          userId: participantUserId,
          dareId: dareId,
          dareTitle: dareTitle,
          challengeId: challengeId ?? '',
          challengeTitle: challengeTitle,
          rewardType: card.rewardType,
          xpAmount: card.xpAmount,
          medal: card.medal,
          multiplier: card.multiplier,
        );

        // Award medal
        if (medalType != null) {
          await _svc.awardMedal(
            userId: participantUserId,
            medalType: medalType,
            dareId: dareId,
            dareTitle: dareTitle,
            challengeTitle: challengeTitle,
            bannerUrl: bannerUrl,
          );
        }

        // Update member progress
        await _svc.markChallengeComplete(
          dareId: dareId,
          userId: participantUserId,
          xpEarned: xpReward ?? 100,
        );

        final fresh = await _svc.getById(dareId);
        if (fresh != null) _updateLocal(dareId, (_) => fresh);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Scratch card ──────────────────────────────────────────────────────

  Future<void> scratchCard({
    required String userId,
    required String cardId,
  }) async {
    try {
      await _svc.scratchCard(userId: userId, cardId: cardId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Remove member ─────────────────────────────────────────────────────

  Future<void> removeMember({
    required String dareId,
    required String targetUserId,
  }) async {
    try {
      final fresh = await _svc.removeMember(
        dareId: dareId,
        targetUserId: targetUserId,
      );
      if (fresh != null) _updateLocal(dareId, (_) => fresh);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Like ──────────────────────────────────────────────────────────────

  Future<void> toggleLike({
    required String dareId,
    required String userId,
  }) async {
    try {
      await _svc.toggleLike(dareId: dareId, userId: userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // ── Cap check ─────────────────────────────────────────────────────────

  Future<bool> canCreateDare(String userId) async {
    try {
      final count = await _svc.countCreatedDares(userId);
      return count < kFreeDareCap;
    } catch (_) {
      return true;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _updateLocal(String dareId, DareModel Function(DareModel) fn) {
    final idx = state.myDares.indexWhere((d) => d.id == dareId);
    if (idx >= 0) {
      final updated = List<DareModel>.from(state.myDares);
      updated[idx] = fn(updated[idx]);
      state = state.copyWith(myDares: updated);
    } else {
      final pubIdx = state.publicDares.indexWhere((d) => d.id == dareId);
      if (pubIdx >= 0) {
        final updated = List<DareModel>.from(state.publicDares);
        updated[pubIdx] = fn(updated[pubIdx]);
        state = state.copyWith(publicDares: updated);
      }
    }
  }

  void clearError() => state = state.copyWith(error: null);
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final dareControllerProvider = NotifierProvider<DareController, DareState>(
  DareController.new,
);

/// Watch a single dare live from Firestore.
final dareDetailProvider =
    StreamProvider.family<DareModel?, String>((ref, id) {
  return ref.read(firestoreDareServiceProvider).watchById(id);
});

/// Live stream of dares the current user created, joined, or has a pending request for.
final myDaresStreamProvider =
    StreamProvider.autoDispose.family<List<DareModel>, String>((ref, userId) {
  return ref.read(firestoreDareServiceProvider).watchMyDares(userId);
});

/// Stream proofs for a dare (creator view).
final dareProofsProvider =
    StreamProvider.family<List<ProofSubmission>, String>((ref, dareId) {
  return ref
      .read(firestoreDareServiceProvider)
      .watchProofsForDare(dareId);
});

/// Stream my proofs for a dare. Param is '$dareId|$userId'.
final myDareProofsProvider =
    StreamProvider.family<List<ProofSubmission>, String>((ref, param) {
  final parts = param.split('|');
  if (parts.length != 2) return const Stream.empty();
  return ref
      .read(firestoreDareServiceProvider)
      .watchMyProofs(dareId: parts[0], userId: parts[1]);
});

/// Stream scratch cards for a user.
final scratchCardsProvider =
    StreamProvider.family<List<ScratchCard>, String>((ref, userId) {
  return ref.read(firestoreDareServiceProvider).watchScratchCards(userId);
});

/// Stream medals for a user.
final dareMedalsProvider =
    StreamProvider.family<List<DareMedalRecord>, String>((ref, userId) {
  return ref.read(firestoreDareServiceProvider).watchMedals(userId);
});

/// All dares (public list) provider
final daresProvider = Provider<List<DareModel>>((ref) {
  return ref.watch(dareControllerProvider).publicDares;
});

// ─── Notification providers ─────────────────────────────────────────────────

/// Record type for a single pending join request.
typedef JoinRequestItem = ({DareModel dare, DareMember requester});

/// Streams all pending join requests across dares the user created.
final pendingJoinRequestsProvider =
    StreamProvider.autoDispose.family<List<JoinRequestItem>, String>(
  (ref, userId) {
    return ref
        .read(firestoreDareServiceProvider)
        .watchCreatedDares(userId)
        .map((dares) {
      final items = <JoinRequestItem>[];
      for (final dare in dares) {
        for (final request in dare.joinRequests) {
          items.add((dare: dare, requester: request));
        }
      }
      return items;
    });
  },
);

/// Count of pending join requests (for the notification badge).
final pendingJoinCountProvider =
    Provider.autoDispose.family<int, String>((ref, userId) {
  return ref.watch(pendingJoinRequestsProvider(userId)).when(
    data: (list) => list.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
