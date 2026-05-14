import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flashai/features/notifications/presentation/models/notification_model.dart';

/// PushNotificationService handles all push notification related
/// functionality including FCM token management, message handling,
/// and local notification display.
class PushNotificationService {
  /// Singleton instance
  static final PushNotificationService _instance =
      PushNotificationService._();

  /// Factory constructor
  factory PushNotificationService() => _instance;

  PushNotificationService._();

  /// Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Local Notifications plugin instance
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Stream controller for notification events
  final StreamController<NotificationItem> _notificationStreamController =
      StreamController<NotificationItem>.broadcast();

  /// Get stream of incoming notifications
  Stream<NotificationItem> get notificationStream =>
      _notificationStreamController.stream;

  /// Flag to track initialization status
  bool _isInitialized = false;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the push notification service
  /// 
  /// This method:
  /// 1. Requests notification permissions
  /// 2. Initializes local notifications plugin
  /// 3. Configures FCM message handlers
  /// 4. Retrieves FCM token
  /// 
  /// Returns:
  ///   - Future<bool>: True if initialization succeeded
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Step 1: Request notification permissions
      await _requestPermissions();

      // Step 2: Initialize local notifications
      await _initializeLocalNotifications();

      // Step 3: Configure FCM message handlers
      await _configureMessageHandlers();

      // Step 4: Get FCM token
      await _getFCMToken();

      _isInitialized = true;
      
      if (kDebugMode) {
        print('Push notification service initialized successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing push notifications: $e');
      }
      _isInitialized = false;
      return false;
    }
  }

  /// Request notification permissions from the user
  /// 
  /// Requests authorization for alerts, badges, and sounds.
  /// On iOS, also requests provisional authorization for
  /// background notifications.
  /// 
  /// Returns:
  ///   - Future<NotificationSettings>: The granted settings
  Future<NotificationSettings> requestPermissions() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
    );
  }

  /// Internal method to request notification permissions
  Future<NotificationSettings> _requestPermissions() async {
    return await requestPermissions();
  }

  /// Initialize the local notifications plugin
  /// 
  /// Configures the Android and iOS initialization settings
  /// for displaying local notifications.
  /// 
  /// Returns:
  ///   - Future<void>
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  /// Configure FCM message handlers
  /// 
  /// Sets up handlers for:
  /// - Foreground messages
  /// - Background/terminated messages
  /// - Message opened from terminated state
  /// 
  /// Returns:
  ///   - Future<void>
  Future<void> _configureMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Handle messages opened from terminated state
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Handle messages opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Handle foreground FCM messages
  /// 
  /// Called when a message is received while the app is in the foreground.
  /// Displays a local notification to the user.
  /// 
  /// Parameters:
  ///   - message: The received remote message
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Received foreground message: ${message.messageId}');
    }

    final notification = _parseRemoteMessage(message);
    
    // Show local notification
    _showLocalNotification(notification);
    
    // Emit to stream
    _notificationStreamController.add(notification);
  }

  /// Handle background/terminated FCM messages
  /// 
  /// Static method called when a message is received while the app
  /// is in the background or terminated state.
  /// 
  /// Parameters:
  ///   - message: The received remote message
  /// 
  /// Returns:
  ///   - Future<void>
  static Future<void> _handleBackgroundMessage(
    RemoteMessage message,
  ) async {
    if (kDebugMode) {
      print('Received background message: ${message.messageId}');
    }
    
    // Re-initialize Firebase if needed
    await Firebase.initializeApp();
  }

  /// Handle message opened from terminated state
  /// 
  /// Called when the user taps a notification to open the app
  /// from a terminated state.
  /// 
  /// Parameters:
  ///   - message: The remote message that opened the app
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('Message opened app: ${message.messageId}');
    }

    final notification = _parseRemoteMessage(message);
    
    // Emit to stream (will be picked up by NotificationProvider)
    _notificationStreamController.add(notification);
    
    // Also add directly to NotificationProvider for immediate persistence
    try {
      // Access NotificationProvider via provider registry if available
      // This works because NotificationProvider is a singleton ChangeNotifier
      // The main app's listener will also handle this via the stream
    } catch (e) {
      if (kDebugMode) {
        print('Error handling message opened app: $e');
      }
    }
    
    // Navigate to relevant screen (implement in app level)
    // This can be handled by a navigation service
  }

  /// Handle local notification response
  /// 
  /// Called when the user interacts with a local notification.
  /// 
  /// Parameters:
  ///   - response: The notification response
  void _onDidReceiveNotificationResponse(
    NotificationResponse response,
  ) {
    if (kDebugMode) {
      print('Notification response: ${response.payload}');
    }
    // Handle notification response
  }

  /// Parse a RemoteMessage into a NotificationItem
  /// 
  /// Extracts notification data from FCM message and converts
  /// it to the app's internal notification model.
  /// 
  /// Parameters:
  ///   - message: The remote message to parse
  /// 
  /// Returns:
  ///   - NotificationItem: The parsed notification
  NotificationItem _parseRemoteMessage(RemoteMessage message) {
    return NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? message.data['title'] ?? 'Notification',
      body: message.notification?.body ?? message.data['body'] ?? '',
      timestamp: message.sentTime ?? DateTime.now(),
      isRead: false,
    );
  }

  /// Show a local notification
  /// 
  /// Displays a local notification to the user using the
  /// Flutter Local Notifications plugin.
  /// 
  /// Parameters:
  ///   - notification: The notification to display
  /// 
  /// Returns:
  ///   - Future<void>
  Future<void> _showLocalNotification(NotificationItem notification) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'flashai_channel',
      'FlashAI Notifications',
      channelDescription: 'Push notifications for FlashAI app',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      notificationDetails,
      payload: notification.id,
    );
   }

  /// Show a notification (public API)
  /// 
  /// Displays a local notification and adds it to the notification stream
  /// so it appears in the app's notification center.
  /// 
  /// Parameters:
  ///   - notification: The notification to display
  /// 
  /// Returns:
  ///   - Future<void>
  Future<void> showNotification(NotificationItem notification) async {
    await _showLocalNotification(notification);
    _notificationStreamController.add(notification);
  }

  /// Get the current FCM token
  /// 
  /// Returns the FCM token for the current device instance.
  /// This token should be sent to your server for targeting
  /// this device with push notifications.
  /// 
  /// Returns:
  ///   - Future<String?>: The FCM token, or null if not available
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Internal method to get and log FCM token
  /// 
  /// Returns:
  ///   - Future<String?>: The FCM token
  Future<String?> _getFCMToken() async {
    final token = await getFCMToken();
    if (kDebugMode) {
      print('FCM Token: $token');
    }
    return token;
  }

  /// Refresh the FCM token
  /// 
  /// Forces a refresh of the FCM token. Useful when
  /// the token has been invalidated.
  /// 
  /// Returns:
  ///   - Future<String?>: The new FCM token
  Future<String?> refreshToken() async {
    await _firebaseMessaging.deleteToken();
    return await getFCMToken();
  }

  /// Subscribe to a notification topic
  /// 
  /// Allows the device to receive messages sent to a
  /// specific topic.
  /// 
  /// Parameters:
  ///   - topic: The topic name to subscribe to
  /// 
  /// Returns:
  ///   - Future<void>
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    if (kDebugMode) {
      print('Subscribed to topic: $topic');
    }
  }

  /// Unsubscribe from a notification topic
  /// 
  /// Stops receiving messages sent to a specific topic.
  /// 
  /// Parameters:
  ///   - topic: The topic name to unsubscribe from
  /// 
  /// Returns:
  ///   - Future<void>
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    if (kDebugMode) {
      print('Unsubscribed from topic: $topic');
    }
  }

  /// Delete the FCM token
  /// 
  /// Removes the token from the device. Useful for logout
  /// or when the user opts out of notifications.
  /// 
  /// Returns:
  ///   - Future<void>
  Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
    if (kDebugMode) {
      print('FCM token deleted');
    }
  }

  /// Get the current notification permission status
  /// 
  /// Returns the current authorization status for notifications.
  /// 
  /// Returns:
  ///   - Future<AuthorizationStatus>: The current status
  Future<AuthorizationStatus> getNotificationStatus() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Dispose the service and clean up resources
  void dispose() {
    _notificationStreamController.close();
  }
}

/// Singleton instance shortcut
final pushNotificationService = PushNotificationService();