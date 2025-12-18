// chat_screen.dart
import 'dart:convert';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/pusher_service.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/video_api.dart';
import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart' as chatItem;
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../../../../user_chat_screen/chat_ui_sceen/component/chat_bubble.dart';

// message_model.dart
class Message {
  final String text;
  final String senderId;
  final DateTime timestamp;
  final String name;
  final String profilePic;
  final bool isSentByMe;

  Message({
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.name,
    required this.profilePic,
    required this.isSentByMe,
  });

}
class MeetingChatScreen extends StatefulWidget {
  final String channelId;
  const MeetingChatScreen({
    super.key,
    required this.channelId,
  });

  @override
  _MeetingChatScreenState createState() => _MeetingChatScreenState();
}

class _MeetingChatScreenState extends State<MeetingChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final PusherService _pusherService = PusherService();
  bool _isSending = false;
  PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  late PusherChannel clientListenChannel;
  late PusherChannel clientSendChannel;
  @override
  void initState() {
    super.initState();
   ConnectPusher();
  }

  // void _initializePusher() async {
  //   await _pusherService.initialize();
  //   await _pusherService.connect();
  //   _pusherService.subscribeToChannel(widget.channelId);
  //
  //   _pusherService.registerEventListener('new-message', _handleNewMessage);
  // }
  //
  // void _handleNewMessage(dynamic data) {
  //   final message = Message.fromJson(data);
  //   setState(() {
  //     AppData.chatMessages.add(message);
  //   });
  // }

  void onSubscriptionSucceeded(String channelName, dynamic data) {
    print("onSubscriptionSucceeded: $channelName data: $data");
  }

  void onSubscriptionError(String message, dynamic e) {
    print("onSubscriptionError: $message Exception: $e");
  }

  void onDecryptionFailure(String event, String reason) {
    print("onDecryptionFailure: $event reason: $reason");
  }

  void onMemberAdded(String channelName, PusherMember member) {
    print("onMemberAdded: $channelName member: $member");
  }

  void onMemberRemoved(String channelName, PusherMember member) {
    print("onMemberRemoved: $channelName member: $member");
  }

  void onError(String message, int? code, dynamic e) {
    print("onError: $message code: $code exception: $e");
  }

  // Authorizer method for Pusher - required to prevent iOS crash
  Future<dynamic>? onAuthorizer(
      String channelName, String socketId, dynamic options) async {
    print(
        "onAuthorizer called for channel: $channelName, socketId: $socketId");
    
    // For public channels (not starting with 'private-' or 'presence-'),
    // return null
    if (!channelName.startsWith('private-') &&
        !channelName.startsWith('presence-')) {
      return null;
    }
    
    return null;
  }


  void ConnectPusher() async {

    // Create the Pusher client
    try {
      await pusher.init(
          apiKey: PusherConfig.key,
          cluster: PusherConfig.cluster,
          useTLS: false,
          onSubscriptionSucceeded: onSubscriptionSucceeded,
          onSubscriptionError: onSubscriptionError,
          onMemberAdded: onMemberAdded,
          onMemberRemoved: onMemberRemoved,
          // onEvent: onEvent,
          onDecryptionFailure: onDecryptionFailure,
          onError: onError,
          onSubscriptionCount: onSubscriptionCount,
          onAuthorizer: onAuthorizer);

      pusher.connect();

      if (pusher != null) {
        // Successfully created and connected to Pusher
        clientListenChannel = await pusher.subscribe(
          channelName: "meeting-channel${widget.channelId}",
          onMemberAdded: (member) {
            // print("Member added: $member");
          },
          onMemberRemoved: (member) {
            print("Member removed: $member");
          },
          onEvent: (event) {
            String eventName = event.eventName;
            Map<String, dynamic> jsonMap = jsonDecode(event.data.toString());
            print('eventdata ${jsonMap}');
            print('eventdata1 $eventName');

            switch (eventName) {
              case 'new-message':
                if(AppData.logInUserId != jsonMap['user_id']) {
                  AppData.chatMessages.add(Message(text: jsonMap['message'], senderId: jsonMap['user_id'],profilePic: jsonMap['profile_pic'],name: '',timestamp: DateTime.timestamp(), isSentByMe: false));
                }
               setState(() {});
                break;
              case 'allow-join-request':
                print("eventName $eventName");
                toast(eventName);
                break;
              default:
              // Handle unknown event types or ignore them
                break;
            }
          },
        );

        // Attach an event listener to the channel
      } else {
        // Handle the case where Pusher connection failed
        // print("Failed to connect to Pusher");
      }
    } catch (e) {
      print('eee $e');
    }
  }

  onSubscriptionCount(String channelName, int subscriptionCount) {}
  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      await sendMessage(
         widget.channelId,
          _messageController.text,
        AppData.logInUserId
      );
       AppData.chatMessages.add(Message( text: _messageController.text, senderId: AppData.logInUserId, timestamp: DateTime.timestamp(), isSentByMe: true, name:'', profilePic: "${AppData.imageUrl}${AppData.profile_pic}"));
       setState(() {

       });
       _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${translation(context).msg_something_wrong} $e')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   List<Message> messageList= AppData.chatMessages.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () {
          Navigator.pop(context);
        },),
        title: Text(translation(context).lbl_chat),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messageList.length,
              itemBuilder: (context, index) {
                final message = messageList[index];
                return  ChatBubble(
                  profile:message.profilePic,
                  message: message.text?? '',
                  isMe:message.isSentByMe,
                  createAt: message.timestamp.toString(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(child: _buildMessageInput()) ,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              enabled: !_isSending,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: _isSending
                ? const CircularProgressIndicator()
                : const Icon(Icons.send),
            onPressed: _isSending ? null : _sendMessage,
          ),
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

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.createAt,
    required this.profile,
  }) : super(key: key);

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
            alignment: isMe?Alignment.centerRight:Alignment.centerLeft,
            child:  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment:
    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
    children: [
    IntrinsicWidth(
    child: Container(
    constraints: BoxConstraints(
    maxWidth: 60.w,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: chatItem.ChatBubble(
                elevation: 0,
                padding: const EdgeInsets.all(8),
                clipper: ChatBubbleClipper5(
                  type: isMe ? BubbleType.sendBubble : BubbleType.receiverBubble,
                ),
                backGroundColor: isMe ? Colors.blueAccent : const Color(0xffE7E7ED),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 16.0,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    if (createAt != null)
                      Text(
                        timeAgo.format(DateTime.parse(createAt!)),
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w500,
                          color: isMe ? Colors.white70 : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ), if (isMe) _buildProfileImage(),]));
  }

  Widget _buildProfileImage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CircleAvatar(
        backgroundImage: NetworkImage(profile),
        radius: 16.0,
      ),
    );
  }
}
