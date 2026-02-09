import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/improved_reply_comment_list_widget.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/block_user_dialog.dart';
import 'package:doctak_app/presentation/home_screen/home/components/moderation/report_content_bottom_sheet.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

/// Memory-optimized comment item with performance improvements
class MemoryOptimizedCommentItem extends StatefulWidget {
  final PostComments comment;
  final CommentBloc commentBloc;
  final String postId;
  final int? selectedCommentId;
  final Function(int) onReplySelected;

  const MemoryOptimizedCommentItem({super.key, required this.comment, required this.commentBloc, required this.postId, this.selectedCommentId, required this.onReplySelected});

  @override
  State<MemoryOptimizedCommentItem> createState() => _MemoryOptimizedCommentItemState();
}

class _MemoryOptimizedCommentItemState extends State<MemoryOptimizedCommentItem> {
  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
        decoration: BoxDecoration(color: theme.cardBackground, borderRadius: BorderRadius.circular(14), boxShadow: theme.cardShadow),
        child: _buildCommentContent(theme),
      ),
    );
  }

  Widget _buildCommentContent(OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Avatar, Name, Time, Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Compact Avatar
              _buildCompactAvatar(theme),
              const SizedBox(width: 10),
              // Name and Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              SVProfileFragment(userId: widget.comment.commenter?.id ?? '').launch(context);
                            },
                            child: Text(
                              '${widget.comment.commenter?.firstName ?? ''} ${widget.comment.commenter?.lastName ?? ''}'.trim(),
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: theme.primary, fontFamily: 'Poppins'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if ((widget.comment.commenter?.firstName ?? '').isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Image.asset('images/socialv/icons/ic_TickSquare.png', height: 12, width: 12, fit: BoxFit.cover),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo.format(DateTime.parse(widget.comment.createdAt!)),
                      style: TextStyle(fontSize: 11, color: theme.textTertiary, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
              // Menu for comments (delete for own, report/block for others)
              _buildOptionsMenu(theme),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Comment Text
          Text(
            widget.comment.comment ?? '',
            style: TextStyle(fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.normal, color: theme.textPrimary, height: 1.3),
          ),
          
          const SizedBox(height: 8),
          
          // Actions Row (Reply & Like) - More compact
          _buildCompactActionRow(theme),
        ],
      ),
    );
  }

  Widget _buildCompactAvatar(OneUITheme theme) {
    return GestureDetector(
      onTap: () {
        SVProfileFragment(userId: widget.comment.commenter?.id ?? '').launch(context);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: widget.comment.commenter?.profilePic != null && widget.comment.commenter!.profilePic!.isNotEmpty
              ? Image.network(
                  widget.comment.commenter?.profilePic ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        (widget.comment.commenter?.firstName ?? '')[0].toUpperCase(),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primary),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    (widget.comment.commenter?.firstName ?? '')[0].toUpperCase(),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.primary),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOptionsMenu(OneUITheme theme) {
    final isOwnComment = widget.comment.commenter?.id == AppData.logInUserId;
    
    return SizedBox(
      width: 28,
      height: 28,
      child: PopupMenuButton(
        icon: Icon(Icons.more_vert, color: theme.textSecondary, size: 16),
        padding: EdgeInsets.zero,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) {
          if (isOwnComment) {
            // Show delete option for own comments
            return [
              PopupMenuItem(
                value: 'delete',
                height: 40,
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: theme.error, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      translation(context).lbl_delete,
                      style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: theme.textPrimary),
                    ),
                  ],
                ),
              ),
            ];
          } else {
            // Show report and block options for other users' comments
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
                      style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: theme.warning),
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
                      style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: theme.error),
                    ),
                  ],
                ),
              ),
            ];
          }
        },
        onSelected: (value) {
          if (value == 'delete') {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return CustomAlertDialog(
                  title: translation(context).msg_confirm_delete_comment,
                  callback: () {
                    widget.commentBloc.add(DeleteCommentEvent(commentId: widget.comment.id.toString()));
                    Navigator.of(context).pop();
                  },
                );
              },
            );
          } else if (value == 'report') {
            // Show report bottom sheet
            ReportContentBottomSheet.show(
              context: context,
              contentId: widget.comment.id ?? 0,
              contentType: 'comment',
              contentOwnerName: '${widget.comment.commenter?.firstName ?? ''} ${widget.comment.commenter?.lastName ?? ''}'.trim(),
            );
          } else if (value == 'block') {
            // Show block dialog
            final userId = int.tryParse(widget.comment.commenter?.id ?? '0') ?? 0;
            if (userId > 0) {
              BlockUserDialog.show(
                context: context,
                userId: userId,
                userName: '${widget.comment.commenter?.firstName ?? ''} ${widget.comment.commenter?.lastName ?? ''}'.trim(),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildCompactActionRow(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Reply button - more compact inline style
            InkWell(
              onTap: () => widget.onReplySelected(widget.comment.id ?? 0),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.reply_outlined, size: 14, color: theme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.comment.replyCount} ${translation(context).lbl_reply}',
                      style: TextStyle(fontSize: 12, color: theme.textSecondary, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Like button - more compact inline style
            InkWell(
              onTap: () {
                widget.commentBloc.add(LikeReplyComment(commentId: widget.comment.id.toString()));
                setState(() {
                  if (!(widget.comment.userHasLiked ?? true)) {
                    widget.comment.reactionCount = (widget.comment.reactionCount ?? 0) + 1;
                    widget.comment.userHasLiked = true;
                  } else {
                    if ((widget.comment.reactionCount ?? 0) > 0) {
                      widget.comment.reactionCount = (widget.comment.reactionCount ?? 0) - 1;
                    }
                    widget.comment.userHasLiked = false;
                  }
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.comment.userHasLiked ?? false ? Icons.favorite : Icons.favorite_border_outlined,
                      size: 14,
                      color: widget.comment.userHasLiked ?? false ? theme.likeColor : theme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.comment.userHasLiked ?? false 
                          ? '${widget.comment.reactionCount} ${translation(context).lbl_liked}' 
                          : '${widget.comment.reactionCount} ${translation(context).lbl_like}',
                      style: TextStyle(
                        fontSize: 12, 
                        color: widget.comment.userHasLiked ?? false ? theme.likeColor : theme.textSecondary, 
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Show Reply Comment Section if selected
        if (widget.selectedCommentId == widget.comment.id)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: theme.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border, width: 1),
            ),
            child: ImprovedReplyCommentListWidget(commentBloc: widget.commentBloc, postId: int.parse(widget.postId), commentId: widget.selectedCommentId ?? 0),
          ),
      ],
    );
  }
}
