// lib/presentation/call_module/widgets/status_bar.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:doctak_app/presentation/calling_module/providers/call_provider.dart';
import 'package:doctak_app/presentation/calling_module/models/call_state.dart';
import 'package:doctak_app/presentation/calling_module/models/user_model.dart';
import 'package:doctak_app/localization/app_localization.dart';

/// Widget that displays call status information at the top of the screen with OneUI 8.5 theming
/// Note: Calling screens always use dark background for consistent experience
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  // Calling screen colors - always dark for consistent experience
  static const _callTextPrimary = Colors.white;
  static final _callTextSecondary = Colors.white70;
  static final _callSurfaceVariant = Colors.white.withValues(alpha: 0.1);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final callProvider = Provider.of<CallProvider>(context);
    final callState = callProvider.callState;
    final remoteUser = callProvider.remoteUser;
    final isVideoCall = callState.callType == CallType.video;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isVideoCall ? Colors.transparent : _callSurfaceVariant,
        borderRadius: isVideoCall ? null : const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Contact info
          Flexible(
            child: Row(
              children: [
                // Small avatar
                if (!isVideoCall || !callState.isRemoteUserJoined) _buildAvatar(remoteUser, theme),

                // Name and call type
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        remoteUser.name,
                        style: const TextStyle(color: _callTextPrimary, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isVideoCall ? Icons.videocam_rounded : Icons.phone_rounded, color: _callTextSecondary, size: 14),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              "${isVideoCall ? translation(context).lbl_video : translation(context).lbl_audio} ${translation(context).lbl_end_call.toLowerCase()} · ${callState.formattedCallDuration}",
                              style: TextStyle(color: _callTextSecondary, fontSize: 12, fontFamily: 'Poppins'),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(callState.getNetworkQualityIcon(), color: callState.getNetworkQualityColor(), size: 14),
                  const SizedBox(width: 5),
                  Text(
                    callState.getNetworkQualityText(context: context),
                    style: const TextStyle(color: _callTextPrimary, fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserModel user, OneUITheme theme) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _callSurfaceVariant,
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: ClipOval(
        child: user.avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: user.avatarUrl,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                placeholder: (context, url) => Icon(Icons.person_rounded, size: 22, color: _callTextSecondary),
                errorWidget: (context, url, error) => Icon(Icons.person_rounded, size: 22, color: _callTextSecondary),
              )
            : Icon(Icons.person_rounded, size: 22, color: _callTextSecondary),
      ),
    );
  }
}
