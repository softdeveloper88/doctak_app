import 'dart:async';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/constants.dart';
import '../models/agora_callbacks.dart';

/// Service to handle all Agora SDK interactions
class AgoraService {
  // Agora Engine
  RtcEngine? _engine;

  // Event callbacks
  AgoraJoinChannelSuccessCallback? _onJoinChannelSuccess;
  AgoraUserJoinedCallback? _onUserJoined;
  AgoraUserOfflineCallback? _onUserOffline;
  AgoraAudioVolumeIndicationCallback? _onAudioVolumeIndication;
  AgoraNetworkQualityCallback? _onNetworkQuality;
  AgoraConnectionStateChangedCallback? _onConnectionStateChanged;
  AgoraFirstRemoteVideoFrameCallback? _onFirstRemoteVideoFrame;
  AgoraErrorCallback? _onError;

  // Check if engine is initialized
  bool isInitialized() {
    return _engine != null;
  }

  // Get the Agora engine (for VideoView)
  RtcEngine? getEngine() {
    return _engine;
  }

  // Initialize the Agora engine
  Future<bool> initialize({
    AgoraJoinChannelSuccessCallback? onJoinChannelSuccess,
    AgoraUserJoinedCallback? onUserJoined,
    AgoraUserOfflineCallback? onUserOffline,
    AgoraAudioVolumeIndicationCallback? onAudioVolumeIndication,
    AgoraNetworkQualityCallback? onNetworkQuality,
    AgoraConnectionStateChangedCallback? onConnectionStateChanged,
    AgoraFirstRemoteVideoFrameCallback? onFirstRemoteVideoFrame,
    AgoraErrorCallback? onError,
  }) async {
    try {
      // Store callbacks
      _onJoinChannelSuccess = onJoinChannelSuccess;
      _onUserJoined = onUserJoined;
      _onUserOffline = onUserOffline;
      _onAudioVolumeIndication = onAudioVolumeIndication;
      _onNetworkQuality = onNetworkQuality;
      _onConnectionStateChanged = onConnectionStateChanged;
      _onFirstRemoteVideoFrame = onFirstRemoteVideoFrame;
      _onError = onError;

      // Create and initialize the engine
      _engine = createAgoraRtcEngine();

      print('🔴 AGORA INITIALIZATION:');
      print('  📱 App ID: "${AppConstants.agoraAppId}"');
      print('  📱 App ID Length: ${AppConstants.agoraAppId.length}');
      print('  🔄 Channel Profile: COMMUNICATION');

      await _engine?.initialize(const RtcEngineContext(appId: AppConstants.agoraAppId, channelProfile: ChannelProfileType.channelProfileCommunication));

      print('✅ Agora engine initialized successfully');

      // Register event handlers
      _registerEventHandlers();

      return true;
    } catch (e) {
      print('Agora engine initialization error: $e');
      return false;
    }
  }

  // Register event handlers
  void _registerEventHandlers() {
    print('🎯 Registering Agora event handlers');
    _engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print('✅ onJoinChannelSuccess: channel="${connection.channelId}", uid=${connection.localUid}, elapsed=${elapsed}ms');
          print('🔴 CRITICAL: Successfully joined Agora channel!');
          print('  📍 Channel Name: "${connection.channelId}"');
          print('  👤 My UID: ${connection.localUid}');
          print('  ⏱️ Time taken: ${elapsed}ms');
          if (_onJoinChannelSuccess != null) {
            _onJoinChannelSuccess!(connection.localUid ?? 0, connection.channelId ?? "", elapsed);
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('👥 onUserJoined: uid=$remoteUid, channel=${connection.channelId}, elapsed=${elapsed}ms');
          if (_onUserJoined != null) {
            _onUserJoined!(remoteUid, elapsed);
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          print('👋 onUserOffline: uid=$remoteUid, channel=${connection.channelId}, reason=${reason.index}');
          if (_onUserOffline != null) {
            _onUserOffline!(remoteUid, reason.index);
          }
        },
        onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int s) {
          if (speakers.isEmpty || _onAudioVolumeIndication == null) return;

          // Convert speakers list to a more usable format
          try {
            final List<Map<String, dynamic>> speakersData = speakers.map((speaker) {
              return {'uid': speaker.uid, 'volume': speaker.volume ?? 0, 'vad': speaker.vad ?? 0};
            }).toList();

            _onAudioVolumeIndication!(speakersData, totalVolume);
          } catch (e) {
            debugPrint('Error processing audio volume indication: $e');
          }
        },
        onNetworkQuality: (RtcConnection connection, int uid, QualityType txQuality, QualityType rxQuality) {
          if (_onNetworkQuality != null) {
            _onNetworkQuality!(uid, txQuality.index, rxQuality.index);
          }
        },
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          print('🔄 onConnectionStateChanged: state=${state.index}(${_getConnectionStateName(state.index)}), reason=${reason.index}(${_getConnectionReasonName(reason.index)})');
          if (_onConnectionStateChanged != null) {
            _onConnectionStateChanged!(state.index, reason.index);
          }
        },
        onFirstRemoteVideoFrame: (RtcConnection connection, int remoteUid, int width, int height, int elapsed) {
          print('📹 onFirstRemoteVideoFrame: uid=$remoteUid, size=${width}x$height, elapsed=${elapsed}ms');
          if (_onFirstRemoteVideoFrame != null) {
            _onFirstRemoteVideoFrame!(remoteUid, width, height, elapsed);
          }
        },
        onError: (ErrorCodeType err, String msg) {
          print('❌ onError: code=${err.value}, message=$msg');
          if (_onError != null) {
            _onError!(err, msg);
          }
        },
        // Additional event handlers for better debugging
        onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
          print('📺 onRemoteVideoStateChanged: uid=$remoteUid, state=${state.index}, reason=${reason.index}, elapsed=${elapsed}ms');
        },
        onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid, RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
          print('🔊 onRemoteAudioStateChanged: uid=$remoteUid, state=${state.index}, reason=${reason.index}, elapsed=${elapsed}ms');
        },
        onLocalVideoStateChanged: (VideoSourceType source, LocalVideoStreamState state, LocalVideoStreamReason reason) {
          print('📱 onLocalVideoStateChanged: source=${source.index}, state=${state.index}, reason=${reason.index}');
        },
        onLocalAudioStateChanged: (RtcConnection connection, LocalAudioStreamState state, LocalAudioStreamReason reason) {
          print('🎤 onLocalAudioStateChanged: state=${state.index}, reason=${reason.index}');
        },
      ),
    );
  }

  // Join channel
  // Future<bool> joinChannel({
  //   required String channelId,
  //   required int uid,
  //   String? token,
  //   required bool isVideoCall,
  // }) async {
  //   try {
  //     if (_engine == null) return false;
  //
  //     print('AgoraService: Joining channel $channelId with token: ${token ??
  //         'empty'}, uid: $uid, isVideoCall: $isVideoCall');
  //
  //     // Join the channel with updated options
  //     await _engine!.joinChannel(
  //       token: '',
  //       channelId: channelId,
  //       uid: uid,
  //       options: const ChannelMediaOptions(
  //         channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
  //         clientRoleType: ClientRoleType.clientRoleBroadcaster,
  //       ),
  //     );
  //
  //     return true;
  //   } catch (e) {
  //     print('Channel ID: $channelId, UID: $uid, Token empty: ${token == null ||
  //         token.isEmpty}');
  //
  //     print('Join channel error: $e');
  //     return false;
  //   }
  // }

  // Enhanced media configuration with better video stream handling
  Future<void> configureMediaSettings({required bool isVideoCall}) async {
    if (_engine == null) {
      throw Exception('Agora engine not initialized');
    }

    print('🎥 Configuring media settings: isVideoCall=$isVideoCall, platform=${Platform.operatingSystem}');

    try {
      // CRITICAL FIX: Check and request permissions BEFORE configuring media
      await _validateAndRequestPermissions(isVideoCall: isVideoCall);

      // Add small delay to ensure permissions are properly processed
      await Future.delayed(const Duration(milliseconds: 200));

      print('✅ Permissions validated, proceeding with media configuration...');

      // STEP 1: Set client role first (this is critical and must succeed)
      try {
        await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        print('✅ Client role set to broadcaster');
      } catch (e) {
        print('❌ FAILED at setClientRole: $e');
        rethrow;
      }

      // STEP 2: Configure basic audio settings first
      try {
        // Use simple, standard audio configuration
        await _engine!.setAudioProfile(profile: AudioProfileType.audioProfileDefault, scenario: AudioScenarioType.audioScenarioDefault);
        print('✅ Basic audio profile set');
      } catch (e) {
        print('❌ FAILED at setAudioProfile: $e');
        rethrow;
      }

      // STEP 3: Enable audio volume indication (basic version)
      try {
        await _engine!.enableAudioVolumeIndication(
          interval: 1000, // Less frequent for stability
          smooth: 3,
          reportVad: false, // Disable VAD for now
        );
        print('✅ Audio volume indication enabled');
      } catch (e) {
        print('❌ FAILED at enableAudioVolumeIndication: $e');
        rethrow;
      }

      // STEP 4: Skip complex audio parameters for now
      print('✅ Basic audio settings configured');

      if (isVideoCall) {
        // STEP 5: Enable video (basic)
        try {
          await _engine!.enableVideo();
          print('✅ Video enabled');
        } catch (e) {
          print('❌ FAILED at enableVideo: $e');
          rethrow;
        }

        // STEP 6: Set basic video encoder configuration
        try {
          await _engine!.setVideoEncoderConfiguration(
            const VideoEncoderConfiguration(
              dimensions: VideoDimensions(width: 640, height: 480),
              frameRate: 15,
              bitrate: 800,
              minBitrate: 400,
              orientationMode: OrientationMode.orientationModeAdaptive,
              degradationPreference: DegradationPreference.maintainQuality,
              mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
              codecType: VideoCodecType.videoCodecH264,
            ),
          );
          print('✅ Video encoder configuration set');
        } catch (e) {
          print('❌ FAILED at setVideoEncoderConfiguration: $e');
          rethrow;
        }

        // STEP 7: Enable dual stream mode (optional)
        try {
          await _engine!.enableDualStreamMode(enabled: true);
          print('✅ Dual stream mode enabled');
        } catch (e) {
          print('⚠️ Warning: Dual stream mode failed: $e');
          // Continue without failing, as this is optional
        }

        // STEP 8: Set basic camera configuration
        try {
          await _engine!.setCameraCapturerConfiguration(const CameraCapturerConfiguration(cameraDirection: CameraDirection.cameraFront));
          print('✅ Camera configuration set');
        } catch (e) {
          print('❌ FAILED at setCameraCapturerConfiguration: $e');
          rethrow;
        }

        // STEP 9: Start local video preview (essential for video calls)
        try {
          await _engine!.startPreview();
          print('✅ Video preview started');
        } catch (e) {
          print('❌ Error starting preview: $e');
          // Continue anyway - preview might still work during call
        }

        // STEP 10: Set basic audio routing for video calls
        try {
          await _engine!.setDefaultAudioRouteToSpeakerphone(true);
          await _engine!.setEnableSpeakerphone(true);
          print('✅ Audio routing configured for video call');
        } catch (e) {
          print('⚠️ Warning: Audio routing failed: $e');
          // Continue without failing
        }

        print('✅ Video call configuration completed');
      } else {
        // STEP 5 (audio call): Disable video and configure audio routing
        try {
          await _engine!.disableVideo();
          print('✅ Video disabled for audio call');
        } catch (e) {
          print('❌ FAILED at disableVideo: $e');
          rethrow;
        }

        try {
          await _engine!.setDefaultAudioRouteToSpeakerphone(false);
          print('✅ Audio routing configured for audio call');
        } catch (e) {
          print('⚠️ Warning: Audio routing failed: $e');
          // Continue without failing
        }

        print('✅ Audio call configuration completed');
      }
    } catch (e) {
      print('❌ Error configuring media settings: $e');
      rethrow;
    }
  }

  // iOS-specific audio session configuration
  Future<void> _configureIOSAudioSession() async {
    try {
      // Simplified iOS audio session - use default settings only
      print('ℹ️ Using default iOS audio session settings');
      // Removed complex setParameters calls that were causing AgoraRtcException(-3, null)
    } catch (e) {
      print('❌ Error configuring iOS audio session: $e');
    }
  }

  // Add method to properly deactivate the audio session on iOS
  Future<void> deactivateAudioSession() async {
    if (_engine == null) return;

    try {
      // Set parameters to deactivate audio session
      if (Platform.isIOS) {
        await _engine!.setParameters('{"che.audio.keep_audiosession": false}');
      }
    } catch (e) {
      print('Error deactivating audio session: $e');
    }
  }

  // Configure minimal settings for reconnection
  Future<void> configureForReconnection() async {
    if (_engine == null) return;

    try {
      // Disable video for faster reconnection
      if (_engine != null) {
        await _engine!.enableLocalVideo(false);

        // Set minimal video quality
        await _engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 160, height: 120),
            frameRate: 10,
            bitrate: 100,
            orientationMode: OrientationMode.orientationModeAdaptive,
            degradationPreference: DegradationPreference.maintainFramerate,
          ),
        );
      }
    } catch (e) {
      print('Error configuring for reconnection: $e');
    }
  }

  // Restore media settings after reconnection
  Future<void> restoreMediaSettings({required bool isVideoCall}) async {
    if (_engine == null) return;

    try {
      if (isVideoCall) {
        // Restore video settings
        await _engine!.enableLocalVideo(true);

        await _engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 640, height: 480),
            frameRate: 15,
            bitrate: 1000,
            orientationMode: OrientationMode.orientationModeAdaptive,
            degradationPreference: DegradationPreference.maintainQuality,
            codecType: VideoCodecType.videoCodecH264,
          ),
        );

        // Update media options
        await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(publishCameraTrack: true, publishMicrophoneTrack: true, autoSubscribeAudio: true, autoSubscribeVideo: true));
      } else {
        // Restore audio settings
        await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(publishCameraTrack: false, publishMicrophoneTrack: true, autoSubscribeAudio: true, autoSubscribeVideo: false));
      }
    } catch (e) {
      print('Error restoring media settings: $e');
    }
  }

  // Switch to video call
  Future<void> switchToVideoCall() async {
    if (_engine == null) return;

    // Enable video mode
    await _engine!.enableVideo();
    await _engine!.enableLocalVideo(true);

    // Configure video encoder
    await _engine!.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 480),
        frameRate: 15,
        bitrate: 1000,
        orientationMode: OrientationMode.orientationModeAdaptive,
        degradationPreference: DegradationPreference.maintainQuality,
        codecType: VideoCodecType.videoCodecH264,
      ),
    );

    // Start preview
    await _engine!.startPreview();
    await _engine!.enableDualStreamMode(enabled: true);

    // Update media options
    await _engine!.updateChannelMediaOptions(
      const ChannelMediaOptions(
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCustomVideoTrack: false,
        publishCustomAudioTrack: false,
      ),
    );

    // Enable speaker for video calls
    await _engine!.setEnableSpeakerphone(true);
  }

  // Switch to audio call
  Future<void> switchToAudioCall() async {
    if (_engine == null) return;

    // Disable video streaming and preview
    await _engine!.disableVideo();
    await _engine!.enableLocalVideo(false);
    await _engine!.stopPreview();

    // Update media options
    await _engine!.updateChannelMediaOptions(const ChannelMediaOptions(publishCameraTrack: false, publishMicrophoneTrack: true, autoSubscribeAudio: true, autoSubscribeVideo: false));

    // Switch to earpiece for audio calls
    await _engine!.setEnableSpeakerphone(false);
  }

  // Mute/unmute local audio
  Future<void> muteLocalAudioStream(bool mute) async {
    if (_engine == null) return;
    await _engine!.muteLocalAudioStream(mute);
  }

  // Enable/disable local video
  Future<void> enableLocalVideo(bool enable) async {
    if (_engine == null) return;
    await _engine!.enableLocalVideo(enable);
  }

  // Mute/unmute local video
  Future<void> muteLocalVideoStream(bool mute) async {
    if (_engine == null) return;
    await _engine!.muteLocalVideoStream(mute);
  }

  // Enable/disable speaker
  Future<void> setEnableSpeakerphone(bool enable) async {
    if (_engine == null) return;
    await _engine!.setEnableSpeakerphone(enable);
  }

  // Switch camera
  Future<void> switchCamera() async {
    if (_engine == null) return;
    await _engine!.switchCamera();
  }

  // Get connection state
  Future<int> getConnectionState() async {
    if (_engine == null) return -1;
    return _engine!.getConnectionState().then((state) => state.index);
  }

  // Leave channel
  Future<void> leaveChannel() async {
    if (_engine == null) return;
    await _engine!.leaveChannel();
  }

  // Improved release method for better cleanup
  Future<void> release() async {
    if (_engine == null) return;

    try {
      // Stop preview if running
      try {
        await _engine!.stopPreview();
      } catch (e) {
        print('Warning: Error stopping preview: $e');
      }

      // Disable video if enabled
      try {
        await _engine!.disableVideo();
      } catch (e) {
        print('Warning: Error disabling video: $e');
      }

      // Deactivate audio session on iOS
      try {
        await deactivateAudioSession();
      } catch (e) {
        print('Warning: Error deactivating audio session: $e');
      }

      // Leave channel if still connected
      try {
        await _engine!.leaveChannel();
      } catch (e) {
        print('Warning: Error leaving channel: $e');
        // Continue with release even if leave fails
      }

      // Clear callbacks to prevent memory leaks
      _clearCallbacks();

      // Then release engine resources
      await _engine!.release();
      print('Successfully released Agora resources');
    } catch (e) {
      print('Error releasing Agora resources: $e');
    } finally {
      // Always set engine to null to prevent further usage attempts
      _engine = null;
    }
  }

  // Helper method to clear all callbacks
  void _clearCallbacks() {
    _onJoinChannelSuccess = null;
    _onUserJoined = null;
    _onUserOffline = null;
    _onAudioVolumeIndication = null;
    _onNetworkQuality = null;
    _onConnectionStateChanged = null;
    _onFirstRemoteVideoFrame = null;
    _onError = null;
  }

  // Toggle local video
  Future<void> toggleLocalVideo(bool enabled) async {
    if (_engine == null) return;

    try {
      // First, enable/disable the local video
      await _engine!.enableLocalVideo(enabled);

      // Then, mute/unmute the video stream
      await _engine!.muteLocalVideoStream(!enabled);
    } catch (e) {
      print('Error toggling local video: $e');
    }
  }

  // Safe dispose method that can be called multiple times
  Future<void> dispose() async {
    await release();
  }

  // Helper method to check if engine is in a valid state
  bool _isEngineValid() {
    return _engine != null;
  }

  // Helper method to get connection state name for debugging
  String _getConnectionStateName(int state) {
    switch (state) {
      case 1:
        return 'DISCONNECTED';
      case 2:
        return 'CONNECTING';
      case 3:
        return 'CONNECTED';
      case 4:
        return 'RECONNECTING';
      case 5:
        return 'FAILED';
      default:
        return 'UNKNOWN($state)';
    }
  }

  // Helper method to get connection reason name for debugging
  String _getConnectionReasonName(int reason) {
    switch (reason) {
      case 0:
        return 'CONNECTING';
      case 1:
        return 'JOIN_SUCCESS';
      case 2:
        return 'INTERRUPTED';
      case 3:
        return 'BANNED_BY_SERVER';
      case 4:
        return 'JOIN_FAILED';
      case 5:
        return 'LEAVE_CHANNEL';
      case 6:
        return 'INVALID_APP_ID';
      case 7:
        return 'INVALID_CHANNEL_NAME';
      case 8:
        return 'INVALID_TOKEN';
      case 9:
        return 'TOKEN_EXPIRED';
      case 10:
        return 'REJECTED_BY_SERVER';
      case 11:
        return 'SETTING_PROXY_SERVER';
      case 12:
        return 'RENEW_TOKEN';
      case 13:
        return 'CLIENT_IP_ADDRESS_CHANGED';
      case 14:
        return 'KEEP_ALIVE_TIMEOUT';
      case 15:
        return 'REJOIN_SUCCESS';
      case 16:
        return 'LOST';
      case 17:
        return 'ECHO_TEST';
      case 18:
        return 'CLIENT_IP_ADDRESS_CHANGED_BY_USER';
      case 19:
        return 'SAME_UID_LOGIN';
      case 20:
        return 'TOO_MANY_BROADCASTERS';
      default:
        return 'UNKNOWN($reason)';
    }
  }

  // Log current engine state for debugging
  Future<void> _logEngineState() async {
    if (_engine == null) {
      print('❌ Engine is null');
      return;
    }

    try {
      final connectionState = await _engine!.getConnectionState();
      print('📊 Engine connection state: ${connectionState.index} (${_getConnectionStateName(connectionState.index)})');
    } catch (e) {
      print('❌ Error getting engine state: $e');
    }
  }

  // Debug method to log all media settings
  Future<void> _logMediaSettings({required bool isVideoCall}) async {
    print('📋 Current media settings:');
    print('  - Call type: ${isVideoCall ? 'VIDEO' : 'AUDIO'}');
    print('  - Engine initialized: ${_engine != null}');

    if (_engine != null) {
      try {
        final connectionState = await _engine!.getConnectionState();
        print('  - Connection state: ${connectionState.index} (${_getConnectionStateName(connectionState.index)})');
      } catch (e) {
        print('  - Connection state: ERROR - $e');
      }
    }
  }

  /// Helper method to setup video after joining channel
  /// This runs asynchronously but catches all errors to prevent unhandled exceptions
  void _setupVideoAfterJoin() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        if (_engine != null) {
          await _engine!.enableVideo();
          await _engine!.startPreview();
          print('🎥 Video enabled and preview started post-join');
        }
      } catch (e) {
        print('⚠️ Post-join video setup failed: $e');
        // Error is caught and logged - no rethrow to prevent unhandled async errors
      }
    }).catchError((error) {
      // Catch any errors from the Future itself
      print('⚠️ Error in post-join video setup: $error');
    });
  }

  // Enhanced join channel with optimized media options and retry logic
  Future<bool> joinChannel({required String channelId, required int uid, String? token, required bool isVideoCall, int maxRetries = 3}) async {
    if (!_isEngineValid()) {
      print('❌ Cannot join channel: Agora engine not initialized');
      return false;
    }

    // CRITICAL FIX: Check current connection state and cleanup if needed
    try {
      final currentState = await _engine!.getConnectionState();
      print('📊 Current connection state: ${currentState.index} (${_getConnectionStateName(currentState.index)})');

      // If already connected or connecting, leave first
      if (currentState == ConnectionStateType.connectionStateConnected ||
          currentState == ConnectionStateType.connectionStateConnecting ||
          currentState == ConnectionStateType.connectionStateReconnecting) {
        print('⚠️ Already in a channel, leaving first...');
        try {
          await _engine!.leaveChannel();
          // Wait for leave to complete
          await Future.delayed(const Duration(milliseconds: 500));
          print('✅ Left previous channel successfully');
        } catch (e) {
          print('⚠️ Warning leaving previous channel: $e');
        }
      }
    } catch (e) {
      print('⚠️ Could not check connection state: $e');
    }

    // Retry logic for slow network conditions
    int retryCount = 0;
    Exception? lastError;

    while (retryCount < maxRetries) {
      try {
        print('🚀 Joining Agora channel (attempt ${retryCount + 1}/$maxRetries):');
        print('  📍 Channel ID: "$channelId" (length: ${channelId.length})');
        print('  👤 UID: $uid');
        print('  🎥 Is Video Call: $isVideoCall');
        print('  📱 Platform: ${Platform.operatingSystem}');
        print('  🕐 Timestamp: ${DateTime.now().toIso8601String()}');

        // Log engine state
        await _logEngineState();

        // CRITICAL FIX: Enhanced channel options for better video support
        final options = ChannelMediaOptions(
          // Publishing options - explicit configuration
          publishCameraTrack: isVideoCall,
          publishMicrophoneTrack: true,
          publishScreenTrack: false,
          publishEncodedVideoTrack: false,
          publishMediaPlayerVideoTrack: false,
          publishMediaPlayerAudioTrack: false,

          // Subscription options - force subscribe to remote streams
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideoCall,

          // Channel configuration - use LiveBroadcasting for better video
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,

          // Audio/Video configuration
          enableAudioRecordingOrPlayout: true,

          // Disable encryption for empty token compatibility
          enableBuiltInMediaEncryption: false,
        );

        await _engine!.joinChannel(
          token: '', // token should be empty
          channelId: channelId,
          uid: uid,
          options: options,
        );

        print('✅ Successfully initiated channel join');

        // CRITICAL FIX: Force video subscription after join (for empty token compatibility)
        if (isVideoCall) {
          // Add a delay to allow channel join to complete - use unawaited pattern
          _setupVideoAfterJoin();
        }

        // Log channel options for debugging
        print('📋 Channel options used:');
        print('  - publishCameraTrack: ${options.publishCameraTrack}');
        print('  - publishMicrophoneTrack: ${options.publishMicrophoneTrack}');
        print('  - autoSubscribeAudio: ${options.autoSubscribeAudio}');
        print('  - autoSubscribeVideo: ${options.autoSubscribeVideo}');

        return true;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        print('❌ Error joining channel (attempt ${retryCount + 1}): $e');

        // Check if it's error -17 (already in channel) - try leaving and retry
        if (e.toString().contains('-17')) {
          print('🔄 Error -17 detected: Attempting to leave and rejoin...');
          try {
            await _engine!.leaveChannel();
            await Future.delayed(const Duration(milliseconds: 800));
          } catch (leaveError) {
            print('⚠️ Error leaving channel: $leaveError');
          }
        }

        retryCount++;
        if (retryCount < maxRetries) {
          // Exponential backoff: 500ms, 1000ms, 2000ms
          final delay = Duration(milliseconds: 500 * (1 << (retryCount - 1)));
          print('⏳ Retrying in ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
        }
      }
    }

    print('❌ Failed to join channel after $maxRetries attempts. Last error: $lastError');
    return false;
  }

  /// CRITICAL FIX: Validate and request permissions before media configuration
  Future<void> _validateAndRequestPermissions({required bool isVideoCall}) async {
    print('🔒 Validating permissions for ${isVideoCall ? 'video' : 'audio'} call...');

    try {
      // Check microphone permission (required for all calls)
      PermissionStatus micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        print('🎤 Requesting microphone permission...');
        micStatus = await Permission.microphone.request();
        if (!micStatus.isGranted) {
          throw Exception('Microphone permission is required for calls');
        }
      }
      print('✅ Microphone permission granted');

      // Check camera permission for video calls
      if (isVideoCall) {
        PermissionStatus cameraStatus = await Permission.camera.status;
        if (!cameraStatus.isGranted) {
          print('📹 Requesting camera permission...');
          cameraStatus = await Permission.camera.request();
          if (!cameraStatus.isGranted) {
            throw Exception('Camera permission is required for video calls');
          }
        }
        print('✅ Camera permission granted');
      }

      // Additional notification permission for Android 13+
      if (Platform.isAndroid) {
        PermissionStatus notificationStatus = await Permission.notification.status;
        if (!notificationStatus.isGranted) {
          print('🔔 Requesting notification permission...');
          await Permission.notification.request();
          // Don't fail if notification permission is denied, it's not critical for calling
        }
      }

      print('✅ All required permissions validated successfully');
    } catch (e) {
      print('❌ Permission validation failed: $e');
      throw Exception('Permission validation failed: $e');
    }
  }
}
