import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// OneUI 8.5 styled confirmation dialog
class CustomAlertDialog extends StatelessWidget {
  final VoidCallback callback;
  final VoidCallback? callbackNegative;
  final String title;
  final String? noButtonText;
  final String? yesButtonText;
  final String? mainTitle;

  const CustomAlertDialog({
    Key? key,
    required this.title,
    required this.callback,
    this.callbackNegative,
    this.yesButtonText,
    this.noButtonText,
    this.mainTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: theme.cardBackground,
      child: _buildDialogContent(context, theme),
    );
  }

  Widget _buildDialogContent(BuildContext context, OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            mainTitle ?? translation(context).lbl_delete_with_question,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: theme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop('dialog');
                    callbackNegative?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textPrimary,
                    side: BorderSide(color: theme.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    noButtonText ?? translation(context).lbl_cancel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Confirm/Delete button
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop('dialog');
                    callback();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    yesButtonText ?? translation(context).lbl_delete,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Legacy function for backward compatibility - now uses OneUI 8.5 styling
Widget confirmationCustomAlertDialog(
  BuildContext context,
  String title,
  VoidCallback callBack,
  String yesButtonText,
  String mainTitle,
  VoidCallback? callbackNegative,
  String? noButtonText,
) {
  return CustomAlertDialog(
    title: title,
    callback: callBack,
    yesButtonText: yesButtonText,
    mainTitle: mainTitle,
    callbackNegative: callbackNegative,
    noButtonText: noButtonText,
  );
}
