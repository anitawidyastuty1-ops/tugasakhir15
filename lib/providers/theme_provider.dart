import 'package:flutter/material.dart';

import '../core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _isDarkMode = await StorageService.isDarkMode();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await StorageService.saveDarkMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    await StorageService.saveDarkMode(_isDarkMode);
    notifyListeners();
  }
}
