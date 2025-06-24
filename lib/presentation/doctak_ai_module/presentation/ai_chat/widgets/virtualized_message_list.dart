import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../data/models/ai_chat_model/ai_chat_message_model.dart';
import 'ai_typing_indicator.dart';
import 'user_message_bubble.dart';
import 'ai_message_bubble.dart';
import 'streaming_message_bubble.dart';

class VirtualizedMessageList extends StatefulWidget {
  final List<AiChatMessageModel> messages;
  final bool isLoading;
  final bool webSearch;
  final Function(String, String) onFeedbackSubmitted;
  final ScrollController scrollController;
  final bool isStreaming;
  final String streamingContent;
  
  const VirtualizedMessageList({
    Key? key,
    required this.messages,
    required this.scrollController,
    this.isLoading = false,
    this.webSearch = false,
    required this.onFeedbackSubmitted,
    this.isStreaming = false,
    this.streamingContent = '',
  }) : super(key: key);

  @override
  State<VirtualizedMessageList> createState() => _VirtualizedMessageListState();
}

class _VirtualizedMessageListState extends State<VirtualizedMessageList> {
  // Keep track of which messages have been seen for animations
  final Set<String> _seenMessageIds = {};
  
  @override
  void initState() {
    super.initState();
    // Mark all initial messages as seen (historical messages)
    _markCurrentMessagesAsSeen();
  }
  
  @override
  void didUpdateWidget(VirtualizedMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check for new messages - only mark new ones as seen after animation completes
    if (widget.messages.length > oldWidget.messages.length) {
      _scrollToBottom();
      
      // Mark only the new messages as seen after a delay to allow typing animation
      Future.delayed(const Duration(milliseconds: 500), () {
        _markCurrentMessagesAsSeen();
      });
    } else {
      // If no new messages, mark all as seen immediately (e.g., when loading history)
      _markCurrentMessagesAsSeen();
    }
  }
  
  void _markCurrentMessagesAsSeen() {
    for (final message in widget.messages) {
      _seenMessageIds.add(message.id.toString());
    }
  }
  
  void _scrollToBottom() {
    if (widget.scrollController.hasClients) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total items: messages + loading indicator + streaming bubble
    final totalCount = widget.messages.length + 
                       (widget.isLoading ? 1 : 0) + 
                       (widget.isStreaming ? 1 : 0);
    
    return AnimationLimiter(
      child: ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: totalCount,
        itemBuilder: (context, index) {
          // Special cases for the last items
          if (index >= widget.messages.length) {
            // If streaming, show the streaming message bubble
            if (widget.isStreaming && index == widget.messages.length) {
              return StreamingMessageBubble(
                partialContent: widget.streamingContent,
                showAvatar: widget.messages.isEmpty || 
                    widget.messages.last.role != MessageRole.assistant,
                isComplete: false,
              );
            }
            
            // Otherwise, show typing indicator as the last item when loading
            if (widget.isLoading) {
              return AiTypingIndicator(webSearch: widget.webSearch);
            }
            
            // Should not reach here, fallback
            return const SizedBox();
          }
          
          // Regular message handling
          final message = widget.messages[index];
          final messageId = message.id.toString();
          final isNewMessage = !_seenMessageIds.contains(messageId);
          
          // Determine if we should show the avatar based on consecutive messages
          final showAvatar = index == 0 || 
              (index > 0 && widget.messages[index - 1].role != message.role);
          
          // Create the appropriate message bubble based on role
          Widget messageBubble;
          if (message.role == MessageRole.user) {
            messageBubble = UserMessageBubble(
              message: message,
              showAvatar: showAvatar,
            );
          } else {
            messageBubble = AiMessageBubble(
              message: message,
              showAvatar: showAvatar,
              isNewMessage: isNewMessage,
              onFeedbackSubmitted: (feedback) {
                widget.onFeedbackSubmitted(message.id.toString(), feedback);
              },
            );
          }
          
          // Apply enter animation for new messages
          if (isNewMessage) {
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 350),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: messageBubble,
                ),
              ),
            );
          }
          
          return messageBubble;
        },
        // Advanced optimization - report if item is visible for analytics or read receipts
        addRepaintBoundaries: true,
        addAutomaticKeepAlives: true,
        // Prevent excessive rebuilds that could cause jank
        cacheExtent: 1000, // Cache more items for smoother scrolling
      ),
    );
  }
}