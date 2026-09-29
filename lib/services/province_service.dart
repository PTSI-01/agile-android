import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ProvinceListResult {
  final bool success;
  final String message;
  final List<Map<String, dynamic>> items;
  final int total;
  final int currentPage;
  final int lastPage;

  const ProvinceListResult({
    required this.success,
    required this.message,
    this.items = const [],
    this.total = 0,
    this.currentPage = 1,
    this.lastPage = 1,
  });
}

class ProvinceService {
  static Future<ProvinceListResult> list({
    String search = '',
    int page = 1,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/provinces').replace(
              queryParameters: {
                'page': '$page',
                'per_page': '50',
                if (search.trim().isNotEmpty) 'search': search.trim(),
              },
            ),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 404) {
        return await _legacyList(search: search);
      }
      final body = _decode(response);
      if (response.statusCode >= 400 || body['success'] != true) {
        return ProvinceListResult(
          success: false,
          message: _message(body, 'Gagal memuat data provinsi.'),
        );
      }
      final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? {};
      return ProvinceListResult(
        success: true,
        message: body['message']?.toString() ?? 'Berhasil',
        items: (data['data'] as List? ?? [])
            .whereType<Map>()
            .map((row) => row.cast<String, dynamic>())
            .toList(),
        total: _asInt(data['total']),
        currentPage: _asInt(data['current_page'], fallback: 1),
        lastPage: _asInt(data['last_page'], fallback: 1),
      );
    } catch (error) {
      return ProvinceListResult(
        success: false,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  static Future<Map<String, dynamic>> save(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/provinces${id == null ? '' : '/$id'}',
      );
      final response = id == null
          ? await http
                .post(
                  uri,
                  headers: await _headers(json: true),
                  body: jsonEncode(data),
                )
                .timeout(const Duration(seconds: 20))
          : await http
                .put(
                  uri,
                  headers: await _headers(json: true),
                  body: jsonEncode(data),
                )
                .timeout(const Duration(seconds: 20));
      return _result(response, 'Gagal menyimpan provinsi.');
    } catch (error) {
      return {
        'success': false,
        'message': error.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  static Future<Map<String, dynamic>> delete(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/provinces/$id'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 20));
      return _result(response, 'Gagal menghapus provinsi.');
    } catch (error) {
      return {
        'success': false,
        'message': error.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await AuthService.getToken();
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _result(http.Response response, String fallback) {
    if (response.statusCode == 404) {
      return {
        'success': false,
        'message': 'API CRUD Provinsi belum tersedia di server. Backend Laravel perlu diperbarui.',
      };
    }
    final body = _decode(response);
    if (response.statusCode >= 400 || body['success'] != true) {
      return {'success': false, 'message': _message(body, fallback)};
    }
    return body;
  }

  static Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {
      // Ditangani sebagai respons server yang tidak valid.
    }
    if (response.statusCode == 401) {
      throw Exception('Sesi login sudah berakhir. Silakan masuk kembali.');
    }
    if (response.statusCode == 403) {
      throw Exception('Anda tidak memiliki hak untuk melakukan aksi ini.');
    }
    throw Exception(
      'Respons server tidak valid (HTTP ${response.statusCode}).',
    );
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

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static Future<ProvinceListResult> _legacyList({String search = ''}) async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/master-data/wilayah')
              .replace(queryParameters: {'per_page': '100'}),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 20));
    final body = _decode(response);
    if (response.statusCode >= 400 || body['success'] != true) {
      return ProvinceListResult(
        success: false,
        message: _message(body, 'Gagal memuat data provinsi.'),
      );
    }

    final data = (body['data'] as Map?)?.cast<String, dynamic>() ?? {};
    final query = search.trim().toLowerCase();
    final items = (data['data'] as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .where((row) {
          if (query.isEmpty) return true;
          return '${row['code'] ?? ''} ${row['name'] ?? ''}'
              .toLowerCase()
              .contains(query);
        })
        .toList();

    return ProvinceListResult(
      success: true,
      message: 'Berhasil',
      items: items,
      total: items.length,
    );
  }
}
