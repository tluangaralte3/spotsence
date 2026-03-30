import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';
import '../models/listing_models.dart';
import '../models/spot_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ListingsService
// ─────────────────────────────────────────────────────────────────────────────

class ListingsService extends BaseApiService {
  ListingsService(super.dio);

  // ── Tourist Spots ────────────────────────────────────────────────────────

  Future<ApiResult<List<SpotModel>>> getTouristSpots({
    int page = 1,
    int limit = 20,
    String? district,
    String? category,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/spots',
        queryParameters: {
          'page': page,
          'limit': limit,
          'status': 'Approved',
          'district': ?district,
          'category': ?category,
        },
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => SpotModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  // ── Restaurants ──────────────────────────────────────────────────────────

  Future<ApiResult<List<RestaurantModel>>> getRestaurants({
    int page = 1,
    int limit = 20,
    String? district,
    String? priceRange,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/listings/restaurants',
        queryParameters: {
          'page': page,
          'limit': limit,
          'district': ?district,
          'priceRange': ?priceRange,
        },
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => RestaurantModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  // ── Hotels ───────────────────────────────────────────────────────────────

  Future<ApiResult<List<HotelModel>>> getHotels({
    int page = 1,
    int limit = 20,
    String? district,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/listings/hotels',
        queryParameters: {
          'page': page,
          'limit': limit,
          'district': ?district,
        },
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => HotelModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  // ── Cafes ────────────────────────────────────────────────────────────────

  Future<ApiResult<List<CafeModel>>> getCafes({
    int page = 1,
    int limit = 20,
    String? district,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/listings/cafes',
        queryParameters: {
          'page': page,
          'limit': limit,
          'district': ?district,
        },
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => CafeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  // ── Homestays ────────────────────────────────────────────────────────────

  Future<ApiResult<List<HomestayModel>>> getHomestays({
    int page = 1,
    int limit = 20,
    String? district,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/listings/homestays',
        queryParameters: {
          'page': page,
          'limit': limit,
          'district': ?district,
        },
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => HomestayModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  // ── Adventure Spots ──────────────────────────────────────────────────────

  Future<ApiResult<List<AdventureSpotModel>>> getAdventureSpots({
    int page = 1,
    int limit = 20,
    String? district,
    String? difficulty,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/listings/adventure-spots',
        queryParameters: {
          'page': page,
          'limit': limit,
          'district': ?district,
          'difficulty': ?difficulty,
        },
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => AdventureSpotModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  // ── Shopping Areas ───────────────────────────────────────────────────────

  Future<ApiResult<List<ShoppingAreaModel>>> getShoppingAreas({
    int page = 1,
    int limit = 20,
    String? district,
    String? type,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/listings/shopping-areas',
        queryParameters: {
          'page': page,
          'limit': limit,
          'district': ?district,
          'type': ?type,
        },
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => ShoppingAreaModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  // ── Events ───────────────────────────────────────────────────────────────

  Future<ApiResult<List<EventModel>>> getEvents({
    int page = 1,
    int limit = 20,
    String? type,
    bool? upcomingOnly,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/listings/events',
        queryParameters: {
          'page': page,
          'limit': limit,
          'type': ?type,
          if (upcomingOnly == true) 'upcoming': 'true',
        },
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  // ── Generic detail ───────────────────────────────────────────────────────

  Future<ApiResult<Map<String, dynamic>>> getListingDetail(
    String type,
    String id,
  ) async {
    return safeCall(() async {
      final response = await dio.get('/api/listings/$type/$id');
      return unwrap(response, (json) => json as Map<String, dynamic>);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final listingsServiceProvider = Provider<ListingsService>((ref) {
  return ListingsService(ref.watch(dioProvider));
});
