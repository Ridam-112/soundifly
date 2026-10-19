import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  Session? _session;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isGuest = false;
  bool _needsPasswordReset = false;
  StreamSubscription<AuthState>? _authSubscription;

  User? get user => _user;
  Session? get session => _session;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _isGuest;
  bool get isAuthenticatedOrGuest => isAuthenticated || _isGuest;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get needsPasswordReset => _needsPasswordReset;

  /// Enable Guest mode to explore and listen without requiring credentials
  void continueAsGuest() {
    _isGuest = true;
    _errorMessage = null;
    notifyListeners();
  }

  /// Exit Guest mode and return to sign in / registration flow
  void exitGuestMode() {
    _isGuest = false;
    _errorMessage = null;
    notifyListeners();
  }

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    if (!SupabaseService.isInitialized) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final client = SupabaseService.client;

    // Restore existing session
    _session = client.auth.currentSession;
    _user = client.auth.currentUser;
    _isLoading = false;
    notifyListeners();

    // Listen to live Auth state changes
    _authSubscription = client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      _session = session;
      _user = session?.user ?? client.auth.currentUser;

      if (event == AuthChangeEvent.passwordRecovery) {
        _needsPasswordReset = true;
      } else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.signedOut) {
        _needsPasswordReset = false;
      }

      notifyListeners();
    }, onError: (err) {
      debugPrint('Auth state listener error: $err');
    });
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Sign Up with Email, Password and Full Name
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (!SupabaseService.isInitialized) {
      _errorMessage = 'Supabase backend is not initialized. Please check credentials.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
        },
      );

      _user = response.user;
      _session = response.session;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred during sign up. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign In with Email & Password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (!SupabaseService.isInitialized) {
      _errorMessage = 'Supabase backend is not initialized. Please check credentials.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      _session = response.session;
      _user = response.user;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to connect. Please check your network connection.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Send password recovery link to user's email
  Future<bool> sendPasswordResetEmail(String email) async {
    if (!SupabaseService.isInitialized) {
      _errorMessage = 'Supabase backend is not initialized.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb ? null : 'soundifly://reset-callback',
      );
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on AuthException catch (_) {
      // Security requirement: Do not reveal whether a particular email is registered
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isSubmitting = false;
      notifyListeners();
      return true;
    }
  }

  /// Update password after recovery deep link
  Future<bool> updatePassword(String newPassword) async {
    if (!SupabaseService.isInitialized) {
      _errorMessage = 'Supabase backend is not initialized.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      _needsPasswordReset = false;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update password. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Direct Sign In with Google OAuth
  Future<bool> signInWithGoogle() async {
    if (!SupabaseService.isInitialized) {
      _errorMessage = 'Supabase backend is not initialized.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'soundifly://login-callback',
      );
      _isSubmitting = false;
      notifyListeners();
      return success;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in could not be completed. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify 6-digit OTP code sent to email and update password
  Future<bool> verifyOtpAndResetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    if (!SupabaseService.isInitialized) {
      _errorMessage = 'Supabase backend is not initialized.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Verify OTP token for recovery
      final res = await SupabaseService.client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.recovery,
      );

      if (res.session == null && res.user == null) {
        _errorMessage = 'Invalid or expired code. Please request a new code.';
        _isSubmitting = false;
        notifyListeners();
        return false;
      }

      // 2. Set new password
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _needsPasswordReset = false;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      _isSubmitting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to reset password. Please check the code and try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out current user and clear local private user state
  Future<void> signOut() async {
    _isGuest = false;
    if (!SupabaseService.isInitialized) {
      _session = null;
      _user = null;
      _needsPasswordReset = false;
      _errorMessage = null;
      notifyListeners();
      return;
    }

    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _isGuest = false;
      _session = null;
      _user = null;
      _needsPasswordReset = false;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Friendly error message mapper that prevents user enumeration
  String _mapAuthError(AuthException e) {
    final msg = e.message.toLowerCase();

    if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
      return 'Invalid email or password. Please verify and try again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please check your email and confirm your account before signing in.';
    }
    if (msg.contains('user already registered') || msg.contains('user_already_exists')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('password should be at least')) {
      return 'Password must be at least 6 characters long.';
    }
    if (msg.contains('token is expired') || msg.contains('invalid token') || msg.contains('token has expired') || msg.contains('otp_expired')) {
      return 'The recovery code is invalid or has expired. Please request a new code.';
    }
    if (msg.contains('provider is not enabled') || msg.contains('unsupported provider')) {
      return 'Google sign-in is not enabled in Supabase yet. Please enable Google provider in your dashboard.';
    }
    if (msg.contains('rate limit')) {
      return 'Too many attempts. Please wait a few moments and try again.';
    }
    return e.message;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
