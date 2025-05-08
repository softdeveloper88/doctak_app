import 'package:doctak_app/presentation/calling_module/models/call_state.dart';
import 'package:doctak_app/presentation/calling_module/providers/call_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget that displays call control buttons
class CallControls extends StatelessWidget {
  final Function() onEndCallConfirm;

  const CallControls({Key? key, required this.onEndCallConfirm,})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final callState = callProvider.callState;
    final isVideoCall = callState.callType == CallType.video;

    return Container(padding: const EdgeInsets.symmetric(vertical: 16),
      color: isVideoCall ? Colors.transparent : Colors.black38,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // If video is active, show a light decorative line for better visibility
        if (isVideoCall)Container(height: 4,
          width: 40,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white30, borderRadius: BorderRadius.circular(2),),),

        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          // Mute button
          _CallControlButton(onTap: callProvider.toggleMute,
            icon: callState.isMuted ? CupertinoIcons.mic_off : CupertinoIcons
                .mic,
            label: "Mute",
            bgColor: callState.isMuted ? Colors.red : Colors.white24,),

          // Switch call type button
          _CallControlButton(onTap: callProvider.switchCallType,
            icon: isVideoCall ? Icons.phone : Icons.videocam,
            label: isVideoCall ? "Audio" : "Video",
            bgColor: Colors.white24,),

          // Speaker button
          _CallControlButton(onTap: callProvider.toggleSpeaker,
            icon: callState.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            label: "Speaker",
            bgColor: callState.isSpeakerOn ? Colors.white24 : Colors.white24,),

          // Swap cameras button or switch view button
          if (isVideoCall)_CallControlButton(onTap:
          // !callState.isRemoteUserJoined
          //     ? callProvider.swapLocalAndRemoteVideo
          //     :
          callProvider.switchCamera, icon:
          // callState.isRemoteUserJoined
          //     ? Icons.swap_horiz
          //     :
          CupertinoIcons.camera_rotate, label:
          // callState.isRemoteUserJoined ? "Swap" :
          "Flip", bgColor: Colors.white24,),

          // End call button
          _CallControlButton(onTap: onEndCallConfirm,
            icon: Icons.call_end,
            label: "End",
            bgColor: Colors.red,),
        ],),
      ],),);
  }
}

/// Individual call control button with animation
class _CallControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color bgColor;

  const _CallControlButton(
      {Key? key, required this.onTap, required this.icon, required this.label, required this.bgColor,})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Transform.scale(scale: 0.8 + (0.2 * value),
            child: Column(mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: bgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: bgColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,),
                    ],),
                  child: Icon(icon, color: Colors.white, size: 26,),),
                Text(label, style: const TextStyle(color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,),),
              ],),);
        },),);
  }
}


