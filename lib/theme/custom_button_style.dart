import 'package:doctak_app/core/app_export.dart';
import 'package:flutter/material.dart';

/// A class that offers pre-defined button styles for customizing button appearance.
class CustomButtonStyles {
  // Filled button style
  static ButtonStyle get fillBlue => ElevatedButton.styleFrom(
    backgroundColor: appTheme.blue50,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
  static ButtonStyle get fillGray => ElevatedButton.styleFrom(
    backgroundColor: appTheme.gray100,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
  static ButtonStyle get fillWhiteA => ElevatedButton.styleFrom(
    backgroundColor: appTheme.whiteA700,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // Outline button style
  static ButtonStyle get outlinePrimary => OutlinedButton.styleFrom(
    backgroundColor: Colors.transparent,
    side: BorderSide(color: theme.colorScheme.primary, width: 1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
  // text button style
  static ButtonStyle get none => ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent), elevation: WidgetStateProperty.all<double>(0));
}
