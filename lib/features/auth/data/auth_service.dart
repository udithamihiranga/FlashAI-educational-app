import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyEmail = 'saved_email';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyIsFirstLogin = 'is_first_login';

  Future<void> saveLoginDetails(String email, bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setBool(_keyRememberMe, rememberMe);
  }

  Future<Map<String, dynamic>> getLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyEmail) ?? '',
      'rememberMe': prefs.getBool(_keyRememberMe) ?? false,
    };
  }

  Future<bool> isFirstLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsFirstLogin) ?? true;
  }

  Future<void> setFirstLoginCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstLogin, false);
  }

  Future<void> clearLoginDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRememberMe);
  }
}