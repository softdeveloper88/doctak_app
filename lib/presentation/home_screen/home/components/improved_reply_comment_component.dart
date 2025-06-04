import 'package:doctak_app/data/models/post_comment_model/reply_comment_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../../../core/utils/app/AppData.dart';

class ImprovedReplyCommentComponent extends StatelessWidget {
  final CommentsModel replyComment;
  final Function? onDelete;
  final Function? onEdit;

  const ImprovedReplyCommentComponent({
    required this.replyComment,
    this.onDelete,
    this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          _buildAvatar(context),
          
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with username and actions
                _buildHeader(context),
                
                // Comment text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                    replyComment.comment ?? translation(context).lbl_no_name,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                
                // Timestamp
                Text(
                  timeAgo.format(DateTime.parse(replyComment.createdAt!)),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build avatar widget
  Widget _buildAvatar(BuildContext context) {
    return InkWell(
      onTap: () {
        SVProfileFragment(userId: replyComment.commenterId ?? '')
            .launch(context);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: replyComment.commenter?.profilePic != null &&
                replyComment.commenter!.profilePic!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  replyComment.commenter?.profilePic ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Text(
                        (replyComment.commenter?.name ?? '')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    );
                  },
                ),
              )
            : Center(
                child: Text(
                  (replyComment.commenter?.name ?? '')[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
      ),
    );
  }

  // Build header with username and actions
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Username with verification
        Expanded(
          child: InkWell(
            onTap: () {
              SVProfileFragment(userId: replyComment.commenterId ?? "")
                  .launch(context);
            },
            child: Row(
              children: [
                Text(
                  replyComment.commenter?.name ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.blue[800],
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  'images/socialv/icons/ic_TickSquare.png',
                  height: 12,
                  width: 12,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
        ),
        
        // Actions menu (only for own replies)
        if (replyComment.commenterId == AppData.logInUserId)
          PopupMenuButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey[600],
              size: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) {
              return [
                // Edit option
                PopupMenuItem(
                  value: "Update",
                  height: 40,
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        translation(context).lbl_update,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete option
                PopupMenuItem(
                  value: "Delete",
                  height: 40,
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Colors.red[400],
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
              if (value == 'Delete') {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CustomAlertDialog(
                      title: translation(context).msg_confirm_delete_comment,
                      callback: () {
                        onDelete?.call();
                        Navigator.of(context).pop();
                      },
                    );
                  },
                );
              } else if (value == 'Update') {
                onEdit?.call();
              }
            },
          ),
      ],
    );
  }
}