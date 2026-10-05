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

  static Future<List<Map<String, dynamic>>> listSites({
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/inventory/sites').replace(
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
    final body = _responseMap(response, 'Gagal memuat master site');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat master site'));
    }
    final data = body['data'];
    final rows = data is Map ? data['data'] : data;
    return (rows as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<Map<String, dynamic>> getSite(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/v1/inventory/sites/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat detail site');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat detail site'));
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> saveSite(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/inventory/sites${id == null ? '' : '/$id'}',
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
    final body = _responseMap(response, 'Gagal menyimpan master site');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal menyimpan master site'));
    }
    return body;
  }

  static Future<void> deleteSite(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/v1/inventory/sites/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menghapus master site');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal menghapus master site'));
    }
  }

  static Future<List<Map<String, dynamic>>> listWarehouses({
    String search = '',
  }) => _listInventoryResource(
    'warehouses',
    search: search,
    label: 'master gudang',
  );

  static Future<Map<String, dynamic>> getWarehouse(String id) =>
      _getInventoryResource('warehouses', id, label: 'gudang');

  static Future<Map<String, dynamic>> saveWarehouse(
    Map<String, dynamic> data, {
    String? id,
  }) => _saveInventoryResource(
    'warehouses',
    data,
    id: id,
    label: 'master gudang',
  );

  static Future<void> deleteWarehouse(String id) =>
      _deleteInventoryResource('warehouses', id, label: 'master gudang');

  static Future<List<Map<String, dynamic>>> listBins({String search = ''}) =>
      _listInventoryResource('bins', search: search, label: 'master bin');

  static Future<Map<String, dynamic>> getBin(String id) =>
      _getInventoryResource('bins', id, label: 'bin');

  static Future<Map<String, dynamic>> saveBin(
    Map<String, dynamic> data, {
    String? id,
  }) => _saveInventoryResource('bins', data, id: id, label: 'master bin');

  static Future<void> deleteBin(String id) =>
      _deleteInventoryResource('bins', id, label: 'master bin');

  static Future<List<Map<String, dynamic>>> listSurveyors({
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/master-surveyors').replace(
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
    if (response.statusCode == 404) {
      return list('surveyor', search: search);
    }
    final body = _responseMap(response, 'Gagal memuat master surveyor');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat master surveyor'));
    }
    final data = body['data'];
    final rows = data is Map ? data['data'] : data;
    return (rows as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<Map<String, dynamic>> getSurveyor(String id) async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/master-surveyors/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 404) {
      final rows = await listSurveyors();
      return rows.firstWhere(
        (row) => row['id']?.toString() == id,
        orElse: () => <String, dynamic>{'id': id},
      );
    }
    final body = _responseMap(response, 'Gagal memuat detail surveyor');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat detail surveyor'));
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<List<Map<String, dynamic>>> surveyorUserReferences() async {
    final token = await AuthService.getToken();
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    http.Response? response;
    for (final path in const [
      '/master-surveyors/references',
      '/v1/master-surveyors/references',
    ]) {
      response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 404) break;
    }
    if (response == null || response.statusCode == 404) {
      throw Exception(
        'API User Account Surveyor belum tersedia di server. '
        'Deploy route master-surveyors lalu jalankan route:clear.',
      );
    }
    final body = _responseMap(response, 'Gagal memuat referensi user account');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(
        _responseMessage(body, 'Gagal memuat referensi user account'),
      );
    }
    final data = body['data'];
    final users = data is Map ? data['users'] : const [];
    return (users as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<Map<String, dynamic>> saveSurveyor(
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final token = await AuthService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    http.Response? response;
    for (final prefix in const ['/master-surveyors', '/v1/master-surveyors']) {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}$prefix${id == null ? '' : '/$id'}',
      );
      response = id == null
          ? await http
                .post(uri, headers: headers, body: jsonEncode(data))
                .timeout(const Duration(seconds: 20))
          : await http
                .put(uri, headers: headers, body: jsonEncode(data))
                .timeout(const Duration(seconds: 20));
      if (response.statusCode != 404) break;
    }
    if (response == null || response.statusCode == 404) {
      throw Exception(
        'API CRUD Master Surveyor belum tersedia di server. '
        'Deploy route master-surveyors lalu jalankan route:clear.',
      );
    }
    final body = _responseMap(response, 'Gagal menyimpan master surveyor');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(
        _responseMessage(body, 'Gagal menyimpan master surveyor'),
      );
    }
    return body;
  }

  static Future<void> deleteSurveyor(String id) async {
    final token = await AuthService.getToken();
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    http.Response? response;
    for (final prefix in const ['/master-surveyors', '/v1/master-surveyors']) {
      response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}$prefix/$id'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 404) break;
    }
    if (response == null || response.statusCode == 404) {
      throw Exception(
        'API CRUD Master Surveyor belum tersedia di server. '
        'Deploy route master-surveyors lalu jalankan route:clear.',
      );
    }
    final body = _responseMap(response, 'Gagal menghapus master surveyor');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(
        _responseMessage(body, 'Gagal menghapus master surveyor'),
      );
    }
  }

  static Future<List<Map<String, dynamic>>> _listInventoryResource(
    String resource, {
    required String label,
    String search = '',
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse('${ApiConfig.baseUrl}/v1/inventory/$resource')
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
    final body = _responseMap(response, 'Gagal memuat $label');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat $label'));
    }
    final data = body['data'];
    final rows = data is Map ? data['data'] : data;
    return (rows as List? ?? [])
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  static Future<Map<String, dynamic>> _getInventoryResource(
    String resource,
    String id, {
    required String label,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/v1/inventory/$resource/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));
    final body = _responseMap(response, 'Gagal memuat detail $label');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal memuat detail $label'));
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> _saveInventoryResource(
    String resource,
    Map<String, dynamic> data, {
    required String label,
    String? id,
  }) async {
    final token = await AuthService.getToken();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/v1/inventory/$resource${id == null ? '' : '/$id'}',
    );
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = id == null
        ? await http
              .post(uri, headers: headers, body: jsonEncode(data))
              .timeout(const Duration(seconds: 20))
        : await http
              .put(uri, headers: headers, body: jsonEncode(data))
              .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menyimpan $label');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal menyimpan $label'));
    }
    return body;
  }

  static Future<void> _deleteInventoryResource(
    String resource,
    String id, {
    required String label,
  }) async {
    final token = await AuthService.getToken();
    final response = await http
        .delete(
          Uri.parse('${ApiConfig.baseUrl}/v1/inventory/$resource/$id'),
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 20));
    final body = _responseMap(response, 'Gagal menghapus $label');
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(_responseMessage(body, 'Gagal menghapus $label'));
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
    late final Map<String, dynamic> body;
    try {
      body = _responseMap(response, 'Gagal memuat referensi pricelist');
    } catch (_) {
      if (response.statusCode == 404 || response.statusCode >= 500) {
        return _priceListReferencesFallback(priceListId: priceListId);
      }
      rethrow;
    }
    if (response.statusCode == 404 || response.statusCode >= 500) {
      return _priceListReferencesFallback(priceListId: priceListId);
    }
    if (response.statusCode >= 400 || body['success'] != true) {
      throw Exception(
        _responseMessage(body, 'Gagal memuat referensi pricelist'),
      );
    }
    return (body['data'] as Map).cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>> _priceListReferencesFallback({
    String? priceListId,
  }) async {
    final token = await AuthService.getToken();
    final headers = {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final requests = <Future<http.Response>>[
      http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/v1/inventory/items')
                .replace(queryParameters: const {'per_page': '100'}),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15)),
      http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/suppliers')
                .replace(queryParameters: const {'per_page': '100'}),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15)),
      if (priceListId != null)
        http
            .get(
              Uri.parse(
                '${ApiConfig.baseUrl}/v1/inventory/price-lists/$priceListId',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15)),
    ];
    final responses = await Future.wait(requests);
    final itemBody = _responseMap(responses[0], 'Gagal memuat referensi item');
    final supplierBody = _responseMap(
      responses[1],
      'Gagal memuat referensi supplier',
    );
    if (responses[0].statusCode >= 400 || itemBody['success'] != true) {
      throw Exception(
        _responseMessage(itemBody, 'Gagal memuat referensi item'),
      );
    }
    if (responses[1].statusCode >= 400 || supplierBody['success'] != true) {
      throw Exception(
        _responseMessage(supplierBody, 'Gagal memuat referensi supplier'),
      );
    }

    List<Map<String, dynamic>> rows(dynamic payload) {
      final data = payload is Map
          ? (payload['data'] ?? payload['items'])
          : payload;
      return (data as List? ?? [])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .toList();
    }

    final items = rows(itemBody['data']);
    final suppliers = rows(supplierBody['data']);
    if (priceListId != null && responses.length > 2) {
      final detailBody = _responseMap(
        responses[2],
        'Gagal memuat detail pricelist',
      );
      if (responses[2].statusCode < 400 && detailBody['success'] == true) {
        final detail = detailBody['data'];
        if (detail is Map) {
          final priceList = detail.cast<String, dynamic>();
          final item = priceList['item'];
          if (item is Map &&
              !items.any(
                (row) => row['id'].toString() == item['id'].toString(),
              )) {
            items.add(item.cast<String, dynamic>());
          }
          final supplier = priceList['supplier'];
          if (supplier is Map &&
              !suppliers.any(
                (row) => row['id'].toString() == supplier['id'].toString(),
              )) {
            suppliers.add(supplier.cast<String, dynamic>());
          }
        }
      }
    }
    return {'items': items, 'suppliers': suppliers};
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
    late final Map<String, dynamic> body;
    try {
      body = _responseMap(response, 'Gagal memeriksa pricelist aktif');
    } catch (_) {
      if (response.statusCode == 404 || response.statusCode >= 500) {
        final rows = await listPriceLists();
        return rows.any(
          (row) =>
              row['item_id']?.toString() == itemId &&
              row['supplier_id']?.toString() == supplierId &&
              row['status']?.toString().toLowerCase() == 'aktif' &&
              row['id']?.toString() != ignoreId,
        );
      }
      rethrow;
    }
    if (response.statusCode == 404 || response.statusCode >= 500) {
      final rows = await listPriceLists();
      return rows.any(
        (row) =>
            row['item_id']?.toString() == itemId &&
            row['supplier_id']?.toString() == supplierId &&
            row['status']?.toString().toLowerCase() == 'aktif' &&
            row['id']?.toString() != ignoreId,
      );
    }
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
