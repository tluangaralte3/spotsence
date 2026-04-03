import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spot_model.dart';
import '../models/gamification_models.dart';
import 'api_client.dart';

final spotsServiceProvider = Provider<SpotsService>((ref) {
  return SpotsService(ref.watch(dioProvider));
});

class SpotsService extends BaseApiService {
  SpotsService(super.dio);

  Future<ApiResult<List<SpotModel>>> getSpots({
    String? category,
    int page = 1,
    int pageSize = 20,
    String sortBy = 'popularity',
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/spots',
        queryParameters: {
          'category': ?category,
          'page': page,
          'pageSize': pageSize,
          'sortBy': sortBy,
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

  Future<ApiResult<List<SpotModel>>> getFeaturedSpots({int limit = 8}) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/spots/featured',
        queryParameters: {'limit': limit},
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => SpotModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  Future<ApiResult<SpotModel>> getSpotDetail(String id) async {
    return safeCall(() async {
      final response = await dio.get('/api/spots/$id');
      return unwrap(
        response,
        (json) => SpotModel.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  Future<ApiResult<bool>> toggleBookmark(String spotId) async {
    return safeCall(() async {
      final response = await dio.post('/api/spots/$spotId');
      return unwrap(
        response,
        (json) => (json as Map<String, dynamic>)['bookmarked'] as bool,
      );
    });
  }

  Future<ApiResult<List<SpotModel>>> search(
    String query, {
    String? category,
    int page = 1,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/search',
        queryParameters: {
          'q': query,
          'category': ?category,
          'page': page,
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

  Future<ApiResult<List<Map<String, dynamic>>>> getCategories() async {
    return safeCall(() async {
      final response = await dio.get('/api/categories');
      return unwrap(response, (json) {
        final list = json as List;
        return list.cast<Map<String, dynamic>>();
      });
    });
  }

  Future<ApiResult<List<SpotModel>>> getBookmarks(
    String userId, {
    CancelToken? cancelToken,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/users/$userId/bookmarks',
        cancelToken: cancelToken,
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => SpotModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  Future<ApiResult<List<ReviewModel>>> getReviews(
    String spotId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/reviews',
        queryParameters: {'spotId': spotId, 'page': page, 'pageSize': pageSize},
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  Future<ApiResult<Map<String, dynamic>>> submitReview({
    required String spotId,
    required double rating,
    required String comment,
  }) async {
    return safeCall(() async {
      final response = await dio.post(
        '/api/reviews',
        data: {'spotId': spotId, 'rating': rating, 'comment': comment},
      );
      return unwrap(response, (json) => json as Map<String, dynamic>);
    });
  }
}
