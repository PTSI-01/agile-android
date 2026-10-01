import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class MasterDataService {
  static Future<List<Map<String, dynamic>>> list(
    String type, {
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/master-data/$type').replace(
      queryParameters: {
        'per_page': '100',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal memuat data master');
    }
    final data = body['data'] as Map<String, dynamic>;
    return (data['data'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> buyers({String search = ''}) =>
      list('buyer', search: search);

  static Future<List<Map<String, dynamic>>> listItems({
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/inventory/items').replace(
      queryParameters: {
        'per_page': '100',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat master item');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat master item'));
    }
    final data = body['data'];
    final rows = data is Map ? data['data'] : data;
    return (rows as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<Map<String, dynamic>> getItem(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/v1/inventory/items/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat detail master item');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(
        _responseMessage(body, 'Gagal memuat detail master item'),
      );
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> itemReferences({String? itemId}) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/inventory/items/references');
    final response = await http
        .get(
          uri.replace(
            queryParameters: itemId == null
                ? const <String, String>{}
                : <String, String>{'item_id': itemId},
          ),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat referensi item');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat referensi item'));
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> saveItem(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/inventory/items${id == null ? '' : '/$id'}',
    );
    final response = id == null
        ? await http
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20))
        : await http
              .put(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menyimpan master item');
    if (response.statusCode >= 400 || body['success'] == false) {
      throw Exception(_responseMessage(body, 'Gagal menyimpan master item'));
    }
    return body;
  }

  static Future<void> deleteItem(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/v1/inventory/items/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menghapus master item');
    if (response.statusCode >= 400 || body['success'] == false) {
      throw Exception(_responseMessage(body, 'Gagal menghapus master item'));
    }
  }

  static Future<List<Map<String, dynamic>>> listUnits({
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/inventory/units').replace(
      queryParameters: {
        'per_page': '100',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat master satuan');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat master satuan'));
    }
    final data = body['data'];
    final rows = data is Map ? data['data'] : data;
    return (rows as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<Map<String, dynamic>> getUnit(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/v1/inventory/units/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat detail satuan');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat detail satuan'));
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> saveUnit(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/inventory/units${id == null ? '' : '/$id'}',
    );
    final response = id == null
        ? await http
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20))
        : await http
              .put(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menyimpan master satuan');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal menyimpan master satuan'));
    }
    return body;
  }

  static Future<void> deleteUnit(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/v1/inventory/units/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menghapus master satuan');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal menghapus master satuan'));
    }
  }

  static Future<List<Map<String, dynamic>>> listUnitConversions({
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/inventory/unit-conversions')
        .replace(
          queryParameters: {
            'per_page': '100',
            if (search.trim().isNotEmpty) 'search': search.trim(),
          },
        );
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat konversi satuan');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat konversi satuan'));
    }
    final data = body['data'];
    final rows = data is Map ? data['data'] : data;
    return (rows as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<Map<String, dynamic>> unitConversionReferences({
    String? conversionId,
  }) async {
    final token = await AuthService.getToken();
    final uri =
        Uri.parse(
          '${ApiConfig.baseUrl}/v1/inventory/unit-conversions/references',
        ).replace(
          queryParameters: conversionId == null
              ? const <String, String>{}
              : <String, String>{'conversion_id': conversionId},
        );
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat referensi konversi');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(
        _responseMessage(body, 'Gagal memuat referensi konversi'),
      );
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> saveUnitConversion(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/inventory/unit-conversions${id == null ? '' : '/$id'}',
    );
    final response = id == null
        ? await http
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20))
        : await http
              .put(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menyimpan konversi satuan');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(
        _responseMessage(body, 'Gagal menyimpan konversi satuan'),
      );
    }
    return body;
  }

  static Future<void> deleteUnitConversion(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/v1/inventory/unit-conversions/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menghapus konversi satuan');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(
        _responseMessage(body, 'Gagal menghapus konversi satuan'),
      );
    }
  }

  static Future<List<Map<String, dynamic>>> listPriceLists({
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/inventory/price-lists')
        .replace(
          queryParameters: {
            'per_page': '100',
            if (search.trim().isNotEmpty) 'search': search.trim(),
          },
        );
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat pricelist item');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat pricelist item'));
    }
    final data = body['data'];
    final rows = data is Map ? data['data'] : data;
    return (rows as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<Map<String, dynamic>> priceListReferences({
    String? priceListId,
  }) async {
    final token = await AuthService.getToken();
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/v1/inventory/price-lists/references')
            .replace(
              queryParameters: priceListId == null
                  ? const <String, String>{}
                  : <String, String>{'price_list_id': priceListId},
            );
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat referensi pricelist');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(
        _responseMessage(body, 'Gagal memuat referensi pricelist'),
      );
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<bool> hasActivePriceList({
    required String itemId,
    required String supplierId,
    String? ignoreId,
  }) async {
    final token = await AuthService.getToken();
    final query = <String, String>{
      'item_id': itemId,
      'supplier_id': supplierId,
    };
    if (ignoreId != null) query['ignore_id'] = ignoreId;
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/inventory/price-lists/check-active',
    ).replace(queryParameters: query);
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memeriksa pricelist aktif');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(
        _responseMessage(body, 'Gagal memeriksa pricelist aktif'),
      );
    }
    return body['has_active'] == true;
  }

  static Future<Map<String, dynamic>> savePriceList(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/inventory/price-lists${id == null ? '' : '/$id'}',
    );
    final response = id == null
        ? await http
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20))
        : await http
              .put(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menyimpan pricelist item');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal menyimpan pricelist item'));
    }
    return body;
  }

  static Future<void> deletePriceList(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/v1/inventory/price-lists/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menghapus pricelist item');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal menghapus pricelist item'));
    }
  }

  static Future<List<Map<String, dynamic>>> banks({String search = ''}) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/master-banks').replace(
      queryParameters: {
        'per_page': '100',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal memuat master bank');
    }
    final data = body['data'] as Map<String, dynamic>;
    return (data['data'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> saveBank(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/master-banks${id == null ? '' : '/$id'}',
    );
    final response = id == null
        ? await http
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20))
        : await http
              .put(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menyimpan master bank');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal menyimpan master bank'));
    }
    return body;
  }

  static Map<String, dynamic> _responseMap(
    http.Response response,
    String fallback,
  ) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {
      // Pesan yang ramah pengguna diberikan di bawah.
    }

    if (response.statusCode == 401) {
      throw Exception('Sesi login sudah berakhir. Silakan masuk kembali.');
    }
    if (response.statusCode == 403) {
      throw Exception('Anda tidak memiliki hak untuk melakukan tindakan ini.');
    }
    throw Exception('$fallback (HTTP ${response.statusCode}).');
  }

  static String _responseMessage(Map<String, dynamic> body, String fallback) {
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

  static Future<Map<String, dynamic>> bankDetail(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/master-banks/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal memuat detail bank');
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<void> deleteBank(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/master-banks/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menghapus master bank');
    }
  }

  static Future<Map<String, dynamic>> saveBuyer(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/master-buyers${id == null ? '' : '/$id'}',
    );
    final finalResponse = id == null
        ? await http
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20))
        : await http
              .put(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode(data),
              )
              .timeout(const Duration(seconds: 20));
    final body = jsonDecode(finalResponse.body) as Map<String, dynamic>;
    if (finalResponse.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Gagal menyimpan buyer');
    }
    return body;
  }

  static Future<Map<String, dynamic>> buyerDetail(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/master-buyers/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Gagal memuat detail buyer');
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<void> deactivateBuyer(String id) async {
    final token = await AuthService.getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/master-buyers/$id'),
      headers: {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode >= 400) {
      throw Exception('Gagal menonaktifkan buyer');
    }
  }
}
