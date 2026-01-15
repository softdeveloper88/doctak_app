import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:flutter/foundation.dart';

/// Get SecureStorageService instance with retry mechanism for devices
/// where initialization may be delayed in release mode.
/// This replaces the old SharedPreferences implementation with secure storage.
Future<SecureStorageService> getSharedPreferencesWithRetry({int maxRetries = 5, int initialDelayMs = 100}) async {
  return getSecureStorageWithRetry(maxRetries: maxRetries, initialDelayMs: initialDelayMs);
}

Future<void> initializeAsync() async {
  try {
    SecureStorageService prefs = await getSharedPreferencesWithRetry();

    if (await prefs.containsKey('token')) {
      String? userToken = await prefs.getString('token');
      String? userId = await prefs.getString('userId');

      String? name = await prefs.getString('name');
      String? profilePic = await prefs.getString('profile_pic');
      String? background = await prefs.getString('background');
      String? email = await prefs.getString('email');
      String? specialty = await prefs.getString('specialty');
      String? userType = await prefs.getString('user_type') ?? '';
      String? university = await prefs.getString('university') ?? '';
      String? countryName = await prefs.getString('country') ?? '';
      String? currency = await prefs.getString('currency') ?? '';
      if (userToken != null) {
        AppData.userToken = userToken;
        AppData.logInUserId = userId;
        AppData.name = name ?? '';
        AppData.profile_pic = profilePic ?? '';
        AppData.background = background ?? '';
        AppData.email = email ?? '';
        AppData.specialty = specialty ?? '';
        AppData.university = university;
        AppData.userType = userType;
        AppData.countryName = countryName;
        AppData.currency = currency;
      }
    }
  } catch (e) {
    debugPrint('Error in initializeAsync: $e');
    // Don't rethrow - allow app to continue even if prefs fail
  }
}
