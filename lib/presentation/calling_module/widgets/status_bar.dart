// lib/presentation/call_module/widgets/status_bar.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctak_app/presentation/calling_module/providers/call_provider.dart';
import 'package:doctak_app/presentation/calling_module/models/call_state.dart';
import 'package:doctak_app/presentation/calling_module/models/user_model.dart';
import 'package:doctak_app/localization/app_localization.dart';

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
          Expanded(
            child: Row(
              children: [
                // Small avatar
                if (!isVideoCall || !callState.isRemoteUserJoined)
                  _buildAvatar(remoteUser),

                // Name and call type
                Expanded(
                  child: Column(
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
                          Flexible(
                            child: Text(
                              "${isVideoCall ? translation(context).lbl_video : translation(context).lbl_audio} ${translation(context).lbl_end_call.toLowerCase()} · ${callState.formattedCallDuration}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        color: Colors.grey.shade800,
      ),
      child: ClipOval(
        child: user.avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: user.avatarUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Icon(Icons.person, size: 20, color: Colors.white),
                errorWidget: (context, url, error) => const Icon(Icons.person, size: 20, color: Colors.white),
              )
            : const Icon(Icons.person, size: 20, color: Colors.white),
      ),
    );
  }
}
