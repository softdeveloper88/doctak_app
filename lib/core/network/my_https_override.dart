import 'dart:io';

class MyHttpsOverrides extends HttpOverrides {
  static bool _isInitialized = false;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    if (!_isInitialized) {
      _isInitialized = true;
      // Use print instead of debugPrint as debugPrint may be stripped in release
      print('🌐 MyHttpsOverrides: Creating HTTP client with certificate bypass');
    }

    final client = super.createHttpClient(context);

    // Accept all certificates (for development/testing)
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      print('🔐 MyHttpsOverrides: Certificate check for $host:$port - BYPASSED');
      return true;
    };

    // Enhanced timeout configuration for S3 compatibility
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 30);

    // Increase connection pool for multiple S3 requests
    client.maxConnectionsPerHost = 15;

    // Add user agent for better S3 compatibility
    client.userAgent = 'DocTak-Mobile-App/1.0 (Flutter; iOS/Android)';

    // Enable automatic redirection
    client.autoUncompress = true;

    return client;
  }
}
