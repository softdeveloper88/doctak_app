import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/chat_model/conversation_message_model.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
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
  /// Called when the user taps "Edit" on their own message.
  /// The parent should pre-fill the input field and show an edit banner.
  final void Function(ConversationMessage msg)? onEditRequested;

  const OptimizedMessageList({
    super.key,
    required this.chatBloc,
    required this.userId,
    required this.conversationId,
    required this.profilePic,
    required this.scrollController,
    required this.isSomeoneTyping,
    this.onEditRequested,
  });

  @override
  State<OptimizedMessageList> createState() => _OptimizedMessageListState();
}

class _OptimizedMessageListState extends State<OptimizedMessageList> {
  final Map<int, Widget> _cachedMessages = {};
  final Set<int> _visibleIndices = {};
  int _lastMessageCount = -1;
  // Fingerprint of all receiptStates: clears cache when any tick changes.
  int _receiptFingerprint = 0;
  double? _scrollExtentBeforeLoadMore;

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
    if (msg.hasAttachment || msg.isVoiceOrAudioMessage) {
      attachmentType = msg.isVoiceOrAudioMessage ? 'audio' : (msg.attachmentCategory == 'file' ? msg.type : msg.attachmentCategory);
      attachmentJson = msg.resolvedFileUrl;
    }

    // Map status/receiptState for tick display
    final String? receiptState = msg.receiptState ?? (msg.status == 'read' ? 'seen' : null);

    final messageWidget = GestureDetector(
      onLongPress: () => _showReactionSheet(context, msg, isMe),
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
            receiptState: receiptState,
            messageId: msg.id,
            reactions: msg.reactions,
            onReact: (emoji) {
              if (msg.id != null) {
                widget.chatBloc.add(ToggleReactionEvent(messageId: msg.id!, emoji: emoji));
              }
            },
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

    if (oldWidget.chatBloc.isLoadingMore && !widget.chatBloc.isLoadingMore) {
      final before = _scrollExtentBeforeLoadMore;
      _scrollExtentBeforeLoadMore = null;
      if (before != null && widget.scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!widget.scrollController.hasClients) return;
          final position = widget.scrollController.position;
          final delta = position.maxScrollExtent - before;
          if (delta > 0) {
            position.jumpTo(position.pixels + delta);
          }
        });
      }
    }
  }

  // Quick emojis shown in the reaction picker (WhatsApp-style)
  static const _quickEmojis = ['❤️', '😂', '😮', '😢', '👍', '🙏'];

  void _showReactionSheet(BuildContext context, ConversationMessage msg, bool isMe) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;
    // receiptState: null/'sent'/'delivered'/'seen'
    final String? receiptState = msg.receiptState ?? (msg.status == 'read' ? 'seen' : null);
    final bool alreadyRead = receiptState == 'seen';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Quick emoji row — only for OTHER people's messages, not your own
              if (!isMe)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _quickEmojis.map((emoji) {
                    final alreadyReacted = msg.reactions
                            ?.any((r) => r.emoji == emoji && r.userIds.contains(AppData.logInUserId?.toString())) ??
                        false;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        if (msg.id != null) {
                          widget.chatBloc.add(ToggleReactionEvent(messageId: msg.id!, emoji: emoji));
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: alreadyReacted
                              ? theme.primary.withValues(alpha: 0.15)
                              : (isDark ? Colors.white10 : Colors.grey.shade100),
                          shape: BoxShape.circle,
                          border: alreadyReacted
                              ? Border.all(color: theme.primary, width: 1.5)
                              : null,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  }).toList(),
                ),
              // Edit + Delete options for own messages
              if (isMe && msg.id != null) ...[
                if (!isMe) const Divider(height: 24),
                // Edit — disabled once the other side has read the message
                if (msg.type == null || msg.type == 'text')
                  Opacity(
                    opacity: alreadyRead ? 0.4 : 1.0,
                    child: ListTile(
                      leading: Icon(
                        Icons.edit_outlined,
                        color: alreadyRead
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : theme.primary,
                      ),
                      title: Text(
                        alreadyRead ? 'Edit (read by recipient)' : 'Edit',
                        style: TextStyle(
                          color: alreadyRead
                              ? (isDark ? Colors.white38 : Colors.black38)
                              : (isDark ? Colors.white : Colors.black87),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: alreadyRead
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              widget.onEditRequested?.call(msg);
                            },
                    ),
                  ),
                const Divider(height: 8),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: Text(
                    translation(context).msg_confirm_delete_message,
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogCtx) {
                        return CustomAlertDialog(
                          title: translation(context).msg_confirm_delete_message,
                          callback: () {
                            widget.chatBloc.add(DeleteConversationMessageEvent(messageId: msg.id!));
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.chatBloc;

    if (_lastMessageCount != bloc.conversationMessages.length) {
      _cachedMessages.clear();
      _visibleIndices.clear();
      _lastMessageCount = bloc.conversationMessages.length;
      _receiptFingerprint = 0;
    } else {
      // Invalidate cache when any message's receiptState changes (e.g. sent→delivered→seen).
      // XOR of (id * 31) ^ receiptState.hashCode is cheap and order-independent.
      int fp = 0;
      for (final m in bloc.conversationMessages) {
        fp ^= ((m.id ?? 0) * 31) ^
            (m.receiptState?.hashCode ?? 0) ^
            (m.resolvedFileUrl?.hashCode ?? 0);
      }
      if (fp != _receiptFingerprint) {
        _receiptFingerprint = fp;
        _cachedMessages.clear();
      }
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
                receiptState: null,
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
                        if (widget.scrollController.hasClients) {
                          _scrollExtentBeforeLoadMore =
                              widget.scrollController.position.maxScrollExtent;
                        }
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
