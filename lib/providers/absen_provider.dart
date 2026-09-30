import 'package:flutter/material.dart';

import '../core/services/api_service.dart';
import '../core/services/location_service.dart';
import '../core/utils/date_formatter.dart';
import '../models/absen_model.dart';

class AbsenProvider extends ChangeNotifier {
  List<AbsenModel> _history = [];
  AbsenModel? _todayAbsen;
  bool _isLoadingHistory = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  // Filter state
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  List<AbsenModel> get history => _history;
  AbsenModel? get todayAbsen => _todayAbsen;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;

  // Statistics
  int get totalAbsen => _history.length;
  int get totalMasuk => _history.where((a) => !a.isIzin).length;
  int get totalIzin => _history.where((a) => a.isIzin).length;
  int get totalSelesai => _history.where((a) => a.isCheckedOut).length;

  double get attendancePercentage {
    if (_history.isEmpty) return 0.0;
    return (totalMasuk / _history.length) * 100;
  }

  // Check today's status
  // Options: 'belum_absen', 'masuk', 'izin', 'selesai'
  String get todayStatus {
    if (_todayAbsen == null) return 'belum_absen';
    if (_todayAbsen!.isIzin) return 'izin';
    if (_todayAbsen!.isCheckedOut) return 'selesai';
    return 'masuk';
  }

  void _identifyTodayAbsen() {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    _todayAbsen = null;
    for (final item in _history) {
      final date = item.checkInDateTime ?? item.createdDateTime;
      if (date != null) {
        final itemDateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        if (itemDateStr == todayStr) {
          _todayAbsen = item;
          break;
        }
      }
    }
  }

  Future<void> fetchHistory({DateTime? start, DateTime? end}) async {
    _isLoadingHistory = true;
    _errorMessage = null;
    notifyListeners();

    _filterStartDate = start;
    _filterEndDate = end;

    String? startStr;
    String? endStr;
    if (start != null && end != null) {
      startStr = DateFormatter.formatApiDate(start);
      endStr = DateFormatter.formatApiDate(end);
    }

    final res = await ApiService.getHistory(start: startStr, end: endStr);

    _isLoadingHistory = false;
    if (res.success && res.data != null) {
      _history = res.data!;
      _identifyTodayAbsen();
    } else {
      _errorMessage = res.message;
    }
    notifyListeners();
  }

  Future<bool> checkIn({
    required String status, // 'masuk' or 'izin'
    String? alasanIzin,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Get current location
      final locationResult = await LocationService.getCurrentLocation();

      // 2. Call API
      final res = await ApiService.checkIn(
        lat: locationResult.latitude,
        lng: locationResult.longitude,
        address: locationResult.address,
        status: status,
        alasanIzin: alasanIzin,
      );

      _isSubmitting = false;
      if (res.success && res.data != null) {
        _successMessage = res.message;
        _todayAbsen = res.data;
        // Refresh history to have all recent records
        await fetchHistory();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Terjadi kesalahan saat absensi: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut() async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Get current location
      final locationResult = await LocationService.getCurrentLocation();

      // 2. Call API
      final res = await ApiService.checkOut(
        lat: locationResult.latitude,
        lng: locationResult.longitude,
        address: locationResult.address,
      );

      _isSubmitting = false;
      if (res.success && res.data != null) {
        _successMessage = res.message;
        _todayAbsen = res.data;
        await fetchHistory();
        return true;
      } else {
        _errorMessage = res.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Terjadi kesalahan saat absen pulang: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAbsen(int id) async {
    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final res = await ApiService.deleteAbsen(id);

    _isSubmitting = false;
    if (res.success) {
      _successMessage = res.message;
      _history.removeWhere((item) => item.id == id);
      if (_todayAbsen?.id == id) {
        _todayAbsen = null;
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
