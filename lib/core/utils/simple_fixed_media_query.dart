import 'package:flutter/material.dart';

/// Locks text scale while keeping the real device size and safe-area insets.
class SimpleFixedMediaQuery {
  static const double _maxBottomInset = 48;

  static double _clampBottom(double value) => value.clamp(0, _maxBottomInset);

  static EdgeInsets _clampBottomEdgeInsets(EdgeInsets insets) {
    return EdgeInsets.fromLTRB(
      insets.left,
      insets.top,
      insets.right,
      _clampBottom(insets.bottom),
    );
  }

  /// Creates MediaQueryData with fixed text scale and clamped bottom insets.
  static MediaQueryData createFixedData(BuildContext context) {
    final original = MediaQuery.of(context);

    return MediaQueryData(
      size: original.size,
      devicePixelRatio: original.devicePixelRatio,
      textScaler: const TextScaler.linear(1.0),
      padding: _clampBottomEdgeInsets(original.padding),
      viewInsets: original.viewInsets,
      viewPadding: _clampBottomEdgeInsets(original.viewPadding),
      systemGestureInsets: original.systemGestureInsets,
      boldText: false,
      highContrast: false,
      disableAnimations: false,
      invertColors: false,
      accessibleNavigation: false,
      platformBrightness: original.platformBrightness,
      alwaysUse24HourFormat: original.alwaysUse24HourFormat,
      gestureSettings: original.gestureSettings,
      displayFeatures: original.displayFeatures,
    );
  }

  /// Wraps a widget with normalized MediaQuery.
  static Widget wrap({required Widget child, BuildContext? context}) {
    return Builder(
      builder: (builderContext) {
        final contextToUse = context ?? builderContext;
        return MediaQuery(
          data: createFixedData(contextToUse),
          child: child,
        );
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
