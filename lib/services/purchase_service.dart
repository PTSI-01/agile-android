import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class PurchaseService {
  static Map<String, dynamic> _body(http.Response r) {
    try {
      final v = jsonDecode(r.body);
      return v is Map<String, dynamic>
          ? v
          : Map<String, dynamic>.from(v as Map);
    } catch (_) {
      throw Exception(
        'Server mengembalikan halaman HTML (HTTP ${r.statusCode}). Periksa log Laravel.',
      );
    }
  }

  static Future<Map<String, dynamic>> references() async {
    final t = await AuthService.getToken();
    final r = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/purchase-orders/references'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
    );
    final b = jsonDecode(r.body);
    if (r.statusCode >= 400) {
      throw Exception(b['message'] ?? 'Gagal memuat referensi');
    }
    return (b['data'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> siteReferences(String site) async {
    final t = await AuthService.getToken();
    final r = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/purchase-orders/site-references/$site'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
    );
    final b = jsonDecode(r.body);
    if (r.statusCode >= 400) {
      throw Exception(b['message'] ?? 'Gagal memuat item site');
    }
    return (b['data'] as Map).cast<String, dynamic>();
  }

  static Future<List<Map<String, dynamic>>> wilayah(
    String level,
    String code,
  ) async {
    final t = await AuthService.getToken();
    final r = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/wilayah/$level/$code'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
    );
    final b = jsonDecode(r.body);
    if (r.statusCode >= 400) {
      throw Exception(b['message'] ?? 'Gagal memuat wilayah');
    }
    return ((b['data'] ?? []) as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> list({String search = ''}) async {
    final t = await AuthService.getToken();
    final u = Uri.parse('${ApiConfig.baseUrl}/purchase-orders').replace(
      queryParameters: {
        'per_page': '100',
        if (search.isNotEmpty) 'search': search,
      },
    );
    final r = await http.get(
      u,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
    );
    final b = jsonDecode(r.body);
    if (r.statusCode >= 400) {
      throw Exception(b['message'] ?? 'Gagal memuat pembelian');
    }
    return ((b['data']['data'] ?? []) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> save(Map<String, dynamic> data, {String? id}) async {
    final t = await AuthService.getToken();
    final u = Uri.parse(
      '${ApiConfig.baseUrl}/purchase-orders${id == null ? '' : '/$id'}',
    );
    final h = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $t',
    };
    final r = id == null
        ? await http.post(u, headers: h, body: jsonEncode(data))
        : await http.put(u, headers: h, body: jsonEncode(data));
    if (r.statusCode >= 400) {
      final b = _body(r);
      final errors = b['errors'];
      throw Exception(
        errors is Map
            ? errors.values.expand((x) => x is List ? x : [x]).join('\n')
            : (b['message'] ?? 'Gagal menyimpan pembelian'),
      );
    }
  }

  static Future<void> remove(String id) async {
    final t = await AuthService.getToken();
    final r = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/purchase-orders/$id'),
      headers: {'Authorization': 'Bearer $t'},
    );
    if (r.statusCode >= 400) throw Exception('Gagal menghapus pembelian');
  }
}
