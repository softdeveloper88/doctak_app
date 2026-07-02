import 'dart:convert';

/// Strip HTML tags and decode common entities for conference excerpts.
String conferencePlainText(String? value) {
  if (value == null || value.trim().isEmpty) return '';

  var text = value;
  if (_isProbablyHtmlContent(text)) {
    text = text
        .replaceAll(RegExp(r'<[^>]*>', multiLine: true), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }

  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _isProbablyHtmlContent(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  if (RegExp(r'</?[a-z][\w:-]*(?:\s[^>]*)?>', caseSensitive: false).hasMatch(trimmed)) {
    return true;
  }
  if (RegExp(r'&lt;/?[a-z][\w:-]*', caseSensitive: false).hasMatch(trimmed)) {
    return true;
  }
  return false;
}

bool conferenceIsHtmlContent(String? value) => _isProbablyHtmlContent(value ?? '');

/// Parse specialties / call-for-papers stored as JSON, HTML, or delimited text.
List<String> parseConferenceTopics(String? text) {
  if (text == null || text.trim().isEmpty) return [];

  var trimmed = text.trim();
  if (_isProbablyHtmlContent(trimmed)) {
    trimmed = conferencePlainText(trimmed);
  }

  final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(trimmed);
  final jsonCandidate = jsonMatch?.group(0) ?? trimmed;

  if (jsonCandidate.startsWith('[')) {
    try {
      final parsed = jsonDecode(jsonCandidate);
      if (parsed is List) {
        final topics = parsed
            .map((item) {
              if (item is String) return item.trim();
              if (item is Map) {
                final value = item['value'] ?? item['name'] ?? item['label'] ?? item['title'];
                if (value != null) return value.toString().trim();
              }
              return item?.toString().trim() ?? '';
            })
            .where((topic) => topic.isNotEmpty)
            .toList();
        if (topics.isNotEmpty) return topics;
      }
    } catch (_) {
      // Fall through to plain-text parsing.
    }
  }

  final plain = conferencePlainText(trimmed);
  if (plain.isEmpty) return [];

  return plain
      .split(RegExp(r'\||,'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

String conferenceTopicsLabel(List<String> topics, {int maxLength = 180}) {
  if (topics.isEmpty) return '';
  final joined = topics.join(', ');
  if (joined.length <= maxLength) return joined;
  return '${joined.substring(0, maxLength - 1).trim()}…';
}

String conferenceTopicsPreview(String? text, {int maxLength = 180}) {
  return conferenceTopicsLabel(parseConferenceTopics(text), maxLength: maxLength);
}

String conferenceExcerpt(String? text, {int maxLength = 160}) {
  final plain = conferencePlainText(text);
  if (plain.isEmpty) return '';
  if (plain.length <= maxLength) return plain;
  return '${plain.substring(0, maxLength).trim()}…';
}

String conferenceLocationLabel({
  String? location,
  String? city,
  String? state,
  String? country,
  String? countryName,
}) {
  if (location != null && location.trim().isNotEmpty) return location.trim();
  final resolvedCountry = (countryName?.trim().isNotEmpty == true)
      ? countryName!.trim()
      : country?.trim();
  return [
    city?.trim(),
    state?.trim(),
    resolvedCountry,
  ].whereType<String>().where((part) => part.isNotEmpty).join(', ');
}

String conferenceCountryFilterValue(dynamic item) {
  if (item is Map) {
    final id = item['id'] ?? item['country_id'];
    if (id != null && id.toString().trim().isNotEmpty) {
      return id.toString();
    }
    return (item['name'] ?? item['countryName'] ?? item['country_name'] ?? '').toString();
  }
  return item?.toString() ?? '';
}

String conferenceCountryDisplayName(dynamic item) {
  if (item is Map) {
    final name = item['name'] ?? item['countryName'] ?? item['country_name'];
    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString();
    }
    return conferenceCountryFilterValue(item);
  }
  return item?.toString() ?? '';
}

String conferenceCountryNameFromList(List<dynamic> list, String filterValue) {
  if (filterValue.isEmpty || filterValue == 'all') return 'All';
  for (final item in list) {
    if (conferenceCountryFilterValue(item) == filterValue) {
      return conferenceCountryDisplayName(item);
    }
  }
  return filterValue;
}
