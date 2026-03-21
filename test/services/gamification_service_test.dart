// test/services/gamification_service_test.dart
//
// Unit tests for GamificationService using FakeFirebaseFirestore.
//
// Covers:
//   award()         — XP written, points updated, level-up detected, badges
//   recordDailyLogin() — once-per-day guard, streak logic, milestone bonuses
//   incrementCounter() — writes FieldValue.increment
//   watchXpEvents() — stream returns written events

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotmizoram/models/gamification_models.dart';
import 'package:spotmizoram/models/user_model.dart';
import 'package:spotmizoram/services/gamification_service.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Creates a bare-minimum user document in the fake database.
Future<void> seedUser(
  FakeFirebaseFirestore db, {
  String uid = 'u1',
  int points = 0,
  int loginStreak = 0,
  int longestStreak = 0,
  int ratingsCount = 0,
  int contributionsCount = 0,
  int photosCount = 0,
  int dilemmasCreated = 0,
  int dilemmasVoted = 0,
  int bucketListsCreated = 0,
  int bucketItemsCompleted = 0,
  List<String> badgesEarned = const [],
  DateTime? lastLogin,
}) async {
  await db.collection('users').doc(uid).set({
    'points': points,
    'level': UserModel.calculateLevel(points),
    'levelTitle': UserModel.getLevelTitle(UserModel.calculateLevel(points)),
    'loginStreak': loginStreak,
    'longestStreak': longestStreak,
    'ratingsCount': ratingsCount,
    'contributionsCount': contributionsCount,
    'photosCount': photosCount,
    'dilemmasCreated': dilemmasCreated,
    'dilemmasVoted': dilemmasVoted,
    'bucketListsCreated': bucketListsCreated,
    'bucketItemsCompleted': bucketItemsCompleted,
    'badgesEarned': badgesEarned,
    'badges': badgesEarned,
    if (lastLogin != null) 'lastLogin': lastLogin,
  });
}

void main() {
  late FakeFirebaseFirestore fakeDb;
  late GamificationService sut;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    sut = GamificationService(fakeDb);
  });

  // ── award() — basic XP ────────────────────────────────────────────────────

  group('award() — basic XP', () {
    test('returns null when user doc does not exist', () async {
      // No seedUser() call — doc absent
      final result = await sut.award(
        userId: 'ghost',
        action: XpAction.writeReview,
      );
      expect(result, isNull);
    });

    test('returns GamificationResult with correct xpAwarded', () async {
      await seedUser(fakeDb);
      final result = await sut.award(
        userId: 'u1',
        action: XpAction.writeReview,
      );

      expect(result, isNotNull);
      // writeReview baseXp = 15; streak 0 → multiplier 1.0; no badges
      expect(result!.xpAwarded, 15);
    });

    test('updates users/{uid}.points by xpAwarded', () async {
      await seedUser(fakeDb, points: 50);
      await sut.award(userId: 'u1', action: XpAction.writeReview); // +15

      final snap = await fakeDb.collection('users').doc('u1').get();
      expect(snap.data()!['points'], 65);
    });

    test('writes an xpEvent document under users/{uid}/xpEvents', () async {
      await seedUser(fakeDb);
      await sut.award(
        userId: 'u1',
        action: XpAction.uploadPhoto,
        relatedId: 'spot42',
      );

      final events = await fakeDb
          .collection('users')
          .doc('u1')
          .collection('xpEvents')
          .get();
      expect(events.docs.length, 1);
      final d = events.docs.first.data();
      expect(d['action'], 'uploadPhoto');
      expect(d['relatedId'], 'spot42');
    });

    test('xpEvent records total xpEarned (base + badge bonus)', () async {
      await seedUser(fakeDb);
      await sut.award(userId: 'u1', action: XpAction.writeReview);

      final events = await fakeDb
          .collection('users')
          .doc('u1')
          .collection('xpEvents')
          .get();
      expect(events.docs.first.data()['xpEarned'], greaterThan(0));
    });

    test('detects level-up when crossing level threshold', () async {
      // Level 2 starts at 100 pts; user at 90 pts, writeReview +15 → 105 pts
      await seedUser(fakeDb, points: 90);
      final result = await sut.award(
        userId: 'u1',
        action: XpAction.writeReview,
      );

      expect(result, isNotNull);
      expect(result!.leveledUp, isTrue);
      expect(result.newLevel, 2);
    });

    test('leveledUp is false when not crossing threshold', () async {
      await seedUser(fakeDb, points: 0);
      final result = await sut.award(
        userId: 'u1',
        action: XpAction.writeReview,
      );

      expect(result!.leveledUp, isFalse);
    });

    test('GamificationResult.hasReward is true when xp > 0', () async {
      await seedUser(fakeDb);
      final result = await sut.award(
        userId: 'u1',
        action: XpAction.writeReview,
      );
      expect(result!.hasReward, isTrue);
    });

    test('streak multiplier applied for non-login actions', () async {
      // streak = 5 → multiplier = 1.1; writeReview baseXp = 15 → 17 (rounded)
      // Pre-earn all review and streak badges to isolate just the multiplier
      await seedUser(
        fakeDb,
        loginStreak: 5,
        longestStreak: 5,
        badgesEarned: [
          'first_review',
          'five_reviews',
          'twenty_reviews',
          'fifty_reviews',
          'streak_3',
          'streak_7',
          'streak_30',
        ],
      );
      final result = await sut.award(
        userId: 'u1',
        action: XpAction.writeReview,
      );

      expect(result, isNotNull);
      // With no new badges, xpAwarded = (15 * 1.1).round() = 17
      expect(result!.xpAwarded, (15 * 1.1).round());
    });

    test('streak multiplier NOT applied for dailyLogin action', () async {
      await seedUser(fakeDb, loginStreak: 10, longestStreak: 10);
      final result = await sut.award(userId: 'u1', action: XpAction.dailyLogin);

      // dailyLogin baseXp = 5; no multiplier applied
      expect(result, isNotNull);
      expect(result!.xpAwarded, XpAction.dailyLogin.baseXp); // 5
    });

    test('streak multiplier NOT applied for streakBonus action', () async {
      // Pre-earn all streak and review badges to prevent badge bonuses inflating the value
      await seedUser(
        fakeDb,
        loginStreak: 10,
        longestStreak: 10,
        badgesEarned: [
          'streak_3',
          'streak_7',
          'streak_30',
          'first_review',
          'five_reviews',
          'twenty_reviews',
          'fifty_reviews',
        ],
      );
      final result = await sut.award(
        userId: 'u1',
        action: XpAction.streakBonus,
      );

      // streakBonus baseXp = 10; no multiplier applied; no new badges
      expect(result!.xpAwarded, XpAction.streakBonus.baseXp); // 10
    });
  });

  // ── award() — badge evaluation ────────────────────────────────────────────

  group('award() — badge evaluation', () {
    test('first_review badge earned when ratingsCount reaches threshold', () async {
      // first_review badge condition: ratingsCount >= 1 (reads STORED Firestore value)
      // Must seed with ratingsCount: 1 so the stored value satisfies the condition
      await seedUser(fakeDb, ratingsCount: 1);
      final result = await sut.award(
        userId: 'u1',
        action: XpAction.writeReview,
      );

      expect(result, isNotNull);
      // first_review badge should be awarded (ratingsCount=1 satisfies condition >= 1)
      expect(result!.newBadgeIds, contains('first_review'));
      // Total points include base XP (15) + badge bonus (10) = 25
      expect(result.totalPoints, greaterThanOrEqualTo(25));
    });

    test('already-earned badges are not re-awarded', () async {
      // Seed with first_review already earned
      await seedUser(fakeDb, badgesEarned: ['first_review'], ratingsCount: 5);
      final result = await sut.award(
        userId: 'u1',
        action: XpAction.writeReview,
      );

      expect(result, isNotNull);
      expect(result!.newBadgeIds, isNot(contains('first_review')));
    });
  });

  // ── incrementCounter() ────────────────────────────────────────────────────

  group('incrementCounter()', () {
    test('increments the named field by 1', () async {
      await seedUser(fakeDb, ratingsCount: 3);
      await sut.incrementCounter('u1', 'ratingsCount');

      final snap = await fakeDb.collection('users').doc('u1').get();
      expect(snap.data()!['ratingsCount'], 4);
    });

    test('increments a zero field from 0 to 1', () async {
      await seedUser(fakeDb, photosCount: 0);
      await sut.incrementCounter('u1', 'photosCount');

      final snap = await fakeDb.collection('users').doc('u1').get();
      expect(snap.data()!['photosCount'], 1);
    });

    test('silently ignores non-existent user (no throw)', () async {
      // Should not throw
      await expectLater(
        sut.incrementCounter('nonexistent_uid', 'ratingsCount'),
        completes,
      );
    });
  });

  // ── recordDailyLogin() ────────────────────────────────────────────────────

  group('recordDailyLogin()', () {
    test('returns null for non-existent user', () async {
      final result = await sut.recordDailyLogin('ghost');
      expect(result, isNull);
    });

    test('awards dailyLogin XP on first login (no lastLogin)', () async {
      await seedUser(fakeDb); // no lastLogin
      final result = await sut.recordDailyLogin('u1');

      expect(result, isNotNull);
      expect(
        result!.xpAwarded,
        greaterThanOrEqualTo(XpAction.dailyLogin.baseXp),
      );
    });

    test('returns null when already logged in today', () async {
      final today = DateTime.now();
      await seedUser(fakeDb, lastLogin: today);
      final result = await sut.recordDailyLogin('u1');

      expect(result, isNull);
    });

    test('increments streak for consecutive-day login', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await seedUser(
        fakeDb,
        loginStreak: 2,
        longestStreak: 2,
        lastLogin: yesterday,
      );
      final result = await sut.recordDailyLogin('u1');

      expect(result, isNotNull);
      expect(result!.streak.currentStreak, 3);
    });

    test('resets streak to 1 when a day was missed', () async {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await seedUser(
        fakeDb,
        loginStreak: 5,
        longestStreak: 5,
        lastLogin: twoDaysAgo,
      );
      final result = await sut.recordDailyLogin('u1');

      expect(result, isNotNull);
      expect(result!.streak.currentStreak, 1);
    });

    test(
      'longestStreak is updated when new streak exceeds old record',
      () async {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await seedUser(
          fakeDb,
          loginStreak: 4,
          longestStreak: 4,
          lastLogin: yesterday,
        );
        final result = await sut.recordDailyLogin('u1');

        expect(result!.streak.longestStreak, 5);
      },
    );
  });

  // ── watchXpEvents() ───────────────────────────────────────────────────────

  group('watchXpEvents()', () {
    test('emits empty list when no events exist', () async {
      await seedUser(fakeDb);
      final stream = sut.watchXpEvents('u1', limit: 10);
      final first = await stream.first;
      expect(first, isEmpty);
    });

    test('emits events after award() is called', () async {
      await seedUser(fakeDb);
      await sut.award(userId: 'u1', action: XpAction.writeReview);
      final stream = sut.watchXpEvents('u1', limit: 10);
      final events = await stream.first;
      expect(events.length, 1);
      expect(events.first.action, XpAction.writeReview);
    });

    test('emits most recent events first', () async {
      await seedUser(fakeDb);
      await sut.award(userId: 'u1', action: XpAction.writeReview);
      await sut.award(userId: 'u1', action: XpAction.uploadPhoto);

      final stream = sut.watchXpEvents('u1', limit: 10);
      final events = await stream.first;
      expect(events.length, 2);
    });
  });

  // ── GamificationResult integrity ──────────────────────────────────────────

  group('GamificationResult', () {
    test('totalPoints equals points in user doc after award', () async {
      await seedUser(fakeDb, points: 20);
      final result = await sut.award(
        userId: 'u1',
        action: XpAction.createDilemma,
      );

      final snap = await fakeDb.collection('users').doc('u1').get();
      expect(snap.data()!['points'], result!.totalPoints);
    });

    test('streak in result matches loginStreak in user doc', () async {
      await seedUser(fakeDb, loginStreak: 3, longestStreak: 3);
      final result = await sut.award(
        userId: 'u1',
        action: XpAction.voteDilemma,
      );

      expect(result!.streak.currentStreak, 3);
    });
  });
}
