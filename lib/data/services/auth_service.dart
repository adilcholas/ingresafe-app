import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result wrapper for auth operations
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  const AuthResult({required this.success, this.errorMessage, this.user});

  factory AuthResult.ok(User user) => AuthResult(success: true, user: user);
  factory AuthResult.fail(String msg) =>
      AuthResult(success: false, errorMessage: msg);
}

/// Central Firebase Auth + Firestore user-profile service.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _kOnboardedKey = 'ingresafe_onboarded';

  // ── Stream ─────────────────────────────────────────────────────────────────

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  // ── Onboarding Flag (SharedPreferences) ───────────────────────────────────

  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardedKey) ?? false;
  }

  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardedKey, true);
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────

  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user!;

      // Set display name on Firebase Auth profile
      await user.updateDisplayName(displayName.trim());

      // Create user document in Firestore
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'healthProfile': {
          'allergies': [],
          'dietaryPreferences': [],
          'healthConditions': [],
        },
      });

      debugPrint('[Auth] Sign-up success: ${user.uid}');
      return AuthResult.ok(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authErrorMessage(e.code));
    } catch (e) {
      return AuthResult.fail('An unexpected error occurred. Please try again.');
    }
  }

  // ── Sign In ────────────────────────────────────────────────────────────────

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      debugPrint('[Auth] Sign-in success: ${cred.user!.uid}');
      return AuthResult.ok(cred.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authErrorMessage(e.code));
    } catch (e) {
      return AuthResult.fail('An unexpected error occurred. Please try again.');
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  static Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('[Auth] Signed out.');
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  static Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authErrorMessage(e.code));
    }
  }

  // ── User Profile (Firestore) ───────────────────────────────────────────────

  /// Fetches the stored user document from Firestore.
  static Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      return snap.data();
    } catch (e) {
      debugPrint('[Auth] fetchUserProfile error: $e');
      return null;
    }
  }

  /// Saves / merges the health-profile sub-map in Firestore.
  static Future<void> saveHealthProfile(
    String uid, {
    required List<String> allergies,
    required List<String> dietaryPreferences,
    required List<String> healthConditions,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'healthProfile': {
          'allergies': allergies,
          'dietaryPreferences': dietaryPreferences,
          'healthConditions': healthConditions,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Auth] saveHealthProfile error: $e');
    }
  }

  // ── Error Message Mapping ──────────────────────────────────────────────────

  static String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
