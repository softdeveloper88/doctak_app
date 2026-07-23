import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/doctak_app_loader.dart';
import 'package:flutter/material.dart';

/// Modal card with branded loader — visible on all themes (not a transparent overlay).
void showLoadingDialog(BuildContext context, {String? title, String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: DoctakAppLoaderConfig.overlayBarrierColor,
    builder: (BuildContext dialogContext) {
      final theme = OneUITheme.of(dialogContext);

      return PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: theme.cardBackground,
          surfaceTintColor: theme.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          content: DoctakAppLoaderDialogBody(
            title: title ?? translation(dialogContext).lbl_sending_verification_link,
            message: message ?? translation(dialogContext).msg_verification_email_wait,
          ),
        ),
      );
    },
  );
}

/// Minimal full-screen overlay — Lottie only.
void showSimpleLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: DoctakAppLoaderConfig.overlayBarrierColor,
    builder: (BuildContext dialogContext) {
      return const DoctakAppLoaderOverlay();
    },
  );
}

/// Dismisses the topmost loading dialog if one is open.
void hideLoadingDialog(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}
