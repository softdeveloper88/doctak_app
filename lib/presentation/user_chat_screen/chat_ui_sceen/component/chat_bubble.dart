import 'dart:io';

// import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/home/components/SVPostComponent.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:voice_message_package/voice_message_package.dart';

import '../../../home_screen/fragments/home_main_screen/post_widget/video_player_widget.dart';
import 'video_view.dart';
import 'voice_message_view1.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(profile),
              radius: 16.0,
            )
          else
            const SizedBox(width: 24.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  IntrinsicWidth(
                    child: Container(
                      constraints:  BoxConstraints(
                        maxWidth: 60.w,
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 8.0),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[300] : Colors.grey[300],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12.0),
                          bottomRight: Radius.circular(isMe ? 0.0 : 12.0),
                          topRight: Radius.circular(isMe ? 12.0 : 0.0),
                          bottomLeft: Radius.circular(isMe ? 12.0 : 0.0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontSize: 16.0,
                            ),
                          ),
                          if (attachmentJson != null) _buildAttachment(context),
                          // const SizedBox(height: 4.0),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  timeAgo.format(DateTime.parse(createAt.toString())),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w500,
                                    color: isMe ? Colors.white70 : Colors.black54,
                                  ),

                                ),
                                const SizedBox(width: 10,),
                               if(isMe)
                                 if(seen==1)Image.asset('assets/icon/ic_seen.png',height: 20,width: 20,) else Image.asset('assets/icon/ic_unseen.png',height: 20,width: 20,)
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
          const SizedBox(width: 8.0),
          if (isMe)
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider('${AppData.imageUrl}${AppData.profile_pic}'),
              radius: 16.0,
            )
          else
            const SizedBox(width: 24.0),
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    if (attachmentJson!.endsWith('mp3') || attachmentJson!.endsWith('m4a')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 1),
          child: VoiceMessageView(
            controller: VoiceController(
              audioSrc: "${AppData.imageUrl}$attachmentJson",
              maxDuration: const Duration(seconds: 10),
              isFile: false, onComplete: () {  }, onPause: () {  }, onPlaying: () {  },
            ),
            innerPadding: 12,
            cornerRadius: 20,
          ),
        ),
      );
    } else if (attachmentJson!.endsWith('mp4')) {
      return VideoPlayerWidget(
          videoUrl: '${AppData.imageUrl}$attachmentJson');
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

