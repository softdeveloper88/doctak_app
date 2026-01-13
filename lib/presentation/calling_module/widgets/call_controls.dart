import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/calling_module/models/call_state.dart';
import 'package:doctak_app/presentation/calling_module/providers/call_provider.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget that displays call control buttons with OneUI 8.5 theming
class CallControls extends StatelessWidget {
  final Function() onEndCallConfirm;

  const CallControls({
    Key? key,
    required this.onEndCallConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final callState = callProvider.callState;
    final isVideoCall = callState.callType == CallType.video;
    final theme = OneUITheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(isVideoCall ? 0.6 : 0.4),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative handle
            Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Mute button
                _CallControlButton(
                  onTap: callProvider.toggleMute,
                  icon: callState.isMuted ? CupertinoIcons.mic_off : CupertinoIcons.mic,
                  label: translation(context).lbl_mute,
                  bgColor: callState.isMuted ? theme.error : Colors.white.withOpacity(0.2),
                  isActive: callState.isMuted,
                ),

                // Switch call type button
                _CallControlButton(
                  onTap: callProvider.switchCallType,
                  icon: isVideoCall ? Icons.phone_rounded : Icons.videocam_rounded,
                  label: isVideoCall ? translation(context).lbl_audio : translation(context).lbl_video,
                  bgColor: Colors.white.withOpacity(0.2),
                  isActive: false,
                ),

                // Speaker button
                _CallControlButton(
                  onTap: callProvider.toggleSpeaker,
                  icon: callState.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  label: translation(context).lbl_speaker,
                  bgColor: callState.isSpeakerOn ? theme.primary : Colors.white.withOpacity(0.2),
                  isActive: callState.isSpeakerOn,
                ),

                // Swap cameras button (video only)
                if (isVideoCall)
                  _CallControlButton(
                    onTap: callProvider.switchCamera,
                    icon: CupertinoIcons.camera_rotate,
                    label: translation(context).lbl_flip,
                    bgColor: Colors.white.withOpacity(0.2),
                    isActive: false,
                  ),

                // End call button
                _CallControlButton(
                  onTap: onEndCallConfirm,
                  icon: Icons.call_end_rounded,
                  label: translation(context).lbl_end,
                  bgColor: theme.error,
                  isActive: true,
                  isEndCall: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual call control button with OneUI 8.5 styling
class _CallControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color bgColor;
  final bool isActive;
  final bool isEndCall;

  const _CallControlButton({
    Key? key,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.bgColor,
    this.isActive = false,
    this.isEndCall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isEndCall ? 64 : 56,
            height: isEndCall ? 64 : 56,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isEndCall ? 28 : 24,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}


