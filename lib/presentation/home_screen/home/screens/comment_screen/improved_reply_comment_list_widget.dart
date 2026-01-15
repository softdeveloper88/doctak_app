import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../widgets/retry_widget.dart';
import '../../components/improved_reply_comment_component.dart';
import 'bloc/comment_bloc.dart';

class ImprovedReplyCommentListWidget extends StatefulWidget {
  final CommentBloc commentBloc;
  final int postId;
  final int commentId;

  const ImprovedReplyCommentListWidget({required this.commentBloc, required this.postId, required this.commentId, super.key});

  @override
  State<ImprovedReplyCommentListWidget> createState() => _ImprovedReplyCommentListWidgetState();
}

class _ImprovedReplyCommentListWidgetState extends State<ImprovedReplyCommentListWidget> {
  final CommentBloc commentBloc = CommentBloc();
  int selectComment = -1;

  @override
  void initState() {
    commentBloc.add(FetchReplyComment(postId: widget.postId.toString(), commentId: widget.commentId.toString()));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title for replies section
          Container(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Row(
              children: [
                Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: theme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  translation(context).lbl_reply,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: theme.textSecondary, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),

          // Reply list area
          BlocConsumer<CommentBloc, CommentState>(
            bloc: commentBloc,
            listener: (BuildContext context, CommentState state) {
              if (state is DataError) {
                // Error handling if needed
              }
            },
            builder: (context, state) {
              if (state is PaginationLoadingState) {
                return Container(
                  height: 150,
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator(color: theme.primary)),
                );
              } else if (state is PaginationLoadedState) {
                if (commentBloc.replyCommentList.isNotEmpty) {
                  return _buildReplyList(theme);
                } else {
                  return const SizedBox.shrink();
                }
              } else if (state is DataError) {
                return RetryWidget(
                  errorMessage: translation(context).msg_something_went_wrong_retry,
                  onRetry: () {
                    try {
                      commentBloc.add(FetchReplyComment(commentId: widget.commentId.toString(), postId: widget.postId.toString()));
                    } catch (e) {
                      debugPrint(e.toString());
                    }
                  },
                );
              }
              return Container();
            },
          ),

          // Reply input component with minimal spacing
          if (selectComment == -1)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ImprovedReplyInputField(commentBloc: commentBloc, commentId: widget.commentId, postId: widget.postId),
            ),
        ],
      ),
    );
  }

  // Build the list of replies
  Widget _buildReplyList(OneUITheme theme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: commentBloc.replyCommentList.length,
      itemBuilder: (context, index) {
        if (selectComment != index) {
          return ImprovedReplyCommentComponent(
            replyComment: commentBloc.replyCommentList[index],
            onDelete: () {
              commentBloc.add(DeleteReplyCommentEvent(commentId: commentBloc.replyCommentList[index].id.toString()));
            },
            onEdit: () {
              setState(() {
                selectComment = index;
              });
            },
          );
        } else {
          // Edit reply UI
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primary.withValues(alpha: 0.1)),
            ),
            // Using LayoutBuilder to get available width constraints
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Take only as much space as needed
                  children: [
                    Text(
                      translation(context).lbl_update,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primary),
                    ),
                    const SizedBox(height: 8),
                    // Custom input field for updating comment to prevent overflow
                    // Pass available width constraint to ensure it doesn't overflow
                    SizedBox(
                      width: constraints.maxWidth, // Use available width
                      child: CustomReplyUpdateField(
                        initialValue: commentBloc.replyCommentList[selectComment].comment ?? '',
                        onSubmit: (value) {
                          if (value.isNotEmpty) {
                            commentBloc.add(UpdateReplyCommentEvent(commentId: commentBloc.replyCommentList[selectComment].id.toString(), content: value));
                            selectComment = -1;
                            setState(() {});
                          }
                        },
                        onCancel: () {
                          selectComment = -1;
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }
      },
    );
  }
}

/// Improved Reply Input Component
class ImprovedReplyInputField extends StatefulWidget {
  final CommentBloc commentBloc;
  final int commentId;
  final int postId;

  const ImprovedReplyInputField({required this.commentBloc, required this.commentId, required this.postId, super.key});

  @override
  State<ImprovedReplyInputField> createState() => _ImprovedReplyInputFieldState();
}

class _ImprovedReplyInputFieldState extends State<ImprovedReplyInputField> {
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.border, width: 1),
        boxShadow: theme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Align items to bottom for multi-line input
        children: [
          // User Avatar (small)
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.primary.withValues(alpha: 0.08),
            child: Icon(Icons.person_rounded, size: 20, color: theme.primary),
          ),

          const SizedBox(width: 14),

          // Text Field with constraints to prevent overflow
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 100, // Maximum height for input field
              ),
              child: TextField(
                controller: _replyController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: translation(context).lbl_write_a_comment,
                  hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: theme.textTertiary, fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: TextStyle(fontFamily: 'Poppins', fontSize: 15, color: theme.textPrimary, fontWeight: FontWeight.w400),
                // Allow text to wrap to new lines, but limit with ConstrainedBox
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                onSubmitted: _submitReply,
              ),
            ),
          ),

          // Send Button
          Container(
            margin: const EdgeInsets.only(bottom: 2.0),
            child: IconButton(
              onPressed: () => _submitReply(_replyController.text),
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              style: IconButton.styleFrom(backgroundColor: theme.primary, padding: const EdgeInsets.all(10), shape: const CircleBorder()),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            ),
          ),
        ],
      ),
    );
  }

  void _submitReply(String value) {
    if (value.isNotEmpty) {
      // If commentId is 0, we're posting a main comment, not a reply
      if (widget.commentId == 0) {
        widget.commentBloc.add(PostCommentEvent(postId: widget.postId, comment: value));
      } else {
        // Otherwise we're replying to a specific comment
        widget.commentBloc.add(ReplyComment(commentId: widget.commentId.toString(), postId: widget.postId.toString(), commentText: value));
      }
      _replyController.clear();
      _focusNode.unfocus();
    }
  }
}

/// Custom widget for updating reply comments without overflow issues
class CustomReplyUpdateField extends StatefulWidget {
  final String initialValue;
  final Function(String) onSubmit;
  final Function onCancel;

  const CustomReplyUpdateField({required this.initialValue, required this.onSubmit, required this.onCancel, super.key});

  @override
  State<CustomReplyUpdateField> createState() => _CustomReplyUpdateFieldState();
}

class _CustomReplyUpdateFieldState extends State<CustomReplyUpdateField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();

    // Automatically focus the field when the widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Text field with container to prevent overflow
        Container(
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border),
          ),
          // Use ConstrainedBox to prevent TextField from expanding too much
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 120, // Maximum height constraint
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null, // Allow dynamic number of lines
              keyboardType: TextInputType.multiline, // Enable multiline input
              textCapitalization: TextCapitalization.sentences, // Start with capital letter
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(12),
                hintText: translation(context).lbl_write_a_comment,
                border: InputBorder.none,
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textTertiary),
                // Make sure there's no excess padding causing overflow
                isDense: true,
              ),
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min, // Take only as much space as needed
            children: [
              // Cancel button
              TextButton(
                onPressed: () => widget.onCancel(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  translation(context).lbl_cancel,
                  style: TextStyle(color: theme.textSecondary, fontSize: 14, fontFamily: 'Poppins'),
                ),
              ),

              // Update button
              TextButton(
                onPressed: () => widget.onSubmit(_controller.text),
                style: TextButton.styleFrom(
                  backgroundColor: theme.primary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  translation(context).lbl_update,
                  style: TextStyle(color: theme.primary, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
