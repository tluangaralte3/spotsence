import 'package:equatable/equatable.dart';

/// Base class for all failures in the app
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred'])
    : super(message);
}

/// Network/Connection failures
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'No internet connection'])
    : super(message);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred'])
    : super(message);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Authentication failed'])
    : super(message);
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'Permission denied'])
    : super(message);
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Validation failed'])
    : super(message);
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Resource not found'])
    : super(message);
}

/// Firestore-specific failures
class FirestoreFailure extends Failure {
  const FirestoreFailure([String message = 'Database error occurred'])
    : super(message);
}

/// Firebase Storage failures
class StorageFailure extends Failure {
  const StorageFailure([String message = 'Storage error occurred'])
    : super(message);
}

/// Location/GPS failures
class LocationFailure extends Failure {
  const LocationFailure([String message = 'Location error occurred'])
    : super(message);
}

/// Image processing failures
class ImageFailure extends Failure {
  const ImageFailure([String message = 'Image processing failed'])
    : super(message);
}

/// Generic/Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'An unknown error occurred'])
    : super(message);
}
