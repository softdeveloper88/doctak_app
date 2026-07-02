import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Renders plain text with `#hashtags` styled in the accent color.
class HashtagRichText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final void Function(String tag)? onHashtagTap;

  const HashtagRichText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.onHashtagTap,
  });

  static final RegExp _hashtag = RegExp(r'#[\w\u0600-\u06FF]+');

  static List<InlineSpan> buildSpans({
    required String raw,
    required TextStyle baseStyle,
    required TextStyle tagStyle,
    void Function(String tag)? onHashtagTap,
  }) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _hashtag.allMatches(raw)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: raw.substring(cursor, match.start)));
      }
      final token = match.group(0) ?? '';
      spans.add(
        TextSpan(
          text: token,
          style: tagStyle,
          recognizer: onHashtagTap == null
              ? null
              : (TapGestureRecognizer()..onTap = () => onHashtagTap(token)),
        ),
      );
      cursor = match.end;
    }
    if (cursor < raw.length) {
      spans.add(TextSpan(text: raw.substring(cursor)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final theme = OneUITheme.of(context);
    final baseStyle = style ?? theme.bodyMedium;
    final tagStyle = baseStyle.copyWith(
      color: theme.primary,
      fontWeight: FontWeight.w600,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: buildSpans(
          raw: text,
          baseStyle: baseStyle,
          tagStyle: tagStyle,
          onHashtagTap: onHashtagTap,
        ),
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Live preview shown under compose fields when the user types hashtags.
class HashtagComposePreview extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const HashtagComposePreview({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (!HashtagRichText._hashtag.hasMatch(text)) {
      return const SizedBox.shrink();
    }

    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: HashtagRichText(
        text: text,
        style: style ?? theme.bodyMedium.copyWith(fontSize: 15),
      ),
    );
  }
}
