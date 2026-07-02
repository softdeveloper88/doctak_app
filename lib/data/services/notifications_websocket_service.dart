import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io' as io;

import 'package:doctak_app/core/utils/app/AppData.dart';

// ─── Event types ────────────────────────────────────────────────────────────

sealed class NotificationWsEvent {}

class NotificationNew extends NotificationWsEvent {
  final Map<String, dynamic> data;
  NotificationNew(this.data);
}

class MeetingEnded extends NotificationWsEvent {
  final String channel;
  final int? meetingId;
  final String? endedAt;
  MeetingEnded({required this.channel, this.meetingId, this.endedAt});
}

class MeetingInvitation extends NotificationWsEvent {
  final Map<String, dynamic> data;
  MeetingInvitation(this.data);
}

class ChatMessageNotification extends NotificationWsEvent {
  final int conversationId;
  final Map<String, dynamic> message;
  ChatMessageNotification({required this.conversationId, required this.message});
}

class ChatTypingNotification extends NotificationWsEvent {
  final int conversationId;
  final String userId;
  final bool isTyping;
  ChatTypingNotification({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });
}

class NotificationCountsUpdated extends NotificationWsEvent {
  final int notifications;
  final int friendRequests;
  final int messages;
  NotificationCountsUpdated({
    required this.notifications,
    required this.friendRequests,
    required this.messages,
  });
}

class FeedPostArrived extends NotificationWsEvent {
  final String postId;
  final String authorName;
  final String? authorAvatar;
  final String preview;
  FeedPostArrived({
    required this.postId,
    required this.authorName,
    this.authorAvatar,
    required this.preview,
  });
}

class NotificationWsPong extends NotificationWsEvent {}

/// Calling module v2 — incoming call delivered over the per-user channel.
/// This is the foreground fast-path (app alive): it arrives instantly over
/// the already-open socket, independent of FCM push latency/delivery.
class IncomingCallWsEvent extends NotificationWsEvent {
  final String callId;
  final String callerId;
  final String callerName;
  final String callerAvatar;
  final String callType; // "audio" | "video"
  final int expiresAt;
  IncomingCallWsEvent({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.callerAvatar,
    required this.callType,
    required this.expiresAt,
  });
}

/// Calling module v2 — stop ringing (caller cancelled / answered elsewhere).
class CallCancelledWsEvent extends NotificationWsEvent {
  final String callId;
  CallCancelledWsEvent(this.callId);
}

// ─── Service ─────────────────────────────────────────────────────────────────

/// Singleton WebSocket service for user-scoped real-time notifications.
///
/// Connects to the doctak-node UserChannel Durable Object by first fetching
/// a short-lived ticket from [/api/notifications/ws-ticket], then opening a
/// native WebSocket to the returned [wsUrl].
///
/// Usage:
///   await NotificationsWebSocketService().connect();
///   NotificationsWebSocketService().events.listen((event) { ... });
///   NotificationsWebSocketService().disconnect();
class NotificationsWebSocketService {
  static final NotificationsWebSocketService _instance =
      NotificationsWebSocketService._internal();
  factory NotificationsWebSocketService() => _instance;
  NotificationsWebSocketService._internal();

  final StreamController<NotificationWsEvent> _controller =
      StreamController<NotificationWsEvent>.broadcast();

  Stream<NotificationWsEvent> get events => _controller.stream;

  io.WebSocket? _socket;
  bool _connected = false;
  bool _connecting = false;

  Timer? _pingTimer;
  Timer? _reconnectTimer;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  String? _cachedWsUrl;

  // ─── Public API ─────────────────────────────────────────────

  bool get isConnected => _connected;

  Future<void> connect() async {
    if (_connected || _connecting) return;

    final userId = AppData.logInUserId?.toString().trim() ?? '';
    final token = AppData.userToken?.trim() ?? '';
    if (userId.isEmpty || token.isEmpty) {
      log('NotificationsWebSocketService: Missing userId or token, cannot connect');
      return;
    }

    final nodeUrl = AppData.nodeApiUrl.trim();
    if (nodeUrl.isEmpty) {
      log('NotificationsWebSocketService: nodeApiUrl is empty');
      return;
    }

    _connecting = true;
    _reconnectAttempts = 0;
    await _fetchTicketAndConnect();
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer = null;

    _connected = false;
    _connecting = false;
    _reconnectAttempts = 0;
    _cachedWsUrl = null;

    final s = _socket;
    _socket = null;
    await s?.close(io.WebSocketStatus.normalClosure);
  }

  // ─── Internal connection logic ───────────────────────────────

  Future<void> _fetchTicketAndConnect() async {
    try {
      final nodeUrl = AppData.nodeApiUrl;
      final base = nodeUrl.endsWith('/')
          ? nodeUrl.substring(0, nodeUrl.length - 1)
          : nodeUrl;
      final ticketUrl = Uri.parse('$base/api/notifications/ws-ticket');

      final client = io.HttpClient();
      final request = await client.getUrl(ticketUrl);
      request.headers.set('Authorization', 'Bearer ${AppData.userToken}');
      request.headers.set('Accept', 'application/json');

      final response = await request.close();
      if (response.statusCode != 200) {
        log('NotificationsWebSocketService: ws-ticket returned ${response.statusCode}');
        _connecting = false;
        return;
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        log('NotificationsWebSocketService: Invalid ticket response');
        _connecting = false;
        return;
      }
      final json = Map<String, dynamic>.from(decoded);
      final wsUrl = json['wsUrl']?.toString();

      if (wsUrl == null || wsUrl.isEmpty) {
        log('NotificationsWebSocketService: No wsUrl in ticket response');
        _connecting = false;
        return;
      }

      _cachedWsUrl = wsUrl;
      _openSocket(wsUrl);
    } catch (e) {
      log('NotificationsWebSocketService: _fetchTicketAndConnect failed: $e');
      _connecting = false;
      _scheduleReconnect();
    }
  }

  void _openSocket(String wsUrl) {
    io.WebSocket.connect(wsUrl).then((socket) {
      _socket = socket;
      _connected = true;
      _connecting = false;
      _reconnectAttempts = 0;

      _startPingTimer();

      socket.listen(
        _onWsMessage,
        onDone: _onWsClosed,
        onError: (_) => _onWsClosed(),
        cancelOnError: false,
      );

      log('NotificationsWebSocketService: Connected to $wsUrl');
    }).catchError((e) {
      log('NotificationsWebSocketService: Connection failed: $e');
      _connecting = false;
      _scheduleReconnect();
    });
  }

  void _onWsMessage(dynamic raw) {
    if (raw is! String) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _dispatchEvent(json);
    } catch (_) {}
  }

  void _onWsClosed() {
    _socket = null;
    _connected = false;
    _pingTimer?.cancel();
    _pingTimer = null;
    log('NotificationsWebSocketService: Socket closed');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      log('NotificationsWebSocketService: Max reconnect attempts reached');
      return;
    }

    _reconnectAttempts++;
    // Exponential back-off: 2s, 4s, 8s, 16s, 32s
    final delay = Duration(seconds: 2 << (_reconnectAttempts - 1));
    log('NotificationsWebSocketService: Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (!_connected && !_connecting) {
        if (_cachedWsUrl != null) {
          _connecting = true;
          _openSocket(_cachedWsUrl!);
        } else {
          _connecting = true;
          await _fetchTicketAndConnect();
        }
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      try {
        _socket?.add(jsonEncode({'kind': 'ping'}));
      } catch (_) {}
    });
  }

  void _dispatchEvent(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    if (kind == null) return;

    switch (kind) {
      case 'pong':
        _controller.add(NotificationWsPong());
      case 'notification':
      case 'notification.new':
        _controller.add(NotificationNew(json));
      case 'counts':
        final counts = json['counts'];
        if (counts is Map) {
          final map = Map<String, dynamic>.from(counts);
          _controller.add(NotificationCountsUpdated(
            notifications: _asInt(map['notifications']),
            friendRequests: _asInt(map['friendRequests']),
            messages: _asInt(map['messages']),
          ));
        }
      case 'feed.post':
        final post = json['post'];
        if (post is Map) {
          final map = Map<String, dynamic>.from(post);
          final postId = (map['id'] ?? '').toString();
          if (postId.isNotEmpty) {
            final orgName = (map['organizationName'] ?? '').toString().trim();
            _controller.add(FeedPostArrived(
              postId: postId,
              authorName: orgName.isNotEmpty
                  ? orgName
                  : (map['authorName'] ?? 'Someone in your network').toString(),
              authorAvatar: (map['authorAvatar'] as String?)?.trim(),
              preview: (map['preview'] ?? 'shared a new post').toString(),
            ));
          }
        }
      case 'meeting.ended':
        _controller.add(MeetingEnded(
          channel: json['channel'] as String? ?? '',
          meetingId: json['meetingId'] as int?,
          endedAt: json['endedAt'] as String?,
        ));
      case 'meeting.invitation':
        _controller.add(MeetingInvitation(json));
      case 'chat.message':
        final convId = json['conversationId'] ?? json['conversation_id'];
        final convIdInt = convId is int ? convId : int.tryParse('$convId') ?? 0;
        final message = json['message'];
        if (convIdInt > 0 && message is Map) {
          _controller.add(ChatMessageNotification(
            conversationId: convIdInt,
            message: Map<String, dynamic>.from(message),
          ));
        }
      case 'chat.typing':
        final convId = json['conversationId'] ?? json['conversation_id'];
        final convIdInt = convId is int ? convId : int.tryParse('$convId') ?? 0;
        final userId = (json['userId'] ?? json['user_id'] ?? '').toString();
        if (convIdInt > 0 && userId.isNotEmpty) {
          _controller.add(ChatTypingNotification(
            conversationId: convIdInt,
            userId: userId,
            isTyping: json['isTyping'] != false,
          ));
        }
      case 'call.incoming':
        final caller = json['caller'];
        final callerMap = caller is Map ? Map<String, dynamic>.from(caller) : const {};
        final callId = (json['callId'] ?? '').toString();
        if (callId.isNotEmpty) {
          _controller.add(IncomingCallWsEvent(
            callId: callId,
            callerId: (callerMap['id'] ?? '').toString(),
            callerName: (callerMap['name'] ?? 'Unknown').toString(),
            callerAvatar: (callerMap['avatar'] ?? '').toString(),
            callType: (json['callType'] ?? 'audio').toString(),
            expiresAt: (json['expiresAt'] is int)
                ? json['expiresAt'] as int
                : int.tryParse('${json['expiresAt']}') ??
                    DateTime.now().add(const Duration(seconds: 45)).millisecondsSinceEpoch,
          ));
        }
      case 'call.cancelled':
        final callId = (json['callId'] ?? '').toString();
        if (callId.isNotEmpty) _controller.add(CallCancelledWsEvent(callId));
      default:
        log('NotificationsWebSocketService: Unhandled event kind: $kind');
    }
  }

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
