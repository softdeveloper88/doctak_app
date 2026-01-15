import 'dart:io';
import 'dart:typed_data';

import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

import '../../../data/models/ai_chat_model/ai_chat_message_model.dart';

class UserMessageBubble extends StatelessWidget {
  final AiChatMessageModel message;
  final bool showAvatar;

  const UserMessageBubble({super.key, required this.message, this.showAvatar = true});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Message content
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    decoration: BoxDecoration(color: theme.primary, borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The text content
                        Text(
                          message.content,
                          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w400),
                        ),

                        // File attachment (if any)
                        if (message.filePath != null) _buildFileAttachment(context, theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Avatar
          showAvatar
              ? Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: theme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.person, size: 18, color: theme.primary),
                )
              : const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildFileAttachment(BuildContext context, OneUITheme theme) {
    final mimeType = message.mimeType ?? '';
    final errorPlaceholderColor = theme.isDark ? Colors.grey[800]! : Colors.grey.shade200;

    if (mimeType.startsWith('image/')) {
      // Priority 1: Use fileBytes if available (most reliable)
      if (message.fileBytes != null && message.fileBytes!.isNotEmpty) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              Uint8List.fromList(message.fileBytes!),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: errorPlaceholderColor,
                  child: Center(child: Icon(Icons.broken_image, size: 48, color: theme.textSecondary)),
                );
              },
            ),
          ),
        );
      }

      // Priority 2: Validate and use filePath
      if (message.filePath == null || message.filePath!.trim().isEmpty) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          height: 150,
          decoration: BoxDecoration(color: errorPlaceholderColor, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Icon(Icons.broken_image, size: 48, color: theme.textSecondary)),
        );
      }

      // Check if path is a local file or URL
      final isLocalFile = !message.filePath!.startsWith('http://') && !message.filePath!.startsWith('https://');

      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isLocalFile
              ? Image.file(
                  File(message.filePath!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: errorPlaceholderColor,
                      child: Center(child: Icon(Icons.broken_image, size: 48, color: theme.textSecondary)),
                    );
                  },
                )
              : Image.network(
                  message.filePath!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: errorPlaceholderColor,
                      child: Center(child: Icon(Icons.broken_image, size: 48, color: theme.textSecondary)),
                    );
                  },
                ),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.attach_file, size: 16, color: Colors.white.withValues(alpha: 0.8)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Attachment',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontFamily: 'Poppins'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
  }
}
