import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import '../models/case_discussion_models.dart';

class DiscussionCard extends StatelessWidget {
  final CaseDiscussionListItem discussion;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const DiscussionCard({
    Key? key,
    required this.discussion,
    required this.onTap,
    required this.onLike,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: theme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with author info - One UI style
                Row(
                  children: [
                    // Avatar with gradient border
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.primary,
                            theme.primary.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.cardBackground,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.avatarBackground,
                          backgroundImage: discussion.author.profilePic != null
                              ? CachedNetworkImageProvider("${AppData.imageUrl}${discussion.author.profilePic!}")
                              : null,
                          child: discussion.author.profilePic == null
                              ? Text(
                                  discussion.author.name.isNotEmpty
                                      ? discussion.author.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: theme.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    fontFamily: 'Poppins',
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            discussion.author.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: theme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            discussion.author.specialty.isNotEmpty
                                ? discussion.author.specialty
                                : 'Medical Professional',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Specialty badge - One UI pill style
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getSpecialtyColor(discussion.author.specialty, theme),
                            _getSpecialtyColor(discussion.author.specialty, theme).withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        discussion.author.specialty.isNotEmpty
                            ? discussion.author.specialty.toUpperCase()
                            : 'GENERAL',
                        style: TextStyle(
                          color: theme.cardBackground,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // More menu for author
                    if (_isCurrentUserAuthor() && onDelete != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_horiz_rounded,
                            color: theme.textSecondary,
                            size: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: theme.cardBackground,
                          elevation: 8,
                          onSelected: (value) {
                            if (value == 'edit' && onEdit != null) {
                              onEdit!();
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, theme);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            if (onEdit != null)
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, color: theme.primary, size: 18),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Edit',
                                      style: TextStyle(
                                        color: theme.textPrimary,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: theme.error, size: 18),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: theme.error,
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
                  ],
                ),
                
                const SizedBox(height: 16),

                // Title - prominent and clean
                Text(
                  discussion.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: theme.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Description preview
                Text(
                  discussion.title.length > 100
                      ? '${discussion.title.substring(0, 100)}...'
                      : discussion.title,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Tags/Symptoms - One UI chip style
                if (discussion.parsedTags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: discussion.parsedTags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: theme.warning,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (discussion.parsedTags.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+${discussion.parsedTags.length - 3} more',
                        style: TextStyle(
                          color: theme.textTertiary,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 16),
                
                // Divider
                Container(
                  height: 1,
                  color: theme.divider,
                ),
                
                const SizedBox(height: 12),

                // Footer with stats - One UI style
                Row(
                  children: [
                    _buildStatChip(Icons.thumb_up_rounded, discussion.stats.likes, theme, iconColor: theme.primary),
                    const SizedBox(width: 10),
                    _buildStatChip(Icons.chat_bubble_rounded, discussion.stats.commentsCount, theme, iconColor: theme.success),
                    const SizedBox(width: 10),
                    _buildStatChip(Icons.visibility_rounded, discussion.stats.views, theme, iconColor: theme.secondary),
                    const Spacer(),
                    // Time with icon - One UI style container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: theme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(discussion.createdAt),
                            style: TextStyle(
                              color: theme.textTertiary,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, int count, OneUITheme theme, {Color? iconColor}) {
    final color = iconColor ?? theme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            _formatCount(count),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  Color _getSpecialtyColor(String specialty, OneUITheme theme) {
    switch (specialty.toLowerCase()) {
      case 'cardiology':
        return theme.error;
      case 'neurology':
        return const Color(0xFF9C27B0);
      case 'orthopedics':
        return theme.primary;
      case 'pediatrics':
        return theme.success;
      default:
        return theme.warning;
    }
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

  bool _isCurrentUserAuthor() {
    return discussion.author.name.toString() == AppData.name.toString();
  }

  void _showDeleteConfirmation(BuildContext context, OneUITheme theme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Discussion',
            style: TextStyle(
              color: theme.textPrimary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this case discussion? This action cannot be undone.',
            style: TextStyle(
              color: theme.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete?.call();
              },
              style: TextButton.styleFrom(foregroundColor: theme.error),
              child: Text(
                'Delete',
                style: TextStyle(
                  color: theme.error,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
