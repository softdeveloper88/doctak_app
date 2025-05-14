// lib/presentation/call_module/widgets/status_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctak_app/presentation/calling_module/providers/call_provider.dart';
import 'package:doctak_app/presentation/calling_module/models/call_state.dart';
import 'package:doctak_app/presentation/calling_module/models/user_model.dart';

import '../../../localization/app_localization.dart';
import '../models/user_model.dart';

/// Widget that displays call status information at the top of the screen
class StatusBar extends StatelessWidget {
  const StatusBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final callProvider = Provider.of<CallProvider>(context);
    final callState = callProvider.callState;
    final remoteUser = callProvider.remoteUser;
    final isVideoCall = callState.callType == CallType.video;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isVideoCall ? Colors.transparent : Colors.black45,
        boxShadow: isVideoCall
            ? []
            : [BoxShadow(
          color: Colors.black26,
          blurRadius: 4,
          spreadRadius: 1,
        )],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Contact info
          Row(
            children: [
              // Small avatar
              if (!isVideoCall || !callState.isRemoteUserJoined)
                _buildAvatar(remoteUser),

              // Name and call type
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remoteUser.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isVideoCall ? Icons.videocam : Icons.phone,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${isVideoCall ? translation(context).lbl_video : translation(context).lbl_audio} ${translation(context).lbl_end_call.toLowerCase()} · ${callState.formattedCallDuration}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Network quality indicator
          if (callState.networkQuality != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    callState.getNetworkQualityIcon(),
                    color: callState.getNetworkQualityColor(),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    callState.getNetworkQualityText(context: context),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: user.avatarUrl.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(user.avatarUrl),
          fit: BoxFit.cover,
        )
            : null,
        color: user.avatarUrl.isEmpty ? Colors.grey.shade800 : null,
      ),
      child: user.avatarUrl.isEmpty
          ? const Icon(Icons.person, size: 20, color: Colors.white)
          : null,
    );
  }
}
