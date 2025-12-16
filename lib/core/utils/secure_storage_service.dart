import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service class that wraps FlutterSecureStorage to provide
/// a similar interface to SharedPreferences for easier migration.
///
/// This provides encrypted storage for sensitive data like tokens,
/// user credentials, and other personal information.
class SecureStorageService {
  static SecureStorageService? _instance;
  late FlutterSecureStorage _storage;

  // Cache for frequently accessed values
  final Map<String, String?> _cache = {};
  bool _isInitialized = false;

  SecureStorageService._internal() {
    // Configure Android options for better security and compatibility
    AndroidOptions androidOptions = const AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    );

    // Configure iOS options
    IOSOptions iosOptions = const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    );

    _storage = FlutterSecureStorage(
      aOptions: androidOptions,
      iOptions: iosOptions,
    );
  }

  /// Get the singleton instance of SecureStorageService
  static SecureStorageService get instance {
    _instance ??= SecureStorageService._internal();
    return _instance!;
  }

  /// Get the FlutterSecureStorage instance directly if needed
  FlutterSecureStorage get storage => _storage;

  /// Initialize the storage and optionally preload cache
  Future<void> initialize({bool preloadCache = true}) async {
    if (_isInitialized) return;

    try {
      if (preloadCache) {
        // Preload commonly used keys into cache
        final allValues = await _storage.readAll();
        _cache.addAll(allValues);
      }
      _isInitialized = true;
      debugPrint('SecureStorageService initialized successfully');
    } catch (e) {
      debugPrint('SecureStorageService initialization error: $e');

      // If we get a bad base-64 error, storage is corrupted
      // We need to recreate the storage instance with different options
      // to force a clean slate
      if (e.toString().contains('bad base-64') ||
          e.toString().contains('Exception encountered')) {
        debugPrint('Detected corrupted storage, recreating with resetOnError');

        try {
          // Recreate storage instance with resetOnError to force cleanup
          AndroidOptions androidOptions = const AndroidOptions(
            encryptedSharedPreferences: true,
            resetOnError: true, // This will delete corrupted data
          );

          IOSOptions iosOptions = const IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          );

          _storage = FlutterSecureStorage(
            aOptions: androidOptions,
            iOptions: iosOptions,
          );

          // Try one more simple operation to trigger reset
          await _storage.write(key: '_init_test', value: 'ok');
          await _storage.delete(key: '_init_test');

          _isInitialized = true;
          debugPrint('SecureStorageService recovered from corruption');
        } catch (e3) {
          debugPrint('SecureStorageService recovery failed: $e3');
          // Mark as initialized anyway to prevent infinite loops
          _isInitialized = true;
        }
      } else {
        // For other errors, just mark as initialized to avoid infinite loops
        _isInitialized = true;
      }
    }
  }

  /// Read a string value
  Future<String?> getString(String key) async {
    try {
      // Check cache first
      if (_cache.containsKey(key)) {
        return _cache[key];
      }

      final value = await _storage.read(key: key);
      _cache[key] = value;
      return value;
    } catch (e) {
      debugPrint('SecureStorage getString error for $key: $e');
      return null;
    }
  }

  /// Write a string value
  Future<bool> setString(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      _cache[key] = value;
      return true;
    } catch (e) {
      debugPrint('SecureStorage setString error for $key: $e');
      return false;
    }
  }

  /// Read a boolean value (stored as string "true" or "false")
  Future<bool?> getBool(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  /// Write a boolean value
  Future<bool> setBool(String key, bool value) async {
    return setString(key, value.toString());
  }

  /// Read an integer value
  Future<int?> getInt(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Write an integer value
  Future<bool> setInt(String key, int value) async {
    return setString(key, value.toString());
  }

  /// Read a double value
  Future<double?> getDouble(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return double.tryParse(value);
  }

  /// Write a double value
  Future<bool> setDouble(String key, double value) async {
    return setString(key, value.toString());
  }

  /// Read a string list value (stored as JSON-encoded string)
  Future<List<String>?> getStringList(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    try {
      // Stored as comma-separated string with custom delimiter to avoid conflicts
      return value.split('|||');
    } catch (e) {
      debugPrint('SecureStorage getStringList error for $key: $e');
      return null;
    }
  }

  /// Write a string list value
  Future<bool> setStringList(String key, List<String> value) async {
    try {
      // Store as comma-separated string with custom delimiter
      final encoded = value.join('|||');
      return setString(key, encoded);
    } catch (e) {
      debugPrint('SecureStorage setStringList error for $key: $e');
      return false;
    }
  }

  /// Check if a key exists
  Future<bool> containsKey(String key) async {
    try {
      if (_cache.containsKey(key)) {
        return _cache[key] != null;
      }
      final value = await _storage.read(key: key);
      _cache[key] = value;
      return value != null;
    } catch (e) {
      debugPrint('SecureStorage containsKey error for $key: $e');
      return false;
    }
  }

  /// Remove a key
  Future<bool> remove(String key) async {
    try {
      await _storage.delete(key: key);
      _cache.remove(key);
      return true;
    } catch (e) {
      debugPrint('SecureStorage remove error for $key: $e');
      return false;
    }
  }

  /// Clear all stored data
  Future<bool> clear() async {
    try {
      await _storage.deleteAll();
      _cache.clear();
      return true;
    } catch (e) {
      debugPrint('SecureStorage clear error: $e');
      return false;
    }
  }

  /// Get all stored keys and values
  Future<Map<String, String>> getAll() async {
    try {
      final allValues = await _storage.readAll();
      _cache.addAll(allValues);
      return allValues;
    } catch (e) {
      debugPrint('SecureStorage getAll error: $e');
      return {};
    }
  }

  /// Clear the in-memory cache
  void clearCache() {
    _cache.clear();
  }

  /// Reload cache from storage
  Future<void> reloadCache() async {
    _cache.clear();
    await getAll();
  }
}

/// Global function to get SecureStorageService instance with retry mechanism
/// This provides a similar interface to the old getSharedPreferencesWithRetry
Future<SecureStorageService> getSecureStorageWithRetry({
  int maxRetries = 3, // Reduced from 5 to prevent infinite loops
  int initialDelayMs = 100,
}) async {
  final storage = SecureStorageService.instance;

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      await storage.initialize();
      if (attempt > 1) {
        debugPrint('SecureStorage succeeded on attempt $attempt');
      }
      return storage;
    } catch (e) {
      debugPrint('SecureStorage attempt $attempt/$maxRetries failed: $e');

      // Don't retry on corruption errors - the initialize method handles them
      if (e.toString().contains('bad base-64') ||
          e.toString().contains('Exception encountered')) {
        debugPrint(
            'Storage corruption detected, initialize() will handle recovery');
        return storage; // Return even if initialization had issues
      }

      if (attempt < maxRetries) {
        // Exponential backoff: 100ms, 200ms, 400ms
        final delay = initialDelayMs * (1 << (attempt - 1));
        debugPrint('Retrying SecureStorage in ${delay}ms...');
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
  }

  // All retries exhausted - return storage anyway to prevent app crash
  debugPrint(
      'SecureStorage failed after $maxRetries attempts, returning instance anyway');
  return storage;
}
