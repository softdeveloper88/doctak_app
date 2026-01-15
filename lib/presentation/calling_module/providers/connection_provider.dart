// lib/presentation/call_module/providers/connection_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Provider to manage connection state
class ConnectionProvider extends ChangeNotifier {
  // Connection states
  bool _isConnecting = true;
  bool _isReconnecting = false;
  bool _isConnected = false;
  bool _isInitialized = false;
  int? _networkQuality;
  int _reconnectionAttempts = 0;
  DateTime? _lastSuccessfulConnectionTime;
  bool _isRecoveringConnection = false;

  // Timers
  Timer? _connectionWatchdog;
  Timer? _reconnectionAttemptTimer;

  // Getters
  bool get isConnecting => _isConnecting;
  bool get isReconnecting => _isReconnecting;
  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  int? get networkQuality => _networkQuality;
  int get reconnectionAttempts => _reconnectionAttempts;

  // Constructor
  ConnectionProvider() {
    // Start connection watchdog
    _startConnectionWatchdog();
  }

  // Connection watchdog
  void _startConnectionWatchdog() {
    _connectionWatchdog?.cancel();

    _connectionWatchdog = Timer.periodic(const Duration(seconds: 10), (timer) {
      // Skip check if already reconnecting
      if (_isReconnecting || !_isInitialized) return;

      // Check if it's been too long since last successful connection
      if (_lastSuccessfulConnectionTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_lastSuccessfulConnectionTime!).inSeconds;

        // If no successful connection for 20 seconds, trigger reconnection
        if (difference > 20 && !_isRecoveringConnection) {
          triggerConnectionRecovery();
        }
      }
    });
  }

  // Set connecting state
  void setConnecting(bool value) {
    if (_isConnecting != value) {
      _isConnecting = value;
      notifyListeners();
    }
  }

  // Set reconnecting state
  void setReconnecting(bool value) {
    if (_isReconnecting != value) {
      _isReconnecting = value;
      notifyListeners();
    }
  }

  // Set connected state
  void setConnected(bool value) {
    if (_isConnected != value) {
      _isConnected = value;
      if (value) {
        _lastSuccessfulConnectionTime = DateTime.now();
        _isReconnecting = false;
        _isRecoveringConnection = false;
      }
      notifyListeners();
    }
  }

  // Set initialized state
  void setInitialized(bool value) {
    if (_isInitialized != value) {
      _isInitialized = value;
      notifyListeners();
    }
  }

  // Set network quality
  void setNetworkQuality(int quality) {
    if (_networkQuality != quality) {
      _networkQuality = quality;
      notifyListeners();
    }
  }

  // Trigger connection recovery
  void triggerConnectionRecovery() {
    if (_isRecoveringConnection) return;

    _isRecoveringConnection = true;
    _reconnectionAttempts = 0;
    notifyListeners();

    // Implement reconnection logic here or emit events for other providers
  }

  // Increment reconnection attempts
  void incrementReconnectionAttempts() {
    _reconnectionAttempts++;
    notifyListeners();
  }

  // Reset reconnection attempts
  void resetReconnectionAttempts() {
    _reconnectionAttempts = 0;
    notifyListeners();
  }

  // Update connection timestamp
  void updateConnectionTimestamp() {
    _lastSuccessfulConnectionTime = DateTime.now();
  }

  @override
  void dispose() {
    _connectionWatchdog?.cancel();
    _reconnectionAttemptTimer?.cancel();
    super.dispose();
  }
}
