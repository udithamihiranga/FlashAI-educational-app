# Persistent Login (Remember Me) Implementation Guide

## Overview
This guide explains the complete implementation of persistent login functionality in FlashAI. When users check "Remember Me" during login, their login state is stored securely and automatically restored when the app is reopened.

## Architecture

### Components
1. **AuthProvider** - Centralized state management for authentication
2. **LoadingScreen** - Checks login state on app startup
3. **LoginScreen** - Handles user authentication with Remember Me option
4. **FirebaseAuthService** - Backend authentication logic
5. **SharedPreferences** - Secure local storage for login state

### Flow Diagram
```
App Startup
    ↓
LoadingScreen (shows splash)
    ↓
Check AuthProvider.initializeAuthState()
    ├── Firebase user session still active? → YES → MainNavigationShell
    ├── Remember Me data saved? → YES → (pre-fill email, prompt password)
    └── NO → LoginScreen

User Login with "Remember Me"
    ↓
FirebaseAuthService.signInWithEmail()
    ↓
Save to SharedPreferences (isLoggedIn, email, userId)
    ↓
MainNavigationShell

User Logout
    ↓
AuthProvider.signOut()
    ↓
Clear all SharedPreferences data
    ↓
LoginScreen
```

## Implementation Details

### 1. AuthProvider (State Management)

Location: `lib/features/auth/presentation/providers/auth_provider.dart`

```dart
class AuthProvider extends ChangeNotifier {
  // Manages: isAuthenticated, isLoading, userEmail, userName, userId
  
  // Initialize on app startup - checks both Firebase session and Remember Me data
  Future<void> initializeAuthState()
  
  // Sign in methods
  Future<bool> signInWithEmail(...)
  Future<bool> signInWithGoogle(...)
  Future<bool> signUpWithEmail(...)
  
  // Sign out - clears all data
  Future<bool> signOut()
  
  // Reset password
  Future<bool> resetPassword(...)
}
```

**Key Methods:**
- `initializeAuthState()`: Called on app startup to check if user is already logged in
- `signOut()`: Clears SharedPreferences and Firebase session

### 2. LoadingScreen (Auto-Login Check)

Location: `lib/core/presentation/screens/loading_screen.dart`

```dart
void _checkAuthState() async {
  final authProvider = context.read<AuthProvider>();
  await authProvider.initializeAuthState();
  
  // Route based on authentication state
  if (authProvider.isAuthenticated) {
    Navigator.pushReplacement(...MainNavigationShell);
  } else {
    Navigator.pushReplacement(...LoginScreen);
  }
}
```

**Purpose:**
- Executes during app startup (after 2-second splash screen)
- Determines initial route based on login state
- Users with valid Remember Me token go directly to home
- Users without Remember Me go to login screen

### 3. FirebaseAuthService (Storage Layer)

Location: `lib/features/auth/data/firebase_auth_service.dart`

```dart
// SharedPreferences keys
static const String _keyEmail = 'saved_email';
static const String _keyRememberMe = 'remember_me';
static const String _keyUserId = 'user_id';
static const String _keyUserName = 'user_name';

// Save login details when Remember Me is checked
Future<void> _saveLoginDetails(
  String email,
  String userName,
  String userId,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_keyEmail, email);
  await prefs.setString(_keyUserName, userName);
  await prefs.setString(_keyUserId, userId);
  await prefs.setBool(_keyRememberMe, true);
}

// Get saved login details
Future<Map<String, dynamic>> getLoginDetails() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'email': prefs.getString(_keyEmail) ?? '',
    'userName': prefs.getString(_keyUserName) ?? '',
    'userId': prefs.getString(_keyUserId) ?? '',
    'rememberMe': prefs.getBool(_keyRememberMe) ?? false,
  };
}

// Clear all login data
Future<void> _clearLoginDetails() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyEmail);
  await prefs.remove(_keyUserName);
  await prefs.remove(_keyUserId);
  await prefs.setBool(_keyRememberMe, false);
}
```

### 4. LoginScreen Integration

Location: `lib/features/auth/presentation/screens/login_screen.dart`

```dart
bool _rememberMe = false;  // Checkbox state

void _handleSignIn() async {
  final authProvider = context.read<AuthProvider>();
  final success = await authProvider.signInWithEmail(
    email: _emailController.text,
    password: _passwordController.text,
    rememberMe: _rememberMe,  // Pass Remember Me flag
  );
  
  if (success) {
    // Navigate to home
    Navigator.pushReplacement(...MainNavigationShell);
  }
}
```

## Security Best Practices

### ✅ What We're Doing Right

1. **Not storing passwords**
   - Only Firebase auth tokens are managed by Firebase (encrypted)
   - Email and user ID are stored in SharedPreferences

2. **Biometric authentication ready**
   - Architecture supports adding biometric auth layer

3. **Automatic session expiration**
   - Firebase handles token expiration automatically
   - If Firebase token expires but Remember Me exists, user needs to re-login

4. **Secure logout**
   - Both Firebase and local storage cleared
   - No orphaned data remains

### ⚠️ Security Considerations

1. **SharedPreferences is not encrypted by default**
   ```dart
   // For production, consider flutter_secure_storage
   import 'package:flutter_secure_storage/flutter_secure_storage.dart';
   
   // Replace SharedPreferences with:
   const storage = FlutterSecureStorage();
   await storage.write(key: 'remember_me', value: 'true');
   ```

2. **Device security matters**
   - If device is unlocked/compromised, Remember Me data could be accessed
   - Consider adding PIN/Biometric on app launch for sensitive operations

3. **Token refresh**
   - Firebase handles tokens automatically
   - But for custom tokens, implement refresh logic

## Usage Examples

### Example 1: Checking If User Is Logged In

```dart
// In any screen with access to AuthProvider
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    if (authProvider.isLoading) {
      return const CircularProgressIndicator();
    }
    
    if (authProvider.isAuthenticated) {
      return Text('Welcome, ${authProvider.userName}');
    } else {
      return const Text('Please log in');
    }
  },
)
```

### Example 2: Manual Logout

```dart
void _handleLogout() async {
  final authProvider = context.read<AuthProvider>();
  await authProvider.signOut();
  
  // Navigate to login
  Navigator.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}
```

### Example 3: Pre-filling Email from Remember Me

```dart
@override
void initState() {
  super.initState();
  _loadSavedCredentials();
}

Future<void> _loadSavedCredentials() async {
  final details = await FirebaseAuthService().getLoginDetails();
  if (mounted && details['rememberMe'] == true) {
    _emailController.text = details['email'];
    setState(() {
      _rememberMe = true;
    });
  }
}
```

## Testing Checklist

- [ ] Login with "Remember Me" checked
- [ ] Close app completely
- [ ] Reopen app → should show home screen directly
- [ ] Logout → should return to login screen
- [ ] Login without "Remember Me" → closing and reopening shows login screen
- [ ] Login on another device with same account → first device still works (Firebase handles this)
- [ ] Change password in one session → other sessions auto-invalidate (Firebase)
- [ ] Clear app data → should require re-login

## Troubleshooting

### Issue: App always shows login screen
**Solution:**
```dart
// In LoadingScreen, add debug logging:
print('isAuthenticated: ${authProvider.isAuthenticated}');
print('loginDetails: ${await FirebaseAuthService().getLoginDetails()}');
```

### Issue: "Remember Me" not persisting
**Solution:**
1. Check that `rememberMe: _rememberMe` is passed to `signInWithEmail()`
2. Verify SharedPreferences is saving correctly
3. Check device storage permissions (Android/iOS)

### Issue: Firebase session expired but Remember Me still shows
**Solution:**
This is expected behavior. User sees their email pre-filled and needs to enter password again. This provides security.

## Migration from Old Auth System

If migrating from existing auth:

```dart
// 1. Add AuthProvider to main.dart
ChangeNotifierProvider(create: (_) => AuthProvider()),

// 2. Update LoadingScreen to call initializeAuthState()

// 3. Update LoginScreen to use AuthProvider.signInWithEmail()

// 4. Update SettingsScreen logout to use AuthProvider.signOut()

// 5. Test thoroughly before release
```

## Dependencies

These are already in your `pubspec.yaml`:
- `shared_preferences: ^2.3.0` - Local storage
- `firebase_auth: ^5.1.4` - Authentication
- `provider: ^6.1.4` - State management

Optional for enhanced security:
- `flutter_secure_storage: ^9.0.0` - Encrypted storage

## References

- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [SharedPreferences Best Practices](https://pub.dev/packages/shared_preferences)
- [Provider Pattern](https://pub.dev/packages/provider)
- [Flutter Security Best Practices](https://flutter.dev/docs/testing/best-practices)

---

## File Summary

| File | Purpose |
|------|---------|
| `lib/features/auth/presentation/providers/auth_provider.dart` | Centralized auth state |
| `lib/core/presentation/screens/loading_screen.dart` | Auto-login check on startup |
| `lib/features/auth/presentation/screens/login_screen.dart` | User login with Remember Me |
| `lib/features/auth/data/firebase_auth_service.dart` | Firebase & storage backend |
| `lib/features/settings/presentation/screens/settings_screen.dart` | Logout functionality |
| `lib/main.dart` | App initialization with AuthProvider |
