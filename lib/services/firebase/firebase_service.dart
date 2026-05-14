import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// FirebaseService handles the initialization and configuration
/// of Firebase for the FlashAI application.
class FirebaseService {
  /// Private constructor for singleton pattern
  FirebaseService._();

  /// Singleton instance
  static final FirebaseService _instance = FirebaseService._();

  /// Factory constructor to return the singleton instance
  factory FirebaseService() => _instance;

  /// Flag to track if Firebase has been initialized
  bool _isInitialized = false;

  /// Check if Firebase is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase
  /// 
  /// This method initializes Firebase for both web and mobile platforms.
  /// On web, it uses the default options. On mobile, it uses the
  /// platform-specific Firebase configuration files.
  /// 
  /// Returns:
  ///   - Future<FirebaseApp>: The initialized Firebase app instance
  /// 
  /// Throws:
  ///   - FirebaseException: If Firebase initialization fails
  Future<FirebaseApp> initialize() async {
    if (_isInitialized) {
      return Firebase.app();
    }

    FirebaseApp app;

    if (kIsWeb) {
      // Web platform initialization
      app = await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBmock_web_api_key_for_development',
          authDomain: 'flashai-mock.firebaseapp.com',
          projectId: 'flashai-mock',
          storageBucket: 'flashai-mock.appspot.com',
          messagingSenderId: '123456789012',
          appId: '1:123456789012:web:mock_web_app_id',
        ),
      );
    } else {
      // Mobile platform initialization (Android/iOS)
      app = await Firebase.initializeApp();
    }

    _isInitialized = true;
    
    if (kDebugMode) {
      print('Firebase initialized successfully');
    }

    return app;
  }

  /// Get the default Firebase app instance
  /// 
  /// Returns the default Firebase app. If Firebase is not
  /// initialized, throws a StateError.
  /// 
  /// Throws:
  ///   - StateError: If Firebase is not initialized
  FirebaseApp get app {
    if (!_isInitialized) {
      throw StateError('Firebase is not initialized. Call initialize() first.');
    }
    return Firebase.app();
  }
}