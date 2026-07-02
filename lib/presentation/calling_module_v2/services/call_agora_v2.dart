import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

/// Calling module v2 — Agora media engine wrapper (Flutter).
///
/// Joins with `joinChannelWithUserAccount` (string uid) so web and Flutter
/// participants of the same call resolve each other's tracks — the same
/// unified uid scheme the Meeting module uses. Maps Agora SDK events onto
/// the call-state callbacks the controller expects (§3.3/§3.5).
class CallAgoraV2 {
  RtcEngine? _engine;
  bool _joined = false;
  int? _remoteUid;
  bool _remoteVideoOn = false;

  // Callbacks wired by the controller.
  VoidCallback? onRemoteMediaConnected;
  VoidCallback? onRemoteLeft;
  void Function(bool hasVideo)? onRemoteVideoChanged;
  VoidCallback? onReconnecting;
  VoidCallback? onReconnected;
  VoidCallback? onTokenWillExpire;

  /// 0(worst)–5(best) normalized quality for the UI banner.
  void Function(int quality)? onNetworkQuality;

  RtcEngine? get engine => _engine;
  int? get remoteUid => _remoteUid;
  bool get remoteVideoOn => _remoteVideoOn;
  bool get isJoined => _joined;

  Future<void> join({
    required String appId,
    required String channel,
    required String token,
    required String userAccount,
    required bool withVideo,
  }) async {
    if (_joined) return;

    final engine = createAgoraRtcEngine();
    _engine = engine;
    await engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint('📞 [CallAgoraV2] joined channel ${connection.channelId}');
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        _remoteUid = remoteUid;
        // Remote party present in the channel — communication profile
        // publishes immediately, so treat this as media established (§3.3).
        onRemoteMediaConnected?.call();
      },
      onUserOffline: (connection, remoteUid, reason) {
        if (_remoteUid == remoteUid) {
          _remoteUid = null;
          _remoteVideoOn = false;
          onRemoteLeft?.call();
        }
      },
      onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
        final on = state == RemoteVideoState.remoteVideoStateDecoding ||
            state == RemoteVideoState.remoteVideoStateStarting;
        if (on != _remoteVideoOn) {
          _remoteVideoOn = on;
          onRemoteVideoChanged?.call(on);
        }
      },
      onConnectionStateChanged: (connection, state, reason) {
        if (state == ConnectionStateType.connectionStateReconnecting) {
          onReconnecting?.call();
        } else if (state == ConnectionStateType.connectionStateConnected) {
          onReconnected?.call();
        }
      },
      onTokenPrivilegeWillExpire: (connection, token) {
        onTokenWillExpire?.call();
      },
      onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
        if (remoteUid != 0) return; // local report only
        final worst = _qualityRank(txQuality) > _qualityRank(rxQuality)
            ? _qualityRank(txQuality)
            : _qualityRank(rxQuality);
        onNetworkQuality?.call((6 - worst).clamp(0, 5));
      },
    ));

    await engine.enableAudio();
    if (withVideo) {
      await engine.enableVideo();
      await engine.startPreview();
    } else {
      await engine.disableVideo();
    }

    // Audio routing (§3.7): earpiece for audio calls, speaker for video.
    await engine.setDefaultAudioRouteToSpeakerphone(withVideo);

    await engine.joinChannelWithUserAccount(
      token: token,
      channelId: channel,
      userAccount: userAccount,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishMicrophoneTrack: true,
        publishCameraTrack: withVideo,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
    _joined = true;
  }

  static int _qualityRank(QualityType quality) {
    switch (quality) {
      case QualityType.qualityExcellent:
        return 1;
      case QualityType.qualityGood:
        return 2;
      case QualityType.qualityPoor:
        return 3;
      case QualityType.qualityBad:
        return 4;
      case QualityType.qualityVbad:
        return 5;
      case QualityType.qualityDown:
        return 6;
      default:
        return 1;
    }
  }

  Future<void> setMuted(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> setVideoEnabled(bool enabled) async {
    final engine = _engine;
    if (engine == null) return;
    if (enabled) {
      await engine.enableVideo();
      await engine.startPreview();
      await engine.updateChannelMediaOptions(const ChannelMediaOptions(
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ));
    } else {
      await engine.stopPreview();
      await engine.updateChannelMediaOptions(const ChannelMediaOptions(
        publishCameraTrack: false,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ));
    }
  }

  Future<void> setSpeakerphone(bool enabled) async {
    await _engine?.setEnableSpeakerphone(enabled);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> renewToken(String token) async {
    await _engine?.renewToken(token);
  }

  Future<void> leave() async {
    final engine = _engine;
    _engine = null;
    _joined = false;
    _remoteUid = null;
    _remoteVideoOn = false;
    if (engine == null) return;
    try {
      await engine.stopPreview();
    } catch (_) {}
    try {
      await engine.leaveChannel();
    } catch (_) {}
    try {
      await engine.release();
    } catch (_) {}
  }
}
