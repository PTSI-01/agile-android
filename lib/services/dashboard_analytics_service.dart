import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class DashboardAnalyticsService {
  static Future<Map<String, dynamic>> fetch(String kind) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan');
    }
    final path = switch (kind) {
      'pembelian' => 'v1/dashboard/pembelian',
      'laba-rugi' => 'v1/dashboard/laba-rugi',
      _ => 'v1/dashboard/hasil-lab',
    };
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/$path'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gagal memuat dashboard (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw Exception('Format data dashboard tidak valid');
    return Map<String, dynamic>.from(decoded);
  }
}
