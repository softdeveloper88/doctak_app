import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'chat_bubble.dart';

class OptimizedMessageList extends StatefulWidget {
  final ChatBloc chatBloc;
  final String userId;
  final int conversationId;
  final String profilePic;
  final ScrollController scrollController;
  final bool isSomeoneTyping;

  const OptimizedMessageList({
    super.key,
    required this.chatBloc,
    required this.userId,
    required this.conversationId,
    required this.profilePic,
    required this.scrollController,
    required this.isSomeoneTyping,
  });

  @override
  State<OptimizedMessageList> createState() => _OptimizedMessageListState();
}

class _OptimizedMessageListState extends State<OptimizedMessageList> {
  final Map<int, Widget> _cachedMessages = {};
  final Set<int> _visibleIndices = {};
  int _lastMessageCount = -1;

  @override
  void dispose() {
    _cachedMessages.clear();
    _visibleIndices.clear();
    super.dispose();
  }

  Widget _buildLoadMoreIndicator(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMessage(int index) {
    // Don't use cache for the first few messages to ensure real-time updates
    if (index > 5 && _cachedMessages.containsKey(index)) {
      return _cachedMessages[index]!;
    }

    final bloc = widget.chatBloc;
    final msg = bloc.conversationMessages[index];
    final isMe = msg.senderId?.toString() == widget.userId;
    final isLastOfOwnMessage = index == bloc.conversationMessages.length - 1 ||
        bloc.conversationMessages[index].senderId != bloc.conversationMessages[index + 1].senderId;

    // Build attachment info
    String? attachmentJson;
    String? attachmentType;
    if (msg.hasAttachment) {
      attachmentType = msg.type;
      // Use fileUrl if available, otherwise use first file from files list
      if (msg.fileUrl != null && msg.fileUrl!.isNotEmpty) {
        attachmentJson = msg.fileUrl;
      } else if (msg.files != null && msg.files!.isNotEmpty) {
        attachmentJson = msg.files!.first.fileUrl;
      }
    }

    // Map status to seen value (0 = sent, 1 = read)
    final int seen = (msg.status == 'read') ? 1 : 0;

    final messageWidget = InkWell(
      onLongPress: () {
        if (isMe) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: translation(context).msg_confirm_delete_message,
                callback: () {
                  bloc.add(DeleteConversationMessageEvent(messageId: msg.id!));
                },
              );
            },
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(top: isLastOfOwnMessage ? 16 : 8),
        child: VisibilityDetector(
          key: Key('message_$index'),
          onVisibilityChanged: (info) {
            if (info.size.width > 0 && info.size.height > 0) {
              if (info.visibleFraction > 0.1) {
                _visibleIndices.add(index);
              } else {
                _visibleIndices.remove(index);
                if (_cachedMessages.length > 50 && !_visibleIndices.contains(index)) {
                  _cachedMessages.remove(index);
                }
              }
            }
          },
          child: ChatBubble(
            profile: isMe
                ? AppData.profilePicUrl
                : AppData.fullImageUrl(msg.sender?.profilePic ?? widget.profilePic),
            message: msg.displayText,
            isMe: isMe,
            attachmentJson: attachmentJson,
            attachmentType: attachmentType,
            createAt: msg.createdAt,
            seen: seen,
          ),
        ),
      ),
    );

    _cachedMessages[index] = messageWidget;
    return messageWidget;
  }

  @override
  void didUpdateWidget(OptimizedMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatBloc.conversationMessages.length != widget.chatBloc.conversationMessages.length) {
      _cachedMessages.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.chatBloc;

    if (_lastMessageCount != bloc.conversationMessages.length) {
      _cachedMessages.clear();
      _visibleIndices.clear();
      _lastMessageCount = bloc.conversationMessages.length;
    }

    return CustomScrollView(
      controller: widget.scrollController,
      reverse: true,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Typing indicator (first sliver = bottom-most with reverse:true)
        if (widget.isSomeoneTyping)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: ChatBubble(
                profile: AppData.fullImageUrl(widget.profilePic),
                isMe: false,
                attachmentJson: null,
                attachmentType: null,
                createAt: null,
                seen: 0,
                message: translation(context).lbl_typing,
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Show loading spinner at the top (oldest end) when loading more
                if (index >= bloc.conversationMessages.length) {
                  // Trigger load only once via guard
                  if (bloc.hasMoreMessages && !bloc.isLoadingMore) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      if (widget.conversationId > 0) {
                        bloc.add(LoadMoreMessagesEvent(conversationId: widget.conversationId));
                      }
                    });
                  }
                  return _buildLoadMoreIndicator(bloc.isLoadingMore);
                }

                return _buildMessage(index);
              },
              childCount: bloc.conversationMessages.length + ((bloc.hasMoreMessages || bloc.isLoadingMore) ? 1 : 0),
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              addSemanticIndexes: false,
            ),
          ),
        ),

      ],
    );
  }
}
