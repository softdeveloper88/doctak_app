import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/block_user_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String profilePicUrl;
  final String userName;
  final String? createdAt;
  final String? specialty;
  final VoidCallback onProfileTap;
  final VoidCallback onDeleteTap;
  final bool isCurrentUser;
  final int? postId;
  final String? userId;
  final VoidCallback? onReportTap;
  final VoidCallback? onBlockTap;

  const ProfileHeaderWidget({
    super.key,
    required this.profilePicUrl,
    required this.userName,
    this.createdAt,
    this.specialty,
    required this.onProfileTap,
    required this.onDeleteTap,
    required this.isCurrentUser,
    this.postId,
    this.userId,
    this.onReportTap,
    this.onBlockTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onProfileTap(),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  // Clean circular avatar
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.avatarBackground,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: profilePicUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: profilePicUrl,
                              height: 42,
                              width: 42,
                              fit: BoxFit.cover,
                              memCacheWidth: 84,
                              memCacheHeight: 84,
                              fadeInDuration: const Duration(milliseconds: 150),
                              fadeOutDuration: const Duration(milliseconds: 100),
                              placeholder: (context, url) => Container(
                                color: theme.avatarBackground,
                                child: Center(
                                  child: Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                    style: TextStyle(color: theme.avatarText, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.avatarBackground,
                                child: Center(
                                  child: Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                    style: TextStyle(color: theme.avatarText, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: theme.avatarBackground,
                              child: Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                  style: TextStyle(color: theme.avatarText, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name and Verification Badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: theme.textPrimary),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Verified Badge
                            Icon(
                              CupertinoIcons.checkmark_seal_fill,
                              size: 14,
                              color: theme.verifiedBadge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Specialty or Time Info
                        if (specialty != null)
                          Row(
                            children: [
                              Icon(CupertinoIcons.heart_circle, size: 14, color: theme.textSecondary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  specialty!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.textSecondary, fontFamily: 'Poppins'),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Text(
                                createdAt ?? '',
                                style: TextStyle(fontSize: 12, color: theme.textSecondary),
                              ),
                              if (createdAt != null && createdAt!.isNotEmpty) ...[
                                Text(
                                  ' • ',
                                  style: TextStyle(fontSize: 12, color: theme.textSecondary),
                                ),
                                Icon(CupertinoIcons.globe, size: 12, color: theme.textSecondary),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // More Options Button
          PopupMenuButton<String>(
            icon: Icon(CupertinoIcons.ellipsis, color: theme.iconColor, size: 20),
            padding: const EdgeInsets.all(8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: theme.cardBackground,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              itemBuilder: (context) => [
                // Delete option - only for current user's posts
                if (isCurrentUser)
                  PopupMenuItem(
                    value: 'Delete',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.trash, color: theme.deleteRed, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: theme.deleteRed, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                // Report option - only for other users' posts
                if (!isCurrentUser)
                  PopupMenuItem(
                    value: 'Report',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.flag, color: theme.warning, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Report Post',
                          style: TextStyle(color: theme.warning, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                // Block user option - only for other users' posts
                if (!isCurrentUser)
                  PopupMenuItem(
                    value: 'Block',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.hand_raised, color: theme.deleteRed, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Block User',
                          style: TextStyle(color: theme.deleteRed, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'Delete') {
                  onDeleteTap();
                } else if (value == 'Report') {
                  // Show report bottom sheet
                  if (postId != null) {
                    ContentModerationBottomSheet.show(
                      context: context,
                      contentId: postId!,
                      contentType: 'post',
                      userId: userId,
                      userName: userName,
                      isCurrentUser: false,
                    );
                  } else {
                    onReportTap?.call();
                  }
                } else if (value == 'Block') {
                  // Show block dialog
                  if (userId != null) {
                    BlockUserDialog.show(
                      context: context,
                      userId: userId!,
                      userName: userName,
                      onUserBlocked: onBlockTap,
                    );
                  } else {
                    onBlockTap?.call();
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}
