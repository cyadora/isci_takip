import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _emailKey = 'user_email';
  static const String _rememberMeKey = 'remember_me';

  // Kullanıcı e-postasını kaydet
  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  // Kaydedilmiş kullanıcı e-postasını getir
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // "Beni hatırla" durumunu kaydet
  static Future<void> saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
  }

  // "Beni hatırla" durumunu getir
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  // Kullanıcı oturum bilgilerini temizle
  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(await getRememberMe())) {
      await prefs.remove(_emailKey);
    }
  }
}
