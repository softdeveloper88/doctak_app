import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper class for managing edge-to-edge display and safe area handling
///
/// IMPORTANT: For screens with bottom navigation or input fields:
/// - DO NOT use `extendBody: true` in Scaffold
/// - Use `getSafeBottomPadding()` to add proper padding for navigation bar areas
/// - This ensures content is not hidden behind system navigation bars on older devices
class EdgeToEdgeHelper {
  static void configureEdgeToEdge() {
    // Set system UI overlay style for edge-to-edge
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Set system UI overlay style for transparent system bars
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  static void configureEdgeToEdgeDark() {
    // Set system UI overlay style for edge-to-edge
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Set system UI overlay style for transparent system bars (dark mode)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  /// Get safe area padding for manual handling
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get safe bottom padding (for bottom navigation/input areas)
  /// Returns bottom padding + additional padding for better spacing
  /// Use this instead of SafeArea for bottom UI elements
  static double getSafeBottomPadding(BuildContext context, {double additionalPadding = 0.0}) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return bottomPadding + additionalPadding;
  }

  /// Get safe top padding (for app bar areas)
  static double getSafeTopPadding(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Create EdgeInsets for bottom padding that respects safe area
  /// Example: padding: EdgeToEdgeHelper.bottomSafePadding(context, horizontal: 16, vertical: 8)
  static EdgeInsets bottomSafePadding(BuildContext context, {double horizontal = 0.0, double vertical = 0.0}) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return EdgeInsets.only(left: horizontal, right: horizontal, top: vertical, bottom: bottomPadding + vertical);
  }

  /// Create EdgeInsets for all-around safe area padding
  static EdgeInsets allSafePadding(BuildContext context, {double horizontal = 0.0, double vertical = 0.0}) {
    final padding = MediaQuery.of(context).padding;
    return EdgeInsets.only(left: padding.left + horizontal, right: padding.right + horizontal, top: padding.top + vertical, bottom: padding.bottom + vertical);
  }
}