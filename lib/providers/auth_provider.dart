import 'package:flutter/material.dart';

import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    try {
      _token = await StorageService.getToken();
      _currentUser = await StorageService.getUser();

      if (_token != null && _token!.isNotEmpty) {
        // Refresh profile data from API
        final res = await ApiService.getProfile();
        if (res.success && res.data != null) {
          _currentUser = res.data;
          await StorageService.saveUser(res.data!);
        }
      }
    } catch (e) {
      debugPrint('CheckAuthStatus error: $e');
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.login(email: email, password: password);

    _isLoading = false;
    if (res.success && res.data != null) {
      _token = res.data!['token'];
      _currentUser = res.data!['user'];

      if (_token != null) {
        await StorageService.saveToken(_token!);
      }
      if (_currentUser != null) {
        await StorageService.saveUser(_currentUser!);
      }

      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? batch,
    int? trainingId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.register(
      name: name,
      email: email,
      password: password,
      batch: batch,
      trainingId: trainingId,
    );

    _isLoading = false;
    if (res.success && res.data != null) {
      _token = res.data!['token'];
      _currentUser = res.data!['user'];

      if (_token != null) {
        await StorageService.saveToken(_token!);
      }
      if (_currentUser != null) {
        await StorageService.saveUser(_currentUser!);
      }

      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(String newName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.updateProfile(name: newName);

    _isLoading = false;
    if (res.success && res.data != null) {
      _currentUser = res.data;
      await StorageService.saveUser(res.data!);
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchProfile() async {
    if (!isAuthenticated) return;
    final res = await ApiService.getProfile();
    if (res.success && res.data != null) {
      _currentUser = res.data;
      await StorageService.saveUser(res.data!);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await StorageService.clearAuthData();
    _token = null;
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
