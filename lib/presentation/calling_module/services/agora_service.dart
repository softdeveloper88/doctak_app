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
    _engine?.registerEventHandler(
      RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (_onJoinChannelSuccess != null) {
              _onJoinChannelSuccess!(0, connection.channelId ?? "", elapsed);
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (_onUserJoined != null) {
              _onUserJoined!(remoteUid, elapsed);
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
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
            if (_onConnectionStateChanged != null) {
              _onConnectionStateChanged!(state.index, reason.index);
            }
          },
          onFirstRemoteVideoFrame: (RtcConnection connection, int remoteUid,
              int width, int height, int elapsed) {
            if (_onFirstRemoteVideoFrame != null) {
              _onFirstRemoteVideoFrame!(remoteUid, width, height, elapsed);
            }
          },
          onError: (ErrorCodeType err, String msg) {
            if (_onError != null) {
              _onError!(err, msg);
            }
          }
      ),
    );
  }

  // Join channel
  Future<bool> joinChannel({
    required String channelId,
    required int uid,
    String? token,
    required bool isVideoCall,
  }) async {
    try {
      if (_engine == null) return false;

      print('AgoraService: Joining channel $channelId with token: ${token ??
          'empty'}, uid: $uid, isVideoCall: $isVideoCall');

      // Join the channel with updated options
      await _engine!.joinChannel(
        token: '',
        channelId: channelId,
        uid: uid,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      return true;
    } catch (e) {
      print('Channel ID: $channelId, UID: $uid, Token empty: ${token == null ||
          token.isEmpty}');

      print('Join channel error: $e');
      return false;
    }
  }

  // Improved method to configure media settings
  Future<void> configureMediaSettings({required bool isVideoCall}) async {
    if (_engine == null) return;
    try {
      // Set client role
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Configure audio - match web implementation with AEC, ANS, AGC
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioDefault,
      );

      // Enable audio processing options to match web
      await _engine!.enableAudioVolumeIndication(interval: 500, smooth: 3, reportVad: true);
      await _engine!.setParameters('{"che.audio.enable_aec": true}');
      await _engine!.setParameters('{"che.audio.enable_agc": true}');
      await _engine!.setParameters('{"che.audio.enable_ns": true}');

      // Set default audio route
      if (isVideoCall) {
        await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      } else {
        await _engine!.setDefaultAudioRouteToSpeakerphone(false);
      }

      if (isVideoCall) {
        // Enable video
        await _engine!.enableVideo();

        // Set video encoder configuration to match web implementation's 480p_1 preset
        await _engine!.setVideoEncoderConfiguration(
          const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 640, height: 480), // Match web resolution
            frameRate: 15,
            // minFrameRate: FrameRate.frameRateFps10,
            bitrate: 500, // Reduced for better compatibility
            minBitrate: 400,
            orientationMode: OrientationMode.orientationModeAdaptive,
            degradationPreference: DegradationPreference.maintainQuality,
            mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled, // Enable mirroring as in web
          ),
        );

        // Enable dual stream mode for better cross-platform compatibility
        await _engine!.enableDualStreamMode(enabled: true);
        await _engine!.setRemoteVideoStreamType(
          uid: 0, // Remote user
          streamType: VideoStreamType.videoStreamLow, // Start with low stream, can switch based on quality
        );

        // Configure remote video rendering mode to match web's object-fit: cover
        await _engine!.setRemoteRenderMode(
          uid: 0,
          renderMode: RenderModeType.renderModeFit,
          mirrorMode: VideoMirrorModeType.videoMirrorModeDisabled,
        );

        // Set content hints to match web optimization mode
        await _engine!.setParameters('{"che.video.contentHint": "balanced"}');

        // Start preview
        await _engine!.startPreview();
      } else {
        // Audio call configuration
        await _engine!.disableVideo();
      }
    } catch (e) {
      print('Error configuring media settings: $e');
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
      // First leave channel if still connected
      try {
        await _engine!.leaveChannel();
      } catch (e) {
        print('Warning: Error leaving channel: $e');
        // Continue with release even if leave fails
      }

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
}