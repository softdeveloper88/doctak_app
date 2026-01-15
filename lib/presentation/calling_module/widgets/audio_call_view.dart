// lib/presentation/call_module/widgets/audio_call_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctak_app/presentation/calling_module/providers/call_provider.dart';
import 'package:doctak_app/presentation/calling_module/widgets/waveform_painter.dart';

/// Widget that displays the audio call UI with OneUI 8.5 theming
/// Note: Calling screens always use dark background for consistent experience
class AudioCallView extends StatelessWidget {
  const AudioCallView({super.key});

  // Calling screen colors - always dark for consistent experience
  static const _callBackgroundDark = Color(0xFF1A2332);
  static const _callBackgroundLight = Color(0xFF243447);

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final callState = callProvider.callState;
    final remoteUser = callProvider.remoteUser;
    final theme = OneUITheme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.primary.withValues(alpha: 0.3), _callBackgroundLight, _callBackgroundDark],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern for audio calls
          Opacity(
            opacity: 0.05,
            child: CustomPaint(size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height), painter: AudioWaveformPainter()),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Contact avatar with speaking animation
                SpeakingAvatar(avatarUrl: remoteUser.avatarUrl, isSpeaking: callState.isRemoteUserSpeaking),

                const SizedBox(height: 30),
                Text(
                  remoteUser.name,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "${translation(context).lbl_in_call} · ${callState.formattedCallDuration}",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays an avatar with speaking animation
class SpeakingAvatar extends StatefulWidget {
  final String avatarUrl;
  final bool isSpeaking;

  const SpeakingAvatar({super.key, required this.avatarUrl, required this.isSpeaking});

  @override
  State<SpeakingAvatar> createState() => _SpeakingAvatarState();
}

class _SpeakingAvatarState extends State<SpeakingAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Calling screen colors
  static final _callSurfaceVariant = Colors.white.withValues(alpha: 0.1);
  static final _callTextTertiary = Colors.white.withValues(alpha: 0.5);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 750), vsync: this)..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Animated speaking indicator
            if (widget.isSpeaking)
              ...List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 1500 + index * 300),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: (1.0 - value) * 0.5,
                      child: Transform.scale(
                        scale: 1.0 + value * 0.8,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(color: theme.success.withValues(alpha: 0.4), shape: BoxShape.circle),
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    if (mounted && widget.isSpeaking) {
                      setState(() {});
                    }
                  },
                );
              }),

            // Avatar container
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.isSpeaking ? theme.success.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.3), width: widget.isSpeaking ? 3 : 2),
                boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 4)],
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundColor: _callSurfaceVariant,
                child: widget.avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.avatarUrl,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(Icons.person_rounded, size: 70, color: _callTextTertiary),
                          errorWidget: (context, url, error) => Icon(Icons.person_rounded, size: 70, color: _callTextTertiary),
                        ),
                      )
                    : Icon(Icons.person_rounded, size: 70, color: _callTextTertiary),
              ),
            ),
          ],
        );
      },
    );
  }
}
