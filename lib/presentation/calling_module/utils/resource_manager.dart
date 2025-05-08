// lib/presentation/call_module/utils/resource_manager.dart

/// Class to manage resources and optimize performance
class ResourceManager {
  bool _isHighPerformanceMode = true;
  DateTime? _lastUIUpdate;

  /// Set high performance mode on/off
  void setHighPerformanceMode(bool enabled) {
    _isHighPerformanceMode = enabled;
  }

  /// Check if UI update should be allowed based on performance settings
  /// This prevents too frequent UI updates that could cause performance issues
  bool shouldUpdateUI() {
    final now = DateTime.now();

    if (_lastUIUpdate == null) {
      _lastUIUpdate = now;
      return true;
    }

    // In high performance mode, update every 16ms (60fps)
    // In low performance mode, update every 100ms (10fps)
    final updateInterval = _isHighPerformanceMode ? 16 : 100;

    if (now.difference(_lastUIUpdate!).inMilliseconds > updateInterval) {
      _lastUIUpdate = now;
      return true;
    }

    return false;
  }
}