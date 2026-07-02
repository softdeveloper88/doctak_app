import 'package:doctak_app/presentation/guideline_module/data/models/guideline_chat_model.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

/// A single chat message bubble for the guideline chat.
class GuidelineMessageBubble extends StatelessWidget {
  final GuidelineChatMessage message;
  final Function(String rating)? onFeedback;

  /// When non-null, this is a streaming bubble showing partial content.
  /// The bubble hides action buttons and shows a blinking cursor.
  final String? streamingContent;

  const GuidelineMessageBubble({
    super.key,
    required this.message,
    this.onFeedback,
    this.streamingContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    if (message.isUser) {
      return _buildUserBubble(context, theme);
    }
    return _buildAssistantBubble(context, theme);
  }

  Widget _buildUserBubble(BuildContext context, OneUITheme theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 6, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A84FF),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A84FF).withValues(alpha:0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context, OneUITheme theme) {
    final isStreaming = streamingContent != null;
    final displayContent = streamingContent ?? message.content;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 6, right: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + label
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/logo/logo.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Medical guidelines assistant',
                    style: TextStyle(
                      color: theme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Message content
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: theme.border,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Markdown content
                  MarkdownBody(
                    data: displayContent,
                    selectable: !isStreaming,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                      h1: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      h2: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      h3: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      strong: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      em: TextStyle(
                        color: theme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      listBullet: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                      ),
                      code: TextStyle(
                        color: const Color(0xFF0A84FF),
                        backgroundColor:
                            const Color(0xFF0A84FF).withValues(alpha:0.08),
                        fontSize: 13,
                      ),
                      blockquote: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: const Color(0xFF0A84FF).withValues(alpha:0.5),
                            width: 3,
                          ),
                        ),
                      ),
                      tableBorder: TableBorder.all(
                        color: theme.border,
                        width: 0.5,
                      ),
                      tableHead: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tableBody: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 13,
                      ),
                      tableHeadAlign: TextAlign.left,
                      tableCellsPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                    ),
                    onTapLink: (text, href, title) {
                      if (href != null) {
                        launchUrl(Uri.parse(href),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                  ),

                  // Blinking cursor during streaming
                  if (isStreaming) ...[
                    const SizedBox(height: 4),
                    _BlinkingCursor(),
                  ],

                  // Action buttons (hidden during streaming)
                  if (!isStreaming) ...[
                    // Sources used (matching web sidebar "Sources Used")
                    if (message.sources.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildSourcesSection(context, theme, message.sources),
                    ],
                    const SizedBox(height: 10),
                    Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.copy_rounded,
                        tooltip: 'Copy',
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: message.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Copied to clipboard'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      if (onFeedback != null) ...[
                        const SizedBox(width: 4),
                        _buildActionButton(
                          context,
                          icon: Icons.thumb_up_outlined,
                          tooltip: 'Helpful',
                          isActive: message.rating == 1,
                          activeColor: const Color(0xFF34C759),
                          onTap: () => onFeedback!('positive'),
                        ),
                        const SizedBox(width: 4),
                        _buildActionButton(
                          context,
                          icon: Icons.thumb_down_outlined,
                          tooltip: 'Not helpful',
                          isActive: message.rating == -1,
                          activeColor: const Color(0xFFFF3B30),
                          onTap: () => onFeedback!('negative'),
                        ),
                      ],
                    ],
                  ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourcesSection(
    BuildContext context,
    OneUITheme theme,
    List<Map<String, dynamic>> sources,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0A84FF).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF0A84FF).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined,
                  size: 13, color: const Color(0xFF0A84FF)),
              const SizedBox(width: 4),
              Text(
                'Sources Used',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0A84FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...sources.map((source) {
            final name = source['source']?.toString() ??
                source['name']?.toString() ??
                source['title']?.toString() ??
                'Unknown Source';
            final url = source['url']?.toString();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                onTap: url != null
                    ? () => launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication)
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 5,
                      color: theme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 11,
                          color: url != null
                              ? const Color(0xFF0A84FF)
                              : theme.textSecondary,
                          decoration: url != null
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    final theme = OneUITheme.of(context);
    final color = isActive
        ? (activeColor ?? const Color(0xFF0A84FF))
        : theme.textSecondary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

/// A small blinking cursor shown at the end of streaming text.
class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFF0A84FF),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
