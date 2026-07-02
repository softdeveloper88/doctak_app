import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/case_discussion_models.dart';
import 'case_display_utils.dart';
import 'vote_controls.dart';

/// Card widget for a single comment in the case discussion.
/// Supports clinical tag badges, like action, replies, and a reply input.
class CommentCard extends StatefulWidget {
  final CaseComment comment;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;
  final VoidCallback onDelete;
  final Function(String text)? onUpdateComment;
  final Function(String text) onReply;
  final Function(int commentId)? onLoadReplies;
  final void Function(int replyId, String direction)? onVoteReply;
  final void Function(int replyId)? onDeleteReply;
  final void Function(int replyId, String text)? onUpdateReply;
  final bool isOwner;
  final bool showDivider;

  const CommentCard({
    super.key,
    required this.comment,
    required this.onUpvote,
    required this.onDownvote,
    required this.onDelete,
    this.onUpdateComment,
    required this.onReply,
    this.onLoadReplies,
    this.onVoteReply,
    this.onDeleteReply,
    this.onUpdateReply,
    this.isOwner = false,
    this.showDivider = true,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _showReplies = false;
  bool _showReplyInput = false;
  bool _editingComment = false;
  final _replyController = TextEditingController();
  final _editCommentController = TextEditingController();
  final _replyFocusNode = FocusNode();

  bool get _canManageComment =>
      widget.isOwner || widget.comment.isOwner == true;

  @override
  void dispose() {
    _replyController.dispose();
    _editCommentController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final author = widget.comment.author;
    final metaParts = <String>[];
    final specialty = specialtyLabelOrNull(author.specialty);
    if (specialty != null) metaParts.add(specialty);
    metaParts.add(timeago.format(widget.comment.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CommentAvatar(
                      name: author.name,
                      imageUrl: author.profilePic,
                      theme: theme,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  author.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                    color: theme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (author.isVerified)
                                theme.buildVerifiedBadge(size: 14),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            metaParts.join(' · '),
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Poppins',
                              color: theme.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (_canManageComment)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        icon: Icon(Icons.more_horiz,
                            size: 20, color: theme.textTertiary),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _startEditComment();
                          } else if (value == 'delete') {
                            _confirmDelete(context, theme);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outlined,
                                    size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_editingComment)
                        _buildEditField(
                          theme: theme,
                          controller: _editCommentController,
                          onCancel: _cancelEditComment,
                          onSave: _saveEditComment,
                        )
                      else
                        Text(
                          widget.comment.comment,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            color: theme.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          VoteControls(
                            layout: VoteLayout.row,
                            iconSize: 16,
                            likes: widget.comment.likes,
                            dislikes: widget.comment.dislikes,
                            isUpvoted: widget.comment.isLiked,
                            isDownvoted: widget.comment.isDisliked,
                            onUpvote: widget.onUpvote,
                            onDownvote: widget.onDownvote,
                          ),
                          const SizedBox(width: 14),
                          InkWell(
                            onTap: () {
                              if (widget.comment.repliesCount > 0) {
                                final show = !_showReplies;
                                setState(() {
                                  _showReplies = show;
                                  if (show) _showReplyInput = false;
                                });
                                if (show) {
                                  widget.onLoadReplies?.call(widget.comment.id);
                                }
                              } else {
                                setState(() => _showReplyInput = !_showReplyInput);
                                if (_showReplyInput) {
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    _replyFocusNode.requestFocus();
                                  });
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline,
                                      size: 15, color: theme.textTertiary),
                                  const SizedBox(width: 5),
                                  Text(
                                    widget.comment.repliesCount > 0
                                        ? 'Reply (${widget.comment.repliesCount})'
                                        : 'Reply',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_showReplies && widget.comment.replies.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            children: widget.comment.replies.map((reply) {
                              return _ReplyCard(
                                reply: reply,
                                theme: theme,
                                onUpvote: widget.onVoteReply == null
                                    ? null
                                    : () => widget.onVoteReply!(reply.id, 'up'),
                                onDownvote: widget.onVoteReply == null
                                    ? null
                                    : () =>
                                        widget.onVoteReply!(reply.id, 'down'),
                                onDelete: reply.isOwner &&
                                        widget.onDeleteReply != null
                                    ? () => _confirmDeleteReply(
                                        context, theme, reply.id)
                                    : null,
                                onUpdate: reply.isOwner &&
                                        widget.onUpdateReply != null
                                    ? (text) =>
                                        widget.onUpdateReply!(reply.id, text)
                                    : null,
                              );
                            }).toList(),
                          ),
                        ),
                      if (_showReplyInput ||
                          (_showReplies && widget.comment.repliesCount > 0))
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.inputBackground,
                                    borderRadius: BorderRadius.circular(20),
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
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
                ),
            ],
          ),
        ),
        if (widget.showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
            color: theme.divider.withValues(alpha: 0.12),
          ),
      ],
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

  void _startEditComment() {
    _editCommentController.text = widget.comment.comment;
    setState(() => _editingComment = true);
  }

  void _cancelEditComment() {
    _editCommentController.clear();
    setState(() => _editingComment = false);
  }

  void _saveEditComment() {
    final text = _editCommentController.text.trim();
    if (text.isEmpty || widget.onUpdateComment == null) return;
    widget.onUpdateComment!(text);
    _cancelEditComment();
  }

  Widget _buildEditField({
    required OneUITheme theme,
    required TextEditingController controller,
    required VoidCallback onCancel,
    required VoidCallback onSave,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.inputBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            maxLines: 4,
            minLines: 2,
            autofocus: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: onSave,
              child: Text('Save', style: TextStyle(color: theme.primary)),
            ),
            TextButton(
              onPressed: onCancel,
              child: Text('Cancel',
                  style: TextStyle(color: theme.textSecondary)),
            ),
          ],
        ),
      ],
    );
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

  void _confirmDeleteReply(BuildContext context, OneUITheme theme, int replyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleteReply?.call(replyId);
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

class _ReplyCard extends StatefulWidget {
  final CaseReply reply;
  final OneUITheme theme;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;
  final VoidCallback? onDelete;
  final void Function(String text)? onUpdate;

  const _ReplyCard({
    required this.reply,
    required this.theme,
    this.onUpvote,
    this.onDownvote,
    this.onDelete,
    this.onUpdate,
  });

  @override
  State<_ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends State<_ReplyCard> {
  bool _editing = false;
  late final TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.reply.reply);
  }

  @override
  void didUpdateWidget(covariant _ReplyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.reply.reply != widget.reply.reply) {
      _editController.text = widget.reply.reply;
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  bool get _canManage => widget.onDelete != null || widget.onUpdate != null;

  void _startEdit() {
    _editController.text = widget.reply.reply;
    setState(() => _editing = true);
  }

  void _cancelEdit() {
    _editController.text = widget.reply.reply;
    setState(() => _editing = false);
  }

  void _saveEdit() {
    final text = _editController.text.trim();
    if (text.isEmpty || widget.onUpdate == null) return;
    widget.onUpdate!(text);
    setState(() => _editing = false);
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reply'),
        content: const Text('Are you sure you want to delete this reply?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: widget.theme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete?.call();
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reply = widget.reply;
    final theme = widget.theme;
    final metaParts = <String>[];
    final specialty = specialtyLabelOrNull(reply.author.specialty);
    if (specialty != null) metaParts.add(specialty);
    metaParts.add(timeago.format(reply.createdAt));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              margin: const EdgeInsets.only(left: 18, right: 12),
              decoration: BoxDecoration(
                color: theme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CommentAvatar(
                        name: reply.author.name,
                        imageUrl: reply.author.profilePic,
                        theme: theme,
                        size: 30,
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      color: theme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (reply.author.isVerified)
                                  theme.buildVerifiedBadge(size: 13),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              metaParts.join(' · '),
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                color: theme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_canManage)
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: Icon(Icons.more_horiz,
                              size: 18, color: theme.textTertiary),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _startEdit();
                            } else if (value == 'delete') {
                              _confirmDelete(context);
                            }
                          },
                          itemBuilder: (_) => [
                            if (widget.onUpdate != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 14),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                            if (widget.onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outlined,
                                        size: 14, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_editing)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: theme.inputBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _editController,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              color: theme.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                            maxLines: 3,
                            minLines: 2,
                            autofocus: true,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _saveEdit,
                              child: Text('Save',
                                  style: TextStyle(color: theme.primary)),
                            ),
                            TextButton(
                              onPressed: _cancelEdit,
                              child: Text('Cancel',
                                  style:
                                      TextStyle(color: theme.textSecondary)),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Text(
                      reply.reply,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        color: theme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  if (widget.onUpvote != null && widget.onDownvote != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: VoteControls(
                        layout: VoteLayout.row,
                        iconSize: 14,
                        likes: reply.likes,
                        dislikes: reply.dislikes,
                        isUpvoted: reply.isLiked,
                        isDownvoted: reply.isDisliked,
                        onUpvote: widget.onUpvote!,
                        onDownvote: widget.onDownvote!,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
    final initials = authorInitials(name);
    final color = avatarColorFromName(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
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
                      fontWeight: FontWeight.w700,
                      color: color,
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
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
    );
  }
}
