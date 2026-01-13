import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import '../models/case_discussion_models.dart';

class CommentCard extends StatelessWidget {
  final CaseComment comment;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  const CommentCard({
    Key? key,
    required this.comment,
    required this.onLike,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: theme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with enhanced styling
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.avatarBorder,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.avatarBackground,
                  backgroundImage: comment.author.profilePic != null
                      ? NetworkImage(comment.author.profilePic!)
                      : null,
                  child: comment.author.profilePic == null
                      ? Text(
                          comment.author.name.isNotEmpty
                              ? comment.author.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (comment.author.specialty.isNotEmpty)
                      Text(
                        comment.author.specialty,
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: theme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(comment.createdAt),
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.moreButtonBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  color: theme.cardBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: theme.iconColor,
                    size: 18,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: theme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: theme.error,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Comment text with enhanced styling
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.border,
              ),
            ),
            child: Text(
              comment.comment,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                color: theme.textPrimary,
                height: 1.5,
              ),
            ),
          ),

          // Clinical tags with improved design
          if (comment.clinicalTags != null && comment.clinicalTags!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: comment.clinicalTags!.split(',').map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        size: 12,
                        color: theme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tag.trim(),
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Actions with enhanced styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: theme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onLike,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: comment.isLiked == true
                          ? theme.likeColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: comment.isLiked == true
                            ? theme.likeColor.withOpacity(0.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          comment.isLiked == true
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_outlined,
                          size: 16,
                          color: comment.isLiked == true
                              ? theme.likeColor
                              : theme.iconColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          comment.likes.toString(),
                          style: TextStyle(
                            color: comment.isLiked == true
                                ? theme.likeColor
                                : theme.textSecondary,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_down_outlined,
                        size: 16,
                        color: theme.iconColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        comment.dislikes.toString(),
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (comment.repliesCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: theme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${comment.repliesCount} replies',
                          style: TextStyle(
                            color: theme.primary,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}