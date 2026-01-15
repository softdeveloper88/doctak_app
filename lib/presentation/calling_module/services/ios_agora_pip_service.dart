import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// iOS-specific PiP service for Agora video calls using native AVPictureInPictureController
/// This provides reliable PiP for live video content on iOS 15+
class IOSAgoraPiPService {
  static final IOSAgoraPiPService _instance = IOSAgoraPiPService._internal();
  factory IOSAgoraPiPService() => _instance;
  IOSAgoraPiPService._internal();

  static const MethodChannel _channel = MethodChannel('com.doctak.app/agora_pip');

  bool _isSetup = false;
  bool _isActive = false;
  bool _isRestoringUI = false; // Tracks if user is returning to app

  final StreamController<PiPState> _stateController = StreamController<PiPState>.broadcast();

  /// Stream of PiP state changes
  Stream<PiPState> get stateStream => _stateController.stream;

  /// Check if PiP is currently active
  bool get isActive => _isActive;

  /// Check if user is returning to app from PiP
  bool get isRestoringUI => _isRestoringUI;

  /// Initialize the service and set up method channel handler
  Future<void> initialize() async {
    if (!Platform.isIOS) return;

    // Set up method channel handler for callbacks from native
    _channel.setMethodCallHandler(_handleMethodCall);
    debugPrint('📺 IOSAgoraPiP: Initialized');
  }

  /// Handle method calls from native iOS
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPiPStateChanged':
        final Map<dynamic, dynamic> args = call.arguments;
        final String state = args['state'] ?? 'unknown';
        _handleStateChange(state);
        break;
    }
  }

  /// Process state changes from native
  void _handleStateChange(String state) {
    debugPrint('📺 IOSAgoraPiP: State changed to $state');

    PiPState pipState;
    switch (state) {
      case 'started':
        _isActive = true;
        _isRestoringUI = false;
        pipState = PiPState.started;
        break;
      case 'stopped':
        _isActive = false;
        pipState = PiPState.stopped;
        break;
      case 'willStart':
        _isRestoringUI = false;
        pipState = PiPState.willStart;
        break;
      case 'willStop':
        pipState = PiPState.willStop;
        break;
      case 'failed':
        _isActive = false;
        _isRestoringUI = false;
        pipState = PiPState.failed;
        break;
      case 'restoreUI':
        _isActive = false;
        _isRestoringUI = true; // Mark that we're restoring UI
        pipState = PiPState.restoreUI;
        break;
      default:
        pipState = PiPState.unknown;
    }

    _stateController.add(pipState);
  }

  /// Check if PiP is supported on this device
  Future<bool> isSupported() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      debugPrint('📺 IOSAgoraPiP: isSupported = $result');
      return result ?? false;
    } catch (e) {
      debugPrint('📺 IOSAgoraPiP: Error checking support: $e');
      return false;
    }
  }

  /// Enable or disable auto-PiP mode
  Future<bool> setAutoEnabled(bool enabled) async {
    if (!Platform.isIOS) return false;

    try {
      await _channel.invokeMethod('setAutoEnabled', {'enabled': enabled});
      debugPrint('📺 IOSAgoraPiP: setAutoEnabled = $enabled');
      return true;
    } catch (e) {
      debugPrint('📺 IOSAgoraPiP: Error setting auto enabled: $e');
      return false;
    }
  }

  /// Set up PiP controller (must call before start)
  Future<bool> setup() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('setup');
      _isSetup = result ?? false;
      debugPrint('📺 IOSAgoraPiP: setup = $_isSetup');
      return _isSetup;
    } catch (e) {
      debugPrint('📺 IOSAgoraPiP: Error setting up: $e');
      return false;
    }
  }

  /// Start PiP mode
  Future<bool> start() async {
    if (!Platform.isIOS) return false;

    // Don't start if we're restoring UI (user returning to app)
    if (_isRestoringUI) {
      debugPrint('📺 IOSAgoraPiP: Skipping start - UI is being restored');
      return false;
    }

    if (!_isSetup) {
      await setup();
    }

    try {
      final result = await _channel.invokeMethod<bool>('start');
      debugPrint('📺 IOSAgoraPiP: start = $result');
      return result ?? false;
    } catch (e) {
      debugPrint('📺 IOSAgoraPiP: Error starting: $e');
      return false;
    }
  }

  /// Stop PiP mode
  Future<bool> stop() async {
    if (!Platform.isIOS) return false;

    // Reset restoration flag on explicit stop
    _isRestoringUI = false;

    try {
      final result = await _channel.invokeMethod<bool>('stop');
      debugPrint('📺 IOSAgoraPiP: stop = $result');
      return result ?? false;
    } catch (e) {
      debugPrint('📺 IOSAgoraPiP: Error stopping: $e');
      return false;
    }
  }

  /// Cancel any pending PiP operations
  /// Call this immediately when app resumes to prevent delayed PiP start
  Future<void> cancelPending() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod<bool>('cancelPending');
      debugPrint('📺 IOSAgoraPiP: cancelPending called');
    } catch (e) {
      debugPrint('📺 IOSAgoraPiP: Error cancelling pending: $e');
    }
  }

  /// Check if PiP is currently active
  Future<bool> checkIsActive() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isActive');
      _isActive = result ?? false;
      return _isActive;
    } catch (e) {
      debugPrint('📺 IOSAgoraPiP: Error checking active state: $e');
      return false;
    }
  }

  /// Reset the UI restoration flag - call this when user has been in the app
  /// for a while and PiP should be allowed to start again on next background
  void resetRestorationFlag() {
    _isRestoringUI = false;
    debugPrint('📺 IOSAgoraPiP: Restoration flag reset');
  }

  /// Update PiP with a Flutter widget frame capture
  /// Call this periodically (e.g., every 100ms) when PiP is active to show live widget content
  Future<void> updateFrame(Uint8List imageData, int width, int height) async {
    if (!Platform.isIOS) return;
    if (!_isActive) return;

    try {
      await _channel.invokeMethod('updateFrame', {'imageData': imageData, 'width': width, 'height': height});
    } catch (e) {
      // Don't spam logs for frame updates
    }
  }

  /// Dispose and clean up resources
  Future<void> dispose() async {
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod<bool>('dispose');
      _isSetup = false;
      _isActive = false;
      debugPrint('📺 IOSAgoraPiP: Disposed');
    } catch (e) {
      debugPrint('�SAgoraPiP: Error disposing: $e');
    }
  }

  /// Clean up stream controller
  void closeStream() {
    _stateController.close();
  }
}

/// PiP state enum
enum PiPState { willStart, started, willStop, stopped, failed, restoreUI, unknown }
