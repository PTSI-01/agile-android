import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class LabModuleService {
  static Future<List<Map<String, dynamic>>> incomingReferences() async {
    final token = await AuthService.getToken();
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/v1/lab-incoming/references'), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal memuat PO Lab Incoming');
    return ((body['data'] ?? []) as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<void> saveIncoming(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/v1/lab-incoming'), headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(data));
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal menyimpan Lab Incoming');
  }
  static Future<List<Map<String, dynamic>>> actualReferences() async {
    final token = await AuthService.getToken();
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/v1/lab-aktual/references'), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal memuat PO Lab Aktual');
    return ((body['data'] ?? []) as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<void> saveActual(Map<String, dynamic> data) async {
    final token = await AuthService.getToken();
    final response = await http.post(Uri.parse('${ApiConfig.baseUrl}/v1/lab-aktual'), headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(data));
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal menyimpan Lab Aktual');
  }
  static Future<List<Map<String, dynamic>>> list(String resource, {String search = '', bool history = false, bool input = false}) async {
    final token = await AuthService.getToken();
    final stage = resource == 'lab-aktual' ? 'aktual' : 'incoming';
    // Halaman input mengikuti web: data yang belum dicek berasal dari Buyer
    // (status transaksi), bukan dari tabel hasil lab yang belum dibuat.
    if (input && !history) {
      final endpoint = stage == 'aktual' ? 'lab-aktual/references' : 'lab-incoming/references';
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/$endpoint').replace(queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
      });
      final response = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
      final body = jsonDecode(response.body);
      if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal memuat data lab');
      return ((body['data'] ?? []) as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (input && history) {
      final uri = Uri.parse('${ApiConfig.baseUrl}/v1/transactions/${stage == 'aktual' ? 'lab-aktual' : 'lab-incoming'}').replace(queryParameters: {
        'per_page': '100',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      });
      final response = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
      final body = jsonDecode(response.body);
      if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal memuat riwayat lab');
      final data = body['data'];
      return ((data is Map ? data['data'] : data) as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/lab-approvals/$stage').replace(queryParameters: {
      'per_page': '100',
      'history': history ? '1' : '0',
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/parameter-lab').replace(queryParameters: {
      'per_page': '100',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    });
    final response = await http.get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal memuat parameter lab');
    final data = body['data'];
    return ((data is Map ? data['data'] : data) as List? ?? []).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }

  static Future<void> action(String stage, String id, {required bool approve}) async {
    final token = await AuthService.getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/v1/lab-approvals/$stage'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'id': id, 'aksi_lab': approve ? 1 : 5}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Aksi lab gagal disimpan');
  }

  static Future<void> saveParameter(Map<String, dynamic> data, {String? legalNumber}) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/parameter-lab${legalNumber == null ? '' : '/$legalNumber'}');
    final response = legalNumber == null
        ? await http.post(uri, headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(data))
        : await http.put(uri, headers: {'Accept': 'application/json', 'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode(data));
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) throw Exception(body['message'] ?? 'Gagal menyimpan Parameter Lab');
  }

  static Future<void> deleteParameter(String legalNumber) async {
    final token = await AuthService.getToken();
    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}/v1/parameter-lab/$legalNumber'), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    if (response.statusCode >= 400) throw Exception('Gagal menghapus Parameter Lab');
  }
}
