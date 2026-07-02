import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;

import 'package:doctak_app/core/network/network_utils.dart';

sealed class MeetingWsEvent {}

class MeetingWsConnected extends MeetingWsEvent {}

class MeetingWsPong extends MeetingWsEvent {}

class MeetingRealtimeEvent extends MeetingWsEvent {
  MeetingRealtimeEvent({required this.event, required this.payload});
  final String event;
  final Map<String, dynamic> payload;
}

class MeetingWsEnded extends MeetingWsEvent {
  MeetingWsEnded({
    required this.meetingId,
    this.channel,
    this.endedBy,
    this.endedAt,
  });
  final String meetingId;
  final String? channel;
  final String? endedBy;
  final String? endedAt;
}

/// Native WebSocket for in-meeting realtime (replaces Pusher).
class MeetingWebSocketService {
  final StreamController<MeetingWsEvent> _controller =
      StreamController<MeetingWsEvent>.broadcast();

  Stream<MeetingWsEvent> get events => _controller.stream;

  io.WebSocket? _socket;
  String? _meetingId;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  Future<void> connect(String meetingId) async {
    if (_meetingId == meetingId && _socket != null) return;
    await disconnect();
    _meetingId = meetingId;
    _reconnectAttempts = 0;
    await _openSocket(meetingId);
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    _meetingId = null;
  }

  Future<void> _openSocket(String meetingId) async {
    try {
      final response = await buildHttpResponseNode(
        '/api/meetings/ws-ticket?meetingId=${Uri.encodeComponent(meetingId)}',
      );
      final data = await handleResponse(response) as Map<String, dynamic>;
      final wsUrl = data['wsUrl']?.toString();
      if (wsUrl == null || wsUrl.isEmpty) {
        log('MeetingWebSocketService: wsUrl unavailable — polling fallbacks remain active');
        return;
      }

      final socket = await io.WebSocket.connect(wsUrl);
      _socket = socket;
      _controller.add(MeetingWsConnected());

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _send({'kind': 'ping'});
      });

      socket.listen(
        (raw) => _onMessage(raw),
        onDone: () => _scheduleReconnect(meetingId),
        onError: (_) => _scheduleReconnect(meetingId),
        cancelOnError: true,
      );
    } catch (e) {
      log('MeetingWebSocketService connect error: $e');
      _scheduleReconnect(meetingId);
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final kind = json['kind']?.toString() ?? '';
      switch (kind) {
        case 'pong':
        case 'hello':
          _controller.add(MeetingWsPong());
        case 'meeting.event':
          final event = json['event']?.toString() ?? '';
          final payload = json['payload'] is Map
              ? Map<String, dynamic>.from(json['payload'] as Map)
              : <String, dynamic>{};
          if (event.isNotEmpty) {
            _controller.add(MeetingRealtimeEvent(event: event, payload: payload));
          }
        case 'meeting.ended':
          _controller.add(MeetingWsEnded(
            meetingId: json['meetingId']?.toString() ?? _meetingId ?? '',
            channel: json['channel']?.toString(),
            endedBy: json['endedBy']?.toString(),
            endedAt: json['endedAt']?.toString(),
          ));
      }
    } catch (e) {
      log('MeetingWebSocketService parse error: $e');
    }
  }

  void _send(Map<String, dynamic> body) {
    try {
      _socket?.add(jsonEncode(body));
    } catch (_) {}
  }

  void _scheduleReconnect(String meetingId) {
    if (_meetingId != meetingId) return;
    _pingTimer?.cancel();
    _socket = null;
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts += 1;
    final delay = Duration(seconds: (1 << (_reconnectAttempts - 1)).clamp(1, 15));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_meetingId == meetingId) {
        unawaited(_openSocket(meetingId));
      }
    });
  }
}
