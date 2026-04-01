// test/models/spot_model_test.dart
//
// Unit tests for EntryFee, SpotRating, SpotComment, SpotModel.

import 'package:flutter_test/flutter_test.dart';
import 'package:xplooria/models/spot_model.dart';

void main() {
  // ── EntryFee ──────────────────────────────────────────────────────────────

  group('EntryFee', () {
    test('fromJson parses type and amount', () {
      final fee = EntryFee.fromJson({'type': 'adult', 'amount': '₹50'});
      expect(fee.type, 'adult');
      expect(fee.amount, '₹50');
    });

    test('fromJson defaults to empty strings', () {
      final fee = EntryFee.fromJson({});
      expect(fee.type, '');
      expect(fee.amount, '');
    });

    test('toJson round-trips correctly', () {
      const fee = EntryFee(type: 'child', amount: '20');
      final json = fee.toJson();
      expect(json['type'], 'child');
      expect(json['amount'], '20');
    });

    test('toJson / fromJson round-trip', () {
      const original = EntryFee(type: 'foreign', amount: '\$5');
      final restored = EntryFee.fromJson(original.toJson());
      expect(restored.type, original.type);
      expect(restored.amount, original.amount);
    });
  });

  // ── SpotRating ────────────────────────────────────────────────────────────

  group('SpotRating', () {
    test('fromJson parses all fields', () {
      final r = SpotRating.fromJson({
        'userId': 'u1',
        'userName': 'Lalzama',
        'rating': 4.5,
        'timestamp': '2024-01-01',
      });
      expect(r.userId, 'u1');
      expect(r.userName, 'Lalzama');
      expect(r.rating, 4.5);
      expect(r.timestamp, '2024-01-01');
    });

    test('fromJson coerces int rating to double', () {
      final r = SpotRating.fromJson({
        'userId': '',
        'userName': '',
        'rating': 4,
        'timestamp': '',
      });
      expect(r.rating, isA<double>());
      expect(r.rating, 4.0);
    });

    test('fromJson defaults to 0 rating when missing', () {
      final r = SpotRating.fromJson({});
      expect(r.rating, 0.0);
    });
  });

  // ── SpotComment ───────────────────────────────────────────────────────────

  group('SpotComment', () {
    test('fromJson parses all fields', () {
      final c = SpotComment.fromJson({
        'userId': 'u2',
        'userName': 'Vanlal',
        'comment': 'Stunning waterfalls!',
        'timestamp': '2024-02-15',
      });
      expect(c.userId, 'u2');
      expect(c.userName, 'Vanlal');
      expect(c.comment, 'Stunning waterfalls!');
      expect(c.timestamp, '2024-02-15');
    });

    test('fromJson defaults to empty strings when fields missing', () {
      final c = SpotComment.fromJson({});
      expect(c.userId, '');
      expect(c.comment, '');
    });
  });

  // ── SpotModel ─────────────────────────────────────────────────────────────

  group('SpotModel', () {
    Map<String, dynamic> fullJson() => {
      'id': 'spot1',
      'name': 'Vantawng Falls',
      'category': 'waterfall',
      'locationAddress': 'Thenzawl, Mizoram',
      'district': 'Serchhip',
      'averageRating': 4.7,
      'popularity': 9.2,
      'ratingsCount': 312,
      'imagesUrl': ['https://img1.jpg', 'https://img2.jpg'],
      'featured': true,
      'status': 'approved',
      'views': 5000,
      'bestSeason': 'October–March',
      'placeStory': 'Tallest waterfall in Mizoram',
      'thingsToDo': ['swimming', 'picnic'],
      'entryFees': [
        {'type': 'adult', 'amount': '₹30'},
      ],
      'tags': ['waterfall', 'nature'],
      'latitude': 23.4,
      'longitude': 92.7,
    };

    test('fromJson parses all fields correctly', () {
      final spot = SpotModel.fromJson(fullJson());

      expect(spot.id, 'spot1');
      expect(spot.name, 'Vantawng Falls');
      expect(spot.category, 'waterfall');
      expect(spot.locationAddress, 'Thenzawl, Mizoram');
      expect(spot.district, 'Serchhip');
      expect(spot.averageRating, 4.7);
      expect(spot.popularity, 9.2);
      expect(spot.ratingsCount, 312);
      expect(spot.featured, isTrue);
      expect(spot.status, 'approved');
      expect(spot.views, 5000);
      expect(spot.bestSeason, 'October–March');
      expect(spot.placeStory, 'Tallest waterfall in Mizoram');
      expect(spot.thingsToDo, ['swimming', 'picnic']);
      expect(spot.tags, ['waterfall', 'nature']);
      expect(spot.latitude, 23.4);
      expect(spot.longitude, 92.7);
    });

    test('heroImage returns first image from imagesUrl', () {
      final spot = SpotModel.fromJson(fullJson());
      expect(spot.heroImage, 'https://img1.jpg');
    });

    test('heroImage returns empty string when imagesUrl is empty', () {
      final data = Map<String, dynamic>.from(fullJson());
      data['imagesUrl'] = [];
      final spot = SpotModel.fromJson(data);
      expect(spot.heroImage, '');
    });

    test('fromJson defaults numeric fields to 0 when missing', () {
      final spot = SpotModel.fromJson({
        'id': 'x',
        'name': 'N',
        'category': '',
        'locationAddress': '',
        'district': '',
        'status': '',
      });
      expect(spot.averageRating, 0.0);
      expect(spot.popularity, 0.0);
      expect(spot.ratingsCount, 0);
      expect(spot.views, 0);
      expect(spot.featured, isFalse);
    });

    test('fromJson coerces int averageRating to double', () {
      final data = Map<String, dynamic>.from(fullJson());
      data['averageRating'] = 4; // int in JSON
      final spot = SpotModel.fromJson(data);
      expect(spot.averageRating, isA<double>());
      expect(spot.averageRating, 4.0);
    });

    test('fromJson parses nested entryFees list', () {
      final spot = SpotModel.fromJson(fullJson());
      expect(spot.entryFees.length, 1);
      expect(spot.entryFees.first.type, 'adult');
      expect(spot.entryFees.first.amount, '₹30');
    });

    test('fromJson parses nested ratings list', () {
      final data = Map<String, dynamic>.from(fullJson());
      data['ratings'] = [
        {'userId': 'u1', 'userName': 'A', 'rating': 5.0, 'timestamp': 'ts'},
        {'userId': 'u2', 'userName': 'B', 'rating': 4.0, 'timestamp': 'ts2'},
      ];
      final spot = SpotModel.fromJson(data);
      expect(spot.ratings.length, 2);
      expect(spot.ratings.first.rating, 5.0);
    });

    test('fromJson parses nested comments list', () {
      final data = Map<String, dynamic>.from(fullJson());
      data['comments'] = [
        {
          'userId': 'u1',
          'userName': 'A',
          'comment': 'Great!',
          'timestamp': 'ts',
        },
      ];
      final spot = SpotModel.fromJson(data);
      expect(spot.comments.length, 1);
      expect(spot.comments.first.comment, 'Great!');
    });

    test('fromJson handles missing optional fields gracefully', () {
      final spot = SpotModel.fromJson({
        'id': 'spot2',
        'name': 'Reiek',
        'category': 'peak',
        'locationAddress': 'Reiek, Mizoram',
        'district': 'Mamit',
        'status': 'approved',
      });
      expect(spot.bestSeason, isNull);
      expect(spot.placeStory, isNull);
      expect(spot.latitude, isNull);
      expect(spot.longitude, isNull);
      expect(spot.alternateNames, isEmpty);
      expect(spot.thingsToDo, isEmpty);
      expect(spot.entryFees, isEmpty);
    });

    test('fromJson parses alternateNames list', () {
      final data = Map<String, dynamic>.from(fullJson());
      data['alternateNames'] = ['Vantawng', 'Thosiem Falls'];
      final spot = SpotModel.fromJson(data);
      expect(spot.alternateNames, ['Vantawng', 'Thosiem Falls']);
    });
  });
}
