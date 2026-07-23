import 'dart:async';

import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

import '../controller/call_controller_v2.dart';
import '../models/call_protocol.dart';
import 'call_api_v2.dart';
import 'call_dismiss_registry.dart';
import 'callkit_v2.dart';

/// Calling module v2 — push entry points (§5).
///
/// Two payloads arrive as high-priority FCM DATA messages (and as APNs VoIP
/// pushes on iOS when configured):
///
///   `incoming_call`  — ring this device (show CallKit / in-app incoming UI)
///   `call_cancelled` — stop ringing (caller cancelled / answered elsewhere)
///
/// Wire-up: the app's existing FCM handlers call [maybeHandle] for both
/// foreground messages and the background isolate. Returns true when the
/// message belonged to the calling module (callers should stop processing).
class CallPushV2 {
  CallPushV2._();

  /// Foreground / background-with-process entry (controller available).
  static Future<bool> maybeHandle(RemoteMessage message) async {
    final data = message.data;
    final type = data['type']?.toString();
    if (data['signalVersion'] != '2') return false;

    if (type == 'incoming_call') {
      final push = IncomingCallPushV2.tryParse(data);
      if (push == null) return true;
      if (await _shouldIgnoreIncoming(push)) return true;
      debugPrint('📞 [CallPushV2] incoming_call ${push.callId}');
      await CallControllerV2.instance.handleIncomingPush(push);
      return true;
    }

    if (type == 'call_cancelled') {
      final callId = data['callId']?.toString() ?? '';
      debugPrint('📞 [CallPushV2] call_cancelled $callId');
      await _handleCancel(callId);
      return true;
    }

    return false;
  }

  /// Killed-app background isolate entry (Android data push). The Dart VM
  /// here has no UI — show the native call UI, then SUPERVISE the ring:
  /// the plugin's notification Accept/Decline buttons only emit events to a
  /// live Dart listener (they never relaunch the app), so this isolate must
  /// stay alive to relay the user's choice to the signaling server. Media
  /// connects when the app is opened (CallControllerV2 cold-start resume).
  @pragma('vm:entry-point')
  static Future<bool> maybeHandleBackground(RemoteMessage message) async {
    final data = message.data;
    if (data['signalVersion'] != '2') return false;
    final type = data['type']?.toString();

    if (type == 'incoming_call') {
      final push = IncomingCallPushV2.tryParse(data);
      if (push == null || push.isExpired) return true;
      if (await _shouldIgnoreIncoming(push)) return true;

      // Cross-isolate busy guard: this device may already be on a call in the
      // main isolate (whose state the background isolate can't see). If so,
      // auto-reject the second call as busy instead of ringing a second time.
      if (await _isBusyWithOtherCall(push.callId)) {
        debugPrint('📞 [CallPushV2] busy — auto-rejecting incoming ${push.callId}');
        await CallApiV2.instance
            .action(callId: push.callId, action: 'reject', reason: 'busy');
        return true;
      }

      // Authoritative check before ringing — skip ghost rings when offline
      // delivery arrives after the caller already hung up.
      final snapshot = await CallApiV2.instance.getCall(push.callId);
      if (snapshot != null && snapshot.state != CallState.ringing) {
        debugPrint('📞 [CallPushV2] skip stale incoming ${push.callId} (${snapshot.state})');
        await CallDismissRegistry.markDismissed(push.callId);
        return true;
      }

      await CallKitV2.instance.showIncoming(push);
      // Do NOT await — return quickly so a queued `call_cancelled` FCM can
      // be processed while this isolate supervises the ring.
      unawaited(_superviseBackgroundRing(push));
      return true;
    }

    if (type == 'call_cancelled') {
      final callId = data['callId']?.toString() ?? '';
      await _handleCancel(callId);
      return true;
    }

    return false;
  }

  static Future<void> _handleCancel(String callId) async {
    if (callId.isEmpty) return;
    await CallDismissRegistry.markDismissed(callId);
    await CallKitV2.instance.end(callId);
    // Controller may not be alive in the background isolate.
    try {
      await CallControllerV2.instance.dismissCancelledCall(callId);
    } catch (_) {}
  }

  static Future<bool> _shouldIgnoreIncoming(IncomingCallPushV2 push) async {
    if (push.isExpired) return true;
    if (await CallDismissRegistry.isDismissed(push.callId)) {
      debugPrint('📞 [CallPushV2] ignore dismissed incoming ${push.callId}');
      return true;
    }
    return false;
  }

  /// Keeps the background isolate alive while the native UI rings so that
  /// Accept/Decline reach the server even with the app killed (the #1 cause
  /// of "attended but nothing happened"). Also polls the authoritative call
  /// state so an answer on another device dismisses this ring quickly.
  static Future<void> _superviseBackgroundRing(IncomingCallPushV2 push) async {
    final done = Completer<void>();
    var accepted = false;

    void finish() {
      if (!done.isCompleted) done.complete();
    }

    final sub = FlutterCallkitIncoming.onEvent.listen((event) async {
      if (event == null) return;
      switch (event) {
        case CallEventActionCallAccept(:final id) when id == push.callId:
          accepted = true;
          debugPrint('📞 [CallPushV2] bg accept ${push.callId} → REST');
          await CallApiV2.instance.action(
            callId: push.callId,
            action: 'accept',
            deviceId: await _storedDeviceId(),
          );
          finish();
        case CallEventActionCallDecline(:final id) when id == push.callId:
          debugPrint('📞 [CallPushV2] bg decline ${push.callId} → REST');
          await CallApiV2.instance.action(callId: push.callId, action: 'reject');
          finish();
        case CallEventActionCallTimeout(:final id) when id == push.callId:
          finish(); // server ring alarm is authoritative
        case CallEventActionCallEnded(:final id) when id == push.callId:
          finish();
        default:
          break;
      }
    });

    // Answered/cancelled elsewhere: poll authoritative state (cancel FCM may
    // now arrive in parallel since the handler returns without awaiting us).
    final poll = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (await CallDismissRegistry.isDismissed(push.callId) && !accepted) {
        await CallKitV2.instance.end(push.callId);
        finish();
        return;
      }
      final snapshot = await CallApiV2.instance.getCall(push.callId);
      if (snapshot != null && snapshot.state != CallState.ringing && !accepted) {
        await CallDismissRegistry.markDismissed(push.callId);
        await CallKitV2.instance.end(push.callId);
        finish();
      }
    });

    // Safety cap below Android's background execution window; late accepts
    // are still rescued by the cold-start resume when the app opens.
    final cap = Timer(const Duration(seconds: 28), finish);

    try {
      await done.future;
    } finally {
      cap.cancel();
      poll.cancel();
      await sub.cancel();
      await CallDismissRegistry.markDismissed(push.callId);
    }
  }

  /// True when this device is already on a different live call. Reads the
  /// cross-isolate busy marker the controller persists, then confirms with the
  /// server (so a stale marker from a crashed call doesn't block real calls).
  static Future<bool> _isBusyWithOtherCall(String incomingCallId) async {
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      final activeId = await prefs.getString(CallControllerV2.busyMarkerKey);
      if (activeId == null || activeId.isEmpty || activeId == incomingCallId) {
        return false;
      }
      // Confirm the marked call is genuinely still live (self-heal stale flags).
      final snapshot = await CallApiV2.instance.getCall(activeId);
      if (snapshot == null || snapshot.state == CallState.ended) {
        await prefs.remove(CallControllerV2.busyMarkerKey);
        return false;
      }
      return true;
    } catch (_) {
      return false; // never block a real call on an error
    }
  }

  /// Same secure-storage key the controller uses — keeps the accepted
  /// deviceId consistent so media credentials target this device when the
  /// app opens and the controller resumes the call.
  static Future<String> _storedDeviceId() async {
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      final stored = await prefs.getString('call_v2_device_id');
      if (stored != null && stored.isNotEmpty) return stored;
    } catch (_) {}
    return 'android-bg';
  }
}
