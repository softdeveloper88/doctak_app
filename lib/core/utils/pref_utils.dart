//ignore: unused_import
import 'dart:convert';

import 'package:doctak_app/core/utils/secure_storage_service.dart';

class PrefUtils {
  static SecureStorageService? _secureStorage;
  static String _cachedTheme = 'primary';

  PrefUtils() {
    // init();
    SecureStorageService.instance.initialize().then((_) {
      _secureStorage = SecureStorageService.instance;
    });
  }

  Future<void> init() async {
    _secureStorage ??= SecureStorageService.instance;
    await _secureStorage!.initialize();
    // Load cached theme during initialization
    try {
      _cachedTheme = await _secureStorage!.getString('themeData') ?? 'primary';
    } catch (e) {
      _cachedTheme = 'primary';
    }
    print('SecureStorage Initialized');
  }

  ///will clear all the data stored in preference
  void clearPreferencesData() async {
    _secureStorage!.clear();
  }

  Future<void> setThemeData(String value) async {
    _cachedTheme = value; // Update cache immediately
    await _secureStorage!.setString('themeData', value);
  }

  /// Synchronous getter for theme data - returns cached value or default
  /// Use this for initial widget build where async is not possible
  String getThemeData() {
    return _cachedTheme;
  }

  /// Async getter for theme data - reads from secure storage
  /// Use this when you need the most up-to-date value
  Future<String> getThemeDataAsync() async {
    try {
      final theme = await _secureStorage!.getString('themeData') ?? 'primary';
      _cachedTheme = theme; // Update cache
      return theme;
    } catch (e) {
      return _cachedTheme;
    }
  }
}
