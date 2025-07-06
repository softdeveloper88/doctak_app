import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with author info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: discussion.author.profilePic != null
                        ? CachedNetworkImageProvider("${AppData.imageUrl}${discussion.author.profilePic!}")
                        : null,
                    child: discussion.author.profilePic == null
                        ? Text(discussion.author.name.isNotEmpty
                            ? discussion.author.name[0].toUpperCase()
                            : '?')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discussion.author.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          discussion.author.specialty.isNotEmpty
                              ? discussion.author.specialty
                              : 'Medical Professional',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Specialty badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getSpecialtyColor(discussion.author.specialty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getSpecialtyColor(discussion.author.specialty)
                            .withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      discussion.author.specialty.isNotEmpty
                          ? discussion.author.specialty.toUpperCase()
                          : 'GENERAL',
                      style: TextStyle(
                        color: _getSpecialtyColor(discussion.author.specialty),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Delete button - only show if current user is the author
                  if (_isCurrentUserAuthor() && onDelete != null) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(context);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        if (onEdit != null)
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue[600], size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Edit',
                                  style: TextStyle(color: Colors.blue[600]),
                                ),
                              ],
                            ),
                          ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red[600], size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                discussion.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description preview (using title as description for list view)
              Text(
                discussion.title.length > 100 
                    ? '${discussion.title.substring(0, 100)}...'
                    : discussion.title,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Tags/Symptoms if available
              if (discussion.parsedTags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: discussion.parsedTags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (discussion.parsedTags.length > 3)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    child: Text(
                      '+${discussion.parsedTags.length - 3} more tags',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],

              // Footer with stats and actions
              Row(
                children: [
                  // Stats
                  _buildStat(Icons.thumb_up_outlined, discussion.stats.likes),
                  const SizedBox(width: 16),
                  _buildStat(Icons.comment_outlined, discussion.stats.commentsCount),
                  const SizedBox(width: 16),
                  _buildStat(Icons.visibility_outlined, discussion.stats.views),

                  const Spacer(),

                  // Time
                  Text(
                    _formatTime(discussion.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getSpecialtyColor(String specialty) {
    switch (specialty.toLowerCase()) {
      case 'cardiology':
        return Colors.red;
      case 'neurology':
        return Colors.purple;
      case 'orthopedics':
        return Colors.blue;
      case 'pediatrics':
        return Colors.green;
      default:
        return Colors.grey;
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
    // Check if the current user is the author of this discussion
    // Compare the author ID with the current user's ID
    return discussion.author.name.toString() == AppData.name.toString();
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Discussion'),
          content: const Text(
            'Are you sure you want to delete this case discussion? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete?.call();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
