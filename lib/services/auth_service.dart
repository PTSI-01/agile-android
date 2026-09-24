import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/dashboard_model.dart';

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;
  final String? token;
  final bool passwordSetupRequired;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.passwordSetupRequired = false,
  });
}

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user_data';

  /// Melakukan login ke backend Laravel
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.loginUrl);
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
              'device_name': 'agile-mobile-android',
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final isSuccess = data['success'] == true;
      final message = data['message'] as String? ??
          (isSuccess ? 'Login berhasil' : 'Gagal masuk.');

      if (isSuccess && data['data'] != null) {
        final token = data['data']['token'] as String;
        final userData = data['data']['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        // Simpan sesi ke local storage
        await _saveSession(token: token, user: user);

        return AuthResult(
          success: true,
          message: message,
          token: token,
          user: user,
        );
      } else {
        final isPasswordSetup = data['password_setup_required'] == true;
        return AuthResult(
          success: false,
          message: message,
          passwordSetupRequired: isPasswordSetup,
        );
      }
    } on SocketException catch (_) {
      return AuthResult(
        success: false,
        message:
            'Tidak dapat terhubung ke server Laravel (${ApiConfig.baseUrl}). Pastikan server aktif dan IP sesuai.',
      );
    } on TimeoutException catch (_) {
      return AuthResult(
        success: false,
        message: 'Koneksi ke server timeout. Silakan coba lagi.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  /// Logout dari backend dan hapus token lokal
  static Future<bool> logout() async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final uri = Uri.parse(ApiConfig.logoutUrl);
        await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Tetap lanjutkan hapus sesi lokal jika request server gagal
      }
    }

    await clearSession();
    return true;
  }

  /// Ambil data user yang sedang login dari local storage
  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyUser);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Ambil auth token tersimpan
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Cek apakah user sedang login
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<DashboardData?> getDashboard() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.dashboardUrl),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true || data['data'] is! Map<String, dynamic>) return null;
      return DashboardData.fromJson(data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Simpan token dan data user ke SharedPreferences
  static Future<void> _saveSession({
    required String token,
    required UserModel user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  /// Hapus sesi lokal
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
