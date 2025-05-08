// import 'dart:async';
// import 'dart:math' as math;
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:doctak_app/presentation/call_module/call_service.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// const appId = "f2cf99f1193a40e69546157883b2159f"; // Your Agora App ID
//
// class CallScreen extends StatefulWidget {
//   final String callId;
//   final String contactId;
//   final String contactName;
//   final String contactAvatar;
//   final bool isIncoming;
//   final bool isVideoCall;
//   final String? token; // Optional token for secure connections
//
//   const CallScreen({
//     Key? key,
//     required this.callId,
//     required this.contactId,
//     required this.contactName,
//     required this.contactAvatar,
//     required this.isIncoming,
//     required this.isVideoCall,
//     this.token,
//   }) : super(key: key);
//
//   @override
//   _CallScreenState createState() => _CallScreenState();
// }
//
// class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
//   // Agora Engine
//   RtcEngine? _agoraEngine;
//   int? _remoteUid;
//   bool _isLocalUserJoined = false;
//   bool _isRemoteUserJoined = false;
//   bool _isInitialized = false;
//   bool _isConnecting = true; // Track initial connection state
//
//   // Call controls
//   bool _isMuted = false;
//   bool _isSpeakerOn = true;
//   bool _isLocalVideoEnabled = true;
//   bool _isFrontCamera = true;
//   bool _isVideoCallActive = false; // Track current call type (video or audio)
//   bool _isLocalVideoFullScreen = false; // Track if local video is in fullscreen mode
//   bool _isControlsVisible = true;
//
//   // Call state
//   int _callDuration = 0;
//   Timer? _callTimer;
//   int? _networkQuality;
//   bool _isReconnecting = false;
//   DateTime? _lastNetworkQualityUpdate;
//   bool _isInBackground = false;
//
//   // Connection watchdogs
//   Timer? _connectionWatchdog;
//   Timer? _reconnectionAttemptTimer;
//   int _reconnectionAttempts = 0;
//   bool _isRecoveringConnection = false;
//   DateTime? _lastSuccessfulConnectionTime;
//   Timer? _controlsAutoHideTimer;
//
//   // UI animation controllers
//   late AnimationController _speakingAnimationController;
//   late Animation<double> _speakingAnimation;
//   bool _isLocalUserSpeaking = false;
//   bool _isRemoteUserSpeaking = false;
//   Map<int, Timer?> _speakingTimers = {};
//
//   // Video quality adaptation
//   bool _isUsingLowerVideoQuality = false;
//   int _consecutivePoorNetworkUpdates = 0;
//
//   // User account mapping
//   final Map<int, String> _uidToUserIdMap = {};
//   final Map<String, int> _userIdToUidMap = {};
//
//   // Resource manager for performance optimization
//   final _ResourceManager _resourceManager = _ResourceManager();
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//
//     // Initialize the video state based on call type
//     _isVideoCallActive = widget.isVideoCall;
//
//     // Initialize animation controller for speaking indication
//     _speakingAnimationController = AnimationController(
//       duration: const Duration(milliseconds: 750),
//       vsync: this,
//     )..repeat(reverse: true);
//     _speakingAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(_speakingAnimationController);
//
//     // Start call setup with delay to ensure the widget is properly built
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _initializeCall();
//
//       // Setup network monitoring for adaptive quality
//       _setupNetworkQualityMonitoring();
//
//       // Start connection watchdog
//       _startConnectionWatchdog();
//
//       // Start controls auto-hide timer
//       _startControlsAutoHideTimer();
//     });
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//
//     // Handle app background/foreground transitions
//     if (state == AppLifecycleState.paused) {
//       _isInBackground = true;
//       // Pause video when going to background
//       if (_isVideoCallActive && _agoraEngine != null) {
//         _agoraEngine!.muteLocalVideoStream(true);
//         _resourceManager.setHighPerformanceMode(false);
//       }
//     } else if (state == AppLifecycleState.resumed) {
//       _isInBackground = false;
//       // Restore video when coming back to foreground
//       if (_isVideoCallActive && _agoraEngine != null && _isLocalVideoEnabled) {
//         _agoraEngine!.muteLocalVideoStream(false);
//         _resourceManager.setHighPerformanceMode(true);
//       }
//
//       // Check connection status when app comes to foreground
//       if (_agoraEngine != null && _isInitialized) {
//         _checkConnectionStatus();
//       }
//     }
//   }
//
//   // Connection monitoring and recovery functions
//   void _startConnectionWatchdog() {
//     // Cancel existing watchdog if any
//     _connectionWatchdog?.cancel();
//
//     // Create new watchdog that checks connection every 10 seconds
//     _connectionWatchdog = Timer.periodic(const Duration(seconds: 10), (timer) {
//       if (!mounted || _agoraEngine == null) {
//         timer.cancel();
//         return;
//       }
//
//       // Skip check if already reconnecting
//       if (_isReconnecting || !_isInitialized) return;
//
//       // Check if it's been too long since last successful connection
//       if (_lastSuccessfulConnectionTime != null) {
//         final now = DateTime.now();
//         final difference = now.difference(_lastSuccessfulConnectionTime!).inSeconds;
//
//         // If no successful connection for 20 seconds, try to recover
//         if (difference > 20 && !_isRecoveringConnection) {
//           _triggerConnectionRecovery();
//         }
//       }
//     });
//   }
//
//   void _triggerConnectionRecovery() {
//     if (_isRecoveringConnection) return;
//
//     setState(() {
//       _isRecoveringConnection = true;
//       _reconnectionAttempts = 0;
//     });
//
//     _attemptReconnection();
//   }
//
//   Future<void> _attemptReconnection() async {
//     if (!mounted || _agoraEngine == null) return;
//
//     _reconnectionAttempts++;
//     if (_reconnectionAttempts > 5) {
//       // Too many failed attempts, give up and end call
//       _showErrorDialog(
//           'Connection Lost',
//           'Could not reconnect to the call after multiple attempts.'
//       );
//       Future.delayed(const Duration(seconds: 2), () {
//         _endCall();
//       });
//       return;
//     }
//
//     setState(() {
//       _isReconnecting = true;
//     });
//
//     _showSystemMessage('Reconnecting... Attempt $_reconnectionAttempts/5');
//
//     try {
//       // First leave the channel
//       await _safeAsyncOperation(
//             () => _agoraEngine!.leaveChannel(),
//         'Failed to leave channel for reconnection',
//       );
//
//       // Set media options to minimal for faster reconnection
//       await _configureMediaForReconnection();
//
//       // Try to rejoin
//       final bool joinedChannel = await _joinChannel();
//       if (joinedChannel) {
//         setState(() {
//           _isReconnecting = false;
//           _isRecoveringConnection = false;
//           _lastSuccessfulConnectionTime = DateTime.now();
//         });
//         _showSystemMessage('Successfully reconnected');
//
//         // Restore full media configuration
//         await _configureMediaSettings();
//       } else {
//         // Try again after a short delay
//         _reconnectionAttemptTimer = Timer(
//             Duration(seconds: 2 + _reconnectionAttempts),
//             _attemptReconnection
//         );
//       }
//     } catch (e) {
//       print('Reconnection attempt $_reconnectionAttempts failed: $e');
//
//       // Try again after a delay
//       _reconnectionAttemptTimer = Timer(
//           Duration(seconds: 2 + _reconnectionAttempts),
//           _attemptReconnection
//       );
//     }
//   }
//
//   Future<void> _configureMediaForReconnection() async {
//     if (_agoraEngine == null) return;
//
//     try {
//       // Disable video for faster reconnection
//       if (_isVideoCallActive) {
//         await _agoraEngine!.enableLocalVideo(false);
//       }
//
//       // Set lowest quality possible
//       await _agoraEngine!.setVideoEncoderConfiguration(
//         VideoEncoderConfiguration(
//           dimensions: const VideoDimensions(width: 160, height: 120),
//           frameRate: 10,
//           bitrate: 100,
//           orientationMode: OrientationMode.orientationModeAdaptive,
//           degradationPreference: DegradationPreference.maintainFramerate,
//         ),
//       );
//     } catch (e) {
//       print('Error configuring media for reconnection: $e');
//     }
//   }
//
//   // Verify connection status when app resumes
//   Future<void> _checkConnectionStatus() async {
//     if (_agoraEngine == null) return;
//
//     try {
//       // Try to get connection state
//       final connectionState = await _safeAsyncOperation(
//             () async {
//           final stats = await _agoraEngine!.getConnectionState();
//           return stats;
//         },
//         'Failed to get connection status',
//       );
//
//       if (connectionState != ConnectionStateType.connectionStateConnected &&
//           !_isReconnecting &&
//           _isInitialized) {
//         print('Connection not active, triggering reconnection');
//         _triggerConnectionRecovery();
//       } else {
//         // Update last successful connection time
//         _lastSuccessfulConnectionTime = DateTime.now();
//       }
//     } catch (e) {
//       print('Error checking connection: $e');
//     }
//   }
//
//   // UI controls visibility handling
//   void _startControlsAutoHideTimer() {
//     _controlsAutoHideTimer?.cancel();
//
//     if (_isVideoCallActive && _isRemoteUserJoined) {
//       _controlsAutoHideTimer = Timer(const Duration(seconds: 5), () {
//         if (mounted && _isControlsVisible) {
//           setState(() {
//             _isControlsVisible = false;
//           });
//         }
//       });
//     }
//   }
//
//   void _showControls() {
//     if (!_isControlsVisible) {
//       setState(() {
//         _isControlsVisible = true;
//       });
//       _startControlsAutoHideTimer();
//     } else {
//       // Reset the timer
//       _startControlsAutoHideTimer();
//     }
//   }
//
//   // Setup periodic network quality monitoring
//   void _setupNetworkQualityMonitoring() {
//     Timer.periodic(const Duration(seconds: 3), (timer) {
//       if (!mounted || _agoraEngine == null) {
//         timer.cancel();
//         return;
//       }
//
//       if (_isInitialized && _isLocalUserJoined) {
//         _optimizeMediaConfigurations();
//       }
//     });
//   }
//
//   Future<void> _initializeCall() async {
//     try {
//       setState(() {
//         _isConnecting = true; // Show connecting UI
//       });
//
//       // Request permissions first - most important step!
//       final bool permissionsGranted = await _requestPermissions();
//       if (!permissionsGranted) {
//         // If permissions not granted, show a message but allow the user to try again
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text("Call cannot start without required permissions"),
//               action: SnackBarAction(
//                 label: "Try Again",
//                 onPressed: () => _initializeCall(),
//               ),
//             ),
//           );
//         }
//         return;
//       }
//
//       // Create and initialize the Agora engine
//       final bool engineInitialized = await _createEngine();
//       if (!engineInitialized || _agoraEngine == null) {
//         if (mounted) {
//           _showErrorDialog(
//             'Engine Initialization Failed',
//             'Could not initialize the call engine. Please try again later.',
//           );
//         }
//         return;
//       }
//
//       // Configure event handlers
//       _setupEventHandlers();
//
//       // Configure audio/video settings based on call type
//       await _configureMediaSettings();
//
//       // Finally join the channel
//       final bool joinedChannel = await _joinChannel();
//       if (!joinedChannel) {
//         if (mounted) {
//           _showErrorDialog(
//             'Failed to Join Call',
//             'Could not connect to the call. Please check your internet connection and try again.',
//           );
//         }
//         return;
//       }
//
//       // Start call timer
//       _startCallTimer();
//
//       // Record connection time
//       _lastSuccessfulConnectionTime = DateTime.now();
//
//       // Mark as initialized, but still waiting for remote user
//       setState(() {
//         _isInitialized = true;
//         _isConnecting = false; // Done with initial connection, now waiting for remote user
//       });
//     } catch (e) {
//       print('Call initialization error: $e');
//       if (mounted) {
//         _showErrorDialog('Setup Error', 'An error occurred while setting up the call: $e');
//       }
//     }
//   }
//
//   Future<T?> _safeAsyncOperation<T>(Future<T> Function() operation, String errorMessage, {T? defaultValue}) async {
//     try {
//       return await operation();
//     } catch (e) {
//       print('$errorMessage: $e');
//       _showSystemMessage(errorMessage);
//       return defaultValue;
//     }
//   }
//
//   Future<bool> _requestPermissions() async {
//     print('Requesting permissions...');
//
//     try {
//       // First check current status
//       final micStatus = await Permission.microphone.status;
//       final camStatus = (_isVideoCallActive)
//           ? await Permission.camera.status
//           : PermissionStatus.granted;
//
//       // If already granted, return true
//       if (micStatus.isGranted && camStatus.isGranted) {
//         print('Permissions already granted');
//         return true;
//       }
//
//       // Request permissions
//       final Map<Permission, PermissionStatus> statuses = await [
//         Permission.microphone,
//         if (_isVideoCallActive) Permission.camera,
//       ].request();
//
//       bool allGranted = true;
//       List<String> deniedPermissions = [];
//
//       if (statuses[Permission.microphone] != PermissionStatus.granted) {
//         allGranted = false;
//         deniedPermissions.add('Microphone');
//         print('Microphone permission denied');
//       }
//
//       if (_isVideoCallActive && statuses[Permission.camera] != PermissionStatus.granted) {
//         allGranted = false;
//         deniedPermissions.add('Camera');
//         print('Camera permission denied');
//       }
//
//       if (!allGranted) {
//         print('Some permissions were denied: $deniedPermissions');
//         _showPermissionDialog(deniedPermissions);
//         return false;
//       }
//
//       print('All permissions granted');
//       return true;
//     } catch (e) {
//       print('Error requesting permissions: $e');
//       return false;
//     }
//   }
//
//   void _showPermissionDialog(List<String> deniedPermissions) {
//     if (!mounted) return;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Permissions Required'),
//         content: Text('${deniedPermissions.join(', ')} permission(s) are required for the call. '
//             'The app may not function properly without these permissions.'),
//         actions: [
//           TextButton(
//             onPressed: () async {
//               Navigator.pop(context);
//               await openAppSettings();
//             },
//             child: const Text('Open Settings'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text('Continue Anyway'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<bool> _createEngine() async {
//     try {
//       print('Creating Agora engine...');
//
//       if (_agoraEngine != null) {
//         print('Engine already exists, releasing first');
//         await _agoraEngine?.release();
//         _agoraEngine = null;
//       }
//
//       // Create an instance of the Agora engine with timeout protection
//       _agoraEngine = createAgoraRtcEngine();
//
//       // Use a timeout to prevent hanging on initialization
//       bool initialized = await _safeAsyncOperation(
//               () async {
//             await _agoraEngine?.initialize(const RtcEngineContext(
//               appId: appId,
//               channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
//               // Add additional params for better performance
//               // areaCode: AreaCode.areaCodeGlob,
//             )).timeout(const Duration(seconds: 10));
//             return true;
//           },
//           'Engine initialization timed out',
//           defaultValue: false
//       ) ?? false;
//
//       if (initialized) {
//         print('Agora engine created and initialized successfully');
//       } else {
//         print('Failed to initialize Agora engine');
//         _agoraEngine = null;
//       }
//
//       return initialized;
//     } catch (e) {
//       print('Agora engine creation error: $e');
//       _agoraEngine = null;
//       return false;
//     }
//   }
//
//   void _setupEventHandlers() {
//     if (_agoraEngine == null) return;
//
//     try {
//       _agoraEngine!.registerEventHandler(
//         RtcEngineEventHandler(
//           onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//             print('🟢 Local user joined - UID: 0, Channel: ${connection.channelId}, Elapsed: ${elapsed}ms');
//             if (mounted) {
//               setState(() {
//                 _isLocalUserJoined = true;
//                 _isConnecting = false; // No longer connecting, waiting for remote
//               });
//             }
//             _showSystemMessage('Connected to call');
//             _lastSuccessfulConnectionTime = DateTime.now();
//           },
//
//           onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//             print('🟢 Remote user joined - UID: $remoteUid, Channel: ${connection.channelId}');
//
//             if (mounted) {
//               setState(() {
//                 _remoteUid = remoteUid;
//                 _isRemoteUserJoined = true;
//                 _isConnecting = false; // Remote user joined, call is connected
//               });
//             }
//
//             _showSystemMessage('${widget.contactName} joined the call');
//             _lastSuccessfulConnectionTime = DateTime.now();
//
//             // Set initial remote video stream type based on network
//             if (_isVideoCallActive && _networkQuality != null && _networkQuality! > 3) {
//               _agoraEngine!.setRemoteVideoStreamType(
//                 uid: remoteUid,
//                 streamType: VideoStreamType.videoStreamLow,
//               );
//             }
//           },
//
//           onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
//             print('🔴 Remote user offline: $remoteUid, reason: $reason, Channel: ${connection.channelId}');
//
//             if (mounted) {
//               setState(() {
//                 _remoteUid = null;
//                 _isRemoteUserJoined = false;
//               });
//             }
//
//             // Auto end call if remote user leaves
//             if (reason != UserOfflineReasonType.userOfflineBecomeAudience) {
//               _showSystemMessage('Call ended by ${widget.contactName}');
//               Future.delayed(const Duration(seconds: 2), () {
//                 _endCall();
//               });
//             }
//           },
//
//           onAudioVolumeIndication: (connection, speakers, totalVolume, s) {
//             if (speakers.isEmpty) return;
//
//             // Efficient UI updates with debouncing
//             if (!_resourceManager.shouldUpdateUI()) return;
//
//             // Check for speaking users
//             if (mounted) {
//               setState(() {
//                 // Reset speaking states by default
//                 bool foundLocalSpeaking = false;
//                 bool foundRemoteSpeaking = false;
//
//                 for (var speaker in speakers) {
//                   if ((speaker.volume ?? 0) > 50) { // Threshold for speaking
//                     if (speaker.uid == 0) {
//                       // Local user speaking
//                       foundLocalSpeaking = true;
//                       _isLocalUserSpeaking = true;
//
//                       // Cancel previous timer
//                       _speakingTimers[0]?.cancel();
//
//                       // Set timer to reset speaking state
//                       _speakingTimers[0] = Timer(const Duration(milliseconds: 800), () {
//                         if (mounted) setState(() => _isLocalUserSpeaking = false);
//                       });
//                     } else if (speaker.uid == _remoteUid) {
//                       // Remote user speaking
//                       foundRemoteSpeaking = true;
//                       _isRemoteUserSpeaking = true;
//
//                       // Cancel previous timer
//                       _speakingTimers[_remoteUid ?? 0]?.cancel();
//
//                       // Set timer to reset speaking state
//                       _speakingTimers[_remoteUid ?? 0] = Timer(const Duration(milliseconds: 800), () {
//                         if (mounted) setState(() => _isRemoteUserSpeaking = false);
//                       });
//                     }
//                   }
//                 }
//
//                 // If not found in speakers, keep the reset
//                 if (!foundLocalSpeaking) {
//                   _isLocalUserSpeaking = false;
//                 }
//                 if (!foundRemoteSpeaking) {
//                   _isRemoteUserSpeaking = false;
//                 }
//               });
//             }
//           },
//
//           onNetworkQuality: (RtcConnection connection, int uid, QualityType txQuality, QualityType rxQuality) {
//             // Only update if there's a significant change to reduce state updates
//             if (_networkQuality != rxQuality.index && mounted) {
//               setState(() => _networkQuality = rxQuality.index);
//
//               // Track number of consecutive poor network quality updates
//               if (rxQuality.index >= 4) { // Poor quality
//                 _consecutivePoorNetworkUpdates++;
//                 if (_consecutivePoorNetworkUpdates >= 3 && !_isUsingLowerVideoQuality) {
//                   // After 3 consecutive poor quality updates, lower video quality
//                   _reducedVideoQuality();
//                 }
//               } else if (rxQuality.index <= 2) { // Good quality
//                 _consecutivePoorNetworkUpdates = 0;
//                 if (_isUsingLowerVideoQuality) {
//                   // If network is good again, restore quality after a delay
//                   Future.delayed(const Duration(seconds: 5), () {
//                     if (_networkQuality != null && _networkQuality! <= 2) {
//                       _restoreVideoQuality();
//                     }
//                   });
//                 }
//               }
//
//               // Adjust video quality based on network conditions
//               // Only do this periodically to avoid too many encoder changes
//               if (_lastNetworkQualityUpdate == null ||
//                   DateTime.now().difference(_lastNetworkQualityUpdate!).inSeconds > 5) {
//                 _lastNetworkQualityUpdate = DateTime.now();
//                 _optimizeMediaConfigurations();
//               }
//             }
//
//             // Update last successful connection time on any quality update
//             _lastSuccessfulConnectionTime = DateTime.now();
//           },
//
//           onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
//             print('🔷 Connection state changed: $state, reason: $reason, Channel: ${connection.channelId}');
//
//             if (state == ConnectionStateType.connectionStateReconnecting) {
//               if (mounted) {
//                 setState(() {
//                   _isReconnecting = true;
//                 });
//               }
//               _showSystemMessage('Connection lost. Reconnecting...');
//
//               // Adjust performance mode during reconnection
//               _resourceManager.setHighPerformanceMode(false);
//             } else if (state == ConnectionStateType.connectionStateConnected) {
//               if (_isReconnecting) {
//                 _showSystemMessage('Successfully reconnected');
//               }
//               if (mounted) {
//                 setState(() {
//                   _isReconnecting = false;
//                   _isRecoveringConnection = false;
//                 });
//               }
//
//               // Restore performance mode
//               _resourceManager.setHighPerformanceMode(true);
//
//               // Update last successful connection time
//               _lastSuccessfulConnectionTime = DateTime.now();
//             } else if (state == ConnectionStateType.connectionStateFailed) {
//               // Try our custom reconnection if the built-in one fails
//               if (!_isRecoveringConnection) {
//                 _triggerConnectionRecovery();
//               }
//             }
//           },
//
//           onFirstRemoteVideoFrame: (connection, remoteUid, width, height, elapsed) {
//             // First video frame received - good point to ensure UI is optimal
//             if (mounted) {
//               setState(() {
//                 // Ensure controls are visible briefly when video starts
//                 _isControlsVisible = true;
//                 _startControlsAutoHideTimer();
//               });
//             }
//           },
//
//           onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
//             print('⚠️ Token will expire soon for channel: ${connection.channelId}');
//             // You would typically request a new token from your server here
//             _showSystemMessage('Call session expiring soon');
//           },
//
//           onError: (err, msg) {
//             try {
//               print('❌ Agora error: $err, message: $msg');
//
//               // Handle known error codes
//               if (err == ErrorCodeType.errOk) {
//                 // Not an error, just a success message
//                 return;
//               }
//
//               // Show error dialog for serious errors only
//               if (err.index >= 1) {
//                 _showErrorDialog('Call Error', 'Error code: ${err.name}\n$msg');
//               }
//             } catch (e) {
//               // Handle unknown error codes (like 1052)
//               print('⚠️ Unknown Agora error: $err, message: $msg');
//
//               // Don't show dialogs for every error, only critical ones
//               if (err.value() < 0) { // Negative errors are typically more critical
//                 _showErrorDialog('Call Error', 'Error code: $err\n$msg');
//               }
//             }
//           },
//         ),
//       );
//       print('Event handlers set up successfully');
//     } catch (e) {
//       print('Error setting up event handlers: $e');
//     }
//   }
//
//   Future<void> _configureMediaSettings() async {
//     if (_agoraEngine == null) return;
//
//     try {
//       print('Configuring media settings...');
//
//       // Set client role before other configurations
//       await _safeAsyncOperation(
//               () => _agoraEngine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster),
//           'Could not set client role, using default'
//       );
//
//       // Configure audio settings with fallback
//       await _safeAsyncOperation(
//               () => _agoraEngine!.setAudioProfile(
//             profile: AudioProfileType.audioProfileMusicHighQuality,
//             scenario: AudioScenarioType.audioScenarioChatroom,
//           ),
//           'Could not set audio profile, using default'
//       );
//
//       // Enable echo cancellation and noise suppression for better audio quality
//       await _safeAsyncOperation(
//               () => _agoraEngine!.setParameters('{"che.audio.enable.aec": true}'),
//           'Could not enable echo cancellation'
//       );
//
//       await _safeAsyncOperation(
//               () => _agoraEngine!.setParameters('{"che.audio.enable.ns": true}'),
//           'Could not enable noise suppression'
//       );
//
//       // Set initial speaker state based on call type
//       bool speakerState = _isVideoCallActive;
//       bool success = await _safeAsyncOperation(
//               () async {
//             await _agoraEngine!.setEnableSpeakerphone(speakerState);
//             return true;
//           },
//           'Could not set speaker state',
//           defaultValue: false
//       ) ?? false;
//
//       setState(() => _isSpeakerOn = success ? speakerState : false);
//
//       // Configure video settings if this is a video call
//       if (_isVideoCallActive) {
//         try {
//           // Enable video processing
//           await _agoraEngine!.enableVideo();
//           print('Video enabled');
//
//           // Try to configure video encoder
//           bool encoderConfigured = await _safeAsyncOperation(
//                   () async {
//                 await _agoraEngine!.setVideoEncoderConfiguration(
//                   VideoEncoderConfiguration(
//                     dimensions: const VideoDimensions(width: 640, height: 480),
//                     frameRate: 15,
//                     bitrate: 1000,
//                     orientationMode: OrientationMode.orientationModeAdaptive,
//                     degradationPreference: DegradationPreference.maintainQuality,
//                     mirrorMode: VideoMirrorModeType.videoMirrorModeAuto,
//                   ),
//                 );
//                 return true;
//               },
//               'Could not configure video encoder, using default settings',
//               defaultValue: false
//           ) ?? false;
//
//           // Enable local video
//           bool localVideoEnabled = await _safeAsyncOperation(
//                   () async {
//                 await _agoraEngine!.enableLocalVideo(true);
//                 return true;
//               },
//               'Could not enable local video',
//               defaultValue: false
//           ) ?? false;
//
//           setState(() => _isLocalVideoEnabled = localVideoEnabled);
//
//           // Start preview
//           await _safeAsyncOperation(
//                   () => _agoraEngine!.startPreview(),
//               'Could not start preview'
//           );
//
//           // Enable dual stream mode for bandwidth adaptation
//           await _safeAsyncOperation(
//                   () => _agoraEngine!.enableDualStreamMode(enabled: true),
//               'Could not enable dual stream mode'
//           );
//
//           // Set video smoothness over sharpness for better performance
//           await _safeAsyncOperation(
//                   () => _agoraEngine!.setParameters('{"che.video.lowBitRateStreamParameter": {"width":160,"height":120,"frameRate":15,"bitRate":120}}'),
//               'Could not set low bitrate parameters'
//           );
//
//           // Use hardware acceleration if available
//           await _safeAsyncOperation(
//                   () => _agoraEngine!.setParameters('{"che.video.enableHardwareEncoder": true}'),
//               'Could not enable hardware encoder'
//           );
//
//         } catch (e) {
//           print('Error configuring video: $e');
//           // If video setup fails, fall back to audio-only
//           setState(() => _isLocalVideoEnabled = false);
//           _showSystemMessage('Video unavailable. Falling back to audio-only call.');
//
//           // Try to disable video as fallback
//           await _safeAsyncOperation(
//                   () => _agoraEngine!.enableLocalVideo(false),
//               'Could not disable local video in fallback'
//           );
//         }
//       } else {
//         // Audio-only call
//         await _safeAsyncOperation(
//                 () async {
//               await _agoraEngine!.enableVideo();
//               await _agoraEngine!.enableLocalVideo(false);
//               return true;
//             },
//             'Could not configure audio-only mode'
//         );
//         setState(() => _isLocalVideoEnabled = false);
//       }
//
//       // Enable audio volume indication as a non-critical feature
//       await _safeAsyncOperation(
//               () => _agoraEngine!.enableAudioVolumeIndication(
//             interval: 500,
//             smooth: 3,
//             reportVad: true,
//           ),
//           'Could not enable audio volume indication'
//       );
//
//       print('Media settings configured successfully');
//     } catch (e) {
//       print('Error configuring media settings: $e');
//       _showSystemMessage('Error setting up call media. Some features may be limited.');
//     }
//   }
//
//   // Smooth video quality transitions
//   Future<void> _reducedVideoQuality() async {
//     if (_agoraEngine == null || !_isVideoCallActive || _isUsingLowerVideoQuality) return;
//
//     try {
//       print('Reducing video quality for smooth performance');
//
//       // Notify user
//       _showSystemMessage('Optimizing video for current network...');
//
//       // Set low quality configuration
//       await _safeAsyncOperation(
//               () => _agoraEngine!.setVideoEncoderConfiguration(
//             VideoEncoderConfiguration(
//               dimensions: const VideoDimensions(width: 320, height: 240),
//               frameRate: 15,
//               bitrate: 400,
//               orientationMode: OrientationMode.orientationModeAdaptive,
//               degradationPreference: DegradationPreference.maintainFramerate,
//             ),
//           ),
//           'Failed to reduce video quality'
//       );
//
//       // Switch remote video to low stream
//       if (_remoteUid != null) {
//         await _safeAsyncOperation(
//                 () => _agoraEngine!.setRemoteVideoStreamType(
//               uid: _remoteUid!,
//               streamType: VideoStreamType.videoStreamLow,
//             ),
//             'Failed to set low stream'
//         );
//       }
//
//       setState(() {
//         _isUsingLowerVideoQuality = true;
//       });
//     } catch (e) {
//       print('Error reducing video quality: $e');
//     }
//   }
//
//   Future<void> _restoreVideoQuality() async {
//     if (_agoraEngine == null || !_isVideoCallActive || !_isUsingLowerVideoQuality) return;
//
//     try {
//       print('Restoring video quality');
//
//       // Set higher quality configuration
//       await _safeAsyncOperation(
//               () => _agoraEngine!.setVideoEncoderConfiguration(
//             VideoEncoderConfiguration(
//               dimensions: const VideoDimensions(width: 640, height: 480),
//               frameRate: 24,
//               bitrate: 1200,
//               orientationMode: OrientationMode.orientationModeAdaptive,
//               degradationPreference: DegradationPreference.maintainQuality,
//             ),
//           ),
//           'Failed to restore video quality'
//       );
//
//       // Switch remote video to high stream
//       if (_remoteUid != null) {
//         await _safeAsyncOperation(
//                 () => _agoraEngine!.setRemoteVideoStreamType(
//               uid: _remoteUid!,
//               streamType: VideoStreamType.videoStreamHigh,
//             ),
//             'Failed to set high stream'
//         );
//       }
//
//       setState(() {
//         _isUsingLowerVideoQuality = false;
//       });
//     } catch (e) {
//       print('Error restoring video quality: $e');
//     }
//   }
//
//   // Optimize media configurations for better performance
//   Future<void> _optimizeMediaConfigurations() async {
//     if (_agoraEngine == null) return;
//
//     try {
//       // Set appropriate video encoder settings based on network quality
//       if (_isVideoCallActive && _networkQuality != null) {
//         VideoEncoderConfiguration config;
//
//         // Adjust video quality based on network conditions
//         if (_networkQuality! <= 2) {
//           // Good network - higher quality
//           config = VideoEncoderConfiguration(
//             dimensions: const VideoDimensions(width: 640, height: 480),
//             frameRate: 24,
//             bitrate: 1200,
//             orientationMode: OrientationMode.orientationModeAdaptive,
//             degradationPreference: DegradationPreference.maintainQuality,
//           );
//         } else if (_networkQuality! <= 4) {
//           // Medium network - balanced quality
//           config = VideoEncoderConfiguration(
//             dimensions: const VideoDimensions(width: 480, height: 360),
//             frameRate: 15,
//             bitrate: 800,
//             orientationMode: OrientationMode.orientationModeAdaptive,
//             degradationPreference: DegradationPreference.maintainFramerate,
//           );
//         } else {
//           // Poor network - lower quality for stability
//           config = VideoEncoderConfiguration(
//             dimensions: const VideoDimensions(width: 320, height: 240),
//             frameRate: 15,
//             bitrate: 400,
//             orientationMode: OrientationMode.orientationModeAdaptive,
//             degradationPreference: DegradationPreference.maintainFramerate,
//           );
//         }
//
//         await _safeAsyncOperation(
//               () => _agoraEngine!.setVideoEncoderConfiguration(config),
//           'Failed to update video configuration',
//         );
//       }
//
//       // Enable/adjust dual stream mode based on network conditions
//       if (_isVideoCallActive) {
//         bool useDualStream = _networkQuality == null || _networkQuality! <= 4;
//
//         await _safeAsyncOperation(
//               () => _agoraEngine!.enableDualStreamMode(enabled: useDualStream),
//           'Failed to update dual stream mode',
//         );
//
//         // If dual stream is enabled and we have poor network, use low stream
//         if (useDualStream && _remoteUid != null && _networkQuality != null && _networkQuality! > 3) {
//           await _safeAsyncOperation(
//                 () => _agoraEngine!.setRemoteVideoStreamType(
//               uid: _remoteUid!,
//               streamType: VideoStreamType.videoStreamLow,
//             ),
//             'Failed to set remote video stream type',
//           );
//         }
//       }
//     } catch (e) {
//       print('Error optimizing media configurations: $e');
//     }
//   }
//
//   Future<bool> _joinChannel() async {
//     if (_agoraEngine == null) return false;
//
//     try {
//       print('Joining channel with user account...');
//
//       final String? tokenToUse = widget.token;
//       final String channelToJoin = widget.callId;
//       final String userAccount = widget.contactId;
//
//       print('Attempting to join channel: $channelToJoin with user account: $userAccount');
//
//       // Create mappings for user tracking
//       _userIdToUidMap[userAccount] = 0;
//       _uidToUserIdMap[0] = userAccount;
//
//       // First attempt to join
//       bool joined = false;
//       for (int attempt = 1; attempt <= 3; attempt++) {
//         try {
//           print('Join attempt $attempt');
//
//           // Join the channel
//           await _agoraEngine!.joinChannel(
//             token: tokenToUse ?? '',
//             channelId: channelToJoin,
//             uid: 0,
//             options: ChannelMediaOptions(
//               channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
//               clientRoleType: ClientRoleType.clientRoleBroadcaster,
//               publishCameraTrack: _isVideoCallActive,
//               publishMicrophoneTrack: true,
//               autoSubscribeAudio: true,
//               autoSubscribeVideo: _isVideoCallActive,
//             ),
//           ).timeout(const Duration(seconds: 15));
//
//           joined = true;
//           print('Successfully joined channel: $channelToJoin (attempt $attempt)');
//           break;
//         } catch (e) {
//           if (attempt < 3) {
//             print('Join attempt $attempt failed: $e. Retrying in 2 seconds...');
//             await Future.delayed(const Duration(seconds: 2));
//           } else {
//             print('All join attempts failed: $e');
//             throw e;
//           }
//         }
//       }
//
//       return joined;
//     } catch (e) {
//       print('Join channel error: $e');
//       return false;
//     }
//   }
//
//   void _startCallTimer() {
//     _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) {
//         setState(() => _callDuration++);
//       } else {
//         timer.cancel();
//       }
//     });
//   }
//
//   void _showSystemMessage(String message) {
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         duration: const Duration(seconds: 2),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: EdgeInsets.only(
//           bottom: MediaQuery.of(context).size.height - 150,
//           left: 20,
//           right: 20,
//         ),
//       ),
//     );
//   }
//
//   void _showErrorDialog(String title, String message) {
//     if (!mounted) return;
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // CALL CONTROL FUNCTIONS
//
//   Future<void> _toggleMute() async {
//     if (_agoraEngine == null) return;
//
//     try {
//       setState(() => _isMuted = !_isMuted);
//       await _agoraEngine!.muteLocalAudioStream(_isMuted);
//       print('Local audio ${_isMuted ? 'muted' : 'unmuted'}');
//     } catch (e) {
//       print('Error toggling mute: $e');
//       // Revert state change if operation failed
//       setState(() => _isMuted = !_isMuted);
//       _showSystemMessage('Failed to ${_isMuted ? 'unmute' : 'mute'} audio');
//     }
//   }
//
//   Future<void> _toggleSpeaker() async {
//     if (_agoraEngine == null) return;
//
//     try {
//       setState(() => _isSpeakerOn = !_isSpeakerOn);
//       await _agoraEngine!.setEnableSpeakerphone(_isSpeakerOn);
//       print('Speaker ${_isSpeakerOn ? 'enabled' : 'disabled'}');
//     } catch (e) {
//       print('Error toggling speaker: $e');
//       // Revert state change if operation failed
//       setState(() => _isSpeakerOn = !_isSpeakerOn);
//       _showSystemMessage('Failed to switch ${_isSpeakerOn ? 'to earpiece' : 'to speaker'}');
//     }
//   }
//
//   Future<void> _toggleLocalVideo() async {
//     if (_agoraEngine == null) return;
//
//     if (_isVideoCallActive) {
//       try {
//         setState(() => _isLocalVideoEnabled = !_isLocalVideoEnabled);
//         await _agoraEngine!.enableLocalVideo(_isLocalVideoEnabled);
//         await _agoraEngine!.muteLocalVideoStream(!_isLocalVideoEnabled);
//         print('Local video ${_isLocalVideoEnabled ? 'enabled' : 'disabled'}');
//       } catch (e) {
//         print('Error toggling video: $e');
//         // Revert state change if operation failed
//         setState(() => _isLocalVideoEnabled = !_isLocalVideoEnabled);
//         _showSystemMessage('Failed to ${_isLocalVideoEnabled ? 'disable' : 'enable'} video');
//       }
//     } else {
//       _showSystemMessage("This is an audio call");
//     }
//   }
//
//   Future<void> _switchCamera() async {
//     if (_agoraEngine == null) return;
//
//     if (_isVideoCallActive) {
//       try {
//         await _agoraEngine!.switchCamera();
//         setState(() => _isFrontCamera = !_isFrontCamera);
//         print('Camera switched to ${_isFrontCamera ? 'front' : 'rear'}');
//       } catch (e) {
//         print('Error switching camera: $e');
//         _showSystemMessage('Failed to switch camera');
//       }
//     }
//   }
//
//   // Switch between local and remote video in fullscreen (WhatsApp style)
//   void _swapLocalAndRemoteVideo() {
//     if (!_isVideoCallActive || !_isRemoteUserJoined) return;
//
//     setState(() {
//       _isLocalVideoFullScreen = !_isLocalVideoFullScreen;
//     });
//
//     _showSystemMessage(_isLocalVideoFullScreen
//         ? 'Switched to self view'
//         : 'Switched to ${widget.contactName}');
//
//     // Show controls temporarily
//     _showControls();
//   }
//
//   // New method for switching between audio and video
//   Future<void> _switchCallType() async {
//     if (_agoraEngine == null) return;
//
//     try {
//       // Show switching indicator
//       setState(() {
//         _isConnecting = true;
//       });
//
//       _showSystemMessage("Switching call mode...");
//
//       // Switching from audio to video
//       if (!_isVideoCallActive) {
//         // Check camera permission first
//         final camStatus = await Permission.camera.status;
//         if (!camStatus.isGranted) {
//           final status = await Permission.camera.request();
//           if (status != PermissionStatus.granted) {
//             _showSystemMessage("Camera permission required for video call");
//             setState(() => _isConnecting = false);
//             return;
//           }
//         }
//
//         // Enable video mode
//         await _agoraEngine!.enableVideo();
//         await _agoraEngine!.enableLocalVideo(true);
//
//         // Configure video encoder for proper rendering
//         await _agoraEngine!.setVideoEncoderConfiguration(
//           VideoEncoderConfiguration(
//             dimensions: const VideoDimensions(width: 640, height: 480),
//             frameRate: 15,
//             bitrate: 1000,
//             orientationMode: OrientationMode.orientationModeAdaptive,
//             degradationPreference: DegradationPreference.maintainQuality,
//           ),
//         );
//
//         // Start preview and update channel settings
//         await _agoraEngine!.startPreview();
//         await _agoraEngine!.enableDualStreamMode(enabled: true);
//
//         // Update media options
//         await _agoraEngine!.updateChannelMediaOptions(
//           ChannelMediaOptions(
//             publishCameraTrack: true,
//             publishMicrophoneTrack: true,
//             autoSubscribeAudio: true,
//             autoSubscribeVideo: true,
//           ),
//         );
//
//         // Enable speaker for video calls
//         await _agoraEngine!.setEnableSpeakerphone(true);
//
//         // Update state
//         setState(() {
//           _isVideoCallActive = true;
//           _isLocalVideoEnabled = true;
//           _isSpeakerOn = true;
//           _isConnecting = false;
//           _isLocalVideoFullScreen = false; // Reset to remote video as primary
//           _isControlsVisible = true; // Show controls
//         });
//
//         // Start control auto-hide timer
//         _startControlsAutoHideTimer();
//
//         _showSystemMessage("Switched to video call");
//       }
//       // Switching from video to audio
//       else {
//         // Disable video streaming and preview
//         await _agoraEngine!.disableVideo();
//         await _agoraEngine!.enableLocalVideo(false);
//         await _agoraEngine!.stopPreview();
//
//         // Update media options - disable video tracks
//         await _agoraEngine!.updateChannelMediaOptions(
//           ChannelMediaOptions(
//             publishCameraTrack: false,
//             publishMicrophoneTrack: true,
//             autoSubscribeAudio: true,
//             autoSubscribeVideo: false,
//           ),
//         );
//
//         // Switch to earpiece for audio calls
//         await _agoraEngine!.setEnableSpeakerphone(false);
//
//         // Update state
//         setState(() {
//           _isVideoCallActive = false;
//           _isLocalVideoEnabled = false;
//           _isSpeakerOn = false;
//           _isConnecting = false;
//           _isControlsVisible = true; // Always show controls for audio calls
//         });
//
//         // Cancel any auto-hide timer for controls
//         _controlsAutoHideTimer?.cancel();
//
//         _showSystemMessage("Switched to audio call");
//       }
//     } catch (e) {
//       print('Error switching call type: $e');
//       // Revert state in case of error
//       setState(() {
//         _isConnecting = false;
//       });
//       _showSystemMessage("Failed to switch call mode");
//     }
//   }
//
//   void _endCall() {
//     // Clean up and exit
//     print('Ending call and returning to previous screen');
//     Navigator.of(context).pop(); // Return to previous screen
//   }
//
//   void _confirmEndCall() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('End Call'),
//         content: const Text('Are you sure you want to end this call?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context); // Close dialog
//
//               // Leave Agora channel if available
//               _agoraEngine?.leaveChannel();
//               _agoraEngine?.release();
//               CallService().endCall();
//               // Return to previous screen
//               Navigator.of(context).pop();
//             },
//             child: const Text('End Call', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Memory management to prevent leaks
//   void _cleanupResources() {
//     // Cancel all timers
//     _callTimer?.cancel();
//     _callTimer = null;
//
//     _connectionWatchdog?.cancel();
//     _reconnectionAttemptTimer?.cancel();
//     _controlsAutoHideTimer?.cancel();
//
//     for (var timer in _speakingTimers.values) {
//       timer?.cancel();
//     }
//     _speakingTimers.clear();
//
//     // Clear cached data
//     _uidToUserIdMap.clear();
//     _userIdToUidMap.clear();
//   }
//
//   @override
//   void dispose() {
//     print('Disposing CallScreen');
//
//     WidgetsBinding.instance.removeObserver(this);
//     _cleanupResources();
//
//     // Clean up animation controller
//     try {
//       _speakingAnimationController.dispose();
//     } catch (e) {
//       print('Error disposing animation controller: $e');
//     }
//
//     // Clean up Agora engine with timeout protection
//     try {
//       if (_agoraEngine != null) {
//         _safeAsyncOperation(
//                 () => _agoraEngine!.leaveChannel().timeout(const Duration(seconds: 5)),
//             'Error leaving channel'
//         );
//
//         _safeAsyncOperation(
//                 () => _agoraEngine!.release().timeout(const Duration(seconds: 5)),
//             'Error releasing Agora engine'
//         );
//
//         _agoraEngine = null;
//         print('Agora engine released successfully');
//       }
//     } catch (e) {
//       print('Error during Agora cleanup: $e');
//     }
//
//     super.dispose();
//   }
//
//   String _formatDuration(int seconds) {
//     final int hours = seconds ~/ 3600;
//     final int minutes = (seconds % 3600) ~/ 60;
//     final int secs = seconds % 60;
//
//     if (hours > 0) {
//       return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//     } else {
//       return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//     }
//   }
//
//   Color _getNetworkQualityColor() {
//     switch (_networkQuality) {
//       case 1:
//         return Colors.green;
//       case 2:
//         return Colors.green.shade300;
//       case 3:
//         return Colors.yellow;
//       case 4:
//         return Colors.orange;
//       case 5:
//       case 6:
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   // Helper methods for network quality UI
//   IconData _getNetworkQualityIcon() {
//     switch (_networkQuality) {
//       case 1:
//         return Icons.network_wifi;
//       case 2:
//         return Icons.network_wifi;
//       case 3:
//         return Icons.network_wifi;
//       case 4:
//       case 5:
//       case 6:
//         return Icons.signal_wifi_statusbar_connected_no_internet_4;
//       default:
//         return Icons.signal_wifi_statusbar_null;
//     }
//   }
//
//   String _getNetworkQualityText() {
//     switch (_networkQuality) {
//       case 1:
//         return "Excellent";
//       case 2:
//         return "Good";
//       case 3:
//         return "Fair";
//       case 4:
//         return "Poor";
//       case 5:
//       case 6:
//         return "Very poor";
//       default:
//         return "Unknown";
//     }
//   }
//
//   // UI BUILDING METHODS
//
//   @override
//   Widget build(BuildContext context) {
//     // Screen dimensions
//     final Size screenSize = MediaQuery.of(context).size;
//
//     return Scaffold(
//       backgroundColor: Colors.black87,
//       body: WillPopScope(
//         onWillPop: () async {
//           // Show confirm dialog before exiting
//           _confirmEndCall();
//           return false;
//         },
//         child: GestureDetector(
//           onTap: () {
//             if (_isVideoCallActive && _isRemoteUserJoined) {
//               _showControls();
//             }
//           },
//           child: SafeArea(
//             child: Stack(
//               fit: StackFit.expand,
//               children: [
//                 // Main content with animated transition between audio/video modes
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   child: _getMainContent(),
//                 ),
//
//                 // Reconnecting overlay with fade animation
//                 AnimatedOpacity(
//                   opacity: _isReconnecting ? 1.0 : 0.0,
//                   duration: const Duration(milliseconds: 300),
//                   child: _isReconnecting ? _buildReconnectingOverlay() : const SizedBox.shrink(),
//                 ),
//
//                 // Status Bar with professional layout (always at top)
//                 AnimatedPositioned(
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeInOut,
//                   top: _isVideoCallActive && !_isControlsVisible ? -80 : 0,
//                   left: 0,
//                   right: 0,
//                   child: _buildStatusBar(),
//                 ),
//
//                 // Local Video Preview (when remote video is fullscreen)
//                 if (_isVideoCallActive && _isLocalUserJoined && !_isLocalVideoFullScreen && _remoteUid != null)
//                   AnimatedPositioned(
//                     duration: const Duration(milliseconds: 300),
//                     right: 16,
//                     top: 80,
//                     child: GestureDetector(
//                       onTap: _swapLocalAndRemoteVideo,
//                       child: _buildLocalVideoPreview(),
//                     ),
//                   ),
//
//                 // Call Controls with slide-up animation (at bottom)
//                 AnimatedPositioned(
//                   duration: const Duration(milliseconds: 300),
//                   curve: Curves.easeOut,
//                   left: 0,
//                   right: 0,
//                   bottom: (_isControlsVisible || !_isVideoCallActive) ? 40 : -100,
//                   child: _buildControlButtons(),
//                 ),
//
//                 // Mode switching overlay
//                 if (_isConnecting && _isInitialized)
//                   _buildModeSwitchingOverlay(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Helper method to return the appropriate main content
//   Widget _getMainContent() {
//     if (!_isInitialized || _isConnecting) {
//       return _buildConnectingView();
//     } else if (_isRemoteUserJoined) {
//       // Remote user has joined - show their video or audio view
//       if (_isVideoCallActive) {
//         if (_isLocalVideoFullScreen) {
//           // Show local video in full screen with remote video in PIP
//           return _buildLocalVideoMainView();
//         } else {
//           // Show remote video in full screen with local video in PIP
//           return _buildRemoteVideoMainView();
//         }
//       } else {
//         return _buildAudioCallUI();
//       }
//     } else {
//       // Connected but waiting for remote user
//       return _buildWaitingForRemoteView();
//     }
//   }
//
//   // Build the local video as main view with remote video in PIP
//   Widget _buildLocalVideoMainView() {
//     if (_agoraEngine == null) return const SizedBox.shrink();
//
//     return Stack(
//       children: [
//         // Main video (local)
//         AgoraVideoView(
//           controller: VideoViewController(
//             rtcEngine: _agoraEngine!,
//             canvas: const VideoCanvas(uid: 0),
//           ),
//         ),
//
//         // Bottom gradient for controls visibility
//         Positioned(
//           left: 0,
//           right: 0,
//           bottom: 0,
//           height: 150,
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.transparent,
//                   Colors.black.withOpacity(0.7),
//                 ],
//               ),
//             ),
//           ),
//         ),
//
//         // Remote video in PIP
//         if (_remoteUid != null)
//           Positioned(
//             right: 16,
//             top: 80,
//             child: GestureDetector(
//               onTap: _swapLocalAndRemoteVideo,
//               child: Container(
//                 width: 120,
//                 height: 180,
//                 decoration: BoxDecoration(
//                   color: Colors.black,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: _isRemoteUserSpeaking
//                         ? Colors.green.withOpacity(0.7)
//                         : Colors.white30,
//                     width: _isRemoteUserSpeaking ? 2 : 1,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.5),
//                       blurRadius: 10,
//                       spreadRadius: 2,
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(11),
//                   child: AgoraVideoView(
//                     controller: VideoViewController.remote(
//                       rtcEngine: _agoraEngine!,
//                       canvas: VideoCanvas(uid: _remoteUid),
//                       connection: RtcConnection(channelId: widget.callId),
//                       useFlutterTexture: true,
//                       useAndroidSurfaceView: true,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }
//
//   // Build the remote video as main view with local video in PIP
//   Widget _buildRemoteVideoMainView() {
//     if (_remoteUid == null || _agoraEngine == null) {
//       return _buildWaitingForRemoteView();
//     }
//
//     return Stack(
//       children: [
//         // Main video view - remote video
//         AgoraVideoView(
//           controller: VideoViewController.remote(
//             rtcEngine: _agoraEngine!,
//             canvas: VideoCanvas(uid: _remoteUid),
//             connection: RtcConnection(channelId: widget.callId),
//             useFlutterTexture: true,
//             useAndroidSurfaceView: true,
//           ),
//         ),
//
//         // Bottom gradient overlay for better visibility of controls
//         Positioned(
//           left: 0,
//           right: 0,
//           bottom: 0,
//           height: 150,
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.transparent,
//                   Colors.black.withOpacity(0.7),
//                 ],
//               ),
//             ),
//           ),
//         ),
//
//         // Top gradient overlay for better visibility of status bar
//         Positioned(
//           left: 0,
//           right: 0,
//           top: 0,
//           height: 80,
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.bottomCenter,
//                 end: Alignment.topCenter,
//                 colors: [
//                   Colors.transparent,
//                   Colors.black.withOpacity(0.7),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // New overlay for mode switching
//   Widget _buildModeSwitchingOverlay() {
//     return Container(
//       color: Colors.black87.withOpacity(0.7),
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               _isVideoCallActive
//                   ? "Switching to video call..."
//                   : "Switching to audio call...",
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildConnectingView() {
//     return Container(
//       color: Colors.black87,
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Animated connecting indicator
//             SizedBox(
//               width: 100,
//               height: 100,
//               child: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   // Pulsating circle animation
//                   TweenAnimationBuilder<double>(
//                     tween: Tween<double>(begin: 0.0, end: 1.0),
//                     duration: const Duration(seconds: 2),
//                     builder: (context, value, child) {
//                       return Opacity(
//                         opacity: 1.0 - value,
//                         child: Transform.scale(
//                           scale: 1.0 + value * 0.5,
//                           child: Container(
//                             width: 100,
//                             height: 100,
//                             decoration: BoxDecoration(
//                               color: Colors.blue.withOpacity(0.3),
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                     onEnd: () {
//                       // Rebuild to restart animation
//                       if (mounted && (_isConnecting || !_isInitialized)) {
//                         setState(() {});
//                       }
//                     },
//                   ),
//
//                   // Main indicator
//                   const CircularProgressIndicator(
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     strokeWidth: 3,
//                   ),
//
//                   // Center icon
//                   Icon(
//                     _isVideoCallActive ? Icons.videocam : Icons.phone,
//                     color: Colors.white,
//                     size: 30,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),
//             Text(
//               widget.isIncoming
//                   ? "Incoming call from ${widget.contactName}..."
//                   : "Connecting to ${widget.contactName}...",
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             if (!_isInitialized)
//               ElevatedButton.icon(
//                 onPressed: _initializeCall,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text("Retry"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//               )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildWaitingForRemoteView() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.blue.shade900, Colors.black],
//         ),
//       ),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircleAvatar(
//               radius: 70,
//               backgroundColor: Colors.grey.shade800,
//               backgroundImage: widget.contactAvatar.isNotEmpty
//                   ? NetworkImage(widget.contactAvatar)
//                   : null,
//               child: widget.contactAvatar.isEmpty
//                   ? const Icon(Icons.person, size: 70, color: Colors.white)
//                   : null,
//             ),
//             const SizedBox(height: 24),
//             Text(
//               "Calling ${widget.contactName}...",
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 24,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white10,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 _isVideoCallActive ? "Video Call" : "Audio Call",
//                 style: const TextStyle(
//                   color: Colors.white70,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 40),
//             // Animated waiting indicator
//             SizedBox(
//               width: 60,
//               height: 20,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(3, (index) {
//                   return TweenAnimationBuilder<double>(
//                     tween: Tween<double>(begin: 0.0, end: 1.0),
//                     duration: Duration(milliseconds: 400 + (index * 200)),
//                     builder: (context, value, child) {
//                       return Container(
//                         margin: const EdgeInsets.symmetric(horizontal: 3),
//                         width: 10,
//                         height: 10 * value,
//                         decoration: BoxDecoration(
//                           color: Colors.white70,
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       );
//                     },
//                     onEnd: () {
//                       if (mounted && !_isRemoteUserJoined) {
//                         setState(() {});
//                       }
//                     },
//                   );
//                 }),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAudioCallUI() {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.blue.shade900, Colors.black],
//         ),
//       ),
//       child: Stack(
//         children: [
//           // Background pattern for audio calls
//           Opacity(
//             opacity: 0.05,
//             child: CustomPaint(
//               size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
//               painter: AudioWaveformPainter(),
//             ),
//           ),
//
//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Contact avatar with speaking animation
//                 AnimatedBuilder(
//                   animation: _speakingAnimationController,
//                   builder: (context, child) {
//                     return Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         // Animated speaking indicator
//                         if (_isRemoteUserSpeaking)
//                           ...List.generate(3, (index) {
//                             return TweenAnimationBuilder<double>(
//                               tween: Tween<double>(begin: 0.0, end: 1.0),
//                               duration: Duration(milliseconds: 1500 + index * 300),
//                               builder: (context, value, child) {
//                                 return Opacity(
//                                   opacity: (1.0 - value) * 0.5,
//                                   child: Transform.scale(
//                                     scale: 1.0 + value * 0.8,
//                                     child: Container(
//                                       width: 150,
//                                       height: 150,
//                                       decoration: BoxDecoration(
//                                         color: Colors.green.withOpacity(0.4),
//                                         shape: BoxShape.circle,
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                               onEnd: () {
//                                 if (mounted && _isRemoteUserSpeaking) {
//                                   setState(() {});
//                                 }
//                               },
//                             );
//                           }),
//
//                         // Avatar container
//                         Container(
//                           padding: const EdgeInsets.all(4),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(
//                               color: _isRemoteUserSpeaking
//                                   ? Colors.green.withOpacity(0.7)
//                                   : Colors.white24,
//                               width: _isRemoteUserSpeaking ? 3 : 1,
//                             ),
//                           ),
//                           child: CircleAvatar(
//                             radius: 70,
//                             backgroundColor: Colors.grey.shade800,
//                             backgroundImage: widget.contactAvatar.isNotEmpty
//                                 ? NetworkImage(widget.contactAvatar)
//                                 : null,
//                             child: widget.contactAvatar.isEmpty
//                                 ? const Icon(Icons.person, size: 70, color: Colors.white)
//                                 : null,
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//
//                 const SizedBox(height: 30),
//                 Text(
//                   widget.contactName,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(
//                         Icons.phone,
//                         color: Colors.white70,
//                         size: 16,
//                       ),
//                       const SizedBox(width: 8),
//                       Text(
//                         "In call · ${_formatDuration(_callDuration)}",
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReconnectingOverlay() {
//     return Container(
//       color: Colors.black54,
//       child: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               "Reconnecting...",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               "Please wait",
//               style: TextStyle(
//                 color: Colors.white70,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Status bar at the top of the screen with call info
//   Widget _buildStatusBar() {
//     return Container(
//       height: 60,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: _isVideoCallActive
//             ? Colors.transparent
//             : Colors.black45,
//         boxShadow: _isVideoCallActive
//             ? []
//             : [BoxShadow(
//           color: Colors.black26,
//           blurRadius: 4,
//           spreadRadius: 1,
//         )],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           // Contact info
//           Row(
//             children: [
//               // Small avatar
//               if (!_isVideoCallActive || !_isRemoteUserJoined)
//                 Container(
//                   width: 40,
//                   height: 40,
//                   margin: const EdgeInsets.only(right: 10),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     image: widget.contactAvatar.isNotEmpty
//                         ? DecorationImage(
//                       image: NetworkImage(widget.contactAvatar),
//                       fit: BoxFit.cover,
//                     )
//                         : null,
//                     color: widget.contactAvatar.isEmpty ? Colors.grey.shade800 : null,
//                   ),
//                   child: widget.contactAvatar.isEmpty
//                       ? const Icon(Icons.person, size: 20, color: Colors.white)
//                       : null,
//                 ),
//
//               // Name and call type
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     widget.contactName,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Row(
//                     children: [
//                       Icon(
//                         _isVideoCallActive ? Icons.videocam : Icons.phone,
//                         color: Colors.white70,
//                         size: 14,
//                       ),
//                       const SizedBox(width: 4),
//                       Text(
//                         "${_isVideoCallActive ? 'Video' : 'Audio'} call · ${_formatDuration(_callDuration)}",
//                         style: const TextStyle(
//                           color: Colors.white70,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ],
//           ),
//
//           // Network quality indicator
//           if (_networkQuality != null)
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//               decoration: BoxDecoration(
//                 color: Colors.black45,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Row(
//                 children: [
//                   Icon(
//                     _getNetworkQualityIcon(),
//                     color: _getNetworkQualityColor(),
//                     size: 14,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     _getNetworkQualityText(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildLocalVideoPreview() {
//     if (!_isVideoCallActive || _agoraEngine == null) return const SizedBox.shrink();
//
//     return Container(
//       width: 120,
//       height: 180,
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: _isLocalUserSpeaking
//               ? Colors.green.withOpacity(0.7)
//               : Colors.white30,
//           width: _isLocalUserSpeaking ? 2 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.5),
//             blurRadius: 10,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Stack(
//         fit: StackFit.expand,
//         children: [
//           // Video view or placeholder
//           ClipRRect(
//             borderRadius: BorderRadius.circular(11),
//             child: _isLocalVideoEnabled && _isLocalUserJoined
//                 ? AgoraVideoView(
//               controller: VideoViewController(
//                 rtcEngine: _agoraEngine!,
//                 canvas: const VideoCanvas(uid: 0),
//               ),
//             )
//                 : Container(
//               color: Colors.black54,
//               child: const Center(
//                 child: Icon(
//                   Icons.videocam_off,
//                   color: Colors.white70,
//                   size: 30,
//                 ),
//               ),
//             ),
//           ),
//
//           // Camera toggle indicator
//           Positioned(
//             bottom: 8,
//             right: 8,
//             child: Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: Colors.black54,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 _isFrontCamera ? Icons.camera_front : Icons.camera_rear,
//                 color: Colors.white,
//                 size: 16,
//               ),
//             ),
//           ),
//
//           // Speaking indicator
//           if (_isLocalUserSpeaking)
//             Positioned(
//               top: 8,
//               left: 8,
//               child: Container(
//                 padding: const EdgeInsets.all(4),
//                 decoration: BoxDecoration(
//                   color: Colors.green.withOpacity(0.7),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.mic,
//                   color: Colors.white,
//                   size: 16,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildControlButtons() {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       color: _isVideoCallActive ? Colors.transparent : Colors.black38,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // If video is active, show a light decorative line for better visibility
//           if (_isVideoCallActive)
//             Container(
//               height: 4,
//               width: 40,
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: Colors.white30,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               // Mute button
//               _buildCircleButton(
//                 onTap: _toggleMute,
//                 icon: _isMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic,
//                 label: "Mute",
//                 bgColor: _isMuted ? Colors.red : Colors.white24,
//               ),
//
//               // Switch call type button
//               _buildCircleButton(
//                 onTap: _switchCallType,
//                 icon: _isVideoCallActive ? Icons.phone : Icons.videocam,
//                 label: _isVideoCallActive ? "Audio" : "Video",
//                 bgColor: Colors.white24,
//               ),
//
//               // Speaker button
//               _buildCircleButton(
//                 onTap: _toggleSpeaker,
//                 icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
//                 label: "Speaker",
//                 bgColor: _isSpeakerOn ? Colors.white24 : Colors.white24,
//               ),
//
//               // Swap cameras button or switch view button
//               if (_isVideoCallActive)
//                 _buildCircleButton(
//                   onTap: _isRemoteUserJoined ? _swapLocalAndRemoteVideo : _switchCamera,
//                   icon: _isRemoteUserJoined ? Icons.swap_horiz : CupertinoIcons.camera_rotate,
//                   label: _isRemoteUserJoined ? "Swap" : "Flip",
//                   bgColor: Colors.white24,
//                 ),
//
//               // End call button
//               _buildCircleButton(
//                 onTap: _confirmEndCall,
//                 icon: Icons.call_end,
//                 label: "End",
//                 bgColor: Colors.red,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCircleButton({
//     required VoidCallback onTap,
//     required IconData icon,
//     required String label,
//     required Color bgColor,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: TweenAnimationBuilder<double>(
//         tween: Tween<double>(begin: 0.0, end: 1.0),
//         duration: const Duration(milliseconds: 300),
//         builder: (context, value, child) {
//           return Transform.scale(
//             scale: 0.8 + (0.2 * value),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   width: 56,
//                   height: 56,
//                   margin: const EdgeInsets.only(bottom: 8),
//                   decoration: BoxDecoration(
//                     color: bgColor,
//                     shape: BoxShape.circle,
//                     boxShadow: [
//                       BoxShadow(
//                         color: bgColor.withOpacity(0.5),
//                         blurRadius: 8,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                   child: Icon(
//                     icon,
//                     color: Colors.white,
//                     size: 26,
//                   ),
//                 ),
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
//
// // Enhanced Audio Waveform Painter for background
// class AudioWaveformPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1.0;
//
//     final path = Path();
//
//     // Create a simple audio waveform pattern
//     final double width = size.width;
//     final double height = size.height;
//     final double centerY = height / 2;
//
//     // Draw horizontal wave patterns
//     for (int i = 0; i < 10; i++) {
//       double offsetY = centerY + (i - 5) * 80;
//
//       path.moveTo(0, offsetY);
//
//       for (double x = 0; x < width; x += 10) {
//         path.lineTo(x, offsetY + 20 * math.sin(x / 50));
//       }
//     }
//
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
//
// // Resource manager for performance optimization
// class _ResourceManager {
//   bool _isHighPerformanceMode = true;
//   DateTime? _lastUIUpdate;
//
//   void setHighPerformanceMode(bool enabled) {
//     _isHighPerformanceMode = enabled;
//   }
//
//   bool shouldUpdateUI() {
//     final now = DateTime.now();
//     if (_lastUIUpdate == null ||
//         now.difference(_lastUIUpdate!).inMilliseconds > (_isHighPerformanceMode ? 16 : 100)) {
//       _lastUIUpdate = now;
//       return true;
//     }
//     return false;
//   }
// }