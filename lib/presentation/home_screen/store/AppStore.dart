import 'dart:ui';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../utils/SVColors.dart';
import '../../../core/utils/edge_to_edge_helper.dart';

part 'AppStore.g.dart';

class AppStore = AppStoreBase with _$AppStore;

abstract class AppStoreBase with Store {
  static const String _darkModeKey = 'is_dark_mode';
  static const String _themeSourceKey = 'theme_source'; // 'system' or 'user'

  @observable
  bool isDarkMode = false;

  @observable
  bool isUsingSystemTheme = true; // Track if using system theme or user choice

  /// Get the current system brightness (dark or light mode)
  bool _getSystemIsDarkMode() {
    // Use PlatformDispatcher to get system brightness without context
    final brightness = PlatformDispatcher.instance.platformBrightness;
    return brightness == Brightness.dark;
  }

  /// Initialize the store by loading saved preferences or using system theme
  Future<void> initialize() async {
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();

      // Check if user has manually set a theme preference
      final themeSource = await prefs.getString(_themeSourceKey);
      final savedDarkMode = await prefs.getBool(_darkModeKey);

      if (themeSource == 'user' && savedDarkMode != null) {
        // User has manually chosen a theme, use their preference
        isUsingSystemTheme = false;
        await toggleDarkMode(value: savedDarkMode, save: false);
        debugPrint('Using user-selected theme: ${savedDarkMode ? "dark" : "light"}');
      } else {
        // No user preference, use system theme as default
        isUsingSystemTheme = true;
        final systemIsDark = _getSystemIsDarkMode();
        await toggleDarkMode(value: systemIsDark, save: false);
        debugPrint('Using system theme: ${systemIsDark ? "dark" : "light"}');
      }
    } catch (e) {
      debugPrint('AppStore initialization error: $e');
      // Fallback to system theme on error
      final systemIsDark = _getSystemIsDarkMode();
      await toggleDarkMode(value: systemIsDark, save: false, isUserChoice: false);
    }
  }

  /// Update theme based on system theme change (only if using system theme)
  @action
  Future<void> updateFromSystemTheme() async {
    if (isUsingSystemTheme) {
      final systemIsDark = _getSystemIsDarkMode();
      if (isDarkMode != systemIsDark) {
        await toggleDarkMode(value: systemIsDark, save: false, isUserChoice: false);
        debugPrint('System theme changed, updated to: ${systemIsDark ? "dark" : "light"}');
      }
    }
  }

  @action
  Future<void> toggleDarkMode({bool? value, bool save = true, bool isUserChoice = true}) async {
    isDarkMode = value ?? !isDarkMode;

    // Save the preference
    if (save) {
      try {
        final prefs = SecureStorageService.instance;
        await prefs.initialize();
        await prefs.setBool(_darkModeKey, isDarkMode);

        // Mark that user has manually chosen a theme (no longer following system)
        if (isUserChoice) {
          isUsingSystemTheme = false;
          await prefs.setString(_themeSourceKey, 'user');
          debugPrint('User manually set theme to: ${isDarkMode ? "dark" : "light"}');
        }
      } catch (e) {
        debugPrint('Error saving dark mode preference: $e');
      }
    }

    if (isDarkMode) {
      textPrimaryColorGlobal = Colors.white;
      textSecondaryColorGlobal = viewLineColor;

      defaultLoaderBgColorGlobal = Colors.white;
      shadowColorGlobal = Colors.white12;

      // Configure edge-to-edge for dark mode
      EdgeToEdgeHelper.configureEdgeToEdgeDark();
    } else {
      textPrimaryColorGlobal = textPrimaryColor;
      textSecondaryColorGlobal = textSecondaryColor;

      defaultLoaderBgColorGlobal = Colors.white;
      appButtonBackgroundColorGlobal = SVAppColorPrimary;
      shadowColorGlobal = Colors.black12;

      // Configure edge-to-edge for light mode
      EdgeToEdgeHelper.configureEdgeToEdge();
    }
  }

  /// Reset to follow system theme instead of user preference
  @action
  Future<void> useSystemTheme() async {
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();

      // Remove user preference and set to system mode
      await prefs.remove(_themeSourceKey);
      await prefs.remove(_darkModeKey);
      isUsingSystemTheme = true;

      // Apply current system theme
      final systemIsDark = _getSystemIsDarkMode();
      await toggleDarkMode(value: systemIsDark, save: false, isUserChoice: false);
      debugPrint('Switched to system theme: ${systemIsDark ? "dark" : "light"}');
    } catch (e) {
      debugPrint('Error resetting to system theme: $e');
    }
  }
}
