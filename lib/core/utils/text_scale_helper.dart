import 'package:flutter/material.dart';

/// Helper class to manage text scaling across the app
class TextScaleHelper {
  /// Fixed text scale factor to ensure consistent font sizes
  static const double fixedTextScaleFactor = 1.0;

  /// Wraps a widget with a MediaQuery that overrides ALL text scaling properties
  static Widget withFixedTextScale({required Widget child, double textScaleFactor = fixedTextScaleFactor}) {
    return Builder(
      builder: (context) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScaleFactor), boldText: false),
          child: child,
        );
      },
    );
  }

  /// Gets the current text scale factor (always returns the fixed value)
  static double getTextScaleFactor(BuildContext context) {
    return fixedTextScaleFactor;
  }

  /// Creates a TextStyle with fixed font size (ignores device text scaling)
  static TextStyle createFixedTextStyle({required double fontSize, FontWeight? fontWeight, Color? color, String? fontFamily, TextDecoration? decoration, double? letterSpacing, double? height}) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: fontFamily,
      decoration: decoration,
      letterSpacing: letterSpacing,
      height: height,
      // Explicitly set textScaleFactor to 1.0 in the style
      // This ensures the text size is exactly what we specify
    );
  }
}
