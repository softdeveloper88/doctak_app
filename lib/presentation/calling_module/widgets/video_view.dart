// lib/presentation/call_module/widgets/video_view.dart
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import 'package:doctak_app/presentation/calling_module/providers/call_provider.dart';
import 'package:doctak_app/presentation/calling_module/models/call_state.dart';

/// Widget that manages video views (local and remote)
class VideoView extends StatelessWidget {
  const VideoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final callState = callProvider.callState;

    if (callState.isLocalVideoFullScreen) {
      return LocalVideoMainView(
        remoteUid: callState.remoteUid,
        channelId: callState.callId,
        isRemoteUserSpeaking: callState.isRemoteUserSpeaking,
        onTap: callProvider.swapLocalAndRemoteVideo,
      );
    } else {
      return RemoteVideoMainView(
        remoteUid: callState.remoteUid,
        channelId: callState.callId,
      );
    }
  }
}

/// Widget that displays the local video as main view with remote video in PIP
class LocalVideoMainView extends StatelessWidget {
  final int? remoteUid;
  final String channelId;
  final bool isRemoteUserSpeaking;
  final VoidCallback onTap;

  const LocalVideoMainView({
    Key? key,
    required this.remoteUid,
    required this.channelId,
    required this.isRemoteUserSpeaking,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final agoraEngine = Provider.of<CallProvider>(context).getAgoraEngine();

    if (agoraEngine == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Main video (local)
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: agoraEngine,
            canvas: const VideoCanvas(uid: 0),
          ),
        ),

        // Bottom gradient for controls visibility
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),

        // Remote video in PIP
        if (remoteUid != null)
          Positioned(
            right: 16,
            top: 80,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 120,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRemoteUserSpeaking
                        ? Colors.green.withOpacity(0.7)
                        : Colors.white30,
                    width: isRemoteUserSpeaking ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: agoraEngine,
                      canvas: VideoCanvas(uid: remoteUid),
                      connection: RtcConnection(channelId: channelId),
                      useFlutterTexture: true,
                      useAndroidSurfaceView: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
/// Widget that displays the remote video as main view with local video in PIP
class RemoteVideoMainView extends StatelessWidget {
  final int? remoteUid;
  final String channelId;

  const RemoteVideoMainView({
    Key? key,
    required this.remoteUid,
    required this.channelId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final agoraEngine = Provider.of<CallProvider>(context).getAgoraEngine();

    if (remoteUid == null || agoraEngine == null) {
      return const WaitingForRemoteView();
    }

    return Stack(
      children: [
        // Main video view - remote video
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: agoraEngine,
            canvas: VideoCanvas(uid: remoteUid),
            connection: RtcConnection(channelId: channelId),
            // useFlutterTexture: true,
            // useAndroidSurfaceView: true,
          ),
        ),

        // Bottom gradient overlay for better visibility of controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),

        // Top gradient overlay for better visibility of status bar
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 80,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget that displays the local video preview
class LocalVideoPreview extends StatelessWidget {
  final bool isEnabled;
  final bool isUserSpeaking;
  final bool isFrontCamera;
  final VoidCallback onTap;

  const LocalVideoPreview({
    Key? key,
    required this.isEnabled,
    required this.isUserSpeaking,
    required this.isFrontCamera,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final agoraEngine = Provider.of<CallProvider>(context).getAgoraEngine();

    if (agoraEngine == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUserSpeaking
                ? Colors.green.withOpacity(0.7)
                : Colors.white30,
            width: isUserSpeaking ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video view or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: isEnabled
                  ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: agoraEngine,
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

            // Camera toggle indicator
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isFrontCamera ? Icons.camera_front : Icons.camera_rear,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),

            // Speaking indicator
            if (isUserSpeaking)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget that displays waiting for remote user UI
class WaitingForRemoteView extends StatelessWidget {
  const WaitingForRemoteView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final remoteUser = callProvider.remoteUser;
    final isVideoCall = callProvider.callState.callType == CallType.video;

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
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey.shade800,
              backgroundImage: remoteUser.avatarUrl.isNotEmpty
                  ? NetworkImage(remoteUser.avatarUrl)
                  : null,
              child: remoteUser.avatarUrl.isEmpty
                  ? const Icon(Icons.person, size: 70, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              translation(context).lbl_calling_user(remoteUser.name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isVideoCall ? translation(context).lbl_video_call : translation(context).lbl_audio_call,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Animated waiting indicator
            const WaitingDots(),
          ],
        ),
      ),
    );
  }
}

/// Animated waiting dots
class WaitingDots extends StatefulWidget {
  const WaitingDots({Key? key}) : super(key: key);

  @override
  State<WaitingDots> createState() => _WaitingDotsState();
}

class _WaitingDotsState extends State<WaitingDots> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    // Create 3 dots with staggered animations
    _controllers = List.generate(3, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 400 + (index * 200)),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(controller);
    }).toList();

    // Start the animations
    for (final controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 10,
                height: 10 * _animations[index].value,
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
