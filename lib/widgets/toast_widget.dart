import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Shows a toast message with OneUI 8.5 theming
void showToast(String message, {BuildContext? context}) {
  // Use themed colors if context is available, otherwise use sensible defaults
  Color bgColor = const Color(0xFF1A1A1A);
  Color textColor = Colors.white;

  if (context != null) {
    final theme = OneUITheme.of(context);
    bgColor = theme.isDark ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A);
    textColor = Colors.white;
  }

  Fluttertoast.showToast(msg: message, toastLength: Toast.LENGTH_LONG, gravity: ToastGravity.TOP, timeInSecForIosWeb: 2, backgroundColor: bgColor, textColor: textColor, fontSize: 14.0);
}

/// Shows a success toast with green accent
void showSuccessToast(String message, {BuildContext? context}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 2,
    backgroundColor: const Color(0xFF34C759),
    textColor: Colors.white,
    fontSize: 14.0,
  );
}

/// Shows an error toast with red accent
void showErrorToast(String message, {BuildContext? context}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.TOP,
    timeInSecForIosWeb: 2,
    backgroundColor: const Color(0xFFFF3B30),
    textColor: Colors.white,
    fontSize: 14.0,
  );
}
