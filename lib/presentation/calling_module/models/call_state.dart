// lib/presentation/call_module/models/call_state.dart
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';

/// Enum representing the different call types
enum CallType {
  audio,
  video
}

/// Enum representing the different call states
enum CallConnectionState {
  connecting,
  connected,
  reconnecting,
  disconnected,
  failed
}

/// Model representing the state of a call
class CallState {
  final String callId;
  final CallType callType;
  final CallConnectionState connectionState;
  final bool isLocalUserJoined;
  final bool isRemoteUserJoined;
  final bool isLocalVideoEnabled;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final bool isLocalVideoFullScreen;
  final bool isControlsVisible;
  final int? remoteUid;
  final int callDuration;
  final int? networkQuality;
  final bool isLocalUserSpeaking;
  final bool isRemoteUserSpeaking;
  final bool isUsingLowerVideoQuality;

  CallState({
    required this.callId,
    required this.callType,
    this.connectionState = CallConnectionState.connecting,
    this.isLocalUserJoined = false,
    this.isRemoteUserJoined = false,
    this.isLocalVideoEnabled = true,
    this.isMuted = false,
    this.isSpeakerOn = true,
    this.isFrontCamera = true,
    this.isLocalVideoFullScreen = false,
    this.isControlsVisible = true,
    this.remoteUid,
    this.callDuration = 0,
    this.networkQuality,
    this.isLocalUserSpeaking = false,
    this.isRemoteUserSpeaking = false,
    this.isUsingLowerVideoQuality = false,
  });

  /// Create a copy of this CallState with the given fields replaced with new values
  CallState copyWith({
    String? callId,
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
    return CallState(
      callId: callId ?? this.callId,
      callType: callType ?? this.callType,
      connectionState: connectionState ?? this.connectionState,
      isLocalUserJoined: isLocalUserJoined ?? this.isLocalUserJoined,
      isRemoteUserJoined: isRemoteUserJoined ?? this.isRemoteUserJoined,
      isLocalVideoEnabled: isLocalVideoEnabled ?? this.isLocalVideoEnabled,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isLocalVideoFullScreen: isLocalVideoFullScreen ?? this.isLocalVideoFullScreen,
      isControlsVisible: isControlsVisible ?? this.isControlsVisible,
      remoteUid: remoteUid ?? this.remoteUid,
      callDuration: callDuration ?? this.callDuration,
      networkQuality: networkQuality ?? this.networkQuality,
      isLocalUserSpeaking: isLocalUserSpeaking ?? this.isLocalUserSpeaking,
      isRemoteUserSpeaking: isRemoteUserSpeaking ?? this.isRemoteUserSpeaking,
      isUsingLowerVideoQuality: isUsingLowerVideoQuality ?? this.isUsingLowerVideoQuality,
    );
  }

  /// Get a string representation of the network quality
  String getNetworkQualityText({required BuildContext context}) {
    switch (networkQuality) {
      case 1: return translation(context).lbl_network_quality_excellent;
      case 2: return translation(context).lbl_network_quality_good;
      case 3: return translation(context).lbl_network_quality_fair;
      case 4: return translation(context).lbl_network_quality_poor;
      case 5:
      case 6: return translation(context).lbl_network_quality_very_poor;
      default: return translation(context).lbl_network_quality_unknown;
    }
  }

  /// Get a color for the network quality
  Color getNetworkQualityColor() {
    switch (networkQuality) {
      case 1: return Colors.green;
      case 2: return Colors.green.shade300;
      case 3: return Colors.yellow;
      case 4: return Colors.orange;
      case 5:
      case 6: return Colors.red;
      default: return Colors.grey;
    }
  }

  /// Get an icon for the network quality
  IconData getNetworkQualityIcon() {
    switch (networkQuality) {
      case 1:
      case 2:
      case 3: return Icons.network_wifi;
      case 4:
      case 5:
      case 6: return Icons.signal_wifi_statusbar_connected_no_internet_4;
      default: return Icons.signal_wifi_statusbar_null;
    }
  }

  /// Format call duration into a string (mm:ss or hh:mm:ss)
  String get formattedCallDuration {
    final int hours = callDuration ~/ 3600;
    final int minutes = (callDuration % 3600) ~/ 60;
    final int seconds = callDuration % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
