import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class MasterDataService {
  static Future<List<Map<String, dynamic>>> list(String type, {String search = ''}) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/master-data/$type').replace(
      queryParameters: {'per_page': '100', if (search.trim().isNotEmpty) 'search': search.trim()},
    );
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal memuat data master');
    }
    final data = body['data'] as Map<String, dynamic>;
    return (data['data'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> buyers({String search = ''}) => list('buyer', search: search);

  static Future<Map<String, dynamic>> saveBuyer(Map<String, dynamic> data, {String? id}) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/master-buyers${id == null ? '' : '/$id'}');
    final finalResponse = id == null
        ? await http.post(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json', if (token != null) 'Authorization': 'Bearer $token'}, body: jsonEncode(data)).timeout(const Duration(seconds: 20))
        : await http.put(uri, headers: {'Content-Type': 'application/json', 'Accept': 'application/json', if (token != null) 'Authorization': 'Bearer $token'}, body: jsonEncode(data)).timeout(const Duration(seconds: 20));
    final body = jsonDecode(finalResponse.body) as Map<String, dynamic>;
    if (finalResponse.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal menyimpan buyer');
    return body;
  }

  static Future<void> deactivateBuyer(String id) async {
    final token = await AuthService.getToken();
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/master-buyers/$id'), headers: {'Accept': 'application/json', if (token != null) 'Authorization': 'Bearer $token'});
    if (response.statusCode >= 400) throw Exception('Gagal menonaktifkan buyer');
  }
}
