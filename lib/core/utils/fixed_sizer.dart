import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Fixed Sizer wrapper that forces consistent responsive dimensions
/// regardless of device display settings
class FixedSizer extends StatelessWidget {
  final Widget child;
  final Size? designSize;
  final double? maxTabletWidth;

  const FixedSizer({
    Key? key,
    required this.child,
    this.designSize,
    this.maxTabletWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Force fixed screen dimensions for Sizer calculations
    final fixedSize = designSize ?? const Size(393.0, 852.0); // iPhone 14 Pro dimensions
    final fixedDevicePixelRatio = 3.0;
    
    // Create a custom MediaQuery that Sizer will use for calculations
    final customMediaQueryData = MediaQueryData(
      size: fixedSize,
      devicePixelRatio: fixedDevicePixelRatio,
      textScaler: const TextScaler.linear(1.0),
      boldText: false,
      padding: MediaQuery.of(context).padding,
      viewInsets: MediaQuery.of(context).viewInsets,
      viewPadding: MediaQuery.of(context).viewPadding,
      platformBrightness: MediaQuery.of(context).platformBrightness,
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
      accessibleNavigation: false,
      invertColors: false,
      disableAnimations: false,
      highContrast: false,
      gestureSettings: MediaQuery.of(context).gestureSettings,
      displayFeatures: const [],
    );

    return MediaQuery(
      data: customMediaQueryData,
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return child;
        },
      ),
    );
  }
}

/// Custom responsive size extensions that ignore device scaling
extension FixedResponsiveSize on num {
  /// Fixed screen percentage width (ignores device display zoom)
  double get fw => (this * 393.0) / 100; // Fixed width calculation
  
  /// Fixed screen percentage height (ignores device display zoom)
  double get fh => (this * 852.0) / 100; // Fixed height calculation
  
  /// Fixed font size (completely ignores device scaling)
  double get fsp => toDouble(); // Fixed font size - no scaling applied
  
  /// Fixed responsive width based on fixed screen dimensions
  double get fixedW => (this * 393.0) / 100;
  
  /// Fixed responsive height based on fixed screen dimensions
  double get fixedH => (this * 852.0) / 100;
}

/// Utility class for fixed responsive calculations
class FixedResponsive {
  static const double _fixedScreenWidth = 393.0;
  static const double _fixedScreenHeight = 852.0;
  
  /// Calculate fixed width percentage
  static double width(double percentage) {
    return (percentage * _fixedScreenWidth) / 100;
  }
  
  /// Calculate fixed height percentage
  static double height(double percentage) {
    return (percentage * _fixedScreenHeight) / 100;
  }
  
  /// Fixed font size calculation
  static double fontSize(double size) {
    return size; // No scaling applied
  }
  
  /// Responsive font size with fixed base dimensions
  static double responsiveFontSize(double baseSize) {
    // Calculate responsive size based on fixed dimensions
    final scaleFactor = _fixedScreenWidth / 375.0; // Base on iPhone design
    return baseSize * scaleFactor;
  }
}