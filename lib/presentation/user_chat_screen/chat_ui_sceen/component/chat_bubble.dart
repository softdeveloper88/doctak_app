import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/main.dart';
import 'package:doctak_app/presentation/home_screen/home/components/full_screen_image_page.dart';
import 'package:doctak_app/presentation/home_screen/utils/SVColors.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import 'video_player_widget.dart';
import 'custom_audio_player.dart';
import 'voice_message_precacher.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isMe;
  final String profile;
  final String? attachmentJson;
  final String? attachmentType;
  final String? createAt;
  final int? seen;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.createAt,
    required this.profile,
    this.attachmentJson,
    this.attachmentType,
    this.seen,
  }) : super(key: key);

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 12.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (widget.isMe)
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    SVAppColorPrimary,
                    SVAppColorPrimary.withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: SVAppColorPrimary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.message.isNotEmpty)
                      Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    if (widget.attachmentJson != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: widget.message.isNotEmpty ? 8 : 0,
                        ),
                        child: _buildAttachment(context),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeAgo.format(DateTime.parse(widget.createAt.toString())),
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (widget.isMe)
                          Icon(
                            widget.seen == 1
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 16,
                            color: widget.seen == 1
                                ? Colors.lightBlueAccent
                                : Colors.white.withOpacity(0.7),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: appStore.isDarkMode
                    ? const Color(0xFF2A2A2A) // Slightly lighter dark gray
                    : const Color(0xFFE8E8E8),
                // Light gray for light mode
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: appStore.isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.message.isNotEmpty)
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: appStore.isDarkMode
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 15.0,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    if (widget.attachmentJson != null)
                      Padding(
                        padding: EdgeInsets.only(
                          top: widget.message.isNotEmpty ? 8 : 0,
                        ),
                        child: _buildAttachment(context),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      widget.createAt != null
                          ? timeAgo.format(DateTime.parse(widget.createAt.toString()))
                          : '',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11.0,
                        fontWeight: FontWeight.w400,
                        color: appStore.isDarkMode
                            ? Colors.white.withOpacity(0.5)
                            : Colors.black.withOpacity(0.5),
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
    try {
      // Null safety check
      if (widget.attachmentJson == null || widget.attachmentJson!.isEmpty) {
        debugPrint('Attachment is null or empty');
        return const SizedBox.shrink();
      }

      debugPrint('Building attachment: ${widget.attachmentJson}, type: ${widget.attachmentType}');

      // Check attachmentType first (more reliable than extension)
      final attachmentType = widget.attachmentType?.toString().toLowerCase() ?? '';

      // Handle voice/audio messages
      if (attachmentType.contains('audio') ||
          attachmentType.contains('voice') ||
          attachmentType == 'audio' ||
          attachmentType == 'voice') {
        debugPrint('Rendering voice/audio message');
        final audioUrl = "${AppData.imageUrl}${widget.attachmentJson}";
        return VoiceMessagePrecacher(
          audioUrl: audioUrl,
          child: CustomAudioPlayer(
            audioUrl: audioUrl,
            isMe: widget.isMe,
          ),
        );
      }

      // Handle video messages
      if (attachmentType.contains('video') || attachmentType == 'video') {
        debugPrint('Rendering video message');
        return VideoPlayerWidget(
            videoUrl: '${AppData.imageUrl}${widget.attachmentJson}');
      }

      // Fallback to extension-based detection if attachmentType is not available
      final audioExtensions = [
        'mp3',
        'm4a',
        'wav',
        'aac',
        'ogg',
        'flac',
        'amr'
      ];
      final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'];

      // Safe file extension extraction
      final parts = widget.attachmentJson!.split('.');
      if (parts.isEmpty) {
        debugPrint('No file extension found');
        return _buildErrorAttachment();
      }

      final fileExtension = parts.last.toLowerCase();
      debugPrint('File extension: $fileExtension');

      if (audioExtensions.contains(fileExtension)) {
        // Use custom audio player with pre-caching for better performance
        debugPrint('Rendering audio by extension');
        final audioUrl = "${AppData.imageUrl}${widget.attachmentJson}";
        return VoiceMessagePrecacher(
          audioUrl: audioUrl,
          child: CustomAudioPlayer(
            audioUrl: audioUrl,
            isMe: widget.isMe,
          ),
        );
      } else if (videoExtensions.contains(fileExtension)) {
        debugPrint('Rendering video by extension');
        return VideoPlayerWidget(
            videoUrl: '${AppData.imageUrl}${widget.attachmentJson}');
      } else {
        // Default to image
        debugPrint('Rendering as image (default)');
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImagePage(
                  listCount: 1,
                  imageUrl: "${AppData.imageUrl}${widget.attachmentJson}",
                  post: null,
                  mediaUrls: [],
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
                maxHeight: 300,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  CustomImageView(
                    imagePath: "${AppData.imageUrl}${widget.attachmentJson}",
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error building attachment: $e');
      return _buildErrorAttachment();
    }
  }

  Widget _buildErrorAttachment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Unable to load attachment',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

}
