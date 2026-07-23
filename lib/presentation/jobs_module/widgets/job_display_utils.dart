import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class JobDisplayUtils {
  /// Safely opens [url] externally (CV downloads, external apply links,
  /// promo checkout, etc). Never throws — on failure it shows a toast
  /// instead of letting an uncaught [PlatformException] crash the app
  /// (e.g. `ACTIVITY_NOT_FOUND` when no app can handle the link).
  static Future<void> openExternalUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      toast('Link unavailable');
      return;
    }
    // API often returns host-relative media paths (/profile-media/cvs/...).
    // Resolve those onto the R2/media base before handing to the OS.
    final resolved = AppData.fullImageUrl(url.trim());
    final uri = Uri.tryParse(resolved.isNotEmpty ? resolved : url.trim());
    if (uri == null ||
        !(uri.hasScheme &&
            (uri.scheme == 'http' ||
                uri.scheme == 'https' ||
                uri.scheme == 'mailto' ||
                uri.scheme == 'tel'))) {
      toast('Invalid link');
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        toast('Couldn’t open link');
      }
    }
  }

  static String jobTypeLabel(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'full_time':
      case 'full-time':
        return 'Full-time';
      case 'part_time':
      case 'part-time':
        return 'Part-time';
      case 'contract':
        return 'Contract';
      case 'locum':
        return 'Locum';
      case 'internship':
        return 'Internship';
      default:
        if (raw == null || raw.isEmpty) return 'Role';
        return raw.replaceAll('_', ' ');
    }
  }

  static String locationLine(JobCardDto job) {
    final parts = <String>[
      if (job.location != null && job.location!.trim().isNotEmpty)
        job.location!.trim(),
      if (job.country != null && job.country!.trim().isNotEmpty)
        job.country!.trim(),
    ];
    return parts.isEmpty ? 'Location flexible' : parts.join(' · ');
  }

  static String relativePosted(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  /// Card header time — relative post time plus year when available.
  static String postedTimeLabel(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final rel = relativePosted(iso);
    final dt = DateTime.tryParse(iso);
    if (dt == null || rel.isEmpty) return rel;
    return '$rel · ${dt.toLocal().year}';
  }

  static String formatExperience(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final exp = raw.trim();
    if (RegExp(r'year', caseSensitive: false).hasMatch(exp)) return exp;
    final num = int.tryParse(exp);
    if (num != null) return '$exp year${num == 1 ? '' : 's'}';
    return exp;
  }

  static String? expiryLabel({required int? daysLeft, required bool isExpired}) {
    if (isExpired || (daysLeft != null && daysLeft < 0)) return 'Expired';
    if (daysLeft == null) return null;
    if (daysLeft == 0) return 'Closes today';
    return '${daysLeft}d left';
  }

  static Color expiryColor(
    OneUITheme theme, {
    required int? daysLeft,
    required bool isExpired,
  }) {
    if (isExpired || (daysLeft != null && daysLeft < 0)) return theme.error;
    if (daysLeft != null && daysLeft <= 7) return theme.warning;
    return theme.success;
  }

  /// Human-friendly absolute+relative date, e.g. "15 Jul 2026 · 2h ago".
  /// Falls back gracefully instead of ever showing a raw ISO string.
  static String friendlyDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = '${local.day} ${months[local.month - 1]} ${local.year}';
    final rel = relativePosted(iso);
    return rel.isEmpty ? date : '$date · $rel';
  }

  /// Formats a raw salary number/string with thousands separators, e.g.
  /// "100000" → "100,000" and leaves already-formatted ranges untouched.
  static String salaryLabel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final trimmed = raw.trim();
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      return _withThousands(trimmed);
    }
    // Range like "100000-150000" or "100000 - 150000".
    final rangeMatch = RegExp(r'^(\d+)\s*-\s*(\d+)$').firstMatch(trimmed);
    if (rangeMatch != null) {
      return '${_withThousands(rangeMatch.group(1)!)} - ${_withThousands(rangeMatch.group(2)!)}';
    }
    return trimmed;
  }

  static String _withThousands(String digits) {
    final buffer = StringBuffer();
    final reversed = digits.split('').reversed.toList();
    for (var i = 0; i < reversed.length; i++) {
      if (i != 0 && i % 3 == 0) buffer.write(',');
      buffer.write(reversed[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  static Color stageColor(OneUITheme theme, String stage) {
    switch (stage) {
      case 'shortlisted':
      case 'offer':
      case 'accepted':
        return theme.success;
      case 'interview':
        return theme.warning;
      case 'rejected':
        return theme.error;
      case 'reviewed':
        return theme.textSecondary;
      default:
        return theme.primary;
    }
  }

  /// Turns raw application answer values into readable text (no `[...]` braces).
  static String formatAnswerValue(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is num) return value.toString();
    if (value is List) {
      return value
          .map(formatAnswerValue)
          .where((s) => s.trim().isNotEmpty)
          .join(', ');
    }
    if (value is Map) {
      if (value.containsKey('value')) {
        return formatAnswerValue(value['value']);
      }
      if (value.containsKey('label') && value.containsKey('text')) {
        return formatAnswerValue(value['text']);
      }
      return value.entries
          .map((e) => '${e.key}: ${formatAnswerValue(e.value)}')
          .join(', ');
    }

    var text = value.toString().trim();
    if (text.isEmpty) return '';

    // JSON / Dart list string: ["React", "Flutter"] or [skill text]
    if (text.startsWith('[') && text.endsWith(']')) {
      final inner = text.substring(1, text.length - 1).trim();
      if (inner.isEmpty) return '';
      if (!inner.contains('{') && !inner.contains('\n')) {
        final parts = _splitListish(inner);
        if (parts.isNotEmpty) return parts.join(', ');
      }
    }

    // JSON-encoded string
    if ((text.startsWith('"') && text.endsWith('"')) ||
        (text.startsWith("'") && text.endsWith("'"))) {
      text = text.substring(1, text.length - 1);
    }

    return text;
  }

  static List<String> _splitListish(String inner) {
    final parts = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    var quote = '';

    for (var i = 0; i < inner.length; i++) {
      final ch = inner[i];
      if (!inQuotes && (ch == '"' || ch == "'")) {
        inQuotes = true;
        quote = ch;
        continue;
      }
      if (inQuotes && ch == quote) {
        inQuotes = false;
        quote = '';
        continue;
      }
      if (!inQuotes && ch == ',') {
        final piece = buf.toString().trim();
        if (piece.isNotEmpty) parts.add(piece);
        buf.clear();
        continue;
      }
      buf.write(ch);
    }
    final last = buf.toString().trim();
    if (last.isNotEmpty) parts.add(last);
    return parts;
  }

  /// Splits a formatted answer into chip-friendly items when appropriate.
  static List<String> answerChips(String formatted) {
    final trimmed = formatted.trim();
    if (trimmed.isEmpty) return const [];
    if (!trimmed.contains(',')) return [trimmed];
    final parts = trimmed
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.length < 2) return [trimmed];
    // Only chip-ify short skill-like tags (avoid splitting sentences).
    if (parts.every((p) => p.length <= 40) && parts.length <= 12) {
      return parts;
    }
    return [trimmed];
  }

  static String humanizeFieldLabel(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return 'Answer';
    return t
        .replaceAll(RegExp(r'^(custom_|field_)'), '')
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
  }
}
