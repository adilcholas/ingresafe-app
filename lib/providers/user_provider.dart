import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/services/auth_service.dart';
import '../models/health_profile_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class UserProvider with ChangeNotifier {
  User? _user;
  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;
  HealthProfileModel _healthProfile = HealthProfileModel();

  User? get user => _user;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  String? get errorMessage => _errorMessage;
  HealthProfileModel get healthProfile => _healthProfile;

  String get displayName =>
      _user?.displayName?.isNotEmpty == true
          ? _user!.displayName!
          : (_user?.email?.split('@').first ?? 'User');

  String get email => _user?.email ?? '';
  String get uid => _user?.uid ?? '';

  UserProvider() {
    // Listen to Firebase auth state changes
    AuthService.authStateChanges.listen(_onAuthStateChange);
  }

  // ── Auth State Listener ────────────────────────────────────────────────────

  Future<void> _onAuthStateChange(User? user) async {
    _user = user;
    if (user != null) {
      _status = AuthStatus.authenticated;
      await _loadHealthProfile(user.uid);
    } else {
      _status = AuthStatus.unauthenticated;
      _healthProfile = HealthProfileModel();
    }
    notifyListeners();
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    final result = await AuthService.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
    _setLoading(false);

    if (!result.success) {
      _errorMessage = result.errorMessage;
      notifyListeners();
    }
    return result.success;
  }

  // ── Sign In ────────────────────────────────────────────────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    final result = await AuthService.signIn(email: email, password: password);
    _setLoading(false);

    if (!result.success) {
      _errorMessage = result.errorMessage;
      notifyListeners();
    }
    return result.success;
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await AuthService.signOut();
    // Auth state listener will handle status update
  }

  // ── Password Reset ─────────────────────────────────────────────────────────

  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    final result = await AuthService.sendPasswordReset(email);
    _setLoading(false);

    if (!result.success) {
      _errorMessage = result.errorMessage;
      notifyListeners();
    }
    return result.success;
  }

  // ── Health Profile ─────────────────────────────────────────────────────────

  Future<void> _loadHealthProfile(String uid) async {
    final data = await AuthService.fetchUserProfile(uid);
    if (data != null && data['healthProfile'] != null) {
      final hp = data['healthProfile'] as Map<String, dynamic>;
      _healthProfile = HealthProfileModel(
        allergies: List<String>.from(hp['allergies'] ?? []),
        dietaryPreferences: List<String>.from(hp['dietaryPreferences'] ?? []),
        healthConditions: List<String>.from(hp['healthConditions'] ?? []),
      );
    }
  }

  void updateHealthProfileLocally(HealthProfileModel profile) {
    _healthProfile = profile;
    notifyListeners();
    // Persist to Firestore
    if (_user != null) {
      AuthService.saveHealthProfile(
        _user!.uid,
        allergies: profile.allergies,
        dietaryPreferences: profile.dietaryPreferences,
        healthConditions: profile.healthConditions,
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _errorMessage = null;
    notifyListeners();
  }
}
