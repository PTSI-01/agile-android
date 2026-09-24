import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/supplier_model.dart';
import 'auth_service.dart';

class SupplierListResult {
  final bool success;
  final String message;
  final List<SupplierModel> items;
  final int total;
  final int totalActive;
  final int totalInactive;
  final int currentPage;
  final int lastPage;

  SupplierListResult({
    required this.success,
    required this.message,
    this.items = const [],
    this.total = 0,
    this.totalActive = 0,
    this.totalInactive = 0,
    this.currentPage = 1,
    this.lastPage = 1,
  });
}

class SupplierService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Ambil daftar supplier dengan pagination dan filter
  static Future<SupplierListResult> getSuppliers({
    String? search,
    String? groupId,
    int? status,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (groupId != null && groupId.isNotEmpty) {
        queryParams['supplier_group_id'] = groupId;
      }
      if (status != null) {
        queryParams['status_user'] = status.toString();
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/suppliers')
          .replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final data = json['data'] as Map<String, dynamic>;
        final itemsRaw = (data['items'] as List? ?? []);
        final items = itemsRaw
            .map((e) => SupplierModel.fromJson(e as Map<String, dynamic>))
            .toList();

        final stats = data['stats'] as Map<String, dynamic>?;

        return SupplierListResult(
          success: true,
          message: json['message'] as String? ?? 'Berhasil memuat supplier',
          items: items,
          total: (data['total'] as int?) ?? items.length,
          totalActive: (stats?['active'] as int?) ?? 0,
          totalInactive: (stats?['inactive'] as int?) ?? 0,
          currentPage: (data['current_page'] as int?) ?? 1,
          lastPage: (data['last_page'] as int?) ?? 1,
        );
      } else {
        return SupplierListResult(
          success: false,
          message: json['message'] as String? ?? 'Gagal memuat data supplier',
        );
      }
    } on SocketException catch (_) {
      return SupplierListResult(
        success: false,
        message: 'Tidak dapat terhubung ke server Laravel (${ApiConfig.baseUrl}).',
      );
    } on TimeoutException catch (_) {
      return SupplierListResult(
        success: false,
        message: 'Koneksi ke server timeout.',
      );
    } catch (e) {
      return SupplierListResult(
        success: false,
        message: 'Terjadi kesalahan: ${e.toString()}',
      );
    }
  }

  /// Ambil detail 1 supplier
  static Future<SupplierModel?> getSupplierDetail(String id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/suppliers/$id');
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return SupplierModel.fromJson(json['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Ambil referensi (group, bank, buyer, provinsi)
  static Future<SupplierReferenceModel?> getReferences() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/suppliers/references');
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return SupplierReferenceModel.fromJson(
            json['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Ambil daftar kabupaten berdasarkan kode provinsi
  static Future<List<RegionRef>> getKabupaten(String provinceCode) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/wilayah/kabupaten/$provinceCode');
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((e) => RegionRef.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Ambil daftar kecamatan berdasarkan kode kota/kabupaten
  static Future<List<RegionRef>> getKecamatan(String cityCode) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/wilayah/kecamatan/$cityCode');
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((e) => RegionRef.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Ambil daftar desa/kelurahan berdasarkan kode kecamatan
  static Future<List<RegionRef>> getDesa(String districtCode) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/wilayah/desa/$districtCode');
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['success'] == true && json['data'] != null) {
        return (json['data'] as List)
            .map((e) => RegionRef.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Tambah Supplier baru
  static Future<Map<String, dynamic>> createSupplier(
      Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/suppliers');
      final response = await http
          .post(
            uri,
            headers: await _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 20));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengirim data: ${e.toString()}',
      };
    }
  }

  /// Update data supplier
  static Future<Map<String, dynamic>> updateSupplier(
      String id, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/suppliers/$id');
      final response = await http
          .put(
            uri,
            headers: await _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 20));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memperbarui data: ${e.toString()}',
      };
    }
  }

  /// Toggle status aktif/nonaktif supplier
  static Future<Map<String, dynamic>> toggleStatus(String id) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/suppliers/$id');
      final response = await http
          .delete(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal mengubah status: ${e.toString()}',
      };
    }
  }
}

