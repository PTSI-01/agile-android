import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class NotificationService {
  static Future<List<Map<String, dynamic>>> list() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) return const [];
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/v1/notifications'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Notifikasi belum dapat dimuat.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'];
    final rows = data is Map ? data['items'] : data;
    return (rows as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }
}
