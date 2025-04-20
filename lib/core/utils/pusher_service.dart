import 'dart:developer';

import 'package:doctak_app/presentation/user_chat_screen/Pusher/PusherConfig.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'dart:convert';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  late PusherChannelsFlutter _pusher;
  final Map<String, List<Function(dynamic)>> _eventListeners = {};
  final Map<String, PusherChannel> _channels = {};
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectInterval = Duration(seconds: 5);

  factory PusherService() {
    return _instance;
  }

  PusherService._internal();

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    _pusher = PusherChannelsFlutter.getInstance();

    await _pusher.init(
      apiKey: PusherConfig.key,
      cluster: PusherConfig.cluster,
      useTLS: false,
      onSubscriptionSucceeded: _onSubscriptionSucceeded,
      onSubscriptionError: _onSubscriptionError,
      onMemberAdded: _onMemberAdded,
      onMemberRemoved: _onMemberRemoved,
      onDecryptionFailure: _onDecryptionFailure,
      onError: _onError,
      onSubscriptionCount: _onSubscriptionCount,
    );

    _pusher.onConnectionStateChange = (String state,String state1) {
      if (state == 'DISCONNECTED') {
        _scheduleReconnection();
      }
      if (state1 == 'DISCONNECTED') {
        _scheduleReconnection();
      }
    };
  }

  Future<void> connect() async {
    if (!_isConnected) {
      await _pusher.connect();
      _isConnected = true;
      _reconnectAttempts = 0;
    }
  }

  Future<void> disconnect() async {
    await _pusher.disconnect();
    _isConnected = false;
    _reconnectAttempts = 0;
  }

  void subscribeToChannel(String channelName) async {
    // if (_channels.containsKey(channelName)) return;

    final channel = await _pusher.subscribe(
      channelName: channelName,
      onEvent: _handleEvent,
    );
    _channels[channelName] = channel;

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
    if (_reconnectAttempts < _maxReconnectAttempts) {
      Future.delayed(_reconnectInterval * (1 + _reconnectAttempts), () async {
        _reconnectAttempts++;
        try {
          await connect();
        } catch (e) {
          _scheduleReconnection();
        }
      });
    }
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
    _scheduleReconnection();
  }

  void _onSubscriptionCount(String channelName, int subscriptionCount) {
    log('Subscription count for $channelName: $subscriptionCount');
  }
}