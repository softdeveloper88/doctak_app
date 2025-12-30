import 'dart:io';
import 'package:doctak_app/core/utils/system_permission_handler.dart';
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

  /// Check and request overlay permission if needed (Android only)
  Future<bool> checkOverlayPermission(BuildContext? context) async {
    if (!Platform.isAndroid) return true;

    final hasPermission = await systemPermissionHandler.hasOverlayPermission();

    if (!hasPermission && context != null && context.mounted) {
      debugPrint('📺 PiP: Overlay permission not granted, requesting...');
      return await systemPermissionHandler.requestOverlayPermission(context);
    }

    return hasPermission;
  }

  /// Enable PiP mode when app goes to background
  /// [context] is optional but recommended to show permission dialog if needed
  ///
  /// Uses createNewEngine: true to show a custom floating widget (pipMain)
  /// instead of the full app view. This creates a proper small floating window.
  Future<bool> enablePiP({
    String? contactName,
    bool isVideoCall = true,
    BuildContext? context,
  }) async {
    try {
      final available = await isAvailable();
      if (!available) {
        debugPrint('📺 PiP: Not available on this device');
        return false;
      }

      // Check overlay permission on Android
      if (Platform.isAndroid) {
        final hasOverlay = await checkOverlayPermission(context);
        if (!hasOverlay) {
          debugPrint('📺 PiP: Overlay permission denied, cannot enable PiP');
          return false;
        }
      }

      // Enable PiP with platform-specific configurations
      // createNewEngine: true - Creates a new Flutter engine with pipMain()
      // This shows the custom PiPCallWidget as a floating window
      final result = await FlPiP().enable(
        android: FlPiPAndroidConfig(
          // Use smaller aspect ratio for floating window
          aspectRatio: const Rational(16, 9),
          enabledWhenBackground: true,
          // CRITICAL: Set to true to use the pipMain() entry point
          // This creates a proper floating PiP window instead of showing the full app
          createNewEngine: true,
        ),
        ios: const FlPiPiOSConfig(
          enabledWhenBackground: true,
          createNewEngine: true, // Use pipMain() for iOS too
          // Use the default video from fl_pip package
          videoPath: 'assets/landscape.mp4',
          audioPath: 'assets/audio.mp3',
          packageName: 'fl_pip', // Use fl_pip package assets
          enableControls: false,
          enablePlayback: false,
        ),
      );

      _isPiPEnabled = result;
      debugPrint('📺 PiP: Enabled with new engine = $result');
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
      await FlPiP().toggle(
        toForeground ? AppState.foreground : AppState.background,
      );
      debugPrint(
        '📺 PiP: Toggled to ${toForeground ? 'foreground' : 'background'}',
      );
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
  /// Uses createNewEngine: true for proper floating window behavior
  /// [context] is optional but recommended to show permission dialog if needed
  Future<bool> enableAutoPiP({
    bool isVideoCall = true,
    BuildContext? context,
  }) async {
    if (!Platform.isAndroid) return false;

    try {
      final available = await isAvailable();
      if (!available) return false;

      // Check overlay permission on Android
      final hasOverlay = await checkOverlayPermission(context);
      if (!hasOverlay) {
        debugPrint('📺 PiP: Overlay permission denied, cannot enable auto-PiP');
        return false;
      }

      // Use createNewEngine: true to show the pipMain() widget
      // This creates a proper floating PiP window instead of showing the full app
      final result = await FlPiP().enable(
        android: FlPiPAndroidConfig(
          // Use 16:9 aspect ratio for a proper floating window size
          aspectRatio: const Rational(16, 9),
          enabledWhenBackground: true,
          // CRITICAL: Set to true for proper floating window
          createNewEngine: true,
        ),
        ios: const FlPiPiOSConfig(
          enabledWhenBackground: true,
          createNewEngine: true,
          // Use the default video from fl_pip package
          videoPath: 'assets/landscape.mp4',
          audioPath: 'assets/audio.mp3',
          packageName: 'fl_pip', // Use fl_pip package assets
        ),
      );

      _isPiPEnabled = result;
      debugPrint('📺 PiP: Auto-PiP enabled with new engine = $result');
      return result;
    } catch (e) {
      debugPrint('📺 PiP: Error enabling auto-PiP: $e');
      return false;
    }
  }
}
