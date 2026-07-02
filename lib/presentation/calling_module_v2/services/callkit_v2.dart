import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../models/call_protocol.dart';
import 'callkit_event_hub.dart';

/// Calling module v2 — native incoming-call UI bridge.
///
/// Wraps `flutter_callkit_incoming`: full-screen incoming UI over the lock
/// screen on Android (from the FCM data push, app killed included) and
/// CallKit on iOS. The controller subscribes to [events] for user actions
/// (accept / decline / timeout) and keeps the native UI in sync with the
/// server state machine.
class CallKitV2 {
  CallKitV2._();
  static final CallKitV2 instance = CallKitV2._();

  /// Native call-UI actions, normalized.
  final StreamController<CallKitActionV2> _actions =
      StreamController<CallKitActionV2>.broadcast();
  Stream<CallKitActionV2> get events => _actions.stream;

  StreamSubscription<CallEvent?>? _subscription;
  final Set<String> _shown = <String>{};

  /// Fired when iOS PushKit reports a new/updated VoIP token. The controller
  /// re-reads [voipToken] and registers it with the server.
  VoidCallback? onVoipTokenUpdated;

  void listen() {
    _subscription?.cancel();
    // Via the hub — NEVER subscribe to FlutterCallkitIncoming.onEvent
    // directly in the main isolate (single-listener EventChannel).
    _subscription = CallKitEventHub.instance.stream.listen((event) {
      if (event == null) return;
      switch (event) {
        case CallEventActionCallAccept(:final id):
          _actions.add(CallKitActionV2(kind: CallKitActionKind.accept, callId: id));
        case CallEventActionCallDecline(:final id):
          _actions.add(CallKitActionV2(kind: CallKitActionKind.decline, callId: id));
        case CallEventActionCallTimeout(:final id):
          _actions.add(CallKitActionV2(kind: CallKitActionKind.timeout, callId: id));
        case CallEventActionCallEnded(:final id):
          _actions.add(CallKitActionV2(kind: CallKitActionKind.ended, callId: id));
        case CallEventActionDidUpdateDevicePushTokenVoip():
          onVoipTokenUpdated?.call();
        default:
          break;
      }
    });
  }

  /// Shows the native incoming-call UI (idempotent per callId).
  Future<void> showIncoming(IncomingCallPushV2 push) async {
    if (_shown.contains(push.callId)) return;
    _shown.add(push.callId);

    final params = CallKitParams(
      id: push.callId,
      nameCaller: push.callerName,
      appName: 'DocTak',
      avatar: push.callerAvatar,
      handle: '',
      type: push.callType == CallTypeV2.video ? 1 : 0,
      duration: CallTimings.ringTimeout.inMilliseconds,
      extra: {
        'callId': push.callId,
        'callerId': push.callerId,
        'callerName': push.callerName,
        'callerAvatar': push.callerAvatar,
        'callType': push.callType.wire,
        'signalVersion': '2',
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1A2332',
        actionColor: '#0955fa',
        textColor: '#ffffff',
        textAccept: 'Accept',
        textDecline: 'Decline',
        incomingCallNotificationChannelName: 'DocTak Calls',
        missedCallNotificationChannelName: 'DocTak Missed Calls',
        isShowCallID: false,
        isShowFullLockedScreen: true,
        isImportant: true,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    try {
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } catch (e) {
      debugPrint('📞 [CallKitV2] showCallkitIncoming failed: $e');
    }
  }

  /// Native "connected call" UI for outgoing/active calls (keeps the iOS
  /// audio session alive in background — §5.1/§5.2).
  Future<void> startOutgoing({
    required String callId,
    required String peerName,
    required String peerAvatar,
    required CallTypeV2 callType,
  }) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    final params = CallKitParams(
      id: callId,
      nameCaller: peerName,
      appName: 'DocTak',
      avatar: peerAvatar,
      handle: '',
      type: callType == CallTypeV2.video ? 1 : 0,
      extra: {'callId': callId, 'signalVersion': '2'},
    );
    try {
      await FlutterCallkitIncoming.startCall(params);
    } catch (e) {
      debugPrint('📞 [CallKitV2] startCall failed: $e');
    }
  }

  Future<void> setConnected(String callId) async {
    try {
      await FlutterCallkitIncoming.setCallConnected(callId);
    } catch (_) {}
  }

  Future<void> end(String callId) async {
    _shown.remove(callId);
    try {
      await FlutterCallkitIncoming.endCall(callId);
    } catch (_) {}
  }

  Future<void> endAll() async {
    _shown.clear();
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {}
  }

  /// Calls still shown by the OS — used on cold start to resume a call the
  /// user accepted while the Dart VM was dead.
  Future<List<Map<String, dynamic>>> activeCalls() async {
    try {
      final List<dynamic> calls = await FlutterCallkitIncoming.activeCalls();
      return calls
          .whereType<Map>()
          .map((call) => Map<String, dynamic>.from(call))
          .toList();
    } catch (_) {}
    return const [];
  }

  /// True when the native call entry was created by this module
  /// (extra.signalVersion == '2'). Used to ignore legacy-module calls.
  Future<bool> ownsCall(String callId) async {
    if (_shown.contains(callId)) return true;
    for (final call in await activeCalls()) {
      if (call['id']?.toString() != callId) continue;
      final extra = call['extra'];
      return extra is Map && extra['signalVersion']?.toString() == '2';
    }
    return false;
  }

  /// iOS PushKit VoIP token (empty elsewhere).
  Future<String> voipToken() async {
    if (!Platform.isIOS) return '';
    try {
      return await FlutterCallkitIncoming.getDevicePushTokenVoIP() ?? '';
    } catch (_) {
      return '';
    }
  }
}

enum CallKitActionKind { accept, decline, timeout, ended }

class CallKitActionV2 {
  final CallKitActionKind kind;
  final String callId;
  const CallKitActionV2({required this.kind, required this.callId});
}
