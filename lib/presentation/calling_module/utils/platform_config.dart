// lib/presentation/calling_module/utils/platform_config.dart
import 'dart:io';

/// Platform-specific configuration for the calling module
class PlatformConfig {
  static final PlatformConfig _instance = PlatformConfig._internal();
  factory PlatformConfig() => _instance;
  PlatformConfig._internal();

  /// Check if running on iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if running on Android
  static bool get isAndroid => Platform.isAndroid;

  /// Get platform name
  static String get platformName => Platform.operatingSystem;

  /// Platform-specific video encoder settings
  static Map<String, dynamic> getVideoEncoderConfig({required bool isVideoCall, required bool isHighQuality}) {
    if (isIOS) {
      return {
        'width': isHighQuality ? 640 : 320,
        'height': isHighQuality ? 480 : 240,
        'frameRate': isHighQuality ? 15 : 10,
        'bitrate': isHighQuality ? 900 : 400,
        'minBitrate': isHighQuality ? 500 : 200,
        'degradationPreference': 'maintainQuality', // iOS handles quality better
      };
    } else {
      return {
        'width': isHighQuality ? 640 : 320,
        'height': isHighQuality ? 480 : 240,
        'frameRate': isHighQuality ? 15 : 12,
        'bitrate': isHighQuality ? 800 : 350,
        'minBitrate': isHighQuality ? 400 : 150,
        'degradationPreference': 'maintainFramerate', // Android prefers framerate
      };
    }
  }

  /// Platform-specific audio settings
  static Map<String, dynamic> getAudioConfig() {
    if (isIOS) {
      return {
        'profile': 'audioProfileMusicHighQuality',
        'scenario': 'audioScenarioGameStreaming', // Better for iOS
        'aec': true,
        'ns': true,
        'agc': true,
      };
    } else {
      return {'profile': 'audioProfileMusicHighQuality', 'scenario': 'audioScenarioDefault', 'aec': true, 'ns': true, 'agc': true};
    }
  }

  /// Platform-specific connection timeouts
  static Map<String, int> getConnectionTimeouts() {
    if (isIOS) {
      return {
        'connectionTimeout': 30000, // 30 seconds
        'heartbeatInterval': 5000, // 5 seconds
        'reconnectDelay': 2000, // 2 seconds
        'maxReconnectAttempts': 5,
      };
    } else {
      return {
        'connectionTimeout': 25000, // 25 seconds
        'heartbeatInterval': 4000, // 4 seconds
        'reconnectDelay': 1500, // 1.5 seconds
        'maxReconnectAttempts': 6,
      };
    }
  }

  /// Platform-specific video parameters
  static Map<String, String> getVideoParameters() {
    if (isIOS) {
      return {
        'h264Profile': '77', // Main profile for iOS
        'preferFrameRate': 'false',
        'contentHint': 'motion',
        'enablePreEncode': 'true', // iOS hardware acceleration
        'captureMode': '1', // Auto capture mode
      };
    } else {
      return {
        'h264Profile': '66', // Baseline profile for Android compatibility
        'preferFrameRate': 'true', // Android prefers framerate
        'contentHint': 'motion',
        'enablePreEncode': 'false',
        'captureMode': '0', // Default capture mode
      };
    }
  }

  /// Platform-specific audio parameters
  static Map<String, dynamic> getAudioParameters() {
    if (isIOS) {
      return {
        'keepAudioSession': true,
        'audioSessionCategory': 'AVAudioSessionCategoryPlayAndRecord',
        'audioSessionMode': 'AVAudioSessionModeVideoChat',
        'forceAudioRoute': -1, // Auto routing
      };
    } else {
      return {
        'keepAudioSession': false,
        'audioSessionCategory': 'default',
        'audioSessionMode': 'default',
        'forceAudioRoute': -1, // Auto routing
      };
    }
  }

  /// Platform-specific background handling
  static Map<String, bool> getBackgroundConfig() {
    if (isIOS) {
      return {'pauseVideoInBackground': true, 'keepAudioInBackground': true, 'restartPreviewOnForeground': true, 'delayForegroundCheck': true};
    } else {
      return {'pauseVideoInBackground': true, 'keepAudioInBackground': false, 'restartPreviewOnForeground': false, 'delayForegroundCheck': false};
    }
  }

  /// Platform-specific network quality thresholds
  static Map<String, int> getNetworkQualityThresholds() {
    if (isIOS) {
      return {
        'excellentThreshold': 1,
        'goodThreshold': 2,
        'fairThreshold': 3,
        'poorThreshold': 4,
        'badThreshold': 5,
        'adaptiveQualityThreshold': 3, // Start reducing quality at fair
      };
    } else {
      return {
        'excellentThreshold': 1,
        'goodThreshold': 2,
        'fairThreshold': 3,
        'poorThreshold': 4,
        'badThreshold': 5,
        'adaptiveQualityThreshold': 4, // Start reducing quality at poor for Android
      };
    }
  }

  /// Platform-specific camera settings
  static Map<String, dynamic> getCameraConfig() {
    if (isIOS) {
      return {'defaultDirection': 'front', 'switchWithPreviewRestart': true, 'autoFocus': true, 'exposureCompensation': 0};
    } else {
      return {'defaultDirection': 'front', 'switchWithPreviewRestart': false, 'autoFocus': true, 'exposureCompensation': 0};
    }
  }

  /// Get recommended call settings based on device capabilities
  static Map<String, dynamic> getRecommendedCallSettings() {
    if (isIOS) {
      return {'preferredCodec': 'H264', 'enableHardwareAcceleration': true, 'enableAdaptiveBitrate': true, 'enableDualStream': true, 'maxVideoBitrate': 1200, 'maxAudioBitrate': 128};
    } else {
      return {
        'preferredCodec': 'H264',
        'enableHardwareAcceleration': false, // More conservative for Android
        'enableAdaptiveBitrate': true,
        'enableDualStream': true,
        'maxVideoBitrate': 1000,
        'maxAudioBitrate': 96,
      };
    }
  }

  /// Platform-specific debug settings
  static Map<String, bool> getDebugConfig() {
    return {
      'enableVerboseLogging': isIOS, // More verbose on iOS for debugging
      'logNetworkStats': true,
      'logVideoStats': true,
      'logAudioStats': true,
      'enablePerformanceMonitoring': true,
    };
  }

  /// Get platform-specific error recovery settings
  static Map<String, dynamic> getErrorRecoveryConfig() {
    if (isIOS) {
      return {'autoReconnect': true, 'reconnectBackoffMultiplier': 1.5, 'maxReconnectDelay': 10000, 'enableFallbackToAudio': true, 'cameraErrorRecoveryDelay': 500};
    } else {
      return {'autoReconnect': true, 'reconnectBackoffMultiplier': 2.0, 'maxReconnectDelay': 8000, 'enableFallbackToAudio': true, 'cameraErrorRecoveryDelay': 200};
    }
  }
}
