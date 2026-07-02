// chat_screen.dart
import 'dart:async';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart' as chatItem;
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeAgo;

// message_model.dart
class Message {
  final String text;
  final String senderId;
  final DateTime timestamp;
  final String name;
  final String profilePic;
  final bool isSentByMe;

  Message({required this.text, required this.senderId, required this.timestamp, required this.name, required this.profilePic, required this.isSentByMe});
}

class MeetingChatScreen extends StatefulWidget {
  final String channelId;
  const MeetingChatScreen({super.key, required this.channelId});

  @override
  _MeetingChatScreenState createState() => _MeetingChatScreenState();
}

class _MeetingChatScreenState extends State<MeetingChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  Timer? _pollTimer;
  String? _lastCreatedAt;

  @override
  void initState() {
    super.initState();
    _pollMessages();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _pollMessages());
  }

  Future<void> _pollMessages() async {
    try {
      final result =
          await getMessages(widget.channelId, afterIso: _lastCreatedAt);
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

        if (createdAt.isNotEmpty) {
          _lastCreatedAt = createdAt.replaceFirst(' ', 'T');
        }
        if (serverId.isNotEmpty && AppData.seenMessageIds.contains(serverId)) {
          continue;
        }
        if (serverId.isNotEmpty) AppData.seenMessageIds.add(serverId);
        if (userId == AppData.logInUserId) continue;

        AppData.chatMessages.add(Message(
          text: text,
          senderId: userId,
          profilePic:
              AppData.fullImageUrl((m['userAvatar'] ?? '').toString()),
          name: (m['userName'] ?? '').toString(),
          timestamp: createdAt.isNotEmpty
              ? DateTime.tryParse(createdAt.replaceFirst(' ', 'T')) ??
                  DateTime.now()
              : DateTime.now(),
          isSentByMe: false,
        ));
        added = true;
      }

      if (added && mounted) setState(() {});
    } catch (_) {}
  }
  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

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
        Message(text: _messageController.text, senderId: AppData.logInUserId, timestamp: DateTime.timestamp(), isSentByMe: true, name: '', profilePic: AppData.profilePicUrl),
      );
      setState(() {});
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${translation(context).msg_something_wrong} $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Message> messageList = AppData.chatMessages.reversed.toList();
    return Scaffold(
      appBar: DoctakAppBar(
        title: translation(context).lbl_chat,
        toolbarHeight: 56,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messageList.length,
              itemBuilder: (context, index) {
                final message = messageList[index];
                return ChatBubble(profile: message.profilePic, message: message.text, isMe: message.isSentByMe, createAt: message.timestamp.toString());
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(child: _buildMessageInput()),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: translation(context).lbl_type_message_here,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              enabled: !_isSending,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(icon: _isSending ? const CircularProgressIndicator() : const Icon(Icons.send), onPressed: _isSending ? null : _sendMessage),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String profile;
  final String? createAt;

  const ChatBubble({super.key, required this.message, required this.isMe, required this.createAt, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) _buildProfileImage(),
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                IntrinsicWidth(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 60.w),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: chatItem.ChatBubble(
                      elevation: 0,
                      padding: const EdgeInsets.all(8),
                      clipper: ChatBubbleClipper5(type: isMe ? BubbleType.sendBubble : BubbleType.receiverBubble),
                      backGroundColor: isMe ? Colors.blueAccent : const Color(0xffE7E7ED),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16.0, fontFamily: 'Poppins', fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 4.0),
                          if (createAt != null)
                            Text(
                              timeAgo.format(DateTime.parse(createAt!)),
                              style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w500, color: isMe ? Colors.white70 : Colors.black54),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) _buildProfileImage(),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CircleAvatar(backgroundImage: NetworkImage(profile), radius: 16.0),
    );
  }
}
