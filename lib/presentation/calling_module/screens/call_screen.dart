import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/pusher_service.dart';
import 'package:doctak_app/core/utils/call_permission_handler.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/calling_module/models/user_model.dart';
import 'package:doctak_app/presentation/calling_module/services/pip_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/call_state.dart';
import '../providers/call_provider.dart';
import '../services/agora_service.dart';
import '../services/call_service.dart';
import '../widgets/audio_call_view.dart';
import '../widgets/call_controls.dart';
import '../widgets/connecting_view.dart';
import '../widgets/status_bar.dart';
import '../widgets/video_view.dart';

/// Main call screen that integrates all call components
class CallScreen extends StatefulWidget {
  // Add a global key to access this widget's state from anywhere
  static final GlobalKey<CallScreenState> globalKey =
      GlobalKey<CallScreenState>();

  final String callId;
  final String contactId;
  final String contactName;
  final String contactAvatar;
  final bool isIncoming;
  final bool isVideoCall;
  final String? token; // Optional token for secure connections
  final bool
  isWaitingForCallData; // New flag to indicate we're waiting for real call data

  const CallScreen({
    Key? key,
    required this.callId,
    required this.contactId,
    required this.contactName,
    required this.contactAvatar,
    required this.isIncoming,
    required this.isVideoCall,
    this.token,
    this.isWaitingForCallData =
        false, // Default to false for backward compatibility
  }) : super(key: key);

  @override
  State<CallScreen> createState() => CallScreenState();
}

class CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  // Services
  late AgoraService _agoraService;
  PusherChannelsFlutter? get pusher =>
      AppData.isPusherInitialized ? AppData.pusher : null;

  // Add global CallService instance
  final CallService _callService = CallService();

  // PiP service for Picture-in-Picture support
  final PiPService _pipService = PiPService();
  bool _isPiPEnabled = false;
  StreamSubscription<PiPServiceStatus>? _pipStatusSubscription;

  // Track if we're in PiP/background transition to prevent false disconnections
  bool _isInPiPTransition = false;
  DateTime? _pipTransitionStartTime;
  static const int _pipTransitionGracePeriodMs = 4000; // 4 seconds grace period

  // Flag to temporarily hide video views during PiP transition to prevent surface crash
  bool _isVideoViewSuspended = false;
  
  // Key to force recreation of video views after PiP - prevents null surface crash
  Key _videoViewKey = UniqueKey();

  // Add flag to prevent duplicate ending
  bool _isEndingCall = false;

  // User models
  late UserModel _localUser;
  late UserModel _remoteUser;

  // Call provider
  late CallProvider _callProvider;

  // Local state
  String _currentCallId = '';
  bool _isWaitingForCallData = false;
  bool _hasInitializedCall = false;

  // Add state for call status
  bool _callEstablished = false;

  // Timer for auto-closing call ended screen
  Timer? _autoCloseTimer;
  CallEndReason? _lastCallEndReason;

  // Timestamp when call screen was initialized - used to ignore stale events
  DateTime? _callScreenInitTime;

  // Minimum time before accepting call.ended events (in milliseconds)
  static const int _callEndedProtectionMs = 3000;

  @override
  void initState() {
    super.initState();
    _currentCallId = widget.callId;
    _isWaitingForCallData = widget.isWaitingForCallData;
    _callScreenInitTime = DateTime.now();

    WidgetsBinding.instance.addObserver(this);

    // NOTE: PiP is NOT allowed here - only when call is actually established
    // _pipService.allowPiP() will be called in _onCallStateChanged when remote user joins

    // Initialize services
    _agoraService = AgoraService();

    // Create user models
    _localUser = UserModel(
      id: AppData.logInUserId, // Replace with actual user ID
      name: 'You',
      avatarUrl: "${AppData.userProfileUrl}${AppData.profile_pic}",
    );
    _remoteUser = UserModel(
      id: widget.contactId,
      name: widget.contactName,
      avatarUrl: widget.contactAvatar,
    );

    // CRITICAL FIX: Delay Pusher listener setup to avoid catching stale events
    // This prevents call.ended events from prior calls from ending new calls
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && !_isEndingCall) {
        _setupPusherListeners();
      }
    });

    // Initialize call provider with token
    _callProvider = CallProvider(
      agoraService: _agoraService,
      callId: _currentCallId,
      localUser: _localUser,
      remoteUser: _remoteUser,
      isVideoCall: widget.isVideoCall,
      token: widget.token, // Pass the token
    );

    // Notify CallService that we've opened the call screen
    _callService.handleCallAccepted(_currentCallId);

    // Check permissions and start call if not waiting for call data
    if (!_isWaitingForCallData) {
      _checkPermissionsAndStartCall();
    }

    // Ensure the screen stays on during a call
    _enableWakelock();

    // Initialize PiP subscription for video calls (but don't enable yet)
    _initializePiPSubscription();
  }

  // Initialize Picture-in-Picture subscription only
  Future<void> _initializePiPSubscription() async {
    if (widget.isVideoCall) {
      try {
        // Cancel any existing subscription first
        await _pipStatusSubscription?.cancel();
        _pipStatusSubscription = null;

        // Subscribe to PiP status changes
        _pipStatusSubscription = _pipService.statusStream.listen((status) {
          if (mounted) {
            final isInPiP = status == PiPServiceStatus.enabled;
            if (_isPiPEnabled != isInPiP) {
              setState(() {
                _isPiPEnabled = isInPiP;
              });
              debugPrint('📺 CallScreen: PiP status changed to $status');
            }
          }
        });
        debugPrint('📺 CallScreen: PiP subscription ready');
      } catch (e) {
        debugPrint('📺 CallScreen: Error setting up PiP subscription: $e');
      }
    }
  }

  // Enable PiP mode - no longer needed, handled by native auto-enter
  Future<void> _enablePiPMode() async {
    // PiP is now handled by Android native onUserLeaveHint
    debugPrint('📺 CallScreen: PiP mode handled by native layer');
  }

  // Disable PiP mode
  Future<void> _disablePiPMode() async {
    try {
      await _pipService.disablePiP();
      // The status listener will update _isPiPEnabled
      print('📺 CallScreen: PiP disabled');
    } catch (e) {
      print('📺 CallScreen: Error disabling PiP: $e');
    }
  }

  // Enable wakelock with error handling
  Future<void> _enableWakelock() async {
    try {
      await WakelockPlus.enable();
      print('📞 CallScreen: Wakelock enabled successfully');
    } catch (e) {
      print('📞 CallScreen: Error enabling wakelock: $e');
    }
  }

  // Disable wakelock with error handling
  Future<void> _disableWakelock() async {
    try {
      await WakelockPlus.disable();
      print('📞 CallScreen: Wakelock disabled successfully');
    } catch (e) {
      print('📞 CallScreen: Error disabling wakelock: $e');
    }
  }

  // Method to update call data when it becomes available
  void updateCallData(String callId) {
    if (!mounted) return;

    setState(() {
      _currentCallId = callId;
      _isWaitingForCallData = false;

      // Re-initialize call provider with new callId
      _callProvider = CallProvider(
        agoraService: _agoraService,
        callId: _currentCallId,
        localUser: _localUser,
        remoteUser: _remoteUser,
        isVideoCall: widget.isVideoCall,
      );

      // Notify CallService that we've accepted the call with the new ID
      _callService.handleCallAccepted(_currentCallId);

      // Now check permissions and start the call
      _checkPermissionsAndStartCall();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // Re-enable wakelock when app returns to foreground
        _enableWakelock();
        debugPrint('📞 CallScreen: App resumed');

        // Tell PiP service app is resumed - handles smooth transition
        // This temporarily disables auto-enter to prevent re-minimizing
        unawaited(_pipService.onAppResumed());

        // Handle PiP transition gracefully
        if (_isPiPEnabled) {
          _isInPiPTransition = true;
          _pipTransitionStartTime = DateTime.now();
          debugPrint('📞 CallScreen: Starting PiP transition grace period');
          
          // CRITICAL FIX: Suspend video views during PiP transition to prevent
          // null SurfaceProducer crash when texture registry is being recreated
          if (mounted) {
            setState(() {
              _isVideoViewSuspended = true;
            });
          }

          // Recreate video views after a delay to ensure surface is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isVideoViewSuspended = false;
                _videoViewKey = UniqueKey(); // Force recreation of video views
              });
              debugPrint('📞 CallScreen: Video views recreated after PiP');
            }
          });

          // Clear the transition state after grace period
          Future.delayed(
            Duration(milliseconds: _pipTransitionGracePeriodMs),
            () {
              if (mounted) {
                _isInPiPTransition = false;
                debugPrint('📞 CallScreen: PiP transition grace period ended');
              }
            },
          );
        }

        // Reset PiP flag immediately when returning to foreground
        if (_isPiPEnabled && mounted) {
          setState(() {
            _isPiPEnabled = false;
          });
        }

        // Restore call state
        if (mounted && !_isEndingCall) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !_isEndingCall) {
              _callProvider.handleAppForeground();
            }
          });
        }
        break;

      case AppLifecycleState.inactive:
        // PiP is handled by Android native onUserLeaveHint - no action needed
        debugPrint('📞 CallScreen: App inactive');
        break;

      case AppLifecycleState.paused:
        // App fully backgrounded - trigger PiP if allowed
        debugPrint('📞 CallScreen: App paused');
        // Suspend video views before going to PiP to prevent surface issues
        if (mounted) {
          setState(() {
            _isVideoViewSuspended = true;
          });
        }
        _pipService.onAppPaused();
        _callProvider.handleAppBackground();
        break;

      case AppLifecycleState.detached:
        debugPrint('📞 CallScreen: App detached');
        break;

      case AppLifecycleState.hidden:
        debugPrint('📞 CallScreen: App hidden');
        break;
    }
  }

  // Check permissions and start call
  Future<void> _checkPermissionsAndStartCall() async {
    if (_hasInitializedCall) return; // Prevent multiple initializations

    // Check required permissions using the professional handler
    final hasPermissions = await callPermissionHandler.hasCallPermissions(
      isVideoCall: widget.isVideoCall,
    );

    if (hasPermissions) {
      // Initialize call
      _hasInitializedCall = true;
      _callProvider.initializeCall();

      // Listen for call state changes to track when call is established
      _callProvider.addListener(_onCallStateChanged);
    } else {
      // Request permissions with professional UI
      if (!mounted) return;

      final result = await callPermissionHandler.showInCallPermissionDialog(
        context,
        isVideoCall: widget.isVideoCall,
      );

      if (result == CallPermissionResult.granted) {
        _hasInitializedCall = true;
        _callProvider.initializeCall();

        // Listen for call state changes
        _callProvider.addListener(_onCallStateChanged);
      } else {
        _showPermissionErrorSnackbar();
      }
    }
  }

  // Callback for call state changes
  void _onCallStateChanged() {
    // Check if call is established (remote user joined)
    if (_callProvider.callState.isRemoteUserJoined && !_callEstablished) {
      setState(() {
        _callEstablished = true;
      });

      // NOW enable PiP since call is actually connected
      // Allow PiP and enable auto-enter when app goes to background
      _pipService.allowPiP();
      _pipService.enableAutoPiP(
        isVideoCall: widget.isVideoCall,
        context: mounted ? context : null,
      );

      // IMPORTANT: Pre-setup PiP so it's ready before backgrounding (especially for iOS)
      // This ensures the PiP controller is fully initialized before we need it
      if (Platform.isIOS) {
        _pipService.setup().then((_) {
          debugPrint('📺 CallScreen: iOS PiP pre-setup complete');
        });
      }

      debugPrint('📞 CallScreen: Call established - PiP service notified');
    }

    // Check if call has ended and start auto-close timer
    final callEndReason = _callProvider.callState.callEndReason;
    if (callEndReason != CallEndReason.none &&
        _lastCallEndReason != callEndReason &&
        _autoCloseTimer == null &&
        !_isEndingCall) {
      _lastCallEndReason = callEndReason;

      print(
        '📞 CallScreen: Call ended with reason: $callEndReason, starting auto-close timer',
      );

      // Start a 2.5 second timer to auto-close the screen
      _autoCloseTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && !_isEndingCall) {
          print('📞 CallScreen: Auto-closing call screen after call ended');
          _endCallAndCleanup();
        }
      });
    }
  }

  // Show permission error with auto-retry
  void _showPermissionErrorSnackbar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                translation(context).lbl_requesting_permissions,
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );

    // Auto-retry permissions after a short delay
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      final granted = await callPermissionHandler.requestWithUI(
        context,
        isVideoCall: widget.isVideoCall,
        showRationale: true,
      );
      if (granted && mounted) {
        _checkPermissionsAndStartCall();
      } else if (mounted) {
        // If still not granted, show final error and close
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              translation(context).lbl_permission_denied,
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        // End call after permission denied
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _endCallAndCleanup();
        });
      }
    });
  }

  // Improved end call method that handles all cleanup steps
  Future<void> _endCallAndCleanup() async {
    // Prevent multiple end call attempts
    if (_isEndingCall) return;

    // Check if widget is still mounted before calling setState
    if (!mounted) return;

    setState(() {
      _isEndingCall = true;
    });

    try {
      // First, end the call with CallProvider (Agora)
      _callProvider.endCall();

      // Then call the global service to handle API updates and UI
      await _callService.endCall();

      // Finally, pop the screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error during call cleanup: $e');

      // Make sure we still pop the screen even if cleanup fails
      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      // Only call setState if still mounted
      if (mounted) {
        setState(() {
          _isEndingCall = false;
        });
      }
    }
  }

  // OneUI 8.5 styled end call confirmation dialog
  void _confirmEndCall() {
    // For a more WhatsApp-like experience, end call immediately without confirmation
    // during an active call
    if (_callEstablished) {
      _endCallAndCleanup();
      return;
    }

    // Only show confirmation dialog when call is still connecting
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E2A3A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_end_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  translation(context).lbl_end_call,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                // Content
                Text(
                  translation(context).lbl_end_call_confirmation,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.white70
                              : Colors.black54,
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          translation(context).lbl_cancel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _endCallAndCleanup();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          translation(context).lbl_end_call,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Clean up audio session
  Future<void> _cleanupAudioSession() async {
    try {
      if (Platform.isIOS) {
        // On iOS, we need to deactivate the audio session
        await _agoraService.deactivateAudioSession();
      }
    } catch (e) {
      print('Error cleaning up audio session: $e');
    }
  }

  // Setup Pusher listeners for remote call events
  void _setupPusherListeners() {
    try {
      final pusherService = PusherService();
      final userChannel = "user.${AppData.logInUserId}";

      print(
        '📞 CallScreen: Setting up Pusher listeners for channel: $userChannel',
      );

      // Subscribe to user channel if not already subscribed
      pusherService.subscribeToChannel(userChannel);

      // Listen for call ended events from remote side
      pusherService.registerEventListener('call.ended', _handleRemoteCallEnded);
      pusherService.registerEventListener('Call_Ended', _handleRemoteCallEnded);
      
      // Listen for call cancelled events (when caller cancels before call is established)
      pusherService.registerEventListener('call.cancelled', _handleRemoteCallCancelled);
      pusherService.registerEventListener('Call_Cancelled', _handleRemoteCallCancelled);
      pusherService.registerEventListener('call_cancelled', _handleRemoteCallCancelled);

      print(
        '📞 CallScreen: Pusher listeners registered for call.ended, call.cancelled events',
      );
    } catch (e) {
      print('📞 CallScreen: Error setting up Pusher listeners: $e');
    }
  }

  // Handle remote call cancelled event (caller cancelled before call established)
  void _handleRemoteCallCancelled(dynamic data) {
    print('📞 CallScreen: ====== REMOTE CALL CANCELLED EVENT RECEIVED ======');
    print('📞 CallScreen: Raw data: $data');

    // Don't process if call is already established
    if (_callEstablished) {
      print('📞 CallScreen: IGNORING call.cancelled - call already established');
      return;
    }

    // Don't process if already ending
    if (_isEndingCall) {
      print('📞 CallScreen: IGNORING call.cancelled - already ending call');
      return;
    }

    try {
      // Parse the event data
      Map<String, dynamic> callData = {};
      if (data is String) {
        callData = jsonDecode(data);
      } else if (data is Map<String, dynamic>) {
        callData = data;
      }

      // Check if this event is for the current call
      final remoteCallId =
          callData['call_id']?.toString() ??
          callData['id']?.toString() ??
          callData['callId']?.toString();

      if (remoteCallId == null || remoteCallId.isEmpty) {
        print('📞 CallScreen: IGNORING call.cancelled - no call_id in event');
        return;
      }

      final isForCurrentCall = remoteCallId == _currentCallId;

      if (isForCurrentCall) {
        print('📞 CallScreen: Caller cancelled the call - showing cancelled state');

        // Update call state to show cancelled
        _callProvider.setCallEndReason(
          CallEndReason.callCancelledByRemote,
          connectionState: CallConnectionState.failed,
        );

        // End the call after showing the message
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isEndingCall) {
            _endCallAndCleanup();
          }
        });
      } else {
        print(
          '📞 CallScreen: IGNORING call.cancelled - call ID mismatch (remote: $remoteCallId, current: $_currentCallId)',
        );
      }
    } catch (e) {
      print('Error handling remote call cancelled event: $e');
    }
  }  // Handle remote call ended event
  void _handleRemoteCallEnded(dynamic data) {
    print('📞 CallScreen: ====== REMOTE CALL ENDED EVENT RECEIVED ======');
    print('📞 CallScreen: Raw data type: ${data.runtimeType}');
    print('📞 CallScreen: Raw data: $data');

    // CRITICAL FIX: Check if we're in a PiP transition
    // Events during PiP transitions should be ignored to prevent false disconnections
    if (_isInPiPTransition) {
      if (_pipTransitionStartTime != null) {
        final timeSinceTransition = DateTime.now()
            .difference(_pipTransitionStartTime!)
            .inMilliseconds;
        if (timeSinceTransition < _pipTransitionGracePeriodMs) {
          print(
            '📞 CallScreen: IGNORING call.ended event - in PiP transition (${timeSinceTransition}ms < ${_pipTransitionGracePeriodMs}ms)',
          );
          return;
        }
      }
    }

    // CRITICAL FIX: Check if the call screen was just initialized
    // Ignore call.ended events that come within the protection window
    // This prevents stale events from previous calls from ending new calls
    if (_callScreenInitTime != null) {
      final timeSinceInit = DateTime.now()
          .difference(_callScreenInitTime!)
          .inMilliseconds;
      if (timeSinceInit < _callEndedProtectionMs) {
        print(
          '📞 CallScreen: IGNORING call.ended event - call screen just initialized ${timeSinceInit}ms ago (protection: ${_callEndedProtectionMs}ms)',
        );
        return;
      }
    }

    // Don't process if already ending call
    if (_isEndingCall) {
      print('📞 CallScreen: IGNORING call.ended event - already ending call');
      return;
    }

    try {
      // Parse the event data
      Map<String, dynamic> callData = {};
      if (data is String) {
        callData = jsonDecode(data);
      } else if (data is Map<String, dynamic>) {
        callData = data;
      }

      print('📞 CallScreen: Parsed call data: $callData');

      // Check if this event is for the current call
      final remoteCallId =
          callData['call_id']?.toString() ??
          callData['id']?.toString() ??
          callData['callId']?.toString();

      print(
        '📞 CallScreen: Remote call ID: $remoteCallId, Current call ID: $_currentCallId',
      );

      // CRITICAL FIX: Only handle if this is EXPLICITLY for our current call
      // Events without a call_id should be ignored to prevent false positives
      if (remoteCallId == null || remoteCallId.isEmpty) {
        print(
          '📞 CallScreen: IGNORING call.ended event - no call_id in event data',
        );
        return;
      }

      final isForCurrentCall = remoteCallId == _currentCallId;

      if (isForCurrentCall) {
        print('📞 CallScreen: Remote side ended the call, cleaning up locally');

        // Determine the appropriate end reason based on call state
        CallEndReason endReason;
        if (!_callEstablished) {
          // If call wasn't established yet, it means caller cancelled
          endReason = CallEndReason.callCancelledByRemote;
          print('📞 CallScreen: Call cancelled by remote (not yet established)');
        } else {
          endReason = CallEndReason.remoteUserEnded;
          print('📞 CallScreen: Call ended by remote user');
        }

        // Update call state to indicate remote ended/cancelled call
        _callProvider.setCallEndReason(
          endReason,
          connectionState: CallConnectionState.failed,
        );

        if (mounted) {
          setState(() {
            _callEstablished = false;
          });
        }

        // End the call after showing the message
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isEndingCall) {
            _endCallAndCleanup();
          }
        });
      } else {
        print(
          '📞 CallScreen: IGNORING call.ended event - call ID mismatch (remote: $remoteCallId, current: $_currentCallId)',
        );
      }
    } catch (e) {
      print('Error handling remote call ended event: $e');
      // DON'T end the call on parse errors - this was causing issues
      // Only end if we explicitly get a matching call.ended event
    }
  }

  @override
  void dispose() {
    // Cancel auto-close timer if it's running
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;

    // Cancel PiP status subscription safely
    try {
      _pipStatusSubscription?.cancel();
      _pipStatusSubscription = null;
    } catch (e) {
      debugPrint('CallScreen: Error cancelling PiP subscription: $e');
    }

    // Notify PiP service that call has ended
    try {
      _pipService.disablePiP();
    } catch (e) {
      debugPrint('CallScreen: Error disabling PiP: $e');
    }

    // Clean up Pusher listeners first
    try {
      final pusherService = PusherService();
      pusherService.unregisterEventListener(
        'call.ended',
        _handleRemoteCallEnded,
      );
      pusherService.unregisterEventListener(
        'Call_Ended',
        _handleRemoteCallEnded,
      );
      // Unregister call cancelled listeners
      pusherService.unregisterEventListener(
        'call.cancelled',
        _handleRemoteCallCancelled,
      );
      pusherService.unregisterEventListener(
        'Call_Cancelled',
        _handleRemoteCallCancelled,
      );
      pusherService.unregisterEventListener(
        'call_cancelled',
        _handleRemoteCallCancelled,
      );
    } catch (e) {
      print('Error cleaning up Pusher listeners: $e');
    }
    // Make sure to clean up properly
    _callProvider.removeListener(_onCallStateChanged);
    WidgetsBinding.instance.removeObserver(this);

    // Allow the screen to turn off again
    _disableWakelock();

    // Clean up audio session
    _cleanupAudioSession();

    super.dispose();
  }

  // Consistent dark call screen background color
  static const _callBackgroundColor = Color(0xFF1A2332);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _callProvider,
      child: Scaffold(
        backgroundColor: _callBackgroundColor,
        body: WillPopScope(
          onWillPop: () async {
            // Show confirm dialog before exiting
            // _confirmEndCall();
            return false; // Always prevent default back behavior
          },
          // Use LayoutBuilder to detect PiP mode (small window)
          child: LayoutBuilder(
            builder: (context, constraints) {
              // DEBUG: Log the actual constraint values to understand real device behavior
              print(
                '📐 CallScreen: constraints.maxWidth=${constraints.maxWidth}, maxHeight=${constraints.maxHeight}, _isPiPEnabled=$_isPiPEnabled',
              );

              // ONLY use _isPiPEnabled flag - remove isSmallWindow check
              // The isSmallWindow check was causing false positives on some devices
              if (_isPiPEnabled) {
                print('📐 CallScreen: Showing PiP view');
                return _buildPipModeView(context, constraints);
              }

              print('📐 CallScreen: Showing Normal view');
              return Consumer<CallProvider>(
                builder: (context, callProvider, child) {
                  final callState = callProvider.callState;

                  // If waiting for call data, show connecting view with "Initializing call..."
                  if (_isWaitingForCallData) {
                    return SafeArea(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ConnectingView(
                            contactName: widget.contactName,
                            isIncoming: widget.isIncoming,
                            isVideoCall: widget.isVideoCall,
                            onRetry: () {}, // No retry in this state
                            showRetry: false,
                            customMessage: translation(
                              context,
                            ).lbl_initializing_call,
                          ),
                          // Call Controls with end call button only
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: MediaQuery.of(context).padding.bottom + 20,
                            child: Center(
                              child: GestureDetector(
                                onTap: _endCallAndCleanup,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.call_end,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      // Show controls when screen is tapped in video mode
                      if (callState.callType == CallType.video &&
                          callState.isRemoteUserJoined) {
                        callProvider.showControls();
                      }
                    },
                    child: SafeArea(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Main content based on call state
                          _buildMainContent(callState),

                          // Status Bar with professional layout
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            top:
                                callState.callType == CallType.video &&
                                    !callState.isControlsVisible
                                ? -80
                                : 0,
                            left: 0,
                            right: 0,
                            child: const StatusBar(),
                          ),

                          // Local Video Preview (when remote video is fullscreen)
                          if (callState.callType == CallType.video &&
                              callState.isLocalUserJoined &&
                              !callState.isLocalVideoFullScreen &&
                              callState.remoteUid != null)
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              right: 16,
                              top: 80,
                              child: LocalVideoPreview(
                                isEnabled: callState.isLocalVideoEnabled,
                                isUserSpeaking: callState.isLocalUserSpeaking,
                                isFrontCamera: callState.isFrontCamera,
                                onTap: callProvider.swapLocalAndRemoteVideo,
                              ),
                            ),

                          // Call Controls with slide-up animation
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            left: 0,
                            right: 0,
                            bottom:
                                (callState.isControlsVisible ||
                                    callState.callType == CallType.audio)
                                ? MediaQuery.of(context).padding.bottom + 20
                                : -100,
                            child: CallControls(
                              onEndCallConfirm: _confirmEndCall,
                            ),
                          ),

                          // Reconnecting overlay
                          if (callState.connectionState ==
                              CallConnectionState.reconnecting)
                            _buildReconnectingOverlay(callState),

                          // Loading overlay when ending call
                          if (_isEndingCall) _buildEndingCallOverlay(),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // Build compact PiP mode view for floating widget
  Widget _buildPipModeView(BuildContext context, BoxConstraints constraints) {
    return Consumer<CallProvider>(
      builder: (context, callProvider, child) {
        final callState = callProvider.callState;
        final agoraEngine = callProvider.getAgoraEngine();
        final totalHeight = constraints.maxHeight;
        final totalWidth = constraints.maxWidth;

        // Calculate sizes based on available space
        final isVerySmall = totalHeight < 150 || totalWidth < 150;
        final buttonSize = (totalWidth / 5).clamp(24.0, 40.0);
        final iconSize = (buttonSize * 0.5).clamp(12.0, 20.0);
        final spacing = (totalWidth / 20).clamp(4.0, 8.0);

        return Container(
          color: Colors.black87,
          child: ClipRect(
            child: Column(
              children: [
                // Video/Avatar area - takes most space
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background or video
                      // CRITICAL: Don't render video views during PiP transition to prevent null surface crash
                      if (_isVideoViewSuspended)
                        Container(
                          color: const Color(0xFF1a1a2e),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white54,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      else if (callState.callType == CallType.video &&
                          callState.isRemoteUserJoined &&
                          agoraEngine != null)
                        KeyedSubtree(
                          key: _videoViewKey,
                          child: const VideoView(),
                        )
                      else if (callState.callType == CallType.video &&
                          callState.isLocalUserJoined &&
                          callState.isLocalVideoEnabled &&
                          agoraEngine != null)
                        // Show LOCAL video when no remote user has joined yet
                        KeyedSubtree(
                          key: _videoViewKey,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              SafeAgoraVideoView(
                                controller: VideoViewController(
                                  rtcEngine: agoraEngine,
                                  canvas: const VideoCanvas(uid: 0),
                                  useFlutterTexture: true,
                                  useAndroidSurfaceView: true,
                                ),
                              ),
                              // Show "You" label
                              Positioned(
                                bottom: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'You',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          color: const Color(0xFF1a1a2e),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  callState.callType == CallType.video
                                      ? Icons.videocam_rounded
                                      : Icons.phone_rounded,
                                  color: Colors.white54,
                                  size: isVerySmall ? 24 : 32,
                                ),
                                if (!isVerySmall) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _remoteUser.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                      // Call timer overlay
                      if (!isVerySmall)
                        Positioned(
                          top: 2,
                          left: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer,
                                  color: Colors.white,
                                  size: 8,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  callState.formattedCallDuration,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Reconnecting overlay
                      if (callState.connectionState ==
                          CallConnectionState.reconnecting)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Compact control bar
                Container(
                  height: (totalHeight * 0.25).clamp(32.0, 50.0),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: spacing),
                  decoration: const BoxDecoration(color: Color(0xFF263238)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Mute button
                      _buildPipControlButton(
                        icon: callState.isMuted ? Icons.mic_off : Icons.mic,
                        color: callState.isMuted
                            ? Colors.red
                            : const Color(0xFF3D4D55),
                        onPressed: callProvider.toggleMute,
                        buttonSize: buttonSize,
                        iconSize: iconSize,
                      ),
                      SizedBox(width: spacing),
                      // Speaker button
                      _buildPipControlButton(
                        icon: callState.isSpeakerOn
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: const Color(0xFF3D4D55),
                        onPressed: callProvider.toggleSpeaker,
                        buttonSize: buttonSize,
                        iconSize: iconSize,
                      ),
                      SizedBox(width: spacing),
                      // Video toggle (for video calls)
                      if (callState.callType == CallType.video) ...[
                        _buildPipControlButton(
                          icon: callState.isLocalVideoEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          color: callState.isLocalVideoEnabled
                              ? const Color(0xFF3D4D55)
                              : Colors.red,
                          onPressed: callProvider.toggleLocalVideo,
                          buttonSize: buttonSize,
                          iconSize: iconSize,
                        ),
                        SizedBox(width: spacing),
                      ],
                      // End call button
                      _buildPipControlButton(
                        icon: Icons.call_end,
                        color: Colors.red,
                        onPressed: _endCallAndCleanup,
                        buttonSize: buttonSize,
                        iconSize: iconSize,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Compact control button for PiP mode
  Widget _buildPipControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double buttonSize,
    required double iconSize,
  }) {
    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(buttonSize / 2),
          onTap: onPressed,
          child: Center(
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }

  // Build main content based on call state
  Widget _buildMainContent(CallState callState) {
    // Check if call has ended with a reason (show end message)
    if (callState.callEndReason != CallEndReason.none) {
      return ConnectingView(
        contactName: widget.contactName,
        isIncoming: widget.isIncoming,
        isVideoCall: widget.isVideoCall,
        onRetry: () {}, // No retry when call ended
        showRetry: false,
        callEndReason: callState.callEndReason,
      );
    }

    // Check if call failed
    if (callState.connectionState == CallConnectionState.failed) {
      return ConnectingView(
        contactName: widget.contactName,
        isIncoming: widget.isIncoming,
        isVideoCall: widget.isVideoCall,
        onRetry: _callProvider.initializeCall,
        showRetry: true,
        callEndReason: CallEndReason.callFailed,
      );
    }

    // Check connection state first
    if (callState.connectionState == CallConnectionState.connecting) {
      return ConnectingView(
        contactName: widget.contactName,
        isIncoming: widget.isIncoming,
        isVideoCall: widget.isVideoCall,
        onRetry: _callProvider.initializeCall,
        showRetry: !callState.isLocalUserJoined,
      );
    }

    // Check if remote user has joined
    if (!callState.isRemoteUserJoined) {
      return const WaitingForRemoteView();
    }

    // Show appropriate view based on call type
    if (callState.callType == CallType.video) {
      // CRITICAL: Don't render video during PiP transition to prevent null surface crash
      if (_isVideoViewSuspended) {
        return Container(
          color: const Color(0xFF1a1a2e),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 2,
            ),
          ),
        );
      }
      return KeyedSubtree(
        key: _videoViewKey,
        child: const VideoView(),
      );
    } else {
      return const AudioCallView();
    }
  }

  // Build reconnecting overlay with countdown
  Widget _buildReconnectingOverlay(CallState callState) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  translation(context).lbl_reconnecting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  translation(context).lbl_please_wait,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                // Show countdown if available
                if (callState.reconnectCountdown > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${translation(context).lbl_disconnecting_in} ${callState.reconnectCountdown} ${translation(context).lbl_seconds}',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build ending call overlay
  Widget _buildEndingCallOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
            const SizedBox(height: 16),
            Text(
              translation(context).lbl_ending_call,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
