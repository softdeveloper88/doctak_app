import 'package:flutter/material.dart';

/// DocTak web design tokens (`doctak-node/assets/css/doctak.css` --dt-*).
/// Single source of truth — reference these from [OneUITheme], not hardcoded hex in widgets.
abstract final class DoctakPalette {
  // ── Light mode surfaces ───────────────────────────────────────────────
  /// Page / scaffold background (`--dt-bg` / `--bg`).
  static const Color bg = Color(0xFFF7F5F0);

  /// Soft warm glow behind auth header (`--accent-50` in standalone auth mock).
  static const Color authGlow = Color(0xFFFEF6EA);

  /// Cards, elevated panels (`--dt-surface`).
  static const Color surface = Color(0xFFFFFFFF);

  /// TextField / search field fill (app-wide).
  static const Color inputFill = Color(0xFFFAF8F2);

  /// Soft panels, drawer header (`--dt-surface-soft`).
  static const Color surfaceSoft = Color(0xFFFAF8F3);

  /// Slightly elevated surfaces (`--dt-surface-elevated`).
  static const Color surfaceElevated = Color(0xFFFBFAF6);

  /// Standard border (`--dt-border`).
  static const Color border = Color(0xFFE5E7EB);

  /// Stronger border (`--dt-border-strong`).
  static const Color borderStrong = Color(0xFFD1D5DB);

  // ── Text (light) ──────────────────────────────────────────────────────
  static const Color text = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSoft = Color(0xFF9CA3AF);
}
