import 'dart:convert';
import 'dart:io';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/pusher_service.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/calling_module/models/user_model.dart';
import 'package:doctak_app/presentation/calling_module/services/permission_service.dart';
import 'package:flutter/material.dart';
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
  static final GlobalKey<CallScreenState> globalKey = GlobalKey<CallScreenState>();

  final String callId;
  final String contactId;
  final String contactName;
  final String contactAvatar;
  final bool isIncoming;
  final bool isVideoCall;
  final String? token; // Optional token for secure connections
  final bool isWaitingForCallData; // New flag to indicate we're waiting for real call data

  const CallScreen({
    Key? key,
    required this.callId,
    required this.contactId,
    required this.contactName,
    required this.contactAvatar,
    required this.isIncoming,
    required this.isVideoCall,
    this.token,
    this.isWaitingForCallData = false, // Default to false for backward compatibility
  }) : super(key: key);

  @override
  State<CallScreen> createState() => CallScreenState();
}

class CallScreenState extends State<CallScreen> with WidgetsBindingObserver {
  // Services
  late AgoraService _agoraService;
  PusherChannelsFlutter get pusher => AppData.pusher;

  // Add global CallService instance
  final CallService _callService = CallService();

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

  @override
  void initState() {
    super.initState();
    _currentCallId = widget.callId;
    _isWaitingForCallData = widget.isWaitingForCallData;

    WidgetsBinding.instance.addObserver(this);

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

    // Setup Pusher listeners for call events
    _setupPusherListeners();

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
    WakelockPlus.enable();
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
    // Handle app lifecycle changes
    if (state == AppLifecycleState.paused) {
      // App going to background
      _callProvider.handleAppBackground();
    } else if (state == AppLifecycleState.resumed) {
      // App coming to foreground
      _callProvider.handleAppForeground();
    }
  }

  // Check permissions and start call
  Future<void> _checkPermissionsAndStartCall() async {
    if (_hasInitializedCall) return; // Prevent multiple initializations

    // Check required permissions
    final hasPermissions = await PermissionService.hasRequiredPermissions(
      isVideoCall: widget.isVideoCall,
    );

    if (hasPermissions) {
      // Initialize call
      _hasInitializedCall = true;
      _callProvider.initializeCall();

      // Listen for call state changes to track when call is established
      _callProvider.addListener(_onCallStateChanged);
    } else {
      // Request permissions
      final permissions = await PermissionService.requestCallPermissions(
        isVideoCall: widget.isVideoCall,
      );

      // Check if all required permissions are granted
      if (widget.isVideoCall) {
        if (permissions[Permission.microphone] == true &&
            permissions[Permission.camera] == true) {
          _hasInitializedCall = true;
          _callProvider.initializeCall();

          // Listen for call state changes
          _callProvider.addListener(_onCallStateChanged);
        } else {
          _showPermissionErrorSnackbar();
        }
      } else {
        if (permissions[Permission.microphone] == true) {
          _hasInitializedCall = true;
          _callProvider.initializeCall();

          // Listen for call state changes
          _callProvider.addListener(_onCallStateChanged);
        } else {
          _showPermissionErrorSnackbar();
        }
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
    }
  }

  // Show permission error
  void _showPermissionErrorSnackbar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(translation(context).lbl_call_permission_error),
        action: SnackBarAction(
          label: translation(context).lbl_try_again,
          onPressed: _checkPermissionsAndStartCall,
        ),
      ),
    );
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

  // Confirm end call dialog with improved UX
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
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: Text(translation(context).lbl_end_call),
        content: Text(translation(context).lbl_end_call_confirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translation(context).lbl_cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _endCallAndCleanup();
            },
            child: Text(translation(context).lbl_end_call, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
      
      // Subscribe to user channel if not already subscribed
      pusherService.subscribeToChannel(userChannel);
      
      // Listen for call ended events from remote side
      pusherService.registerEventListener('call.ended', _handleRemoteCallEnded);
      pusherService.registerEventListener('Call_Ended', _handleRemoteCallEnded);
      
      print('Pusher listeners setup for call events on channel: $userChannel');
    } catch (e) {
      print('Error setting up Pusher listeners: $e');
    }
  }

  // Handle remote call ended event
  void _handleRemoteCallEnded(dynamic data) {
    print('Received remote call ended event: $data');
    
    try {
      // Parse the event data
      Map<String, dynamic> callData = {};
      if (data is String) {
        callData = jsonDecode(data);
      } else if (data is Map<String, dynamic>) {
        callData = data;
      }

      // Check if this event is for the current call
      final remoteCallId = callData['call_id']?.toString() ?? 
                          callData['id']?.toString() ?? 
                          callData['callId']?.toString();
      
      print('Remote call ID: $remoteCallId, Current call ID: $_currentCallId');
      
      // Only handle if this is for our current call or if no specific call ID is provided
      // (some systems might send generic call end events)
      final isForCurrentCall = remoteCallId == null || 
                              remoteCallId.isEmpty || 
                              remoteCallId == _currentCallId;
      
      if (isForCurrentCall) {
        print('Remote side ended the call, cleaning up locally');
        
        // Update call state to indicate remote ended call
        if (mounted) {
          setState(() {
            _callEstablished = false;
          });
        }
        
        // End the call immediately without confirmation since remote ended it
        if (mounted && !_isEndingCall) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _endCallAndCleanup();
          });
        }
      }
    } catch (e) {
      print('Error handling remote call ended event: $e');
      // On error, still try to end the call if we're in an active call state
      if (mounted && !_isEndingCall && _callEstablished) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _endCallAndCleanup();
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up Pusher listeners first
    try {
      final pusherService = PusherService();
      pusherService.unregisterEventListener('call.ended', _handleRemoteCallEnded);
      pusherService.unregisterEventListener('Call_Ended', _handleRemoteCallEnded);
    } catch (e) {
      print('Error cleaning up Pusher listeners: $e');
    }
    // Make sure to clean up properly
    _callProvider.removeListener(_onCallStateChanged);
    WidgetsBinding.instance.removeObserver(this);

    // Allow the screen to turn off again
    WakelockPlus.disable();

    // Clean up audio session
    _cleanupAudioSession();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _callProvider,
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: WillPopScope(
          onWillPop: () async {
            // Show confirm dialog before exiting
            // _confirmEndCall();
            return false; // Always prevent default back behavior
          },
          child: Consumer<CallProvider>(
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
                        customMessage: translation(context).lbl_initializing_call,
                      ),
                      // Call Controls with end call button only
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 40,
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
                  if (callState.callType == CallType.video && callState.isRemoteUserJoined) {
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
                        top: callState.callType == CallType.video && !callState.isControlsVisible ? -80 : 0,
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
                        bottom: (callState.isControlsVisible || callState.callType == CallType.audio) ? 40 : -100,
                        child: CallControls(
                          onEndCallConfirm: _confirmEndCall,
                        ),
                      ),

                      // Reconnecting overlay
                      if (callState.connectionState == CallConnectionState.reconnecting)
                        _buildReconnectingOverlay(),

                      // Loading overlay when ending call
                      if (_isEndingCall)
                        _buildEndingCallOverlay(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Build main content based on call state
  Widget _buildMainContent(CallState callState) {
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
      return const VideoView();
    } else {
      return const AudioCallView();
    }
  }

  // Build reconnecting overlay
  Widget _buildReconnectingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
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
            ),
            const SizedBox(height: 8),
            Text(
              translation(context).lbl_please_wait,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
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

