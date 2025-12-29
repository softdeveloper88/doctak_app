import 'dart:io';
import 'package:fl_pip/fl_pip.dart';
import 'package:flutter/material.dart';

/// Service to manage Picture-in-Picture functionality for calls
class PiPService {
  static final PiPService _instance = PiPService._internal();
  factory PiPService() => _instance;
  PiPService._internal();

  bool _isPiPEnabled = false;
  bool get isPiPEnabled => _isPiPEnabled;

  /// Check if PiP is available on the current device
  Future<bool> isAvailable() async {
    try {
      return await FlPiP().isAvailable;
    } catch (e) {
      debugPrint('📺 PiP: Error checking availability: $e');
      return false;
    }
  }

  /// Enable PiP mode when app goes to background
  Future<bool> enablePiP({
    String? contactName,
    bool isVideoCall = true,
  }) async {
    try {
      final available = await isAvailable();
      if (!available) {
        debugPrint('📺 PiP: Not available on this device');
        return false;
      }

      // Enable PiP with platform-specific configurations
      // IMPORTANT: createNewEngine must be false to keep the call active
      final result = await FlPiP().enable(
        android: FlPiPAndroidConfig(
          aspectRatio: isVideoCall ? const Rational.landscape() : const Rational.square(),
          enabledWhenBackground: true,
          createNewEngine: false, // Keep false to maintain call connection
        ),
        ios: const FlPiPiOSConfig(
          enabledWhenBackground: true,
          createNewEngine: false, // Keep false to maintain call connection
          // Use the default video from fl_pip package
          videoPath: 'assets/landscape.mp4',
          audioPath: 'assets/audio.mp3',
          packageName: 'fl_pip', // Use fl_pip package assets
          enableControls: false,
          enablePlayback: false,
        ),
      );

      _isPiPEnabled = result;
      debugPrint('📺 PiP: Enabled = $result');
      return result;
    } catch (e) {
      debugPrint('📺 PiP: Error enabling: $e');
      return false;
    }
  }

  /// Disable PiP mode
  Future<bool> disablePiP() async {
    try {
      final result = await FlPiP().disable();
      _isPiPEnabled = false;
      debugPrint('📺 PiP: Disabled = $result');
      return result;
    } catch (e) {
      debugPrint('📺 PiP: Error disabling: $e');
      return false;
    }
  }

  /// Toggle app state (foreground/background)
  Future<void> toggleAppState(bool toForeground) async {
    try {
      await FlPiP().toggle(toForeground ? AppState.foreground : AppState.background);
      debugPrint('📺 PiP: Toggled to ${toForeground ? 'foreground' : 'background'}');
    } catch (e) {
      debugPrint('📺 PiP: Error toggling state: $e');
    }
  }

  /// Get current PiP status
  Future<PiPStatusInfo?> getStatus() async {
    try {
      return await FlPiP().isActive;
    } catch (e) {
      debugPrint('📺 PiP: Error getting status: $e');
      return null;
    }
  }

  /// Enable PiP automatically when going to background (Android native PiP)
  Future<bool> enableAutoPiP({bool isVideoCall = true}) async {
    if (!Platform.isAndroid) return false;
    
    try {
      final available = await isAvailable();
      if (!available) return false;

      final result = await FlPiP().enable(
        android: FlPiPAndroidConfig(
          aspectRatio: isVideoCall ? const Rational.landscape() : const Rational.square(),
          enabledWhenBackground: true,
          createNewEngine: false, // Use native PiP without new engine
        ),
        ios: const FlPiPiOSConfig(
          enabledWhenBackground: true,
          createNewEngine: false,
          // Use the default video from fl_pip package
          videoPath: 'assets/landscape.mp4',
          audioPath: 'assets/audio.mp3',
          packageName: 'fl_pip', // Use fl_pip package assets
        ),
      );

      _isPiPEnabled = result;
      debugPrint('📺 PiP: Auto-PiP enabled = $result');
      return result;
    } catch (e) {
      debugPrint('📺 PiP: Error enabling auto-PiP: $e');
      return false;
    }
  }
}
