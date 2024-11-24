import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart' as chatItem;
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:voice_message_package/voice_message_package.dart';

import '../../../home_screen/fragments/home_main_screen/post_widget/video_player_widget.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String profile;
  final String? attachmentJson;
  final String? createAt;
  final int? seen;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.createAt,
    required this.profile,
    this.attachmentJson,
    this.seen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isMe)
            chatItem.ChatBubble(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 8,horizontal: 8),
              clipper: ChatBubbleClipper9(type: BubbleType.sendBubble),
              alignment: Alignment.topRight,
              backGroundColor: Colors.blueAccent,
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    IntrinsicWidth(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 60.w,
                        ),
                        padding: const EdgeInsets.symmetric(
                             horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message,
                              style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400),
                            ),
                            if (attachmentJson != null)
                              _buildAttachment(context),
                            // const SizedBox(height: 4.0),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    timeAgo.format(
                                        DateTime.parse(createAt.toString())),
                                    style: GoogleFonts.poppins(
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.w500,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  if (isMe)
                                    if (seen == 1)
                                      Image.asset(
                                        color: Colors.lightBlueAccent.shade100,
                                        'assets/icon/ic_seen.png',
                                        height: 15,
                                        width: 15,
                                      )
                                    else
                                      Image.asset(
                                        color: Colors.grey[400],

                                        'assets/icon/ic_unseen.png',
                                        height: 15,
                                        width: 15,
                                      )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ),
            )
          else
            chatItem.ChatBubble(
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 8),
              clipper: ChatBubbleClipper9(type: BubbleType.receiverBubble),
              backGroundColor: const Color(0xffE7E7ED),
              // margin: EdgeInsets.only(top: 20),
              child: Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    IntrinsicWidth(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: 60.w,
                        ),
                        padding: const EdgeInsets.symmetric(
                             horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message,
                              style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w400),
                            ),
                            if (attachmentJson != null)
                              _buildAttachment(context),
                            // const SizedBox(height: 4.0),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    timeAgo.format(
                                        DateTime.parse(createAt.toString())),
                                    style: GoogleFonts.poppins(
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.w500,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  if (isMe)
                                    if (seen == 1)
                                      Image.asset(
                                        'assets/icon/ic_seen.png',
                                        height: 15,
                                        width: 15,
                                      )
                                    else
                                      Image.asset(
                                        'assets/icon/ic_unseen.png',
                                        height: 15,
                                        width: 15,
                                      )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // const SizedBox(width: 8.0),
          // if (isMe)
          //   CircleAvatar(
          //     backgroundImage: CachedNetworkImageProvider('${AppData.imageUrl}${AppData.profile_pic}'),
          //     radius: 16.0,
          //   )
          // else
          //   const SizedBox(width: 24.0),
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    if (attachmentJson!.endsWith('mp3') || attachmentJson!.endsWith('m4a')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 1),
          child: VoiceMessageView(
            controller: VoiceController(
              audioSrc: "${AppData.imageUrl}$attachmentJson",
              maxDuration: const Duration(seconds: 10),
              isFile: false,
              onComplete: () {},
              onPause: () {},
              onPlaying: () {},
            ),
            innerPadding: 12,
            cornerRadius: 20,
          ),
        ),
      );
    } else if (attachmentJson!.endsWith('mp4')) {
      return VideoPlayerWidget(videoUrl: '${AppData.imageUrl}$attachmentJson');
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: CustomImageView(
          imagePath: "${AppData.imageUrl}$attachmentJson",
          fit: BoxFit.cover,
          width: MediaQuery.of(context).size.width * 0.6,
        ),
      );
    }
  }
}
