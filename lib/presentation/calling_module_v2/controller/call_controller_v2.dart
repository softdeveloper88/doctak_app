import 'dart:async';
import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
import 'package:doctak_app/data/services/notifications_websocket_service.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../models/call_protocol.dart';
import '../screens/call_screen_v2.dart';
import '../services/call_agora_v2.dart';
import '../services/call_api_v2.dart';
import '../services/call_signaling_v2.dart';
import '../services/callkit_v2.dart';

/// Client-side phase mirror of the server state machine (§4).
enum CallPhaseV2 {
  idle,
  outgoing, // INITIATING/RINGING as caller
  incoming, // RINGING as callee
  connecting, // CONNECTING
  active, // ACTIVE
  reconnecting, // RECONNECTING
  ended,
}

/// Calling module v2 — central controller (singleton ChangeNotifier).
///
/// Orchestrates the REST control plane, the per-call signaling socket, the
/// Agora engine and the native CallKit UI. The server's CallSession Durable
/// Object owns the canonical state; every `call.state` snapshot reconciles
/// this mirror (server wins, §4).
class CallControllerV2 extends ChangeNotifier {
  CallControllerV2._();
  static final CallControllerV2 instance = CallControllerV2._();

  // ── observable state ────────────────────────────────────────────────
  CallPhaseV2 phase = CallPhaseV2.idle;
  String? callId;
  CallParticipant? peer;
  CallTypeV2 callType = CallTypeV2.audio;
  bool muted = false;
  bool videoEnabled = false;
  bool speakerOn = false;
  CallMediaStateV2 peerMedia = const CallMediaStateV2();
  int networkQuality = 5;
  DateTime? connectedAt;
  CallEndReason? endReason;
  String? errorMessage;
  String? upgradeRequestFrom;

  final CallAgoraV2 agora = CallAgoraV2();
  CallSignalingV2? _signaling;
  bool _initialized = false;
  bool _navigatedToCallScreen = false;
  String _deviceId = 'flutter';
  StreamSubscription<CallKitActionV2>? _callKitSub;
  StreamSubscription<NotificationWsEvent>? _wsSub;
  Timer? _endedResetTimer;

  /// Call ids whose CallKit entry WE ended programmatically (dismissal, not a
  /// user tap). flutter_callkit_incoming reports an end on a not-yet-accepted
  /// call as a DECLINE event, and that event can interleave before our phase
  /// change — so without this guard a dismissal round-trips into a `reject`
  /// the caller wrongly sees as "declined". Echoed decline/timeout/ended for
  /// these ids are ignored.
  final Set<String> _selfDismissed = <String>{};

  String get _platform => Platform.isIOS ? 'ios' : 'android';
  bool get isLive =>
      phase == CallPhaseV2.outgoing ||
      phase == CallPhaseV2.incoming ||
      phase == CallPhaseV2.connecting ||
      phase == CallPhaseV2.active ||
      phase == CallPhaseV2.reconnecting;

  // ── lifecycle ───────────────────────────────────────────────────────

  /// Call after app start and again after login. Listener wiring happens
  /// once; the token-dependent steps (VoIP registration, live-call
  /// reconciliation) re-run on every call so a fresh login picks them up.
  Future<void> init() async {
    if (!_initialized) {
      _initialized = true;

      try {
        final prefs = SecureStorageService.instance;
        await prefs.initialize();
        var stored = await prefs.getString('call_v2_device_id');
        if (stored == null || stored.isEmpty) {
          stored = const Uuid().v4();
          await prefs.setString('call_v2_device_id', stored);
        }
        _deviceId = stored;
      } catch (_) {
        _deviceId = const Uuid().v4();
      }

      CallKitV2.instance.listen();
      _callKitSub?.cancel();
      _callKitSub = CallKitV2.instance.events.listen(_onCallKitAction);
      // PushKit delivers the VoIP token asynchronously (and on rotation) —
      // register it whenever it arrives, not just at init.
      CallKitV2.instance.onVoipTokenUpdated = _registerVoipToken;

      // Foreground fast-path: the per-user notifications socket also carries
      // call.incoming / call.cancelled. When the app is alive this delivers a
      // call instantly, independent of FCM push latency/delivery — the #1
      // cause of "incoming call doesn't show". The socket is connected by the
      // app shell; we just make sure it's up.
      _wsSub?.cancel();
      _wsSub = NotificationsWebSocketService().events.listen(_onWsNotification);
      unawaited(NotificationsWebSocketService().connect());
    }

    // iOS killed-app delivery: register the PushKit VoIP token (§5.2). It may
    // not be ready yet at first init — onVoipTokenUpdated covers that case.
    await _registerVoipToken();

    if (!isLive) await _resumeAfterColdStart();
  }

  /// Registers this device's iOS VoIP token with the server (no-op elsewhere).
  Future<void> _registerVoipToken() async {
    if (!Platform.isIOS) return;
    final voipToken = await CallKitV2.instance.voipToken();
    if (voipToken.isNotEmpty) {
      unawaited(CallApiV2.instance
          .registerVoipToken(token: voipToken, deviceId: _deviceId));
    }
  }

  /// Re-reconcile when the app returns to the foreground.
  ///
  /// When the app is merely BACKGROUNDED (not killed) and the call is accepted
  /// from the native UI, the accept is handled by the FCM background isolate
  /// (REST accept → the peer connects) but its CallKit events never reach this
  /// (main) isolate — so the controller stays idle and no call screen opens.
  /// `init()` only runs once, so resume must re-run the reconcile to catch up.
  Future<void> onAppResumed() async {
    if (isLive) {
      // Already tracking the call — make sure its screen is on top (the user
      // may have accepted from the lock screen / notification).
      if (!_navigatedToCallScreen) _navigateToCallScreen();
      return;
    }
    await _resumeAfterColdStart();
  }

  /// Reconcile with the server after a cold start: a call accepted from the
  /// native UI while the Dart VM was dead, an in-flight call after an OS
  /// kill (§4 reconcile / edge 17, 28), and stale native call UIs that must
  /// not keep ringing (WhatsApp-grade hygiene, edge 26).
  Future<void> _resumeAfterColdStart() async {
    // 1. Calls the OS UI still shows.
    final nativeCalls = await CallKitV2.instance.activeCalls();
    final v2Entries = <({String id, Map<String, dynamic> extra, bool accepted})>[];
    for (final call in nativeCalls) {
      final extra = call['extra'];
      final extraMap = extra is Map ? Map<String, dynamic>.from(extra) : const <String, dynamic>{};
      if (extraMap['signalVersion'] != '2') continue;
      final id = extraMap['callId']?.toString() ?? call['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      v2Entries.add((
        id: id,
        extra: extraMap,
        accepted: call['isAccepted'] == true || call['accepted'] == true,
      ));
    }

    for (final entry in v2Entries) {
      if (entry.accepted) {
        await _connectAsCallee(
          callId: entry.id,
          caller: CallParticipant(
            id: entry.extra['callerId']?.toString() ?? '',
            name: entry.extra['callerName']?.toString() ?? 'Unknown',
            avatar: entry.extra['callerAvatar']?.toString() ?? '',
          ),
          type: CallTypeV2.fromWire(entry.extra['callType']?.toString()),
          sendAccept: true,
        );
        return;
      }
    }

    // 2. Server-side state is the truth for everything else.
    final active = await CallApiV2.instance
        .getActiveCall(deviceId: _deviceId, platform: _platform);

    if (active == null) {
      // No ACTIVE/CONNECTING call for us. This does NOT mean the native UIs
      // are stale: `/api/calls/active` returns null for a RINGING call when
      // the DO can't report state (worker restart, transient error). Ending a
      // ringing CallKit here would emit a spurious DECLINE. So reap each
      // native entry only on POSITIVE confirmation it is terminal.
      for (final entry in v2Entries) {
        await _dismissNativeCallIfEnded(entry.id);
      }
      return;
    }

    final snapshot = active.snapshot;
    final myId = AppData.logInUserId?.toString() ?? '';
    final isCaller = snapshot.caller.id == myId;

    // Stale native entries for a different call than the live one — confirm
    // terminal before dismissing (never blind-end a possibly-ringing call).
    for (final entry in v2Entries) {
      if (entry.id != snapshot.callId) await _dismissNativeCallIfEnded(entry.id);
    }

    if (snapshot.state == CallState.ringing && !isCaller) {
      // Still ringing for us — restore incoming state so a CallKit accept
      // (or the in-app screen) routes into this controller.
      _resetTo(
        phase: CallPhaseV2.incoming,
        callId: snapshot.callId,
        peer: snapshot.caller,
        type: snapshot.callType,
      );
      _openSignaling(snapshot.callId, active.wsUrl);
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        _signaling?.send('call.ringing');
      });
      return;
    }

    if (snapshot.state == CallState.active ||
        snapshot.state == CallState.connecting ||
        snapshot.state == CallState.reconnecting) {
      _resetTo(
        phase: CallPhaseV2.connecting,
        callId: snapshot.callId,
        peer: isCaller ? snapshot.callee : snapshot.caller,
        type: snapshot.upgradedToVideo ? CallTypeV2.video : snapshot.callType,
      );
      _openSignaling(snapshot.callId, active.wsUrl);
      _navigateToCallScreen();
    }
  }

  /// Dismisses a native CallKit entry ONLY when the server positively
  /// confirms the call is terminal. If the call is still live (ringing) or the
  /// state is unknown (DO unreachable / network error), the native UI is left
  /// alone so a real ring is never turned into a spurious DECLINE.
  Future<void> _dismissNativeCallIfEnded(String nativeCallId) async {
    final snapshot = await CallApiV2.instance.getCall(nativeCallId);
    if (snapshot != null && snapshot.state == CallState.ended) {
      await _selfEndCallKit(nativeCallId);
    }
  }

  /// Ends a CallKit entry that WE decided to dismiss (call ended/cancelled/
  /// taken). Marks the id first so the plugin's resulting decline/ended echo
  /// is not mistaken for a user reject. The mark self-expires after the native
  /// event echoes drain.
  Future<void> _selfEndCallKit(String id) async {
    if (id.isEmpty) return;
    _selfDismissed.add(id);
    Timer(const Duration(seconds: 6), () => _selfDismissed.remove(id));
    await CallKitV2.instance.end(id);
  }

  // ── outgoing (§1.2) ─────────────────────────────────────────────────

  /// Starts an outgoing call. Permissions must already be granted by the
  /// caller (the chat screen runs the permission UI first).
  Future<void> startOutgoing({
    required CallParticipant callee,
    required CallTypeV2 type,
  }) async {
    if (isLive) return;
    _endedResetTimer?.cancel();
    _resetTo(phase: CallPhaseV2.outgoing, callId: null, peer: callee, type: type);
    _navigateToCallScreen();

    if (callee.id.trim().isEmpty) {
      // Defensive: a conversation row without a resolved peer id (see
      // user_chat_screen peer fallback) must not produce a server error.
      _finish(CallEndReason.error, message: 'Could not identify this user');
      return;
    }

    final result = await CallApiV2.instance.initiate(
      calleeId: callee.id,
      callType: type,
      deviceId: _deviceId,
      platform: _platform,
    );

    final newCallId = result['callId']?.toString();
    final wsUrl = result['wsUrl']?.toString();
    if (result['success'] != true || newCallId == null || wsUrl == null) {
      final reason = result['reason']?.toString();
      final message = switch (reason) {
        'busy' => result['message']?.toString() ?? '${callee.name} is on another call',
        'unreachable' => '${callee.name} cannot be reached right now',
        'glare' => 'You called each other at the same time — answer the incoming call',
        _ => result['message']?.toString() ?? 'Could not start the call',
      };
      _finish(
        reason == 'busy'
            ? CallEndReason.busy
            : reason == 'unreachable'
                ? CallEndReason.unreachable
                : CallEndReason.error,
        message: message,
      );
      return;
    }

    callId = newCallId;
    notifyListeners();
    _openSignaling(newCallId, wsUrl);
    unawaited(CallKitV2.instance.startOutgoing(
      callId: newCallId,
      peerName: callee.name,
      peerAvatar: callee.avatar,
      callType: type,
    ));
  }

  // ── incoming ────────────────────────────────────────────────────────

  /// Foreground fast-path from the per-user notifications socket. Routes a
  /// call.incoming the same way an FCM push would (handleIncomingPush is
  /// idempotent per callId, so a near-simultaneous FCM is a no-op).
  void _onWsNotification(NotificationWsEvent event) {
    switch (event) {
      case IncomingCallWsEvent e:
        unawaited(handleIncomingPush(IncomingCallPushV2(
          callId: e.callId,
          callerId: e.callerId,
          callerName: e.callerName,
          callerAvatar: e.callerAvatar,
          callType: CallTypeV2.fromWire(e.callType),
          expiresAt: e.expiresAt,
        )));
      case CallCancelledWsEvent e:
        unawaited(dismissCancelledCall(e.callId));
      default:
        break;
    }
  }

  /// Entry from the FCM/VoIP push handler while the app process is alive.
  /// (When killed, the background isolate only shows the native UI; this
  /// runs on the next launch via [_resumeAfterColdStart].)
  Future<void> handleIncomingPush(IncomingCallPushV2 push) async {
    if (push.isExpired) return; // ghost-ring guard (edge 26)

    if (isLive && callId != push.callId) {
      // Already on a call — auto-busy (§9 rows 8/20).
      unawaited(CallApiV2.instance
          .action(callId: push.callId, action: 'reject', reason: 'busy'));
      return;
    }
    if (callId == push.callId) return; // duplicate delivery

    // Ring IMMEDIATELY (WhatsApp-grade latency) — `expiresAt` already guards
    // stale pushes. The server verification below runs in parallel and only
    // dismisses on a DEFINITIVE "no longer ringing"; a slow or failed check
    // must never swallow a real call.
    _endedResetTimer?.cancel();
    _resetTo(
      phase: CallPhaseV2.incoming,
      callId: push.callId,
      peer: CallParticipant(
        id: push.callerId,
        name: push.callerName,
        avatar: push.callerAvatar,
      ),
      type: push.callType,
    );
    unawaited(CallKitV2.instance.showIncoming(push));

    unawaited(CallApiV2.instance.getCall(push.callId).then((snapshot) async {
      // ONLY dismiss on positive confirmation the call is terminal (edge 26).
      // A null/unreachable snapshot or a transient state (CONNECTING during a
      // multi-device accept race) must NEVER end a live ring — doing so makes
      // flutter_callkit_incoming emit a DECLINE on an un-accepted call, which
      // the caller sees as a rejection the callee never made.
      if (snapshot != null &&
          snapshot.state == CallState.ended &&
          callId == push.callId &&
          phase == CallPhaseV2.incoming) {
        await _selfEndCallKit(push.callId);
        dismissTakenElsewhere();
      }
    }));

    final wsUrl = await CallApiV2.instance.wsTicket(
      callId: push.callId,
      deviceId: _deviceId,
      platform: _platform,
    );
    if (wsUrl != null) {
      _openSignaling(push.callId, wsUrl);
      // Tell the caller we're ringing. The socket's `call.state` snapshot
      // also reconciles us if the call ended meanwhile.
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        _signaling?.send('call.ringing');
      });
    }
  }

  /// User accepted from the in-app UI or the native call UI.
  Future<void> accept() async {
    final id = callId;
    if (id == null || phase != CallPhaseV2.incoming) return;
    phase = CallPhaseV2.connecting;
    notifyListeners();
    _navigateToCallScreen();
    if (!(_signaling?.send('call.accept') ?? false)) {
      // Socket not up yet (accept from killed state) — REST fallback.
      await CallApiV2.instance
          .action(callId: id, action: 'accept', deviceId: _deviceId);
      await _ensureSignaling(id);
    }
  }

  Future<void> reject() async {
    final id = callId;
    if (id == null || phase != CallPhaseV2.incoming) return;
    if (!(_signaling?.send('call.reject') ?? false)) {
      unawaited(CallApiV2.instance.action(callId: id, action: 'reject'));
    }
    _finish(null);
  }

  /// Answered on another of the user's devices (push fan-out arrived before
  /// the socket's `call.taken`) — stop ringing without touching the server.
  void dismissTakenElsewhere() {
    if (phase != CallPhaseV2.incoming) return;
    _finish(null);
  }

  /// Dismisses a cancelled/answered-elsewhere call's native UI from a push
  /// handler. Routes through the self-dismiss guard so the resulting native
  /// decline echo is never sent to the server as a user reject.
  Future<void> dismissCancelledCall(String cancelledCallId) async {
    if (cancelledCallId.isEmpty) return;
    // If we're the device carrying this call (already connecting/active), the
    // cancel is the "answered elsewhere" fan-out reaching us — ignore it.
    final carrying = callId == cancelledCallId &&
        (phase == CallPhaseV2.connecting ||
            phase == CallPhaseV2.active ||
            phase == CallPhaseV2.reconnecting);
    if (carrying) return;
    await _selfEndCallKit(cancelledCallId);
    if (callId == cancelledCallId && phase == CallPhaseV2.incoming) {
      dismissTakenElsewhere();
    }
  }

  // ── in-call actions ─────────────────────────────────────────────────

  Future<void> hangUp() async {
    final id = callId;
    if (id == null) return;
    switch (phase) {
      case CallPhaseV2.outgoing:
        if (!(_signaling?.send('call.cancel') ?? false)) {
          unawaited(CallApiV2.instance.action(callId: id, action: 'cancel'));
        }
        _finish(CallEndReason.cancelled);
      case CallPhaseV2.connecting:
      case CallPhaseV2.active:
      case CallPhaseV2.reconnecting:
        if (!(_signaling?.send('call.end', {'reason': 'completed'}) ?? false)) {
          unawaited(CallApiV2.instance
              .action(callId: id, action: 'end', reason: 'completed'));
        }
        _finish(CallEndReason.completed);
      default:
        break;
    }
  }

  Future<void> toggleMute() async {
    muted = !muted;
    notifyListeners();
    await agora.setMuted(muted);
    _signaling?.send('call.media_state', {'muted': muted});
  }

  Future<void> toggleVideo() async {
    if (callType == CallTypeV2.audio && !videoEnabled && phase == CallPhaseV2.active) {
      // audio→video upgrade handshake (§3.4)
      _signaling?.send('call.media_upgrade', {'phase': 'request'});
      return;
    }
    videoEnabled = !videoEnabled;
    notifyListeners();
    await agora.setVideoEnabled(videoEnabled);
    _signaling?.send('call.media_state', {'videoEnabled': videoEnabled});
  }

  Future<void> respondVideoUpgrade(bool acceptUpgrade) async {
    upgradeRequestFrom = null;
    _signaling?.send('call.media_upgrade', {'phase': acceptUpgrade ? 'accept' : 'decline'});
    if (acceptUpgrade) {
      callType = CallTypeV2.video;
      videoEnabled = true;
      speakerOn = true;
      notifyListeners();
      await agora.setVideoEnabled(true);
      await agora.setSpeakerphone(true);
      _signaling?.send('call.media_state', {'videoEnabled': true});
    }
  }

  Future<void> toggleSpeaker() async {
    speakerOn = !speakerOn;
    notifyListeners();
    await agora.setSpeakerphone(speakerOn);
  }

  Future<void> switchCamera() => agora.switchCamera();

  // ── signaling plumbing ──────────────────────────────────────────────

  Future<void> _ensureSignaling(String id) async {
    if (_signaling != null && _signaling!.callId == id) return;
    final wsUrl = await CallApiV2.instance
        .wsTicket(callId: id, deviceId: _deviceId, platform: _platform);
    if (wsUrl != null) _openSignaling(id, wsUrl);
  }

  void _openSignaling(String id, String wsUrl) {
    _signaling?.close();
    final signaling = CallSignalingV2(
      callId: id,
      wsUrl: wsUrl,
      refreshWsUrl: () => CallApiV2.instance
          .wsTicket(callId: id, deviceId: _deviceId, platform: _platform),
    );
    signaling.onEvent = _onSignal;
    _signaling = signaling;
    unawaited(signaling.connect());
  }

  Future<void> _onSignal(SignalEnvelopeV2 envelope) async {
    if (envelope.callId != callId && envelope.type != 'pong') return;

    switch (envelope.type) {
      case 'call.state':
        final snapshot = CallSnapshotV2.fromJson(envelope.payload);
        if (snapshot.state == CallState.ended) {
          _finish(snapshot.endReason ?? CallEndReason.completed);
          return;
        }
        // Fill peer/callType from the authoritative snapshot when local
        // context is incomplete (accept from killed app, reconcile).
        final myId = AppData.logInUserId?.toString() ?? '';
        final snapshotPeer =
            snapshot.caller.id == myId ? snapshot.callee : snapshot.caller;
        if ((peer == null || peer!.id.isEmpty) && snapshotPeer.id.isNotEmpty) {
          peer = snapshotPeer;
          callType = snapshot.upgradedToVideo ? CallTypeV2.video : snapshot.callType;
          notifyListeners();
        }
        return;

      case 'call.ringing':
        // Caller UI: callee device is ringing.
        notifyListeners();
        return;

      case 'call.accept':
        if (phase == CallPhaseV2.outgoing) {
          phase = CallPhaseV2.connecting;
          notifyListeners();
        }
        return;

      case 'call.taken':
        // Answered on another of my devices (§6).
        await _selfEndCallKit(callId ?? '');
        _finish(null,
            message: phase == CallPhaseV2.incoming
                ? 'Answered on another device'
                : null);
        return;

      case 'call.join_channel':
        await _joinAgora(JoinChannelPayloadV2.fromJson(envelope.payload));
        return;

      case 'call.token_renew':
        final token = envelope.payload['token']?.toString();
        if (token != null && token.isNotEmpty) await agora.renewToken(token);
        return;

      case 'call.connected':
        _markActive();
        return;

      case 'call.media_state':
        if (envelope.from != null &&
            envelope.from != (AppData.logInUserId?.toString() ?? '')) {
          peerMedia = CallMediaStateV2.fromJson(envelope.payload);
          notifyListeners();
        }
        return;

      case 'call.media_upgrade':
        final upgradePhase = envelope.payload['phase']?.toString() ?? 'request';
        if (upgradePhase == 'request') {
          upgradeRequestFrom = envelope.from ?? 'peer';
          notifyListeners();
        } else if (upgradePhase == 'accept') {
          callType = CallTypeV2.video;
          videoEnabled = true;
          speakerOn = true;
          notifyListeners();
          await agora.setVideoEnabled(true);
          await agora.setSpeakerphone(true);
          _signaling?.send('call.media_state', {'videoEnabled': true});
        } else {
          upgradeRequestFrom = null;
          notifyListeners();
        }
        return;

      case 'call.reconnecting':
        if (phase == CallPhaseV2.active) {
          phase = CallPhaseV2.reconnecting;
          notifyListeners();
        }
        return;

      case 'call.reject':
        _finish(CallEndReason.declined);
        return;
      case 'call.cancel':
        await _selfEndCallKit(callId ?? '');
        _finish(CallEndReason.cancelled);
        return;
      case 'call.timeout':
        await _selfEndCallKit(callId ?? '');
        _finish(CallEndReason.fromWire(envelope.payload['reason']?.toString()) ??
            CallEndReason.noAnswer);
        return;
      case 'call.end':
        _finish(CallEndReason.fromWire(envelope.payload['reason']?.toString()) ??
            CallEndReason.completed);
        return;

      case 'call.error':
        debugPrint('📞 [CallControllerV2] signaling error: ${envelope.payload}');
        return;

      default:
        return;
    }
  }

  // ── media (§3) ──────────────────────────────────────────────────────

  Future<void> _joinAgora(JoinChannelPayloadV2 payload) async {
    if (agora.isJoined) return;
    var withVideo = payload.callType == CallTypeV2.video;

    // CallKit accepts bypass the chat screen's permission UI — make sure the
    // runtime permissions exist before the engine starts (edge 24).
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      _signaling?.send('call.end', {'reason': 'error'});
      _finish(CallEndReason.error, message: 'Microphone permission is required');
      return;
    }
    if (withVideo) {
      final camera = await Permission.camera.request();
      if (!camera.isGranted) {
        // Camera denied is not fatal — degrade to audio-only.
        withVideo = false;
        _signaling?.send('call.media_state', {'videoEnabled': false});
      }
    }

    videoEnabled = withVideo;
    speakerOn = withVideo;
    phase = CallPhaseV2.connecting;
    notifyListeners();

    agora.onRemoteMediaConnected = () {
      _signaling?.send('call.connected');
      _markActive();
    };
    agora.onRemoteLeft = () {
      // Peer's media vanished — hangup frames arrive via signaling; if none
      // do, flag reconnecting and let the server grace decide (edge 17/25).
      if (phase == CallPhaseV2.active) {
        _signaling?.send('call.reconnecting');
        phase = CallPhaseV2.reconnecting;
        notifyListeners();
      }
    };
    agora.onRemoteVideoChanged = (hasVideo) {
      peerMedia = CallMediaStateV2(muted: peerMedia.muted, videoEnabled: hasVideo);
      notifyListeners();
    };
    agora.onReconnecting = () {
      _signaling?.send('call.reconnecting');
      if (phase == CallPhaseV2.active) {
        phase = CallPhaseV2.reconnecting;
        notifyListeners();
      }
    };
    agora.onReconnected = () {
      _signaling?.send('call.connected');
      _markActive();
    };
    agora.onNetworkQuality = (quality) {
      if (quality != networkQuality) {
        networkQuality = quality;
        notifyListeners();
      }
    };

    try {
      await agora.join(
        appId: payload.appId,
        channel: payload.channel,
        token: payload.token,
        userAccount: payload.uid,
        withVideo: withVideo,
      );
    } catch (e) {
      debugPrint('📞 [CallControllerV2] Agora join failed: $e');
      _signaling?.send('call.end', {'reason': 'connect_failed'});
      _finish(CallEndReason.connectFailed, message: 'Could not connect the call');
    }
  }

  void _markActive() {
    if (phase == CallPhaseV2.ended || phase == CallPhaseV2.idle) return;
    connectedAt ??= DateTime.now();
    phase = CallPhaseV2.active;
    notifyListeners();
    // Belt-and-suspenders: whatever path got us here (accept, reconcile,
    // background-accept catch-up), make sure the in-app call screen is visible.
    _navigateToCallScreen();
    final id = callId;
    if (id != null) unawaited(CallKitV2.instance.setConnected(id));
  }

  // ── CallKit (native UI) actions ─────────────────────────────────────

  Future<void> _onCallKitAction(CallKitActionV2 action) async {
    debugPrint('📞 [CallControllerV2] CallKit action ${action.kind} for ${action.callId} (current callId=$callId, phase=$phase)');

    // Ignore decline/timeout/ended echoes for entries WE dismissed
    // programmatically — the plugin reports our end() as a DECLINE, and acting
    // on it would send a spurious `reject` the caller sees as the callee
    // declining. (Accept is never suppressed — a dismissed call can't be
    // accepted anyway.)
    if (action.kind != CallKitActionKind.accept &&
        _selfDismissed.contains(action.callId)) {
      debugPrint('📞 [CallControllerV2] ignoring self-dismissed echo ${action.kind} for ${action.callId}');
      return;
    }

    final isCurrentCall = callId == action.callId;

    // Only handle calls this module created (extra.signalVersion == '2').
    if (!isCurrentCall && !await CallKitV2.instance.ownsCall(action.callId)) {
      debugPrint('📞 [CallControllerV2] ignoring CallKit action — not a v2-owned call');
      return;
    }

    // ── Action for a DIFFERENT call than the one we're tracking ──
    // (a second call that rang while we were already busy, or a native-only
    // ring the controller never adopted). These must still be disconnected on
    // the server + dismissed natively, or they ring forever (the "second call
    // hangup doesn't disconnect" bug).
    if (!isCurrentCall) {
      switch (action.kind) {
        case CallKitActionKind.accept:
          if (isLive) {
            // Can't take a second call — reject as busy and stop its native UI.
            debugPrint('📞 [CallControllerV2] second call accepted while busy → reject busy ${action.callId}');
            unawaited(CallApiV2.instance
                .action(callId: action.callId, action: 'reject', reason: 'busy'));
            await CallKitV2.instance.end(action.callId);
          } else {
            // Not on a call — adopt it (accept raced ahead of state / native-only ring).
            await _connectAsCallee(
              callId: action.callId,
              caller: peer ?? const CallParticipant(id: '', name: 'Unknown', avatar: ''),
              type: callType,
              sendAccept: true,
            );
          }
        case CallKitActionKind.decline:
        case CallKitActionKind.ended:
        case CallKitActionKind.timeout:
          // Hang up / reject the OTHER call so it disconnects everywhere.
          debugPrint('📞 [CallControllerV2] disconnecting non-current call ${action.callId} (${action.kind})');
          unawaited(CallApiV2.instance.action(callId: action.callId, action: 'reject'));
          await CallKitV2.instance.end(action.callId);
      }
      return;
    }

    // ── Action for the call we're currently tracking ──
    switch (action.kind) {
      case CallKitActionKind.accept:
        await accept();
      case CallKitActionKind.decline:
        await reject();
      case CallKitActionKind.timeout:
        // Server's ring alarm is authoritative; just drop local UI state.
        if (phase == CallPhaseV2.incoming) {
          _finish(CallEndReason.missed);
        }
      case CallKitActionKind.ended:
        // Native in-call UI ended (e.g. lock-screen / notification hangup).
        if (phase == CallPhaseV2.incoming) {
          await reject();
        } else if (phase == CallPhaseV2.outgoing ||
            phase == CallPhaseV2.connecting ||
            phase == CallPhaseV2.active ||
            phase == CallPhaseV2.reconnecting) {
          await hangUp();
        }
    }
  }

  /// Connects + accepts as callee when the in-memory state is missing
  /// (accept from killed app / native-only ring).
  Future<void> _connectAsCallee({
    required String callId,
    required CallParticipant caller,
    required CallTypeV2 type,
    required bool sendAccept,
  }) async {
    _endedResetTimer?.cancel();
    _resetTo(phase: CallPhaseV2.connecting, callId: callId, peer: caller, type: type);
    _navigateToCallScreen();
    await _ensureSignaling(callId);
    if (sendAccept) {
      if (!(_signaling?.send('call.accept') ?? false)) {
        await CallApiV2.instance
            .action(callId: callId, action: 'accept', deviceId: _deviceId);
      }
    }
  }

  // ── teardown ────────────────────────────────────────────────────────

  void _finish(CallEndReason? reason, {String? message}) {
    if (phase == CallPhaseV2.ended && reason == null) return;
    final id = callId;
    _signaling?.close();
    _signaling = null;
    unawaited(agora.leave());
    if (id != null) unawaited(_selfEndCallKit(id));

    phase = CallPhaseV2.ended;
    endReason = reason;
    errorMessage = message;
    connectedAt = null;
    upgradeRequestFrom = null;
    unawaited(_writeBusyMarker(null)); // clear cross-isolate busy marker
    notifyListeners();

    _endedResetTimer?.cancel();
    _endedResetTimer = Timer(const Duration(milliseconds: 2200), () {
      _popCallScreen();
      _resetTo(phase: CallPhaseV2.idle, callId: null, peer: null, type: CallTypeV2.audio);
    });
  }

  void _resetTo({
    required CallPhaseV2 phase,
    required String? callId,
    required CallParticipant? peer,
    required CallTypeV2 type,
  }) {
    this.phase = phase;
    this.callId = callId;
    this.peer = peer;
    callType = type;
    muted = false;
    videoEnabled = type == CallTypeV2.video;
    speakerOn = type == CallTypeV2.video;
    peerMedia = const CallMediaStateV2();
    networkQuality = 5;
    connectedAt = null;
    endReason = null;
    errorMessage = null;
    upgradeRequestFrom = null;
    // Cross-isolate "busy" marker: persist the live callId so the FCM
    // background isolate can reject a second incoming call (busy) instead of
    // ringing twice. Cleared when the call ends / goes idle.
    unawaited(_writeBusyMarker(isLive ? callId : null));
    notifyListeners();
  }

  /// Secure-storage key shared with [CallPushV2] so both isolates agree on
  /// whether this device is currently on a call.
  static const String busyMarkerKey = 'call_v2_busy_call_id';

  static Future<void> _writeBusyMarker(String? callId) async {
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      if (callId == null || callId.isEmpty) {
        await prefs.remove(busyMarkerKey);
      } else {
        await prefs.setString(busyMarkerKey, callId);
      }
    } catch (_) {}
  }

  // ── navigation ──────────────────────────────────────────────────────

  /// Whether the in-app call screen (`/call-v2`) is currently on the stack.
  /// Used by the global ongoing-call banner to decide when to show.
  bool get isCallScreenVisible => _navigatedToCallScreen;

  /// Re-open the call screen for a live call (e.g. from the ongoing-call
  /// banner after the user navigated away). No-op when no call is live.
  void reopenCallScreen() {
    if (!isLive) return;
    _navigateToCallScreen();
  }

  void _navigateToCallScreen([int attempt = 0]) {
    if (_navigatedToCallScreen) return;
    final navigator = NavigatorService.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('📞 [CallControllerV2] navigator not ready (attempt $attempt) — retrying');
      // Cold start: the navigator may not exist yet (CallKit accept relaunched
      // the app). Retry briefly instead of silently dropping the screen.
      if (attempt < 30 && isLive) {
        Timer(const Duration(milliseconds: 300), () => _navigateToCallScreen(attempt + 1));
      }
      return;
    }
    _navigatedToCallScreen = true;
    debugPrint('📞 [CallControllerV2] opening CallScreenV2 (phase=$phase, callId=$callId)');
    navigator
        .push(MaterialPageRoute(
          settings: const RouteSettings(name: '/call-v2'),
          builder: (_) => const CallScreenV2(),
        ))
        .whenComplete(() => _navigatedToCallScreen = false);
  }

  void _popCallScreen() {
    if (!_navigatedToCallScreen) return;
    final navigator = NavigatorService.navigatorKey.currentState;
    navigator?.popUntil((route) => route.settings.name != '/call-v2');
  }
}
