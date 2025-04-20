import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/constants.dart';

class AgoraService {
  RtcEngine? _engine;
  String? _token;
  String? _channel;
  int? _uid;
  bool _isInitialized = false;
  bool _isJoined = false;
  bool _isMicOn = true;
  bool _isCameraOn = false;
  bool _isScreenSharing = false;

  // Event callbacks
  final _onUserJoined = StreamController<UserJoinedEvent>.broadcast();
  final _onUserLeft = StreamController<UserLeftEvent>.broadcast();
  final _onUserMuteAudio = StreamController<UserMuteAudioEvent>.broadcast();
  final _onUserMuteVideo = StreamController<UserMuteVideoEvent>.broadcast();
  final _onLocalUserMuteAudio = StreamController<bool>.broadcast();
  final _onLocalUserMuteVideo = StreamController<bool>.broadcast();
  final _onLocalUserScreenShare = StreamController<bool>.broadcast();
  final _onJoinChannelSuccess = StreamController<JoinChannelSuccessEvent>.broadcast();
  final _onError = StreamController<ErrorEvent>.broadcast();
  final _onRemoteVideoStats = StreamController<RtcStats>.broadcast();
  final _onVolumeIndication = StreamController<VolumeIndicationEvent>.broadcast();

  // Getters for streams
  Stream<UserJoinedEvent> get onUserJoined => _onUserJoined.stream;
  Stream<UserLeftEvent> get onUserLeft => _onUserLeft.stream;
  Stream<UserMuteAudioEvent> get onUserMuteAudio => _onUserMuteAudio.stream;
  Stream<UserMuteVideoEvent> get onUserMuteVideo => _onUserMuteVideo.stream;
  Stream<bool> get onLocalUserMuteAudio => _onLocalUserMuteAudio.stream;
  Stream<bool> get onLocalUserMuteVideo => _onLocalUserMuteVideo.stream;
  Stream<bool> get onLocalUserScreenShare => _onLocalUserScreenShare.stream;
  Stream<JoinChannelSuccessEvent> get onJoinChannelSuccess => _onJoinChannelSuccess.stream;
  Stream<ErrorEvent> get onError => _onError.stream;
  Stream<RtcStats> get onRemoteVideoStats => _onRemoteVideoStats.stream;
  Stream<VolumeIndicationEvent> get onVolumeIndication => _onVolumeIndication.stream;

  // Status getters
  bool get isInitialized => _isInitialized;
  bool get isJoined => _isJoined;
  bool get isMicOn => _isMicOn;
  bool get isCameraOn => _isCameraOn;
  bool get isScreenSharing => _isScreenSharing;

  // Initialize Agora SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: AGORA_APP_ID,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // Register event handlers
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          _isJoined = true;
          _onJoinChannelSuccess.add(JoinChannelSuccessEvent(connection, elapsed));
        },
        onError: (ErrorCodeType err, String msg) {
          _onError.add(ErrorEvent(err, msg));
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          _onUserJoined.add(UserJoinedEvent(connection, uid, elapsed));
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          _onUserLeft.add(UserLeftEvent(connection, uid, reason));
        },
        onRemoteAudioStateChanged: (RtcConnection connection, int uid, RemoteAudioState state, RemoteAudioStateReason reason, int elapsed) {
          if (state == RemoteAudioState.remoteAudioStateStopped) {
            _onUserMuteAudio.add(UserMuteAudioEvent(uid, true));
          } else if (state == RemoteAudioState.remoteAudioStateDecoding) {
            _onUserMuteAudio.add(UserMuteAudioEvent(uid, false));
          }
        },
        onRemoteVideoStateChanged: (RtcConnection connection, int uid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
          if (state == RemoteVideoState.remoteVideoStateStopped) {
            _onUserMuteVideo.add(UserMuteVideoEvent(uid, true));
          } else if (state == RemoteVideoState.remoteVideoStateDecoding) {
            _onUserMuteVideo.add(UserMuteVideoEvent(uid, false));
          }
        },
        onRtcStats: (RtcConnection connection, RtcStats stats) {
          _onRemoteVideoStats.add(stats);
        },
        // onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume) {
        //   _onVolumeIndication.add(VolumeIndicationEvent(connection, speakers, totalVolume));
        // },
      ),
    );

    // Enable video
    await _engine!.enableVideo();

    // Enable dual stream mode
    await _engine!.enableDualStreamMode(enabled: true);

    // Set video encoder configuration
    await _engine!.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 15,
        bitrate: 1000,
      ),
    );

    _isInitialized = true;
  }

  // Join a channel
  Future<void> joinChannel(String token, String channel, int uid) async {
    if (!_isInitialized) {
      await initialize();
    }

    _token = token;
    _channel = channel;
    _uid = uid;

    // Set client role
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // Join the channel
    await _engine!.joinChannel(
      token: token,
      channelId: channel,
      uid: uid,
      options: const ChannelMediaOptions(
        publishScreenTrack: true,
        publishSecondaryScreenTrack: true,
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        publishScreenCaptureAudio: true,
        publishScreenCaptureVideo: true,
        autoSubscribeAudio: true,
        publishMediaPlayerAudioTrack: true,
        clientRoleType: ClientRoleType
            .clientRoleBroadcaster,
      ),
    );
  }

  // Leave the channel
  Future<void> leaveChannel() async {
    if (!_isInitialized || !_isJoined) return;

    await _engine!.leaveChannel();
    _isJoined = false;
  }

  // Toggle local audio (microphone)
  Future<void> toggleMicrophone() async {
    if (!_isInitialized || !_isJoined) return;

    _isMicOn = !_isMicOn;
    await _engine!.enableLocalAudio(_isMicOn);
    _onLocalUserMuteAudio.add(_isMicOn);
  }

  // Set microphone state directly
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (!_isInitialized || !_isJoined) return;
    if (_isMicOn == enabled) return;

    _isMicOn = enabled;
    await _engine!.enableLocalAudio(_isMicOn);
    _onLocalUserMuteAudio.add(_isMicOn);
  }

  // Toggle local video (camera)
  Future<void> toggleCamera() async {
    if (!_isInitialized || !_isJoined) return;

    _isCameraOn = !_isCameraOn;

    if (_isScreenSharing && _isCameraOn) {
      // Stop screen sharing first
      await stopScreenSharing();
    }

    await _engine!.enableLocalVideo(_isCameraOn);
    _onLocalUserMuteVideo.add(_isCameraOn);
  }

  // Set camera state directly
  Future<void> setCameraEnabled(bool enabled) async {
    if (!_isInitialized || !_isJoined) return;
    if (_isCameraOn == enabled) return;

    _isCameraOn = enabled;

    if (_isScreenSharing && _isCameraOn) {
      // Stop screen sharing first
      await stopScreenSharing();
    }

    await _engine!.enableLocalVideo(_isCameraOn);
    _onLocalUserMuteVideo.add(_isCameraOn);
  }

  // Start screen sharing
  Future<void> startScreenSharing() async {
    if (!_isInitialized || !_isJoined) return;

    if (_isCameraOn) {
      // Turn off camera first
      await setCameraEnabled(false);
    }

    // Start screen sharing
    await _engine!.startScreenCapture(const ScreenCaptureParameters2(
      captureAudio: false,
      captureVideo: true,
    ));

    // Publish screen share video stream
    await _engine!.updateChannelMediaOptions(
      const ChannelMediaOptions(
        publishScreenTrack: true,
        publishCameraTrack: false,
      ),
    );

    _isScreenSharing = true;
    _onLocalUserScreenShare.add(_isScreenSharing);
  }

  // Stop screen sharing
  Future<void> stopScreenSharing() async {
    if (!_isInitialized || !_isJoined || !_isScreenSharing) return;

    // Stop publishing screen share
    await _engine!.updateChannelMediaOptions(
      const ChannelMediaOptions(
        publishScreenTrack: false,
        publishCameraTrack: false,
      ),
    );

    // Stop screen capture
    await _engine!.stopScreenCapture();

    _isScreenSharing = false;
    _onLocalUserScreenShare.add(_isScreenSharing);
  }

  // Toggle screen sharing
  Future<void> toggleScreenSharing() async {
    if (_isScreenSharing) {
      await stopScreenSharing();
    } else {
      await startScreenSharing();
    }
  }

  // Enable/disable volume indicator
  Future<void> enableVolumeIndication(bool enabled) async {
    if (!_isInitialized) return;

    if (enabled) {
      await _engine!.enableAudioVolumeIndication(
        interval: 500,
        smooth: 3,
        reportVad: true,
      );
    } else {
      await _engine!.enableAudioVolumeIndication(
        interval: 0,
        smooth: 3,
        reportVad: false,
      );
    }
  }

  // Render local video
  Widget createLocalView() {
    if (!_isInitialized) return Container();

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  // Render local screen share
  Widget createLocalScreenShareView() {
    if (!_isInitialized || !_isScreenSharing) return Container();

    return AgoraVideoView(
      controller: VideoViewController(
        canvas: const VideoCanvas(
          uid: 0,
          sourceType: VideoSourceType.videoSourceRemote,
        ),
        // connection: RtcConnection(channelId: 'channelName'),
        useFlutterTexture: true,
        useAndroidSurfaceView: true,
        rtcEngine: _engine!,
      ),
    );
  }

  // Render remote video
  Widget createRemoteView(int uid) {
    if (!_isInitialized) return Container();

    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: uid),
        useFlutterTexture: true,
        useAndroidSurfaceView: true,
      ),
    );
  }

  // Dispose resources
  void dispose() {
    _onUserJoined.close();
    _onUserLeft.close();
    _onUserMuteAudio.close();
    _onUserMuteVideo.close();
    _onLocalUserMuteAudio.close();
    _onLocalUserMuteVideo.close();
    _onLocalUserScreenShare.close();
    _onJoinChannelSuccess.close();
    _onError.close();
    _onRemoteVideoStats.close();
    _onVolumeIndication.close();

    _engine?.leaveChannel();
    _engine?.release();
    _engine = null;
    _isInitialized = false;
    _isJoined = false;
  }
}

// Event classes
class UserJoinedEvent {
  final RtcConnection connection;
  final int uid;
  final int elapsed;

  UserJoinedEvent(this.connection, this.uid, this.elapsed);
}

class UserLeftEvent {
  final RtcConnection connection;
  final int uid;
  final UserOfflineReasonType reason;

  UserLeftEvent(this.connection, this.uid, this.reason);
}

class UserMuteAudioEvent {
  final int uid;
  final bool muted;

  UserMuteAudioEvent(this.uid, this.muted);
}

class UserMuteVideoEvent {
  final int uid;
  final bool muted;

  UserMuteVideoEvent(this.uid, this.muted);
}

class JoinChannelSuccessEvent {
  final RtcConnection connection;
  final int elapsed;

  JoinChannelSuccessEvent(this.connection, this.elapsed);
}

class ErrorEvent {
  final ErrorCodeType error;
  final String message;

  ErrorEvent(this.error, this.message);
}

class VolumeIndicationEvent {
  final RtcConnection connection;
  final List<AudioVolumeInfo> speakers;
  final int totalVolume;

  VolumeIndicationEvent(this.connection, this.speakers, this.totalVolume);
}