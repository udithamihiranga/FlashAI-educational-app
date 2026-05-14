import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'firebase_storage_service.dart';

/// Firebase Authentication Service
/// Handles user authentication, registration, and Google sign-in
class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._();

  factory FirebaseAuthService() => _instance;

  FirebaseAuthService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '293388346215-ougetu131fe14a7sdt1q12jgde64d51a.apps.googleusercontent.com',
  );

  static const String _keyEmail = 'saved_email';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyIsFirstLogin = 'is_first_login';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get current user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Sign up with email and password
  ///
  /// Returns the created user
  /// Throws [FirebaseAuthException] on failure
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update user profile
      await userCredential.user?.updateDisplayName(displayName.trim());

      // Save to local storage
      await _saveLoginDetails(
        email,
        displayName.trim(),
        userCredential.user!.uid,
        true,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign in with email and password
  ///
  /// Returns the authenticated user
  /// Throws [FirebaseAuthException] on failure
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Save login details if remember me is checked
      if (rememberMe) {
        await _saveLoginDetails(
          email,
          userCredential.user?.displayName ?? 'User',
          userCredential.user!.uid,
          true,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
}

  /// Sign in with Google
  ///
  /// Returns the authenticated user
  /// Throws exception on failure
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign-in cancelled by user');
      }

      // Get Google authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      // Save user details (Google sign-in always remembers)
      await _saveLoginDetails(
        userCredential.user?.email ?? '',
        userCredential.user?.displayName ?? 'User',
        userCredential.user!.uid,
        true,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on PlatformException catch (e) {
      // google_sign_in throws PlatformException on failure
      throw Exception('Google sign-in failed: ${e.message} (code: ${e.code})');
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      // Sign out from Firebase
      await _firebaseAuth.signOut();

      // Sign out from Google
      await _googleSignIn.signOut();

      // Clear saved user details
      await _clearLoginDetails();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Get saved login details
  Future<Map<String, dynamic>> getLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyEmail) ?? '',
      'userName': prefs.getString(_keyUserName) ?? '',
      'userId': prefs.getString(_keyUserId) ?? '',
      'rememberMe': prefs.getBool(_keyRememberMe) ?? false,
    };
  }

   /// Save login details to local storage
   Future<void> _saveLoginDetails(
     String email,
     String userName,
     String userId,
     bool rememberMe,
   ) async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString(_keyEmail, email);
     await prefs.setString(_keyUserName, userName);
     await prefs.setString(_keyUserId, userId);
     await prefs.setBool(_keyRememberMe, rememberMe);
   }

  /// Save remember me preference
  Future<void> saveRememberMe(bool rememberMe, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe);
    if (rememberMe) {
      await prefs.setString(_keyEmail, email);
    } else {
      await prefs.remove(_keyEmail);
    }
  }

  /// Clear login details
  Future<void> _clearLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyIsFirstLogin);
    await prefs.setBool(_keyRememberMe, false);
  }

  /// Clear all login details
  Future<void> clearLoginDetails() async {
    await _clearLoginDetails();
  }

   /// Check if first login
   Future<bool> isFirstLogin() async {
     final prefs = await SharedPreferences.getInstance();
     return prefs.getBool(_keyIsFirstLogin) ?? true;
   }

   /// Set first login completed
   Future<void> setFirstLoginCompleted() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setBool(_keyIsFirstLogin, false);
   }

    /// Update user profile
    Future<void> updateProfile({String? displayName, String? photoURL}) async {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception('No user logged in');

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }
    }

    /// Update user profile with a new profile picture (uploads to Firebase Storage)
    Future<void> updateProfileWithImage({
      required String displayName,
      required Uint8List imageBytes,
      required String extension,
    }) async {
      try {
        final user = _firebaseAuth.currentUser;
        if (user == null) throw Exception('No user logged in');

        print('Starting profile image upload for user: ${user.uid}');

        // Upload new profile picture to Firebase Storage
        final storageService = FirebaseStorageService();
        final photoURL = await storageService.uploadProfilePicture(
          imageBytes,
          user.uid,
          extension,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Upload timed out - please check your internet connection'),
        );

        print('Upload complete, photoURL: $photoURL');

        // Update Firebase Auth profile with new display name and photo URL
        await user.updateDisplayName(displayName);
        await user.updatePhotoURL(photoURL);
        
        print('Profile updated successfully');
      } catch (e, stack) {
        print('updateProfileWithImage error: $e');
        print('Stack: $stack');
        rethrow;
      }
    }

    /// Handle Firebase Auth exceptions and return user-friendly messages
    String _handleAuthException(FirebaseAuthException e) {
    // Print debug info
    print('FirebaseAuthException Code: ${e.code}');
    print('FirebaseAuthException Message: ${e.message}');

    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled. Please enable it in Firebase Console > Authentication > Sign-in methods.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'invalid-api-key':
        return 'Firebase configuration error. Please check your project setup.';
      case 'invalid-app-id':
        return 'Firebase app ID is invalid. Please check your configuration.';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
}
