import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/widgets/doctak_app_loader.dart';
import 'package:flutter/material.dart';

/// Full-screen dimmed overlay with transparent Lottie loader (same as login progress).
void showLoadingDialog(BuildContext context, {String? title, String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: DoctakAppLoaderConfig.overlayBarrierColor,
    builder: (BuildContext dialogContext) {
      return DoctakAppLoaderOverlay(
        title: title ?? translation(dialogContext).lbl_sending_verification_link,
        message: message ?? translation(dialogContext).msg_verification_email_wait,
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
