import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _keyBaseUrl = 'custom_api_base_url';

  // Development backend on the same Wi-Fi as the physical Android device.
  // For an Android Emulator, use http://10.0.2.2:8000/api instead.
  static const String defaultBaseUrl = 'http://192.168.3.55:8000/api';

  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  /// Inisialisasi base URL dari SharedPreferences jika tersimpan
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyBaseUrl);
    // The development machine received a new LAN address; migrate the old
    // default automatically while preserving any other custom server URL.
    if (stored == null ||
        stored.contains('192.168.3.241') ||
        stored.contains('192.168.3.160')) {
      _baseUrl = defaultBaseUrl;
      await prefs.setString(_keyBaseUrl, _baseUrl);
    } else {
      _baseUrl = stored;
    }
  }

  /// Ubah base URL (misal: http://192.168.1.10:8000/api)
  static Future<void> setBaseUrl(String newUrl) async {
    final sanitized = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    _baseUrl = sanitized.endsWith('/api') ? sanitized : '$sanitized/api';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, _baseUrl);
  }

  /// Reset ke default
  static Future<void> resetBaseUrl() async {
    _baseUrl = defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBaseUrl);
  }

  // Endpoints
  static String get loginUrl => '$_baseUrl/login';
  static String get logoutUrl => '$_baseUrl/logout';
  static String get meUrl => '$_baseUrl/me';
  static String get dashboardUrl => '$_baseUrl/dashboard';
}
