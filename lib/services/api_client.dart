import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../core/constants/app_constants.dart';

/// Dio singleton provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Attach Firebase ID token to every request automatically
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Retry once with a fresh token on 401
        if (error.response?.statusCode == 401) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken(true); // force refresh
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final cloneReq = await Dio().fetch(error.requestOptions);
            return handler.resolve(cloneReq);
          }
        }
        handler.next(error);
      },
    ),
  );

  // Log requests/responses in debug mode
  assert(() {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
      ),
    );
    return true;
  }());

  return dio;
});

/// Generic API response wrapper
class ApiResult<T> {
  final T? data;
  final String? error;
  final bool success;
  final ApiMeta? meta;

  const ApiResult._({this.data, this.error, required this.success, this.meta});

  factory ApiResult.ok(T data, {ApiMeta? meta}) =>
      ApiResult._(data: data, success: true, meta: meta);

  factory ApiResult.err(String message) =>
      ApiResult._(error: message, success: false);

  bool get isOk => success;
  bool get isErr => !success;

  R when<R>({required R Function(T) ok, required R Function(String) err}) {
    if (success && data != null) return ok(data as T);
    return err(error ?? 'Unknown error');
  }
}

class ApiMeta {
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const ApiMeta({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) => ApiMeta(
    total: (json['total'] as num?)?.toInt() ?? 0,
    page: (json['page'] as num?)?.toInt() ?? 1,
    pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    hasMore: json['hasMore'] as bool? ?? false,
  );
}

/// Base class all services extend
abstract class BaseApiService {
  final Dio dio;
  BaseApiService(this.dio);

  /// Unwrap the standard { success, data, error, meta } envelope.
  ApiResult<T> unwrap<T>(Response response, T Function(dynamic json) fromJson) {
    try {
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true) {
        final meta = body['meta'] != null
            ? ApiMeta.fromJson(body['meta'] as Map<String, dynamic>)
            : null;
        return ApiResult.ok(fromJson(body['data']), meta: meta);
      }
      return ApiResult.err(body['error'] as String? ?? 'Request failed');
    } catch (e) {
      return ApiResult.err('Parse error: $e');
    }
  }

  /// Safe wrapper that catches Dio + network errors.
  Future<ApiResult<T>> safeCall<T>(Future<ApiResult<T>> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final msg =
          e.response?.data?['error'] as String? ?? e.message ?? 'Network error';
      return ApiResult.err(msg);
    } catch (e) {
      return ApiResult.err(e.toString());
    }
  }
}
