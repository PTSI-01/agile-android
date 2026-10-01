import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class PurchaseTargetService {
  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> list({
    String search = '',
    String status = 'all',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/purchase-targets').replace(
      queryParameters: {
        'per_page': '100',
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status != 'all') 'status': status,
      },
    );
    final body = await _send('GET', uri);
    final payload = body['data'];
    final rows = payload is Map ? payload['data'] : payload;
    return (rows as List? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> buyers() async {
    final body = await _send(
      'GET',
      Uri.parse('${ApiConfig.baseUrl}/purchase-targets/references'),
    );
    final payload = body['data'];
    final rows = payload is Map ? payload['buyers'] : null;
    return (rows as List? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<Map<String, dynamic>> show(String id) async {
    final body = await _send(
      'GET',
      Uri.parse('${ApiConfig.baseUrl}/purchase-targets/$id'),
    );
    return Map<String, dynamic>.from(body['data'] as Map? ?? const {});
  }

  static Future<Map<String, dynamic>> save(
    Map<String, dynamic> payload, {
    String? id,
  }) async {
    final uri = Uri.parse(
      id == null
          ? '${ApiConfig.baseUrl}/purchase-targets'
          : '${ApiConfig.baseUrl}/purchase-targets/$id',
    );
    return _send(id == null ? 'POST' : 'PUT', uri, payload: payload);
  }

  static Future<void> delete(String id) async {
    await _send(
      'DELETE',
      Uri.parse('${ApiConfig.baseUrl}/purchase-targets/$id'),
    );
  }

  static Future<Map<String, dynamic>> _send(
    String method,
    Uri uri, {
    Map<String, dynamic>? payload,
  }) async {
    final headers = await _headers();
    late http.Response response;
    try {
      if (method == 'POST') {
        response = await http
            .post(uri, headers: headers, body: jsonEncode(payload))
            .timeout(const Duration(seconds: 20));
      } else if (method == 'PUT') {
        response = await http
            .put(uri, headers: headers, body: jsonEncode(payload))
            .timeout(const Duration(seconds: 20));
      } else if (method == 'DELETE') {
        response = await http
            .delete(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
      } else {
        response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 20));
      }
    } on TimeoutException {
      throw Exception('Koneksi ke server timeout. Silakan coba lagi.');
    }

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      body = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      throw Exception(
        response.statusCode >= 500
            ? 'Server gagal memproses Target Pembelian.'
            : 'Respons server tidak valid (${response.statusCode}).',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? validationMessage;
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        validationMessage = first is List && first.isNotEmpty
            ? first.first.toString()
            : first.toString();
      }
      throw Exception(
        validationMessage ??
            body['message']?.toString() ??
            'Permintaan gagal (${response.statusCode}).',
      );
    }
    return body;
  }
}
