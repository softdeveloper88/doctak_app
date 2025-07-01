import 'dart:io';

class MyHttpsOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    // Accept all certificates (for development/testing)
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    
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
