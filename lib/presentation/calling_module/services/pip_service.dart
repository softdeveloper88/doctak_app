import 'dart:async';
import 'dart:io';
import 'package:doctak_app/core/utils/system_permission_handler.dart';
import 'package:doctak_app/presentation/calling_module/services/ios_agora_pip_service.dart';
// fl_pip removed - causes iOS crash due to AppDelegate type mismatch
// import 'package:fl_pip/fl_pip.dart';
import 'package:pip/pip.dart' as pip_pkg;
import 'package:flutter/material.dart';

/// Custom PiP status enum to avoid dependency on fl_pip
enum PiPServiceStatus { disabled, enabled }

/// Service to manage Picture-in-Picture functionality for calls
///
/// Uses IOSAgoraPiPService for iOS (native AVPictureInPictureController for live video)
/// Uses pip package for Android (native PiP with auto-enter)
class PiPService {
  static final PiPService _instance = PiPService._internal();
  factory PiPService() => _instance;
  PiPService._internal();

  bool _isPiPEnabled = false;
  bool get isPiPEnabled => _isPiPEnabled;

  // The pip package instance for Android
  final pip_pkg.Pip _pipAndroid = pip_pkg.Pip();
  bool _isSetup = false;
  
  // Track if PiP is allowed (only during active calls)
  bool _isPiPAllowed = false;
  bool get isPiPAllowed => _isPiPAllowed;
  
  // Track if we're in a resume grace period (prevent auto-PiP right after returning)
  bool _isInResumeGracePeriod = false;
  bool get isInResumeGracePeriod => _isInResumeGracePeriod;
  
  // Track if we're in a permission flow (prevent PiP during permission dialogs)
  bool _isInPermissionFlow = false;
  bool get isInPermissionFlow => _isInPermissionFlow;
  
  // Track when PiP started to prevent immediate stop on brief transitions
  DateTime? _pipStartTime;
  static const _minPiPDuration = Duration(milliseconds: 500);
  
  // iOS Agora-specific PiP service for live video
  final IOSAgoraPiPService _iosAgoraPiPService = IOSAgoraPiPService();
  StreamSubscription<PiPState>? _iosAgoraPiPSubscription;

  // Stream controller for PiP status changes
  final StreamController<PiPServiceStatus> _statusController =
      StreamController<PiPServiceStatus>.broadcast();

  /// Stream of PiP status changes - listen to this to update UI when entering/exiting PiP
  Stream<PiPServiceStatus> get statusStream => _statusController.stream;

  // Current PiP status
  PiPServiceStatus _currentStatus = PiPServiceStatus.disabled;
  PiPServiceStatus get currentStatus => _currentStatus;

  /// Check if currently in PiP mode
  bool get isInPiPMode => _currentStatus == PiPServiceStatus.enabled;

  /// Allow PiP to be used (call this when entering a call screen)
  void allowPiP() {
    _isPiPAllowed = true;
    debugPrint('📺 PiP: PiP is now ALLOWED (call screen active)');
  }

  /// Disallow PiP (call this when leaving a call screen)
  void disallowPiP() {
    _isPiPAllowed = false;
    debugPrint('📺 PiP: PiP is now DISALLOWED (not in call screen)');
  }

  /// Initialize/setup the PiP service
  Future<void> setup() async {
    if (_isSetup) return;
    
    // Only allow setup if PiP is allowed (during calls)
    if (!_isPiPAllowed) {
      debugPrint('📺 PiP: Setup blocked - not in a call screen');
      return;
    }

    try {
      if (Platform.isAndroid) {
        // Setup pip package for Android with configuration
        await _pipAndroid.setup(
          pip_pkg.PipOptions(
            autoEnterEnabled: true,
            // Android specific options - 9:16 portrait ratio for call UI
            aspectRatioX: 9,
            aspectRatioY: 16,
          ),
        );

        // Register state change observer for Android
        _pipAndroid.registerStateChangedObserver(
          pip_pkg.PipStateChangedObserver(
            onPipStateChanged: (state, error) {
              debugPrint(
                '📺 PiP Android: State changed to $state, error: $error',
              );
              if (state == pip_pkg.PipState.pipStateStarted) {
                _isPiPEnabled = true;
                _updateStatus(PiPServiceStatus.enabled);
              } else if (state == pip_pkg.PipState.pipStateStopped) {
                _isPiPEnabled = false;
                _updateStatus(PiPServiceStatus.disabled);
              } else if (state == pip_pkg.PipState.pipStateFailed) {
                debugPrint('📺 PiP Android: Failed with error: $error');
                _isPiPEnabled = false;
                _updateStatus(PiPServiceStatus.disabled);
              }
            },
          ),
        );
        debugPrint('📺 PiP: Android setup complete with pip package');
      } else if (Platform.isIOS) {
        // Initialize iOS Agora PiP service for native AVPictureInPictureController
        await _iosAgoraPiPService.initialize();
        
        // Subscribe to iOS PiP state changes
        _iosAgoraPiPSubscription = _iosAgoraPiPService.stateStream.listen((state) {
          debugPrint('📺 PiP iOS: State changed to $state');
          if (state == PiPState.started) {
            _isPiPEnabled = true;
            _updateStatus(PiPServiceStatus.enabled);
          } else if (state == PiPState.stopped || state == PiPState.failed) {
            _isPiPEnabled = false;
            _updateStatus(PiPServiceStatus.disabled);
          } else if (state == PiPState.restoreUI) {
            // User tapped PiP window to return to app
            _isPiPEnabled = false;
            _updateStatus(PiPServiceStatus.disabled);
            debugPrint('📺 PiP iOS: User returned to app - PiP will not auto-restart');
          }
        });
      }

      _isSetup = true;
      debugPrint('📺 PiP: Setup complete on ${Platform.operatingSystem}');
    } catch (e) {
      debugPrint('📺 PiP: Error during setup: $e');
    }
  }

  /// Check if PiP is available on the current device
  Future<bool> isAvailable() async {
    try {
      if (Platform.isIOS) {
        // Check native Agora PiP support (iOS 15+)
        final nativeSupported = await _iosAgoraPiPService.isSupported();
        debugPrint('📺 PiP: iOS native PiP supported = $nativeSupported');
        return nativeSupported;
      } else if (Platform.isAndroid) {
        // pip package supports Android API 26+
        debugPrint('📺 PiP: Android platform supported');
        return true;
      }
      return false;
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
      // Mark that we're in permission flow to prevent PiP during dialog
      _isInPermissionFlow = true;
      debugPrint('📺 PiP: Permission flow STARTED - PiP blocked');
      
      try {
        final result = await systemPermissionHandler.requestOverlayPermission(context);
        
        // Keep permission flow flag for a bit after returning from settings
        // to prevent PiP from starting during the transition
        Future.delayed(const Duration(seconds: 2), () {
          _isInPermissionFlow = false;
          debugPrint('📺 PiP: Permission flow ENDED');
        });
        
        return result;
      } catch (e) {
        _isInPermissionFlow = false;
        debugPrint('📺 PiP: Permission flow error: $e');
        return false;
      }
    }

    return hasPermission;
  }

  /// Enable PiP mode when app goes to background
  ///
  /// Uses IOSAgoraPiPService for iOS (native AVPictureInPictureController)
  /// Uses pip package for Android (native PiP)
  Future<bool> enablePiP({
    String? contactName,
    bool isVideoCall = true,
    BuildContext? context,
  }) async {
    // Block if not in a call screen
    if (!_isPiPAllowed) {
      debugPrint('📺 PiP: enablePiP blocked - not in a call screen');
      return false;
    }
    
    // Block if in resume grace period
    if (_isInResumeGracePeriod) {
      debugPrint('📺 PiP: enablePiP blocked - in resume grace period');
      return false;
    }
    
    // Block if in permission flow
    if (_isInPermissionFlow) {
      debugPrint('📺 PiP: enablePiP blocked - in permission flow');
      return false;
    }
    
    try {
      debugPrint(
        '📺 PiP: enablePiP called, platform=${Platform.operatingSystem}',
      );

      // Ensure setup is done
      await setup();

      final available = await isAvailable();
      debugPrint('📺 PiP: isAvailable = $available');
      if (!available) {
        debugPrint('📺 PiP: Not available on this device');
        return false;
      }

      if (Platform.isAndroid) {
        // Check overlay permission on Android
        final hasOverlay = await checkOverlayPermission(context);
        debugPrint('📺 PiP: hasOverlayPermission = $hasOverlay');
        if (!hasOverlay) {
          debugPrint('📺 PiP: Overlay permission denied, cannot enable PiP');
          return false;
        }

        // Start PiP mode using pip package for Android
        try {
          await _pipAndroid.start();
          _isPiPEnabled = true;
          _updateStatus(PiPServiceStatus.enabled);
          debugPrint('📺 PiP: Started Android PiP mode');
        } catch (e) {
          debugPrint('📺 PiP: Android start error: $e');
          return false;
        }
      } else if (Platform.isIOS) {
        // Don't start PiP if user just returned to app from PiP
        if (_iosAgoraPiPService.isRestoringUI) {
          debugPrint('📺 PiP: Skipping PiP - user just returned from PiP');
          return false;
        }
        
        // Use native iOS Agora PiP (iOS 15+)
        final nativeSupported = await _iosAgoraPiPService.isSupported();
        if (nativeSupported) {
          final setupResult = await _iosAgoraPiPService.setup();
          if (setupResult) {
            final startResult = await _iosAgoraPiPService.start();
            _isPiPEnabled = startResult;
            if (startResult) {
              _updateStatus(PiPServiceStatus.enabled);
            }
            debugPrint('📺 PiP: iOS native Agora PiP start result = $startResult');
            return startResult;
          }
        }
        
        // Native PiP not supported on this device
        debugPrint('📺 PiP: iOS native PiP not supported, PiP unavailable');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('📺 PiP: Error enabling: $e');
      return false;
    }
  }

  /// Disable PiP mode - ONLY call this when leaving the call screen entirely
  /// Don't call this when just coming back from background!
  Future<bool> disablePiP() async {
    try {
      if (Platform.isAndroid) {
        // Stop any active PiP
        await _pipAndroid.stop();
        // IMPORTANT: Disable auto-enter by calling setup with autoEnterEnabled: false
        // This prevents PiP from activating on other screens
        await _pipAndroid.setup(
          pip_pkg.PipOptions(
            autoEnterEnabled: false,
            aspectRatioX: 9,
            aspectRatioY: 16,
          ),
        );
        debugPrint('📺 PiP: Android auto-enter DISABLED');
      } else if (Platform.isIOS) {
        // Stop native iOS PiP if active
        if (_iosAgoraPiPService.isActive) {
          await _iosAgoraPiPService.stop();
        }
      }
      _isPiPEnabled = false;
      _isPiPAllowed = false; // Reset allowed flag
      _isSetup = false; // Reset setup flag
      _isInPermissionFlow = false; // Reset permission flow flag
      _updateStatus(PiPServiceStatus.disabled);
      debugPrint('📺 PiP: Disabled completely and reset');
      return true;
    } catch (e) {
      debugPrint('📺 PiP: Error disabling: $e');
      return false;
    }
  }

  /// Just reset the flag without disabling PiP configuration
  /// Call this when returning from background to foreground
  void resetPiPFlag() {
    _isPiPEnabled = false;
    _updateStatus(PiPServiceStatus.disabled);
    debugPrint('📺 PiP: Flag reset (config still active)');
  }

  /// Toggle app state (foreground/background)
  Future<void> toggleAppState(bool toForeground) async {
    try {
      if (toForeground) {
        // Stop PiP when coming to foreground
        if (Platform.isAndroid) {
          await _pipAndroid.stop();
        } else if (Platform.isIOS) {
          // Stop native iOS PiP if active
          if (_iosAgoraPiPService.isActive) {
            await _iosAgoraPiPService.stop();
          }
        }
        _updateStatus(PiPServiceStatus.disabled);
      } else {
        // Don't start PiP if in permission flow or resume grace period
        if (_isInPermissionFlow) {
          debugPrint('📺 PiP: toggleAppState blocked - in permission flow');
          return;
        }
        if (_isInResumeGracePeriod) {
          debugPrint('📺 PiP: toggleAppState blocked - in resume grace period');
          return;
        }
        
        // Start PiP when going to background
        if (Platform.isAndroid) {
          try {
            await _pipAndroid.start();
          } catch (e) {
            debugPrint('📺 PiP: Android toggle start error: $e');
          }
        } else if (Platform.isIOS) {
          // Don't start if user is restoring UI
          if (_iosAgoraPiPService.isRestoringUI) {
            debugPrint('📺 PiP: Skipping toggle - user returning from PiP');
            return;
          }
          
          // Use native iOS PiP
          final nativeSupported = await _iosAgoraPiPService.isSupported();
          if (nativeSupported) {
            // Ensure setup is called first
            await _iosAgoraPiPService.setup();
            await _iosAgoraPiPService.start();
          } else {
            debugPrint('📺 PiP: iOS native PiP not supported, skipping');
          }
        }
        _updateStatus(PiPServiceStatus.enabled);
      }

      debugPrint(
        '📺 PiP: Toggled to ${toForeground ? 'foreground' : 'background'}',
      );
    } catch (e) {
      debugPrint('📺 PiP: Error toggling state: $e');
    }
  }

  /// Get current PiP status from the system
  Future<bool> getStatus() async {
    try {
      if (Platform.isIOS) {
        // Use IOSAgoraPiPService status for iOS
        return _iosAgoraPiPService.isActive;
      }
      // pip package doesn't have a direct status check, return our internal state
      return _isPiPEnabled;
    } catch (e) {
      debugPrint('📺 PiP: Error getting status: $e');
      return false;
    }
  }

  /// Enable PiP automatically when going to background
  /// This sets up PiP with auto-enter enabled
  Future<bool> enableAutoPiP({
    bool isVideoCall = true,
    BuildContext? context,
  }) async {
    // Block if not in a call screen
    if (!_isPiPAllowed) {
      debugPrint('📺 PiP: enableAutoPiP blocked - not in a call screen');
      return false;
    }
    
    try {
      // Ensure setup is done
      await setup();

      final available = await isAvailable();
      debugPrint(
        '📺 PiP: enableAutoPiP called, isAvailable=$available, platform=${Platform.operatingSystem}',
      );

      if (!available) {
        debugPrint('📺 PiP: Not available on this platform');
        return false;
      }

      if (Platform.isAndroid) {
        // Check overlay permission on Android
        final hasOverlay = await checkOverlayPermission(context);
        if (!hasOverlay) {
          debugPrint(
            '📺 PiP: Overlay permission denied, cannot enable auto-PiP',
          );
          return false;
        }
        // pip package has autoEnterEnabled in setup, which we've already configured
        debugPrint(
          '📺 PiP: Android Auto-PiP configured (autoEnterEnabled=true)',
        );
      } else if (Platform.isIOS) {
        // Setup native iOS PiP for Agora video
        final nativeSupported = await _iosAgoraPiPService.isSupported();
        if (nativeSupported) {
          await _iosAgoraPiPService.setup();
          debugPrint('📺 PiP: iOS native Agora PiP auto-configured');
        } else {
          debugPrint('📺 PiP: iOS native PiP not supported');
        }
      }

      return true;
    } catch (e) {
      debugPrint('📺 PiP: Error enabling auto-PiP: $e');
      return false;
    }
  }

  /// Update the PiP status and notify listeners
  void _updateStatus(PiPServiceStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
      debugPrint('📺 PiP: Status changed to $status');
    }
  }

  /// Immediately set the resume grace period flag
  /// This should be called synchronously when app resumes to block any pending PiP starts
  void setResumeGracePeriod(bool value) {
    _isInResumeGracePeriod = value;
    debugPrint('📺 PiP: Resume grace period set to $value');
  }

  /// Call this when app resumes from background
  Future<void> onAppResumed() async {
    // Set grace period to prevent immediate re-minimizing (may already be set)
    _isInResumeGracePeriod = true;
    debugPrint('📺 PiP: Resume grace period STARTED');
    
    try {
      if (Platform.isAndroid) {
        // Stop PiP first
        try {
          await _pipAndroid.stop();
        } catch (e) {
          debugPrint('📺 PiP: Android stop error (non-fatal): $e');
        }
        
        // CRITICAL: Temporarily disable auto-enter to prevent re-minimizing
        // This is the key fix for smooth PiP-to-app transition
        try {
          await _pipAndroid.setup(
            pip_pkg.PipOptions(
              autoEnterEnabled: false,
              aspectRatioX: 9,
              aspectRatioY: 16,
            ),
          );
          debugPrint('📺 PiP: Android auto-enter DISABLED temporarily');
        } catch (e) {
          debugPrint('📺 PiP: Android setup error (non-fatal): $e');
        }
      } else if (Platform.isIOS) {
        // FIRST: Cancel any pending PiP operations in native side
        await _iosAgoraPiPService.cancelPending();
        
        // Only stop PiP if it's been active for a minimum duration
        // This prevents stopping PiP on brief lifecycle transitions (e.g., control center swipe)
        final pipActiveTime = _pipStartTime != null 
            ? DateTime.now().difference(_pipStartTime!) 
            : Duration.zero;
        
        if (_iosAgoraPiPService.isActive && pipActiveTime >= _minPiPDuration) {
          debugPrint('📺 PiP: iOS PiP active for ${pipActiveTime.inMilliseconds}ms - stopping');
          await _iosAgoraPiPService.stop();
        } else if (_iosAgoraPiPService.isActive) {
          debugPrint('📺 PiP: iOS PiP active for only ${pipActiveTime.inMilliseconds}ms - keeping active (brief transition)');
          // Don't stop - this was likely a brief transition like control center
          _isInResumeGracePeriod = false;
          return;
        }
        
        // Reset start time
        _pipStartTime = null;
        
        // Reset restoration flag after a delay to allow PiP on next background
        Future.delayed(const Duration(seconds: 2), () {
          _iosAgoraPiPService.resetRestorationFlag();
        });
      }
    } catch (e) {
      debugPrint('📺 PiP: onAppResumed error: $e');
    }
    
    _updateStatus(PiPServiceStatus.disabled);
    _isPiPEnabled = false;
    
    // End grace period and re-enable auto-enter after delay
    Future.delayed(const Duration(milliseconds: 1500), () async {
      _isInResumeGracePeriod = false;
      debugPrint('📺 PiP: Resume grace period ENDED');
      
      // Re-enable auto-enter on Android if still in a call screen
      if (Platform.isAndroid && _isPiPAllowed) {
        try {
          await _pipAndroid.setup(
            pip_pkg.PipOptions(
              autoEnterEnabled: true,
              aspectRatioX: 9,
              aspectRatioY: 16,
            ),
          );
          debugPrint('📺 PiP: Android auto-enter RE-ENABLED');
        } catch (e) {
          debugPrint('📺 PiP: Android re-enable error: $e');
        }
      }
    });
    
    debugPrint('📺 PiP: onAppResumed - PiP stopped');
  }

  /// Call this when app goes to background during a call
  Future<void> onAppPaused() async {
    // Only allow if in a call screen
    if (!_isPiPAllowed) {
      debugPrint('📺 PiP: onAppPaused blocked - not in a call screen');
      return;
    }
    
    // Don't start PiP if we're in resume grace period (prevents auto-minimize after returning)
    if (_isInResumeGracePeriod) {
      debugPrint('📺 PiP: onAppPaused blocked - in resume grace period');
      return;
    }
    
    // Don't start PiP if we're in permission flow (user is granting permissions)
    if (_isInPermissionFlow) {
      debugPrint('📺 PiP: onAppPaused blocked - in permission flow');
      return;
    }
    
    try {
      // Ensure setup is done
      await setup();

      if (Platform.isAndroid) {
        // Start PiP when going to background
        try {
          await _pipAndroid.start();
          debugPrint('📺 PiP: Android PiP started');
        } catch (e) {
          debugPrint('📺 PiP: Android start error (non-fatal): $e');
          // Non-fatal - PiP might already be active or not possible
        }
      } else if (Platform.isIOS) {
        // Don't start PiP if user just returned to app from PiP
        if (_iosAgoraPiPService.isRestoringUI) {
          debugPrint('📺 PiP: Skipping PiP start - user just returned from PiP');
          return;
        }
        
        // Double-check grace period before any async operations
        // (app might have resumed while we were waiting)
        if (_isInResumeGracePeriod) {
          debugPrint('📺 PiP: Skipping iOS PiP start - grace period active');
          return;
        }
        
        // Use native iOS Agora PiP
        final nativeSupported = await _iosAgoraPiPService.isSupported();
        
        // Check grace period again after async call
        if (_isInResumeGracePeriod) {
          debugPrint('📺 PiP: Aborting iOS PiP - grace period became active');
          return;
        }
        
        if (nativeSupported && !_iosAgoraPiPService.isActive) {
          // Call setup first to ensure PiP controller is ready
          final setupResult = await _iosAgoraPiPService.setup();
          
          // Check grace period again after async setup
          if (_isInResumeGracePeriod) {
            debugPrint('📺 PiP: Aborting iOS PiP after setup - grace period became active');
            return;
          }
          
          if (setupResult) {
            final startResult = await _iosAgoraPiPService.start();
            if (startResult) {
              _isPiPEnabled = true;
              _pipStartTime = DateTime.now(); // Track when PiP started
              _updateStatus(PiPServiceStatus.enabled);
              debugPrint('📺 PiP: iOS native Agora PiP started successfully');
            } else {
              debugPrint('📺 PiP: iOS native Agora PiP start failed');
            }
          } else {
            debugPrint('📺 PiP: iOS native Agora PiP setup failed');
          }
        } else {
          debugPrint('📺 PiP: iOS native PiP not supported or already active');
        }
        // Return early for iOS - don't set _isPiPEnabled unless start succeeded
        return;
      }

      _isPiPEnabled = true;
      _updateStatus(PiPServiceStatus.enabled);
      debugPrint('📺 PiP: onAppPaused - PiP started');
    } catch (e) {
      debugPrint('📺 PiP: Error in onAppPaused: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    if (Platform.isAndroid) {
      _pipAndroid.unregisterStateChangedObserver();
    } else if (Platform.isIOS) {
      _iosAgoraPiPSubscription?.cancel();
      _iosAgoraPiPService.dispose();
    }
    _statusController.close();
  }
}
