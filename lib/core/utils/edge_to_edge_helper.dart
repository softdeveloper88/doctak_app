import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'navigator_service.dart';

class EdgeToEdgeHelper {
  static void configureEdgeToEdge() {
    // Set system UI overlay style for edge-to-edge
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    
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
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    
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
  
  /// Widget that ensures proper edge-to-edge layout
  static Widget wrapScaffold({
    required Widget child,
    bool extendBody = true,
    bool extendBodyBehindAppBar = true,
  }) {
    final context = NavigatorService.navigatorKey.currentContext;
    if (context != null) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
        child: child,
      );
    }
    return child;
  }
  
  /// Get safe area padding for manual handling
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }
}