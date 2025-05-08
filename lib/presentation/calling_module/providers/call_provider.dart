// lib/presentation/call_module/providers/call_provider.dart
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import '../models/call_state.dart';
import '../models/user_model.dart';
import '../models/agora_callbacks.dart'; // Import the new callback types
import '../services/agora_service.dart';
import '../utils/constants.dart';
import '../utils/resource_manager.dart';

/// Main provider for call state management
class CallProvider extends ChangeNotifier {
  // Services
  final AgoraService _agoraService;
  final ResourceManager _resourceManager = ResourceManager();

  // Call state
  CallState _callState;

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

  // Constructor
  CallProvider({
    required AgoraService agoraService,
    required String callId,
    required UserModel localUser,
    required UserModel remoteUser,
    required bool isVideoCall,
  }) : _agoraService = agoraService,
        _localUser = localUser,
        _remoteUser = remoteUser,
        _callState = CallState(
          callId: callId,
          callType: isVideoCall ? CallType.video : CallType.audio,
        );

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

  // Handle app going to background
  void handleAppBackground() {
    _isInBackground = true;

    // Mute video when going to background
    if (isVideoCall && _agoraService.isInitialized()) {
      _agoraService.muteLocalVideoStream(true);
      _resourceManager.setHighPerformanceMode(false);
    }
  }

  // Handle app coming to foreground
  void handleAppForeground() {
    _isInBackground = false;

    // Restore video when coming back to foreground
    if (isVideoCall && _agoraService.isInitialized() && _callState.isLocalVideoEnabled) {
      _agoraService.muteLocalVideoStream(false);
      _resourceManager.setHighPerformanceMode(true);
    }

    // Check connection status
    if (_agoraService.isInitialized() && _callState.isLocalUserJoined) {
      _checkConnectionStatus();
    }
  }

  // Event handlers - updated to use new callback types
  void _handleJoinChannelSuccess(int uid, String channelId, int elapsed) {
    _updateCallState(
      isLocalUserJoined: true,
      connectionState: CallConnectionState.connected,
    );
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
    // Cancel previous timer
    _speakingTimers[uid]?.cancel();

    // Update state based on UID
    if (uid == 0) {
      _updateCallState(isLocalUserSpeaking: true);
    } else {
      _updateCallState(isRemoteUserSpeaking: true);
    }

    // Set timer to reset speaking state
    _speakingTimers[uid] = Timer(const Duration(milliseconds: 800), () {
      if (uid == 0) {
        _updateCallState(isLocalUserSpeaking: false);
      } else {
        _updateCallState(isRemoteUserSpeaking: false);
      }
    });
  }

  void _handleNetworkQuality(int uid, int txQuality, int rxQuality) {
    // Only update if significant change
    if (_callState.networkQuality != rxQuality) {
      _updateCallState(networkQuality: rxQuality);
    }
  }

  void _handleConnectionStateChanged(int state, int reason) {
    switch (state) {
      case 2: // Connecting
        _updateCallState(connectionState: CallConnectionState.connecting);
        break;
      case 3: // Connected
        _updateCallState(connectionState: CallConnectionState.connected);
        break;
      case 4: // Reconnecting
        _updateCallState(connectionState: CallConnectionState.reconnecting);
        _resourceManager.setHighPerformanceMode(false);
        break;
      case 5: // Failed
        _updateCallState(connectionState: CallConnectionState.failed);
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
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCallState(callDuration: _callState.callDuration + 1);
    });
  }

  // Controls visibility timer
  void _startControlsAutoHideTimer() {
    _controlsAutoHideTimer?.cancel();

    if (isVideoCall && _callState.isRemoteUserJoined) {
      _controlsAutoHideTimer = Timer(const Duration(seconds: 5), () {
        _updateCallState(isControlsVisible: false);
      });
    }
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
  // Switch camera
  Future<void> switchCamera() async {
    if (!isVideoCall) return;

    try {
      await _agoraService.switchCamera();
      _updateCallState(isFrontCamera: !_callState.isFrontCamera);
    } catch (e) {
      print('Error switching camera: $e');
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

    _isRecoveringConnection = true;
    _reconnectionAttempts = 0;

    _continueReconnection();
  }

  Future<void> _continueReconnection() async {
    _reconnectionAttempts++;

    if (_reconnectionAttempts > 5) {
      // Too many attempts, give up
      _updateCallState(connectionState: CallConnectionState.failed);

      // End call after a delay
      Future.delayed(const Duration(seconds: 2), () {
        endCall();
      });
      return;
    }

    _updateCallState(connectionState: CallConnectionState.reconnecting);

    try {
      // Try to reconnect
      await _agoraService.leaveChannel();

      // Use minimal settings for faster reconnection
      await _agoraService.configureForReconnection();

      // Rejoin channel
      final bool joined = await _agoraService.joinChannel(
        channelId: _callState.callId,
        uid: 0,
        token: '', // Add token if needed
        isVideoCall: isVideoCall,
      );

      if (joined) {
        // Success
        _updateCallState(connectionState: CallConnectionState.connected);
        _isRecoveringConnection = false;

        // Restore media settings
        await _agoraService.restoreMediaSettings(isVideoCall: isVideoCall);
      } else {
        // Try again after delay
        Future.delayed(
          Duration(seconds: 2 + _reconnectionAttempts),
          _continueReconnection,
        );
      }
    } catch (e) {
      print('Reconnection attempt failed: $e');

      // Try again after delay
      Future.delayed(
        Duration(seconds: 2 + _reconnectionAttempts),
        _continueReconnection,
      );
    }
  }

  // End call
  void endCall() {
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

    notifyListeners();
  }
// Modify this method in CallProvider
  void _handleUserJoined(int remoteUid, int elapsed) {
    // Update state first
    _updateCallState(
      remoteUid: remoteUid,
      isRemoteUserJoined: true,
      connectionState: CallConnectionState.connected,
    );

    // Start the call timer ONLY when remote user joins
    _startCallTimer();

    // Show controls for video calls
    if (isVideoCall) {
      _startControlsAutoHideTimer();
    }
  }

// Update the initializeCall method to NOT start timer on local join
  Future<void> initializeCall() async {
    try {
      // Initialize Agora service
      await _agoraService.initialize(
        onJoinChannelSuccess: _handleJoinChannelSuccess,
        onUserJoined: _handleUserJoined,
        onUserOffline: _handleUserOffline,
        onAudioVolumeIndication: _handleAudioVolumeIndication,
        onNetworkQuality: _handleNetworkQuality,
        onConnectionStateChanged: _handleConnectionStateChanged,
        onFirstRemoteVideoFrame: _handleFirstRemoteVideoFrame,
        onError: _handleError,
      );

      // Configure for the specific call type
      await _agoraService.configureMediaSettings(isVideoCall: isVideoCall);

      // Join channel - Make sure we use the correct channelId format and token
      final bool joined = await _agoraService.joinChannel(
        channelId: _callState.callId,
        uid: 0,
        token: '', // Add token if needed
        isVideoCall: isVideoCall,
      );

      print('Joining channel: ${_callState.callId}');

      if (joined) {
        // DON'T start call timer here! Start it when remote user joins
        // _startCallTimer(); -- REMOVE THIS
      } else {
        // Update state to failed
        _updateCallState(connectionState: CallConnectionState.failed);
      }
    } catch (e) {
      print('Call initialization error: $e');
      _updateCallState(connectionState: CallConnectionState.failed);
    }
  }

// Modify the handleUserOffline method to handle call ending
  void _handleUserOffline(int remoteUid, int reason) {
    // Stop the timer when the remote user leaves
    _callTimer?.cancel();

    _updateCallState(
      remoteUid: null,
      isRemoteUserJoined: false,
    );

    // Auto end call if remote user leaves
    Future.delayed(const Duration(seconds: 2), () {
      endCall();
    });
  }
  @override
  void dispose() {
    _callTimer?.cancel();
    _controlsAutoHideTimer?.cancel();

    for (var timer in _speakingTimers.values) {
      timer?.cancel();
    }
    _speakingTimers.clear();

    super.dispose();
  }
}