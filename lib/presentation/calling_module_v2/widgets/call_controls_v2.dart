import 'package:flutter/material.dart';

import '../controller/call_controller_v2.dart';
import '../models/call_protocol.dart';

/// Calling module v2 — bottom control bar (mute / video / speaker / camera
/// flip / hang up) plus the accept-reject pair while ringing as callee.
class CallControlsV2 extends StatelessWidget {
  final CallControllerV2 controller;

  const CallControlsV2({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (controller.phase == CallPhaseV2.incoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _RoundButton(
            icon: Icons.call_end_rounded,
            background: Colors.redAccent,
            size: 68,
            onTap: controller.reject,
            label: 'Decline',
          ),
          _RoundButton(
            icon: controller.callType == CallTypeV2.video
                ? Icons.videocam_rounded
                : Icons.call_rounded,
            background: const Color(0xFF22C55E),
            size: 68,
            onTap: controller.accept,
            label: 'Accept',
          ),
        ],
      );
    }

    if (controller.phase == CallPhaseV2.ended) {
      return const SizedBox.shrink();
    }

    final inCall = controller.phase == CallPhaseV2.active ||
        controller.phase == CallPhaseV2.reconnecting ||
        controller.phase == CallPhaseV2.connecting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (inCall)
          Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RoundButton(
                  icon: controller.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  background: controller.muted ? Colors.white : Colors.white12,
                  iconColor: controller.muted ? const Color(0xFF101826) : Colors.white,
                  onTap: controller.toggleMute,
                  label: 'Mute',
                ),
                _RoundButton(
                  icon: controller.videoEnabled
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  background: controller.videoEnabled ? Colors.white12 : Colors.white,
                  iconColor: controller.videoEnabled ? Colors.white : const Color(0xFF101826),
                  onTap: controller.toggleVideo,
                  label: 'Video',
                ),
                _RoundButton(
                  icon: controller.speakerOn
                      ? Icons.volume_up_rounded
                      : Icons.volume_down_rounded,
                  background: controller.speakerOn ? Colors.white : Colors.white12,
                  iconColor: controller.speakerOn ? const Color(0xFF101826) : Colors.white,
                  onTap: controller.toggleSpeaker,
                  label: 'Speaker',
                ),
                if (controller.videoEnabled)
                  _RoundButton(
                    icon: Icons.cameraswitch_rounded,
                    background: Colors.white12,
                    onTap: controller.switchCamera,
                    label: 'Flip',
                  ),
              ],
            ),
          ),
        _RoundButton(
          icon: Icons.call_end_rounded,
          background: Colors.redAccent,
          size: 68,
          onTap: controller.hangUp,
          label: 'End',
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color iconColor;
  final double size;
  final VoidCallback onTap;
  final String label;

  const _RoundButton({
    required this.icon,
    required this.background,
    this.iconColor = Colors.white,
    this.size = 56,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: iconColor, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}
