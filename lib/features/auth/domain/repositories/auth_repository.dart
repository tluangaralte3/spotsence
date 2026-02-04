import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Repository interface for authentication
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign in with Google
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Get current user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Check authentication state
  Stream<UserEntity?> get authStateChanges;

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Update user profile
  Future<Either<Failure, void>> updateUserProfile(UserEntity user);

  /// Delete account
  Future<Either<Failure, void>> deleteAccount();
}
