import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/hashtag_rich_text.dart';
import 'package:flutter/material.dart';

/// Collapses long post copy with localized **See more** / **See less** toggles.
///
/// Uses a lightweight length heuristic instead of [TextPainter] so scrolling
/// does not trigger per-card layout work and [setState] bursts.
class ExpandablePostText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int collapsedMaxLines;
  final EdgeInsetsGeometry? padding;
  final bool highlightHashtags;

  const ExpandablePostText({
    super.key,
    required this.text,
    this.style,
    this.collapsedMaxLines = 4,
    this.padding,
    this.highlightHashtags = true,
  });

  static String plainText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.contains('<')) return trimmed;
    return trimmed
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  @override
  State<ExpandablePostText> createState() => _ExpandablePostTextState();
}

class _ExpandablePostTextState extends State<ExpandablePostText> {
  bool _expanded = false;

  String get _displayText => ExpandablePostText.plainText(widget.text);

  /// Rough estimate — avoids synchronous layout during scroll.
  bool get _likelyOverflows {
    if (_displayText.isEmpty) return false;
    final explicitLines = '\n'.allMatches(_displayText).length + 1;
    if (explicitLines > widget.collapsedMaxLines) return true;
    const charsPerLine = 44;
    return _displayText.length > widget.collapsedMaxLines * charsPerLine;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    if (_displayText.isEmpty) return const SizedBox.shrink();

    final theme = OneUITheme.of(context);
    final l10n = translation(context);
    final bodyStyle = widget.style ?? theme.bodyMedium;
    final linkStyle = bodyStyle.copyWith(
      color: theme.primary,
      fontWeight: FontWeight.w600,
    );
    final showToggle = _likelyOverflows || _expanded;

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.highlightHashtags
              ? HashtagRichText(
                  text: _displayText,
                  style: bodyStyle,
                  maxLines: _expanded ? null : widget.collapsedMaxLines,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                )
              : Text(
                  _displayText,
                  style: bodyStyle,
                  maxLines: _expanded ? null : widget.collapsedMaxLines,
                  overflow:
                      _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
          if (showToggle) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _toggle,
              behavior: HitTestBehavior.opaque,
              child: Text(
                _expanded ? l10n.lbl_show_less : l10n.lbl_see_more,
                style: linkStyle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
