import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyLastSelectedDate = 'last_selected_date';
  static const String _keyUserPreferences = 'user_preferences';

  // Get SharedPreferences instance
  Future<SharedPreferences> get _prefs async => await SharedPreferences.getInstance();

  // Save last selected date
  Future<void> saveLastSelectedDate(DateTime date) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLastSelectedDate, date.toIso8601String());
  }

  // Get last selected date
  Future<DateTime?> getLastSelectedDate() async {
    final prefs = await _prefs;
    final dateString = prefs.getString(_keyLastSelectedDate);
    if (dateString != null) {
      return DateTime.parse(dateString);
    }
    return null;
  }

  // Save user preference
  Future<void> saveUserPreference(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString('$_keyUserPreferences$key', value);
  }

  // Get user preference
  Future<String?> getUserPreference(String key) async {
    final prefs = await _prefs;
    return prefs.getString('$_keyUserPreferences$key');
  }

  // Clear all preferences
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  // Save remember me credentials
  Future<void> saveRememberMe(String email, String password) async {
    final prefs = await _prefs;
    await prefs.setString('remembered_email', email);
    await prefs.setString('remembered_password', password);
    await prefs.setBool('remember_me', true);
  }

  // Get remembered credentials
  Future<Map<String, String?>> getRememberedCredentials() async {
    final prefs = await _prefs;
    if (prefs.getBool('remember_me') == true) {
      return {
        'email': prefs.getString('remembered_email'),
        'password': prefs.getString('remembered_password'),
      };
    }
    return {'email': null, 'password': null};
  }

  // Clear remember me
  Future<void> clearRememberMe() async {
    final prefs = await _prefs;
    await prefs.remove('remembered_email');
    await prefs.remove('remembered_password');
    await prefs.setBool('remember_me', false);
  }
}

