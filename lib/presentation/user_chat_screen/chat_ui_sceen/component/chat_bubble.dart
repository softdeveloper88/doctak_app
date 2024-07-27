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
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:voice_message_package/voice_message_package.dart';

import '../../../home_screen/fragments/home_main_screen/post_widget/video_player_widget.dart';
import 'video_view.dart';
import 'voice_message_view1.dart';

// class AudioViewer extends StatefulWidget {
//   const AudioViewer({
//     super.key,
//     required this.audio,
//     required this.controllable,
//   });
//
//   final String audio;
//   final bool controllable;
//
//   @override
//   State<AudioViewer> createState() => _AudioViewerState();
// }
//
// class _AudioViewerState extends State<AudioViewer> {
//   final player = AudioPlayer();
//
//   bool _isPlaying = false;
//   double _currentPosition = 0.0;
//   double _duration = 0.0;
//   @override
//   void initState() {
//     player.onPlayerComplete.listen((event) {
//       setState(() {});
//     });
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     player.dispose();
//     super.dispose();
//   }
//
//   void changePlayState() async {
//     if (player.state == PlayerState.playing) {
//       await player.pause();
//     } else {
//       if (player.state == PlayerState.completed) {
//         await player.play(UrlSource(widget.audio),
//             position: const Duration(seconds: 0));
//       }
//       await player.play(UrlSource(widget.audio));
//     }
//
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return widget.controllable
//         ? GestureDetector(
//       onTap: () => changePlayState(),
//       child: Stack(
//         fit: StackFit.loose,
//         alignment: Alignment.center,
//         children: [
//           Icon(
//             Icons.music_note_rounded,
//             size: MediaQuery.of(context).size.width * 0.80,
//           ),
//           if (player.state != PlayerState.playing) ...[
//             CircleAvatar(
//               backgroundColor: const Color.fromARGB(255, 209, 208, 208),
//               radius: 40,
//               child: IconButton(
//                 padding: const EdgeInsets.all(0),
//                 onPressed: () => changePlayState(),
//                 icon: const Icon(
//                   Icons.play_arrow_rounded,
//                   size: 50,
//                 ),
//               ),
//             )
//           ],
//         ],
//       ),
//     )
//         : const Center(
//       child: Icon(Icons.music_note_rounded),
//     );
//   }
// }

// class AudioViewer extends StatefulWidget {
//   const AudioViewer({
//     required this.audio,
//     required this.controllable,
//   });
//
//   final String audio;
//   final bool controllable;
//
//   @override
//   State<AudioViewer> createState() => _AudioViewerState();
// }
//
// class _AudioViewerState extends State<AudioViewer> {
//   final player = AudioPlayer();
//   bool isPlaying = false;
//   double sliderValue = 0.0;
//   double duration = 0.0;
//
//   @override
//   void initState() {
//     // player.onPlayerComplete.listen(( state) {
//     //   setState(()  {
//     //     // player.stop();
//     //     duration=0.0;
//     //   });
//     // });
//     player.onPlayerStateChanged.listen((PlayerState state) {
//       if (mounted) {
//         setState(() {
//           isPlaying = state == PlayerState.playing;
//         });
//       }
//     });
//
//     player.onDurationChanged.listen((Duration d) {
//       if (mounted) {
//         setState(() {
//           duration = d.inMilliseconds.toDouble();
//         });
//       }
//     });
//     player.onPositionChanged.listen((Duration p) {
//       if (mounted) {
//         setState(() {
//           sliderValue = p.inMilliseconds.toDouble();
//         });
//       }
//     });
//     super.initState();
//   }
//
//   @override
//   void dispose() {
//     player.dispose();
//     super.dispose();
//   }
//   // void changePlayState() async {
//   //   if (isPlaying) {
//   //     await player.pause();
//   //   } else {
//   //     await player.play(UrlSource(widget.audio),
//   //           position: const Duration(seconds: 0));
//   //     // await player.play(widget.audio, isLocal: true);
//   //   }
//   // }
//
//   void changePlayState() async {
//     if (player.state == PlayerState.playing) {
//       await player.pause();
//     } else {
//       if (player.state == PlayerState.completed) {
//         await player.play(UrlSource(widget.audio),
//             position: const Duration(seconds: 0));
//       }
//       await player.play(UrlSource(widget.audio));
//     }
//
//     setState(() {});
//   }
//
//   void seekToSecond(double second) {
//     Duration newDuration = Duration(milliseconds: second.toInt());
//     player.seek(newDuration);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return widget.controllable
//         ? GestureDetector(
//             onTap: () => changePlayState(),
//             child: Row(
//               children: [
//                 if (!isPlaying)
//                   CircleAvatar(
//                     backgroundColor: const Color.fromARGB(255, 209, 208, 208),
//                     radius: 25,
//                     child: IconButton(
//                       padding: const EdgeInsets.all(0),
//                       onPressed: () => changePlayState(),
//                       icon: const Icon(
//                         Icons.play_arrow_rounded,
//                         size: 40,
//                       ),
//                     ),
//                   )
//                 else
//                   CircleAvatar(
//                     backgroundColor: const Color.fromARGB(255, 209, 208, 208),
//                     radius: 25,
//                     child: IconButton(
//                       padding: const EdgeInsets.all(0),
//                       onPressed: () => changePlayState(),
//                       icon: const Icon(
//                         Icons.pause,
//                         size: 40,
//                       ),
//                     ),
//                   ),
//                 Slider(
//                   value: sliderValue,
//                   min: 0.0,
//                   max: duration,
//                   onChanged: (value) {
//                     seekToSecond(value);
//                     setState(() {
//                       sliderValue = value;
//                     });
//                   },
//                 ),
//               ],
//             ),
//           )
//         : const Center(
//             child: Icon(Icons.music_note_rounded),
//           );
//   }
// }

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String profile;
  final String? attachmentJson;
  final String? createAt;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.createAt,
    required this.profile,
    this.attachmentJson,
  }) : super(key: key);

  // Future<dynamic> durationGet(url) async {
  //   final player = AudioPlayer();
  //   var duration = await player.setSourceUrl(url);
  //   return duration;
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // if (!isMe)
          //   CircleAvatar(
          //     backgroundImage: CachedNetworkImageProvider(profile),
          //     radius: 16.0,
          //   )
          // else
          //   const SizedBox(width: 24.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 150,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(10.0),
                        bottomRight: Radius.circular(isMe ? 0.0 : 10.0),
                        topRight: Radius.circular(isMe ? 10.0 : 0.0),
                        bottomLeft: Radius.circular(isMe ? 10.0 : 0.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                        if (attachmentJson != null)
                          if (attachmentJson!.endsWith('mp3'))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width - 1),
                                child: VoiceMessageView(
                                  controller: VoiceController(
                                    audioSrc:
                                        "${AppData.imageUrl}$attachmentJson",
                                    maxDuration: const Duration(seconds: 10),
                                    isFile: false,
                                    onComplete: () {
                                      /// do something on complete
                                    },
                                    onPause: () {
                                      /// do something on pause
                                    },
                                    onPlaying: () {
                                      /// do something on playing
                                    },
                                    onError: (err) {
                                      /// do somethin on error
                                    },
                                  ),
                                  innerPadding: 12,
                                  cornerRadius: 20,
                                ),
                                // AudioViewer(audio: "${AppData.imageUrl}$attachmentJson", controllable: true,)
                              ),
                            )
                          else if (attachmentJson!.endsWith('m4a'))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width - 1),
                                child: VoiceMessageView(
                                  controller: VoiceController(
                                    audioSrc:
                                        "${AppData.imageUrl}$attachmentJson",
                                    maxDuration: const Duration(seconds: 10),
                                    isFile: false,
                                    onComplete: () {
                                      /// do something on complete
                                    },
                                    onPause: () {
                                      /// do something on pause
                                    },
                                    onPlaying: () {
                                      /// do something on playing
                                    },
                                    onError: (err) {
                                      /// do somethin on error
                                    },
                                  ),
                                  innerPadding: 12,
                                  cornerRadius: 20,
                                ),
                                // AudioViewer(audio: "${AppData.imageUrl}$attachmentJson", controllable: true,)
                              ),
                            )
                          else if (attachmentJson!.endsWith('mp4'))
                            VideoPlayerWidget(
                                videoUrl: '${AppData.imageUrl}$attachmentJson')
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: CustomImageView(
                                imagePath: "${AppData.imageUrl}$attachmentJson",
                                fit: BoxFit.cover,
                                width: MediaQuery.of(context).size.width *
                                    0.6, // Adjust as needed
                                // height: 200, // You can set a fixed height if needed
                              ),
                            ),
                      ],
                    ),
                  ),
                  Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Text(
                        timeAgo.format(DateTime.parse(createAt.toString())),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.black54),
                      )),
                  const SizedBox(
                    height: 8,
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // if (isMe)
          // CircleAvatar(
          //   backgroundImage: CachedNetworkImageProvider(AppData.imageUrl + AppData.profile_pic),
          //   radius: 16.0,
          // )
          // else
          //   const SizedBox(width: 24.0),
        ],
      ),
    );
  }
}
