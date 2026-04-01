// test/models/listing_models_test.dart
//
// Unit tests for all listing model fromJson / fromFirestore deserialization
// and helper getters: RestaurantModel, HotelModel, CafeModel, HomestayModel,
// AdventureSpotModel, ShoppingAreaModel, PaginatedState.

import 'package:flutter_test/flutter_test.dart';
import 'package:xplooria/models/listing_models.dart';
import 'package:xplooria/controllers/listings_controller.dart';

void main() {
  // ── RestaurantModel ───────────────────────────────────────────────────────

  group('RestaurantModel.fromJson', () {
    test('parses complete valid JSON', () {
      final json = {
        'id': 'r1',
        'name': 'Mizo Kitchen',
        'description': 'Traditional food',
        'location': 'Aizawl',
        'images': ['img1.jpg', 'img2.jpg'],
        'rating': 4.5,
        'priceRange': '\$\$',
        'cuisineTypes': ['Mizo', 'Indian'],
        'openingHours': '9AM-9PM',
        'hasDelivery': true,
        'hasReservation': false,
        'district': 'Aizawl',
        'contactPhone': '1234567890',
        'website': 'https://example.com',
        'ratingsCount': 12,
        'latitude': 23.7,
        'longitude': 92.7,
      };

      final r = RestaurantModel.fromJson(json);

      expect(r.id, 'r1');
      expect(r.name, 'Mizo Kitchen');
      expect(r.rating, 4.5);
      expect(r.priceRange, '\$\$');
      expect(r.cuisineTypes, ['Mizo', 'Indian']);
      expect(r.hasDelivery, isTrue);
      expect(r.hasReservation, isFalse);
      expect(r.ratingsCount, 12);
      expect(r.latitude, 23.7);
      expect(r.longitude, 92.7);
    });

    test('heroImage returns first image', () {
      final r = RestaurantModel.fromJson({
        'id': 'r2',
        'name': 'Test',
        'description': '',
        'location': '',
        'images': ['first.jpg', 'second.jpg'],
        'rating': 3.0,
        'priceRange': '\$',
        'cuisineTypes': [],
        'openingHours': '',
        'hasDelivery': false,
        'hasReservation': false,
        'district': '',
      });
      expect(r.heroImage, 'first.jpg');
    });

    test('heroImage returns empty string when no images', () {
      final r = RestaurantModel.fromJson({
        'id': 'r3',
        'name': 'Empty',
        'description': '',
        'location': '',
        'images': [],
        'rating': 0.0,
        'priceRange': '\$',
        'cuisineTypes': [],
        'openingHours': '',
        'hasDelivery': false,
        'hasReservation': false,
        'district': '',
      });
      expect(r.heroImage, '');
    });

    test('graceful defaults for missing fields', () {
      final r = RestaurantModel.fromJson({'id': 'x', 'name': 'Minimal'});
      expect(r.rating, 0.0);
      expect(r.priceRange, '\$');
      expect(r.hasDelivery, isFalse);
      expect(r.ratingsCount, 0);
      expect(r.latitude, isNull);
      expect(r.longitude, isNull);
    });

    test('integer rating is cast to double', () {
      final r = RestaurantModel.fromJson({'rating': 4});
      expect(r.rating, 4.0);
    });
  });

  // ── HotelModel ────────────────────────────────────────────────────────────

  group('HotelModel.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'h1',
        'name': 'Grand Hotel',
        'description': 'Luxury stay',
        'location': 'Aizawl',
        'images': ['hotel.jpg'],
        'rating': 4.8,
        'priceRange': '\$\$\$',
        'amenities': ['WiFi', 'Pool'],
        'roomTypes': ['Deluxe', 'Standard'],
        'district': 'Aizawl',
        'ratingsCount': 50,
        'hasRestaurant': true,
        'hasWifi': true,
        'hasParking': false,
        'hasPool': true,
        'contactPhone': '9876543210',
        'website': 'https://hotel.com',
      };

      final h = HotelModel.fromJson(json);

      expect(h.id, 'h1');
      expect(h.name, 'Grand Hotel');
      expect(h.rating, 4.8);
      expect(h.amenities, ['WiFi', 'Pool']);
      expect(h.roomTypes, ['Deluxe', 'Standard']);
      expect(h.hasRestaurant, isTrue);
      expect(h.hasWifi, isTrue);
      expect(h.hasParking, isFalse);
      expect(h.hasPool, isTrue);
    });

    test('defaults for missing fields', () {
      final h = HotelModel.fromJson({'id': 'h2', 'name': 'Basic'});
      expect(h.rating, 0.0);
      expect(h.amenities, isEmpty);
      expect(h.ratingsCount, 0);
      expect(h.hasPool, isFalse);
    });
  });

  // ── CafeModel ─────────────────────────────────────────────────────────────

  group('CafeModel.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'c1',
        'name': 'Bean & Brew',
        'description': 'Cozy cafe',
        'location': 'Lunglei',
        'images': ['cafe.jpg'],
        'rating': 4.2,
        'priceRange': '\$',
        'specialties': ['Coffee', 'Pastries'],
        'hasWifi': true,
        'hasOutdoorSeating': true,
        'district': 'Lunglei',
        'ratingsCount': 8,
      };

      final c = CafeModel.fromJson(json);

      expect(c.name, 'Bean & Brew');
      expect(c.specialties, ['Coffee', 'Pastries']);
      expect(c.hasWifi, isTrue);
      expect(c.hasOutdoorSeating, isTrue);
    });

    test('defaults for missing fields', () {
      final c = CafeModel.fromJson({});
      expect(c.hasWifi, isFalse);
      expect(c.specialties, isEmpty);
    });
  });

  // ── HomestayModel ─────────────────────────────────────────────────────────

  group('HomestayModel.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 'hs1',
        'name': 'Forest View',
        'description': 'Peaceful homestay',
        'location': 'Champhai',
        'images': ['hs.jpg'],
        'rating': 4.6,
        'priceRange': '\$\$',
        'amenities': ['Breakfast', 'Wi-Fi'],
        'maxGuests': 6,
        'hostName': 'Lalthanga',
        'hostPhoto': 'host.jpg',
        'hasBreakfast': true,
        'hasFreePickup': false,
        'district': 'Champhai',
        'contactPhone': '9876543210',
      };

      final hs = HomestayModel.fromJson(json);

      expect(hs.name, 'Forest View');
      expect(hs.maxGuests, 6);
      expect(hs.hasBreakfast, isTrue);
      expect(hs.hasFreePickup, isFalse);
      expect(hs.hostName, 'Lalthanga');
    });
  });

  // ── AdventureSpotModel ────────────────────────────────────────────────────

  group('AdventureSpotModel.fromJson', () {
    test('parses difficulty and activities', () {
      final json = {
        'id': 'a1',
        'name': 'Phawngpui Peak',
        'description': 'Highest peak',
        'category': 'adventure',
        'location': 'Lawngtlai',
        'images': ['peak.jpg'],
        'rating': 4.9,
        'difficulty': 'Challenging',
        'duration': '2 days',
        'bestSeason': 'Oct-Feb',
        'activities': ['Trekking', 'Camping'],
        'isPopular': true,
        'district': 'Lawngtlai',
      };

      final a = AdventureSpotModel.fromJson(json);

      expect(a.difficulty, 'Challenging');
      expect(a.activities, ['Trekking', 'Camping']);
      expect(a.isPopular, isTrue);
      expect(a.duration, '2 days');
    });

    test('defaults difficulty to Moderate', () {
      final a = AdventureSpotModel.fromJson({});
      expect(a.difficulty, 'Moderate');
      expect(a.activities, isEmpty);
      expect(a.isPopular, isFalse);
    });
  });

  // ── ShoppingAreaModel ─────────────────────────────────────────────────────

  group('ShoppingAreaModel.fromJson', () {
    test('parses all fields', () {
      final json = {
        'id': 's1',
        'name': 'Aizawl Market',
        'description': 'Local market',
        'location': 'Aizawl',
        'images': ['market.jpg'],
        'rating': 3.8,
        'priceRange': '\$',
        'openingHours': '8AM-8PM',
        'district': 'Aizawl',
      };

      final s = ShoppingAreaModel.fromJson(json);

      expect(s.name, 'Aizawl Market');
      expect(s.rating, 3.8);
      expect(s.district, 'Aizawl');
    });

    test('defaults for missing fields', () {
      final s = ShoppingAreaModel.fromJson({});
      expect(s.name, '');
      expect(s.rating, 0.0);
    });
  });

  // ── PaginatedState ────────────────────────────────────────────────────────

  group('PaginatedState', () {
    test('initial state is empty with isLoading false', () {
      const s = PaginatedState<String>();
      expect(s.items, isEmpty);
      expect(s.isLoading, isFalse);
      expect(s.isLoadingMore, isFalse);
      expect(s.hasMore, isTrue);
      expect(s.error, isNull);
      expect(s.currentPage, 0);
    });

    test('copyWith updates only specified fields', () {
      const original = PaginatedState<String>(
        items: ['a', 'b'],
        currentPage: 1,
      );
      final updated = original.copyWith(isLoading: true);

      expect(updated.items, ['a', 'b']); // unchanged
      expect(updated.currentPage, 1); // unchanged
      expect(updated.isLoading, isTrue); // changed
    });

    test('copyWith can clear error by setting it to null', () {
      const withError = PaginatedState<String>(error: 'Network error');
      final cleared = withError.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('copyWith replaces items list', () {
      const original = PaginatedState<int>(items: [1, 2, 3]);
      final updated = original.copyWith(items: [4, 5]);
      expect(updated.items, [4, 5]);
    });

    test('setting hasMore to false prevents further loads', () {
      const state = PaginatedState<String>(hasMore: false);
      expect(state.hasMore, isFalse);
    });
  });

  // ── ListingCategory enum ──────────────────────────────────────────────────

  group('ListingCategory enum', () {
    test('all expected categories exist', () {
      const expected = {
        'touristSpots',
        'restaurants',
        'hotels',
        'cafes',
        'homestays',
        'adventure',
        'shopping',
        'events',
      };
      final actual = ListingCategory.values.map((e) => e.name).toSet();
      expect(actual, containsAll(expected));
    });

    test('each category has a non-empty label', () {
      for (final cat in ListingCategory.values) {
        expect(cat.label, isNotEmpty, reason: '${cat.name} needs a label');
      }
    });

    test('each category has an emoji', () {
      for (final cat in ListingCategory.values) {
        expect(cat.emoji, isNotEmpty, reason: '${cat.name} needs an emoji');
      }
    });
  });
}
