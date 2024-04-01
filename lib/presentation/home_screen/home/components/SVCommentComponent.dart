import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class SVCommentComponent extends StatefulWidget {
  final PostComments comment;

  SVCommentComponent({required this.comment});

  @override
  State<SVCommentComponent> createState() => _SVCommentComponentState();
}

class _SVCommentComponentState extends State<SVCommentComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), // Added top margin
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align items from top
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage('${AppData.imageUrl}${widget.comment.profilePic}'),
              ),
              const SizedBox(width: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.comment.name ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4), // Added margin between name and verified icon
                  const Icon(Icons.verified, color: Colors.blue, size: 18),
                ],
              ),
              const Spacer(),
              Text(
                timeAgo.format(DateTime.parse(widget.comment.createdAt!)),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.comment.comment ?? '',
            style: TextStyle(color: Colors.grey[800], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
