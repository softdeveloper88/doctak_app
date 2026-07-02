import 'package:doctak_app/theme/doctak_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper class for managing edge-to-edge display and safe area handling
///
/// IMPORTANT: For screens with bottom navigation or input fields:
/// - DO NOT use `extendBody: true` in Scaffold
/// - Use `getSafeBottomPadding()` to add proper padding for navigation bar areas
/// - This ensures content is not hidden behind system navigation bars on older devices
class EdgeToEdgeHelper {
  /// Matches [OneUITheme.navBarBackground] dark.
  static const Color darkNavigationBarColor = Color(0xFF152232);

  /// System overlay for light/dark — status bar stays transparent; nav bar uses theme surface.
  static SystemUiOverlayStyle overlayForTheme({required bool isDark}) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isDark ? darkNavigationBarColor : DoctakPalette.surface,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static void applyOverlayForTheme({required bool isDark}) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(overlayForTheme(isDark: isDark));
  }

  static void configureEdgeToEdge() {
    applyOverlayForTheme(isDark: false);
  }

  /// Bottom inset for system nav / home indicator (capped to avoid layout blow-up).
  static double safeBottomInset(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;
    final padding = MediaQuery.paddingOf(context).bottom;
    final inset = viewPadding > 0 ? viewPadding : padding;
    if (inset <= 0) return 0;
    return inset.clamp(0, 48);
  }

  /// Scroll/content padding for modal bottom sheets (overlays ignore [padding]).
  static double modalSheetBottomPadding(
    BuildContext context, {
    double additional = 16,
  }) {
    final inset = safeBottomInset(context);
    return (inset > 0 ? inset : 24) + additional;
  }

  /// Scroll padding for tabs inside [SVDashboardScreen] (nav is below content).
  static double dashboardTabBottomPadding(BuildContext context) {
    return 16;
  }

  static void configureEdgeToEdgeDark() {
    applyOverlayForTheme(isDark: true);
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