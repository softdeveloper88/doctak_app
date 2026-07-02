import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/block_user_dialog.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/report_content_bottom_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_icons.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Overflow menu on feed cards — edit/delete (own), report/block/not interested (others).
class FeedCardOverflowMenu extends StatelessWidget {
  final bool isCurrentUser;
  final String? postId;
  final String? userId;
  final String authorName;
  final String contentType;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDismiss;
  final VoidCallback? onUserBlocked;

  const FeedCardOverflowMenu({
    super.key,
    required this.isCurrentUser,
    this.postId,
    this.userId,
    this.authorName = 'Member',
    this.contentType = 'post',
    this.onEdit,
    this.onDelete,
    this.onDismiss,
    this.onUserBlocked,
  });

  bool get _showMenu {
    if (isCurrentUser) return onDelete != null || onEdit != null;
    return postId != null && userId != null && userId!.isNotEmpty;
  }

  Future<void> _notInterested() async {
    if (postId == null || postId!.isEmpty) return;
    await SharedApiService().recordFeedInteraction(
      contentType: contentType,
      contentId: postId!,
      type: 'dismiss',
    );
    onDismiss?.call();
    toast('Post hidden from your feed');
  }

  @override
  Widget build(BuildContext context) {
    if (!_showMenu) return const SizedBox.shrink();

    final theme = OneUITheme.of(context);

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, size: 20, color: theme.iconColor),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.cardBackground,
      elevation: 8,
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
          case 'report':
            final id = int.tryParse(postId ?? '');
            if (id != null) {
              await ReportContentBottomSheet.show(
                context: context,
                contentId: postId!,
                contentType: contentType,
                contentOwnerName: authorName,
              );
            }
            break;
          case 'block':
            if (userId != null && userId!.isNotEmpty) {
              await BlockUserDialog.show(
                context: context,
                userId: userId!,
                userName: authorName,
                onUserBlocked: onUserBlocked,
              );
            }
            break;
          case 'dismiss':
            await _notInterested();
            break;
        }
      },
      itemBuilder: (context) {
        if (isCurrentUser) {
          return [
            if (onEdit != null)
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: theme.textSecondary, size: 20),
                    const SizedBox(width: 12),
                    Text('Edit',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            if (onDelete != null)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.trash, color: theme.deleteRed, size: 20),
                    const SizedBox(width: 12),
                    Text('Delete',
                        style: TextStyle(
                            color: theme.deleteRed,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
          ];
        }
        return [
          PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(CupertinoIcons.flag, color: theme.warning, size: 20),
                const SizedBox(width: 12),
                Text('Report Post',
                    style: TextStyle(
                        color: theme.warning,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'block',
            child: Row(
              children: [
                Icon(CupertinoIcons.hand_raised,
                    color: theme.deleteRed, size: 20),
                const SizedBox(width: 12),
                Text('Block User',
                    style: TextStyle(
                        color: theme.deleteRed,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'dismiss',
            child: Row(
              children: [
                Icon(CupertinoIcons.eye_slash,
                    color: theme.textSecondary, size: 20),
                const SizedBox(width: 12),
                Text('Not interested',
                    style: TextStyle(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ];
      },
    );
  }
}
