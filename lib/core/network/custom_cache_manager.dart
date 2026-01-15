import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/io_client.dart';

/// Creates an HttpClient that accepts all certificates
HttpClient _createHttpClient() {
  debugPrint('🔧 CustomCacheManager: Creating HTTP client for image loading');
  final httpClient = HttpClient();
  // Accept all certificates (matches MyHttpsOverrides behavior)
  httpClient.badCertificateCallback = (cert, host, port) {
    debugPrint('🔐 CustomCacheManager: Certificate check for $host:$port - BYPASSED');
    return true;
  };
  httpClient.connectionTimeout = const Duration(seconds: 30);
  httpClient.idleTimeout = const Duration(seconds: 60);
  httpClient.maxConnectionsPerHost = 15;
  httpClient.autoUncompress = true;
  debugPrint('🔧 CustomCacheManager: HTTP client created successfully');
  return httpClient;
}

/// Custom HTTP client that bypasses certificate validation for release mode
/// Uses IOClient which properly wraps dart:io HttpClient for the http package
class CustomHttpClient extends IOClient {
  CustomHttpClient() : super(_createHttpClient());
}

/// Custom cache manager that uses our HTTP client with certificate bypass
class CustomCacheManager extends CacheManager {
  static const key = 'doctakImageCache';

  static CustomCacheManager? _instance;

  factory CustomCacheManager() {
    _instance ??= CustomCacheManager._();
    return _instance!;
  }

  CustomCacheManager._()
    : super(
        Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 200,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(httpClient: CustomHttpClient()),
        ),
      );

  /// Clear the singleton instance (useful for testing)
  static void reset() {
    _instance = null;
  }
}
