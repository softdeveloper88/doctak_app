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

  const StreamingMessageBubble({
    Key? key,
    required this.partialContent,
    this.showAvatar = true,
    this.isComplete = false,
    this.onCopyPressed,
  }) : super(key: key);

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
    _typeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
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
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          if (widget.showAvatar)
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              radius: 18,
              child: Icon(
                Icons.medical_services_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
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
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Markdown content with animated typing effect
                      MarkdownBody(
                        data: _displayContent,
                        styleSheet: MarkdownStyleSheet(
                          p: theme.textTheme.bodyMedium!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                          h1: theme.textTheme.headlineSmall!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: theme.textTheme.titleLarge!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                          h3: theme.textTheme.titleMedium!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                          blockquote: theme.textTheme.bodyMedium!.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                          code: TextStyle(
                            fontFamily: 'monospace',
                            color: isDarkMode ? Colors.lightGreenAccent[100] : Colors.teal[700],
                            backgroundColor: isDarkMode
                                ? Colors.grey[850]
                                : Colors.grey[200],
                            fontSize: 14,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          listBullet: theme.textTheme.bodyMedium!.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                          em: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(Uri.parse(href));
                          }
                        },
                        selectable: widget.isComplete, // Only selectable when complete
                      ),

                      // Typing cursor animation when actively streaming
                      if (!widget.isComplete)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildTypingCursor(),
                        ),
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
                          child: InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: widget.partialContent));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Message copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              if (widget.onCopyPressed != null) widget.onCopyPressed!();
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      },
      // Repeat the animation forever
      onEnd: () => _buildTypingCursor(),
    );
  }
}