// gamification_service.dart
//
// Single service responsible for ALL XP / badge / streak writes.
// Every action in the app that earns XP calls  GamificationService.award().
//
// Firestore writes performed inside a transaction:
//   users/{uid}                 — points, level, levelTitle, badges, streak fields
//   users/{uid}/xpEvents/{id}   — audit log entry
//
// The method returns a GamificationResult so the controller can trigger
// the in-app toast / level-up animation without doing any extra reads.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/gamification_models.dart';
import '../models/user_model.dart';

final gamificationServiceProvider = Provider<GamificationService>(
  (_) => GamificationService(),
);

class GamificationService {
  final FirebaseFirestore _db;

  GamificationService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  // ── award ─────────────────────────────────────────────────────────────────

  /// Award XP for [action] to [userId].
  ///
  /// Streak multiplier is applied automatically for non-streak actions.
  /// Pass [relatedId] (spotId, dilemmaId, …) to enrich the XP event log.
  Future<GamificationResult?> award({
    required String userId,
    required XpAction action,
    String? relatedId,
  }) async {
    try {
      final userRef = _db.collection('users').doc(userId);
      late GamificationResult result;

      await _db.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        if (!snap.exists) return;
        final data = snap.data()!;

        // ── Current streak ───────────────────────────────────────────────
        final streak = StreakInfo.fromMap(data);
        final now = DateTime.now();
        int newStreak = streak.currentStreak;
        int longestStreak = streak.longestStreak;
        DateTime? lastLogin = streak.lastLogin;

        if (action == XpAction.dailyLogin) {
          final today = _dateOnly(now);
          final lastDay = lastLogin != null ? _dateOnly(lastLogin) : null;
          if (lastDay == null || today.difference(lastDay).inDays > 1) {
            // streak broken or first login
            newStreak = 1;
          } else if (today.difference(lastDay).inDays == 1) {
            // consecutive day
            newStreak = streak.currentStreak + 1;
          }
          // same day — no change
          longestStreak = newStreak > longestStreak ? newStreak : longestStreak;
          lastLogin = now;
        }

        // ── Base XP with streak multiplier ────────────────────────────────
        final multiplier =
            (action == XpAction.dailyLogin || action == XpAction.streakBonus)
            ? 1.0
            : StreakInfo(
                currentStreak: newStreak,
                longestStreak: longestStreak,
                lastLogin: lastLogin,
              ).xpMultiplier;

        final baseXp = action.baseXp;
        final xpAwarded = (baseXp * multiplier).round();

        // ── Points & level ────────────────────────────────────────────────
        final oldPoints = (data['points'] as num?)?.toInt() ?? 0;
        final oldLevel = UserModel.calculateLevel(oldPoints);
        final newPoints = oldPoints + xpAwarded;
        final newLevel = UserModel.calculateLevel(newPoints);

        // ── Badge evaluation ──────────────────────────────────────────────
        final alreadyEarned = List<String>.from(
          data['badgesEarned'] as List? ?? [],
        );
        final newBadgeIds = BadgeModel.evaluate(
          alreadyEarned: alreadyEarned,
          ratingsCount: (data['ratingsCount'] as num?)?.toInt() ?? 0,
          contributionsCount:
              (data['contributionsCount'] as num?)?.toInt() ?? 0,
          photosCount: (data['photosCount'] as num?)?.toInt() ?? 0,
          dilemmasCreated: (data['dilemmasCreated'] as num?)?.toInt() ?? 0,
          dilemmasVoted: (data['dilemmasVoted'] as num?)?.toInt() ?? 0,
          bucketListsCreated:
              (data['bucketListsCreated'] as num?)?.toInt() ?? 0,
          bucketItemsCompleted:
              (data['bucketItemsCompleted'] as num?)?.toInt() ?? 0,
          loginStreak: newStreak,
          level: newLevel,
          rank: 0, // rank checked separately in leaderboard
        );

        // Points from newly earned badges
        int badgeXp = 0;
        for (final id in newBadgeIds) {
          try {
            badgeXp += BadgeModel.allBadges
                .firstWhere((b) => b.id == id)
                .pointsReward;
          } catch (_) {}
        }
        final totalNewPoints = newPoints + badgeXp;
        final finalLevel = UserModel.calculateLevel(totalNewPoints);

        // ── Firestore writes ──────────────────────────────────────────────
        final updatedBadges = [...alreadyEarned, ...newBadgeIds];

        final userUpdates = <String, dynamic>{
          'points': totalNewPoints,
          'level': finalLevel,
          'levelTitle': UserModel.getLevelTitle(finalLevel),
          'badgesEarned': updatedBadges,
          'badges': updatedBadges,
          'updatedAt': FieldValue.serverTimestamp(),
          if (action == XpAction.dailyLogin) ...{
            'loginStreak': newStreak,
            'longestStreak': longestStreak,
            'lastLogin': FieldValue.serverTimestamp(),
          },
        };
        tx.update(userRef, userUpdates);

        // XP event log
        final eventRef = userRef.collection('xpEvents').doc();
        tx.set(eventRef, {
          'action': action.name,
          'xpEarned': xpAwarded + badgeXp,
          'createdAt': FieldValue.serverTimestamp(),
          if (relatedId != null) 'relatedId': relatedId,
        });

        result = GamificationResult(
          xpAwarded: xpAwarded + badgeXp,
          newBadgeIds: newBadgeIds,
          leveledUp: finalLevel > oldLevel,
          newLevel: finalLevel,
          totalPoints: totalNewPoints,
          streak: StreakInfo(
            currentStreak: newStreak,
            longestStreak: longestStreak,
            lastLogin: now,
          ),
        );
      });

      return result;
    } catch (_) {
      return null;
    }
  }

  // ── Increment activity counters ───────────────────────────────────────────

  /// Increments a named counter on the user document (e.g. ratingsCount,
  /// photosCount). Called alongside award() from each feature service.
  Future<void> incrementCounter(String userId, String field) async {
    try {
      await _db.collection('users').doc(userId).update({
        field: FieldValue.increment(1),
      });
    } catch (_) {}
  }

  // ── Daily login check ─────────────────────────────────────────────────────

  /// Call on every app foreground. Returns a result only if this is
  /// the first login of the day; otherwise returns null (no-op).
  Future<GamificationResult?> recordDailyLogin(String userId) async {
    final snap = await _db.collection('users').doc(userId).get();
    if (!snap.exists) return null;
    final d = snap.data()!;
    final ts = d['lastLogin'];
    final lastLogin = ts is Timestamp ? ts.toDate() : null;
    final today = _dateOnly(DateTime.now());

    // Only award once per calendar day
    if (lastLogin != null && _dateOnly(lastLogin).isAtSameMomentAs(today)) {
      return null;
    }

    // Award daily login XP
    final result = await award(userId: userId, action: XpAction.dailyLogin);

    // Check streak milestones and award bonus XP
    if (result != null) {
      final s = result.streak.currentStreak;
      if (s == 7) {
        await award(userId: userId, action: XpAction.weeklyStreak);
      } else if (s == 30) {
        await award(userId: userId, action: XpAction.monthlyStreak);
      } else if (s >= 3) {
        await award(userId: userId, action: XpAction.streakBonus);
      }
    }

    return result;
  }

  // ── Recent XP events ──────────────────────────────────────────────────────

  /// Stream of the last [limit] XP events for the activity feed.
  Stream<List<XpEvent>> watchXpEvents(String userId, {int limit = 20}) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('xpEvents')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => XpEvent.fromFirestore(d)).toList());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
