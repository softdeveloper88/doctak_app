import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_sheet_widgets.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../widgets/retry_widget.dart';
import '../../components/improved_reply_comment_component.dart';
import 'bloc/comment_bloc.dart';

class ImprovedReplyCommentListWidget extends StatefulWidget {
  final CommentBloc commentBloc;
  final int commentId;
  final bool requestReplyFocus;
  final VoidCallback? onReplyFocusHandled;

  const ImprovedReplyCommentListWidget({
    required this.commentBloc,
    required this.commentId,
    this.requestReplyFocus = false,
    this.onReplyFocusHandled,
    super.key,
  });

  @override
  State<ImprovedReplyCommentListWidget> createState() => _ImprovedReplyCommentListWidgetState();
}

class _ImprovedReplyCommentListWidgetState extends State<ImprovedReplyCommentListWidget> {
  int selectComment = -1;

  CommentBloc get commentBloc => widget.commentBloc;

  @override
  void initState() {
    super.initState();
    commentBloc.add(FetchReplyComment(
      commentId: widget.commentId.toString(),
      postId: commentBloc.contentId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reply list area
          BlocConsumer<CommentBloc, CommentState>(
            bloc: commentBloc,
            listener: (BuildContext context, CommentState state) {
              if (state is DataError) {
                // Error handling if needed
              }
            },
            builder: (context, state) {
              if (state is ReplyLoadingState) {
                return Container(
                  height: 48,
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator(color: theme.primary, strokeWidth: 2)),
                );
              } else if (state is ReplyErrorState) {
                return RetryWidget(
                  errorMessage: translation(context).msg_something_went_wrong_retry,
                  onRetry: () {
                    commentBloc.add(FetchReplyComment(
                      commentId: widget.commentId.toString(),
                      postId: commentBloc.contentId,
                      forceRefresh: true,
                    ));
                  },
                );
              } else if (state is ReplyLoadedState || state is PaginationLoadedState) {
                if (commentBloc.replyCommentList.isNotEmpty) {
                  return _buildReplyList(theme);
                } else {
                  return const SizedBox.shrink();
                }
              }
              return const SizedBox.shrink();
            },
          ),

          // Reply input component
          if (selectComment == -1)
            ImprovedReplyInputField(
              commentBloc: commentBloc,
              commentId: widget.commentId,
              postId: int.tryParse(commentBloc.contentId) ?? 0,
              compact: true,
              requestFocus: widget.requestReplyFocus,
              onFocusHandled: widget.onReplyFocusHandled,
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
              commentBloc.add(DeleteReplyCommentEvent(
                commentId: commentBloc.replyCommentList[index].id.toString(),
              ));
            },
            onEdit: () {
              setState(() {
                selectComment = index;
              });
            },
            onLike: () {
              commentBloc.add(
                LikeReplyComment(
                  commentId: commentBloc.replyCommentList[index].id.toString(),
                ),
              );
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
                      style: TextStyle(fontSize: CommentSheetTokens.actionSize, fontWeight: FontWeight.w600, color: theme.primary),
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
  final bool compact;
  final bool requestFocus;
  final VoidCallback? onFocusHandled;

  const ImprovedReplyInputField({
    required this.commentBloc,
    required this.commentId,
    required this.postId,
    this.compact = true,
    this.requestFocus = false,
    this.onFocusHandled,
    super.key,
  });

  @override
  State<ImprovedReplyInputField> createState() => _ImprovedReplyInputFieldState();
}

class _ImprovedReplyInputFieldState extends State<ImprovedReplyInputField> {
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.requestFocus) {
      _scheduleFocus();
    }
  }

  @override
  void didUpdateWidget(ImprovedReplyInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestFocus && !oldWidget.requestFocus) {
      _scheduleFocus();
    }
  }

  void _scheduleFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      widget.onFocusHandled?.call();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.compact) {
      return CommentSheetComposer(
        controller: _replyController,
        focusNode: _focusNode,
        hint: widget.commentId == 0
            ? 'Add a comment…'
            : translation(context).lbl_write_a_comment,
        onSend: () => _submitReply(_replyController.text),
      );
    }

    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: CommentSheetTokens.inputDecoration(isDark: theme.isDark),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 80),
                child: TextField(
                  controller: _replyController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: translation(context).lbl_write_a_comment,
                    hintStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: CommentSheetTokens.inputSize,
                      color: CommentSheetTokens.metaText,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: CommentSheetTokens.inputSize,
                    color: theme.textPrimary,
                  ),
                  maxLines: null,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            Material(
              color: theme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _submitReply(_replyController.text),
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReply(String value) {
    if (value.isNotEmpty) {
      final postId = widget.postId > 0
          ? widget.postId
          : int.tryParse(widget.commentBloc.contentId);
      final postIdStr = widget.postId > 0
          ? widget.postId.toString()
          : widget.commentBloc.contentId;
      // If commentId is 0, we're posting a main comment, not a reply
      if (widget.commentId == 0) {
        widget.commentBloc.add(PostCommentEvent(postId: postId, comment: value));
      } else {
        // Otherwise we're replying to a specific comment
        widget.commentBloc.add(ReplyComment(
          commentId: widget.commentId.toString(),
          postId: postIdStr,
          commentText: value,
        ));
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
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: CommentSheetTokens.inputSize, color: theme.textTertiary),
                // Make sure there's no excess padding causing overflow
                isDense: true,
              ),
              style: TextStyle(fontFamily: 'Poppins', fontSize: CommentSheetTokens.inputSize, color: theme.textPrimary),
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
                  style: TextStyle(color: theme.textSecondary, fontSize: CommentSheetTokens.actionSize, fontFamily: 'Poppins'),
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
                  style: TextStyle(color: theme.primary, fontSize: CommentSheetTokens.actionSize, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
