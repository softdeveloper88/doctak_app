// lib/presentation/call_module/utils/constants.dart

/// Constants used throughout the application
class AppConstants {
  // Agora configuration
  static const String agoraAppId = "f2cf99f1193a40e69546157883b2159f";

  // Call configuration
  static const int callReconnectionAttempts = 5;
  static const int callReconnectionDelaySeconds = 2;
  static const int controlsAutoHideSeconds = 5;
  static const int connectionWatchdogIntervalSeconds = 10;
  static const int connectionTimeoutSeconds = 20;

  // Audio settings
  static const int audioVolumeIndicationInterval = 500; // milliseconds
  static const int audioVolumeIndicationSmoothing = 3;
  static const int audioSpeakingThreshold = 50; // Volume level considered as speaking
  static const int audioSpeakingResetDelay = 800; // milliseconds

  // Video settings - Standard quality
  static const int videoWidthStandard = 640;
  static const int videoHeightStandard = 480;
  static const int videoFrameRateStandard = 15;
  static const int videoBitrateStandard = 1000;

  // Video settings - Medium quality (for medium networks)
  static const int videoWidthMedium = 480;
  static const int videoHeightMedium = 360;
  static const int videoFrameRateMedium = 15;
  static const int videoBitrateMedium = 800;

  // Video settings - Low quality (for poor networks)
  static const int videoWidthLow = 320;
  static const int videoHeightLow = 240;
  static const int videoFrameRateLow = 15;
  static const int videoBitrateLow = 400;

  // Video settings - Very low quality (for reconnection)
  static const int videoWidthVeryLow = 160;
  static const int videoHeightVeryLow = 120;
  static const int videoFrameRateVeryLow = 10;
  static const int videoBitrateVeryLow = 100;
}
