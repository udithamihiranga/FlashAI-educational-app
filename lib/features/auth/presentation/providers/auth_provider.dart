import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flashai/features/auth/data/firebase_auth_service.dart';

/// Authentication state provider
/// Manages user authentication state and provides methods for auth operations
class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _userEmail;
  String? _userName;
  String? _userId;
  String? _errorMessage;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;

  /// Initialize auth state on app startup
  /// Checks if user is already logged in via Remember Me
  Future<void> initializeAuthState() async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      // Check if user is currently authenticated with Firebase
      if (_authService.isAuthenticated) {
        _isAuthenticated = true;
        _userEmail = _authService.currentUser?.email;
        _userName = _authService.currentUser?.displayName;
        _userId = _authService.currentUserId;
      } else {
        // Check for saved login details from Remember Me
        final loginDetails = await _authService.getLoginDetails();

        if (loginDetails['rememberMe'] == true &&
            loginDetails['userId'] != null) {
          // User had Remember Me checked, but Firebase session expired
          // User will need to re-login, but we can pre-fill email
          _isAuthenticated = false;
          _userEmail = loginDetails['email'];
        } else {
          _isAuthenticated = false;
        }
      }
    } catch (e) {
      _errorMessage = 'Error checking authentication: ${e.toString()}';
      _isAuthenticated = false;
      print(_errorMessage);
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      final userCredential = await _authService.signInWithEmail(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      _isAuthenticated = true;
      _userEmail = userCredential.user?.email;
      _userName = userCredential.user?.displayName;
      _userId = userCredential.user?.uid;

      Future.microtask(() => notifyListeners());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      Future.microtask(() => notifyListeners());
      return false;
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      final userCredential = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      _isAuthenticated = true;
      _userEmail = userCredential.user?.email;
      _userName = userCredential.user?.displayName;
      _userId = userCredential.user?.uid;

      Future.microtask(() => notifyListeners());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      Future.microtask(() => notifyListeners());
      return false;
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      final userCredential = await _authService.signInWithGoogle();

      _isAuthenticated = true;
      _userEmail = userCredential.user?.email;
      _userName = userCredential.user?.displayName;
      _userId = userCredential.user?.uid;

      Future.microtask(() => notifyListeners());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isAuthenticated = false;
      Future.microtask(() => notifyListeners());
      return false;
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Sign out and clear all stored data
  Future<bool> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      await _authService.signOut();

      _isAuthenticated = false;
      _userEmail = null;
      _userName = null;
      _userId = null;

      Future.microtask(() => notifyListeners());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      Future.microtask(() => notifyListeners());
      return false;
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    Future.microtask(() => notifyListeners());

    try {
      await _authService.resetPassword(email);
      Future.microtask(() => notifyListeners());
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      Future.microtask(() => notifyListeners());
      return false;
    } finally {
      _isLoading = false;
      Future.microtask(() => notifyListeners());
    }
  }

   /// Clear error message
   void clearError() {
     _errorMessage = null;
     Future.microtask(() => notifyListeners());
   }

   /// Update user profile (display name and photo URL)
   Future<bool> updateProfile({String? displayName, String? photoURL}) async {
     _isLoading = true;
     _errorMessage = null;
     Future.microtask(() => notifyListeners());

     try {
       await _authService.updateProfile(
         displayName: displayName,
         photoURL: photoURL,
       );

       // Update local state
       if (displayName != null) {
         _userName = displayName;
       }

       Future.microtask(() => notifyListeners());
       return true;
     } catch (e) {
       _errorMessage = e.toString();
       Future.microtask(() => notifyListeners());
       return false;
      } finally {
        _isLoading = false;
        Future.microtask(() => notifyListeners());
      }
    }

   /// Update user profile with image (uploads image and updates both name and photo)
   Future<bool> updateProfileWithImage({
     String? displayName,
     required Uint8List imageBytes,
     required String extension,
   }) async {
     _isLoading = true;
     _errorMessage = null;
     Future.microtask(() => notifyListeners());

     try {
       print('AuthProvider: Starting updateProfileWithImage');
       await _authService.updateProfileWithImage(
         displayName: displayName ?? _userName ?? '',
         imageBytes: imageBytes,
         extension: extension,
       );

       if (displayName != null) {
         _userName = displayName;
       }

       Future.microtask(() => notifyListeners());
       return true;
     } catch (e, stack) {
       print('AuthProvider updateProfileWithImage error: $e');
       print('Stack trace: $stack');
       _errorMessage = _getFriendlyErrorMessage(e);
       Future.microtask(() => notifyListeners());
       return false;
     } finally {
       _isLoading = false;
       Future.microtask(() => notifyListeners());
     }
   }

   String _getFriendlyErrorMessage(dynamic error) {
     final errorStr = error.toString().toLowerCase();
     if (errorStr.contains('network') || errorStr.contains('timeout')) {
       return 'Network error. Please check your internet connection.';
     }
     if (errorStr.contains('permission') || errorStr.contains('denied')) {
       return 'Permission denied. Please check Firebase Storage rules.';
     }
     if (errorStr.contains('storage')) {
       return 'Storage error. Please try again later.';
     }
     return error.toString();
   }
 }
