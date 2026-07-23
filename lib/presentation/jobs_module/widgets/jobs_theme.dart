import 'package:doctak_app/theme/doctak_palette.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Jobs module tokens — aligned with [OneUITheme] / [DoctakPalette].
abstract final class JobsTheme {
  /// One UI / DocTak brand blue.
  static const Color primary = Color(0xFF0A84FF);
  static const Color primaryContainer = Color(0xFF0070E0);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color background = DoctakPalette.bg;
  static const Color surface = DoctakPalette.surface;
  static const Color surfaceBright = DoctakPalette.surfaceElevated;
  static const Color surfaceContainer = DoctakPalette.border;
  static const Color surfaceContainerLow = DoctakPalette.surfaceSoft;
  static const Color surfaceContainerHigh = DoctakPalette.surfaceSoft;
  static const Color surfaceContainerHighest = Color(0xFFE5F2FF);

  static const Color onSurface = DoctakPalette.text;
  static const Color onSurfaceVariant = DoctakPalette.textMuted;
  static const Color outline = DoctakPalette.textSoft;
  static const Color outlineVariant = DoctakPalette.border;

  static const Color success = primary;
  static const Color successSoft = Color(0xFFE5F2FF);
  static const Color warning = Color(0xFFB46B00);
  static const Color warningSoft = Color(0xFFFFF0D6);
  static const Color danger = Color(0xFFBA1A1A);
  static const Color dangerSoft = Color(0xFFFFDAD6);

  /// Alias — filters / accents use brand primary (not teal).
  static const Color filterAccent = primary;

  static const TextStyle displayTitle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    color: onSurface,
    letterSpacing: -0.2,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    color: onSurface,
    letterSpacing: -0.3,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w700,
    color: onSurface,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: onSurface,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: onSurfaceVariant,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: onSurfaceVariant,
  );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
    color: onSurfaceVariant,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: outline,
  );

  /// Prefer [cardDecorationOf] so dark mode and OneUI card styles stay in sync.
  static BoxDecoration cardDecoration({Color? color, Color? borderColor}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? const Color(0x1A0B1220)),
    );
  }

  static BoxDecoration cardDecorationOf(
    BuildContext context, {
    Color? color,
    Color? borderColor,
  }) {
    final theme = OneUITheme.of(context);
    if (color == null && borderColor == null) {
      return theme.surfaceCardDecoration();
    }
    return theme.surfaceCardDecoration().copyWith(
      color: color,
      border: borderColor == null
          ? null
          : Border.all(color: borderColor, width: 1),
    );
  }

  /// Clears the device home indicator / system nav bar when scrolling lists.
  static double scrollBottomInset(BuildContext context, {double extra = 24}) =>
      extra + MediaQuery.paddingOf(context).bottom;

  /// Standard list padding for jobs module scroll views.
  static EdgeInsets listPadding(
    BuildContext context, {
    double top = 0,
    double extraBottom = 24,
    double horizontal = 0,
  }) {
    if (horizontal > 0) {
      return EdgeInsets.fromLTRB(
        horizontal,
        top,
        horizontal,
        scrollBottomInset(context, extra: extraBottom),
      );
    }
    return EdgeInsets.only(
      top: top,
      bottom: scrollBottomInset(context, extra: extraBottom),
    );
  }
}

/// One UI surface card — shared list/detail card style for Jobs.
class JobsSurfaceCard extends StatelessWidget {
  const JobsSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final decoration = (color == null && borderColor == null)
        ? theme.surfaceCardDecoration()
        : theme.surfaceCardDecoration().copyWith(
            color: color,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: 1),
          );

    // Material inside the decorated surface so ListTile/RadioListTile ink is visible.
    return Container(
      margin: margin,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}
