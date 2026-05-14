# Push Notification Service Implementation

This document describes the push notification service implementation for the FlashAI Flutter application.

## Overview

The push notification service uses Firebase Cloud Messaging (FCM) for push notifications and Flutter Local Notifications for displaying local notifications. The implementation includes:

- Firebase initialization and configuration
- FCM token management
- Foreground and background message handling
- Local notification display
- Notification state management
- User permission handling

## Architecture

### Services

1. **FirebaseService** (`lib/services/firebase/firebase_service.dart`)
   - Initializes Firebase for the application
   - Manages Firebase app instance
   - Supports web and mobile platforms

2. **PushNotificationService** (`lib/services/push/push_notification_service.dart`)
   - Handles FCM token management
   - Configures message handlers (foreground/background)
   - Manages local notifications
   - Handles notification permissions
   - Provides notification stream for real-time updates

3. **NotificationProvider** (`lib/services/notification/notification_provider.dart`)
   - Manages application notification state
   - Handles CRUD operations for notifications
   - Provides filtering and search capabilities
   - Integrates with push notifications

### Features

#### 1. Notification Permissions
- Requests notification permissions on app startup
- Supports iOS and Android permission models
- Allows users to enable/disable notifications in settings
- Handles provisional authorization on iOS

#### 2. FCM Token Management
- Automatically retrieves FCM token on initialization
- Supports token refresh
- Allows token deletion (opt-out)
- Provides topic subscription/unsubscription

#### 3. Message Handling

**Foreground Messages:**
- Displays local notifications when app is in foreground
- Emits notifications to stream for real-time updates
- Updates notification state

**Background Messages:**
- Handles messages when app is in background
- Supports terminated state handling
- Re-initializes Firebase if needed

**Notification Taps:**
- Handles user taps on notifications
- Supports navigation from notification tap
- Works from both foreground and background states

#### 4. Local Notifications
- Displays notifications using Flutter Local Notifications
- Customizable Android and iOS notification channels
- Supports vibration, sound, and badge updates
- Handles notification interactions

## Configuration

### Android Setup

1. **Dependencies** (`android/app/build.gradle.kts`):
   ```kotlin
   dependencies {
       implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
       implementation("com.google.firebase:firebase-analytics")
       implementation("com.google.firebase:firebase-messaging")
       implementation("com.google.firebase:firebase-crashlytics")
   }
   ```

2. **Gradle Plugins** (`android/build.gradle.kts`):
   ```kotlin
   plugins {
       id("com.google.gms.google-services") version "4.4.2" apply false
   }
   ```

3. **AndroidManifest.xml**:
   - Added notification permissions
   - Configured Firebase Messaging Service
   - Added notification channel metadata
   - Background mode permissions

### iOS Setup

1. **Info.plist**:
   - Added `FirebaseAppDelegateProxyEnabled`
   - Configured background modes (`fetch`, `remote-notification`)
   - Notification permission descriptions

2. **SceneDelegate.swift**:
   - Imported FirebaseCore

### Flutter Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  firebase_core: ^3.8.0
  firebase_messaging: ^15.2.0
  flutter_local_notifications: ^17.3.0
```

## Usage

### Initialization

The push notification service is automatically initialized in `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  final firebaseService = FirebaseService();
  await firebaseService.initialize();
  
  runApp(const FlashAIApp());
}

// In MainNavigationShell
void _initializePushNotifications() async {
  final pushService = PushNotificationService();
  final initialized = await pushService.initialize();
  
  if (initialized) {
    pushService.notificationStream.listen((notification) {
      context.read<NotificationProvider>().addNotification(notification);
    });
  }
}
```

### Sending Notifications

To send a notification to a device, use the FCM token:

```dart
final pushService = PushNotificationService();
final token = await pushService.getFCMToken();

// Send token to your server
// Use FCM API to send notifications to this token
```

### Handling Notifications in the App

The `NotificationProvider` manages all notification state:

```dart
final provider = context.read<NotificationProvider>();

// Add notification
provider.addNotification(notification);

// Mark as read
provider.markAsRead(notificationId);

// Mark all as read
provider.markAllAsRead();

// Get unread count
final unreadCount = provider.unreadCount;
```

### User Permission Management

Users can manage notification permissions in Settings:

```dart
// Check permission status
final status = await pushService.getNotificationStatus();

// Request permission
final settings = await pushService.requestPermissions();

// Delete token (opt-out)
await pushService.deleteToken();
```

## API Reference

### PushNotificationService

#### Methods

- `initialize()` - Initializes the push notification service
- `getFCMToken()` - Returns the current FCM token
- `refreshToken()` - Forces token refresh
- `deleteToken()` - Deletes the FCM token (opt-out)
- `subscribeToTopic(String topic)` - Subscribes to a topic
- `unsubscribeFromTopic(String topic)` - Unsubscribes from a topic
- `getNotificationStatus()` - Returns current permission status
- `requestPermissions()` - Requests notification permissions

#### Properties

- `notificationStream` - Stream of incoming notifications
- `isInitialized` - Whether the service is initialized

### NotificationProvider

#### Methods

- `addNotification(NotificationItem)` - Adds a notification
- `addNotifications(List<NotificationItem>)` - Adds multiple notifications
- `markAsRead(String id)` - Marks a notification as read
- `markAllAsRead()` - Marks all notifications as read
- `removeNotification(String id)` - Removes a notification
- `clearAll()` - Clears all notifications
- `search(String query)` - Searches notifications
- `filterByDateRange(DateTime, DateTime)` - Filters by date
- `getStatistics()` - Returns notification statistics

#### Properties

- `notifications` - List of all notifications
- `unreadCount` - Number of unread notifications
- `isLoading` - Loading state
- `hasNotifications` - Whether there are any notifications

## Notification Types

The app supports the following notification types:

1. **System Notifications**
   - Feature announcements
   - Maintenance alerts
   - Security alerts

2. **User Notifications**
   - Follow notifications
   - Messages
   - Activity updates

3. **Reminder Notifications**
   - Study reminders
   - Flashcard reviews
   - Upcoming events

## Security Considerations

1. **FCM Token Security**
   - Tokens should be sent to your server over HTTPS
   - Store tokens securely on your server
   - Implement token refresh handling

2. **Notification Content**
   - Avoid sending sensitive data in notifications
   - Use data messages for sensitive content
   - Implement end-to-end encryption for sensitive notifications

3. **Permission Handling**
   - Request permissions at appropriate times
   - Explain why notifications are needed
   - Provide easy opt-out options

## Testing

### Local Testing

To test notifications during development:

1. Use Firebase Console to send test notifications
2. Use Postman to send FCM API requests
3. Test on both iOS and Android devices
4. Test foreground, background, and terminated states

### Debug Mode

The service includes debug logging when `kDebugMode` is enabled:

```dart
if (kDebugMode) {
  print('FCM Token: $token');
}
```

## Troubleshooting

### Common Issues

1. **Notifications not received on iOS**
   - Check APNs certificate configuration
   - Verify background modes are enabled
   - Check notification permissions

2. **FCM token is null**
   - Ensure Firebase is properly configured
   - Check Google Services files
   - Verify app bundle ID matches Firebase project

3. **Background messages not working**
   - Verify background handler is registered
   - Check Android manifest/service configuration
   - Verify iOS background modes

## Future Enhancements

1. **Rich Notifications**
   - Add images and actions to notifications
   - Support for notification categories

2. **Notification Scheduling**
   - Schedule local notifications
   - Recurring notifications

3. **Notification Preferences**
   - Per-category notification settings
   - Do not disturb mode

4. **Analytics**
   - Track notification open rates
   - Monitor delivery success
   - A/B testing for notification content

## References

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Android Notification Channels](https://developer.android.com/training/notify-user/channels)