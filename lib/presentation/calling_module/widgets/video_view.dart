// lib/presentation/call_module/widgets/video_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import 'package:doctak_app/presentation/calling_module/providers/call_provider.dart';
import 'package:doctak_app/presentation/calling_module/models/call_state.dart';
import '../utils/platform_config.dart';

/// Widget that manages video views (local and remote) with OneUI 8.5 theming
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
    final theme = OneUITheme.of(context);
    final agoraEngine = Provider.of<CallProvider>(context).getAgoraEngine();

    if (agoraEngine == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Main video (local) with platform-specific settings
        AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: agoraEngine,
            canvas: const VideoCanvas(uid: 0),
            useFlutterTexture: PlatformConfig.isIOS,
            useAndroidSurfaceView: PlatformConfig.isAndroid,
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
                  theme.scaffoldBackground.withOpacity(0.85),
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
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRemoteUserSpeaking
                        ? theme.success.withOpacity(0.8)
                        : theme.divider,
                    width: isRemoteUserSpeaking ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.scaffoldBackground.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: agoraEngine,
                      canvas: VideoCanvas(uid: remoteUid),
                      connection: RtcConnection(channelId: channelId),
                      useFlutterTexture: PlatformConfig.isIOS,
                      useAndroidSurfaceView: PlatformConfig.isAndroid,
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
    final theme = OneUITheme.of(context);
    final agoraEngine = Provider.of<CallProvider>(context).getAgoraEngine();

    if (remoteUid == null || agoraEngine == null) {
      return const WaitingForRemoteView();
    }

    return Stack(
      children: [
        // Main video view - remote video with platform optimization
        AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: agoraEngine,
            canvas: VideoCanvas(uid: remoteUid),
            connection: RtcConnection(channelId: channelId),
            useFlutterTexture: PlatformConfig.isIOS,
            useAndroidSurfaceView: PlatformConfig.isAndroid,
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
                  theme.scaffoldBackground.withOpacity(0.85),
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
                  theme.scaffoldBackground.withOpacity(0.85),
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
    final theme = OneUITheme.of(context);
    final agoraEngine = Provider.of<CallProvider>(context).getAgoraEngine();

    if (agoraEngine == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 180,
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUserSpeaking
                ? theme.success.withOpacity(0.8)
                : theme.divider,
            width: isUserSpeaking ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.scaffoldBackground.withOpacity(0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video view or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: isEnabled
                  ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: agoraEngine,
                  canvas: const VideoCanvas(uid: 0),
                  useFlutterTexture: PlatformConfig.isIOS,
                  useAndroidSurfaceView: PlatformConfig.isAndroid,
                ),
              )
                  : Container(
                color: theme.surfaceVariant,
                child: Center(
                  child: Icon(
                    Icons.videocam_off_rounded,
                    color: theme.textTertiary,
                    size: 32,
                  ),
                ),
              ),
            ),

            // Camera toggle indicator
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isFrontCamera ? Icons.camera_front_rounded : Icons.camera_rear_rounded,
                  color: theme.textSecondary,
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.success.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
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

/// Widget that displays waiting for remote user UI with OneUI 8.5 theming
/// Note: Calling screens always use dark background for consistent experience
class WaitingForRemoteView extends StatelessWidget {
  const WaitingForRemoteView({Key? key}) : super(key: key);

  // Fixed dark calling screen colors for consistent experience in both light/dark themes
  static const _callBackgroundDark = Color(0xFF1A2332);
  static const _callBackgroundLight = Color(0xFF243447);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final callProvider = Provider.of<CallProvider>(context);
    final remoteUser = callProvider.remoteUser;
    final isVideoCall = callProvider.callState.callType == CallType.video;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _callBackgroundLight,
            _callBackgroundDark,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar with elegant border and glow effect
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primary.withOpacity(0.6),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 75,
                backgroundColor: Colors.white.withOpacity(0.15),
                child: remoteUser.avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: remoteUser.avatarUrl,
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Icon(
                            Icons.person_rounded,
                            size: 75,
                            color: Colors.white70,
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person_rounded,
                            size: 75,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : _buildInitialsAvatar(remoteUser.name),
              ),
            ),
            const SizedBox(height: 32),
            
            // Calling user name - WHITE text for visibility
            Text(
              remoteUser.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Call type badge with glassmorphism effect
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVideoCall ? Icons.videocam_rounded : Icons.phone_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    translation(context).lbl_calling_status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            
            // Animated waiting indicator using theme primary color
            WaitingDots(dotColor: theme.primary),
          ],
        ),
      ),
    );
  }

  /// Builds initials avatar when no image is available
  Widget _buildInitialsAvatar(String name) {
    final initials = name.isNotEmpty 
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : '?';
    
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE91E63), // Pink
            const Color(0xFFE91E63).withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}

/// Animated waiting dots with OneUI theming
class WaitingDots extends StatefulWidget {
  final Color? dotColor;
  
  const WaitingDots({Key? key, this.dotColor}) : super(key: key);

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
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
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
    final theme = OneUITheme.of(context);
    final color = widget.dotColor ?? theme.primary;
    
    return SizedBox(
      width: 70,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12 * _animations[index].value,
                decoration: BoxDecoration(
                  color: color.withOpacity(_animations[index].value),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
