import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/chat_model/conversation_message_model.dart';
import 'package:doctak_app/presentation/home_screen/home/components/full_screen_image_page.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
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
  final String? receiptState;
  final int? messageId;
  final List<MessageReaction>? reactions;
  final void Function(String emoji)? onReact;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.createAt,
    required this.profile,
    this.attachmentJson,
    this.attachmentType,
    this.receiptState,
    this.messageId,
    this.reactions,
    this.onReact,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  String _formatTime() {
    final raw = widget.createAt?.trim();
    if (raw == null || raw.isEmpty) return '';
    try {
      return timeAgo.format(DateTime.parse(raw));
    } catch (_) {
      return '';
    }
  }

  bool get _isVoiceAttachment {
    final type = widget.attachmentType?.toLowerCase() ?? '';
    return type.contains('audio') || type.contains('voice');
  }

  bool get _hasVisibleContent =>
      widget.message.isNotEmpty ||
      (widget.attachmentJson != null && widget.attachmentJson!.isNotEmpty) ||
      _isVoiceAttachment;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final hasReactions = widget.reactions != null && widget.reactions!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        top: 4.0,
        // Extra bottom padding to make room for reaction pills
        bottom: hasReactions ? 16.0 : 4.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (widget.isMe)
            _BubbleWithReactions(
              isMe: true,
              hasReactions: hasReactions,
              reactions: widget.reactions,
              onReact: widget.onReact,
              bubble: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [
                        theme.primary,
                        theme.primary.withValues(alpha: 0.9)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4)),
                  boxShadow: [
                    BoxShadow(
                        color: theme.primary.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
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
                              height: 1.4),
                        ),
                      if (widget.attachmentJson != null || _isVoiceAttachment)
                        Padding(
                          padding: EdgeInsets.only(
                              top: widget.message.isNotEmpty ? 8 : 0),
                          child: _buildAttachment(context),
                        ),
                      if (!_hasVisibleContent)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Message unavailable',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(),
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11.0,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.8)),
                          ),
                          const SizedBox(width: 6),
                          if (widget.isMe)
                            Icon(
                              widget.receiptState == 'seen' || widget.receiptState == 'delivered'
                                  ? Icons.done_all_rounded
                                  : Icons.done_rounded,
                              size: 16,
                              color: widget.receiptState == 'seen'
                                    ? Colors.lightBlueAccent
                                    : Colors.white.withValues(alpha: 0.7)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            _BubbleWithReactions(
              isMe: false,
              hasReactions: hasReactions,
              reactions: widget.reactions,
              onReact: widget.onReact,
              bubble: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                      bottomLeft: Radius.circular(4)),
                  boxShadow: [
                    BoxShadow(
                        color: theme.isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.message.isNotEmpty)
                        Text(
                          widget.message,
                          style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 15.0,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              height: 1.4),
                        ),
                      if (widget.attachmentJson != null || _isVoiceAttachment)
                        Padding(
                          padding: EdgeInsets.only(
                              top: widget.message.isNotEmpty ? 8 : 0),
                          child: _buildAttachment(context),
                        ),
                      if (!_hasVisibleContent)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Message unavailable',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 14,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(),
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11.0,
                            fontWeight: FontWeight.w400,
                            color: theme.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    final theme = OneUITheme.of(context);
    try {
      // Null safety check
      if (widget.attachmentJson == null || widget.attachmentJson!.isEmpty) {
        final attachmentType = widget.attachmentType?.toString().toLowerCase() ?? '';
        if (attachmentType.contains('audio') || attachmentType.contains('voice')) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.isMe ? Colors.white70 : OneUITheme.of(context).primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Voice message',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }

      debugPrint('Building attachment: ${widget.attachmentJson}, type: ${widget.attachmentType}');

      // Check attachmentType first (more reliable than extension)
      final attachmentType = widget.attachmentType?.toString().toLowerCase() ?? '';

      // Handle voice/audio messages
      if (attachmentType.contains('audio') || attachmentType.contains('voice') || attachmentType == 'audio' || attachmentType == 'voice') {
        final audioUrl = widget.attachmentJson == null
            ? ''
            : AppData.resolveChatMediaUrl(widget.attachmentJson);
        if (audioUrl.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.isMe ? Colors.white70 : theme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Voice message',
                  style: TextStyle(
                    fontSize: 14,
                    color: widget.isMe ? Colors.white70 : theme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        return VoiceMessagePrecacher(
          audioUrl: audioUrl,
          child: CustomAudioPlayer(audioUrl: audioUrl, isMe: widget.isMe),
        );
      }

      // Handle video messages
      if (attachmentType.contains('video') || attachmentType == 'video') {
        return VideoPlayerWidget(videoUrl: AppData.resolveChatMediaUrl(widget.attachmentJson));
      }

      // Fallback to extension-based detection if attachmentType is not available
      final audioExtensions = ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'opus', 'webm', 'flac', 'amr'];
      final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', '3gp'];

      // Safe file extension extraction
      final parts = widget.attachmentJson!.split('.');
      if (parts.isEmpty) {
        debugPrint('No file extension found');
        return _buildErrorAttachment();
      }

      final fileExtension = parts.last.toLowerCase();
      debugPrint('File extension: $fileExtension');

      if (audioExtensions.contains(fileExtension)) {
        debugPrint('Rendering audio by extension');
        final audioUrl = AppData.resolveChatMediaUrl(widget.attachmentJson);
        return VoiceMessagePrecacher(
          audioUrl: audioUrl,
          child: CustomAudioPlayer(audioUrl: audioUrl, isMe: widget.isMe),
        );
      } else if (videoExtensions.contains(fileExtension)) {
        debugPrint('Rendering video by extension');
        return VideoPlayerWidget(videoUrl: AppData.resolveChatMediaUrl(widget.attachmentJson));
      } else {
        // Default to image
        debugPrint('Rendering as image (default)');
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FullScreenImagePage(listCount: 1, imageUrl: AppData.fullImageUrl(widget.attachmentJson), post: null, mediaUrls: []),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65, maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: theme.isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Stack(
                children: [
                  CustomImageView(imagePath: AppData.fullImageUrl(widget.attachmentJson), fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
                      child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
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
    final theme = OneUITheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.error.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: theme.error, size: 20),
          const SizedBox(width: 8),
          Text(
            'Unable to load attachment',
            style: TextStyle(color: theme.error, fontSize: 13, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}

/// Wraps a bubble widget with WhatsApp-style reaction pills below it.
class _BubbleWithReactions extends StatelessWidget {
  final Widget bubble;
  final bool isMe;
  final bool hasReactions;
  final List<MessageReaction>? reactions;
  final void Function(String emoji)? onReact;

  const _BubbleWithReactions({
    required this.bubble,
    required this.isMe,
    required this.hasReactions,
    required this.reactions,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasReactions) return bubble;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The main bubble
        bubble,
        // Reaction pills positioned at the bottom edge
        Positioned(
          bottom: -14,
          left: isMe ? null : 8,
          right: isMe ? 8 : null,
          child: _ReactionPills(
            reactions: reactions!,
            isMe: isMe,
            onReact: onReact,
          ),
        ),
      ],
    );
  }
}

class _ReactionPills extends StatelessWidget {
  final List<MessageReaction> reactions;
  final bool isMe;
  final void Function(String emoji)? onReact;

  const _ReactionPills({
    required this.reactions,
    required this.isMe,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final shadowColor = isDark ? Colors.black45 : Colors.black12;

    // Group: only show non-empty
    final nonEmpty = reactions.where((r) => r.count > 0).toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 4, offset: const Offset(0, 2)),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < nonEmpty.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            GestureDetector(
              onTap: () => onReact?.call(nonEmpty[i].emoji),
              child: _ReactionChip(
                reaction: nonEmpty[i],
                isMine: nonEmpty[i].userIds.contains(AppData.logInUserId),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final MessageReaction reaction;
  final bool isMine;

  const _ReactionChip({required this.reaction, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(reaction.emoji, style: const TextStyle(fontSize: 14)),
        if (reaction.count > 1) ...[
          const SizedBox(width: 2),
          Text(
            '${reaction.count}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: isMine
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ],
    );
  }
}
