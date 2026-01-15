// lib/presentation/call_module/models/agora_callbacks.dart

/// Callback for when successfully joining a channel
typedef AgoraJoinChannelSuccessCallback = void Function(int uid, String channelId, int elapsed);

/// Callback for when a remote user joins the channel
typedef AgoraUserJoinedCallback = void Function(int remoteUid, int elapsed);

/// Callback for when a remote user leaves the channel
typedef AgoraUserOfflineCallback = void Function(int remoteUid, int reason);

/// Callback for audio volume indication updates
typedef AgoraAudioVolumeIndicationCallback = void Function(List<Map<String, dynamic>> speakers, int totalVolume);

/// Callback for network quality updates
typedef AgoraNetworkQualityCallback = void Function(int uid, int txQuality, int rxQuality);

/// Callback for connection state changes
typedef AgoraConnectionStateChangedCallback = void Function(int state, int reason);

/// Callback for first remote video frame rendered
typedef AgoraFirstRemoteVideoFrameCallback = void Function(int uid, int width, int height, int elapsed);

/// Callback for errors
typedef AgoraErrorCallback = void Function(dynamic error, String message);
