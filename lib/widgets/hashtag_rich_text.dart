import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';

/// Renders plain text with `#hashtags` and `http(s)` URLs styled as tappable links.
class HashtagRichText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final void Function(String tag)? onHashtagTap;
  final void Function(String url)? onUrlTap;

  const HashtagRichText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.onHashtagTap,
    this.onUrlTap,
  });

  static final RegExp _hashtag = RegExp(r'#[\w\u0600-\u06FF]+');
  // Match common URL forms, including share.google / goo.gl style links.
  static final RegExp _url = RegExp(
    r'(https?:\/\/[^\s<>\[\]\(\)"]+)|(www\.[^\s<>\[\]\(\)"]+)',
    caseSensitive: false,
  );
  static final RegExp _token = RegExp(
    r'(https?:\/\/[^\s<>\[\]\(\)"]+|www\.[^\s<>\[\]\(\)"]+|#[\w\u0600-\u06FF]+)',
    caseSensitive: false,
  );

  static Future<void> openExternalUrl(String raw) async {
    var value = raw.trim();
    // Strip trailing punctuation commonly copied with links.
    value = value.replaceFirst(RegExp(r'[.,;:!?)\]\}>]+$'), '');
    if (value.isEmpty) return;
    final uri = Uri.tryParse(
      RegExp(r'^https?:', caseSensitive: false).hasMatch(value)
          ? value
          : 'https://$value',
    );
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      // Ignore — feed should never crash on a bad URL.
    }
  }

  static List<InlineSpan> buildSpans({
    required String raw,
    required TextStyle baseStyle,
    required TextStyle tagStyle,
    required TextStyle linkStyle,
    void Function(String tag)? onHashtagTap,
    void Function(String url)? onUrlTap,
  }) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _token.allMatches(raw)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: raw.substring(cursor, match.start)));
      }
      final token = match.group(0) ?? '';
      if (_hashtag.hasMatch(token) && token.startsWith('#')) {
        spans.add(
          TextSpan(
            text: token,
            style: tagStyle,
            recognizer: onHashtagTap == null
                ? null
                : (TapGestureRecognizer()..onTap = () => onHashtagTap(token)),
          ),
        );
      } else if (_url.hasMatch(token)) {
        spans.add(
          TextSpan(
            text: token,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (onUrlTap != null) {
                  onUrlTap(token);
                } else {
                  openExternalUrl(token);
                }
              },
          ),
        );
      } else {
        spans.add(TextSpan(text: token));
      }
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
    final linkStyle = baseStyle.copyWith(
      color: theme.primary,
      decoration: TextDecoration.underline,
      decorationColor: theme.primary.withValues(alpha: 0.45),
      fontWeight: FontWeight.w500,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: buildSpans(
          raw: text,
          baseStyle: baseStyle,
          tagStyle: tagStyle,
          linkStyle: linkStyle,
          onHashtagTap: onHashtagTap,
          onUrlTap: onUrlTap,
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
    if (!HashtagRichText._hashtag.hasMatch(text) &&
        !HashtagRichText._url.hasMatch(text)) {
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
