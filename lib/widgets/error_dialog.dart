import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Error dialog with OneUI 8.5 theming
class ErrorDialog extends StatelessWidget {
  final Map<String, dynamic> errors;

  const ErrorDialog({super.key, required this.errors});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return AlertDialog(
      backgroundColor: theme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      title: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              translation(context).lbl_validation_error,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.textPrimary),
            ),
          ),
        ],
      ),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: _buildErrorWidgets(theme)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(translation(context).lbl_ok),
        ),
      ],
    );
  }

  List<Widget> _buildErrorWidgets(OneUITheme theme) {
    List<Widget> errorWidgets = [];
    errors.forEach((field, errorMessages) {
      for (var errorMessage in errorMessages) {
        errorWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 6, color: theme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$field: $errorMessage', style: TextStyle(fontSize: 14, color: theme.textSecondary)),
                ),
              ],
            ),
          ),
        );
      }
    });
    return errorWidgets;
  }
}
