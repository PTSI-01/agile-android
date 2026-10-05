import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class BongkaranService {
  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await AuthService.getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Map<String, dynamic>>> list({String search = ''}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/transactions/bongkaran')
        .replace(
          queryParameters: {
            'per_page': '100',
            if (search.trim().isNotEmpty) 'search': search.trim(),
          },
        );
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal memuat riwayat bongkaran');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_message(body, 'Gagal memuat riwayat bongkaran'));
    }
    final data = body['data'];
    final rows = data is Map ? data['data'] : data;
    return (rows as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<Map<String, dynamic>> references({String? bongkaranId}) async {
    final queryParameters = bongkaranId == null
        ? const <String, String>{}
        : <String, String>{'bongkaran_id': bongkaranId};
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/transactions/bongkaran-references',
    ).replace(queryParameters: queryParameters);
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 404) {
      throw Exception(
        'API referensi Bongkaran belum diperbarui di server. '
        'Silakan deploy route terbaru lalu coba lagi.',
      );
    }
    final body = _responseMap(response, 'Gagal memuat referensi bongkaran');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_message(body, 'Gagal memuat referensi bongkaran'));
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> save(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/transactions/bongkaran${id == null ? '' : '/$id'}',
    );
    final response = id == null
        ? await http
              .post(
                uri,
                headers: await _headers(json: true),
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 30))
        : await http
              .put(
                uri,
                headers: await _headers(json: true),
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 30));
    final body = _responseMap(response, 'Gagal menyimpan data bongkaran');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_message(body, 'Gagal menyimpan data bongkaran'));
    }
    return body;
  }

  static Future<void> delete(String id) async {
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/v1/transactions/bongkaran/$id'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 30));
    final body = _responseMap(response, 'Gagal membatalkan bongkaran');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_message(body, 'Gagal membatalkan bongkaran'));
    }
  }

  static Map<String, dynamic> _responseMap(
    http.Response response,
    String fallback,
  ) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {
      // Keep API failures in the same displayable exception shape.
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
