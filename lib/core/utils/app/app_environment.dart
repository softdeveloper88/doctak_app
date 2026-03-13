import 'package:flutter/foundation.dart';

/// App Environment Configuration
/// 
/// By default, **both debug and release** modes use the **production server** (doctak.net).
/// To use a local development server, explicitly pass:
/// ```bash
/// # Android emulator (uses 10.0.2.2 by default):
/// flutter run --dart-define=ENV=development
/// 
/// # iOS simulator or real device:
/// flutter run --dart-define=ENV=development --dart-define=LOCAL_IP=127.0.0.1
/// 
/// # Real device on same network:
/// flutter run --dart-define=ENV=development --dart-define=LOCAL_IP=192.168.x.x
/// ```
class AppEnvironment {
  AppEnvironment._();

  /// Override via --dart-define=ENV=production or --dart-define=ENV=development
  static const String _envOverride = String.fromEnvironment('ENV', defaultValue: '');

  /// Whether the app is running in production mode.
  /// Defaults to true (production) unless ENV=development is explicitly set.
  static bool get isProduction {
    return _envOverride != 'development';
  }

  /// Whether the app is running in development mode
  static bool get isDevelopment => !isProduction;

  // ===================== Production URLs =====================
  static const String _prodBase = 'https://doctak.net/';
  static const String _prodBase2 = 'https://doctak.net';
  static const String _prodBasePath = 'https://doctak.net/public/';
  static const String _prodApiUrl = 'https://doctak.net/api/v4';
  static const String _prodApiUrlV6 = 'https://doctak.net/api/v6';
  static const String _prodUserProfileUrl = 'https://doctak.net/';
  static const String _prodChatifyUrl = 'https://doctak.net/chatify/api/';
  static const String _prodChatApiUrl = 'https://doctak.net/api/v6/chat';
  static const String _prodImageUrl = 'https://doctak-file.s3.ap-south-1.amazonaws.com/';

  // ===================== Development URLs =====================
  /// Override local IP via --dart-define=LOCAL_IP=192.168.x.x
  /// NOTE: 127.0.0.1 only works on desktop/web. For Android emulator use 10.0.2.2,
  /// for real devices use your machine's local IP (e.g. 192.168.x.x).
  static const String _localIp = String.fromEnvironment('LOCAL_IP', defaultValue: '10.0.2.2');
  static const String _localPort = String.fromEnvironment('LOCAL_PORT', defaultValue: '8000');

  static String get _devBase => 'http://$_localIp:$_localPort/';
  static String get _devBase2 => 'http://$_localIp:$_localPort';
  static String get _devBasePath => 'http://$_localIp:$_localPort/public/';
  static String get _devApiUrl => 'http://$_localIp:$_localPort/api/v4';
  static String get _devApiUrlV6 => 'http://$_localIp:$_localPort/api/v6';
  static String get _devUserProfileUrl => 'http://$_localIp:$_localPort/';
  static String get _devChatifyUrl => 'http://$_localIp:$_localPort/chatify/api/';
  static String get _devChatApiUrl => 'http://$_localIp:$_localPort/api/v6/chat';
  // In dev, still use S3 for images (they are stored on S3 regardless)
  static const String _devImageUrl = 'https://doctak-file.s3.ap-south-1.amazonaws.com/';

  // ===================== Active URLs =====================
  static String get base => isProduction ? _prodBase : _devBase;
  static String get base2 => isProduction ? _prodBase2 : _devBase2;
  static String get basePath => isProduction ? _prodBasePath : _devBasePath;
  static String get apiUrl => isProduction ? _prodApiUrl : _devApiUrl;
  static String get apiUrlV6 => isProduction ? _prodApiUrlV6 : _devApiUrlV6;
  static String get userProfileUrl => isProduction ? _prodUserProfileUrl : _devUserProfileUrl;
  static String get chatifyUrl => isProduction ? _prodChatifyUrl : _devChatifyUrl;
  static String get chatApiUrl => isProduction ? _prodChatApiUrl : _devChatApiUrl;
  static String get imageUrl => isProduction ? _prodImageUrl : _devImageUrl;

  /// Get current environment name for logging
  static String get environmentName => isProduction ? 'PRODUCTION' : 'DEVELOPMENT';

  /// Print current environment info (for debugging)
  static void printEnvironmentInfo() {
    debugPrint('╔══════════════════════════════════════════════════');
    debugPrint('║ App Environment: $environmentName');
    debugPrint('║ API URL: $apiUrl');
    debugPrint('║ Base URL: $base');
    debugPrint('║ Image URL: $imageUrl');
    debugPrint('║ kReleaseMode: $kReleaseMode');
    debugPrint('║ ENV override: ${_envOverride.isEmpty ? "none" : _envOverride}');
    debugPrint('╚══════════════════════════════════════════════════');
  }
}
