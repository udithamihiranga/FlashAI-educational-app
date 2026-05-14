# Firebase Authentication Troubleshooting Guide

## Common Authentication Errors When Creating Account

### 1. ❌ "operation-not-allowed" Error
**What it means**: Email/Password sign-in method is NOT enabled in Firebase Console

**How to fix**:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Authentication** → **Sign-in method**
4. Look for **Email/Password** option
5. Click on it and enable it
6. Save changes

**Status**: 🔴 **CRITICAL** - This must be enabled

---

### 2. ❌ "invalid-email" Error
**What it means**: Email format is invalid

**Examples of invalid emails**:
- `user@` (missing domain)
- `@example.com` (missing username)
- `user @example.com` (space in email)
- `user..name@example.com` (consecutive dots)

**How to fix**:
- Use standard email format: `username@domain.com`
- Check for typos and spaces
- Avoid special characters except dots, hyphens, and underscores before @

---

### 3. ❌ "weak-password" Error
**What it means**: Password doesn't meet Firebase's minimum requirements

**Firebase requirements**:
- Minimum **6 characters**
- But the app checks for 6 characters before sending to Firebase
- If you still see this error, try a longer password (8+ characters)

**How to fix**:
- Use at least 6 characters
- Better: Use 8+ characters with mix of uppercase, lowercase, numbers, and symbols
- Example: `SecurePass123!`

---

### 4. ❌ "email-already-in-use" Error
**What it means**: This email is already registered

**How to fix**:
- Option 1: Use a different email address
- Option 2: If it's your account, use **Sign In** instead of **Sign Up**
- Option 3: Use **Forgot Password** to reset and sign in

---

### 5. ❌ "network-request-failed" Error
**What it means**: Cannot connect to Firebase servers

**Causes**:
- No internet connection
- Firewall blocking Firebase
- VPN issues
- Firebase servers temporarily unavailable

**How to fix**:
1. Check internet connection
2. Try disabling VPN
3. Check if Firebase services are up (check status page)
4. Wait and try again

---

### 6. ❌ "invalid-api-key" or "invalid-app-id" Error
**What it means**: Firebase configuration is incorrect

**Causes**:
- `google-services.json` is missing or corrupted (Android)
- `GoogleService-Info.plist` is missing (iOS)
- Firebase credentials are misconfigured

**How to fix**:

**For Android**:
1. Go to Firebase Console → Project Settings → Your Apps → Android App
2. Download `google-services.json`
3. Place it in: `android/app/google-services.json`
4. Run `flutter clean && flutter pub get`

**For iOS**:
1. Go to Firebase Console → Project Settings → Your Apps → iOS App
2. Download `GoogleService-Info.plist`
3. Add to Xcode: Right-click project → Add Files → GoogleService-Info.plist
4. Check "Copy if needed" is checked
5. Run `cd ios && pod install --repo-update && cd ..`

---

## Quick Diagnostics

### Step 1: Check Console Logs
When you see an error, check the console for the actual error code and message:

```
I/flutter ( 1234): FirebaseAuthException Code: [ERROR_CODE]
I/flutter ( 1234): FirebaseAuthException Message: [ERROR_MESSAGE]
```

The error code will help identify the exact problem.

### Step 2: Verify Internet Connection
```dart
// Add this test code temporarily
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivity = Connectivity();
final result = await connectivity.checkConnectivity();
print('Internet: $result'); // Should show ConnectivityResult.mobile or ConnectivityResult.wifi
```

### Step 3: Check Firebase Initialization
```dart
// In signup_screen.dart, add temporary logging
try {
  print('Attempting signup with: ${_emailController.text}');
  await _authService.signUpWithEmail(
    email: _emailController.text,
    password: _passwordController.text,
    displayName: _nameController.text,
  );
  print('Signup successful!');
} catch (e) {
  print('Signup error: $e');
  print('Error type: ${e.runtimeType}');
}
```

---

## Complete Verification Checklist

### Firebase Console Setup
- [ ] Firebase project created
- [ ] Android app added and configured
- [ ] iOS app added and configured
- [ ] Email/Password sign-in method **ENABLED**
- [ ] Google Sign-in method enabled (for Google sign-in)
- [ ] Authentication quota limits checked

### Android Setup
- [ ] `google-services.json` exists in `android/app/`
- [ ] File contains correct `package_name` matching your app
- [ ] `build.gradle.kts` has Google Services plugin
- [ ] Flutter clean and pub get run

### iOS Setup
- [ ] `GoogleService-Info.plist` added to Xcode
- [ ] Plist added to "Runner" target
- [ ] "Copy if needed" is checked
- [ ] `Info.plist` has Google Sign-In configuration
- [ ] `pod install --repo-update` run successfully
- [ ] iOS deployment target matches Firebase requirements

### Flutter Code
- [ ] Firebase initialization in `main.dart` completed
- [ ] `FirebaseAuthService` imported and used
- [ ] Error handling catches Firebase exceptions
- [ ] Network connectivity available
- [ ] Internet permission added (Android)

---

## Error Code Reference

| Error Code | Meaning | Fix |
|-----------|---------|-----|
| `operation-not-allowed` | Sign-in method not enabled | Enable in Firebase Console |
| `invalid-email` | Bad email format | Check email format |
| `weak-password` | Password too short | Use 6+ characters |
| `email-already-in-use` | Email registered | Use different email |
| `user-not-found` | Email not registered | Create account first |
| `wrong-password` | Incorrect password | Check password |
| `network-request-failed` | No internet | Check connection |
| `too-many-requests` | Rate limited | Wait and retry |
| `user-disabled` | Account disabled | Contact admin |
| `invalid-api-key` | Bad Firebase config | Check credentials |

---

## Advanced Debugging

### Enable Firebase Debug Logging
Add to `main.dart`:
```dart
import 'firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Firebase debug logging
  FirebaseAuth.instance.setLanguageCode("en");
  
  // ... rest of init
}
```

### Test Firebase Connection
Create temporary test file `lib/test_firebase.dart`:
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> testFirebaseConnection() async {
  try {
    print('Testing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized');
    
    print('Testing email/password signup...');
    final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: 'test@example.com',
      password: 'TestPassword123',
    );
    print('✅ Signup works: ${userCred.user?.email}');
    
    await FirebaseAuth.instance.signOut();
    print('✅ Firebase is working correctly!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

## What To Check First (In Order)

1. **Internet Connection**
   - Can you load websites?
   - Can other apps access network?
   - WiFi or mobile data working?

2. **Firebase Console**
   - Email/Password sign-in enabled?
   - Project exists and is accessible?
   - Correct project selected?

3. **Configuration Files**
   - `google-services.json` exists (Android)?
   - `GoogleService-Info.plist` exists (iOS)?
   - Package names match between files and Firebase?

4. **Firebase Initialization**
   - Running `main()` without errors?
   - Firebase service initializes successfully?
   - Check console for init messages

5. **App Settings**
   - Email format valid?
   - Password 6+ characters?
   - No typos in email/password?

---

## Contact Support

If you still can't create an account:

1. **Collect this information**:
   - Exact error message shown in app
   - Error code from console logs
   - Platform (Android or iOS)
   - Flutter version: `flutter --version`
   - Package versions: `flutter pub deps`

2. **Check these resources**:
   - [Firebase Auth Documentation](https://firebase.flutter.dev/docs/auth/overview)
   - [Firebase Console Status](https://status.firebase.google.com/)
   - [Stack Overflow Firebase Tag](https://stackoverflow.com/questions/tagged/firebase)

3. **Enable debugging**:
   - Add console.log output
   - Check Firebase Console activity logs
   - Review Android logcat or iOS console
   - Take screenshots of errors

---

## Quick Test

Try this exact flow:

1. Open login screen
2. Click "Sign Up"
3. Enter:
   - Name: `Test User`
   - Email: `test.user.123@gmail.com` (use a unique email)
   - Password: `TestPassword123`
4. Click "Create Account"
5. Check error message shown

**If successful**: Account created ✅  
**If error**: Note down exact error code and message, consult table above

---

**Last Updated**: May 9, 2026  
**Firebase Auth Version**: 5.1.4
