import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:flutter/material.dart';
import '../models/case_discussion_models.dart';

class DiscussionCard extends StatelessWidget {
  final CaseDiscussion discussion;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const DiscussionCard({
    Key? key,
    required this.discussion,
    required this.onTap,
    required this.onLike,
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
                      color: _getSpecialtyColor(discussion.specialty).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getSpecialtyColor(discussion.specialty)
                            .withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      discussion.specialty.isNotEmpty
                          ? discussion.specialty.toUpperCase()
                          : 'GENERAL',
                      style: TextStyle(
                        color: _getSpecialtyColor(discussion.specialty),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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

              // Description preview
              Text(
                discussion.description,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Patient info if available
              if (discussion.patientInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${discussion.patientInfo!.gender.toUpperCase()}, ${discussion.patientInfo!.age} years',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Symptoms if available
              if (discussion.symptoms != null && discussion.symptoms!.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: discussion.symptoms!.take(3).map((symptom) {
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
                        symptom,
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (discussion.symptoms!.length > 3)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    child: Text(
                      '+${discussion.symptoms!.length - 3} more symptoms',
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
}
