/// Shared helpers for post copy, hashtag stripping, and title/body deduplication.
class PostTextUtils {
  PostTextUtils._();

  static final RegExp _hashtagToken = RegExp(r'#[\w\u0600-\u06FF]+');

  static String stripHashtags(String? text) {
    if (text == null) return '';
    return text
        .replaceAll(_hashtagToken, '')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
  }

  static String normalizeForCompare(String? text) {
    return stripHashtags(text).replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool contentsEquivalent(String? a, String? b) {
    final left = normalizeForCompare(a);
    final right = normalizeForCompare(b);
    if (left.isEmpty && right.isEmpty) return true;
    return left.isNotEmpty && left == right;
  }

  static PostDisplayText resolveDisplay({
    required String? title,
    required String? body,
    required bool isPoll,
    String? pollDescription,
    required bool stripTagsFromText,
  }) {
    final trimmedTitle = title?.trim();
    final trimmedBody = body?.trim();
    final trimmedPollDesc = pollDescription?.trim();

    String? headline;
    String? mainText;

    if (isPoll) {
      if (trimmedBody != null && trimmedBody.isNotEmpty) {
        mainText = trimmedBody;
      } else if (trimmedPollDesc != null && trimmedPollDesc.isNotEmpty) {
        mainText = trimmedPollDesc;
      }
      if (trimmedTitle != null &&
          trimmedTitle.isNotEmpty &&
          !contentsEquivalent(trimmedTitle, mainText)) {
        headline = trimmedTitle;
      }
    } else if (trimmedTitle != null &&
        trimmedTitle.isNotEmpty &&
        trimmedBody != null &&
        trimmedBody.isNotEmpty) {
      if (contentsEquivalent(trimmedTitle, trimmedBody)) {
        mainText = trimmedBody;
      } else if (normalizeForCompare(trimmedBody).isNotEmpty &&
          normalizeForCompare(trimmedTitle)
              .contains(normalizeForCompare(trimmedBody))) {
        mainText = trimmedTitle;
      } else if (normalizeForCompare(trimmedTitle).isNotEmpty &&
          normalizeForCompare(trimmedBody)
              .contains(normalizeForCompare(trimmedTitle))) {
        headline = trimmedTitle;
        mainText = trimmedBody;
      } else {
        headline = trimmedTitle;
        mainText = trimmedBody;
      }
    } else {
      mainText = (trimmedBody != null && trimmedBody.isNotEmpty)
          ? trimmedBody
          : trimmedTitle;
    }

    if (stripTagsFromText) {
      if (headline != null) {
        final strippedHeadline = stripHashtags(headline);
        headline = strippedHeadline.isEmpty ? null : strippedHeadline;
      }
      if (mainText != null) {
        final stripped = stripHashtags(mainText);
        mainText = stripped.isEmpty ? null : stripped;
      }
    }

    return PostDisplayText(headline: headline, mainText: mainText);
  }
}

class PostDisplayText {
  final String? headline;
  final String? mainText;

  const PostDisplayText({this.headline, this.mainText});
}
