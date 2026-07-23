import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// One UI 8 compact control height (dialogs, bottom bars, sheets).
const double kOneUIButtonHeight = 40;

/// Shared One UI button styles — keep dialog / bar CTAs consistent.
class OneUIButtons {
  OneUIButtons._();

  static ButtonStyle filled(OneUITheme theme, {bool destructive = false}) {
    return FilledButton.styleFrom(
      minimumSize: const Size(0, kOneUIButtonHeight),
      maximumSize: const Size(double.infinity, kOneUIButtonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      backgroundColor: destructive ? theme.error : theme.primary,
      foregroundColor: Colors.white,
      textStyle: theme.buttonText.copyWith(fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  static ButtonStyle outlined(OneUITheme theme, {bool destructive = false}) {
    final color = destructive ? theme.error : theme.primary;
    return OutlinedButton.styleFrom(
      minimumSize: const Size(0, kOneUIButtonHeight),
      maximumSize: const Size(double.infinity, kOneUIButtonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      foregroundColor: color,
      side: BorderSide(color: destructive ? theme.error : theme.border),
      textStyle: theme.buttonText.copyWith(fontSize: 14, color: color),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  static ButtonStyle text(OneUITheme theme, {bool destructive = false}) {
    return TextButton.styleFrom(
      minimumSize: const Size(0, kOneUIButtonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      foregroundColor: destructive ? theme.error : theme.primary,
      textStyle: theme.buttonText.copyWith(
        fontSize: 14,
        color: destructive ? theme.error : theme.primary,
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// One UI confirm dialog with title, optional subtitle, compact actions.
Future<bool> showOneUIConfirmDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final theme = OneUITheme.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: theme.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
        contentPadding: subtitle == null || subtitle.isEmpty
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(24, 10, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        title: Text(
          title,
          style: theme.titleSmall.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        content: subtitle == null || subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: theme.bodySecondary.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OneUIButtons.text(theme),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: OneUIButtons.filled(theme, destructive: destructive),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
  return result == true;
}
