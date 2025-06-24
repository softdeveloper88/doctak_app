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
  final bool isNewMessage;

  const AiMessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    required this.onFeedbackSubmitted,
    this.isNewMessage = false,
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
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      size: 18,
                      color: Colors.blue[600],
                    ),
                  ) 
                : const SizedBox(width: 36),

              const SizedBox(width: 8),

              // Message content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.05),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
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
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.black87,
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
                    iconColor: Colors.blue[600]!,
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
                      SnackBar(
                        content: const Text(
                          'Copied to clipboard',
                          style: TextStyle(fontFamily: 'Poppins'),
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.blue[600],
                      ),
                    );
                  },
                  iconColor: Colors.blue[600]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypingMessageContent() {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated typing content
        MarkdownBody(
          data: _currentlyDisplayedText,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
            h1: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            h2: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            h3: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            code: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              backgroundColor: Colors.grey,
              color: Colors.black87,
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue,
                width: 1,
              ),
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
              color: Colors.blue,
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
    final buttonColor = iconColor ?? Colors.blue[600]!;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextButton.icon(
        icon: Icon(
          icon,
          size: 16,
          color: buttonColor,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
            color: buttonColor,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.center,
        ),
        onPressed: onPressed,
      ),
    );
  }
}