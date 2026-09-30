import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_model.dart';

class StorageService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keyDarkMode = 'is_dark_mode';

  // Token Management
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  // User Management
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_keyUser);
    if (userStr != null) {
      try {
        return UserModel.fromJson(jsonDecode(userStr));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static Future<void> removeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  // Theme Management (Dark Mode / Light Mode)
  static Future<void> saveDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, isDark);
  }

  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  // Clear All Auth Data on Logout
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
