import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_endpoints.dart';
import '../../models/user_model.dart';
import '../../models/absen_model.dart';
import 'storage_service.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    required this.statusCode,
  });
}

class ApiService {
  static Map<String, String> _buildHeaders({String? token}) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String _extractErrorMessage(dynamic body, int statusCode) {
    if (body is Map) {
      if (body['message'] != null) {
        String msg = body['message'].toString();
        if (body['errors'] != null && body['errors'] is Map) {
          final errMap = body['errors'] as Map;
          final errorDetails = errMap.values
              .map((v) {
                if (v is List) return v.join(', ');
                return v.toString();
              })
              .join('\n');
          if (errorDetails.isNotEmpty) {
            return '$msg\n$errorDetails';
          }
        }
        return msg;
      }
    }
    switch (statusCode) {
      case 401:
        return 'Sesi telah berakhir atau kredensial salah.';
      case 404:
        return 'Data tidak ditemukan.';
      case 409:
        return 'Konflik data absensi.';
      case 422:
        return 'Data yang dikirimkan tidak valid.';
      case 500:
        return 'Terjadi gangguan pada server.';
      default:
        return 'Terjadi kesalahan (Kode: $statusCode)';
    }
  }

  // 1. REGISTER
  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    String? batch,
    int? trainingId,
  }) async {
    try {
      final url = Uri.parse(ApiEndpoints.register);
      final body = {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      };

      final response = await http
          .post(url, headers: _buildHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = json['data']?['token']?.toString() ?? '';
        final userData = json['data']?['user'];
        final user = userData != null ? UserModel.fromJson(userData) : null;

        return ApiResponse(
          success: true,
          message: json['message']?.toString() ?? 'Registrasi berhasil',
          data: {'token': token, 'user': user},
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(json, response.statusCode),
          errors: json['errors'] is Map ? json['errors'] : null,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Register Error: $e');
      return ApiResponse(
        success: false,
        message: 'Gagal terhubung ke server: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 2. LOGIN
  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse(ApiEndpoints.login);
      final body = {'email': email.trim(), 'password': password};

      final response = await http
          .post(url, headers: _buildHeaders(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = json['data']?['token']?.toString() ?? '';
        final userData = json['data']?['user'];
        final user = userData != null ? UserModel.fromJson(userData) : null;

        return ApiResponse(
          success: true,
          message: json['message']?.toString() ?? 'Login berhasil',
          data: {'token': token, 'user': user},
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(json, response.statusCode),
          errors: json['errors'] is Map ? json['errors'] : null,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      return ApiResponse(
        success: false,
        message: 'Gagal terhubung ke server: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 3. CHECK IN (Masuk / Izin)
  static Future<ApiResponse<AbsenModel>> checkIn({
    required double lat,
    required double lng,
    required String address,
    required String status, // 'masuk' or 'izin'
    String? alasanIzin,
  }) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiEndpoints.checkIn);

      final Map<String, dynamic> body = {
        'check_in_lat': lat.toString(),
        'check_in_lng': lng.toString(),
        'check_in_address': address,
        'status': status,
      };

      if (status == 'izin' && alasanIzin != null && alasanIzin.isNotEmpty) {
        body['alasan_izin'] = alasanIzin;
      }

      final response = await http
          .post(
            url,
            headers: _buildHeaders(token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final absen = AbsenModel.fromJson(json['data'] ?? {});
        return ApiResponse(
          success: true,
          message: json['message']?.toString() ?? 'Absen berhasil dicatat',
          data: absen,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(json, response.statusCode),
          errors: json['errors'] is Map ? json['errors'] : null,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('CheckIn Error: $e');
      return ApiResponse(
        success: false,
        message: 'Gagal melakukan absen masuk: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 4. CHECK OUT (Pulang)
  static Future<ApiResponse<AbsenModel>> checkOut({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiEndpoints.checkOut);

      final Map<String, dynamic> body = {
        'check_out_lat': lat.toString(),
        'check_out_lng': lng.toString(),
        'check_out_location':
            '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
        'check_out_address': address,
      };

      final response = await http
          .post(
            url,
            headers: _buildHeaders(token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final absen = AbsenModel.fromJson(json['data'] ?? {});
        return ApiResponse(
          success: true,
          message: json['message']?.toString() ?? 'Absen keluar berhasil',
          data: absen,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(json, response.statusCode),
          errors: json['errors'] is Map ? json['errors'] : null,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('CheckOut Error: $e');
      return ApiResponse(
        success: false,
        message: 'Gagal melakukan absen keluar: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 5. GET HISTORY ABSEN
  static Future<ApiResponse<List<AbsenModel>>> getHistory({
    String? start,
    String? end,
  }) async {
    try {
      final token = await StorageService.getToken();
      String urlStr = ApiEndpoints.history;
      if (start != null && end != null) {
        urlStr += '?start=$start&end=$end';
      }
      final url = Uri.parse(urlStr);

      final response = await http
          .get(url, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<AbsenModel> list = [];
        if (json['data'] != null && json['data'] is List) {
          list = (json['data'] as List)
              .map((item) => AbsenModel.fromJson(item))
              .toList();
        }
        return ApiResponse(
          success: true,
          message:
              json['message']?.toString() ??
              'Berhasil mengambil riwayat absensi',
          data: list,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(json, response.statusCode),
          data: [],
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('GetHistory Error: $e');
      return ApiResponse(
        success: false,
        message: 'Gagal mengambil riwayat absensi: ${e.toString()}',
        data: [],
        statusCode: 0,
      );
    }
  }

  // 6. DELETE ABSEN
  static Future<ApiResponse<void>> deleteAbsen(int id) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiEndpoints.deleteAbsen(id));

      final response = await http
          .delete(url, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: json['message']?.toString() ?? 'Data absen berhasil dihapus',
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(json, response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('DeleteAbsen Error: $e');
      return ApiResponse(
        success: false,
        message: 'Gagal menghapus data absen: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 7. GET PROFILE
  static Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiEndpoints.profile);

      final response = await http
          .get(url, headers: _buildHeaders(token: token))
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(json['data'] ?? {});
        return ApiResponse(
          success: true,
          message: json['message']?.toString() ?? 'Berhasil mengambil profil',
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(json, response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('GetProfile Error: $e');
      return ApiResponse(
        success: false,
        message: 'Gagal mengambil profil: ${e.toString()}',
        statusCode: 0,
      );
    }
  }

  // 8. UPDATE PROFILE (Edit Name)
  static Future<ApiResponse<UserModel>> updateProfile({
    required String name,
  }) async {
    try {
      final token = await StorageService.getToken();
      final url = Uri.parse(ApiEndpoints.profile);

      final body = {'name': name.trim()};

      final response = await http
          .put(
            url,
            headers: _buildHeaders(token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(json['data'] ?? {});
        return ApiResponse(
          success: true,
          message: json['message']?.toString() ?? 'Profil berhasil diperbarui',
          data: user,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(json, response.statusCode),
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('UpdateProfile Error: $e');
      return ApiResponse(
        success: false,
        message: 'Gagal memperbarui profil: ${e.toString()}',
        statusCode: 0,
      );
    }
  }
}
