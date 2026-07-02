import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/call_protocol.dart';

/// Calling module v2 — per-call signaling WebSocket client.
///
/// Connects to the CallSession Durable Object
/// (`wss://<chat-worker>/call-ws/:callId?token=...`), heartbeats every 25s,
/// and reconnects with backoff while the call is live. After a reconnect the
/// server replays an authoritative `call.state` snapshot (and
/// `call.join_channel` if media credentials were already issued), so the
/// controller reconciles automatically (§4, edge 28).
class CallSignalingV2 {
  final String callId;
  String _wsUrl;

  /// Mints a fresh ws-ticket before a reconnect attempt (tokens are short-lived).
  final Future<String?> Function()? refreshWsUrl;

  void Function(SignalEnvelopeV2 envelope)? onEvent;
  void Function(bool connected)? onStatus;

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  bool _closedByCaller = false;
  Duration _backoff = const Duration(milliseconds: 800);
  static const _maxBackoff = Duration(seconds: 8);

  CallSignalingV2({
    required this.callId,
    required String wsUrl,
    this.refreshWsUrl,
  }) : _wsUrl = wsUrl;

  bool get isConnected => _socket?.readyState == WebSocket.open;

  Future<void> connect() async {
    _closedByCaller = false;
    await _open();
  }

  Future<void> _open() async {
    try {
      final socket = await WebSocket.connect(_wsUrl)
          .timeout(const Duration(seconds: 12));
      _socket = socket;
      _backoff = const Duration(milliseconds: 800);
      onStatus?.call(true);

      _heartbeat?.cancel();
      _heartbeat = Timer.periodic(CallTimings.heartbeatInterval, (_) {
        send('heartbeat');
      });

      _subscription = socket.listen(
        (dynamic message) {
          if (message is! String) return;
          try {
            final decoded = jsonDecode(message);
            if (decoded is Map) {
              final envelope =
                  SignalEnvelopeV2.tryParse(Map<String, dynamic>.from(decoded));
              if (envelope != null) onEvent?.call(envelope);
            }
          } catch (_) {
            // ignore malformed frames
          }
        },
        onDone: _handleClosed,
        onError: (_) => _handleClosed(),
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('📞 [CallSignalingV2] connect failed: $e');
      _handleClosed();
    }
  }

  void _handleClosed() {
    _heartbeat?.cancel();
    _heartbeat = null;
    _subscription?.cancel();
    _subscription = null;
    _socket = null;
    onStatus?.call(false);
    if (_closedByCaller) return;

    final delay = _backoff;
    _backoff = _backoff * 2 > _maxBackoff ? _maxBackoff : _backoff * 2;
    _reconnectTimer = Timer(delay, () async {
      if (_closedByCaller) return;
      final fresh = await refreshWsUrl?.call();
      if (fresh != null && fresh.isNotEmpty) _wsUrl = fresh;
      await _open();
    });
  }

  /// Sends a client signal (§2.2). Returns false when the socket is down —
  /// callers should fall back to the REST action endpoint for critical verbs.
  bool send(String type, [Map<String, dynamic> payload = const {}]) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return false;
    try {
      socket.add(jsonEncode(SignalEnvelopeV2(
        type: type,
        callId: callId,
        ts: DateTime.now().millisecondsSinceEpoch,
        payload: payload,
      ).toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }

  void close() {
    _closedByCaller = true;
    _reconnectTimer?.cancel();
    _heartbeat?.cancel();
    _subscription?.cancel();
    try {
      _socket?.close(1000, 'client done');
    } catch (_) {}
    _socket = null;
  }
}
