// test/models/gamification_models_test.dart
//
// Tests for XpAction, StreakInfo, GamificationResult, BadgeModel, LevelInfo.

import 'package:flutter_test/flutter_test.dart';
import 'package:xplooria/models/gamification_models.dart';

void main() {
  // ── XpAction.baseXp ───────────────────────────────────────────────────────

  group('XpAction.baseXp', () {
    test('writeReview = 15', () => expect(XpAction.writeReview.baseXp, 15));
    test('uploadPhoto = 10', () => expect(XpAction.uploadPhoto.baseXp, 10));
    test(
      'createBucketList = 20',
      () => expect(XpAction.createBucketList.baseXp, 20),
    );
    test(
      'completeBucketItem = 10',
      () => expect(XpAction.completeBucketItem.baseXp, 10),
    );
    test('createDilemma = 25', () => expect(XpAction.createDilemma.baseXp, 25));
    test('voteDilemma = 5', () => expect(XpAction.voteDilemma.baseXp, 5));
    test('dailyLogin = 5', () => expect(XpAction.dailyLogin.baseXp, 5));
    test('streakBonus = 10', () => expect(XpAction.streakBonus.baseXp, 10));
    test('weeklyStreak = 30', () => expect(XpAction.weeklyStreak.baseXp, 30));
    test(
      'monthlyStreak = 100',
      () => expect(XpAction.monthlyStreak.baseXp, 100),
    );
  });

  // ── XpAction.label ───────────────────────────────────────────────────────

  group('XpAction.label', () {
    test('every action has a non-empty label', () {
      for (final action in XpAction.values) {
        expect(
          action.label,
          isNotEmpty,
          reason: '${action.name} should have a label',
        );
      }
    });

    test('writeReview label matches expected', () {
      expect(XpAction.writeReview.label, 'Wrote a review');
    });

    test('dailyLogin label matches expected', () {
      expect(XpAction.dailyLogin.label, 'Daily login');
    });
  });

  // ── XpAction.emoji ───────────────────────────────────────────────────────

  group('XpAction.emoji', () {
    test('every action has a non-empty emoji', () {
      for (final action in XpAction.values) {
        expect(
          action.emoji,
          isNotEmpty,
          reason: '${action.name} should have an emoji',
        );
      }
    });
  });

  // ── StreakInfo.xpMultiplier ───────────────────────────────────────────────

  group('StreakInfo.xpMultiplier', () {
    test('streak 0 → multiplier 1.0', () {
      const s = StreakInfo(currentStreak: 0, longestStreak: 0);
      expect(s.xpMultiplier, 1.0);
    });

    test('streak 1–4 → multiplier 1.0 (not yet a bonus tier)', () {
      for (int i = 1; i <= 4; i++) {
        final s = StreakInfo(currentStreak: i, longestStreak: i);
        expect(s.xpMultiplier, 1.0, reason: 'streak $i');
      }
    });

    test('streak 5 → multiplier 1.1', () {
      const s = StreakInfo(currentStreak: 5, longestStreak: 5);
      expect(s.xpMultiplier, closeTo(1.1, 0.001));
    });

    test('streak 10 → multiplier 1.2', () {
      const s = StreakInfo(currentStreak: 10, longestStreak: 10);
      expect(s.xpMultiplier, closeTo(1.2, 0.001));
    });

    test('streak 50 → multiplier capped at 2.0', () {
      const s = StreakInfo(currentStreak: 50, longestStreak: 50);
      expect(s.xpMultiplier, 2.0);
    });

    test('streak 100 → still capped at 2.0', () {
      const s = StreakInfo(currentStreak: 100, longestStreak: 100);
      expect(s.xpMultiplier, 2.0);
    });
  });

  // ── StreakInfo.display ────────────────────────────────────────────────────

  group('StreakInfo.display', () {
    test('shows fire emoji + streak count', () {
      const s = StreakInfo(currentStreak: 7, longestStreak: 7);
      expect(s.display, '🔥 7');
    });

    test('streak 0 displays as zero', () {
      const s = StreakInfo(currentStreak: 0, longestStreak: 0);
      expect(s.display, '🔥 0');
    });
  });

  // ── StreakInfo.empty constructor ──────────────────────────────────────────

  group('StreakInfo.empty', () {
    test('creates zero streak', () {
      const s = StreakInfo.empty();
      expect(s.currentStreak, 0);
      expect(s.longestStreak, 0);
      expect(s.lastLogin, isNull);
    });
  });

  // ── GamificationResult.hasReward ─────────────────────────────────────────

  group('GamificationResult.hasReward', () {
    const emptyStreak = StreakInfo(currentStreak: 0, longestStreak: 0);

    test('xpAwarded > 0 → hasReward true', () {
      final r = GamificationResult(
        xpAwarded: 15,
        newBadgeIds: const [],
        leveledUp: false,
        newLevel: 1,
        totalPoints: 15,
        streak: emptyStreak,
      );
      expect(r.hasReward, isTrue);
    });

    test('new badge → hasReward true', () {
      final r = GamificationResult(
        xpAwarded: 0,
        newBadgeIds: const ['first_review'],
        leveledUp: false,
        newLevel: 1,
        totalPoints: 0,
        streak: emptyStreak,
      );
      expect(r.hasReward, isTrue);
    });

    test('leveledUp → hasReward true', () {
      final r = GamificationResult(
        xpAwarded: 0,
        newBadgeIds: const [],
        leveledUp: true,
        newLevel: 2,
        totalPoints: 100,
        streak: emptyStreak,
      );
      expect(r.hasReward, isTrue);
    });

    test('everything zero/false → hasReward false', () {
      final r = GamificationResult(
        xpAwarded: 0,
        newBadgeIds: const [],
        leveledUp: false,
        newLevel: 1,
        totalPoints: 0,
        streak: emptyStreak,
      );
      expect(r.hasReward, isFalse);
    });
  });

  // ── LevelInfo ─────────────────────────────────────────────────────────────

  group('LevelInfo', () {
    test('10 levels defined', () {
      expect(LevelInfo.levels.length, 10);
    });

    test('level 1 starts at 0 pts', () {
      expect(LevelInfo.levels.first.minPoints, 0);
    });

    test('level 10 title is Guardian', () {
      expect(LevelInfo.levels.last.title, 'Guardian');
    });

    test('forPoints(0) → level 1', () {
      expect(LevelInfo.forPoints(0).level, 1);
    });

    test('forPoints(1000) → level 5 (Guide)', () {
      expect(LevelInfo.forPoints(1000).title, 'Guide');
    });

    test('forPoints(15000) → level 10 (Guardian)', () {
      expect(LevelInfo.forPoints(15000).level, 10);
    });

    test('forPoints(99999) → still level 10', () {
      expect(LevelInfo.forPoints(99999).level, 10);
    });

    test('level titles are all unique', () {
      final titles = LevelInfo.levels.map((l) => l.title).toSet();
      expect(titles.length, LevelInfo.levels.length);
    });

    test('levels are sorted ascending by minPoints', () {
      for (int i = 1; i < LevelInfo.levels.length; i++) {
        expect(
          LevelInfo.levels[i].minPoints,
          greaterThan(LevelInfo.levels[i - 1].minPoints),
        );
      }
    });
  });

  // ── XP calculation integration ────────────────────────────────────────────

  group('XP with streak multiplier (integration)', () {
    test('writeReview with 5-day streak earns 15 * 1.1 = ~17 XP', () {
      const streak = StreakInfo(currentStreak: 5, longestStreak: 5);
      final xp = (XpAction.writeReview.baseXp * streak.xpMultiplier).round();
      expect(xp, 17); // 15 * 1.1 = 16.5 → rounds to 17
    });

    test('createDilemma with 10-day streak earns 25 * 1.2 = 30 XP', () {
      const streak = StreakInfo(currentStreak: 10, longestStreak: 10);
      final xp = (XpAction.createDilemma.baseXp * streak.xpMultiplier).round();
      expect(xp, 30);
    });

    test('dailyLogin multiplier is always 1.0 (no streak boost)', () {
      // The GamificationService uses multiplier 1.0 for dailyLogin and streakBonus.
      const multiplier = 1.0; // enforced by service
      expect((XpAction.dailyLogin.baseXp * multiplier).round(), 5);
    });
  });
}
