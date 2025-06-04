import 'dart:developer';
import 'dart:async';
import 'dart:io';

import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  late PusherChannelsFlutter _pusher;
  final Map<String, List<Function(dynamic)>> _eventListeners = {};
  final Map<String, PusherChannel> _channels = {};
  bool _isConnected = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _connectionWatchdog;
  
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectInterval = Duration(seconds: 3);
  static const Duration _watchdogInterval = Duration(seconds: 30);

  factory PusherService() {
    return _instance;
  }

  PusherService._internal();

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    try {
      _pusher = PusherChannelsFlutter.getInstance();

      await _pusher.init(
        apiKey: PusherConfig.key,
        cluster: PusherConfig.cluster,
        useTLS: true, // Use TLS for better security
        onSubscriptionSucceeded: _onSubscriptionSucceeded,
        onSubscriptionError: _onSubscriptionError,
        onMemberAdded: _onMemberAdded,
        onMemberRemoved: _onMemberRemoved,
        onDecryptionFailure: _onDecryptionFailure,
        onError: _onError,
        onSubscriptionCount: _onSubscriptionCount,
      );

      _pusher.onConnectionStateChange = (String currentState, String previousState) {
        log('Pusher connection state: $previousState -> $currentState');
        
        if (currentState == 'CONNECTED') {
          _isConnected = true;
          _isReconnecting = false;
          _reconnectAttempts = 0;
          _startConnectionWatchdog();
          
          // Re-subscribe to channels after reconnection
          if (previousState == 'DISCONNECTED' || previousState == 'RECONNECTING') {
            Future.delayed(const Duration(milliseconds: 500), () {
              _resubscribeToChannels();
            });
          }
        } else if (currentState == 'DISCONNECTED' || currentState == 'RECONNECTING') {
          _isConnected = false;
          _scheduleReconnection();
        }
      };
    } catch (e) {
      log('Failed to initialize Pusher: $e');
      _scheduleReconnection();
    }
  }

  Future<void> connect() async {
    try {
      if (!_isConnected && !_isReconnecting) {
        log('Attempting to connect to Pusher...');
        await _pusher.connect();
        // Connection state will be handled by onConnectionStateChange
      }
    } catch (e) {
      log('Failed to connect to Pusher: $e');
      _scheduleReconnection();
    }
  }

  Future<void> disconnect() async {
    try {
      _stopConnectionWatchdog();
      _cancelReconnectTimer();
      await _pusher.disconnect();
      _isConnected = false;
      _reconnectAttempts = 0;
    } catch (e) {
      log('Error disconnecting from Pusher: $e');
    }
  }

  Future<PusherChannel?> subscribeToChannel(String channelName) async {
    try {
      // Wait for connection if not connected
      if (!_isConnected) {
        await _waitForConnection();
      }

      final channel = await _pusher.subscribe(
        channelName: channelName,
        onEvent: _handleEvent,
      );
      _channels[channelName] = channel;
      return channel;
    } catch (e) {
      log('Failed to subscribe to channel $channelName: $e');
      return null;
    }
  }

  Future<void> _waitForConnection({Duration timeout = const Duration(seconds: 10)}) async {
    final stopwatch = Stopwatch()..start();
    
    while (!_isConnected && stopwatch.elapsed < timeout) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (!_isConnected) {
      throw Exception('Pusher connection timeout');
    }
  }

  Future<void> _resubscribeToChannels() async {
    if (_channels.isEmpty) return;
    
    log('Re-subscribing to ${_channels.length} channels...');
    final channelNames = List<String>.from(_channels.keys);
    
    for (final channelName in channelNames) {
      try {
        await subscribeToChannel(channelName);
      } catch (e) {
        log('Failed to re-subscribe to $channelName: $e');
      }
    }
  }

  void unsubscribeFromChannel(String channelName) async {
    if (_channels.containsKey(channelName)) {
      await _pusher.unsubscribe(channelName: channelName);
      _channels.remove(channelName);
    }
  }

  void registerEventListener(String eventName, Function(dynamic) callback) {
    _eventListeners.putIfAbsent(eventName, () => []).add(callback);
  }

  void unregisterEventListener(String eventName, Function(dynamic) callback) {
    if (_eventListeners.containsKey(eventName)) {
      _eventListeners[eventName]!.remove(callback);
    }
  }

  void _handleEvent(event) {
    final eventName = event.eventName;
    print('dataaaa $event');

    final data = jsonDecode(event.data.toString());
    print('dataaaa $data');
    if (_eventListeners.containsKey(eventName)) {
      for (final callback in _eventListeners[eventName]!) {
        callback(data);
      }
    }
  }

  void _scheduleReconnection() {
    if (_isReconnecting || _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _isReconnecting = true;
    _cancelReconnectTimer();

    // Calculate exponential backoff with jitter
    final backoffMs = _reconnectInterval.inMilliseconds * 
        (1 << _reconnectAttempts.clamp(0, 5)); // Cap exponential growth
    final jitter = (backoffMs * 0.2).round(); // 20% jitter
    final delayMs = backoffMs + 
        (DateTime.now().millisecondsSinceEpoch % jitter);
    
    log('Scheduling reconnection attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts in ${delayMs}ms');

    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      _reconnectAttempts++;
      
      try {
        // Check network connectivity first
        if (await _hasNetworkConnection()) {
          await connect();
        } else {
          log('No network connection, retrying...');
          _scheduleReconnection();
        }
      } catch (e) {
        log('Reconnection attempt failed: $e');
        _scheduleReconnection();
      }
    });
  }

  Future<bool> _hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('pusher.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _startConnectionWatchdog() {
    _stopConnectionWatchdog();
    
    _connectionWatchdog = Timer.periodic(_watchdogInterval, (timer) {
      if (!_isConnected && !_isReconnecting) {
        log('Connection watchdog: Connection lost, attempting to reconnect...');
        _scheduleReconnection();
      }
    });
  }

  void _stopConnectionWatchdog() {
    _connectionWatchdog?.cancel();
    _connectionWatchdog = null;
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _isReconnecting = false;
  }

  // Pusher callback handlers
  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    log('Subscribed to $channelName');
  }

  void _onSubscriptionError(String message, dynamic e) {
    log('Subscription error: $message', error: e);
  }

  void _onMemberAdded(String channelName, PusherMember member) {
    log('Member added to $channelName: ${member.userInfo}');
  }

  void _onMemberRemoved(String channelName, PusherMember member) {
    log('Member removed from $channelName: ${member.userInfo}');
  }

  void _onDecryptionFailure(String event, String reason) {
    log('Decryption failed for $event: $reason');
  }

  void _onError(String message, int? code, dynamic e) {
    log('Pusher error: $message (code: $code)', error: e);
    
    // Only reconnect on specific error codes that indicate connection issues
    if (code == null || 
        code >= 4000 && code < 4100 || // Client errors that may be recoverable
        code >= 4200 && code < 4300) { // Connection errors
      _scheduleReconnection();
    }
  }

  void _onSubscriptionCount(String channelName, int subscriptionCount) {
    log('Subscription count for $channelName: $subscriptionCount');
  }
}