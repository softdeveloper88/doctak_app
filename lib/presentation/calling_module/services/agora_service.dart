import 'dart:async';
import 'dart:io';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

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

      await _engine?.initialize(const RtcEngineContext(
        appId: AppConstants.agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

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
            print('✅ onJoinChannelSuccess: channel=${connection.channelId}, elapsed=${elapsed}ms');
            if (_onJoinChannelSuccess != null) {
              _onJoinChannelSuccess!(0, connection.channelId ?? "", elapsed);
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('👥 onUserJoined: uid=$remoteUid, channel=${connection.channelId}, elapsed=${elapsed}ms');
            if (_onUserJoined != null) {
              _onUserJoined!(remoteUid, elapsed);
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            print('👋 onUserOffline: uid=$remoteUid, channel=${connection.channelId}, reason=${reason.index}');
            if (_onUserOffline != null) {
              _onUserOffline!(remoteUid, reason.index);
            }
          },
          onAudioVolumeIndication: (RtcConnection connection,
              List<AudioVolumeInfo> speakers, int totalVolume, int s) {
            if (speakers.isEmpty || _onAudioVolumeIndication == null) return;

            // Convert speakers list to a more usable format
            try {
              final List<Map<String, dynamic>> speakersData = speakers.map((
                  speaker) {
                return {
                  'uid': speaker.uid,
                  'volume': speaker.volume ?? 0,
                  'vad': speaker.vad ?? 0,
                };
              }).toList();

              _onAudioVolumeIndication!(speakersData, totalVolume);
            }catch(e){
              debugPrint('Error processing audio volume indication: $e');
            }
          },
          onNetworkQuality: (RtcConnection connection, int uid,
              QualityType txQuality, QualityType rxQuality) {
            if (_onNetworkQuality != null) {
              _onNetworkQuality!(uid, txQuality.index, rxQuality.index);
            }
          },
          onConnectionStateChanged: (RtcConnection connection,
              ConnectionStateType state, ConnectionChangedReasonType reason) {
            print('🔄 onConnectionStateChanged: state=${state.index}(${_getConnectionStateName(state.index)}), reason=${reason.index}(${_getConnectionReasonName(reason.index)})');
            if (_onConnectionStateChanged != null) {
              _onConnectionStateChanged!(state.index, reason.index);
            }
          },
          onFirstRemoteVideoFrame: (RtcConnection connection, int remoteUid,
              int width, int height, int elapsed) {
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
          onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid,
              RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
            print('📺 onRemoteVideoStateChanged: uid=$remoteUid, state=${state.index}, reason=${reason.index}, elapsed=${elapsed}ms');
          },
          onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid,
              RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
            print('🔊 onRemoteAudioStateChanged: uid=$remoteUid, state=${state.index}, reason=${reason.index}, elapsed=${elapsed}ms');
          },
          onLocalVideoStateChanged: (VideoSourceType source, LocalVideoStreamState state,
              LocalVideoStreamReason reason) {
            print('📱 onLocalVideoStateChanged: source=${source.index}, state=${state.index}, reason=${reason.index}');
          },
          onLocalAudioStateChanged: (RtcConnection connection, LocalAudioStreamState state,
              LocalAudioStreamReason reason) {
            print('🎤 onLocalAudioStateChanged: state=${state.index}, reason=${reason.index}');
          }
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
    if (_engine == null) return;
    
    print('🎥 Configuring media settings: isVideoCall=$isVideoCall, platform=${Platform.operatingSystem}');
    
    try {
      // Set client role first
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      print('✅ Client role set to broadcaster');
      
      // iOS-specific audio session configuration
      if (Platform.isIOS) {
        await _configureIOSAudioSession();
      }

      // Configure audio with platform-specific settings
      if (Platform.isIOS) {
        // iOS optimized audio profile
        await _engine!.setAudioProfile(
          profile: AudioProfileType.audioProfileMusicHighQuality,
          scenario: AudioScenarioType.audioScenarioGameStreaming, // Better for iOS
        );
      } else {
        // Android optimized audio profile
        await _engine!.setAudioProfile(
          profile: AudioProfileType.audioProfileMusicHighQuality,
          scenario: AudioScenarioType.audioScenarioDefault,
        );
      }

      // Enable audio processing for clear audio
      await _engine!.enableAudioVolumeIndication(
        interval: 300,  // More frequent updates for better responsiveness
        smooth: 3, 
        reportVad: true
      );
      
      // Audio enhancement parameters
      await _engine!.setParameters('{"che.audio.enable_aec": true}');
      await _engine!.setParameters('{"che.audio.enable_agc": true}');
      await _engine!.setParameters('{"che.audio.enable_ns": true}');
      await _engine!.setParameters('{"che.audio.aec.enable": true}');
      await _engine!.setParameters('{"che.audio.agc.enable": true}');
      await _engine!.setParameters('{"che.audio.ns.enable": true}');

      print('✅ Audio settings configured');

      if (isVideoCall) {
        // Enhanced video configuration with platform optimization
        await _engine!.enableVideo();
        
        // Platform-specific video encoder configuration
        if (Platform.isIOS) {
          // iOS optimized settings
          await _engine!.setVideoEncoderConfiguration(
            const VideoEncoderConfiguration(
              dimensions: VideoDimensions(width: 640, height: 480),
              frameRate: 15,
              bitrate: 900,  // Slightly higher for iOS
              minBitrate: 500,
              orientationMode: OrientationMode.orientationModeAdaptive,
              degradationPreference: DegradationPreference.maintainQuality, // iOS handles quality better
              mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
              codecType: VideoCodecType.videoCodecH264,
            ),
          );
        } else {
          // Android optimized settings
          await _engine!.setVideoEncoderConfiguration(
            const VideoEncoderConfiguration(
              dimensions: VideoDimensions(width: 640, height: 480),
              frameRate: 15,
              bitrate: 800,
              minBitrate: 400,
              orientationMode: OrientationMode.orientationModeAdaptive,
              degradationPreference: DegradationPreference.maintainFramerate, // Android prefers framerate
              mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
              codecType: VideoCodecType.videoCodecH264,
            ),
          );
        }

        // Enable dual stream mode for adaptive quality
        await _engine!.enableDualStreamMode(enabled: true);
        
        // Set default remote video stream to high quality - removed as it requires specific UID
        // await _engine!.setRemoteDefaultVideoStreamType(
        //   streamType: VideoStreamType.videoStreamHigh,
        // );

        // Platform-specific video parameters
        if (Platform.isIOS) {
          // iOS optimized parameters
          await _engine!.setParameters('{"che.video.h264.profile": 77}'); // Main profile for iOS
          await _engine!.setParameters('{"che.video.h264.preferFrameRateOverImageQuality": false}');
          await _engine!.setParameters('{"che.video.contentHint": "motion"}');
          await _engine!.setParameters('{"che.video.enablePreEncode": true}'); // iOS hardware acceleration
          await _engine!.setParameters('{"che.video.lowBitRateStreamParameter": {"width":160,"height":120,"frameRate":15,"bitRate":80}}');
        } else {
          // Android optimized parameters
          await _engine!.setParameters('{"che.video.h264.profile": 66}'); // Baseline profile for Android compatibility
          await _engine!.setParameters('{"che.video.h264.preferFrameRateOverImageQuality": true}'); // Android prefers framerate
          await _engine!.setParameters('{"che.video.contentHint": "motion"}');
          await _engine!.setParameters('{"che.video.lowBitRateStreamParameter": {"width":160,"height":120,"frameRate":15,"bitRate":65}}');
        }

        // Platform-specific camera settings
        if (Platform.isIOS) {
          await _engine!.setCameraCapturerConfiguration(
            const CameraCapturerConfiguration(
              cameraDirection: CameraDirection.cameraFront,
            ),
          );
          
          // iOS camera optimization
          await _engine!.setParameters('{"che.video.camera.captureMode": 1}'); // Auto capture mode
        } else {
          await _engine!.setCameraCapturerConfiguration(
            const CameraCapturerConfiguration(
              cameraDirection: CameraDirection.cameraFront,
            ),
          );
        }

        // Start local video preview with error handling
        try {
          await _engine!.startPreview();
          print('✅ Video preview started');
        } catch (e) {
          print('❌ Error starting preview: $e');
          // Continue anyway - preview might still work during call
        }

        // Platform-specific audio routing for video calls
        if (Platform.isIOS) {
          // iOS audio routing
          await _engine!.setDefaultAudioRouteToSpeakerphone(true);
          await _engine!.setEnableSpeakerphone(true);
          // iOS specific audio session management
          await _engine!.setParameters('{"che.audio.keep_audiosession": true}');
        } else {
          // Android audio routing
          await _engine!.setDefaultAudioRouteToSpeakerphone(true);
          await _engine!.setEnableSpeakerphone(true);
        }
        
        print('✅ Video settings configured');
      } else {
        // Audio call - disable video with platform-specific settings
        await _engine!.disableVideo();
        
        if (Platform.isIOS) {
          // iOS audio call routing (to earpiece)
          await _engine!.setDefaultAudioRouteToSpeakerphone(false);
          await _engine!.setParameters('{"che.audio.forceAudioRoute": 0}'); // Route to earpiece
        } else {
          // Android audio call routing
          await _engine!.setDefaultAudioRouteToSpeakerphone(false);
        }
        
        print('✅ Audio-only call configured for ${Platform.operatingSystem}');
      }

    } catch (e) {
      print('❌ Error configuring media settings: $e');
      rethrow;
    }
  }
  // iOS-specific audio session configuration
  Future<void> _configureIOSAudioSession() async {
    try {
      // iOS audio session optimization
      await _engine!.setParameters('{"che.audio.audioSession.category": "AVAudioSessionCategoryPlayAndRecord"}');
      await _engine!.setParameters('{"che.audio.audioSession.categoryOptions": ["AVAudioSessionCategoryOptionAllowBluetooth", "AVAudioSessionCategoryOptionDefaultToSpeaker"]}');
      await _engine!.setParameters('{"che.audio.audioSession.mode": "AVAudioSessionModeVideoChat"}');
      await _engine!.setParameters('{"che.audio.enable_aec": true}');
      await _engine!.setParameters('{"che.audio.enable_ns": true}');
      await _engine!.setParameters('{"che.audio.enable_agc": true}');
      print('✅ iOS audio session configured');
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
        await _engine!.updateChannelMediaOptions(
          const ChannelMediaOptions(
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
            autoSubscribeVideo: true,
          ),
        );
      } else {
        // Restore audio settings
        await _engine!.updateChannelMediaOptions(
          const ChannelMediaOptions(
            publishCameraTrack: false,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
            autoSubscribeVideo: false,
          ),
        );
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
    await _engine!.updateChannelMediaOptions(
      const ChannelMediaOptions(
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: false,
      ),
    );

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
      case 1: return 'DISCONNECTED';
      case 2: return 'CONNECTING';
      case 3: return 'CONNECTED';
      case 4: return 'RECONNECTING';
      case 5: return 'FAILED';
      default: return 'UNKNOWN($state)';
    }
  }
  
  // Helper method to get connection reason name for debugging
  String _getConnectionReasonName(int reason) {
    switch (reason) {
      case 0: return 'CONNECTING';
      case 1: return 'JOIN_SUCCESS';
      case 2: return 'INTERRUPTED';
      case 3: return 'BANNED_BY_SERVER';
      case 4: return 'JOIN_FAILED';
      case 5: return 'LEAVE_CHANNEL';
      case 6: return 'INVALID_APP_ID';
      case 7: return 'INVALID_CHANNEL_NAME';
      case 8: return 'INVALID_TOKEN';
      case 9: return 'TOKEN_EXPIRED';
      case 10: return 'REJECTED_BY_SERVER';
      case 11: return 'SETTING_PROXY_SERVER';
      case 12: return 'RENEW_TOKEN';
      case 13: return 'CLIENT_IP_ADDRESS_CHANGED';
      case 14: return 'KEEP_ALIVE_TIMEOUT';
      case 15: return 'REJOIN_SUCCESS';
      case 16: return 'LOST';
      case 17: return 'ECHO_TEST';
      case 18: return 'CLIENT_IP_ADDRESS_CHANGED_BY_USER';
      case 19: return 'SAME_UID_LOGIN';
      case 20: return 'TOO_MANY_BROADCASTERS';
      default: return 'UNKNOWN($reason)';
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

  // Enhanced join channel with optimized media options
  Future<bool> joinChannel({
    required String channelId,
    required int uid,
    String? token,
    required bool isVideoCall,
  }) async {
    if (!_isEngineValid()) {
      print('❌ Cannot join channel: Agora engine not initialized');
      return false;
    }

    try {
      print('🚀 Joining channel: $channelId with UID: $uid, isVideo: $isVideoCall');
      print('📊 Current engine state before join:');
      await _logEngineState();
      await _logMediaSettings(isVideoCall: isVideoCall);
      
      // Enhanced channel media options for better compatibility
      final options = ChannelMediaOptions(
        // Publishing options
        publishCameraTrack: isVideoCall,
        publishMicrophoneTrack: true,
        publishCustomVideoTrack: false,
        publishCustomAudioTrack: false,
        publishScreenTrack: false,
        
        // Subscription options
        autoSubscribeAudio: true,
        autoSubscribeVideo: isVideoCall,
        
        // Channel configuration
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        
        // Audio/Video quality options for better performance
        audioDelayMs: 0,
        enableBuiltInMediaEncryption: false,
        
        // Additional options for stability
        isInteractiveAudience: false,
      );

      await _engine!.joinChannel(
        token: token ?? '',
        channelId: channelId,
        uid: uid,
        options: options,
      );

      print('✅ Successfully initiated channel join');
      
      // Log channel options for debugging
      print('📋 Channel options used:');
      print('  - publishCameraTrack: ${options.publishCameraTrack}');
      print('  - publishMicrophoneTrack: ${options.publishMicrophoneTrack}');
      print('  - autoSubscribeAudio: ${options.autoSubscribeAudio}');
      print('  - autoSubscribeVideo: ${options.autoSubscribeVideo}');
      print('  - channelProfile: ${options.channelProfile?.index}');
      print('  - clientRoleType: ${options.clientRoleType?.index}');
      
      return true;
    } catch (e) {
      print('❌ Error joining channel: $e');
      return false;
    }
  }
}