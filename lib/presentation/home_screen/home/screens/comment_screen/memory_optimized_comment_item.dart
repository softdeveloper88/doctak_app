import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_sheet_widgets.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/improved_reply_comment_list_widget.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/block_user_dialog.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/report_content_bottom_sheet.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nb_utils/nb_utils.dart';

class MemoryOptimizedCommentItem extends StatefulWidget {
  final PostComments comment;
  final CommentBloc commentBloc;
  final String postId;
  final int? selectedCommentId;
  final int? focusReplyForCommentId;
  final void Function(int commentId, {bool expandOnly}) onReplySelected;
  final VoidCallback? onReplyFocusHandled;

  const MemoryOptimizedCommentItem({
    super.key,
    required this.comment,
    required this.commentBloc,
    required this.postId,
    this.selectedCommentId,
    this.focusReplyForCommentId,
    required this.onReplySelected,
    this.onReplyFocusHandled,
  });

  @override
  State<MemoryOptimizedCommentItem> createState() =>
      _MemoryOptimizedCommentItemState();
}

class _MemoryOptimizedCommentItemState extends State<MemoryOptimizedCommentItem> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentBloc, CommentState>(
      bloc: widget.commentBloc,
      builder: (context, state) {
        final comment = widget.commentBloc.postList.firstWhere(
          (c) => c.id == widget.comment.id,
          orElse: () => widget.comment,
        );
        return _buildItem(context, comment);
      },
    );
  }

  Widget _buildItem(BuildContext context, PostComments comment) {
    final theme = OneUITheme.of(context);
    final commenter = comment.commenter;
    final name = commentDisplayName(
      firstName: commenter?.firstName,
      lastName: commenter?.lastName,
    );
    final replyCount = comment.replyCount ?? 0;
    final isExpanded = widget.selectedCommentId == comment.id;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CommentSheetTokens.horizontalPadding,
          10,
          CommentSheetTokens.horizontalPadding,
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommentSheetAvatar(
              name: name,
              imageUrl: commenter?.profilePic,
              size: CommentSheetTokens.avatarMain,
              onTap: () => ProfileNavigation.openUser(
                    context,
                    commenter?.id?.toString(),
                  ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommentSheetBubble(
                    name: name,
                    body: comment.comment ?? '',
                    specialty: _resolvedSpecialty(commenter?.specialty),
                    verified: commenter?.isVerified == true,
                    theme: theme,
                  ),
                  CommentSheetActionRow(
                    theme: theme,
                    timeLabel: commentShortRelativeTime(comment.createdAt),
                    liked: comment.userHasLiked ?? false,
                    likeCount: comment.reactionCount ?? 0,
                    onLike: _toggleLike,
                    onReply: comment.id != null && comment.id! > 0
                        ? () => widget.onReplySelected(
                              comment.id!,
                              expandOnly: true,
                            )
                        : null,
                    trailingMenu: _buildOptionsMenu(theme),
                  ),
                  if (!isExpanded && replyCount > 0)
                    CommentViewRepliesLink(
                      count: replyCount,
                      onTap: () => widget.onReplySelected(comment.id!),
                    ),
                  if (isExpanded) ...[
                    ImprovedReplyCommentListWidget(
                      key: ValueKey('replies_${comment.id}'),
                      commentBloc: widget.commentBloc,
                      commentId: comment.id!,
                      requestReplyFocus:
                          widget.focusReplyForCommentId == comment.id,
                      onReplyFocusHandled: widget.onReplyFocusHandled,
                    ),
                    CommentViewRepliesLink(
                      count: replyCount,
                      hide: true,
                      onTap: () => widget.onReplySelected(comment.id!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _resolvedSpecialty(String? raw) {
    if (raw == null) return null;
    final resolved = displaySpecialty(raw).trim();
    if (resolved.isNotEmpty) return resolved;
    final original = raw.trim();
    return original.isEmpty || SpecialtyDisplay.isNumericId(original) ? null : original;
  }

  void _toggleLike() {
    final id = widget.comment.id?.toString();
    if (id == null || id.isEmpty) return;
    widget.commentBloc.add(LikeReplyComment(commentId: id));
  }

  Widget _buildOptionsMenu(OneUITheme theme) {
    final isOwnComment = widget.comment.commenter?.id == AppData.logInUserId;

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
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) {
          if (isOwnComment) {
            return [
              PopupMenuItem(
                value: 'edit',
                height: 40,
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, color: theme.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      translation(context).lbl_edit,
                      style: TextStyle(
                        fontSize: CommentSheetTokens.actionSize,
                        fontFamily: 'Poppins',
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                height: 40,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: theme.error, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      translation(context).lbl_delete,
                      style: TextStyle(
                        fontSize: CommentSheetTokens.actionSize,
                        fontFamily: 'Poppins',
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ];
          }
          return [
            PopupMenuItem(
              value: 'report',
              height: 40,
              child: Row(
                children: [
                  Icon(CupertinoIcons.flag, color: theme.warning, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Report Comment',
                    style: TextStyle(
                      fontSize: CommentSheetTokens.actionSize,
                      fontFamily: 'Poppins',
                      color: theme.warning,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'block',
              height: 40,
              child: Row(
                children: [
                  Icon(CupertinoIcons.hand_raised, color: theme.error, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Block User',
                    style: TextStyle(
                      fontSize: CommentSheetTokens.actionSize,
                      fontFamily: 'Poppins',
                      color: theme.error,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        onSelected: (value) {
          if (value == 'edit') {
            _showEditCommentDialog(context, theme);
          } else if (value == 'delete') {
            showDialog(
              context: context,
              useRootNavigator: false,
              builder: (BuildContext context) {
                return CustomAlertDialog(
                  title: translation(context).msg_confirm_delete_comment,
                  callback: () {
                    widget.commentBloc.add(
                      DeleteCommentEvent(
                        commentId: widget.comment.id.toString(),
                      ),
                    );
                  },
                );
              },
            );
          } else if (value == 'report') {
            ReportContentBottomSheet.show(
              context: context,
              contentId: widget.comment.id?.toString() ?? '0',
              contentType: 'comment',
              contentOwnerName: commentDisplayName(
                firstName: widget.comment.commenter?.firstName,
                lastName: widget.comment.commenter?.lastName,
              ),
            );
          } else if (value == 'block') {
            final userId = widget.comment.commenter?.id ?? '';
            if ('$userId'.isNotEmpty) {
              BlockUserDialog.show(
                context: context,
                userId: '$userId',
                userName: commentDisplayName(
                  firstName: widget.comment.commenter?.firstName,
                  lastName: widget.comment.commenter?.lastName,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditCommentDialog(BuildContext context, OneUITheme theme) {
    final controller =
        TextEditingController(text: widget.comment.comment ?? '');
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.cardBackground,
          title: Text(
            translation(context).lbl_edit,
            style: TextStyle(fontFamily: 'Poppins', color: theme.textPrimary),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            minLines: 1,
            decoration: InputDecoration(
              hintText: translation(context).lbl_write_a_comment,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            style: TextStyle(fontFamily: 'Poppins', color: theme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(translation(context).lbl_cancel),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  widget.commentBloc.add(UpdateMainCommentEvent(
                    commentId: widget.comment.id.toString(),
                    content: value,
                  ));
                  setState(() {
                    widget.comment.comment = value;
                  });
                }
                Navigator.pop(dialogContext);
              },
              child: Text(translation(context).lbl_update),
            ),
          ],
        );
      },
    );
  }
}
