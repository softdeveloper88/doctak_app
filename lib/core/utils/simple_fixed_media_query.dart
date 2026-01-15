import 'package:flutter/material.dart';

/// Simple and reliable fixed MediaQuery that focuses only on essential properties
class SimpleFixedMediaQuery {
  /// Fixed dimensions based on iPhone 14 Pro
  static const Size _fixedSize = Size(393.0, 852.0);
  static const double _fixedPixelRatio = 3.0;

  /// Creates a minimal fixed MediaQueryData
  static MediaQueryData createFixedData(BuildContext context) {
    final original = MediaQuery.of(context);

    return MediaQueryData(
      // Fixed core properties
      size: _fixedSize,
      devicePixelRatio: _fixedPixelRatio,
      textScaler: const TextScaler.linear(1.0),

      // Essential system properties (preserve originals)
      padding: original.padding,
      viewInsets: original.viewInsets,
      viewPadding: original.viewPadding,
      systemGestureInsets: original.systemGestureInsets,

      // Fixed accessibility properties
      boldText: false,
      highContrast: false,
      disableAnimations: false,
      invertColors: false,
      accessibleNavigation: false,

      // System properties (preserve originals)
      platformBrightness: original.platformBrightness,
      alwaysUse24HourFormat: original.alwaysUse24HourFormat,

      // Preserve gesture and display settings
      gestureSettings: original.gestureSettings,
      displayFeatures: original.displayFeatures,
    );
  }

  /// Wraps a widget with fixed MediaQuery
  static Widget wrap({required Widget child, BuildContext? context}) {
    return Builder(
      builder: (builderContext) {
        final contextToUse = context ?? builderContext;
        return MediaQuery(data: createFixedData(contextToUse), child: child);
      },
    );
  }
}

/// Extension for easy usage
extension SimpleFixedMediaQueryExtension on Widget {
  Widget withSimpleFixedMediaQuery() {
    return SimpleFixedMediaQuery.wrap(child: this);
  }
}
