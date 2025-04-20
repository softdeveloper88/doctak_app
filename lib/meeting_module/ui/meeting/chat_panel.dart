import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../bloc/chat/chat_bloc.dart';
import '../../bloc/chat/chat_event.dart';
import '../../bloc/chat/chat_state.dart';
import '../../models/message.dart';
import '../../utils/constants.dart';

class ChatPanel extends StatefulWidget {
  final String meetingId;
  final String userId;

  const ChatPanel({
    Key? key,
    required this.meetingId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAttachmentUploading = false;
  String? _attachmentUrl;
  String? _attachmentName;

  @override
  void initState() {
    super.initState();
    // Mark chat as visible to reset unread count
    context.read<ChatBloc>().isVisible = true;
    context.read<ChatBloc>().resetUnreadCounter();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Messages list
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (previous, current) {
                // Only rebuild for these states
                return current is ChatLoaded ||
                    current is ChatLoading ||
                    current is ChatError;
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (state is ChatLoaded) {
                  final messages = state.messages;

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('No messages yet'),
                    );
                  }

                  // Scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser = message.userId == widget.userId;
                      return _buildMessageItem(message, isCurrentUser);
                    },
                  );
                } else if (state is ChatError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: kDangerColor, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<ChatBloc>().add(
                              LoadChatHistory(widget.meetingId),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return const Center(
                  child: Text('No chat information available'),
                );
              },
            ),
          ),

          // Attachment preview (if any)
          if (_attachmentUrl != null && _attachmentName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: kLightColor,
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 20, color: kSecondaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attachmentName!,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: kSecondaryColor),
                    onPressed: _clearAttachment,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Chat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              context.read<ChatBloc>().add(
                LoadChatHistory(widget.meetingId),
              );
            },
            tooltip: 'Refresh chat',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, bool isCurrentUser) {
    // Format timestamp
    final timeString = _formatMessageTime(message.createdAt);

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Sender info - only for others' messages
              if (!isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    message.userName ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: kSecondaryColor,
                    ),
                  ),
                ),

              // Message bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCurrentUser ? kPrimaryColor : kLightColor,
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomRight: isCurrentUser ? const Radius.circular(4) : null,
                    bottomLeft: !isCurrentUser ? const Radius.circular(4) : null,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message text
                    Text(
                      message.message,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black,
                      ),
                    ),

                    // Attachment if any
                    if (message.attachmentUrl != null)
                      GestureDetector(
                        onTap: () {
                          // Open attachment
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrentUser
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: 16,
                                color: isCurrentUser ? Colors.white : kPrimaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Attachment',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCurrentUser ? Colors.white : kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Timestamp
              Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  right: isCurrentUser ? 12 : 0,
                  left: isCurrentUser ? 0 : 12,
                ),
                child: Text(
                  timeString,
                  style: const TextStyle(
                    fontSize: 10,
                    color: kSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file, color: kSecondaryColor),
            onPressed: _isAttachmentUploading ? null : _pickAttachment,
            tooltip: 'Add attachment',
          ),

          // Message input field
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: kLightColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                suffixIcon: _isAttachmentUploading
                    ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(8),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
                    : null,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          // Send button
          IconButton(
            icon: const Icon(Icons.send, color: kPrimaryColor),
            onPressed: _isAttachmentUploading ? null : _sendMessage,
            tooltip: 'Send message',
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty && _attachmentUrl == null) return;

    context.read<ChatBloc>().add(
      SendMessageEvent(
        meetingId: widget.meetingId,
        userId: widget.userId,
        message: message,
        attachmentUrl: _attachmentUrl,
      ),
    );

    // Clear input
    _messageController.clear();
    _clearAttachment();
  }

  Future<void> _pickAttachment() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _isAttachmentUploading = true;
      _attachmentName = image.name;
    });

    try {
      // Upload attachment
      final chatBloc = context.read<ChatBloc>();
      chatBloc.add(
        UploadAttachmentEvent(
          meetingId: widget.meetingId,
          file: File(image.path),
        ),
      );

      // Listen for upload completion
      chatBloc.stream.listen((state) {
        if (state is AttachmentUploaded) {
          setState(() {
            _attachmentUrl = state.attachmentUrl;
            _isAttachmentUploading = false;
          });
        } else if (state is ChatError) {
          setState(() {
            _isAttachmentUploading = false;
            _attachmentName = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${state.message}'),
              backgroundColor: kDangerColor,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isAttachmentUploading = false;
        _attachmentName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: kDangerColor,
        ),
      );
    }
  }

  void _clearAttachment() {
    setState(() {
      _attachmentUrl = null;
      _attachmentName = null;
    });
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final time = '$hour:$minute';

    if (messageDate == today) {
      return 'Today, $time';
    } else if (messageDate == yesterday) {
      return 'Yesterday, $time';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString();
      return '$day/$month/$year, $time';
    }
  }
}