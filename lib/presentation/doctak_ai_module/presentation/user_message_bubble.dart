import 'package:flutter/material.dart';

import '../data/models/ai_chat_model/ai_chat_message_model.dart';


class UserMessageBubble extends StatelessWidget {
  final AiChatMessageModel message;
  final bool showAvatar;

  const UserMessageBubble({
    Key? key,
    required this.message,
    this.showAvatar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
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
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // The text content
                        Text(
                          message.content,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        
                        // File attachment (if any)
                        if (message.filePath != null) 
                          _buildFileAttachment(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Avatar
          showAvatar ? CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            radius: 18,
            child: Icon(
              Icons.person,
              size: 18,
              color: colorScheme.primary,
            ),
          ) : const SizedBox(width: 36),
        ],
      ),
    );
  }
  
  Widget _buildFileAttachment(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mimeType = message.mimeType ?? '';
    
    if (mimeType.startsWith('image/')) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            message.filePath!,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.onPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attach_file,
              size: 16,
              color: colorScheme.onPrimary.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Attachment',
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 12,
                ),
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