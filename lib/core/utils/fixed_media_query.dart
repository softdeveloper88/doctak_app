import 'package:flutter/material.dart';

/// Creates a completely fixed MediaQuery that ignores ALL device scaling settings
class FixedMediaQuery {
  /// Standard fixed screen dimensions (iPhone 14 Pro dimensions as reference)
  static const Size _fixedScreenSize = Size(393.0, 852.0);
  static const double _fixedDevicePixelRatio = 3.0;
  static const double _fixedTextScaleFactor = 1.0;

  /// Creates a MediaQueryData with completely fixed values
  static MediaQueryData createFixedMediaQueryData(BuildContext context) {
    // Get original padding values but keep everything else fixed
    final originalQuery = MediaQuery.maybeOf(context);
    final originalPadding = originalQuery?.padding ?? EdgeInsets.zero;
    final originalViewInsets = originalQuery?.viewInsets ?? EdgeInsets.zero;
    final originalViewPadding = originalQuery?.viewPadding ?? EdgeInsets.zero;

    return MediaQueryData(
      // Fixed screen properties
      size: _fixedScreenSize,
      devicePixelRatio: _fixedDevicePixelRatio,

      // Fixed text scaling
      textScaler: const TextScaler.linear(_fixedTextScaleFactor),
      boldText: false,

      // Keep original padding/insets for proper layout
      padding: originalPadding,
      viewInsets: originalViewInsets,
      viewPadding: originalViewPadding,

      // Fixed platform properties
      platformBrightness: originalQuery?.platformBrightness ?? Brightness.light,
      alwaysUse24HourFormat: originalQuery?.alwaysUse24HourFormat ?? false,
      accessibleNavigation: false,
      invertColors: false,
      disableAnimations: false,
      highContrast: false,

      // Use original gesture settings or default
      gestureSettings: originalQuery!.gestureSettings,

      // Fixed display features
      displayFeatures: const [],
    );
  }

  /// Widget that wraps content with completely fixed MediaQuery
  static Widget wrap({required Widget child, BuildContext? context}) {
    return Builder(
      builder: (builderContext) {
        final contextToUse = context ?? builderContext;
        return MediaQuery(data: createFixedMediaQueryData(contextToUse), child: child);
      },
    );
  }

  /// Alternative method with custom screen size
  static Widget wrapWithCustomSize({required Widget child, Size? screenSize, double? devicePixelRatio, BuildContext? context}) {
    return Builder(
      builder: (builderContext) {
        final contextToUse = context ?? builderContext;
        final originalQuery = MediaQuery.maybeOf(contextToUse);
        final originalPadding = originalQuery?.padding ?? EdgeInsets.zero;
        final originalViewInsets = originalQuery?.viewInsets ?? EdgeInsets.zero;
        final originalViewPadding = originalQuery?.viewPadding ?? EdgeInsets.zero;

        final customData = MediaQueryData(
          size: screenSize ?? _fixedScreenSize,
          devicePixelRatio: devicePixelRatio ?? _fixedDevicePixelRatio,
          textScaler: const TextScaler.linear(_fixedTextScaleFactor),
          boldText: false,
          padding: originalPadding,
          viewInsets: originalViewInsets,
          viewPadding: originalViewPadding,
          platformBrightness: originalQuery?.platformBrightness ?? Brightness.light,
          alwaysUse24HourFormat: originalQuery?.alwaysUse24HourFormat ?? false,
          accessibleNavigation: false,
          invertColors: false,
          disableAnimations: false,
          highContrast: false,
          gestureSettings: originalQuery!.gestureSettings,
          displayFeatures: const [],
        );

        return MediaQuery(data: customData, child: child);
      },
    );
  }
}

/// Extension to easily apply fixed MediaQuery to any widget
extension FixedMediaQueryExtension on Widget {
  Widget withFixedMediaQuery({BuildContext? context}) {
    return FixedMediaQuery.wrap(child: this, context: context);
  }

  Widget withCustomMediaQuery({Size? screenSize, double? devicePixelRatio, BuildContext? context}) {
    return FixedMediaQuery.wrapWithCustomSize(child: this, screenSize: screenSize, devicePixelRatio: devicePixelRatio, context: context);
  }
}
