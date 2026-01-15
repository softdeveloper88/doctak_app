import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class StreamingMessageBubble extends StatefulWidget {
  final String partialContent;
  final bool showAvatar;
  final bool isComplete;
  final VoidCallback? onCopyPressed;

  const StreamingMessageBubble({super.key, required this.partialContent, this.showAvatar = true, this.isComplete = false, this.onCopyPressed});

  @override
  State<StreamingMessageBubble> createState() => _StreamingMessageBubbleState();
}

class _StreamingMessageBubbleState extends State<StreamingMessageBubble> with SingleTickerProviderStateMixin {
  late String _displayContent;
  int _currentPosition = 0;
  late AnimationController _typeController;
  Timer? _typeTimer;

  @override
  void initState() {
    super.initState();
    _displayContent = '';
    _typeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _processIncomingContent();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _typeTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(StreamingMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If content changed, update display
    if (widget.partialContent != oldWidget.partialContent) {
      _processIncomingContent();
    }
  }

  // Process and animate incoming content
  void _processIncomingContent() {
    // If we already have all the content displayed, just update directly
    if (_displayContent.length >= widget.partialContent.length) {
      setState(() {
        _displayContent = widget.partialContent;
      });
      return;
    }

    // Cancel any existing typing animation
    _typeTimer?.cancel();

    // Start from current position and animate typing the rest
    _currentPosition = _displayContent.length;

    // Define typing speed based on content length
    // Faster typing for longer content, but maintain readability
    final int charsToAdd = widget.partialContent.length - _currentPosition;
    if (charsToAdd > 0) {
      // Use a timer to add characters incrementally
      _typeTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
        if (_currentPosition < widget.partialContent.length) {
          setState(() {
            _displayContent = widget.partialContent.substring(0, _currentPosition + 1);
            _currentPosition++;
          });
        } else {
          timer.cancel();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          if (widget.showAvatar)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Icon(Icons.psychology_rounded, size: 18, color: Colors.blue[600]),
            )
          else
            const SizedBox(width: 36), // Same width as avatar for alignment

          const SizedBox(width: 8),

          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message bubble
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.1), width: 1),
                    boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.05), offset: const Offset(0, 2), blurRadius: 8, spreadRadius: 0)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Markdown content with animated typing effect
                      MarkdownBody(
                        data: _displayContent,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.black87, height: 1.5),
                          h1: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          h2: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          h3: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          blockquote: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
                          code: const TextStyle(fontFamily: 'monospace', color: Colors.teal, backgroundColor: Colors.grey, fontSize: 13),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue, width: 1),
                          ),
                          listBullet: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.black87),
                          strong: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                          em: const TextStyle(fontStyle: FontStyle.italic, fontFamily: 'Poppins'),
                        ),
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                        selectable: widget.isComplete, // Only selectable when complete
                      ),

                      // Typing cursor animation when actively streaming
                      if (!widget.isComplete) Padding(padding: const EdgeInsets.only(top: 4), child: _buildTypingCursor()),
                    ],
                  ),
                ),

                // Action buttons - only show when complete
                if (widget.isComplete && widget.partialContent.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Copy button
                        Material(
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.1), width: 1),
                            ),
                            child: InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: widget.partialContent));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Message copied to clipboard', style: TextStyle(fontFamily: 'Poppins')),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.blue[600],
                                  ),
                                );
                                if (widget.onCopyPressed != null) widget.onCopyPressed!();
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy, size: 16, color: Colors.blue[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Copy',
                                      style: TextStyle(fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Colors.blue[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Animated typing cursor
  Widget _buildTypingCursor() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value < 0.5 ? 1 : 0, // Blink effect
          child: Container(
            width: 8,
            height: 16,
            decoration: BoxDecoration(color: Colors.blue[600], borderRadius: BorderRadius.circular(2)),
          ),
        );
      },
      // Repeat the animation forever
      onEnd: () => _buildTypingCursor(),
    );
  }
}
