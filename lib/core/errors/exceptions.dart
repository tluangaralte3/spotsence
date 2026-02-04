/// Base exception class
class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => code != null ? '[$code] $message' : message;
}

/// Server/API exceptions
class ServerException extends AppException {
  ServerException([String message = 'Server error occurred', String? code])
    : super(message, code);
}

/// Network exceptions
class NetworkException extends AppException {
  NetworkException([String message = 'No internet connection', String? code])
    : super(message, code);
}

/// Cache exceptions
class CacheException extends AppException {
  CacheException([String message = 'Cache error occurred', String? code])
    : super(message, code);
}

/// Authentication exceptions
class AuthException extends AppException {
  AuthException([String message = 'Authentication failed', String? code])
    : super(message, code);
}

/// Permission exceptions
class PermissionException extends AppException {
  PermissionException([String message = 'Permission denied', String? code])
    : super(message, code);
}

/// Validation exceptions
class ValidationException extends AppException {
  ValidationException([String message = 'Validation failed', String? code])
    : super(message, code);
}

/// Not found exceptions
class NotFoundException extends AppException {
  NotFoundException([String message = 'Resource not found', String? code])
    : super(message, code);
}

/// Firestore exceptions
class FirestoreException extends AppException {
  FirestoreException([String message = 'Database error occurred', String? code])
    : super(message, code);
}

/// Firebase Storage exceptions
class StorageException extends AppException {
  StorageException([String message = 'Storage error occurred', String? code])
    : super(message, code);
}

/// Location exceptions
class LocationException extends AppException {
  LocationException([String message = 'Location error occurred', String? code])
    : super(message, code);
}

/// Image processing exceptions
class ImageException extends AppException {
  ImageException([String message = 'Image processing failed', String? code])
    : super(message, code);
}
