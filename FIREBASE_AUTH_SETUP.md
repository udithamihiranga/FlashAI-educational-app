# Firebase Authentication & Google Sign-In Integration

## Overview
This document outlines the Firebase Authentication and Google Sign-In integration for the FlashAI application. Both email/password and Google sign-in authentication methods are now fully supported.

## What Has Been Implemented

### 1. **Firebase Authentication Setup**
- Added `firebase_auth` package (v5.1.4)
- Created `FirebaseAuthService` for centralized authentication management
- Support for email/password registration and login
- Automatic user profile management with display names
- Password reset functionality
- Firebase error handling with user-friendly messages

### 2. **Google Sign-In Integration**
- Added `google_sign_in` package (v6.2.2)
- Google Sign-In button widget with loading states
- Seamless authentication flow for both login and signup
- Support on Android and iOS platforms
- Error handling for cancelled sign-ins and failures

### 3. **Updated User Interfaces**
- **Login Screen**: 
  - Email/password input with validation
  - "Remember me" checkbox
  - "Forgot Password" functionality
  - Google Sign-In button
  - Error messaging

- **Signup Screen**:
  - Name, email, and password input fields
  - Password strength validation (minimum 6 characters)
  - Google Sign-In button
  - Seamless navigation to login screen

### 4. **Local Storage**
- User credentials saved with Firebase credentials
- Remember-me functionality using SharedPreferences
- User ID, name, and email caching

## File Structure

### New/Modified Files:
```
lib/
├── features/
│   └── auth/
│       ├── data/
│       │   ├── firebase_auth_service.dart (NEW)
│       │   └── auth_service.dart (legacy - kept for compatibility)
│       └── presentation/
│           ├── screens/
│           │   ├── login_screen.dart (UPDATED)
│           │   └── signup_screen.dart (UPDATED)
│           └── widgets/
│               └── google_signin_button.dart (NEW)
pubspec.yaml (UPDATED - added firebase_auth and google_sign_in)
ios/Runner/Info.plist (UPDATED - Google Sign-In configuration)
```

## Dependencies Added

```yaml
firebase_auth: ^5.1.4          # Firebase Authentication
google_sign_in: ^6.2.2          # Google Sign-In
```

## Setup Instructions

### Prerequisites
1. Firebase Project created in Firebase Console
2. Google Cloud Project with OAuth 2.0 credentials

### Android Setup

1. **Google Services Configuration**:
   - `google-services.json` should already be in `android/app/`
   - Ensure it contains the correct package name and credentials

2. **Build Configuration**:
   - Already configured in `android/app/build.gradle.kts`
   - Google Services plugin is applied

3. **No additional setup required** - Google Sign-In will work automatically on Android

### iOS Setup

1. **Update Info.plist** (Already done):
   - Navigate to `ios/Runner/Info.plist`
   - Replace `YOUR_GOOGLE_APP_ID` with your Google App ID
   - Replace `YOUR_GOOGLE_CLIENT_ID` with your Google Client ID
   
   These can be found in:
   - Firebase Console > Project Settings > Your Apps > iOS App
   - Look for "Google App ID" and "Google Client ID" in the plist download

2. **Get Google credentials**:
   ```bash
   # From Firebase Console:
   1. Go to Project Settings
   2. Download GoogleService-Info.plist
   3. In that file, find:
      - GOOGLE_APP_ID
      - CLIENT_ID
   ```

3. **Update iOS Runner project** (if needed):
   ```bash
   cd ios
   pod install --repo-update
   cd ..
   ```

### Web Setup (if needed)

For web platform support:
1. Update Firebase configuration in `lib/services/firebase/firebase_service.dart`
2. Add Google Sign-In JavaScript SDK configuration

## Usage Examples

### Sign Up with Email/Password

```dart
final authService = FirebaseAuthService();

try {
  await authService.signUpWithEmail(
    email: 'user@example.com',
    password: 'securePassword123',
    displayName: 'John Doe',
  );
  // Navigate to main app
} catch (e) {
  print('Signup failed: $e');
}
```

### Sign In with Email/Password

```dart
final authService = FirebaseAuthService();

try {
  await authService.signInWithEmail(
    email: 'user@example.com',
    password: 'securePassword123',
    rememberMe: true,
  );
  // Navigate to main app
} catch (e) {
  print('Login failed: $e');
}
```

### Sign In with Google

```dart
final authService = FirebaseAuthService();

try {
  await authService.signInWithGoogle();
  // Navigate to main app
} catch (e) {
  print('Google sign-in failed: $e');
}
```

### Reset Password

```dart
final authService = FirebaseAuthService();

try {
  await authService.resetPassword('user@example.com');
  // Show success message to user
} catch (e) {
  print('Password reset failed: $e');
}
```

### Sign Out

```dart
final authService = FirebaseAuthService();

try {
  await authService.signOut();
  // Navigate to login screen
} catch (e) {
  print('Sign out failed: $e');
}
```

## API Reference

### FirebaseAuthService

#### Properties
- `currentUser: User?` - Get current Firebase user
- `currentUserId: String?` - Get current user ID
- `isAuthenticated: bool` - Check if user is authenticated
- `authStateChanges: Stream<User?>` - Listen to auth state changes

#### Methods

**signUpWithEmail()**
- Parameters: `email`, `password`, `displayName`
- Returns: `Future<UserCredential>`
- Throws: `FirebaseAuthException`

**signInWithEmail()**
- Parameters: `email`, `password`, `rememberMe`
- Returns: `Future<UserCredential>`
- Throws: `FirebaseAuthException`

**signInWithGoogle()**
- Returns: `Future<UserCredential>`
- Throws: Exception (Google sign-in specific errors)

**resetPassword()**
- Parameters: `email`
- Returns: `Future<void>`
- Throws: `FirebaseAuthException`

**signOut()**
- Returns: `Future<void>`
- Throws: Exception

**getLoginDetails()**
- Returns: `Future<Map<String, dynamic>>` with keys: `email`, `userName`, `userId`, `rememberMe`

**isFirstLogin()**
- Returns: `Future<bool>`

**setFirstLoginCompleted()**
- Returns: `Future<void>`

## Error Handling

The service provides user-friendly error messages for common Firebase errors:

| Error Code | Message |
|-----------|---------|
| user-not-found | No user found with this email. |
| wrong-password | Incorrect password. |
| email-already-in-use | This email is already registered. |
| invalid-email | Invalid email address. |
| weak-password | Password is too weak. Use at least 6 characters. |
| operation-not-allowed | This operation is not allowed. |
| user-disabled | This user account has been disabled. |
| too-many-requests | Too many login attempts. Please try again later. |

## Security Considerations

1. **Never hardcode credentials** - Use environment variables or Firebase configuration files
2. **Password requirements** - Minimum 6 characters (should be increased for production)
3. **HTTPS Only** - Ensure all Firebase operations use HTTPS
4. **Token refresh** - Firebase automatically handles token refresh
5. **Logout on sensitive operations** - Force re-authentication for sensitive actions

## Testing

### Test Credentials (Development Only)
```
Email: test@example.com
Password: Test@123456
```

### Testing Google Sign-In
1. Add test accounts in Firebase Console > Authentication > Settings > Test accounts
2. Use test accounts with test devices for development

## Troubleshooting

### Google Sign-In not working on Android
- Verify `google-services.json` is in correct location
- Check package name matches Firebase project
- Clear app cache: `flutter clean`

### Google Sign-In not working on iOS
- Verify Info.plist has correct Google App ID and Client ID
- Run `pod install --repo-update` in iOS folder
- Check iOS deployment target matches requirements

### Firebase not initialized
- Ensure `firebaseService.initialize()` is called in `main()`
- Check Firebase configuration files are present

### Remember me not working
- Check SharedPreferences permissions (Android: INTERNET permission)
- Verify `rememberMe` flag is being passed correctly

## Future Enhancements

1. **Social sign-in providers**:
   - Apple Sign-In
   - Facebook Login
   - GitHub authentication

2. **Enhanced security**:
   - Biometric authentication
   - Two-factor authentication
   - Security questions

3. **User management**:
   - Profile picture upload
   - Email verification
   - Phone number verification

4. **Session management**:
   - Token expiration handling
   - Automatic re-authentication
   - Session timeout

## References

- [Firebase Authentication Documentation](https://firebase.flutter.dev/docs/auth/overview)
- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Console](https://console.firebase.google.com/)
- [Flutter Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)

## Support

For issues or questions:
1. Check Firebase console logs
2. Enable Firebase debug logging
3. Review error messages from FirebaseAuthService
4. Check platform-specific logs (Android Logcat, iOS Console)

---

**Last Updated**: May 2026
**Status**: Implemented and Ready for Testing
