import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// A simple exception carrying a user-friendly message for the UI.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Handles Google Sign-In via Firebase Authentication.
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isBusy = false;
  String? _lastError;

  bool get isBusy => _isBusy;
  String? get lastError => _lastError;

  /// The signed-in Firebase user, or null when signed out.
  User? get firebaseUser => _auth.currentUser;

  bool get isSignedIn => _auth.currentUser != null;

  /// Initializes the Google Sign-In manager.
  Future<void> initialize() async {
    await _googleSignIn.initialize();
  }

  /// Starts the Google sign-in flow.
  ///
  /// Returns true when signed in, false when the user cancelled the Google
  /// account picker, and throws an [AuthException] on failure.
  Future<bool> signInWithGoogle() async {
    _isBusy = true;
    _lastError = null;
    notifyListeners();

    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return _auth.currentUser != null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        // User cancelled the Google account picker.
        return false;
      }
      debugPrint('Google Sign-In error: ${e.code} - ${e.description}');
      _lastError = _friendlyGoogleSignInError(e);
      throw AuthException(_lastError!);
    } on FirebaseAuthException catch (e) {
      _lastError = _friendlyAuthError(e);
      throw AuthException(_lastError ?? 'Sign-in failed.');
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _lastError = 'Google Sign-In failed. Please try again.';
      throw AuthException(_lastError!);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Signs out of both Google and Firebase.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore google sign-out errors (e.g. not signed in).
    }
    await _auth.signOut();
    notifyListeners();
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled in Firebase. Enable it in '
            'Authentication → Sign-in method.';
      default:
        return 'Sign-in failed (${e.code}).';
    }
  }

  String _friendlyGoogleSignInError(GoogleSignInException e) {
    final code = e.code;

    if (code == GoogleSignInExceptionCode.canceled ||
        code == GoogleSignInExceptionCode.interrupted ||
        code == GoogleSignInExceptionCode.uiUnavailable) {
      return 'Google Sign-In was cancelled. Please try again.';
    }

    // Android returns status_code inside description for DEVELOPER_ERROR /
    // permission errors. Surface a useful hint when present.
    final description = (e.description ?? '').toLowerCase();
    if (description.contains('permission') ||
        description.contains('not authorized') ||
        description.contains('access_denied') ||
        description.contains('10: developer error')) {
      return 'Google permission was not granted. Make sure Google Sign-In is '
          'enabled in Firebase and the app is registered with the correct '
          'SHA-1 fingerprint, then try again.';
    }

    if (description.contains('network') ||
        description.contains('connection') ||
        description.contains('offline')) {
      return 'Network error. Check your internet connection and try again.';
    }

    debugPrint('GoogleSignInException: $code - ${e.description}');
    return 'Google Sign-In failed (${e.code}). Please try again.';
  }
}
