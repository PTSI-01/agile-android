import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/buyer_group_model.dart';
import 'auth_service.dart';

class BuyerGroupListResult {
  final bool success;
  final String message;
  final List<BuyerGroupModel> items;
  final int total;

  const BuyerGroupListResult({
    required this.success,
    required this.message,
    this.items = const [],
    this.total = 0,
  });
}

class BuyerGroupService {
  static const _path = 'buyer-groups';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<BuyerGroupListResult> list({String? search}) async {
    try {
      final query = <String, String>{'per_page': '100'};
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}/$_path')
          .replace(queryParameters: query);
      final response = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 15));
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400 || body['success'] != true) {
        return BuyerGroupListResult(
          success: false,
          message: body['message']?.toString() ?? 'Gagal memuat buyer group',
        );
      }

      final data = body['data'];
      final rows = data is List
          ? data
          : data is Map<String, dynamic>
              ? (data['data'] ?? data['items'] ?? [])
              : [];
      final items = (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(BuyerGroupModel.fromJson)
          .toList();
      final total = data is Map<String, dynamic>
          ? int.tryParse((data['total'] ?? items.length).toString()) ?? items.length
          : items.length;
      return BuyerGroupListResult(
        success: true,
        message: body['message']?.toString() ?? 'Berhasil memuat buyer group',
        items: items,
        total: total,
      );
    } on SocketException {
      return const BuyerGroupListResult(
        success: false,
        message: 'Tidak dapat terhubung ke server Laravel.',
      );
    } on TimeoutException {
      return const BuyerGroupListResult(
        success: false,
        message: 'Koneksi ke server timeout.',
      );
    } catch (error) {
      return BuyerGroupListResult(
        success: false,
        message: 'Terjadi kesalahan: $error',
      );
    }
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) =>
      _send('POST', _path, data, 'Gagal menambahkan buyer group');

  static Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> data,
  ) =>
      _send('PUT', '$_path/$id', data, 'Gagal memperbarui buyer group');

  static Future<Map<String, dynamic>> delete(String id) =>
      _send('DELETE', '$_path/$id', null, 'Gagal menghapus buyer group');

  static Future<Map<String, dynamic>> detail(String id) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/$_path/$id'), headers: await _headers()).timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || body['success'] != true) throw Exception(body['message'] ?? 'Gagal memuat detail buyer group');
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic>? data,
    String fallback,
  ) async {
    try {
      final request = http.Request(method, Uri.parse('${ApiConfig.baseUrl}/$path'))
        ..headers.addAll(await _headers());
      if (data != null) request.body = jsonEncode(data);
      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
      return {'success': response.statusCode < 400, 'message': fallback};
    } catch (error) {
      return {'success': false, 'message': '$fallback: $error'};
    }
  }
}
