import 'package:flutter/material.dart';

const _avatarColors = [
  Color(0xFFDC2626),
  Color(0xFF0D9488),
  Color(0xFF1558D6),
  Color(0xFF7C3AED),
  Color(0xFFB45309),
  Color(0xFFBE123C),
  Color(0xFF15803D),
  Color(0xFF1D4ED8),
];

Color avatarColorFromName(String name) {
  var hash = 0;
  for (var i = 0; i < name.length; i++) {
    hash = (hash + name.codeUnitAt(i) * (i + 1)) % _avatarColors.length;
  }
  return _avatarColors[hash];
}

String authorInitials(String name) {
  return name
      .split(' ')
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}

class CaseTagStyle {
  final Color background;
  final Color foreground;
  final bool uppercase;

  const CaseTagStyle({
    required this.background,
    required this.foreground,
    this.uppercase = true,
  });
}

CaseTagStyle caseTagStyle(String tag) {
  final normalized = tag.trim().toLowerCase().replaceAll('_', ' ');
  if (normalized.contains('urgent') || normalized.contains('critical')) {
    return const CaseTagStyle(
      background: Color(0xFFFEE2E2),
      foreground: Color(0xFFDC2626),
    );
  }
  if (normalized == 'open') {
    return const CaseTagStyle(
      background: Color(0xFFEFF6FF),
      foreground: Color(0xFF1558D6),
    );
  }
  if (normalized.contains('cme')) {
    return const CaseTagStyle(
      background: Color(0xFFFEFCE8),
      foreground: Color(0xFF854D0E),
      uppercase: false,
    );
  }
  if (normalized.contains('resolved')) {
    return const CaseTagStyle(
      background: Color(0xFFECFDF5),
      foreground: Color(0xFF047857),
    );
  }
  return const CaseTagStyle(
    background: Color(0xFFF1F5F9),
    foreground: Color(0xFF1A2236),
    uppercase: false,
  );
}

String formatClinicalList(String? value) {
  if (value == null || value.isEmpty) return '';
  return value
      .replaceAll(' - ', ' · ')
      .replaceAll(' -', ' ·')
      .replaceAll('- ', '· ')
      .replaceAll(',', ' ·');
}
