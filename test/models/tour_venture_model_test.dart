// test/models/tour_venture_model_test.dart
//
// Unit tests for tour_venture_models enums and PricingTier.

import 'package:flutter_test/flutter_test.dart';
import 'package:xplooria/models/tour_venture_models.dart';

void main() {
  // ── PackageCategory ────────────────────────────────────────────────────────

  group('PackageCategory', () {
    test('all values have non-empty label', () {
      for (final c in PackageCategory.values) {
        expect(c.label, isNotEmpty, reason: '${c.name}.label must not be empty');
      }
    });

    test('all values have non-empty emoji', () {
      for (final c in PackageCategory.values) {
        expect(c.emoji, isNotEmpty, reason: '${c.name}.emoji must not be empty');
      }
    });

    test('specific label mappings', () {
      expect(PackageCategory.birdWatching.label, 'Bird Watching');
      expect(PackageCategory.fishing.label, 'Fishing');
      expect(PackageCategory.hiking.label, 'Hiking');
      expect(PackageCategory.wildlifeSafari.label, 'Wildlife Safari');
      expect(PackageCategory.other.label, 'Other');
    });

    test('specific emoji mappings', () {
      expect(PackageCategory.birdWatching.emoji, '🦜');
      expect(PackageCategory.fishing.emoji, '🎣');
      expect(PackageCategory.camping.emoji, '⛺');
      expect(PackageCategory.photography.emoji, '📸');
      expect(PackageCategory.stargazing.emoji, '🌌');
    });

    group('fromString', () {
      test('resolves exact name matches', () {
        expect(PackageCategory.fromString('hiking'), PackageCategory.hiking);
        expect(PackageCategory.fromString('camping'), PackageCategory.camping);
        expect(PackageCategory.fromString('cycling'), PackageCategory.cycling);
      });

      test('resolves case-insensitively', () {
        expect(PackageCategory.fromString('BirdWatching'), PackageCategory.birdWatching);
        expect(PackageCategory.fromString('FISHING'), PackageCategory.fishing);
      });

      test('strips underscores', () {
        expect(PackageCategory.fromString('bird_watching'), PackageCategory.birdWatching);
        expect(PackageCategory.fromString('wildlife_safari'), PackageCategory.wildlifeSafari);
      });

      test('strips spaces', () {
        expect(PackageCategory.fromString('bird watching'), PackageCategory.birdWatching);
        expect(PackageCategory.fromString('eco tourism'), PackageCategory.ecoTourism);
      });

      test('falls back to other for unknown strings', () {
        expect(PackageCategory.fromString('unknown'), PackageCategory.other);
        expect(PackageCategory.fromString(''), PackageCategory.other);
      });
    });
  });

  // ── PackageSeason ──────────────────────────────────────────────────────────

  group('PackageSeason', () {
    test('all values have non-empty label', () {
      for (final s in PackageSeason.values) {
        expect(s.label, isNotEmpty, reason: '${s.name}.label must not be empty');
      }
    });

    test('all values have non-empty emoji', () {
      for (final s in PackageSeason.values) {
        expect(s.emoji, isNotEmpty, reason: '${s.name}.emoji must not be empty');
      }
    });

    test('specific label mappings', () {
      expect(PackageSeason.allYear.label, 'All Year');
      expect(PackageSeason.monsoon.label, 'Monsoon (Jun–Sep)');
      expect(PackageSeason.winter.label, 'Winter (Dec–Feb)');
    });

    test('specific emoji mappings', () {
      expect(PackageSeason.spring.emoji, '🌸');
      expect(PackageSeason.winter.emoji, '❄️');
      expect(PackageSeason.monsoon.emoji, '🌧️');
      expect(PackageSeason.allYear.emoji, '📅');
    });

    group('fromString', () {
      test('resolves exact name', () {
        expect(PackageSeason.fromString('summer'), PackageSeason.summer);
        expect(PackageSeason.fromString('winter'), PackageSeason.winter);
      });

      test('falls back to allYear for unknown', () {
        expect(PackageSeason.fromString('unknown'), PackageSeason.allYear);
      });
    });
  });

  // ── DifficultyLevel ────────────────────────────────────────────────────────

  group('DifficultyLevel', () {
    test('all values have non-empty label', () {
      for (final d in DifficultyLevel.values) {
        expect(d.label, isNotEmpty, reason: '${d.name}.label must not be empty');
      }
    });

    test('specific label mappings', () {
      expect(DifficultyLevel.easy.label, 'Easy');
      expect(DifficultyLevel.moderate.label, 'Moderate');
      expect(DifficultyLevel.challenging.label, 'Challenging');
      expect(DifficultyLevel.extreme.label, 'Extreme');
    });

    test('colorHex values are non-zero', () {
      for (final d in DifficultyLevel.values) {
        expect(d.colorHex, isNonZero, reason: '${d.name}.colorHex should be non-zero');
      }
    });
  });

  // ── MedalTier ──────────────────────────────────────────────────────────────

  group('MedalTier', () {
    test('all values have non-empty label', () {
      for (final m in MedalTier.values) {
        expect(m.label, isNotEmpty, reason: '${m.name}.label must not be empty');
      }
    });

    test('all values have non-empty emoji', () {
      for (final m in MedalTier.values) {
        expect(m.emoji, isNotEmpty, reason: '${m.name}.emoji must not be empty');
      }
    });

    test('colorHex values are non-zero', () {
      for (final m in MedalTier.values) {
        expect(m.colorHex, isNonZero, reason: '${m.name}.colorHex should be non-zero');
      }
    });

    test('specific mappings', () {
      expect(MedalTier.bronze.label, 'Bronze');
      expect(MedalTier.gold.emoji, '🥇');
      expect(MedalTier.legendary.emoji, '🏆');
      expect(MedalTier.platinum.colorHex, 0xFF00CED1);
    });

    group('fromString', () {
      test('resolves known tier names', () {
        expect(MedalTier.fromString('gold'), MedalTier.gold);
        expect(MedalTier.fromString('platinum'), MedalTier.platinum);
        expect(MedalTier.fromString('legendary'), MedalTier.legendary);
      });

      test('is case-insensitive', () {
        expect(MedalTier.fromString('GOLD'), MedalTier.gold);
        expect(MedalTier.fromString('Silver'), MedalTier.silver);
      });

      test('falls back to bronze for unknown', () {
        expect(MedalTier.fromString('diamond'), MedalTier.bronze);
        expect(MedalTier.fromString(''), MedalTier.bronze);
      });
    });
  });

  // ── PricingTier ────────────────────────────────────────────────────────────

  group('PricingTier', () {
    test('fromJson parses all standard fields', () {
      final tier = PricingTier.fromJson({
        'id': 'tier1',
        'name': 'Solo',
        'pricePerPerson': 1500.0,
        'minPersons': 1,
        'maxPersons': 4,
        'description': 'Solo package',
        'includes': ['Breakfast', 'Guide'],
        'excludes': ['Transport'],
        'isPopular': true,
        'isAvailable': true,
      });

      expect(tier.id, 'tier1');
      expect(tier.name, 'Solo');
      expect(tier.pricePerPerson, 1500.0);
      expect(tier.minPersons, 1);
      expect(tier.maxPersons, 4);
      expect(tier.description, 'Solo package');
      expect(tier.includes, ['Breakfast', 'Guide']);
      expect(tier.excludes, ['Transport']);
      expect(tier.isPopular, isTrue);
      expect(tier.isAvailable, isTrue);
    });

    test('fromJson handles int pricePerPerson', () {
      final tier = PricingTier.fromJson({'pricePerPerson': 2000});
      expect(tier.pricePerPerson, 2000.0);
    });

    test('fromJson defaults empty lists for missing includes/excludes', () {
      final tier = PricingTier.fromJson({'name': 'Basic'});
      expect(tier.includes, isEmpty);
      expect(tier.excludes, isEmpty);
    });

    test('fromJson defaults isAvailable to true', () {
      final tier = PricingTier.fromJson({});
      expect(tier.isAvailable, isTrue);
    });

    test('fromJson defaults isPopular to false', () {
      final tier = PricingTier.fromJson({});
      expect(tier.isPopular, isFalse);
    });

    test('toJson round-trip preserves key fields', () {
      const tier = PricingTier(
        id: 'p1',
        name: 'Group',
        pricePerPerson: 999.0,
        minPersons: 5,
        maxPersons: 10,
        includes: ['Lunch'],
      );
      final json = tier.toJson();
      expect(json['id'], 'p1');
      expect(json['name'], 'Group');
      expect(json['pricePerPerson'], 999.0);
      expect(json['minPersons'], 5);
      expect(json['maxPersons'], 10);
      expect(json['includes'], ['Lunch']);
    });
  });
}
