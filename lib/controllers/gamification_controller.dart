// gamification_controller.dart
//
// Riverpod layer over GamificationService.
//
// Responsibilities:
//   1. Expose award() so any screen/service can call it with 1 line.
//   2. Push GamificationResult events to a broadcast stream that the
//      XpToastOverlay widget listens to — it then shows the XP pop-up.
//   3. Handle daily login check on app foreground.
//   4. Expose a Stream of recent XP events for the profile activity tab.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import '../models/gamification_models.dart';
import '../services/gamification_service.dart';

// ── Event broadcast ───────────────────────────────────────────────────────────

/// Global sink — GamificationController pushes results here;
/// XpToastOverlay listens and shows the animated pop-up.
final _rewardStreamController =
    StreamController<GamificationResult>.broadcast();

final gamificationRewardStreamProvider = StreamProvider<GamificationResult>((
  ref,
) {
  return _rewardStreamController.stream;
});

// ── Main controller ────────────────────────────────────────────────────────────

class GamificationController extends Notifier<void> {
  GamificationService get _svc => ref.read(gamificationServiceProvider);

  String? get _uid => ref.read(currentUserProvider)?.id;

  @override
  void build() {} // stateless — rewards are pushed via stream

  // ── Public API ────────────────────────────────────────────────────────────

  /// Award XP for [action]. Pushes to the reward stream if something was earned.
  Future<GamificationResult?> award(
    XpAction action, {
    String? relatedId,
  }) async {
    final uid = _uid;
    if (uid == null) return null;
    final result = await _svc.award(
      userId: uid,
      action: action,
      relatedId: relatedId,
    );
    if (result != null && result.hasReward) {
      _rewardStreamController.add(result);
      // Refresh user profile so points/level update everywhere
      await ref.read(authControllerProvider.notifier).refreshProfile();
    }
    return result;
  }

  /// Call once when the app comes to the foreground.
  Future<void> recordDailyLogin() async {
    final uid = _uid;
    if (uid == null) return;
    final result = await _svc.recordDailyLogin(uid);
    if (result != null && result.hasReward) {
      _rewardStreamController.add(result);
      await ref.read(authControllerProvider.notifier).refreshProfile();
    }
  }

  /// Increment a named activity counter (ratingsCount, photosCount, …)
  Future<void> incrementCounter(String field) async {
    final uid = _uid;
    if (uid == null) return;
    await _svc.incrementCounter(uid, field);
  }
}

final gamificationControllerProvider =
    NotifierProvider<GamificationController, void>(GamificationController.new);

// ── XP event stream for profile activity feed ─────────────────────────────────

final xpEventsProvider = StreamProvider<List<XpEvent>>((ref) {
  final svc = ref.watch(gamificationServiceProvider);
  final uid = ref.watch(currentUserProvider)?.id;
  if (uid == null) return const Stream.empty();
  return svc.watchXpEvents(uid);
});
