import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoUtils {
  // Maximum supported resolution to prevent codec issues
  static const int MAX_SUPPORTED_WIDTH = 1920;
  static const int MAX_SUPPORTED_HEIGHT = 1080;
  
  // Common video resolutions
  static const Size RESOLUTION_4K = Size(3840, 2160);
  static const Size RESOLUTION_1440P = Size(2560, 1440);
  static const Size RESOLUTION_1080P = Size(1920, 1080);
  static const Size RESOLUTION_720P = Size(1280, 720);
  static const Size RESOLUTION_480P = Size(854, 480);
  
  /// Check if video resolution is supported by the device
  static bool isResolutionSupported(Size videoSize) {
    return videoSize.width <= MAX_SUPPORTED_WIDTH && 
           videoSize.height <= MAX_SUPPORTED_HEIGHT;
  }
  
  /// Get video quality level based on resolution
  static String getVideoQuality(Size videoSize) {
    if (videoSize.width >= RESOLUTION_4K.width) {
      return '4K';
    } else if (videoSize.width >= RESOLUTION_1440P.width) {
      return '1440p';
    } else if (videoSize.width >= RESOLUTION_1080P.width) {
      return '1080p';
    } else if (videoSize.width >= RESOLUTION_720P.width) {
      return '720p';
    } else if (videoSize.width >= RESOLUTION_480P.width) {
      return '480p';
    } else {
      return 'Low';
    }
  }
  
  /// Check if video is high resolution (potentially problematic)
  static bool isHighResolution(Size videoSize) {
    return videoSize.width >= RESOLUTION_1440P.width || 
           videoSize.height >= RESOLUTION_1440P.height;
  }
  
  /// Get user-friendly error message based on exception
  static String getVideoErrorMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('exceeds_capabilities') || 
        errorStr.contains('no_exceeds_capabilities')) {
      return 'Video quality too high for this device. Try a lower resolution video.';
    } else if (errorStr.contains('decoder_init_failed') || 
               errorStr.contains('mediacodecrenderer')) {
      return 'Video codec not supported on this device.';
    } else if (errorStr.contains('network') || 
               errorStr.contains('connection') || 
               errorStr.contains('timeout')) {
      return 'Network error. Please check your internet connection.';
    } else if (errorStr.contains('format') || 
               errorStr.contains('unsupported')) {
      return 'Video format not supported.';
    } else if (errorStr.contains('source') || 
               errorStr.contains('not found') || 
               errorStr.contains('404')) {
      return 'Video not found or unavailable.';
    } else if (errorStr.contains('permission') || 
               errorStr.contains('access')) {
      return 'Cannot access video file.';
    } else {
      return 'Unable to play video. Please try again.';
    }
  }
  
  /// Check if error is related to codec/resolution issues
  static bool isCodecError(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    return errorStr.contains('exceeds_capabilities') ||
           errorStr.contains('decoder') ||
           errorStr.contains('mediacodec') ||
           errorStr.contains('codec');
  }
  
  /// Get recommended video settings for device
  static Map<String, dynamic> getRecommendedVideoSettings() {
    return {
      'maxWidth': MAX_SUPPORTED_WIDTH,
      'maxHeight': MAX_SUPPORTED_HEIGHT,
      'preferredFormat': 'mp4',
      'preferredCodec': 'h264',
    };
  }
  
  /// Log video information for debugging
  static void logVideoInfo(VideoPlayerValue value, String context) {
    debugPrint('=== Video Info ($context) ===');
    debugPrint('Resolution: ${value.size.width}x${value.size.height}');
    debugPrint('Duration: ${value.duration}');
    debugPrint('Quality: ${getVideoQuality(value.size)}');
    debugPrint('High Resolution: ${isHighResolution(value.size)}');
    debugPrint('Supported: ${isResolutionSupported(value.size)}');
    debugPrint('========================');
  }
}