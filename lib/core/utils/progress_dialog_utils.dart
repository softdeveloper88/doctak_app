import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/widgets/doctak_app_loader.dart';
import 'package:flutter/material.dart';

/// App-wide blocking progress overlay (login, signup, profile save, meetings, …).
/// Full-screen dimmed scrim + centered Lottie on a transparent background.
class ProgressDialogUtils {
  ProgressDialogUtils._();

  static bool isProgressVisible = false;

  static BuildContext? get _overlayContext =>
      NavigatorService.navigatorKey.currentState?.overlay?.context;

  /// Shows the branded Lottie progress overlay on the root navigator.
  static void showProgressDialog({
    BuildContext? context,
    bool isCancellable = false,
    String? message,
  }) {
    if (isProgressVisible) return;

    final dialogContext = context ?? _overlayContext;
    if (dialogContext == null) return;

    showDialog(
      context: dialogContext,
      barrierDismissible: isCancellable,
      barrierColor: DoctakAppLoaderConfig.overlayBarrierColor,
      useRootNavigator: true,
      builder: (BuildContext ctx) {
        return DoctakAppLoaderOverlay(
          message: message,
          canPop: isCancellable,
        );
      },
    );

    isProgressVisible = true;
  }

  /// Hides the progress dialog if it is visible.
  static void hideProgressDialog() {
    if (!isProgressVisible) return;

    final ctx = _overlayContext;
    if (ctx != null && Navigator.of(ctx, rootNavigator: true).canPop()) {
      Navigator.of(ctx, rootNavigator: true).pop();
    }

    isProgressVisible = false;
  }
}
