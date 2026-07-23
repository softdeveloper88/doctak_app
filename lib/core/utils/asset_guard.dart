import 'package:flutter/services.dart';

/// Knows which assets actually exist inside the *installed* release binary.
///
/// Shorebird patches can only ship Dart code — never new asset files. When a
/// patch references an SVG added after the store release was built, loading it
/// throws `Unable to load asset` (top Crashlytics issue 8843130712e76a55).
/// Widgets should check [has] before attempting an asset load and render a
/// drawn fallback instead.
abstract final class AssetGuard {
  static Set<String>? _available;
  static bool _warming = false;

  /// Load the on-device AssetManifest once. Safe to call multiple times.
  static Future<void> warmUp() async {
    if (_available != null || _warming) return;
    _warming = true;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _available = manifest.listAssets().toSet();
    } catch (_) {
      // Manifest unreadable — keep null so [has] stays permissive.
    } finally {
      _warming = false;
    }
  }

  /// True if [asset] is known to exist in the installed bundle.
  /// Before [warmUp] completes we optimistically return true (widgets that
  /// call this must still have their own errorBuilder fallback).
  static bool has(String asset) => _available?.contains(asset) ?? true;
}
