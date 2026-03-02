import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_client.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(dioProvider), FirebaseAuth.instance);
});

class AuthService extends BaseApiService {
  final FirebaseAuth _firebaseAuth;

  AuthService(Dio dio, this._firebaseAuth) : super(dio);

  // ── Firebase Auth stream ──────────────────────────────────────────────

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // ── Sign in with email / password ─────────────────────────────────────

  Future<ApiResult<UserCredential>> signInWithEmail(
    String email,
    String password,
  ) async {
    return safeCall(() async {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return ApiResult.ok(credential);
    });
  }

  // ── Register (via REST API so we get the Firestore doc created) ───────

  Future<ApiResult<UserModel>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return safeCall(() async {
      final response = await dio.post(
        '/api/auth/register',
        data: {
          'email': email.trim(),
          'password': password,
          'displayName': displayName.trim(),
        },
      );
      // After REST creates the user, sign them in via Firebase SDK
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return unwrap(
        response,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  // ── Get own Firestore profile ─────────────────────────────────────────

  Future<ApiResult<UserModel>> getMyProfile() async {
    return safeCall(() async {
      final response = await dio.get('/api/auth/me');
      return unwrap(
        response,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  // ── Update profile ────────────────────────────────────────────────────

  Future<ApiResult<UserModel>> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
    String? location,
  }) async {
    return safeCall(() async {
      final response = await dio.patch(
        '/api/auth/me',
        data: {
          if (displayName != null) 'displayName': displayName,
          if (photoURL != null) 'photoURL': photoURL,
          if (bio != null) 'bio': bio,
          if (location != null) 'location': location,
        },
      );
      return unwrap(
        response,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    });
  }

  // ── Sign out ──────────────────────────────────────────────────────────

  Future<void> signOut() => _firebaseAuth.signOut();

  // ── Password reset ────────────────────────────────────────────────────

  Future<ApiResult<void>> sendPasswordReset(String email) async {
    return safeCall(() async {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return ApiResult.ok(null);
    });
  }
}
