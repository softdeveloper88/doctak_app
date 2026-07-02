import 'dart:convert';

import 'package:doctak_app/core/utils/post_text_utils.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';

/// Resolved post card copy — prefers server `display*` fields (same as web).
class ResolvedFeedPostDisplay {
  final String? headline;
  final String? mainText;
  final List<String> tags;
  final bool highlightHashtags;

  const ResolvedFeedPostDisplay({
    this.headline,
    this.mainText,
    this.tags = const [],
    this.highlightHashtags = true,
  });
}

class FeedPostDisplay {
  FeedPostDisplay._();

  static List<String> parseTags(FeedItem item) {
    final tokens = <String>[];
    final seen = <String>{};

    void addToken(String raw) {
      var token = raw.trim();
      if (token.isEmpty) return;
      token = token.replaceFirst(RegExp(r'^#+'), '');
      if (token.isEmpty) return;
      final key = token.toLowerCase();
      if (seen.contains(key)) return;
      seen.add(key);
      tokens.add('#$token');
    }

    void absorb(dynamic value) {
      if (value == null) return;
      if (value is List) {
        for (final entry in value) {
          absorb(entry);
        }
        return;
      }
      final text = value.toString().trim();
      if (text.isEmpty || text == '[]') return;
      if (text.startsWith('[') && text.endsWith(']')) {
        try {
          final decoded = jsonDecode(text);
          if (decoded is List) {
            absorb(decoded);
            return;
          }
        } catch (_) {}
      }
      for (final part in text.split(RegExp(r'[\s,]+'))) {
        addToken(part);
        if (tokens.length >= 5) return;
      }
    }

    absorb(item.payload['tags']);

    if (tokens.isEmpty) {
      final haystack = '${item.str('body') ?? ''} ${item.str('title') ?? ''}';
      for (final match
          in RegExp(r'#([\w\u0600-\u06FF]+)').allMatches(haystack)) {
        addToken(match.group(1) ?? '');
        if (tokens.length >= 5) break;
      }
    }

    return tokens.take(5).toList();
  }

  static ResolvedFeedPostDisplay resolve(
    FeedItem item, {
    required bool isPoll,
    String? pollDescription,
  }) {
    final tags = parseTags(item);
    final serverHeadline = item.str('displayTitle');
    final serverBody = item.str('displayBody');

    if (serverHeadline != null || serverBody != null) {
      return ResolvedFeedPostDisplay(
        headline: serverHeadline,
        mainText: serverBody,
        tags: tags,
        highlightHashtags: item.payload['highlightHashtagsInBody'] != false &&
            tags.isEmpty,
      );
    }

    final display = PostTextUtils.resolveDisplay(
      title: item.str('title'),
      body: item.str('body'),
      isPoll: isPoll,
      pollDescription: pollDescription,
      stripTagsFromText: tags.isNotEmpty,
    );

    return ResolvedFeedPostDisplay(
      headline: display.headline,
      mainText: display.mainText,
      tags: tags,
      highlightHashtags: tags.isEmpty,
    );
  }
}
