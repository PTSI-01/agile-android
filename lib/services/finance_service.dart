import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class FinanceService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> list({String search = ''}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/transactions/finance')
        .replace(
          queryParameters: {
            'per_page': '100',
            if (search.trim().isNotEmpty) 'search': search.trim(),
          },
        );

    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 20));

    final body = _responseMap(response, 'Gagal memuat data finance');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_message(body, 'Gagal memuat data finance'));
    }

    final data = body['data'];
    final rows = data is Map ? data['data'] : data;
    return (rows as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Map<String, dynamic> _responseMap(
    http.Response response,
    String fallback,
  ) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {
      // ignore and continue to error conversion
    }

    if (response.statusCode == 401) {
      throw Exception('Sesi login berakhir. Silakan masuk kembali.');
    }
    if (response.statusCode == 403) {
      throw Exception('Anda tidak memiliki izin untuk tindakan ini.');
    }
    throw Exception('$fallback (HTTP ${response.statusCode}).');
  }

  static String _message(Map<String, dynamic> body, String fallback) {
    final errors = body['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }
    return body['message']?.toString() ?? fallback;
  }
}
