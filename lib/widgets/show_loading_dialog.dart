import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Shows a loading dialog with OneUI 8.5 theming
void showLoadingDialog(BuildContext context, {String? title, String? message}) {
  final theme = OneUITheme.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (BuildContext dialogContext) {
      return Dialog(
        backgroundColor: theme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Loading indicator
              SizedBox(
                height: 56,
                width: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3.0,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                ),
              ),
              const SizedBox(height: 24.0),

              // Title
              Text(
                title ??
                    translation(dialogContext).lbl_sending_verification_link,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17.0,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8.0),

              // Message
              Text(
                message ??
                    translation(dialogContext).msg_verification_email_wait,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.0, color: theme.textSecondary),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows a simple loading overlay with OneUI 8.5 theming
void showSimpleLoadingDialog(BuildContext context) {
  final theme = OneUITheme.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black38,
    builder: (BuildContext dialogContext) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: CircularProgressIndicator(
            strokeWidth: 3.0,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        ),
      );
    },
  );
}
