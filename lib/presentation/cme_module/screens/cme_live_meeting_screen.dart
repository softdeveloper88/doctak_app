import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctak_app/data/apiClient/cme/cme_api_service.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_live_interaction_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
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

  // Role info from API (is_speaker from getAgoraToken response)
  bool _isSpeaker = false;

  // Controls state — attendees join with mic/cam off, hosts/speakers on
  bool _micEnabled = true;
  bool _camEnabled = true;
  bool _showControls = true;
  bool _showInteractionPanel = false;
  Timer? _controlsTimer;

  // Remote users
  final Set<int> _remoteUsers = {};
  int? _activeSpeakerUid;

  // Tap-to-fullscreen: which uid is shown full screen (null = auto layout)
  int? _fullScreenUid;
  // Special sentinel: -1 means local user is fullscreen
  static const int _localUserSentinel = -1;

  // Session timer for participation tracking
  final Stopwatch _sessionStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _initMeeting();
    _resetControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _trackParticipationOnLeave();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  /// Track participation duration when leaving the meeting.
  void _trackParticipationOnLeave() {
    if (_sessionStopwatch.elapsed.inSeconds > 0) {
      CmeApiService.trackParticipation(
        widget.eventId,
        duration: _sessionStopwatch.elapsed.inSeconds,
      ).catchError((_) => <String, dynamic>{}); // Fire-and-forget
    }
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

      // Read role info from API response
      _isSpeaker = tokenData['is_speaker'] == true;

      if (_token == null || _appId == null || _channel == null) {
        setState(() {
          _error = 'Failed to get meeting credentials';
          _loading = false;
        });
        return;
      }

      // Role-based A/V defaults: hosts/speakers start with cam+mic on,
      // attendees start muted with camera off (matching web behavior)
      final isPublisher = widget.isHost || _isSpeaker;
      _micEnabled = isPublisher;
      _camEnabled = isPublisher;

      // Initialize Agora engine — use Communication profile to match web (mode: "rtc")
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: _appId!,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Register event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _sessionStopwatch.start();
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
        // Token refresh — fetch a new token before the current one expires
        onTokenPrivilegeWillExpire: (connection, token) async {
          try {
            final newData = await CmeApiService.getAgoraToken(widget.eventId);
            final newToken = newData['token'] as String?;
            if (newToken != null) {
              await _engine?.renewToken(newToken);
              _token = newToken;
            }
          } catch (e) {
            debugPrint('Token refresh failed: $e');
          }
        },
        onError: (err, msg) {
          debugPrint('Agora error: $err $msg');
        },
      ));

      // Configure engine
      await _engine!.enableVideo();
      await _engine!.enableAudio();
      // Ensure local video rendering is enabled
      await _engine!.enableLocalVideo(_camEnabled);
      if (_camEnabled) {
        await _engine!.startPreview();
      }
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

      // Join channel — attendees join as subscribers only (no publish)
      await _engine!.joinChannel(
        token: _token!,
        channelId: _channel!,
        uid: _uid!,
        options: ChannelMediaOptions(
          publishCameraTrack: _camEnabled,
          publishMicrophoneTrack: _micEnabled,
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
    await _engine?.enableLocalVideo(_camEnabled);
    await _engine?.muteLocalVideoStream(!_camEnabled);
    if (_camEnabled) {
      await _engine?.startPreview();
    } else {
      await _engine?.stopPreview();
    }
    setState(() {});
    _resetControlsTimer();
  }

  void _switchCamera() async {
    await _engine?.switchCamera();
    _resetControlsTimer();
  }

  void _leaveMeeting() {
    final theme = OneUITheme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: theme.radiusL),
        title: Text('Leave Meeting?',
            style: TextStyle(fontFamily: 'Poppins', color: theme.textPrimary)),
        content: Text('Are you sure you want to leave this live session?',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Stay', style: TextStyle(fontFamily: 'Poppins', color: theme.textSecondary)),
          ),
          FilledButton(
            onPressed: () {
              _sessionStopwatch.stop();
              // Track participation before leaving
              CmeApiService.trackParticipation(
                widget.eventId,
                duration: _sessionStopwatch.elapsed.inSeconds,
              ).catchError((_) => <String, dynamic>{});
              // Reset so dispose doesn't double-track  
              _sessionStopwatch.reset();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: theme.error),
            child:
                const Text('Leave', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  /// Host-only: Generate certificates for all attendees.
  void _generateCertificates() async {
    try {
      await CmeApiService.generateCertificates(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificates generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate certificates: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    if (_loading) {
      return _buildLoadingScreen(theme);
    }
    if (_error != null) {
      return _buildErrorScreen(theme);
    }

    // Meeting UI always uses dark background for video
    final meetingBg = theme.isDark
        ? theme.scaffoldBackground
        : const Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: meetingBg,
      body: Stack(
        children: [
          // Video grid
          GestureDetector(
            onTap: _resetControlsTimer,
            child: _buildVideoGrid(theme),
          ),

          // Top bar
          if (_showControls && !_showInteractionPanel) _buildTopBar(theme),

          // Bottom controls
          if (_showControls && !_showInteractionPanel) _buildBottomControls(theme),

          // Interaction panel (chat/polls/modules) slide-up sheet
          if (_showInteractionPanel) _buildInteractionPanel(theme),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen(OneUITheme theme) {
    final meetingBg = theme.isDark
        ? theme.scaffoldBackground
        : const Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: meetingBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primary),
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

  Widget _buildErrorScreen(OneUITheme theme) {
    final meetingBg = theme.isDark
        ? theme.scaffoldBackground
        : const Color(0xFF0D1117);

    return Scaffold(
      backgroundColor: meetingBg,
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
              Icon(Icons.error_outline, size: 64, color: theme.error),
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
                    style: FilledButton.styleFrom(backgroundColor: theme.primary),
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

  Widget _buildVideoGrid(OneUITheme theme) {
    final allUsers = <int?>[null, ..._remoteUsers]; // null = local user
    final tileBg = theme.isDark
        ? theme.surfaceVariant
        : const Color(0xFF161B22);

    // If a user is selected for fullscreen view
    if (_fullScreenUid != null) {
      final fsUid = _fullScreenUid == _localUserSentinel ? null : _fullScreenUid;
      // Build list of other users for the strip
      final others = allUsers.where((u) {
        if (fsUid == null) return u != null; // local is fullscreen, show remotes
        return u != fsUid; // remote is fullscreen, show others including local
      }).toList();

      return Stack(
        children: [
          // Full screen video
          GestureDetector(
            onTap: () {
              _resetControlsTimer();
              setState(() => _fullScreenUid = null); // Tap to exit fullscreen
            },
            child: _buildVideoTile(fsUid, fullScreen: true, tileBg: tileBg),
          ),
          // Thumbnail strip at top-right
          if (others.isNotEmpty)
            Positioned(
              right: 8,
              top: MediaQuery.of(context).padding.top + 56,
              child: Column(
                children: others.take(4).map((uid) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GestureDetector(
                      onTap: () {
                        _resetControlsTimer();
                        setState(() {
                          _fullScreenUid = uid == null ? _localUserSentinel : uid;
                        });
                      },
                      child: Container(
                        width: 90,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _activeSpeakerUid == uid
                                ? theme.success
                                : Colors.white24,
                            width: _activeSpeakerUid == uid ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _buildVideoTile(uid, tileBg: tileBg),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    }

    if (allUsers.length == 1) {
      // Only local user — full screen
      return GestureDetector(
        onTap: _resetControlsTimer,
        child: _buildVideoTile(null, fullScreen: true, tileBg: tileBg),
      );
    }

    if (allUsers.length == 2) {
      // 1 remote — big remote, small local pip, tap either to swap
      return Stack(
        children: [
          GestureDetector(
            onTap: () {
              _resetControlsTimer();
              setState(() => _fullScreenUid = _remoteUsers.first);
            },
            child: _buildVideoTile(_remoteUsers.first, fullScreen: true, tileBg: tileBg),
          ),
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 56,
            child: GestureDetector(
              onTap: () {
                _resetControlsTimer();
                setState(() => _fullScreenUid = _localUserSentinel);
              },
              child: Container(
                width: 110,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildVideoTile(null, tileBg: tileBg),
              ),
            ),
          ),
        ],
      );
    }

    // 3+ users — grid layout, tap any tile for fullscreen
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
        final uid = allUsers[i];
        return GestureDetector(
          onTap: () {
            _resetControlsTimer();
            setState(() {
              _fullScreenUid = uid == null ? _localUserSentinel : uid;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: _activeSpeakerUid == allUsers[i]
                  ? Border.all(color: theme.success, width: 2)
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildVideoTile(allUsers[i], tileBg: tileBg),
          ),
        );
      },
    );
  }

  Widget _buildVideoTile(int? uid, {bool fullScreen = false, Color? tileBg}) {
    final bgColor = tileBg ?? const Color(0xFF161B22);

    if (_engine == null) {
      return Container(
        color: bgColor,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white24, size: 40),
        ),
      );
    }

    final isLocal = uid == null;

    if (isLocal && !_camEnabled) {
      return Container(
        color: bgColor,
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
      color: bgColor,
      child: AgoraVideoView(controller: controller),
    );
  }

  // ─── Top Bar ───

  Widget _buildTopBar(OneUITheme theme) {
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
                              ? theme.success
                              : theme.warning,
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
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white, size: 20),
                color: theme.cardBackground,
                shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
                onSelected: (value) {
                  switch (value) {
                    case 'generate_certs':
                      _generateCertificates();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'generate_certs',
                    child: Row(
                      children: [
                        Icon(Icons.card_membership, size: 18, color: theme.primary),
                        const SizedBox(width: 8),
                        Text('Generate Certificates',
                            style: TextStyle(fontFamily: 'Poppins', color: theme.textPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            if (widget.isHost)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: theme.error.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'HOST',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: theme.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (_isSpeaker)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: theme.primary.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'SPEAKER',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: theme.primary,
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

  Widget _buildBottomControls(OneUITheme theme) {
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
              destructiveColor: theme.error,
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
    Color? destructiveColor,
    String? badge,
    required VoidCallback onTap,
  }) {
    final errorColor = destructiveColor ?? Colors.red;

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
                  ? errorColor
                  : active
                      ? Colors.white.withValues(alpha: 0.15)
                      : errorColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon,
                    color: Colors.white,
                    size: 22),
                if (badge != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: errorColor,
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

  Widget _buildInteractionPanel(OneUITheme theme) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.3, 0.55, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Compact drag handle + close
              Container(
                padding: const EdgeInsets.only(top: 8, bottom: 4, left: 16, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.textTertiary.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showInteractionPanel = false),
                      child: Icon(Icons.close, size: 20, color: theme.iconColor),
                    ),
                  ],
                ),
              ),
              // Embed the interaction screen (embedded mode - no Scaffold/AppBar)
              Expanded(
                child: CmeLiveInteractionScreen(
                  eventId: widget.eventId,
                  eventTitle: widget.eventTitle,
                  isHost: widget.isHost,
                  modules: widget.modules,
                  isEmbedded: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
