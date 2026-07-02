import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/post_comment_model/reply_comment_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_sheet_widgets.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ImprovedReplyCommentComponent extends StatefulWidget {
  final CommentsModel replyComment;
  final Function? onDelete;
  final Function? onEdit;
  final VoidCallback? onLike;

  const ImprovedReplyCommentComponent({
    required this.replyComment,
    this.onDelete,
    this.onEdit,
    this.onLike,
    super.key,
  });

  @override
  State<ImprovedReplyCommentComponent> createState() =>
      _ImprovedReplyCommentComponentState();
}

class _ImprovedReplyCommentComponentState
    extends State<ImprovedReplyCommentComponent> {
  String? _resolvedSpecialty(String? raw) {
    if (raw == null) return null;
    final resolved = displaySpecialty(raw).trim();
    if (resolved.isNotEmpty) return resolved;
    final original = raw.trim();
    return original.isEmpty || SpecialtyDisplay.isNumericId(original) ? null : original;
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final name = widget.replyComment.commenter?.name ?? 'Member';
    final isOwn = widget.replyComment.commenterId == AppData.logInUserId;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 2,
                height: 28,
                decoration: BoxDecoration(
                  color: CommentSheetTokens.threadLine,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CommentSheetAvatar(
            name: name,
            imageUrl: widget.replyComment.commenter?.profilePic,
            size: CommentSheetTokens.avatarReply,
            onTap: () => ProfileNavigation.openUser(
                  context,
                  widget.replyComment.commenterId,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommentSheetBubble(
                  name: name,
                  body: widget.replyComment.comment ?? '',
                  specialty: _resolvedSpecialty(widget.replyComment.commenter?.specialty),
                  verified: widget.replyComment.commenter?.isVerified == true,
                  theme: theme,
                ),
                CommentSheetActionRow(
                  theme: theme,
                  timeLabel: commentShortRelativeTime(widget.replyComment.createdAt),
                  liked: widget.replyComment.userHasLiked ?? false,
                  likeCount: widget.replyComment.likeCount ?? 0,
                  onLike: widget.onLike,
                  onReply: null,
                  trailingMenu: isOwn ? _ownMenu(context, theme) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ownMenu(BuildContext context, OneUITheme theme) {
    return SizedBox(
      width: 28,
      height: 28,
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_horiz_rounded,
          color: CommentSheetTokens.metaText,
          size: 18,
        ),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: theme.primary),
                const SizedBox(width: 8),
                Text(
                  translation(context).lbl_update,
                  style: TextStyle(fontSize: CommentSheetTokens.actionSize, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            height: 40,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 16, color: theme.error),
                const SizedBox(width: 8),
                Text(
                  translation(context).lbl_delete,
                  style: TextStyle(fontSize: CommentSheetTokens.actionSize, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'delete') {
            showDialog(
              context: context,
              useRootNavigator: false,
              builder: (BuildContext context) {
                return CustomAlertDialog(
                  title: translation(context).msg_confirm_delete_comment,
                  callback: () => widget.onDelete?.call(),
                );
              },
            );
          } else if (value == 'edit') {
            widget.onEdit?.call();
          }
        },
      ),
    );
  }
}
