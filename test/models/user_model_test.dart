// test/models/user_model_test.dart
//
// Unit tests for UserModel — level calculation, progress, serialisation.

import 'package:flutter_test/flutter_test.dart';
import 'package:spotmizoram/models/user_model.dart';

void main() {
  // ── helpers ──────────────────────────────────────────────────────────────

  UserModel makeUser({
    int points = 0,
    int level = 1,
    String levelTitle = 'Explorer',
    List<String> badges = const [],
    List<String> badgesEarned = const [],
    List<String> bookmarks = const [],
    int role = 1,
  }) => UserModel(
    id: 'uid-test',
    email: 'test@example.com',
    displayName: 'Test User',
    role: role,
    points: points,
    level: level,
    levelTitle: levelTitle,
    badges: badges,
    badgesEarned: badgesEarned,
    contributionsCount: 0,
    ratingsCount: 0,
    bookmarks: bookmarks,
    createdAt: '2024-01-01T00:00:00.000Z',
  );

  // ── calculateLevel ────────────────────────────────────────────────────────

  group('UserModel.calculateLevel', () {
    test('0 pts → level 1', () {
      expect(UserModel.calculateLevel(0), 1);
    });

    test('99 pts → still level 1', () {
      expect(UserModel.calculateLevel(99), 1);
    });

    test('100 pts → level 2 (Wanderer threshold)', () {
      expect(UserModel.calculateLevel(100), 2);
    });

    test('249 pts → still level 2', () {
      expect(UserModel.calculateLevel(249), 2);
    });

    test('250 pts → level 3 (Adventurer)', () {
      expect(UserModel.calculateLevel(250), 3);
    });

    test('500 pts → level 4 (Pathfinder)', () {
      expect(UserModel.calculateLevel(500), 4);
    });

    test('1000 pts → level 5 (Guide)', () {
      expect(UserModel.calculateLevel(1000), 5);
    });

    test('2000 pts → level 6 (Expert)', () {
      expect(UserModel.calculateLevel(2000), 6);
    });

    test('3500 pts → level 7 (Master)', () {
      expect(UserModel.calculateLevel(3500), 7);
    });

    test('5500 pts → level 8 (Legend)', () {
      expect(UserModel.calculateLevel(5500), 8);
    });

    test('8500 pts → level 9 (Champion)', () {
      expect(UserModel.calculateLevel(8500), 9);
    });

    test('12500 pts → level 10 (Guardian)', () {
      expect(UserModel.calculateLevel(12500), 10);
    });

    test('huge pts (999999) → still capped at level 10', () {
      expect(UserModel.calculateLevel(999999), 10);
    });

    test('negative pts → level 1 (graceful)', () {
      // Negative XP is theoretically impossible but should not crash.
      expect(UserModel.calculateLevel(-100), 1);
    });
  });

  // ── getLevelTitle ────────────────────────────────────────────────────────

  group('UserModel.getLevelTitle', () {
    const expected = {
      1: 'Explorer',
      2: 'Wanderer',
      3: 'Adventurer',
      4: 'Pathfinder',
      5: 'Guide',
      6: 'Expert',
      7: 'Master',
      8: 'Legend',
      9: 'Champion',
      10: 'Guardian',
    };

    for (final entry in expected.entries) {
      test('level ${entry.key} → ${entry.value}', () {
        expect(UserModel.getLevelTitle(entry.key), entry.value);
      });
    }

    test('unknown level falls back to Explorer', () {
      expect(UserModel.getLevelTitle(99), 'Explorer');
    });
  });

  // ── pointsToNextLevel ─────────────────────────────────────────────────────

  group('pointsToNextLevel', () {
    test('0 pts (level 1) → needs 100 pts', () {
      final u = makeUser(points: 0, level: 1);
      expect(u.pointsToNextLevel, 100);
    });

    test('150 pts (level 2) → needs 250 - 150 = 100 pts', () {
      final u = makeUser(points: 150, level: 2);
      expect(u.pointsToNextLevel, 100);
    });

    test('at max level (10) → 0 pts needed', () {
      final u = makeUser(points: 12500, level: 10);
      expect(u.pointsToNextLevel, 0);
    });
  });

  // ── levelProgress ─────────────────────────────────────────────────────────

  group('levelProgress', () {
    test('exactly at level start → 0.0 progress', () {
      final u = makeUser(points: 100, level: 2);
      expect(u.levelProgress, closeTo(0.0, 0.001));
    });

    test('halfway through level → ~0.5 progress', () {
      // Level 2: 100–249 (range 150). Halfway = 100 + 75 = 175 pts.
      final u = makeUser(points: 175, level: 2);
      expect(u.levelProgress, closeTo(0.5, 0.01));
    });

    test('at max level → 1.0 progress', () {
      final u = makeUser(points: 12500, level: 10);
      expect(u.levelProgress, 1.0);
    });

    test('progress clamped between 0.0 and 1.0', () {
      final u = makeUser(points: 50000, level: 10);
      expect(u.levelProgress, 1.0);
    });
  });

  // ── isAdmin ────────────────────────────────────────────────────────────────

  group('isAdmin', () {
    test('role 0 → isAdmin true', () {
      expect(makeUser(role: 0).isAdmin, isTrue);
    });

    test('role 1 → isAdmin false', () {
      expect(makeUser(role: 1).isAdmin, isFalse);
    });
  });

  // ── fromJson ──────────────────────────────────────────────────────────────

  group('UserModel.fromJson', () {
    test('parses all standard fields', () {
      final json = {
        'id': 'abc123',
        'email': 'user@test.com',
        'displayName': 'John Doe',
        'role': 1,
        'points': 250,
        'level': 3,
        'levelTitle': 'Adventurer',
        'badges': ['first_review'],
        'badgesEarned': ['first_review'],
        'contributionsCount': 5,
        'ratingsCount': 3,
        'bookmarks': ['spot1', 'spot2'],
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'abc123');
      expect(user.email, 'user@test.com');
      expect(user.displayName, 'John Doe');
      expect(user.points, 250);
      expect(user.level, 3);
      expect(user.levelTitle, 'Adventurer');
      expect(user.badges, ['first_review']);
      expect(user.badgesEarned, ['first_review']);
      expect(user.contributionsCount, 5);
      expect(user.ratingsCount, 3);
      expect(user.bookmarks, ['spot1', 'spot2']);
    });

    test('graceful defaults for missing fields', () {
      final user = UserModel.fromJson({});
      expect(user.id, '');
      expect(user.email, '');
      expect(user.displayName, 'User');
      expect(user.points, 0);
      expect(user.level, 1);
      expect(user.badges, isEmpty);
      expect(user.bookmarks, isEmpty);
    });

    test('level is auto-calculated when derived from points', () {
      // 1000 pts → level 5 regardless of explicit "level" field
      final user = UserModel.fromJson({'points': 1000});
      expect(user.level, 5);
      expect(user.levelTitle, 'Guide');
    });

    test('levelTitle is always overridden by calculated level', () {
      final user = UserModel.fromJson({'points': 2000, 'levelTitle': 'wrong'});
      expect(user.levelTitle, 'Expert');
    });

    test('numeric fields accept both int and double from Firestore', () {
      final user = UserModel.fromJson({
        'points': 500.0,
        'level': 4.0,
        'contributionsCount': 10.0,
      });
      expect(user.points, 500);
      expect(user.level, 4);
      expect(user.contributionsCount, 10);
    });

    test('bookmarks list from JSON is properly parsed', () {
      final user = UserModel.fromJson({
        'bookmarks': ['a', 'b', 'c'],
      });
      expect(user.bookmarks, ['a', 'b', 'c']);
    });
  });
}
