import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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
    // Listen to Firebase auth state changes
    ref.listen(firebaseAuthStreamProvider, (prev, next) {
      next.whenData((firebaseUser) async {
        if (firebaseUser != null) {
          _loadProfile();
        } else {
          state = const AsyncData(
            AuthState(status: AuthStatus.unauthenticated),
          );
        }
      });
    });

    // Check current auth on startup
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

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<String?> signIn(String email, String password) async {
    state = const AsyncLoading();
    final result = await _authService.signInWithEmail(email, password);
    return result.when(
      ok: (_) {
        // _loadProfile will be triggered by firebaseAuthStreamProvider
        return null; // null = success
      },
      err: (msg) {
        state = AsyncData(
          AuthState(status: AuthStatus.error, errorMessage: msg),
        );
        return msg;
      },
    );
  }

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

  /// Refresh the profile from the API.
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
