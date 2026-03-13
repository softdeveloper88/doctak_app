import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_live_interaction_screen.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Full Agora-powered live meeting screen for CME events.
/// Shows video/audio + floating controls + interaction panel (chat/polls/modules).
class CmeLiveMeetingScreen extends StatefulWidget {
  final String eventId;
  final String? eventTitle;
  final bool isHost;
  final List<CmeModule>? modules;

  const CmeLiveMeetingScreen({
    super.key,
    required this.eventId,
    this.eventTitle,
    this.isHost = false,
    this.modules,
  });

  @override
  State<CmeLiveMeetingScreen> createState() => _CmeLiveMeetingScreenState();
}

class _CmeLiveMeetingScreenState extends State<CmeLiveMeetingScreen> {
  // Agora
  RtcEngine? _engine;
  String? _token;
  String? _channel;
  String? _appId;
  int? _uid;
  bool _joined = false;
  bool _loading = true;
  String? _error;

  // Controls state
  bool _micEnabled = true;
  bool _camEnabled = true;
  bool _showControls = true;
  bool _showInteractionPanel = false;
  Timer? _controlsTimer;

  // Remote users
  final Set<int> _remoteUsers = {};
  int? _activeSpeakerUid;

  @override
  void initState() {
    super.initState();
    _initMeeting();
    _resetControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  Future<void> _initMeeting() async {
    try {
      // Request permissions
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (cameraStatus.isDenied || micStatus.isDenied) {
        setState(() {
          _error = 'Camera and microphone permissions are required';
          _loading = false;
        });
        return;
      }

      // Fetch Agora token from backend
      final tokenData = await CmeApiService.getAgoraToken(widget.eventId);
      _token = tokenData['token'] as String?;
      _channel = tokenData['channel'] as String?;
      _appId = tokenData['app_id'] as String?;
      _uid = tokenData['uid'] is int
          ? tokenData['uid'] as int
          : int.tryParse(tokenData['uid'].toString());

      if (_token == null || _appId == null || _channel == null) {
        setState(() {
          _error = 'Failed to get meeting credentials';
          _loading = false;
        });
        return;
      }

      // Initialize Agora engine — use Communication profile to match web (mode: "rtc")
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: _appId!,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Register event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _joined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) setState(() => _remoteUsers.add(remoteUid));
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) {
            setState(() {
              _remoteUsers.remove(remoteUid);
              if (_activeSpeakerUid == remoteUid) _activeSpeakerUid = null;
            });
          }
        },
        onAudioVolumeIndication:
            (connection, speakers, speakerNumber, totalVolume) {
          if (!mounted || speakers.isEmpty) return;
          int loudest = 0;
          int loudestVol = 0;
          for (final s in speakers) {
            if ((s.volume ?? 0) > loudestVol && s.uid != 0) {
              loudest = s.uid ?? 0;
              loudestVol = s.volume ?? 0;
            }
          }
          if (loudest != 0 && loudest != _activeSpeakerUid) {
            setState(() => _activeSpeakerUid = loudest);
          }
        },
        onError: (err, msg) {
          debugPrint('Agora error: $err $msg');
        },
      ));

      // Configure engine
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      await _engine!.enableAudioVolumeIndication(
        interval: 500,
        smooth: 3,
        reportVad: true,
      );
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 30,
          bitrate: 1000,
        ),
      );

      // Join channel
      await _engine!.joinChannel(
        token: _token!,
        channelId: _channel!,
        uid: _uid!,
        options: const ChannelMediaOptions(
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to join meeting: $e';
        _loading = false;
      });
    }
  }

  void _resetControlsTimer() {
    _controlsTimer?.cancel();
    if (mounted) setState(() => _showControls = true);
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleMic() async {
    _micEnabled = !_micEnabled;
    await _engine?.muteLocalAudioStream(!_micEnabled);
    setState(() {});
    _resetControlsTimer();
  }

  void _toggleCamera() async {
    _camEnabled = !_camEnabled;
    await _engine?.muteLocalVideoStream(!_camEnabled);
    setState(() {});
    _resetControlsTimer();
  }

  void _switchCamera() async {
    await _engine?.switchCamera();
    _resetControlsTimer();
  }

  void _leaveMeeting() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Meeting?',
            style: TextStyle(fontFamily: 'Poppins')),
        content: const Text('Are you sure you want to leave this live session?',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay', style: TextStyle(fontFamily: 'Poppins')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Leave', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingScreen();
    }
    if (_error != null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        children: [
          // Video grid
          GestureDetector(
            onTap: _resetControlsTimer,
            child: _buildVideoGrid(),
          ),

          // Top bar
          if (_showControls) _buildTopBar(),

          // Bottom controls
          if (_showControls) _buildBottomControls(),

          // Interaction panel (chat/polls/modules) slide-in
          if (_showInteractionPanel) _buildInteractionPanel(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Joining ${widget.eventTitle ?? 'Live Session'}...',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Setting up audio & video',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white38,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Live Meeting',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white),
                    child: const Text('Go Back',
                        style: TextStyle(fontFamily: 'Poppins')),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _initMeeting();
                    },
                    child: const Text('Retry',
                        style: TextStyle(fontFamily: 'Poppins')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Video Grid ───

  Widget _buildVideoGrid() {
    final allUsers = <int?>[null, ..._remoteUsers]; // null = local user

    if (allUsers.length == 1) {
      // Only local user — full screen
      return _buildVideoTile(null, fullScreen: true);
    }

    if (allUsers.length == 2) {
      // 1 remote — big remote, small local pip
      return Stack(
        children: [
          _buildVideoTile(_remoteUsers.first, fullScreen: true),
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 56,
            child: GestureDetector(
              onTap: _resetControlsTimer,
              child: Container(
                width: 110,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildVideoTile(null),
              ),
            ),
          ),
        ],
      );
    }

    // 3+ users — grid layout
    return GridView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 50,
        bottom: 100,
        left: 4,
        right: 4,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: allUsers.length <= 4 ? 2 : 3,
        childAspectRatio: 3 / 4,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: allUsers.length,
      itemBuilder: (_, i) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: _activeSpeakerUid == allUsers[i]
                ? Border.all(color: const Color(0xFF34C759), width: 2)
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildVideoTile(allUsers[i]),
        );
      },
    );
  }

  Widget _buildVideoTile(int? uid, {bool fullScreen = false}) {
    if (_engine == null) {
      return Container(
        color: const Color(0xFF161B22),
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white24, size: 40),
        ),
      );
    }

    final isLocal = uid == null;

    if (isLocal && !_camEnabled) {
      return Container(
        color: const Color(0xFF161B22),
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white24, size: 48),
        ),
      );
    }

    final controller = isLocal
        ? VideoViewController(
            rtcEngine: _engine!,
            canvas: const VideoCanvas(uid: 0),
            useFlutterTexture: Platform.isIOS,
            useAndroidSurfaceView: Platform.isAndroid,
          )
        : VideoViewController.remote(
            rtcEngine: _engine!,
            canvas: VideoCanvas(uid: uid),
            connection: RtcConnection(channelId: _channel),
            useFlutterTexture: Platform.isIOS,
            useAndroidSurfaceView: Platform.isAndroid,
          );

    return Container(
      color: const Color(0xFF161B22),
      child: AgoraVideoView(controller: controller),
    );
  }

  // ─── Top Bar ───

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            16, MediaQuery.of(context).padding.top + 8, 16, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.eventTitle ?? 'Live Session',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _joined
                              ? const Color(0xFF34C759)
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _joined ? 'Live' : 'Connecting...',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.people_outline,
                          color: Colors.white60, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        '${_remoteUsers.length + 1}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.isHost)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: Colors.red.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'HOST',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Controls ───

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlButton(
              icon: _micEnabled ? Icons.mic : Icons.mic_off,
              label: _micEnabled ? 'Mute' : 'Unmute',
              active: _micEnabled,
              onTap: _toggleMic,
            ),
            _controlButton(
              icon: _camEnabled ? Icons.videocam : Icons.videocam_off,
              label: _camEnabled ? 'Camera' : 'Camera Off',
              active: _camEnabled,
              onTap: _toggleCamera,
            ),
            _controlButton(
              icon: Icons.cameraswitch_outlined,
              label: 'Flip',
              active: true,
              onTap: _switchCamera,
            ),
            _controlButton(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              active: true,
              onTap: () {
                setState(() =>
                    _showInteractionPanel = !_showInteractionPanel);
              },
              badge: null,
            ),
            _controlButton(
              icon: Icons.call_end,
              label: 'Leave',
              isDestructive: true,
              onTap: _leaveMeeting,
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    bool active = true,
    bool isDestructive = false,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red
                  : active
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon,
                    color: isDestructive || !active
                        ? Colors.white
                        : Colors.white,
                    size: 22),
                if (badge != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                      child: Text(badge,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 8)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Interaction Panel (Chat / Polls / Modules) ───

  Widget _buildInteractionPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: MediaQuery.of(context).size.height * 0.55,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            setState(() => _showInteractionPanel = false);
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Close button row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () =>
                          setState(() => _showInteractionPanel = false),
                    ),
                  ],
                ),
              ),
              // Embed the interaction screen
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8)),
                  child: CmeLiveInteractionScreen(
                    eventId: widget.eventId,
                    eventTitle: widget.eventTitle,
                    isHost: widget.isHost,
                    modules: widget.modules,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
