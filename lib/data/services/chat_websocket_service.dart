import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:doctak_app/data/apiClient/services/conversation_api_service.dart';
import 'package:doctak_app/data/models/chat_model/conversation_message_model.dart';

// ─── Event types ────────────────────────────────────────────────────────────

sealed class ChatWsEvent {}

class WsMessageCreated extends ChatWsEvent {
  final ConversationMessage message;
  WsMessageCreated(this.message);
}

class WsMessageUpdated extends ChatWsEvent {
  final ConversationMessage message;
  WsMessageUpdated(this.message);
}

class WsMessageDeleted extends ChatWsEvent {
  final int messageId;
  final int conversationId;
  WsMessageDeleted({required this.messageId, required this.conversationId});
}

class WsReactionsUpdated extends ChatWsEvent {
  final int messageId;
  final List<MessageReaction> reactions;
  WsReactionsUpdated({required this.messageId, required this.reactions});
}

class WsDelivered extends ChatWsEvent {
  final int messageId;
  final String userId;
  WsDelivered({required this.messageId, required this.userId});
}

class WsRead extends ChatWsEvent {
  final int messageId;
  final String userId;
  WsRead({required this.messageId, required this.userId});
}

class WsTyping extends ChatWsEvent {
  final String userId;
  final bool isTyping;
  final int conversationId;
  WsTyping({required this.userId, required this.isTyping, required this.conversationId});
}

class WsPresence extends ChatWsEvent {
  final String userId;
  final bool isOnline;
  WsPresence({required this.userId, required this.isOnline});
}

class WsPong extends ChatWsEvent {}

// ─── Service ─────────────────────────────────────────────────────────────────

/// Native WebSocket service replacing Pusher.
/// Falls back to HTTP polling when the WS URL is not configured.
class ChatWebSocketService {
  static final ChatWebSocketService _instance = ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  final ConversationApiService _api = ConversationApiService();

  // Public event stream
  final StreamController<ChatWsEvent> _controller =
      StreamController<ChatWsEvent>.broadcast();

  Stream<ChatWsEvent> get events => _controller.stream;

  io.WebSocket? _socket;
  int? _currentConversationId;
  bool _polling = false;

  Timer? _pingTimer;
  Timer? _heartbeatTimer;
  Timer? _pollTimer;
  Timer? _safetyPollTimer;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  // Polling cursor: track the highest message ID seen
  int _lastSeenId = 0;
  String? _lastUpdatedAfter;

  // ─── Public API ─────────────────────────────────────────────

  Future<void> connect(int conversationId) async {
    if (_currentConversationId == conversationId && _socket != null) return;
    await disconnect();

    _currentConversationId = conversationId;
    _reconnectAttempts = 0;

    await _tryConnectWs(conversationId);
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    _safetyPollTimer?.cancel();
    _pingTimer = null;
    _heartbeatTimer = null;
    _pollTimer = null;
    _safetyPollTimer = null;

    _polling = false;
    _reconnectAttempts = 0;
    _lastSeenId = 0;
    _lastUpdatedAfter = null;

    final s = _socket;
    _socket = null;
    _currentConversationId = null;
    await s?.close(io.WebSocketStatus.normalClosure);
  }

  /// Send a typing indicator via WebSocket.
  void sendTyping({required bool isTyping}) {
    _sendWs({'kind': 'typing', 'isTyping': isTyping});
  }

  // ─── WebSocket connection ────────────────────────────────────

  Future<void> _tryConnectWs(int conversationId) async {
    try {
      final ticket = await _api.getWsTicket(conversationId: conversationId);
      if (ticket.wsUrl == null || ticket.wsUrl!.isEmpty) {
        _startPolling(conversationId);
        return;
      }
      _openSocket(ticket.wsUrl!, conversationId);
    } catch (_) {
      _startPolling(conversationId);
    }
  }

  void _openSocket(String wsUrl, int conversationId) {
    io.WebSocket.connect(wsUrl).then((socket) {
      _socket = socket;
      _reconnectAttempts = 0;

      _startPingTimer();
      _startHeartbeatTimer(conversationId);
      _startSafetyPoll(conversationId);

      socket.listen(
        _onWsMessage,
        onDone: () => _onWsClosed(conversationId),
        onError: (_) => _onWsClosed(conversationId),
        cancelOnError: false,
      );
    }).catchError((_) {
      _onWsClosed(conversationId);
    });
  }

  void _onWsMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _dispatchEvent(json);
    } catch (_) {}
  }

  void _onWsClosed(int conversationId) {
    _socket = null;
    _pingTimer?.cancel();
    _safetyPollTimer?.cancel();
    _pingTimer = null;
    _safetyPollTimer = null;

    if (_currentConversationId != conversationId) return;

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: 1 << (_reconnectAttempts - 1));
      Future.delayed(delay, () {
        if (_currentConversationId == conversationId) {
          _tryConnectWs(conversationId);
        }
      });
    } else {
      _startPolling(conversationId);
    }
  }

  void _sendWs(Map<String, dynamic> payload) {
    try {
      _socket?.add(jsonEncode(payload));
    } catch (_) {}
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendWs({'kind': 'ping'});
    });
  }

  void _startHeartbeatTimer(int conversationId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      _api.touchPresence().catchError((_) {});
    });
  }

  // ─── Polling fallback ────────────────────────────────────────

  void _startPolling(int conversationId) {
    if (_polling) return;
    _polling = true;

    _scheduleNextPoll(conversationId);
    _startHeartbeatTimer(conversationId);
  }

  /// Safety-net poll that runs alongside an active WebSocket connection.
  /// Catches messages the server failed to push via WS events.
  /// Dedup is handled upstream in the BLoC.
  void _startSafetyPoll(int conversationId) {
    _safetyPollTimer?.cancel();
    _safetyPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_currentConversationId != conversationId) return;
      try {
        final resp = await _api.getMessagesSince(
          conversationId: conversationId,
          afterId: _lastSeenId > 0 ? _lastSeenId : null,
          updatedAfter: _lastUpdatedAfter,
        );
        final msgs = resp.messages ?? [];
        for (final msg in msgs) {
          if (msg.id != null && msg.id! > _lastSeenId) {
            _lastSeenId = msg.id!;
          }
          _controller.add(WsMessageCreated(msg));
        }
        if (msgs.isNotEmpty) {
          _lastUpdatedAfter = DateTime.now().toUtc().toIso8601String();
        }
      } catch (_) {}
    });
  }

  void _scheduleNextPoll(int conversationId) {
    if (!_polling || _currentConversationId != conversationId) return;

    // Randomise interval 2-5s to reduce thundering herd
    final seconds = 2 + (DateTime.now().millisecondsSinceEpoch % 4);
    _pollTimer = Timer(Duration(seconds: seconds), () async {
      if (!_polling || _currentConversationId != conversationId) return;
      try {
        final resp = await _api.getMessagesSince(
          conversationId: conversationId,
          afterId: _lastSeenId > 0 ? _lastSeenId : null,
          updatedAfter: _lastUpdatedAfter,
        );
        final msgs = resp.messages ?? [];
        for (final msg in msgs) {
          if (msg.id != null && msg.id! > _lastSeenId) {
            _lastSeenId = msg.id!;
          }
          _controller.add(WsMessageCreated(msg));
        }
        if (msgs.isNotEmpty) {
          _lastUpdatedAfter = DateTime.now().toUtc().toIso8601String();
        }
      } catch (_) {}
      _scheduleNextPoll(conversationId);
    });
  }

  // ─── Event dispatching ───────────────────────────────────────

  /// Propagates conversationId from the outer WS envelope into the nested
  /// message map if the message itself omits it (common server omission).
  Map<String, dynamic> _patchConvId(
    Map<String, dynamic> envelope,
    dynamic rawMsg,
  ) {
    final msg = rawMsg is Map<String, dynamic>
        ? rawMsg
        : (rawMsg is Map ? Map<String, dynamic>.from(rawMsg) : <String, dynamic>{});
    if (msg['conversationId'] != null || msg['conversation_id'] != null) return msg;
    final convId = envelope['conversationId'] ?? envelope['conversation_id'] ?? _currentConversationId;
    if (convId == null) return msg;
    return {...msg, 'conversationId': convId};
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _dispatchEvent(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    switch (kind) {
      case 'message.created':
        final msg = ConversationMessage.fromJson(_patchConvId(json, json['message'] ?? json['data'] ?? json));
        if (msg.id != null && msg.id! > _lastSeenId) _lastSeenId = msg.id!;
        _controller.add(WsMessageCreated(msg));
        break;

      case 'message.updated':
        final msg = ConversationMessage.fromJson(_patchConvId(json, json['message'] ?? json['data'] ?? json));
        _controller.add(WsMessageUpdated(msg));
        break;

      case 'message.deleted':
        _controller.add(WsMessageDeleted(
          messageId: (json['messageId'] ?? json['message_id'] ?? 0) as int,
          conversationId:
              (json['conversationId'] ?? json['conversation_id'] ?? _currentConversationId ?? 0)
                  as int,
        ));
        break;

      case 'reactions.updated':
        final rawReactions = json['reactions'] ?? [];
        final reactions = (rawReactions as List)
            .map((r) => MessageReaction.fromJson(r))
            .toList();
        _controller.add(WsReactionsUpdated(
          messageId: (json['messageId'] ?? json['message_id'] ?? 0) as int,
          reactions: reactions,
        ));
        break;

      case 'delivered':
        _controller.add(WsDelivered(
          messageId: (json['messageId'] ?? 0) as int,
          userId: (json['userId'] ?? '').toString(),
        ));
        break;

      case 'read':
        _controller.add(WsRead(
          messageId: (json['messageId'] ?? 0) as int,
          userId: (json['userId'] ?? '').toString(),
        ));
        break;

      case 'typing':
        _controller.add(WsTyping(
          userId: (json['userId'] ?? '').toString(),
          isTyping: json['isTyping'] != false,
          conversationId: _parseInt(json['conversationId']) ?? _currentConversationId ?? 0,
        ));
        break;

      case 'presence':
        _controller.add(WsPresence(
          userId: (json['userId'] ?? '').toString(),
          isOnline: json['online'] == true || json['isOnline'] == true,
        ));
        break;

      case 'pong':
        _controller.add(WsPong());
        break;
    }
  }
}
