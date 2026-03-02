import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/community_models.dart';
import '../models/gamification_models.dart';
import 'api_client.dart';

final communityServiceProvider = Provider<CommunityService>((ref) {
  return CommunityService(ref.watch(dioProvider));
});

class CommunityService extends BaseApiService {
  CommunityService(Dio dio) : super(dio);

  // ── Posts ─────────────────────────────────────────────────────────────

  Future<ApiResult<List<CommunityPost>>> getPosts({
    int page = 1,
    int pageSize = 20,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/community/posts',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  Future<ApiResult<CommunityPost>> createPost({
    required String content,
    required String type,
    List<String>? images,
    String? spotId,
    String? spotName,
    String? location,
  }) async {
    return safeCall(() async {
      final response = await dio.post(
        '/api/community/posts',
        data: {
          'content': content,
          'type': type,
          if (images != null) 'images': images,
          if (spotId != null) 'spotId': spotId,
          if (spotName != null) 'spotName': spotName,
          if (location != null) 'location': location,
        },
      );
      return unwrap(
        response,
        (json) => CommunityPost.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  Future<ApiResult<Map<String, dynamic>>> toggleLike(String postId) async {
    return safeCall(() async {
      final response = await dio.post('/api/community/posts/$postId/like');
      return unwrap(response, (json) => json as Map<String, dynamic>);
    });
  }

  Future<ApiResult<void>> addComment(String postId, String comment) async {
    return safeCall(() async {
      final response = await dio.post(
        '/api/community/posts/$postId/comment',
        data: {'comment': comment},
      );
      return unwrap(response, (_) => null);
    });
  }

  // ── Bucket Lists ──────────────────────────────────────────────────────

  Future<ApiResult<List<BucketList>>> getBucketLists({
    int page = 1,
    int pageSize = 20,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/community/bucket-lists',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => BucketList.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  Future<ApiResult<BucketList>> createBucketList({
    required String title,
    String? description,
    int maxParticipants = 10,
    String? startDate,
    String? endDate,
  }) async {
    return safeCall(() async {
      final response = await dio.post(
        '/api/community/bucket-lists',
        data: {
          'title': title,
          if (description != null) 'description': description,
          'maxParticipants': maxParticipants,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
        },
      );
      return unwrap(
        response,
        (json) => BucketList.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  // ── Dilemmas ──────────────────────────────────────────────────────────

  Future<ApiResult<List<Dilemma>>> getDilemmas({
    int page = 1,
    int pageSize = 20,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/community/dilemmas',
        queryParameters: {'page': page, 'pageSize': pageSize},
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => Dilemma.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  Future<ApiResult<Map<String, dynamic>>> voteDilemma(
    String dilemmaId,
    String option,
  ) async {
    return safeCall(() async {
      final response = await dio.post(
        '/api/community/dilemmas/$dilemmaId/vote',
        data: {'option': option},
      );
      return unwrap(response, (json) => json as Map<String, dynamic>);
    });
  }

  // ── Leaderboard ───────────────────────────────────────────────────────

  Future<ApiResult<List<LeaderboardEntry>>> getLeaderboard({
    int limit = 50,
  }) async {
    return safeCall(() async {
      final response = await dio.get(
        '/api/leaderboard',
        queryParameters: {'limit': limit},
      );
      return unwrap(response, (json) {
        final list = json as List;
        return list
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    });
  }

  // ── Contributions ─────────────────────────────────────────────────────

  /// Submit a new tourist spot. Returns null on success, error string on failure.
  Future<String?> createContribution({
    required String name,
    required String description,
    required String category,
    required String city,
    String address = '',
    double? lat,
    double? lng,
    List<XFile> photos = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'description': description,
        'category': category,
        'city': city,
        if (address.isNotEmpty) 'address': address,
        if (lat != null) 'lat': lat.toString(),
        if (lng != null) 'lng': lng.toString(),
        'photos': [
          for (final p in photos)
            await MultipartFile.fromFile(p.path, filename: p.name),
        ],
      });

      await dio.post('/api/contributions', data: formData);
      return null; // success
    } on DioException catch (e) {
      return e.response?.data?['error'] as String? ??
          e.message ??
          'Submission failed';
    } catch (e) {
      return e.toString();
    }
  }
}
