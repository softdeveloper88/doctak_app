import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service to manage iOS screen sharing via ReplayKit Broadcast Extension
/// This handles saving/clearing channel configuration to the App Group
/// so the extension can access it when screen sharing starts.
class ScreenShareService {
  static final ScreenShareService _instance = ScreenShareService._internal();
  factory ScreenShareService() => _instance;
  ScreenShareService._internal();

  static const MethodChannel _channel = MethodChannel(
    'com.doctak.app/screen_share',
  );

  /// Save the Agora configuration to the App Group for the Broadcast Extension
  /// Call this when joining a channel before the user can start screen sharing
  Future<bool> saveChannelConfig({
    required String appId,
    required String channelName,
    String? token,
    int uid = 0,
  }) async {
    if (!Platform.isIOS) return true; // Only needed for iOS

    try {
      final result = await _channel.invokeMethod<bool>('saveChannelConfig', {
        'appId': appId,
        'channelName': channelName,
        'token': token ?? '',
        'uid': uid,
      });
      debugPrint('📺 ScreenShareService: Saved channel config: $channelName');
      return result ?? false;
    } catch (e) {
      debugPrint('📺 ScreenShareService: Error saving config: $e');
      return false;
    }
  }

  /// Clear the Agora configuration from the App Group
  /// Call this when leaving a channel
  Future<bool> clearChannelConfig() async {
    if (!Platform.isIOS) return true; // Only needed for iOS

    try {
      final result = await _channel.invokeMethod<bool>('clearChannelConfig');
      debugPrint('📺 ScreenShareService: Cleared channel config');
      return result ?? false;
    } catch (e) {
      debugPrint('📺 ScreenShareService: Error clearing config: $e');
      return false;
    }
  }

  /// Start the ReplayKit broadcast picker (iOS 12+)
  /// This shows the system UI for selecting the screen sharing extension
  Future<bool> startBroadcast() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('startBroadcast');
      debugPrint('📺 ScreenShareService: Start broadcast result: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('📺 ScreenShareService: Error starting broadcast: $e');
      return false;
    }
  }

  /// Stop the current broadcast
  Future<bool> stopBroadcast() async {
    if (!Platform.isIOS) return true;

    try {
      final result = await _channel.invokeMethod<bool>('stopBroadcast');
      debugPrint('📺 ScreenShareService: Stop broadcast result: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('📺 ScreenShareService: Error stopping broadcast: $e');
      return false;
    }
  }

  /// Check if broadcast is currently active
  Future<bool> isBroadcasting() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isBroadcasting');
      return result ?? false;
    } catch (e) {
      debugPrint('📺 ScreenShareService: Error checking broadcast status: $e');
      return false;
    }
  }
}
