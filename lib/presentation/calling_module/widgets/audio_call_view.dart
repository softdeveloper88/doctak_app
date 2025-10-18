// lib/presentation/call_module/widgets/audio_call_view.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctak_app/presentation/calling_module/providers/call_provider.dart';
import 'package:doctak_app/presentation/calling_module/models/call_state.dart';
import 'package:doctak_app/presentation/calling_module/widgets/waveform_painter.dart';

/// Widget that displays the audio call UI
class AudioCallView extends StatelessWidget {
  const AudioCallView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final callState = callProvider.callState;
    final remoteUser = callProvider.remoteUser;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade900, Colors.black],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern for audio calls
          Opacity(
            opacity: 0.05,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              painter: AudioWaveformPainter(),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Contact avatar with speaking animation
                SpeakingAvatar(
                  avatarUrl: remoteUser.avatarUrl,
                  isSpeaking: callState.isRemoteUserSpeaking,
                ),

                const SizedBox(height: 30),
                Text(
                  remoteUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${translation(context).lbl_in_call} · ${callState.formattedCallDuration}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
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

  const SpeakingAvatar({
    Key? key,
    required this.avatarUrl,
    required this.isSpeaking,
  }) : super(key: key);

  @override
  State<SpeakingAvatar> createState() => _SpeakingAvatarState();
}

class _SpeakingAvatarState extends State<SpeakingAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
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
                border: Border.all(
                  color: widget.isSpeaking
                      ? Colors.green.withOpacity(0.7)
                      : Colors.white24,
                  width: widget.isSpeaking ? 3 : 1,
                ),
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey.shade800,
                child: widget.avatarUrl.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.avatarUrl,
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Icon(Icons.person, size: 70, color: Colors.white),
                          errorWidget: (context, url, error) => const Icon(Icons.person, size: 70, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.person, size: 70, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

