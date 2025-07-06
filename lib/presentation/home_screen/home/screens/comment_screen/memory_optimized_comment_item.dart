import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/bloc/comment_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/improved_reply_comment_list_widget.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
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

  const MemoryOptimizedCommentItem({
    super.key,
    required this.comment,
    required this.commentBloc,
    required this.postId,
    this.selectedCommentId,
    required this.onReplySelected,
  });

  @override
  State<MemoryOptimizedCommentItem> createState() =>
      _MemoryOptimizedCommentItemState();
}

class _MemoryOptimizedCommentItemState
    extends State<MemoryOptimizedCommentItem> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildCommentContent()],
        ),
      ),
    );
  }

  Widget _buildCommentContent() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          _buildAvatarSection(),

          const SizedBox(width: 12),

          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info and Actions Row
                _buildUserInfoRow(),

                const SizedBox(height: 8),

                // Comment Text
                Text(
                  widget.comment.comment ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.normal,
                  ),
                ),

                const SizedBox(height: 8),

                // Timestamp
                Text(
                  timeAgo.format(DateTime.parse(widget.comment.createdAt!)),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),

                const SizedBox(height: 8),

                // Actions Row (Reply & Like)
                _buildActionRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return InkWell(
      onTap: () {
        SVProfileFragment(
          userId: widget.comment.commenter?.id ?? '',
        ).launch(context);
      },
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child:
              widget.comment.commenter?.profilePic != null &&
                  widget.comment.commenter!.profilePic!.isNotEmpty
              ? Image.network(
                  widget.comment.commenter?.profilePic ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        (widget.comment.commenter?.firstName ?? '')[0]
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    );
                  },
                )
              : Center(
                  child: Text(
                    (widget.comment.commenter?.firstName ?? '')[0]
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildUserInfoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Username and badge
        Expanded(
          child: InkWell(
            onTap: () {
              SVProfileFragment(
                userId: widget.comment.commenter?.id ?? '',
              ).launch(context);
            },
            child: Row(
              children: [
                Text(
                  '${widget.comment.commenter?.firstName ?? ''} ${widget.comment.commenter?.lastName ?? ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.blue[800],
                    fontFamily: 'Poppins',
                  ),
                ),
                if ((widget.comment.commenter?.firstName ?? '').isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Image.asset(
                    'images/socialv/icons/ic_TickSquare.png',
                    height: 14,
                    width: 14,
                    fit: BoxFit.cover,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Delete menu (only for own comments)
        if (widget.comment.commenter?.id == AppData.logInUserId)
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[700], size: 18),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red[400],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        translation(context).lbl_delete,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            onSelected: (value) {
              if (value == 'delete') {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CustomAlertDialog(
                      title: translation(context).msg_confirm_delete_comment,
                      callback: () {
                        widget.commentBloc.add(
                          DeleteCommentEvent(
                            commentId: widget.comment.id.toString(),
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Reply button
            TextButton.icon(
              onPressed: () {
                widget.onReplySelected(widget.comment.id ?? 0);
              },
              icon: Icon(
                Icons.reply_outlined,
                size: 16,
                color: Colors.grey[700],
              ),
              label: Text(
                '${widget.comment.replyCount} ${translation(context).lbl_reply}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontFamily: 'Poppins',
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),

            const SizedBox(width: 16),

            // Like button
            TextButton.icon(
              onPressed: () {
                widget.commentBloc.add(
                  LikeReplyComment(commentId: widget.comment.id.toString()),
                );

                setState(() {
                  if (!(widget.comment.userHasLiked ?? true)) {
                    widget.comment.reactionCount =
                        (widget.comment.reactionCount ?? 0) + 1;
                    widget.comment.userHasLiked = true;
                  } else {
                    if ((widget.comment.reactionCount ?? 0) > 0) {
                      widget.comment.reactionCount =
                          (widget.comment.reactionCount ?? 0) - 1;
                    }
                    widget.comment.userHasLiked = false;
                  }
                });
              },
              icon: Icon(
                widget.comment.userHasLiked ?? false
                    ? Icons.favorite
                    : Icons.favorite_border_outlined,
                size: 16,
                color: widget.comment.userHasLiked ?? false
                    ? Colors.red[400]
                    : Colors.grey[700],
              ),
              label: Text(
                widget.comment.userHasLiked ?? false
                    ? '${widget.comment.reactionCount} ${translation(context).lbl_liked}'
                    : '${widget.comment.reactionCount} ${translation(context).lbl_like}',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.comment.userHasLiked ?? false
                      ? Colors.red[400]
                      : Colors.grey[700],
                  fontFamily: 'Poppins',
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),

        // Show Reply Comment Section if selected
        if (widget.selectedCommentId == widget.comment.id)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
            ),
            child: ImprovedReplyCommentListWidget(
              commentBloc: widget.commentBloc,
              postId: int.parse(widget.postId),
              commentId: widget.selectedCommentId ?? 0,
            ),
          ),
      ],
    );
  }
}
