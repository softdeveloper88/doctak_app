// One UI 8.5 styled Meeting Chat Bottom Sheet
import 'dart:async';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'meeting_chat_screen.dart';

/// Shows the One UI 8.5 styled chat bottom sheet
Future<void> showMeetingChatBottomSheet({required BuildContext context, required String channelId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (context) => MeetingChatBottomSheet(channelId: channelId),
  );
}

class MeetingChatBottomSheet extends StatefulWidget {
  final String channelId;

  const MeetingChatBottomSheet({super.key, required this.channelId});

  @override
  State<MeetingChatBottomSheet> createState() => _MeetingChatBottomSheetState();
}

class _MeetingChatBottomSheetState extends State<MeetingChatBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  // ── Polling (same approach as the web — no Pusher for chat) ──────────────
  Timer? _pollTimer;
  String? _lastCreatedAt; // ISO timestamp of the last received message

  @override
  void initState() {
    super.initState();
    // Initial full load then poll every 3 s (like the web's POLL_MESSAGES_MS).
    _pollMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollMessages());
  }

  Future<void> _pollMessages() async {
    try {
      final result = await getMessages(widget.channelId, afterIso: _lastCreatedAt);
      if (!mounted) return;
      if (!result.success) return;

      final data = result.data as Map<String, dynamic>?;
      final rawList = data?['messages'] as List<dynamic>?;
      if (rawList == null || rawList.isEmpty) return;

      bool added = false;

      for (final raw in rawList) {
        final m = raw as Map<String, dynamic>;
        final serverId = (m['id'] ?? '').toString();
        final userId = (m['userId'] ?? '').toString();
        final text = (m['message'] ?? '').toString();
        final createdAt = (m['createdAt'] ?? '').toString();

        // Always advance the cursor so next poll only gets newer messages.
        if (createdAt.isNotEmpty) _lastCreatedAt = createdAt.replaceFirst(' ', 'T');

        // Skip if already shown (works across sheet reopens and own messages).
        if (serverId.isNotEmpty && AppData.seenMessageIds.contains(serverId)) continue;
        if (serverId.isNotEmpty) AppData.seenMessageIds.add(serverId);

        // Own messages are already in the list (added optimistically by _sendMessage).
        // Register their server ID above so they aren't added again, then skip.
        if (userId == AppData.logInUserId) continue;

        AppData.chatMessages.add(Message(
          text: text,
          senderId: userId,
          profilePic: AppData.fullImageUrl((m['userAvatar'] ?? '').toString()),
          name: (m['userName'] ?? '').toString(),
          timestamp: createdAt.isNotEmpty
              ? DateTime.tryParse(createdAt.replaceFirst(' ', 'T')) ?? DateTime.now()
              : DateTime.now(),
          isSentByMe: false,
        ));
        added = true;
      }

      if (added) AppData.chatMessagesNotifier.value++;
    } catch (_) {
      // Swallow poll errors — next tick will retry.
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      final result = await sendMessage(widget.channelId, _messageController.text, AppData.logInUserId);
      final data = result.data as Map<String, dynamic>?;
      final posted = data?['message'] as Map<String, dynamic>?;
      final serverId = posted?['id']?.toString();
      final createdAt = posted?['createdAt']?.toString();
      if (createdAt != null && createdAt.isNotEmpty) {
        _lastCreatedAt = createdAt.replaceFirst(' ', 'T');
      }
      if (serverId != null && serverId.isNotEmpty) {
        AppData.seenMessageIds.add(serverId);
      }
      AppData.chatMessages.add(
        Message(text: _messageController.text, senderId: AppData.logInUserId, timestamp: DateTime.timestamp(), isSentByMe: true, name: AppData.name, profilePic: AppData.profilePicUrl),
      );
      // Notify all listeners (e.g. badge counters) about the new message.
      AppData.chatMessagesNotifier.value++;
      _messageController.clear();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${translation(context).msg_something_wrong} $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          _buildHandleBar(theme),
          // Header
          _buildHeader(theme),
          // Divider
          Divider(color: theme.textSecondary.withValues(alpha: 0.1), height: 1),
          // Chat messages — rebuilt reactively whenever chatMessagesNotifier
          // is incremented (by Pusher handler in VideoCallScreen).
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: AppData.chatMessagesNotifier,
              builder: (context, _, __) => _buildMessageList(theme),
            ),
          ),
          // Message input
          _buildMessageInput(theme, bottomInset, bottomPadding),
        ],
      ),
    );
  }

  Widget _buildHandleBar(OneUITheme theme) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(color: theme.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildHeader(OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: theme.inputBackground, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.chat_bubble_outline, color: theme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  translation(context).lbl_chat,
                  style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppData.chatMessages.length} messages',
                  style: TextStyle(color: theme.textSecondary, fontSize: 13, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          // Close button
          Material(
            color: theme.inputBackground,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(width: 44, height: 44, child: Icon(Icons.close, color: theme.textSecondary, size: 22)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(OneUITheme theme) {
    final messageList = AppData.chatMessages.reversed.toList();

    if (messageList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: theme.inputBackground.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_outline, color: theme.textSecondary.withValues(alpha: 0.5), size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(color: theme.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text('Start a conversation', style: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5), fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messageList.length,
      itemBuilder: (context, index) {
        final message = messageList[index];
        return _buildChatBubble(theme, message);
      },
    );
  }

  Widget _buildChatBubble(OneUITheme theme, Message message) {
    final isMe = message.isSentByMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(theme, message.profilePic, message.name),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: 70.w),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // Sender name — only for received messages
                  if (!isMe && message.name.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        message.name,
                        style: TextStyle(
                          color: theme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? theme.primary : theme.inputBackground,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isMe ? 20 : 4),
                        topRight: const Radius.circular(20),
                        bottomLeft: const Radius.circular(20),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(color: isMe ? Colors.white : theme.textPrimary, fontSize: 15, fontWeight: FontWeight.w400, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      timeAgo.format(message.timestamp),
                      style: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w400),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(theme, message.profilePic, message.name),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(OneUITheme theme, String profilePic, String name) {
    // profilePic already contains the full URL (set via AppData.fullImageUrl at poll time).
    final imageUrl = profilePic.trim();
    // Derive initials fallback from name.
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join()
        : '?';

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.inputBackground, width: 2),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: theme.primary.withValues(alpha: 0.15),
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        onBackgroundImageError: imageUrl.isNotEmpty ? (_, __) {} : null,
        child: imageUrl.isEmpty
            ? Text(initials, style: TextStyle(color: theme.primary, fontSize: 12, fontWeight: FontWeight.w700))
            : null,
      ),
    );
  }

  Widget _buildMessageInput(OneUITheme theme, double bottomInset, double bottomPadding) {
    // Use viewInsets.bottom when keyboard is showing, otherwise use viewPadding.bottom for gesture nav bar
    final effectiveBottomPadding = bottomInset > 0 ? bottomInset + 12 : bottomPadding + 16;

    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: effectiveBottomPadding),
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: theme.inputBackground, borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                enabled: !_isSending,
                style: TextStyle(color: theme.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: translation(context).lbl_type_message_here,
                  hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send button
          Material(
            color: theme.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _isSending ? null : _sendMessage,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: _isSending
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
