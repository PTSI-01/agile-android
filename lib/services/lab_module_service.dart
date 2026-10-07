import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class LabModuleService {
  static Future<List<Map<String, dynamic>>> list(String resource, {String search = ''}) async {
    final token = await AuthService.getToken();
    final stage = resource == 'lab-aktual' ? 'aktual' : 'incoming';
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/lab-approvals/$stage').replace(queryParameters: {
      'per_page': '100',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    });
    final response = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal memuat data lab');
    final data = body['data'];
    return ((data is Map ? data['data'] : data) as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<List<Map<String, dynamic>>> parameters({String search = ''}) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/master-data/parameter-lab').replace(queryParameters: {
      'per_page': '100',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    });
    final response = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal memuat parameter lab');
    final data = body['data'];
    return ((data is Map ? data['data'] : data) as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
}
