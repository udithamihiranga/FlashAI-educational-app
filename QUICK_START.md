# 🚀 Quick Start Guide - Firebase & Google Sign-In

## ⏱️ 5-Minute Setup

### Step 1: Install Dependencies (1 min)
```bash
flutter pub get
```

### Step 2: Add Google Credentials to iOS (2 min)
Edit `ios/Runner/Info.plist` - find and replace:
```xml
<!-- Line ~46 -->
<string>com.googleusercontent.apps.YOUR_GOOGLE_APP_ID</string>

<!-- Line ~51 -->
<string>YOUR_GOOGLE_CLIENT_ID</string>
```

**Where to get these**:
- Open [Firebase Console](https://console.firebase.google.com/)
- Project Settings → Your Apps → iOS App
- Download plist and copy the values

### Step 3: Update iOS Pods (1 min)
```bash
cd ios && pod install --repo-update && cd ..
```

### Step 4: Run App (1 min)
```bash
flutter run
```

---

## ✅ What's Ready to Use

### Login Screen Features:
- Email/password login ✅
- Remember me checkbox ✅
- Forgot password ✅
- Google Sign-In ✅

### Signup Screen Features:
- Email/password registration ✅
- Name input ✅
- Google Sign-In ✅

### Code-Level API:
```dart
// Access authentication
final authService = FirebaseAuthService();

// Sign up
await authService.signUpWithEmail(
  email: email,
  password: password,
  displayName: name,
);

// Sign in
await authService.signInWithEmail(
  email: email,
  password: password,
  rememberMe: true,
);

// Google sign-in
await authService.signInWithGoogle();

// Sign out
await authService.signOut();
```

---

## 🧪 Quick Test

Run the app and:
1. Go to signup page
2. Create account with test email
3. Login with that email
4. Try Google Sign-In button
5. Check remember me works

---

## 📱 Demo Flows

### Signup & Login Flow
```
Login Screen → Click "Sign Up"
    ↓
Signup Screen → Enter name, email, password
    ↓
Click "Create Account" → Firebase registers user
    ↓
App Main Screen (authenticated) ✅
```

### Google Sign-In Flow
```
Login/Signup → Click "Sign in with Google"
    ↓
Google Popup → Select account & authorize
    ↓
Firebase authenticates with Google token
    ↓
App Main Screen (authenticated) ✅
```

### Password Reset Flow
```
Login Screen → Click "Forgot Password?"
    ↓
Enter email → Firebase sends reset link
    ↓
User checks email → Clicks reset link
    ↓
Sets new password ✅
```

---

## 🔧 Key Files Modified

| File | Change | Type |
|------|--------|------|
| `pubspec.yaml` | Added firebase_auth, google_sign_in | Dependency |
| `login_screen.dart` | Firebase auth integration | Logic |
| `signup_screen.dart` | Firebase auth integration | Logic |
| `ios/Runner/Info.plist` | Google Sign-In config | Config |

---

## 📚 Full Documentation

- **Setup Guide**: See `FIREBASE_AUTH_SETUP.md`
- **Checklist**: See `FIREBASE_SETUP_CHECKLIST.md`
- **Status**: See `IMPLEMENTATION_COMPLETE.md`

---

## ⚠️ Important Notes

1. **iOS Google Credentials Required**: 
   - Get from Firebase Console before testing on iOS
   - Update `ios/Runner/Info.plist`

2. **Android Works Out of Box**:
   - `google-services.json` already in place
   - No additional setup needed

3. **Error Messages Are User-Friendly**:
   - Invalid email → "Invalid email address"
   - Weak password → "Password is too weak"
   - Email in use → "This email is already registered"
   - Wrong password → "Incorrect password"

4. **Remember Me Works**:
   - Checkbox saves email locally
   - Uses SharedPreferences
   - Persists across app restarts

---

## 🎯 Next Steps

1. ✅ Run `flutter pub get`
2. ✅ Update iOS Info.plist with Google credentials
3. ✅ Run `cd ios && pod install --repo-update && cd ..`
4. ✅ Test on Android: `flutter run`
5. ✅ Test on iOS: `flutter run -d <device>`
6. ✅ Try signup, login, and Google Sign-In

---

## 💡 Pro Tips

### Debug Authentication
```dart
// Check if user is logged in
bool isLoggedIn = FirebaseAuthService().isAuthenticated;

// Get current user
var user = FirebaseAuthService().currentUser;
print('User: ${user?.email}, Name: ${user?.displayName}');

// Listen to auth changes
FirebaseAuthService().authStateChanges.listen((user) {
  if (user == null) print('User signed out');
  else print('User signed in: ${user.email}');
});
```

### Force Re-authentication
```dart
// Sign out and redirect to login
await FirebaseAuthService().signOut();
// Navigate to LoginScreen
```

### Save Additional User Data
```dart
// After successful auth, save to Firestore
final uid = FirebaseAuthService().currentUserId;
// Add your Firestore logic here
```

---

## 🚨 Common Issues & Quick Fixes

| Issue | Fix |
|-------|-----|
| Google Sign-In not working on iOS | Update Info.plist credentials |
| Dependencies not found | Run `flutter pub get` |
| iOS build fails | Run `cd ios && pod install --repo-update && cd ..` |
| Remember me doesn't work | Check SharedPreferences permissions |
| "User not found" error | Make sure you signed up first |

---

## 📞 Need Help?

1. Check `FIREBASE_AUTH_SETUP.md` for detailed guide
2. Check `FIREBASE_SETUP_CHECKLIST.md` for troubleshooting
3. Check error message - it tells you what's wrong
4. See Firebase Console > Authentication > Logs

---

## ✨ Success Indicators

You'll know everything is working when:

✅ Can create account with email/password  
✅ Can login with email/password  
✅ Can login with Google account  
✅ Remember me saves email  
✅ Can reset password via email  
✅ Error messages are clear  
✅ No console errors  
✅ App navigates to main screen after auth  

---

**You're all set! 🎉**

Start testing now or refer to detailed guides for more information.
