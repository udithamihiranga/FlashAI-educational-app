# Firebase & Google Sign-In Setup Checklist

## Immediate Next Steps

### 1. Run Pub Get
```bash
flutter pub get
```
This will install the new dependencies (firebase_auth and google_sign_in).

### 2. Android Configuration (Most of this is already done)

- [x] `google-services.json` exists in `android/app/`
- [x] Google Services plugin configured in `build.gradle.kts`
- [ ] **Verify** the package name in `google-services.json` matches your Firebase project
  - Location: `android/app/build.gradle.kts` → `applicationId`
  - Should match: Firebase Console > Project Settings > Your Apps

### 3. iOS Configuration - Important!

You MUST update the iOS Info.plist with your actual Google credentials:

**File**: `ios/Runner/Info.plist`

Replace these placeholders:
```xml
<!-- Find this section: -->
<key>CFBundleURLSchemes</key>
<array>
    <string>com.googleusercontent.apps.YOUR_GOOGLE_APP_ID</string>
</array>
<key>GIDClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID</string>

<!-- With your actual values from Firebase Console -->
```

**Where to find these values**:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click "Project Settings" (gear icon)
4. Go to "Your Apps" tab
5. Select your iOS app
6. Copy the file `GoogleService-Info.plist`
7. In that file, find:
   - `GOOGLE_APP_ID` → use in CFBundleURLSchemes
   - `CLIENT_ID` → use in GIDClientID

### 4. Install iOS Pods (After updating Info.plist)
```bash
cd ios
pod install --repo-update
cd ..
```

### 5. Test the Implementation

#### Run on Android:
```bash
flutter run
```
1. Try signup with email/password
2. Try login with email/password
3. Try Google Sign-In

#### Run on iOS:
```bash
flutter run -d <ios-device-id>
```
1. Same tests as Android

### 6. Firebase Console Setup

Ensure these are enabled in Firebase Console:
- [ ] **Authentication**:
  - [ ] Email/Password sign-in method enabled
  - [ ] Google sign-in method enabled
- [ ] **Firestore/Database** (for future use):
  - [ ] Created
  - [ ] Security rules configured

## Code Integration Points

The following screens now support Firebase auth:

1. **Login Screen** (`lib/features/auth/presentation/screens/login_screen.dart`)
   - Email/password login
   - Remember me functionality
   - Forgot password
   - Google Sign-In button

2. **Signup Screen** (`lib/features/auth/presentation/screens/signup_screen.dart`)
   - Email/password registration
   - Name input
   - Google Sign-In button

## Key Services Used

- **FirebaseAuthService** (`lib/features/auth/data/firebase_auth_service.dart`)
  - Centralized authentication management
  - Email/password auth
  - Google Sign-In
  - Password reset
  - Local storage integration

## Common Issues & Solutions

### Issue: "google-services.json not found"
**Solution**: Ensure file exists at `android/app/google-services.json`

### Issue: "iOS deployment target mismatch"
**Solution**: 
```bash
cd ios
pod install --repo-update
cd ..
flutter clean
```

### Issue: Google Sign-In button throws error
**Solution**: 
- Verify Info.plist is correctly updated (iOS)
- Verify google-services.json is valid (Android)
- Check Firebase Console has Google sign-in enabled

### Issue: "Sign in cancelled by user"
**Solution**: This is expected behavior, no fix needed. App handles gracefully.

## What's Been Done For You

✅ Added Firebase Auth package  
✅ Added Google Sign-In package  
✅ Created FirebaseAuthService class  
✅ Updated login screen with Firebase integration  
✅ Updated signup screen with Firebase integration  
✅ Created GoogleSignInButton widget  
✅ Added iOS configuration structure (needs credentials)  
✅ Added error handling with user-friendly messages  
✅ Integrated remember-me functionality  
✅ Created comprehensive documentation  

## What You Need To Do

❌ Update iOS Info.plist with actual Google credentials (CRITICAL)  
❌ Run `flutter pub get`  
❌ Run `pod install --repo-update` (iOS)  
❌ Test on Android  
❌ Test on iOS  
❌ Configure any additional security rules in Firebase Console  
❌ Set up email templates in Firebase Console (optional)  

## Testing Checklist

After setup, verify these work:

### Email/Password Authentication
- [ ] Can sign up with new email
- [ ] Cannot sign up with existing email
- [ ] Password validation works (min 6 chars)
- [ ] Can login with correct credentials
- [ ] Cannot login with wrong password
- [ ] Forgot password link works

### Google Sign-In
- [ ] Google Sign-In button appears
- [ ] Can click and get Google auth prompt
- [ ] Successfully signs in with Google account
- [ ] User redirected to main app after sign-in

### User Experience
- [ ] Error messages are clear and helpful
- [ ] Loading states show properly
- [ ] Remember me checkbox saves credentials
- [ ] Navigation works after successful auth

## Resources

- [Firebase Auth Documentation](https://firebase.flutter.dev/docs/auth/overview)
- [Google Sign-In Documentation](https://pub.dev/packages/google_sign_in)
- [Firebase Console](https://console.firebase.google.com/)

## Support & Debugging

For more detailed information, see: [FIREBASE_AUTH_SETUP.md](./FIREBASE_AUTH_SETUP.md)

Enable debug logging:
```dart
// In main.dart
import 'firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Firebase logging
  FirebaseAuth.instance.setLanguageCode("en");
  
  await Firebase.initializeApp();
  // ... rest of initialization
}
```
