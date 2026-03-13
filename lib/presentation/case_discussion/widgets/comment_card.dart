import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/case_discussion_models.dart';

/// Clinical tag types used on the website for case discussion comments.
enum ClinicalTag {
  diagnosis('Diagnosis', Icons.local_hospital, Color(0xFF2196F3)),
  treatment('Treatment', Icons.healing, Color(0xFF4CAF50)),
  prognosis('Prognosis', Icons.trending_up, Color(0xFFFF9800)),
  workup('Workup', Icons.science, Color(0xFF9C27B0)),
  complication('Complication', Icons.warning_amber, Color(0xFFF44336)),
  differential('Differential', Icons.compare_arrows, Color(0xFF607D8B));

  final String label;
  final IconData icon;
  final Color color;
  const ClinicalTag(this.label, this.icon, this.color);

  static ClinicalTag? fromString(String name) {
    try {
      return ClinicalTag.values.firstWhere(
        (t) => t.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Card widget for a single comment in the case discussion.
/// Supports clinical tag badges, like action, replies, and a reply input.
class CommentCard extends StatefulWidget {
  final CaseComment comment;
  final VoidCallback onLike;
  final VoidCallback onDelete;
  final Function(String text) onReply;
  final Function(int commentId)? onLoadReplies;
  final bool isOwner;

  const CommentCard({
    super.key,
    required this.comment,
    required this.onLike,
    required this.onDelete,
    required this.onReply,
    this.onLoadReplies,
    this.isOwner = false,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _showReplies = false;
  bool _showReplyInput = false;
  final _replyController = TextEditingController();
  final _replyFocusNode = FocusNode();

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final clinicalTags = widget.comment.parsedClinicalTags;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(
          bottom: BorderSide(color: theme.divider, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Author Row ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommentAvatar(
                name: widget.comment.author.name,
                imageUrl: widget.comment.author.profilePic,
                theme: theme,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + time
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.comment.author.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              color: theme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeago.format(widget.comment.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Poppins',
                            color: theme.textTertiary,
                          ),
                        ),
                      ],
                    ),

                    // Clinical Tags
                    if (clinicalTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: clinicalTags.map((tagName) {
                            final tag = ClinicalTag.fromString(tagName);
                            return _ClinicalTagBadge(
                              tag: tag,
                              tagName: tagName,
                            );
                          }).toList(),
                        ),
                      ),

                    // Comment Text
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        widget.comment.comment,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Action Row
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        children: [
                          // Like
                          InkWell(
                            onTap: widget.onLike,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.comment.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 15,
                                    color: widget.comment.isLiked
                                        ? theme.likeColor
                                        : theme.textTertiary,
                                  ),
                                  if (widget.comment.likes > 0) ...[
                                    const SizedBox(width: 3),
                                    Text(
                                      '${widget.comment.likes}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                        color: widget.comment.isLiked
                                            ? theme.likeColor
                                            : theme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Reply
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showReplyInput = !_showReplyInput;
                              });
                              if (_showReplyInput) {
                                Future.delayed(
                                    const Duration(milliseconds: 100), () {
                                  _replyFocusNode.requestFocus();
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Text(
                                'Reply',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTertiary,
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Delete (owner only)
                          if (widget.isOwner ||
                              widget.comment.isOwner == true)
                            InkWell(
                              onTap: () => _confirmDelete(context, theme),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 15,
                                  color: theme.textTertiary,
                                ),
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

          // ── Replies Section ──
          if (widget.comment.repliesCount > 0 && !_showReplies)
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 6),
              child: InkWell(
                onTap: () {
                  setState(() => _showReplies = true);
                  widget.onLoadReplies?.call(widget.comment.id);
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'View ${widget.comment.repliesCount} ${widget.comment.repliesCount == 1 ? 'reply' : 'replies'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                    ),
                  ),
                ),
              ),
            ),

          // Expanded replies
          if (_showReplies && widget.comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 4),
              child: Column(
                children: widget.comment.replies.map((reply) {
                  return _ReplyCard(reply: reply, theme: theme);
                }).toList(),
              ),
            ),

          // ── Reply Input ──
          if (_showReplyInput)
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.inputBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.border),
                      ),
                      child: TextField(
                        controller: _replyController,
                        focusNode: _replyFocusNode,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write a reply...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            color: theme.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          isDense: true,
                        ),
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _submitReply,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _submitReply(_replyController.text),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _submitReply(String text) {
    if (text.trim().isEmpty) return;
    widget.onReply(text.trim());
    _replyController.clear();
    setState(() {
      _showReplyInput = false;
      _showReplies = true;
    });
  }

  void _confirmDelete(BuildContext context, OneUITheme theme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Comment'),
        content:
            const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Reply Card ──

class _ReplyCard extends StatelessWidget {
  final CaseReply reply;
  final OneUITheme theme;

  const _ReplyCard({required this.reply, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentAvatar(
            name: reply.author.name,
            imageUrl: reply.author.profilePic,
            theme: theme,
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        reply.author.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          color: theme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeago.format(reply.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        color: theme.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  reply.reply,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: theme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comment Avatar ──

class _CommentAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final OneUITheme theme;
  final double size;

  const _CommentAvatar({
    required this.name,
    required this.imageUrl,
    required this.theme,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.avatarBackground,
        border: Border.all(color: theme.avatarBorder, width: 0.5),
      ),
      child: hasImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w600,
                      color: theme.avatarText,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w600,
                  color: theme.avatarText,
                ),
              ),
            ),
    );
  }
}

// ── Clinical Tag Badge ──

class _ClinicalTagBadge extends StatelessWidget {
  final ClinicalTag? tag;
  final String tagName;

  const _ClinicalTagBadge({
    required this.tag,
    required this.tagName,
  });

  @override
  Widget build(BuildContext context) {
    final color = tag?.color ?? Colors.grey;
    final icon = tag?.icon ?? Icons.label_outline;
    final label = tag?.label ?? tagName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
