import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/ai_chat_model/ai_chat_message_model.dart';

class AiMessageBubble extends StatefulWidget {
  final AiChatMessageModel message;
  final bool showAvatar;
  final Function(String feedback) onFeedbackSubmitted;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    required this.onFeedbackSubmitted,
  });

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
    _startTypingAnimation();
  }
  
  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(AiMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If message content changed, restart typing animation
    if (oldWidget.message.content != widget.message.content) {
      _currentlyDisplayedText = '';
      _currentCharIndex = 0;
      _isTyping = true;
      _startTypingAnimation();
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
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
                ? CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    radius: 18,
                    child: Icon(
                      Icons.medical_services_rounded,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ) 
                : const SizedBox(width: 36),

              const SizedBox(width: 8),

              // Message content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show animated typing or collapsed content based on state
                      _isExpanded 
                        ? _buildTypingMessageContent() 
                        : Text(
                            '${_currentlyDisplayedText.substring(0, math.min(100, _currentlyDisplayedText.length))}...',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                    
                      // File attachment (if any)
                      if (widget.message.filePath != null)
                        _buildFileAttachment(),
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
                    icon: _isExpanded ? Icons.compress : Icons.expand,
                    label: _isExpanded ? 'Collapse' : 'Expand',
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    iconColor: Colors.black,
                  ),
                ),

                // Button 2: Copy
                _buildActionButton(
                  icon: Icons.copy_all,
                  label: 'Copy',
                  onPressed: () {
                    // Copy to clipboard (always use full message text, even if still typing)
                    final text = widget.message.content;
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  iconColor: Colors.black,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypingMessageContent() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated typing content
        MarkdownBody(
          data: _currentlyDisplayedText,
          styleSheet: MarkdownStyleSheet(
            p: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
            h1: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            h2: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            h3: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            code: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              backgroundColor: Theme.of(context).colorScheme.surface,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            codeblockDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
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
            child: Row(
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 3),
                _buildTypingDot(1),
                const SizedBox(width: 3),
                _buildTypingDot(2),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildTypingDot(int index) {
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFileAttachment() {
    final mimeType = widget.message.mimeType ?? '';
    
    if (mimeType.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.message.filePath!,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: const Text('View Attachment'),
          onPressed: () {
            if (widget.message.filePath != null) {
              launchUrl(Uri.parse(widget.message.filePath!));
            }
          },
        ),
      );
    }
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Function()? onPressed,
    bool isActive = false,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = iconColor ?? (isActive ? colorScheme.primary : Colors.black);
    
    return TextButton.icon(
      icon: Icon(
        icon,
        size: 20,
        color: buttonColor,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: buttonColor,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.center,
      ),
      onPressed: onPressed,
    );
  }
}