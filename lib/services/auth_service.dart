import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, FirebaseFirestore.instance);
});

/// Thin result wrapper used by AuthController.
sealed class AuthResult<T> {
  const AuthResult();
}

class AuthOk<T> extends AuthResult<T> {
  final T value;
  const AuthOk(this.value);
}

class AuthErr<T> extends AuthResult<T> {
  final String message;
  const AuthErr(this.message);
}

extension AuthResultX<T> on AuthResult<T> {
  R when<R>({
    required R Function(T value) ok,
    required R Function(String msg) err,
  }) {
    return switch (this) {
      AuthOk<T> r => ok(r.value),
      AuthErr<T> r => err(r.message),
    };
  }
}

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const _users = 'users';

  AuthService(this._auth, this._db);

  // ── Auth state ────────────────────────────────────────────────────────

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;

  // ── Sign in ───────────────────────────────────────────────────────────

  Future<AuthResult<UserModel>> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return const AuthErr('Sign in cancelled.');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final user = await _fetchOrCreateProfile(cred.user!);
      return AuthOk(user);
    } on FirebaseAuthException catch (e) {
      return AuthErr(_authMessage(e.code));
    } catch (e) {
      return AuthErr('Google sign in failed. Please try again.');
    }
  }

  Future<AuthResult<UserModel>> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = await _fetchOrCreateProfile(cred.user!);
      return AuthOk(user);
    } on FirebaseAuthException catch (e) {
      return AuthErr(_authMessage(e.code));
    } catch (e) {
      return AuthErr('Sign in failed. Please try again.');
    }
  }

  // ── Register ──────────────────────────────────────────────────────────

  Future<AuthResult<UserModel>> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. Create Firebase Auth account
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // 2. Update display name in Firebase Auth
      await cred.user!.updateDisplayName(displayName.trim());

      // 3. Write initial Firestore user document
      final now = DateTime.now();
      final uid = cred.user!.uid;
      final userDoc = {
        'id': uid,
        'email': email.trim(),
        'displayName': displayName.trim(),
        'photoURL': null,
        'bio': null,
        'location': null,
        'role': 1, // 0 = admin, 1 = regular user
        'points': 0,
        'level': 1,
        'levelTitle': 'Explorer',
        'badges': <String>[],
        'badgesEarned': <String>[],
        'contributionsCount': 0,
        'ratingsCount': 0,
        'bookmarks': <String>[],
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      await _db.collection(_users).doc(uid).set(userDoc);

      final user = UserModel.fromJson(userDoc);
      return AuthOk(user);
    } on FirebaseAuthException catch (e) {
      return AuthErr(_authMessage(e.code));
    } catch (e) {
      return AuthErr('Registration failed. Please try again.');
    }
  }

  // ── Fetch profile from Firestore ──────────────────────────────────────

  Future<AuthResult<UserModel>> getMyProfile() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const AuthErr('Not signed in.');
      final user = await _fetchOrCreateProfile(_auth.currentUser!);
      return AuthOk(user);
    } catch (e) {
      return AuthErr('Could not load profile.');
    }
  }

  /// Stream of the current user's Firestore document — live updates.
  Stream<UserModel?> watchMyProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db.collection(_users).doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromFirestore(snap);
    });
  }

  // ── Update profile ────────────────────────────────────────────────────

  Future<AuthResult<UserModel>> updateProfile({
    String? displayName,
    String? photoURL,
    String? bio,
    String? location,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return const AuthErr('Not signed in.');

      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
        if (displayName != null) 'displayName': displayName.trim(),
        'photoURL': ?photoURL,
        if (bio != null) 'bio': bio.trim(),
        if (location != null) 'location': location.trim(),
      };
      await _db.collection(_users).doc(uid).update(updates);

      // Also sync display name in Firebase Auth
      if (displayName != null) {
        await _auth.currentUser!.updateDisplayName(displayName.trim());
      }

      final snap = await _db.collection(_users).doc(uid).get();
      final user = UserModel.fromFirestore(snap);
      return AuthOk(user);
    } catch (e) {
      return AuthErr('Profile update failed.');
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // ── Password reset ────────────────────────────────────────────────────

  Future<AuthResult<void>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthOk(null);
    } on FirebaseAuthException catch (e) {
      return AuthErr(_authMessage(e.code));
    } catch (_) {
      return const AuthErr('Could not send reset email.');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Fetch the user's Firestore profile; create it if it doesn't exist yet
  /// (handles accounts created outside the app, e.g. Firebase Console).
  Future<UserModel> _fetchOrCreateProfile(User firebaseUser) async {
    final snap = await _db.collection(_users).doc(firebaseUser.uid).get();

    if (snap.exists) {
      return UserModel.fromFirestore(snap);
    }

    // Auto-create a minimal profile
    final now = DateTime.now();
    final userDoc = {
      'id': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'displayName': firebaseUser.displayName ?? 'User',
      'photoURL': firebaseUser.photoURL,
      'bio': null,
      'location': null,
      'role': 1,
      'points': 0,
      'level': 1,
      'levelTitle': 'Explorer',
      'badges': <String>[],
      'badgesEarned': <String>[],
      'contributionsCount': 0,
      'ratingsCount': 0,
      'bookmarks': <String>[],
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    await _db.collection(_users).doc(firebaseUser.uid).set(userDoc);
    return UserModel.fromJson(userDoc);
  }

  /// Human-readable messages for Firebase Auth error codes.
  String _authMessage(String code) => switch (code) {
    'user-not-found' => 'No account found with this email.',
    'wrong-password' => 'Incorrect password.',
    'invalid-credential' => 'Invalid email or password.',
    'email-already-in-use' => 'An account with this email already exists.',
    'weak-password' => 'Password must be at least 6 characters.',
    'invalid-email' => 'Please enter a valid email address.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'No internet connection.',
    _ => 'Authentication error. Please try again.',
  };
}
