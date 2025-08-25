// lib/presentation/call_module/providers/call_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import '../models/call_state.dart';
import '../models/user_model.dart';
import '../services/agora_service.dart';
import '../services/call_api_service.dart';
import '../utils/resource_manager.dart';
import '../utils/call_debug_utils.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';

/// Main provider for call state management
class CallProvider extends ChangeNotifier {
  // Services
  final AgoraService _agoraService;
  final ResourceManager _resourceManager = ResourceManager();

  // Call state
  CallState _callState;
  CallState? _previousCallState;
  Timer? _performanceMonitor;

  // Background state
  bool _isInBackground = false;

  // User information
  final UserModel _localUser;
  final UserModel _remoteUser;

  // Timers
  Timer? _callTimer;
  Timer? _controlsAutoHideTimer;
  Map<int, Timer?> _speakingTimers = {};

  // Additional reconnection handling
  int _reconnectionAttempts = 0;
  bool _isRecoveringConnection = false;
  Timer? _connectionHealthTimer;
  Timer? _syncTimer;
  int _lastKnownConnectionState = -1;
  
  // Disposed state tracking
  bool _disposed = false;
  bool get mounted => !_disposed;

  // Add token field
  String? _channelToken;
  
  // Constructor
  CallProvider({
    required AgoraService agoraService,
    required String callId,
    required UserModel localUser,
    required UserModel remoteUser,
    required bool isVideoCall,
    String? token, // Add token parameter
  }) : _agoraService = agoraService,
        _localUser = localUser,
        _remoteUser = remoteUser,
        _channelToken = token,
        _callState = CallState(
          callId: callId,
          callType: isVideoCall ? CallType.video : CallType.audio,
        ) {
    // Log call initialization
    CallDebugUtils.logCallInitialization(
      callId: callId,
      localUserId: localUser.id,
      remoteUserId: remoteUser.id,
      isVideoCall: isVideoCall,
      isIncoming: false, // Will need to be passed as parameter if needed
    );
    
    // Start performance monitoring
    _performanceMonitor = CallDebugUtils.startPerformanceMonitoring(() => _callState);
  }

  // Getters
  CallState get callState => _callState;
  UserModel get localUser => _localUser;
  UserModel get remoteUser => _remoteUser;
  bool get isVideoCall => _callState.callType == CallType.video;
  bool get isConnected => _callState.connectionState == CallConnectionState.connected;
  bool get isReconnecting => _callState.connectionState == CallConnectionState.reconnecting;

  // Get Agora Engine (used in VideoView)
  RtcEngine? getAgoraEngine() {
    return _agoraService.getEngine();
  }

  // Generate or get Agora token for secure channel access
  Future<String> _getAgoraToken() async {
    // If we already have a token, use it
    if (_channelToken != null && _channelToken!.isNotEmpty) {
      print('✅ Using existing token (length: ${_channelToken!.length})');
      return _channelToken!;
    }

    try {
      print('🔑 Generating new Agora token for channel: ${_callState.callId}');
      
      // Create API service instance
      final apiService = CallApiService(baseUrl: AppData.remoteUrl3);
      
      // Generate token with 1 hour expiration
      final token = await apiService.generateAgoraToken(
        channelId: _callState.callId,
        uid: 0, // Use 0 to let Agora assign UID
        expirationTime: 3600, // 1 hour
      );

      if (token.isNotEmpty) {
        _channelToken = token;
        print('✅ Token generated and cached (length: ${token.length})');
        return token;
      } else {
        print('⚠️ Empty token received, using development mode');
        return '';
      }
    } catch (e) {
      print('❌ Failed to generate Agora token: $e');
      print('⚠️ Continuing with development mode (no token)');
      return '';
    }
  }

  // Initialize call
  // Future<void> initializeCall() async {
  //   try {
  //     // Initialize Agora service
  //     await _agoraService.initialize(
  //       onJoinChannelSuccess: _handleJoinChannelSuccess,
  //       onUserJoined: _handleUserJoined,
  //       onUserOffline: _handleUserOffline,
  //       onAudioVolumeIndication: _handleAudioVolumeIndication,
  //       onNetworkQuality: _handleNetworkQuality,
  //       onConnectionStateChanged: _handleConnectionStateChanged,
  //       onFirstRemoteVideoFrame: _handleFirstRemoteVideoFrame,
  //       onError: _handleError,
  //     );
  //
  //     // Configure for the specific call type
  //     await _agoraService.configureMediaSettings(isVideoCall: isVideoCall);
  //
  //     // Join channel - Make sure we use the correct channelId format and token
  //     final bool joined = await _agoraService.joinChannel(
  //       channelId: _callState.callId,
  //       uid: 0,
  //       token: '', // Add token if needed
  //       isVideoCall: isVideoCall,
  //     );
  //
  //     print('Joining channel: ${_callState.callId}');
  //
  //     if (joined) {
  //       _startCallTimer();
  //     } else {
  //       // Update state to failed
  //       _updateCallState(connectionState: CallConnectionState.failed);
  //     }
  //   } catch (e) {
  //     print('Call initialization error: $e');
  //     _updateCallState(connectionState: CallConnectionState.failed);
  //   }
  // }

  // Handle app going to background with platform-specific optimizations
  void handleAppBackground() {
    CallDebugUtils.logInfo('LIFECYCLE', 'App going to background on ${Platform.operatingSystem}');
    _isInBackground = true;

    // Platform-specific background handling
    if (Platform.isIOS) {
      // iOS background handling
      if (isVideoCall && _agoraService.isInitialized()) {
        // On iOS, pause video but keep audio active
        _agoraService.muteLocalVideoStream(true);
        _resourceManager.setHighPerformanceMode(false);
        
        // iOS specific: Enable background audio
        _agoraService.getEngine()?.setParameters('{"che.audio.keep_audiosession": true}');
      }
    } else {
      // Android background handling
      if (isVideoCall && _agoraService.isInitialized()) {
        _agoraService.muteLocalVideoStream(true);
        _resourceManager.setHighPerformanceMode(false);
      }
    }
  }

  // Handle app coming to foreground with platform-specific optimizations
  void handleAppForeground() {
    CallDebugUtils.logInfo('LIFECYCLE', 'App coming to foreground on ${Platform.operatingSystem}');
    _isInBackground = false;

    // Platform-specific foreground handling
    if (Platform.isIOS) {
      // iOS foreground handling
      if (isVideoCall && _agoraService.isInitialized() && _callState.isLocalVideoEnabled) {
        // Restore video with iOS-specific optimizations
        _agoraService.muteLocalVideoStream(false);
        _resourceManager.setHighPerformanceMode(true);
        
        // iOS specific: Reactivate camera if needed
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isInBackground) {
            _agoraService.getEngine()?.startPreview();
          }
        });
      }
    } else {
      // Android foreground handling
      if (isVideoCall && _agoraService.isInitialized() && _callState.isLocalVideoEnabled) {
        _agoraService.muteLocalVideoStream(false);
        _resourceManager.setHighPerformanceMode(true);
      }
    }

    // Check connection status with delay to allow network to stabilize
    if (_agoraService.isInitialized() && _callState.isLocalUserJoined) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) _checkConnectionStatus();
      });
    }
  }

  // Event handlers - updated to use new callback types
  void _handleJoinChannelSuccess(int uid, String channelId, int elapsed) {
    CallDebugUtils.logCallTimeline('LOCAL_USER_JOINED', data: {
      'uid': uid,
      'channelId': channelId,
      'elapsed': '${elapsed}ms',
    });
    
    _updateCallState(
      isLocalUserJoined: true,
      connectionState: CallConnectionState.connected,
    );
    
    // Initialize media state properly for both video and audio calls
    if (isVideoCall) {
      // Ensure video is enabled and preview is started
      _agoraService.enableLocalVideo(true);
      _agoraService.muteLocalVideoStream(false);
      CallDebugUtils.logDebug('MEDIA', 'Local video enabled for video call');
    }
    
    // Enable audio by default
    _agoraService.muteLocalAudioStream(false);
    CallDebugUtils.logDebug('MEDIA', 'Local audio enabled');
  }

  // void _handleUserJoined(int remoteUid, int elapsed) {
  //   _updateCallState(
  //     remoteUid: remoteUid,
  //     isRemoteUserJoined: true,
  //     connectionState: CallConnectionState.connected,
  //   );
  //
  //   if (isVideoCall) {
  //     _startControlsAutoHideTimer();
  //   }
  // }
  //
  // void _handleUserOffline(int remoteUid, int reason) {
  //   _updateCallState(
  //     remoteUid: null,
  //     isRemoteUserJoined: false,
  //   );
  //
  //   // Auto end call if remote user leaves
  //   Future.delayed(const Duration(seconds: 2), () {
  //     endCall();
  //   });
  // }

  void _handleAudioVolumeIndication(List<Map<String, dynamic>> speakers, int totalVolume) {
    if (speakers.isEmpty) return;

    // Efficient UI updates with debouncing
    if (!_resourceManager.shouldUpdateUI()) return;

    // Check for speaking users
    bool foundLocalSpeaking = false;
    bool foundRemoteSpeaking = false;

    for (var speaker in speakers) {
      final int uid = speaker['uid'] as int;
      final int volume = speaker['volume'] as int;

      if (volume > 50) { // Threshold for speaking
        if (uid == 0) {
          // Local user speaking
          foundLocalSpeaking = true;
          _handleSpeakingState(0, true);
        } else if (uid == _callState.remoteUid) {
          // Remote user speaking
          foundRemoteSpeaking = true;
          _handleSpeakingState(_callState.remoteUid!, true);
        }
      }
    }

    // If not found in speakers, reset
    if (!foundLocalSpeaking) {
      _updateCallState(isLocalUserSpeaking: false);
    }

    if (!foundRemoteSpeaking) {
      _updateCallState(isRemoteUserSpeaking: false);
    }
  }

  void _handleSpeakingState(int uid, bool isSpeaking) {
    // Safety check: don't proceed if disposed
    if (!mounted) return;
    
    // Cancel previous timer
    _speakingTimers[uid]?.cancel();
    _speakingTimers[uid] = null;

    // Update state based on UID
    if (uid == 0) {
      _updateCallState(isLocalUserSpeaking: true);
    } else {
      _updateCallState(isRemoteUserSpeaking: true);
    }

    // Set timer to reset speaking state
    _speakingTimers[uid] = Timer(const Duration(milliseconds: 800), () {
      // Safety check: only update if not disposed
      if (!mounted) return;
      
      if (uid == 0) {
        _updateCallState(isLocalUserSpeaking: false);
      } else {
        _updateCallState(isRemoteUserSpeaking: false);
      }
    });
  }

  void _handleNetworkQuality(int uid, int txQuality, int rxQuality) {
    // Only update if significant change and add debouncing to prevent rapid adjustments
    if (_callState.networkQuality != rxQuality) {
      _updateCallState(networkQuality: rxQuality);
      
      // Add delay to prevent rapid network quality adjustments that can disrupt calls
      Timer(const Duration(seconds: 3), () {
        if (mounted && _callState.networkQuality == rxQuality) {
          // Platform-specific network quality optimization (only if quality is still the same)
          if (Platform.isIOS) {
            _handleIOSNetworkQuality(rxQuality);
          } else {
            _handleAndroidNetworkQuality(rxQuality);
          }
        }
      });
    }
  }
  
  // iOS-specific network quality handling
  void _handleIOSNetworkQuality(int quality) {
    if (quality > 4 && isVideoCall && !_callState.isUsingLowerVideoQuality) {
      // Poor network on iOS - reduce video quality (only for very poor quality)
      CallDebugUtils.logWarning('NETWORK', 'Poor network on iOS, reducing video quality');
      _agoraService.getEngine()?.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 480, height: 360),  // Less aggressive reduction
          frameRate: 12,  // Maintain reasonable framerate
          bitrate: 600,   // Conservative bitrate
          orientationMode: OrientationMode.orientationModeAdaptive,
          degradationPreference: DegradationPreference.maintainFramerate,
        ),
      );
      _updateCallState(isUsingLowerVideoQuality: true);
    } else if (quality <= 2 && _callState.isUsingLowerVideoQuality) {
      // Network improved on iOS - restore video quality
      CallDebugUtils.logSuccess('NETWORK', 'Network improved on iOS, restoring video quality');
      _agoraService.getEngine()?.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 800,  // Slightly more conservative bitrate
          orientationMode: OrientationMode.orientationModeAdaptive,
          degradationPreference: DegradationPreference.maintainQuality,
        ),
      );
      _updateCallState(isUsingLowerVideoQuality: false);
    }
  }
  
  // Android-specific network quality handling
  void _handleAndroidNetworkQuality(int quality) {
    if (quality > 4 && isVideoCall && !_callState.isUsingLowerVideoQuality) {
      // Poor network on Android - prioritize framerate (only for very poor quality)
      CallDebugUtils.logWarning('NETWORK', 'Poor network on Android, prioritizing framerate');
      _agoraService.getEngine()?.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 480, height: 360),  // Less aggressive reduction
          frameRate: 12,  // Maintain reasonable framerate
          bitrate: 500,   // Conservative bitrate
          orientationMode: OrientationMode.orientationModeAdaptive,
          degradationPreference: DegradationPreference.maintainFramerate,
        ),
      );
      _updateCallState(isUsingLowerVideoQuality: true);
    } else if (quality <= 2 && _callState.isUsingLowerVideoQuality) {
      // Network improved on Android - restore video quality
      CallDebugUtils.logSuccess('NETWORK', 'Network improved on Android, restoring video quality');
      _agoraService.getEngine()?.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: 800,
          orientationMode: OrientationMode.orientationModeAdaptive,
          degradationPreference: DegradationPreference.maintainFramerate,
        ),
      );
      _updateCallState(isUsingLowerVideoQuality: false);
    }
  }

  void _handleConnectionStateChanged(int state, int reason) {
    print('🔄 Connection state changed: $state (reason: $reason)');
    _lastKnownConnectionState = state;
    
    // Add connection stability check - don't react to rapid state changes
    if (_callState.connectionState == CallConnectionState.connected && state == 2) {
      // If we just connected and immediately see connecting again, wait a moment
      print('ℹ️ Ignoring rapid CONNECTING state after CONNECTED - likely temporary');
      return;
    }
    
    switch (state) {
      case 2: // Connecting
        _updateCallState(connectionState: CallConnectionState.connecting);
        _stopConnectionHealthMonitoring();
        break;
      case 3: // Connected
        _updateCallState(connectionState: CallConnectionState.connected);
        _startConnectionHealthMonitoring();
        _resourceManager.setHighPerformanceMode(true);
        break;
      case 4: // Reconnecting
        print('🔄 Agora engine is reconnecting (reason: $reason)');
        _updateCallState(connectionState: CallConnectionState.reconnecting);
        _resourceManager.setHighPerformanceMode(false);
        _stopConnectionHealthMonitoring();
        break;
      case 5: // Failed
        print('❌ Connection failed (reason: $reason)');
        _updateCallState(connectionState: CallConnectionState.failed);
        _stopConnectionHealthMonitoring();
        break;
    }
  }

  void _handleFirstRemoteVideoFrame(int uid, int width, int height, int elapsed) {
    if (isVideoCall) {
      _updateCallState(isControlsVisible: true);
      _startControlsAutoHideTimer();
    }
  }

  void _handleError(dynamic error, String message) {
    print('Agora error: $error, message: $message');
  }

  // Call timer
  void _startCallTimer() {
    // Cancel existing timer first
    _callTimer?.cancel();
    _callTimer = null;
    
    // Only start timer if not disposed
    if (!mounted) return;
    
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Safety check: stop timer if provider is disposed
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateCallState(callDuration: _callState.callDuration + 1);
    });
  }

  // Controls visibility timer
  void _startControlsAutoHideTimer() {
    // Cancel existing timer first
    _controlsAutoHideTimer?.cancel();
    _controlsAutoHideTimer = null;
    
    // Only start timer if not disposed and conditions are met
    if (!mounted || !isVideoCall || !_callState.isRemoteUserJoined) return;

    _controlsAutoHideTimer = Timer(const Duration(seconds: 5), () {
      // Safety check: only update if not disposed
      if (!mounted) return;
      _updateCallState(isControlsVisible: false);
    });
  }

  // Show controls
  void showControls() {
    if (!_callState.isControlsVisible) {
      _updateCallState(isControlsVisible: true);
      _startControlsAutoHideTimer();
    } else {
      // Reset the timer
      _startControlsAutoHideTimer();
    }
  }

  // Toggle mute
  Future<void> toggleMute() async {
    try {
      final bool newMuteState = !_callState.isMuted;
      await _agoraService.muteLocalAudioStream(newMuteState);
      _updateCallState(isMuted: newMuteState);
    } catch (e) {
      print('Error toggling mute: $e');
    }
  }

  // Toggle speaker
  Future<void> toggleSpeaker() async {
    try {
      final bool newSpeakerState = !_callState.isSpeakerOn;
      await _agoraService.setEnableSpeakerphone(newSpeakerState);
      _updateCallState(isSpeakerOn: newSpeakerState);
    } catch (e) {
      print('Error toggling speaker: $e');
    }
  }
  // Toggle local video
  // Future<void> toggleLocalVideo() async {
  //   if (!isVideoCall) return;
  //
  //   try {
  //     final bool newVideoState = !_callState.isLocalVideoEnabled;
  //     await _agoraService.enableLocalVideo(newVideoState);
  //     await _agoraService.muteLocalVideoStream(!newVideoState);
  //     _updateCallState(isLocalVideoEnabled: newVideoState);
  //   } catch (e) {
  //     print('Error toggling video: $e');
  //   }
  // }
  Future<void> toggleLocalVideo() async {
    if (!isVideoCall) return;

    try {
      final bool newVideoState = !_callState.isLocalVideoEnabled;

      // Use the new method
      await _agoraService.toggleLocalVideo(newVideoState);

      _updateCallState(isLocalVideoEnabled: newVideoState);
    } catch (e) {
      print('Error toggling video: $e');
    }
  }
  // Switch camera with platform-specific optimizations
  Future<void> switchCamera() async {
    if (!isVideoCall) return;

    try {
      CallDebugUtils.logInfo('CAMERA', 'Switching camera on ${Platform.operatingSystem}');
      
      if (Platform.isIOS) {
        // iOS camera switching with preview restart
        await _agoraService.getEngine()?.stopPreview();
        await _agoraService.switchCamera();
        await Future.delayed(const Duration(milliseconds: 200));
        await _agoraService.getEngine()?.startPreview();
      } else {
        // Android camera switching
        await _agoraService.switchCamera();
      }
      
      _updateCallState(isFrontCamera: !_callState.isFrontCamera);
      CallDebugUtils.logSuccess('CAMERA', 'Camera switched successfully');
    } catch (e) {
      CallDebugUtils.logError('CAMERA', 'Error switching camera: $e');
    }
  }

  // Swap video view
  void swapLocalAndRemoteVideo() {
    if (!isVideoCall || !_callState.isRemoteUserJoined) return;

    _updateCallState(isLocalVideoFullScreen: !_callState.isLocalVideoFullScreen);
    showControls();
  }

  // Switch call type
  Future<void> switchCallType() async {
    try {
      if (isVideoCall) {
        // Switch to audio
        await _agoraService.switchToAudioCall();
        _updateCallState(
          callType: CallType.audio,
          isLocalVideoEnabled: false,
          isSpeakerOn: false,
          isControlsVisible: true,
        );

        // Cancel auto-hide timer for controls
        _controlsAutoHideTimer?.cancel();
      } else {
        // Switch to video
        await _agoraService.switchToVideoCall();
        _updateCallState(
          callType: CallType.video,
          isLocalVideoEnabled: true,
          isSpeakerOn: true,
          isLocalVideoFullScreen: false,
          isControlsVisible: true,
        );

        // Start control auto-hide timer
        _startControlsAutoHideTimer();
      }
    } catch (e) {
      print('Error switching call type: $e');
    }
  }

  // Check connection status when app comes to foreground
  Future<void> _checkConnectionStatus() async {
    try {
      final connectionState = await _agoraService.getConnectionState();

      if (connectionState != 3) { // Not connected
        if (_callState.connectionState == CallConnectionState.connected) {
          // If we think we're connected but we're not, trigger reconnection
          _attemptReconnection();
        }
      }
    } catch (e) {
      print('Error checking connection: $e');
    }
  }

  void _attemptReconnection() {
    if (_callState.connectionState == CallConnectionState.reconnecting || _isRecoveringConnection) return;

    print('🔄 Starting reconnection attempt');
    _isRecoveringConnection = true;
    _reconnectionAttempts = 0;
    _stopConnectionHealthMonitoring();

    _continueReconnection();
  }

  Future<void> _continueReconnection() async {
    if (!mounted || _disposed) return;
    
    _reconnectionAttempts++;
    print('🔄 Reconnection attempt $_reconnectionAttempts/5');

    if (_reconnectionAttempts > 5) {
      print('❌ Max reconnection attempts reached, ending call');
      _updateCallState(connectionState: CallConnectionState.failed);
      _isRecoveringConnection = false;

      // End call after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) endCall();
      });
      return;
    }

    _updateCallState(connectionState: CallConnectionState.reconnecting);

    try {
      print('🔄 Attempting to leave and rejoin channel');
      
      // Clean disconnect first
      await _agoraService.leaveChannel();
      await Future.delayed(const Duration(milliseconds: 500));

      // Use minimal settings for faster reconnection
      await _agoraService.configureForReconnection();
      await Future.delayed(const Duration(milliseconds: 300));

      // Rejoin channel with fresh token
      final channelToken = await _getAgoraToken();
      final bool joined = await _agoraService.joinChannel(
        channelId: _callState.callId,
        uid: 0,
        token: channelToken,
        isVideoCall: isVideoCall,
      );

      if (joined) {
        print('✅ Successfully rejoined channel');
        _isRecoveringConnection = false;
        
        // Wait a bit for connection to stabilize
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Restore media settings
        await _agoraService.restoreMediaSettings(isVideoCall: isVideoCall);
        
        // Start monitoring again
        _startConnectionHealthMonitoring();
      } else {
        print('❌ Failed to rejoin channel, will retry');
        // Try again after exponential backoff delay
        if (mounted) {
          Future.delayed(
            Duration(seconds: 2 + (_reconnectionAttempts * 2)),
            _continueReconnection,
          );
        }
      }
    } catch (e) {
      print('❌ Reconnection attempt $_reconnectionAttempts failed: $e');

      // Try again after exponential backoff delay
      if (mounted) {
        Future.delayed(
          Duration(seconds: 2 + (_reconnectionAttempts * 2)),
          _continueReconnection,
        );
      }
    }
  }

  // Start connection health monitoring to detect issues early
  void _startConnectionHealthMonitoring() {
    _stopConnectionHealthMonitoring();
    
    if (!mounted) return;
    
    print('💓 Starting connection health monitoring');
    _connectionHealthTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {  // Reduced frequency
      if (!mounted || _disposed) {
        timer.cancel();
        return;
      }
      
      try {
        final currentState = await _agoraService.getConnectionState();
        
        // Only check for serious inconsistencies, allow for temporary connection states
        if (currentState == 5 && _callState.connectionState == CallConnectionState.connected) {
          // Only act on FAILED state when we think we're connected
          print('⚠️ Critical connection state mismatch detected: engine=FAILED, state=CONNECTED');
          _handleConnectionInconsistency(currentState);
        }
        
        // Log state changes without acting on them unless critical
        if (_lastKnownConnectionState != currentState) {
          print('📊 Connection state update: $_lastKnownConnectionState -> $currentState');
          _lastKnownConnectionState = currentState;
        }
      } catch (e) {
        print('❌ Error checking connection health: $e');
        // Don't immediately react to single check failures
      }
    });
  }
  
  // Stop connection health monitoring
  void _stopConnectionHealthMonitoring() {
    _connectionHealthTimer?.cancel();
    _connectionHealthTimer = null;
    print('💓 Stopped connection health monitoring');
  }
  
  // Start heartbeat mechanism to maintain connection sync
  void _startHeartbeat() {
    _syncTimer?.cancel();
    
    if (!mounted) return;
    
    print('💓 Starting heartbeat mechanism');
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {  // Reduced frequency
      if (!mounted || _disposed) {
        timer.cancel();
        return;
      }
      
      // Only check heartbeat if we believe we're connected and have remote user
      if (_callState.connectionState != CallConnectionState.connected || !_callState.isRemoteUserJoined) {
        return;
      }
      
      // Send a lightweight sync signal to ensure both sides are alive
      try {
        // Check if we can still communicate with the engine
        final connectionState = await _agoraService.getConnectionState();
        
        if (connectionState == 3) {
          // Connection is healthy - no action needed
          print('💓 Heartbeat: Connection healthy');
        } else if (connectionState == 4) {
          // Engine is reconnecting - this is expected, don't interfere
          print('💓 Heartbeat: Engine is reconnecting (normal behavior)');
        } else if (connectionState == 5 || connectionState == 1) {
          // Only trigger reconnection for failed or disconnected states
          print('💔 Heartbeat: Connection issue detected (state: $connectionState)');
          _handleConnectionInconsistency(connectionState);
        }
      } catch (e) {
        print('💔 Heartbeat error: $e');
        // Only trigger reconnection if we get multiple consecutive errors
        _handleConnectionInconsistency(-1);
      }
    });
  }
  
  // Stop heartbeat
  void _stopHeartbeat() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('💓 Stopped heartbeat mechanism');
  }

  // Handle connection state inconsistencies
  void _handleConnectionInconsistency(int actualState) {
    print('🔧 Handling connection inconsistency: actualState=$actualState');
    
    // Only take action for severe issues, not temporary state changes
    if (actualState == 5) {
      // Engine failed - this is a real problem
      print('❌ Engine connection failed, attempting recovery');
      _stopHeartbeat();
      _attemptReconnection();
    } else if (actualState == -1) {
      // Engine unreachable - serious issue
      print('❌ Engine unreachable, attempting recovery');
      _stopHeartbeat();
      _attemptReconnection();
    } else if (actualState == 4) {
      // Engine is reconnecting - update our state but don't interfere
      print('🔄 Engine is reconnecting, updating state');
      _updateCallState(connectionState: CallConnectionState.reconnecting);
    } else {
      // For other states (1=disconnected, 2=connecting), just log but don't take drastic action
      print('ℹ️ Engine state change noted: $actualState - monitoring...');
    }
  }

  // End call
  void endCall() {
    print('📞 Ending call and cleaning up resources');
    
    // Stop all timers immediately when ending call
    _callTimer?.cancel();
    _callTimer = null;
    _controlsAutoHideTimer?.cancel();
    _controlsAutoHideTimer = null;
    _stopConnectionHealthMonitoring();
    _stopHeartbeat();
    
    // Cancel all speaking timers
    for (var timer in _speakingTimers.values) {
      timer?.cancel();
    }
    _speakingTimers.clear();
    
    // Reset reconnection state
    _isRecoveringConnection = false;
    _reconnectionAttempts = 0;
    
    // Release Agora resources
    _agoraService.leaveChannel();
    _agoraService.release();
  }

  // Helper method to update call state
  void _updateCallState({
    CallType? callType,
    CallConnectionState? connectionState,
    bool? isLocalUserJoined,
    bool? isRemoteUserJoined,
    bool? isLocalVideoEnabled,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isFrontCamera,
    bool? isLocalVideoFullScreen,
    bool? isControlsVisible,
    int? remoteUid,
    int? callDuration,
    int? networkQuality,
    bool? isLocalUserSpeaking,
    bool? isRemoteUserSpeaking,
    bool? isUsingLowerVideoQuality,
  }) {
    // Store previous state for comparison
    _previousCallState = _callState;
    
    _callState = _callState.copyWith(
      callType: callType,
      connectionState: connectionState,
      isLocalUserJoined: isLocalUserJoined,
      isRemoteUserJoined: isRemoteUserJoined,
      isLocalVideoEnabled: isLocalVideoEnabled,
      isMuted: isMuted,
      isSpeakerOn: isSpeakerOn,
      isFrontCamera: isFrontCamera,
      isLocalVideoFullScreen: isLocalVideoFullScreen,
      isControlsVisible: isControlsVisible,
      remoteUid: remoteUid,
      callDuration: callDuration,
      networkQuality: networkQuality,
      isLocalUserSpeaking: isLocalUserSpeaking,
      isRemoteUserSpeaking: isRemoteUserSpeaking,
      isUsingLowerVideoQuality: isUsingLowerVideoQuality,
    );

    // Log state changes for debugging
    if (_previousCallState != null) {
      CallDebugUtils.logCallStateChange(_previousCallState!, _callState);
    }
    
    // Analyze for issues periodically
    if (callDuration != null && callDuration % 30 == 0 && callDuration > 0) {
      CallDebugUtils.logCallIssuesAnalysis(_callState);
    }

    notifyListeners();
  }
// Enhanced user joined handler with better synchronization
  void _handleUserJoined(int remoteUid, int elapsed) {
    CallDebugUtils.logCallTimeline('REMOTE_USER_JOINED', data: {
      'uid': remoteUid,
      'elapsed': '${elapsed}ms',
      'callDuration': _callState.callDuration,
    });
    
    // Update state first
    _updateCallState(
      remoteUid: remoteUid,
      isRemoteUserJoined: true,
      connectionState: CallConnectionState.connected,
    );

    // Start the call timer ONLY when remote user joins
    _startCallTimer();
    CallDebugUtils.logCallTimeline('CALL_TIMER_STARTED');

    // Configure media settings for the remote user
    _configureRemoteUserMedia(remoteUid);
    
    // CRITICAL FIX: Force UI refreshes for video calls to ensure video displays
    if (isVideoCall) {
      // Immediate UI refresh
      notifyListeners();
      
      // Progressive UI refreshes to handle video rendering delays
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          notifyListeners();
          print('🔄 UI refresh #1 for video rendering');
        }
      });
      
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          notifyListeners();
          print('🔄 UI refresh #2 for video rendering');
        }
      });
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          notifyListeners();
          _startControlsAutoHideTimer();
          CallDebugUtils.logDebug('UI', 'Video call controls auto-hide timer started');
          print('🔄 Final UI refresh for video rendering');
        }
      });
    }
    
    // Start heartbeat to maintain connection sync
    _startHeartbeat();
  }
  
  // Configure media settings for remote user
  void _configureRemoteUserMedia(int remoteUid) async {
    try {
      print('🎥 Configuring media for remote user $remoteUid');
      
      if (isVideoCall) {
        // CRITICAL FIX: Enhanced remote video configuration
        int attempts = 0;
        bool configured = false;
        
        while (!configured && attempts < 3) {
          try {
            // Force subscribe to remote video stream
            await _agoraService.getEngine()?.muteRemoteVideoStream(uid: remoteUid, mute: false);
            
            // Set high quality video stream
            await _agoraService.getEngine()?.setRemoteVideoStreamType(
              uid: remoteUid,
              streamType: VideoStreamType.videoStreamHigh,
            );
            
            // Configure rendering mode for better display
            await _agoraService.getEngine()?.setRemoteRenderMode(
              uid: remoteUid,
              renderMode: RenderModeType.renderModeFit,
              mirrorMode: VideoMirrorModeType.videoMirrorModeDisabled,
            );
            
            // CRITICAL: Set remote subscription for this specific user
            await _agoraService.getEngine()?.setRemoteVideoSubscriptionOptions(
              uid: remoteUid, 
              options: VideoSubscriptionOptions(
                type: VideoStreamType.videoStreamHigh,
                encodedFrameOnly: false,
              ),
            );
            
            configured = true;
            print('✅ Enhanced video configuration set for user $remoteUid on attempt ${attempts + 1}');
          } catch (e) {
            attempts++;
            print('❌ Video config attempt $attempts failed: $e');
            if (attempts < 3) {
              await Future.delayed(Duration(milliseconds: 300 * attempts));
            }
          }
        }
      }
      
      // Subscribe to remote audio/video with retry logic
      try {
        await _agoraService.getEngine()?.muteRemoteAudioStream(uid: remoteUid, mute: false);
        if (isVideoCall) {
          await _agoraService.getEngine()?.muteRemoteVideoStream(uid: remoteUid, mute: false);
        }
        print('✅ Remote media streams subscribed successfully');
      } catch (e) {
        print('❌ Error subscribing to remote streams: $e');
        // Retry after a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _agoraService.getEngine()?.muteRemoteAudioStream(uid: remoteUid, mute: false);
            if (isVideoCall) {
              _agoraService.getEngine()?.muteRemoteVideoStream(uid: remoteUid, mute: false);
            }
          }
        });
      }
      
      print('✅ Remote user media configured successfully');
    } catch (e) {
      print('❌ Error configuring remote user media: $e');
    }
  }

// Enhanced initializeCall method with better error handling and state management
  Future<void> initializeCall() async {
    print('🚀 Initializing call: ${_callState.callId}, isVideo: $isVideoCall');
    
    // Set connecting state
    _updateCallState(connectionState: CallConnectionState.connecting);
    
    try {
      // Initialize Agora service with enhanced callbacks
      final initialized = await _agoraService.initialize(
        onJoinChannelSuccess: _handleJoinChannelSuccess,
        onUserJoined: _handleUserJoined,
        onUserOffline: _handleUserOffline,
        onAudioVolumeIndication: _handleAudioVolumeIndication,
        onNetworkQuality: _handleNetworkQuality,
        onConnectionStateChanged: _handleConnectionStateChanged,
        onFirstRemoteVideoFrame: _handleFirstRemoteVideoFrame,
        onError: _handleError,
      );

      if (!initialized) {
        throw Exception('Failed to initialize Agora engine');
      }

      // Configure media settings with retry logic
      bool mediaConfigured = false;
      int attempts = 0;
      while (!mediaConfigured && attempts < 3) {
        try {
          await _agoraService.configureMediaSettings(isVideoCall: isVideoCall);
          mediaConfigured = true;
          print('✅ Media settings configured on attempt ${attempts + 1}');
        } catch (e) {
          attempts++;
          print('❌ Media configuration attempt $attempts failed: $e');
          if (attempts < 3) {
            await Future.delayed(Duration(milliseconds: 500 * attempts));
          }
        }
      }

      if (!mediaConfigured) {
        throw Exception('Failed to configure media settings after 3 attempts');
      }

      // CRITICAL DEBUG: Log the channel ID and user information
      print('🔴 CRITICAL DEBUG - Channel Join Details:');
      print('  🆔 Call ID / Channel ID: "${_callState.callId}"');
      print('  👤 Local User: ${_localUser.name} (ID: ${_localUser.id})');
      print('  👥 Remote User: ${_remoteUser.name} (ID: ${_remoteUser.id})');
      print('  🎥 Call Type: ${isVideoCall ? "VIDEO" : "AUDIO"}');
      print('  🕐 Join Time: ${DateTime.now().toIso8601String()}');
      
      // Join channel with retry logic
      bool joined = false;
      attempts = 0;
      while (!joined && attempts < 3) {
        try {
          print('🔄 Channel join attempt ${attempts + 1}/3...');
          
          // Generate or get secure token
          final channelToken = await _getAgoraToken();
          print('  🔑 Using token: ${channelToken.isEmpty ? "EMPTY (Development mode)" : "PROVIDED (${channelToken.length} chars)"}');
          
          joined = await _agoraService.joinChannel(
            channelId: _callState.callId,
            uid: 0, // Let Agora assign UID dynamically
            token: channelToken,
            isVideoCall: isVideoCall,
          );
          if (joined) {
            print('✅ Successfully joined channel "${_callState.callId}" on attempt ${attempts + 1}');
          }
        } catch (e) {
          attempts++;
          print('❌ Channel join attempt $attempts failed: $e');
          if (attempts < 3) {
            await Future.delayed(Duration(milliseconds: 1000 * attempts));
          }
        }
      }

      if (!joined) {
        throw Exception('Failed to join channel after 3 attempts');
      }

    } catch (e) {
      print('❌ Call initialization error: $e');
      _updateCallState(connectionState: CallConnectionState.failed);
      
      // Try to clean up any partial initialization
      try {
        await _agoraService.leaveChannel();
      } catch (cleanupError) {
        print('Warning: Cleanup error: $cleanupError');
      }
    }
  }

// Enhanced user offline handler with better reason handling
  void _handleUserOffline(int remoteUid, int reason) {
    String disconnectReason = _getDisconnectReason(reason);
    CallDebugUtils.logCallTimeline('REMOTE_USER_LEFT', data: {
      'uid': remoteUid,
      'reason': reason,
      'reasonText': disconnectReason,
      'callDuration': _callState.callDuration,
    });
    
    // Stop heartbeat and connection monitoring
    _stopHeartbeat();
    
    // Stop the timer when the remote user leaves
    _callTimer?.cancel();
    _callTimer = null;
    CallDebugUtils.logCallTimeline('CALL_TIMER_STOPPED');

    _updateCallState(
      remoteUid: null,
      isRemoteUserJoined: false,
    );

    // Auto end call if remote user leaves (with different delays based on reason)
    Duration delay = const Duration(seconds: 2);
    
    // If user deliberately quit, end call faster
    if (reason == 1) { // USER_OFFLINE_QUIT
      delay = const Duration(seconds: 1);
      CallDebugUtils.logInfo('DISCONNECT', 'User deliberately left, ending call quickly');
    }
    // If connection dropped, wait a bit longer for potential reconnection
    else if (reason == 2) { // USER_OFFLINE_DROPPED
      delay = const Duration(seconds: 5); // Increased wait time for reconnection
      CallDebugUtils.logWarning('DISCONNECT', 'Connection dropped, waiting for potential reconnection');
    }

    Future.delayed(delay, () {
      if (mounted && !_callState.isRemoteUserJoined) {
        CallDebugUtils.logCallTimeline('AUTO_END_CALL', data: {'delaySeconds': delay.inSeconds});
        endCall();
      }
    });
  }
  
  // Get human-readable disconnect reason
  String _getDisconnectReason(int reason) {
    switch (reason) {
      case 0: return 'USER_OFFLINE_QUIT_DEPRECATED';
      case 1: return 'USER_OFFLINE_QUIT (Normal disconnect)';
      case 2: return 'USER_OFFLINE_DROPPED (Connection lost)';
      case 3: return 'USER_OFFLINE_BECOME_AUDIENCE';
      default: return 'UNKNOWN_REASON ($reason)';
    }
  }
  @override
  void dispose() {
    CallDebugUtils.logCallTimeline('DISPOSING_CALL_PROVIDER');
    
    // Generate final diagnostic report
    CallDebugUtils.logDiagnosticReport(_callState);
    
    // Mark as disposed first to prevent new timers
    _disposed = true;
    
    // Stop performance monitoring
    _performanceMonitor?.cancel();
    _performanceMonitor = null;
    
    // Cancel all timers
    _callTimer?.cancel();
    _callTimer = null;
    _controlsAutoHideTimer?.cancel();
    _controlsAutoHideTimer = null;
    _stopConnectionHealthMonitoring();
    _stopHeartbeat();

    // Cancel speaking timers
    for (var timer in _speakingTimers.values) {
      timer?.cancel();
    }
    _speakingTimers.clear();
    
    // Reset reconnection state
    _isRecoveringConnection = false;
    _reconnectionAttempts = 0;

    super.dispose();
  }
}