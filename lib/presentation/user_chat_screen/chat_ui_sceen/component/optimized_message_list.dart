import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/widgets/custom_alert_dialog.dart';
import 'package:doctak_app/widgets/shimmer_widget/chat_shimmer_loader.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'chat_bubble.dart';

class OptimizedMessageList extends StatefulWidget {
  final ChatBloc chatBloc;
  final String userId;
  final String roomId;
  final String profilePic;
  final ScrollController scrollController;
  final bool isSomeoneTyping;
  final String? fromId;

  const OptimizedMessageList({
    super.key,
    required this.chatBloc,
    required this.userId,
    required this.roomId,
    required this.profilePic,
    required this.scrollController,
    required this.isSomeoneTyping,
    this.fromId,
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

  Widget _buildMessage(int index) {
    // Don't use cache for the first few messages to ensure real-time updates
    if (index > 5 && _cachedMessages.containsKey(index)) {
      return _cachedMessages[index]!;
    }

    final bloc = widget.chatBloc;
    final message = bloc.messagesList[index];
    final isLastOfOwnMessage = index == bloc.messagesList.length - 1 ||
        bloc.messagesList[index].userId != bloc.messagesList[index + 1].userId;

    final messageWidget = InkWell(
      onLongPress: () {
        // Only allow deletion of messages sent by the current user
        if (message.userId == widget.userId) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return CustomAlertDialog(
                title: translation(context).msg_confirm_delete_message,
                callback: () {
                  bloc.add(DeleteMessageEvent(id: message.id.toString()));
                },
              );
            },
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          top: isLastOfOwnMessage ? 16 : 8,
        ),
        child: VisibilityDetector(
          key: Key('message_$index'),
          onVisibilityChanged: (info) {
            if (info.visibleFraction > 0.1) {
              _visibleIndices.add(index);
            } else {
              _visibleIndices.remove(index);
              // Clean up cache for non-visible items
              if (_cachedMessages.length > 50 && !_visibleIndices.contains(index)) {
                _cachedMessages.remove(index);
              }
            }
          },
          child: ChatBubble(
            profile: message.userId == widget.userId
                ? "${AppData.imageUrl}${AppData.profile_pic}"
                : widget.profilePic.startsWith('http')
                    ? widget.profilePic
                    : "${AppData.imageUrl}${widget.profilePic}",
            message: message.body ?? '',
            isMe: message.userId == widget.userId ? true : false,
            attachmentJson: message.attachment,
            attachmentType: message.attachmentType?.toString(),
            createAt: message.createdAt,
            seen: message.seen,
          ),
        ),
      ),
    );

    // Cache the widget
    _cachedMessages[index] = messageWidget;
    return messageWidget;
  }

  @override
  void didUpdateWidget(OptimizedMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear cache when messages change to ensure real-time updates
    if (oldWidget.chatBloc.messagesList.length != widget.chatBloc.messagesList.length) {
      _cachedMessages.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.chatBloc;

    // Important: widget.chatBloc is the same instance across rebuilds.
    // didUpdateWidget can't reliably detect length changes, so track it here.
    if (_lastMessageCount != bloc.messagesList.length) {
      _cachedMessages.clear();
      _visibleIndices.clear();
      _lastMessageCount = bloc.messagesList.length;
    }

    return CustomScrollView(
      controller: widget.scrollController,
      reverse: true,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        // Messages
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Trigger pagination
                if (bloc.messagePageNumber <= bloc.messageNumberOfPage) {
                  if (index == bloc.messagesList.length - bloc.messageNextPageTrigger) {
                    // Schedule pagination after build
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      bloc.add(CheckIfNeedMoreMessageDataEvent(
                        index: index,
                        userId: AppData.logInUserId,
                        roomId: widget.roomId.isEmpty ? widget.chatBloc.roomId! : widget.roomId,
                      ));
                    });
                  }
                }

                // Show loader at the end
                if (bloc.messageNumberOfPage != bloc.messagePageNumber - 1 &&
                    index >= bloc.messagesList.length - 1) {
                  return SizedBox(
                    height: 100,
                    child: ChatShimmerLoader(),
                  );
                }

                return _buildMessage(index);
              },
              childCount: bloc.messagesList.length,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              addSemanticIndexes: false,
            ),
          ),
        ),
        
        // Typing indicator
        if (widget.isSomeoneTyping && widget.fromId != widget.userId)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: ChatBubble(
                profile: widget.profilePic.startsWith('http')
                    ? widget.profilePic
                    : "${AppData.imageUrl}${widget.profilePic}",
                isMe: false,
                attachmentJson: null,
                attachmentType: null,
                createAt: null,
                seen: 0,
                message: translation(context).lbl_typing,
              ),
            ),
          ),
      ],
    );
  }
}