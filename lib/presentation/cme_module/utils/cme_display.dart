import 'dart:convert';

/// Parse learning objectives stored as JSON array, newline list, or plain text.
List<String> parseCmeLearningObjectives(String? value) {
  if (value == null) return [];
  final trimmed = value.trim();
  if (trimmed.isEmpty) return [];

  if (trimmed.startsWith('[')) {
    try {
      final parsed = jsonDecode(trimmed);
      if (parsed is List) {
        return parsed
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {
      /* fall through */
    }
  }

  return trimmed
      .split(RegExp(r'\n|;'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}
