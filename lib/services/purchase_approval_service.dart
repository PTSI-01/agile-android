import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class PurchaseApprovalService {
  static Future<List<Map<String, dynamic>>> list({
    bool history = false,
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/purchase-approvals').replace(
      queryParameters: {
        'per_page': '100',
        'history': history ? '1' : '0',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal memuat approval pembelian');
    }
    return ((body['data']?['data'] ?? []) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  static Future<void> approve(
    String id, {
    required String aksiHarga,
    num? reaksiHarga,
    String? kualitasGabah,
  }) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/purchase-approvals/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'aksi_harga': aksiHarga,
        'reaksi_harga': reaksiHarga,
        'kualitas_gabah': kualitasGabah,
      }),
    );
    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Approval pembelian gagal disimpan');
    }
  }
}
