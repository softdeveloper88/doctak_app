// import 'dart:async';
// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// const appId = "f2cf99f1193a40e69546157883b2159f";
// const token = "007eJxTYJj24FzjNbk6Ub3mZ48q5T9cq521xeer8n8uS3Pxjtw45qkKDGlGyWmWlmmGhpbGiSYGqWaWpiZmhqbmFhbGSUaGppZp3r/npjcEMjI8E5JkYIRCEJ+NISU/uSQxm4EBAJ1iH6U=";
// const channel = "doctak";
//
// class VideoCallScreen extends StatefulWidget {
//   const VideoCallScreen({Key? key}) : super(key: key);
//
//   @override
//   State<VideoCallScreen> createState() => _VideoCallScreenState();
// }
//
// class _VideoCallScreenState extends State<VideoCallScreen> {
//   int? _remoteUid;
//   bool _localUserJoined = false;
//   bool _isMuted = false;
//   bool _isVideoDisabled = false;
//   bool _isFrontCamera = true;
//   late RtcEngine _engine;
//   Timer? _callTimer;
//   int _callDuration = 0;
//   List<Widget> _remoteUsers = [];
//   bool _isSpeakerEnabled = true;
//   int? _networkQuality;
//
//   @override
//   void initState() {
//     super.initState();
//     _initAgora();
//   }
//
//   Future<void> _initAgora() async {
//     try {
//       await _requestPermissions();
//       await _setupEngine();
//       await _joinChannel();
//     } catch (e) {
//       _showErrorDialog("Initialization Error", e.toString());
//     }
//   }
//
//   Future<void> _requestPermissions() async {
//     final status = await [Permission.microphone, Permission.camera].request();
//     if (status[Permission.camera] != PermissionStatus.granted ||
//         status[Permission.microphone] != PermissionStatus.granted) {
//       throw Exception('Permissions not granted');
//     }
//   }
//
//   Future<void> _setupEngine() async {
//     _engine = createAgoraRtcEngine();
//     await _engine.initialize(RtcEngineContext(
//       appId: appId,
//       channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
//     ));
//
//     await _engine.enableVideo();
//     await _engine.startPreview();
//     await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
//
//     _registerEventHandlers();
//   }
//
//   void _registerEventHandlers() {
//     _engine.registerEventHandler(
//       RtcEngineEventHandler(
//         onJoinChannelSuccess: (connection, elapsed) {
//           setState(() => _localUserJoined = true);
//           _startCallTimer();
//         },
//         onUserJoined: (connection, remoteUid, elapsed) {
//           setState(() => _remoteUid = remoteUid);
//         },
//         onUserOffline: (connection, remoteUid, reason) {
//           setState(() => _remoteUid = null);
//           _showUserLeftMessage(remoteUid);
//         },
//         onError: (error, msg) => _showErrorDialog("Engine Error", "$msg ($error)"),
//         onTokenPrivilegeWillExpire: (connection, token) => _renewToken(),
//         onNetworkQuality: (connection, remoteUid, txQuality, rxQuality) {
//           // setState(() => _networkQuality = rxQuality);
//         },
//         onConnectionLost: (connection) => _showErrorDialog("Connection Lost", "Attempting to reconnect..."),
//       ),
//     );
//   }
//
//   Future<void> _joinChannel() async {
//     try {
//       await _engine.joinChannel(
//         token: token,
//         channelId: channel,
//         uid: 0,
//         options: const ChannelMediaOptions(),
//       );
//     } catch (e) {
//       _showErrorDialog("Join Channel Failed", e.toString());
//     }
//   }
//
//   void _startCallTimer() {
//     _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       setState(() => _callDuration++);
//     });
//   }
//
//   void _toggleMute() {
//     setState(() => _isMuted = !_isMuted);
//     _engine.muteLocalAudioStream(_isMuted);
//   }
//
//   void _toggleVideo() {
//     setState(() => _isVideoDisabled = !_isVideoDisabled);
//     _engine.muteLocalVideoStream(_isVideoDisabled);
//   }
//
//   void _switchCamera() {
//     _engine.switchCamera().then((_) {
//       setState(() => _isFrontCamera = !_isFrontCamera);
//     });
//   }
//
//   void _toggleSpeaker() {
//     setState(() => _isSpeakerEnabled = !_isSpeakerEnabled);
//     _engine.setEnableSpeakerphone(_isSpeakerEnabled);
//   }
//
//   Future<void> _renewToken() async {
//     // Implement token renewal logic here
//     const newToken = token; // Replace with actual token renewal
//     await _engine.renewToken(newToken);
//   }
//
//   String _formatDuration(int seconds) {
//     return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
//   }
//
//   void _showUserLeftMessage(int uid) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('User $uid left the call')),
//     );
//   }
//
//   void _showErrorDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           )
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _callTimer?.cancel();
//     _engine.leaveChannel();
//     _engine.release();
//     super.dispose();
//   }
//
//   Widget _buildControlPanel() {
//     return Positioned(
//       bottom: 20,
//       left: 0,
//       right: 0,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _controlButton(
//             icon: _isMuted ? Icons.mic_off : Icons.mic,
//             onPressed: _toggleMute,
//             color: _isMuted ? Colors.red : Colors.white,
//           ),
//           _controlButton(
//             icon: _isVideoDisabled ? Icons.videocam_off : Icons.videocam,
//             onPressed: _toggleVideo,
//             color: _isVideoDisabled ? Colors.red : Colors.white,
//           ),
//           _controlButton(
//             icon: Icons.switch_camera,
//             onPressed: _switchCamera,
//           ),
//           _controlButton(
//             icon: _isSpeakerEnabled ? Icons.volume_up : Icons.volume_off,
//             onPressed: _toggleSpeaker,
//           ),
//           _controlButton(
//             icon: Icons.call_end,
//             onPressed: () => Navigator.pop(context),
//             color: Colors.red,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _controlButton({required IconData icon, required VoidCallback onPressed, Color color = Colors.white}) {
//     return CircleAvatar(
//       backgroundColor: Colors.black54,
//       child: IconButton(
//         icon: Icon(icon, color: color),
//         onPressed: onPressed,
//       ),
//     );
//   }
//
//   Widget _buildNetworkIndicator() {
//     if (_networkQuality == null) return const SizedBox.shrink();
//
//     final quality = _networkQuality!;
//     Color indicatorColor;
//     if (quality > 5) {
//       indicatorColor = Colors.red;
//     } else if (quality > 3) {
//       indicatorColor = Colors.orange;
//     } else {
//       indicatorColor = Colors.green;
//     }
//
//     return Positioned(
//       top: 50,
//       right: 20,
//       child: Row(
//         children: [
//           Icon(Icons.network_check, color: indicatorColor),
//           Text(' ${_formatDuration(_callDuration)}',
//               style: TextStyle(color: Colors.white)),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Video Call'),
//         backgroundColor: Colors.black87,
//       ),
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           _remoteVideoView(),
//           _localPreview(),
//           _buildControlPanel(),
//           _buildNetworkIndicator(),
//         ],
//       ),
//     );
//   }
//
//   Widget _remoteVideoView() {
//     return _remoteUid != null
//         ? AgoraVideoView(
//       controller: VideoViewController.remote(
//         rtcEngine: _engine,
//         canvas: VideoCanvas(uid: _remoteUid),
//         connection: RtcConnection(channelId: channel),
//       ),
//     )
//         : Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(),
//           const SizedBox(height: 20),
//           Text(
//             'Waiting for participant...',
//             style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _localPreview() {
//     return Positioned(
//       right: 20,
//       top: 20,
//       child: SizedBox(
//         width: 120,
//         height: 180,
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(12),
//           child: _localUserJoined
//               ? AgoraVideoView(
//             controller: VideoViewController(
//               rtcEngine: _engine,
//               canvas: const VideoCanvas(uid: 0),
//             ),
//           )
//               : Container(color: Colors.black),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:flutter/material.dart';
class HomeScreen1 extends StatefulWidget {
  const HomeScreen1({super.key});

  @override
  State<HomeScreen1> createState() => _HomeScreen1State();
}

class _HomeScreen1State extends State<HomeScreen1> {
  startMeeting() async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final users = await ApiCaller().callApi(
        endpoint: 'create-meeting',
        method: HttpMethod.post,
        params: null,
      );
      ProgressDialogUtils.hideProgressDialog();

      print('users $users');
    } on ApiException catch (e) {
      ProgressDialogUtils.hideProgressDialog();

      print('Error: ${e.statusCode} - ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meeting Call')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _navigateToCallScreen(context, defaultChannel),
              child: const Text('Start Call'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _showJoinDialog(context),
              child: const Text('Join Call'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCallScreen(BuildContext context, String channel) {
    startMeeting();


  }

  void _showJoinDialog(BuildContext context) {
    final channelController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Call'),
        content: TextField(
          controller: channelController,
          decoration: const InputDecoration(labelText: 'Channel Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (channelController.text.isNotEmpty) {
                Navigator.pop(context);
                _navigateToCallScreen(context, channelController.text);
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
const defaultChannel = 'doctak';
const appId = "f2cf99f1193a40e69546157883b2159f";
// const token ='';
const token = '007eJxTYJhhnBVwqMXBLjxta/H5l7Xee+weGD60jYiwNeKfG9BfparAkGaUnGZpmWZoaGmcaGKQamZpamJmaGpuYWGcZGRoapkWVb01vSGQkcFf9gAzIwMEgvhsDCn5ySWJ2QwMAPb1Hb0=';


class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String userName;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.userName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late RtcEngine _agoraEngine;
  final List<RemoteVideoData> _remoteVideos = [];
  final ValueNotifier<int> _participantCount = ValueNotifier(0);
  final List<Offset> _defaultPositions = [];

  bool _isJoined = false;
  bool _isMuted = false;
  bool _isScreenSharing = false;
  bool _isFrontCamera = true;
  bool _showControls = true;
  bool _isLocalVideoEnabled = true;
  double _localVideoScale = 1.0;
  Offset _localVideoPosition = const Offset(20, 20);
  int _callDuration = 0;
  Timer? _callTimer;
  int? _networkQuality;

  @override
  void initState() {
    super.initState();

    _initializeAgora();
    _generateDefaultPositions();

    _startCallTimer();
  }


  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
    });
  }

  void _generateDefaultPositions() {
    _defaultPositions.addAll([
      const Offset(20, 20),
      const Offset(20, 200),
      const Offset(200, 20),
      const Offset(200, 200),
    ]);
  }

  Future<void> _initializeAgora() async {
    try {
      await [Permission.microphone, Permission.camera].request();

      _agoraEngine = createAgoraRtcEngine();
      await _agoraEngine.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _setupEventHandlers();
      await _configureVideoSettings();
      await _joinChannel();
    } catch (e) {
      _showErrorDialog('Initialization Error', e.toString());
    }
  }

  void _setupEventHandlers() {
    _agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
          onVideoPublishStateChanged:(VideoSourceType videoSourceType, v1 , StreamPublishState streamPublishState1, StreamPublishState streamPublishState2, v2){

          },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            // Handle both camera and screen sharing UIDs
            if (remoteUid != 0) { // Skip local user
              setState(() {
                _remoteVideos.add(RemoteVideoData(
                  uid: remoteUid,
                  isScreenShare: false,
                  position: _getNextPosition(),
                  scale: 1.0,
                ));
              });
            }
          },
          onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid,
              RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
            if (state == RemoteVideoState.remoteVideoStateStarting) {
              if (!_remoteVideos.any((v) => v.uid == remoteUid)) {
                setState(() {
                  _remoteVideos.add(RemoteVideoData(
                    uid: remoteUid,
                    isScreenShare: false,
                    position: _getNextPosition(),
                    scale: 1.0,
                  ));
                });
              }
            }},
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isJoined = true);
          _updateParticipantCount();
        },
        onUserInfoUpdated: (value,UserInfo userInfo){
        },

        // onUserPublished: (RtcConnection connection, int remoteUid, MediaType type) async {
        //   if (type == MediaType.video) {
        //     await _agoraEngine.muteRemoteVideoStream(remoteUid, false);
        //     await _agoraEngine.muteRemoteAudioStream(remoteUid, false);
        //   }
        // },
        // onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
        //   if (state == RemoteVideoState.remoteVideoStateStarting) {
        //     setState(() {
        //       if (!_remoteVideos.any((v) => v.uid == remoteUid)) {
        //         _remoteVideos.add(RemoteVideoData(
        //           uid: remoteUid,
        //           position: _getNextPosition(),
        //           scale: 1.0,
        //         ));
        //       }
        //     });
        //   }
        // },
        // onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        //   setState(() {
        //     _remoteVideos.add(RemoteVideoData(
        //       uid: remoteUid,
        //       position: _getNextPosition(),
        //       scale: 1.0,
        //     ));
        //   });
        //   _showSystemMessage('User $remoteUid joined');
        //   _updateParticipantCount();
        // },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() => _remoteVideos.removeWhere((v) => v.uid == remoteUid));
          _showSystemMessage('User $remoteUid left');
          _updateParticipantCount();
        },
        onError: (ErrorCodeType err, String msg) => _showErrorDialog('Agora Error', msg),
        onRtcStats: (RtcConnection connection,RtcStats stats) => _monitorConnectionQuality(stats),
        onNetworkQuality: (RtcConnection connection, int rxQuality,QualityType qualityType,QualityType qualityType2) {
          setState(() => _networkQuality = rxQuality);
        },
      ),
    );
  }

  Future<void> _configureVideoSettings() async {
    await _agoraEngine.enableVideo();
    await _agoraEngine.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
      dimensions: VideoDimensions(width: 640, height: 480),
      frameRate: 15,
      bitrate: 2000,

    ));
    // Highlight: Keep preview running initially
    await _agoraEngine.startPreview();
    await _agoraEngine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _agoraEngine.enableVideo();

  }

  Future<void> _joinChannel() async {
    try {
      await _agoraEngine.joinChannel(
        token: token,
        channelId: widget.channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishScreenTrack: false,
          publishScreenCaptureVideo: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      _showErrorDialog('Connection Error', e.toString());
    }
  }

  Offset _getNextPosition() {
    if (_remoteVideos.length < _defaultPositions.length) {
      return _defaultPositions[_remoteVideos.length];
    }
    return Offset(
      20 + (_remoteVideos.length % 4) * 180,
      20 + (_remoteVideos.length % 3) * 160,
    );
  }

  void _updateParticipantCount() {
    // _agoraEngine.getRemoteUserCount().then((count) {
    //   _participantCount.value = count;
    // });
  }

  void _monitorConnectionQuality(RtcStats stats) {
    // if (stats.rxQuality > QualityType.qualityExcellent.value ||
    //     stats.rxQuality > QualityType.qualityExcellent.value) {
    //   _showSystemMessage('Poor network connection detected');
    // }
  }

  // Future<void> _toggleScreenSharing() async {
  //   try {
  //     if (_isScreenSharing) {
  //       await _agoraEngine.stopScreenCapture();
  //       await _agoraEngine.startPreview();
  //     } else {
  //       await _agoraEngine.stopPreview();
  //       await _agoraEngine.startScreenCapture(const ScreenCaptureParameters2(
  //         captureVideo: true,
  //         captureAudio: true,
  //         videoParams: ScreenVideoParameters(
  //           dimensions: VideoDimensions(width: 1280, height: 720),
  //           frameRate: 15,
  //           bitrate: 2000,
  //         ),
  //       ));
  //     }
  //     setState(() => _isScreenSharing = !_isScreenSharing);
  //   } catch (e) {
  //     _showErrorDialog('Screen Share Error', e.toString());
  //   }
  // }
  // Future<void> _toggleScreenSharing() async {
  //   try {
  //     if (_isScreenSharing) {
  //       await _agoraEngine.stopScreenCapture();
  //       await _agoraEngine.leaveChannel();
  //       await _joinChannel(); // Rejoin with original settings
  //     } else {
  //       await _agoraEngine.leaveChannel();
  //       await _agoraEngine.startScreenCapture(const ScreenCaptureParameters2(
  //         captureVideo: true,
  //         captureAudio: true,
  //         videoParams: ScreenVideoParameters(
  //           dimensions: VideoDimensions(width: 1280, height: 720),
  //           frameRate: 15,
  //           bitrate: 2000,
  //         ),
  //       ));
  //       await _agoraEngine.joinChannel(
  //         token: token,
  //         channelId: widget.channelName,
  //         uid: 0, // Use a different UID for screen sharing
  //         options: const ChannelMediaOptions(
  //           channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
  //           clientRoleType: ClientRoleType.clientRoleBroadcaster,
  //         ),
  //       );
  //     }
  //     setState(() => _isScreenSharing = !_isScreenSharing);
  //   } catch (e) {
  //     _showErrorDialog('Screen Share Error', e.toString());
  //   }
  // }
  Future<void> _toggleScreenSharing() async {
    try {
      if (_isScreenSharing) {
        // Stop screen sharing
        await _agoraEngine.stopScreenCapture();
              // await _agoraEngine.leaveChannel();
              // await _joinChannel();
        // Restart camera stream
        await _agoraEngine.updateChannelMediaOptions(const ChannelMediaOptions(
          publishScreenTrack: false,
          publishSecondaryScreenTrack: false,
          publishCameraTrack: true,
          publishMicrophoneTrack: false,
          publishScreenCaptureAudio: false,
          publishScreenCaptureVideo: false,
          autoSubscribeAudio: false,
          publishMediaPlayerAudioTrack: false,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ));
        await _agoraEngine.startPreview();
      } else {
        // Stop camera stream
        await _agoraEngine.stopPreview();
        // Start screen sharing
        await _agoraEngine.startScreenCapture(const ScreenCaptureParameters2(
          captureVideo: true,
          captureAudio: true,
          videoParams: ScreenVideoParameters(
            dimensions: VideoDimensions(width: 1280, height: 720),
            frameRate: 15,
            contentHint: VideoContentHint.contentHintMotion,
            bitrate: 2000,
          ),
        ));
        // Update channel to publish screen track

        // await _agoraEngine.updateChannelMediaOptions(const ChannelMediaOptions(
        //   publishCameraTrack: false,
        //   publishScreenTrack: true,
        //   clientRoleType: ClientRoleType.clientRoleBroadcaster,
        // ));
        await _agoraEngine.updateChannelMediaOptions(
           const ChannelMediaOptions(
            publishScreenTrack: true,
            publishSecondaryScreenTrack: true,
            publishCameraTrack: false,
            publishMicrophoneTrack: true,
            publishScreenCaptureAudio: true,
            publishScreenCaptureVideo: true,
            autoSubscribeAudio: true,
            publishMediaPlayerAudioTrack: true,
            clientRoleType: ClientRoleType.clientRoleBroadcaster, // or ClientRoleType.clientRoleAudience
          ),
        );
      }
      setState(() => _isScreenSharing = !_isScreenSharing);
    } catch (e) {
      _showErrorDialog('Screen Share Error', e.toString());
    }
  }
  void _handleVideoMove(int uid, Offset newPosition) {
    setState(() {
      final index = _remoteVideos.indexWhere((v) => v.uid == uid);
      if (index != -1) {
        _remoteVideos[index] = _remoteVideos[index].copyWith(position: newPosition);
      }
    });
  }

  void _handleVideoScale(int uid, double scale) {
    setState(() {
      final index = _remoteVideos.indexWhere((v) => v.uid == uid);
      if (index != -1) {
        _remoteVideos[index] = _remoteVideos[index].copyWith(scale: scale);
      }
    });
  }

  String _formatDuration(int seconds) {
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  void _showSystemMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showControls
          ? AppBar(
        title: ValueListenableBuilder<int>(
          valueListenable: _participantCount,
          builder: (context, count, _) {
            return Row(
              children: [
                Text('Participants: $count'),
                const SizedBox(width: 20),
                const Icon(Icons.timer, size: 18),
                Text(_formatDuration(_callDuration)),
              ],
            );
          },
        ),
        actions: [
          if (_networkQuality != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.network_check,
                    color: _getNetworkQualityColor(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getNetworkQualityText(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            ..._remoteVideos.map(_buildVideoWindow),
            if (_isJoined) _buildLocalPreview(),
            if (_showControls) _buildControlBar(),
          ],
        ),
      ),
    );
  }

  Color _getNetworkQualityColor() {
    switch (_networkQuality) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow;
      case 3:
        return Colors.orange;
      case 4:
      case 5:
      case 6:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNetworkQualityText() {
    switch (_networkQuality) {
      case 1:
        return 'Excellent';
      case 2:
        return 'Good';
      case 3:
        return 'Poor';
      case 4:
        return 'Bad';
      case 5:
        return 'Very Bad';
      case 6:
        return 'Disconnected';
      default:
        return 'Unknown';
    }
  }

  Widget _buildVideoWindow(RemoteVideoData videoData) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      left: videoData.position.dx,
      top: videoData.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          final newPosition = videoData.position + details.delta;
          _handleVideoMove(videoData.uid, newPosition);
        },
        onDoubleTap: () => _handleVideoScale(
          videoData.uid,
          videoData.scale == 1.0 ? 1.5 : 1.0,
        ),
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isScreenSharing ? Colors.green : Colors.grey,
              width: 4,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _agoraEngine,
                canvas: _isScreenSharing?VideoCanvas(
                  uid: videoData.uid,
                  sourceType: VideoSourceType.videoSourceRemote,
                ):VideoCanvas(
                  uid: videoData.uid,
                  // sourceType: VideoSourceType.videoSourceRemote,
                ),
                connection: RtcConnection(channelId: widget.channelName),
                useFlutterTexture: true,
                useAndroidSurfaceView: true
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildLocalPreview() {
    return Positioned(
      left: _localVideoPosition.dx,
      top: _localVideoPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) => setState(() => _localVideoPosition += details.delta),
        onDoubleTap: () => setState(() => _localVideoScale = _localVideoScale == 1.0 ? 1.5 : 1.0),
        child: Transform.scale(
          scale: _localVideoScale,
          child: Container(
            width: 120,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              border: Border.all(color: Colors.blue, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _isScreenSharing
                  ? AgoraVideoView(
                controller: VideoViewController(
                  useAndroidSurfaceView: true,
                  useFlutterTexture: true,
                  rtcEngine: _agoraEngine,
                  canvas:  const VideoCanvas(uid: 0,sourceType:VideoSourceType.videoSourceScreen ),
                  // Use screen capture source
                  // useScreenCapture: true,
                ),
              )
                  : AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _agoraEngine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildControlBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
              color: Colors.white,
              onPressed: _toggleAudio,
            ),
            IconButton(
              icon: Icon(_isLocalVideoEnabled ? Icons.videocam : Icons.videocam_off),
              color: Colors.white,
              onPressed: _toggleVideo,
            ),
            IconButton(
              icon: Icon(_isScreenSharing ? Icons.stop_screen_share : Icons.screen_share),
              color: Colors.white,
              onPressed: _toggleScreenSharing,
            ),
            IconButton(
              icon: Icon(_isFrontCamera ? Icons.camera_front : Icons.camera_rear),
              color: Colors.white,
              onPressed: _switchCamera,
            ),
            IconButton(
              icon: const Icon(Icons.call_end),
              color: Colors.red,
              onPressed: _confirmEndCall,
            ),
          ],
        ),
      ),
    );
  }
  void _toggleAudio() {
    setState(() => _isMuted = !_isMuted);
    _agoraEngine.muteLocalAudioStream(_isMuted);
  }
  void _toggleVideo() {
    setState(() => _isLocalVideoEnabled = !_isLocalVideoEnabled);
    _agoraEngine.muteLocalVideoStream(!_isLocalVideoEnabled);
  }
  Future<void> _switchCamera() async {
    await _agoraEngine.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }
  void _confirmEndCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Call'),
        content: const Text('Are you sure you want to end the call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('End Call', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _agoraEngine.leaveChannel();
    _agoraEngine.release();
    super.dispose();
  }
}

class RemoteVideoData {
  final int uid;
  final Offset position;
  final bool isScreenShare;
  final double scale;

  RemoteVideoData({
    required this.uid,
    required this.position,
    required this.isScreenShare,
    this.scale = 1.0,
  });

  RemoteVideoData copyWith({
    Offset? position,
    bool? isScreenShare,
    double? scale,
  }) {
    return RemoteVideoData(
      uid: uid,
      position: position ?? this.position,
      isScreenShare: isScreenShare ?? this.isScreenShare,
      scale: scale ?? this.scale,
    );
  }
}