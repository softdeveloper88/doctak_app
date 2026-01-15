import 'dart:async';
import 'dart:math' as math;

import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/ai_chat_model/ai_chat_message_model.dart';

class AiMessageBubble extends StatefulWidget {
  final AiChatMessageModel message;
  final bool showAvatar;
  final Function(String feedback) onFeedbackSubmitted;
  final bool isNewMessage;

  const AiMessageBubble({super.key, required this.message, this.showAvatar = true, required this.onFeedbackSubmitted, this.isNewMessage = false});

  @override
  State<AiMessageBubble> createState() => _AiMessageBubbleState();
}

class _AiMessageBubbleState extends State<AiMessageBubble> with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  String _currentlyDisplayedText = '';
  bool _isTyping = true;
  Timer? _typingTimer;
  int _currentCharIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isNewMessage) {
      // Only start typing animation for new messages
      _startTypingAnimation();
    } else {
      // For historical messages, show full content immediately
      _currentlyDisplayedText = widget.message.content;
      _isTyping = false;
      _currentCharIndex = widget.message.content.length;
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(AiMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If message content changed, restart typing animation only if it's a new message
    if (oldWidget.message.content != widget.message.content) {
      if (widget.isNewMessage) {
        _currentlyDisplayedText = '';
        _currentCharIndex = 0;
        _isTyping = true;
        _startTypingAnimation();
      } else {
        // For historical messages, show full content immediately
        _currentlyDisplayedText = widget.message.content;
        _isTyping = false;
        _currentCharIndex = widget.message.content.length;
      }
    }
  }

  void _startTypingAnimation() {
    const typingSpeed = Duration(milliseconds: 20); // Adjust speed as needed

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(typingSpeed, (timer) {
      if (_currentCharIndex < widget.message.content.length) {
        setState(() {
          _currentCharIndex++;
          _currentlyDisplayedText = widget.message.content.substring(0, _currentCharIndex);
        });
      } else {
        setState(() {
          _isTyping = false;
        });
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message row with avatar and content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              widget.showAvatar
                  ? Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.primary.withValues(alpha: 0.2), width: 1.5),
                      ),
                      child: Icon(Icons.psychology_rounded, size: 18, color: theme.primary),
                    )
                  : const SizedBox(width: 36),

              const SizedBox(width: 8),

              // Message content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.primary.withValues(alpha: 0.1), width: 1),
                    boxShadow: [BoxShadow(color: theme.primary.withValues(alpha: 0.05), offset: const Offset(0, 2), blurRadius: 8, spreadRadius: 0)],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show animated typing or collapsed content based on state
                      _isExpanded
                          ? _buildTypingMessageContent(theme)
                          : Text(
                              '${_currentlyDisplayedText.substring(0, math.min(100, _currentlyDisplayedText.length))}...',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary),
                            ),

                      // File attachment (if any)
                      if (widget.message.filePath != null) _buildFileAttachment(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Action buttons in a row below the message
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 8),
            child: Row(
              children: [
                // Button 1: Expand/collapse
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: _buildActionButton(
                    theme: theme,
                    icon: _isExpanded ? Icons.compress : Icons.expand,
                    label: _isExpanded ? 'Collapse' : 'Expand',
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ),

                // Button 2: Copy
                _buildActionButton(
                  theme: theme,
                  icon: Icons.copy_all,
                  label: 'Copy',
                  onPressed: () {
                    // Copy to clipboard (always use full message text, even if still typing)
                    final text = widget.message.content;
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Copied to clipboard', style: TextStyle(fontFamily: 'Poppins')),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        backgroundColor: theme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingMessageContent(OneUITheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated typing content
        MarkdownBody(
          data: _currentlyDisplayedText,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: theme.textPrimary, height: 1.5),
            h1: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: theme.textPrimary),
            h2: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary),
            h3: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: theme.textPrimary),
            code: TextStyle(fontFamily: 'monospace', fontSize: 13, backgroundColor: theme.isDark ? Colors.grey[800] : Colors.grey[200], color: theme.textPrimary),
            codeblockDecoration: BoxDecoration(
              color: theme.isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.primary.withValues(alpha: 0.3), width: 1),
            ),
          ),
          onTapLink: (text, href, title) {
            if (href != null) {
              launchUrl(Uri.parse(href));
            }
          },
        ),

        // Show typing indicator while typing
        if (_isTyping)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(children: [_buildTypingDot(0, theme), const SizedBox(width: 3), _buildTypingDot(1, theme), const SizedBox(width: 3), _buildTypingDot(2, theme)]),
          ),
      ],
    );
  }

  Widget _buildTypingDot(int index, OneUITheme theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Interval(index * 0.2, 1.0, curve: Curves.easeInOut),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -4 * math.sin(value * math.pi)),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: theme.primary, shape: BoxShape.circle),
          ),
        );
      },
    );
  }

  Widget _buildFileAttachment(OneUITheme theme) {
    final mimeType = widget.message.mimeType ?? '';
    final errorPlaceholderColor = theme.isDark ? Colors.grey[800]! : Colors.grey.shade200;

    if (mimeType.startsWith('image/')) {
      // Validate image path before attempting to load
      if (widget.message.filePath == null || widget.message.filePath!.trim().isEmpty) {
        return Container(
          height: 150,
          decoration: BoxDecoration(color: errorPlaceholderColor, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Icon(Icons.broken_image, size: 48, color: theme.textSecondary)),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.message.filePath!,
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
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          icon: Icon(Icons.attach_file, color: theme.primary),
          label: Text('View Attachment', style: TextStyle(color: theme.primary)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: theme.primary.withValues(alpha: 0.5))),
          onPressed: () {
            if (widget.message.filePath != null) {
              launchUrl(Uri.parse(widget.message.filePath!));
            }
          },
        ),
      );
    }
  }

  Widget _buildActionButton({required OneUITheme theme, required IconData icon, required String label, required Function()? onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withValues(alpha: 0.1), width: 1),
      ),
      child: TextButton.icon(
        icon: Icon(icon, size: 16, color: theme.primary),
        label: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Poppins', color: theme.primary),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.center,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
