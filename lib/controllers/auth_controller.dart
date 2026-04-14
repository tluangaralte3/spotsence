import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../services/notification_service.dart';

// ── SignInResult ──────────────────────────────────────────────────────────────

/// Returned by [AuthController.signIn].
/// On success, [errorMessage] is null and [redirectRoute] tells the UI
/// where to navigate ('/admin' for super admin, '/' for regular users).
class SignInResult {
  final String? errorMessage;
  final String redirectRoute;
  const SignInResult({this.errorMessage, this.redirectRoute = '/'});
  bool get isSuccess => errorMessage == null;
}

// ── Auth State ────────────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  const AuthState.initial()
    : status = AuthStatus.initial,
      user = null,
      errorMessage = null;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    errorMessage: errorMessage,
  );
}

// ── Firebase Auth stream provider ────────────────────────────────────────────

final firebaseAuthStreamProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ── Main Auth Controller ──────────────────────────────────────────────────────

class AuthController extends AsyncNotifier<AuthState> {
  AuthService get _authService => ref.read(authServiceProvider);

  @override
  Future<AuthState> build() async {
    // React to Firebase auth state changes (sign in / sign out)
    ref.listen(firebaseAuthStreamProvider, (prev, next) {
      next.whenData((firebaseUser) {
        if (firebaseUser != null) {
          _loadProfile();
        } else {
          state = const AsyncData(
            AuthState(status: AuthStatus.unauthenticated),
          );
        }
      });
    });

    // Initial check on startup
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    return _fetchProfile();
  }

  Future<AuthState> _fetchProfile() async {
    final result = await _authService.getMyProfile();
    return result.when(
      ok: (user) => AuthState(status: AuthStatus.authenticated, user: user),
      err: (_) => const AuthState(status: AuthStatus.unauthenticated),
    );
  }

  Future<void> _loadProfile() async {
    state = const AsyncData(AuthState(status: AuthStatus.loading));
    state = AsyncData(await _fetchProfile());
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  /// Signs in the user.
  /// Returns a [SignInResult] — check [SignInResult.errorMessage] for failure,
  /// or [SignInResult.redirectRoute] to know where to navigate on success.
  Future<SignInResult> signIn(String email, String password) async {
    state = const AsyncLoading();
    final result = await _authService.signInWithEmail(email, password);
    return result.when(
      ok: (user) async {
        state = AsyncData(
          AuthState(status: AuthStatus.authenticated, user: user),
        );
        // Check Firebase custom claim to decide where to land
        final adminService = ref.read(adminServiceProvider);
        final isSuperAdmin = await adminService.checkSuperAdminClaim();
        if (isSuperAdmin) {
          // Seed / update the admin Firestore document
          await adminService.seedSuperAdmin();
        }
        // Subscribe to FCM topics and persist the device token.
        unawaited(NotificationService.instance.subscribeToTopics());
        unawaited(NotificationService.instance.saveTokenToFirestore(user.id));
        return SignInResult(redirectRoute: isSuperAdmin ? '/admin' : '/');
      },
      err: (msg) {
        state = AsyncData(
          AuthState(status: AuthStatus.error, errorMessage: msg),
        );
        return SignInResult(errorMessage: msg);
      },
    );
  }

  /// Returns null on success, or an error message string.
  Future<String?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    final result = await _authService.registerWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    return result.when(
      ok: (user) {
        state = AsyncData(
          AuthState(status: AuthStatus.authenticated, user: user),
        );
        // Subscribe to FCM topics on registration, same as on login.
        unawaited(NotificationService.instance.subscribeToTopics());
        unawaited(NotificationService.instance.saveTokenToFirestore(user.id));
        return null;
      },
      err: (msg) {
        state = AsyncData(
          AuthState(status: AuthStatus.error, errorMessage: msg),
        );
        return msg;
      },
    );
  }

  Future<void> signOut() async {
    unawaited(NotificationService.instance.unsubscribeFromTopics());
    await _authService.signOut();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }

  Future<String?> sendPasswordReset(String email) async {
    final result = await _authService.sendPasswordReset(email);
    return result.when(ok: (_) => null, err: (msg) => msg);
  }

  Future<String?> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
    String? location,
  }) async {
    final result = await _authService.updateProfile(
      displayName: displayName,
      photoURL: photoURL,
      bio: bio,
      location: location,
    );
    return result.when(
      ok: (updatedUser) {
        state = AsyncData(state.value!.copyWith(user: updatedUser));
        return null;
      },
      err: (msg) => msg,
    );
  }

  /// Refresh the profile from Firestore.
  Future<void> refreshProfile() => _loadProfile();
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Convenient shortcut — just the UserModel or null.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).value?.user;
});

/// Whether the user is currently signed in.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).value?.isAuthenticated ?? false;
});

/// Live Firestore stream of the current user's profile.
/// Keeps the in-memory UserModel up-to-date when points/badges change.
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.watchMyProfile();
});
