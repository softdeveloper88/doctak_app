import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

const appId = "f2cf99f1193a40e69546157883b2159f"; // Your Agora App ID

class CallScreen extends StatefulWidget {
  final String callId;
  final String contactId;
  final String contactName;
  final String contactAvatar;
  final bool isIncoming;
  final bool isVideoCall;
  final String? token; // Optional token for secure connections

  const CallScreen({
    Key? key,
    required this.callId,
    required this.contactId,
    required this.contactName,
    required this.contactAvatar,
    required this.isIncoming,
    required this.isVideoCall,
    this.token,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with SingleTickerProviderStateMixin {
  // Agora Engine
  late RtcEngine _agoraEngine;
  int? _remoteUid;
  bool _isLocalUserJoined = false;
  bool _isRemoteUserJoined = false;

  // Call controls
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isLocalVideoEnabled = true;
  bool _isFrontCamera = true;

  // Call state
  int _callDuration = 0;
  Timer? _callTimer;
  int? _networkQuality;
  bool _isReconnecting = false;

  // Animation for speaking indicator
  late AnimationController _speakingAnimationController;
  late Animation<double> _speakingAnimation;
  bool _isLocalUserSpeaking = false;
  bool _isRemoteUserSpeaking = false;
  Map<int, Timer?> _speakingTimers = {};

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for speaking indication
    _speakingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    )..repeat(reverse: true);
    _speakingAnimation = Tween<double>(begin: 1.0, end: 1.8).animate(_speakingAnimationController);

    // Start call setup
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      // Request permissions first
      await _requestPermissions();

      // Initialize Agora engine
      await _initializeAgora();

      // Start call timer
      _startCallTimer();

      // Start as speaker if video call
      if (widget.isVideoCall) {
        await _agoraEngine.setEnableSpeakerphone(true);
        setState(() => _isSpeakerOn = true);
      } else {
        // Start with earpiece for audio calls
        await _agoraEngine.setEnableSpeakerphone(false);
        setState(() => _isSpeakerOn = false);
      }

      // Enable video if it's a video call
      if (widget.isVideoCall) {
        setState(() => _isLocalVideoEnabled = true);
      } else {
        await _agoraEngine.enableLocalVideo(false);
        setState(() => _isLocalVideoEnabled = false);
      }
    } catch (e) {
      _showErrorDialog('Initialization Error', e.toString());
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();

    List<String> deniedPermissions = [];

    if (statuses[Permission.microphone] != PermissionStatus.granted) {
      deniedPermissions.add('Microphone');
    }

    if (statuses[Permission.camera] != PermissionStatus.granted) {
      deniedPermissions.add('Camera');
    }

    if (deniedPermissions.isNotEmpty) {
      _showPermissionDialog(deniedPermissions);
    }
  }

  void _showPermissionDialog(List<String> deniedPermissions) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Text('${deniedPermissions.join(', ')} permission(s) are required for the call. '
            'The app may not function properly without these permissions.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeAgora() async {
    // Create an instance of the Agora engine
    _agoraEngine = createAgoraRtcEngine();
    await _agoraEngine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // Set event handlers
    _setupEventHandlers();

    // Configure video settings
    await _configureVideoSettings();

    // Join the channel
    await _joinChannel();
  }

  void _setupEventHandlers() {
    _agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _isLocalUserJoined = true);
          print('Local user joined - UID: 0');
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print('Remote user joined - UID: $remoteUid');
          setState(() {
            _remoteUid = remoteUid;
            _isRemoteUserJoined = true;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          print('Remote user offline: $remoteUid, reason: $reason');
          setState(() {
            _remoteUid = null;
            _isRemoteUserJoined = false;
          });

          // Auto end call if remote user leaves
          if (reason != UserOfflineReasonType.userOfflineBecomeAudience) {
            _showSystemMessage('Call ended by ${widget.contactName}');
            Future.delayed(const Duration(seconds: 2), () {
              _endCall();
            });
          }
        },
        onAudioVolumeIndication: (connection, speakers, totalVolume, s) {
          if (speakers.isEmpty) return;

          // Check for speaking users
          setState(() {
            // Reset speaking states by default
            bool foundLocalSpeaking = false;
            bool foundRemoteSpeaking = false;

            for (var speaker in speakers) {
              if ((speaker.volume ?? 0) > 50) { // Threshold for speaking
                if (speaker.uid == 0) {
                  // Local user speaking
                  foundLocalSpeaking = true;
                  _isLocalUserSpeaking = true;

                  // Cancel previous timer
                  _speakingTimers[0]?.cancel();

                  // Set timer to reset speaking state
                  _speakingTimers[0] = Timer(const Duration(milliseconds: 800), () {
                    if (mounted) setState(() => _isLocalUserSpeaking = false);
                  });
                } else if (speaker.uid == _remoteUid) {
                  // Remote user speaking
                  foundRemoteSpeaking = true;
                  _isRemoteUserSpeaking = true;

                  // Cancel previous timer
                  _speakingTimers[_remoteUid ?? 0]?.cancel();

                  // Set timer to reset speaking state
                  _speakingTimers[_remoteUid ?? 0] = Timer(const Duration(milliseconds: 800), () {
                    if (mounted) setState(() => _isRemoteUserSpeaking = false);
                  });
                }
              }
            }

            // If not found in speakers, keep the reset
            if (!foundLocalSpeaking) {
              _isLocalUserSpeaking = false;
            }
            if (!foundRemoteSpeaking) {
              _isRemoteUserSpeaking = false;
            }
          });
        },
        onNetworkQuality: (RtcConnection connection, int uid, QualityType txQuality, QualityType rxQuality) {
          setState(() => _networkQuality = rxQuality.index);
        },
        onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
          print('Connection state changed: $state, reason: $reason');

          if (state == ConnectionStateType.connectionStateReconnecting) {
            setState(() => _isReconnecting = true);
            _showSystemMessage('Connection lost. Reconnecting...');
          } else if (state == ConnectionStateType.connectionStateConnected) {
            if (_isReconnecting) {
              _showSystemMessage('Successfully reconnected');
            }
            setState(() => _isReconnecting = false);
          }
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          // Handle token expiration (would need token renewal logic)
          print('Token will expire soon');
        },
        onError: (ErrorCodeType err, String msg) {
          print('Agora error: $err, message: $msg');
          if (err != ErrorCodeType.errOk) {
            _showErrorDialog('Call Error', 'Error code: ${err.name}');
          }
        },
      ),
    );
  }

  Future<void> _configureVideoSettings() async {
    // Enable video processing
    await _agoraEngine.enableVideo();

    // Configure video encoder settings
    await _agoraEngine.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 480),
        frameRate: 15,
        bitrate: 1000,
      ),
    );

    // Start preview
    await _agoraEngine.startPreview();

    // Set role as broadcaster (needed for video/audio publishing)
    await _agoraEngine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // Enable audio volume indication
    await _agoraEngine.enableAudioVolumeIndication(
      interval: 500, // Check every 500ms
      smooth: 3, // Smoothing factor
      reportVad: true, // Voice activity detection
    );

    // Set audio profile for better quality
    await _agoraEngine.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
  }

  Future<void> _joinChannel() async {
    try {
      // Join the channel with user account
      await _agoraEngine.joinChannel(
        token: '007eJxTYJiQXxmwe5mfZt30H/1f8x6tOvlHzy18ZY1NYkzXed62owUKDGlGyWmWlmmGhpbGiSYGqWaWpiZmhqbmFhbGSUaGppZpjs8ZMhoCGRk2Tz3DwAiFID4bQ0p+ckliNgMDAO0PIRs=',
        channelId: "doctak",
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (e) {
      print('Join channel error: $e');
      _showErrorDialog('Connection Error', 'Failed to join the call: $e');
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
    });
  }

  void _showSystemMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // CALL CONTROL FUNCTIONS

  Future<void> _toggleMute() async {
    setState(() => _isMuted = !_isMuted);
    await _agoraEngine.muteLocalAudioStream(_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    setState(() => _isSpeakerOn = !_isSpeakerOn);
    await _agoraEngine.setEnableSpeakerphone(_isSpeakerOn);
  }

  Future<void> _toggleLocalVideo() async {
    if (widget.isVideoCall) {
      setState(() => _isLocalVideoEnabled = !_isLocalVideoEnabled);
      await _agoraEngine.muteLocalVideoStream(!_isLocalVideoEnabled);
      await _agoraEngine.enableLocalVideo(_isLocalVideoEnabled);
    } else {
      _showSystemMessage("This is an audio call");
    }
  }

  Future<void> _switchCamera() async {
    if (widget.isVideoCall) {
      await _agoraEngine.switchCamera();
      setState(() => _isFrontCamera = !_isFrontCamera);
    }
  }

  void _endCall() {
    // Show dialog to confirm if needed
    Navigator.of(context).pop(); // Return to previous screen
  }

  @override
  void dispose() {
    // Clean up timers
    _callTimer?.cancel();
    _speakingTimers.forEach((_, timer) => timer?.cancel());

    // Clean up animation controller
    _speakingAnimationController.dispose();

    // Clean up Agora engine
    _agoraEngine.leaveChannel();
    _agoraEngine.release();

    super.dispose();
  }

  String _formatDuration(int seconds) {
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: WillPopScope(
        onWillPop: () async {
          // Show confirm dialog before exiting
          _confirmEndCall();
          return false;
        },
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Remote Video Background (if video call)
              if (widget.isVideoCall)
                _buildRemoteVideo(),

              // Audio call UI (if audio call)
              if (!widget.isVideoCall)
                _buildAudioCallUI(),

              // Reconnecting overlay
              if (_isReconnecting)
                _buildReconnectingOverlay(),

              // Local Video Preview (if video call)
              if (widget.isVideoCall)
                _buildLocalVideoPreview(),

              // Call Status Bar (time, quality indicator)
              _buildCallStatusBar(),

              // Call Controls
              Positioned(
                left: 0,
                right: 0,
                bottom: 40,
                child: _buildControlButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteVideo() {
    if (_remoteUid != null) {
      // Remote user has joined
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _agoraEngine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.callId),
          useFlutterTexture: true,
          useAndroidSurfaceView: true,
        ),
      );
    } else {
      // Waiting for remote user
      return Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: widget.contactAvatar.isNotEmpty
                    ? NetworkImage(widget.contactAvatar)
                    : null,
                child: widget.contactAvatar.isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                _isLocalUserJoined
                    ? "Calling ${widget.contactName}..."
                    : "Connecting...",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              if (!_isLocalUserJoined)
                const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildAudioCallUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade900, Colors.black],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Contact avatar with speaking animation
            AnimatedBuilder(
              animation: _speakingAnimationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRemoteUserSpeaking
                          ? Colors.green.withOpacity(0.7)
                          : Colors.transparent,
                      width: _isRemoteUserSpeaking ? 4 : 0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: widget.contactAvatar.isNotEmpty
                          ? NetworkImage(widget.contactAvatar)
                          : null,
                      child: widget.contactAvatar.isEmpty
                          ? const Icon(Icons.person, size: 70, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              widget.contactName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isRemoteUserJoined
                  ? "In call"
                  : _isLocalUserJoined
                  ? "Calling..."
                  : "Connecting...",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (_isRemoteUserJoined)
              Text(
                _formatDuration(_callDuration),
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),

            // Connection quality indicator
            if (_networkQuality != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi,
                      color: _getNetworkQualityColor(),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Connection quality",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconnectingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              "Reconnecting...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalVideoPreview() {
    if (!widget.isVideoCall) return const SizedBox.shrink();

    return Positioned(
      right: 16,
      top: 16,
      child: GestureDetector(
        onTap: _toggleLocalVideo,
        child: Container(
          width: 120,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isLocalUserSpeaking
                  ? Colors.green.withOpacity(0.7)
                  : Colors.white30,
              width: _isLocalUserSpeaking ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: _isLocalVideoEnabled && _isLocalUserJoined
                ? AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _agoraEngine,
                canvas: const VideoCanvas(uid: 0),
              ),
            )
                : Container(
              color: Colors.black54,
              child: const Center(
                child: Icon(
                  Icons.videocam_off,
                  color: Colors.white70,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallStatusBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Call timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(_callDuration),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          // Network quality
          if (_networkQuality != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.network_check,
                    color: _getNetworkQualityColor(),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "Network",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.black38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildCircleButton(
            onTap: _toggleMute,
            icon: _isMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic,
            label: "Mute",
            bgColor: _isMuted ? Colors.red : Colors.white24,
          ),

          // Video button (only for video calls)
          if (widget.isVideoCall)
            _buildCircleButton(
              onTap: _toggleLocalVideo,
              icon: _isLocalVideoEnabled ? Icons.videocam : Icons.videocam_off,
              label: "Video",
              bgColor: _isLocalVideoEnabled ? Colors.white24 : Colors.red,
            ),

          // Speaker button
          _buildCircleButton(
            onTap: _toggleSpeaker,
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            label: "Speaker",
            bgColor: _isSpeakerOn ? Colors.white24 : Colors.white24,
          ),

          // Camera flip button (only for video calls)
          if (widget.isVideoCall)
            _buildCircleButton(
              onTap: _switchCamera,
              icon: CupertinoIcons.camera_rotate,
              label: "Flip",
              bgColor: Colors.white24,
            ),

          // End call button
          _buildCircleButton(
            onTap: _confirmEndCall,
            icon: Icons.call_end,
            label: "End",
            bgColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color bgColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            iconSize: 24,
            onPressed: onTap,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _confirmEndCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Call'),
        content: const Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog

              // Leave Agora channel
              _agoraEngine.leaveChannel();

              // Return to previous screen
              Navigator.of(context).pop();
            },
            child: const Text('End Call', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}