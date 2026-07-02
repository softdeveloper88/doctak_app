# Calling Module v2 (Flutter)

Self-contained 1:1 audio/video calling, built per `CALLING_SYSTEM_SPEC.md`.
Replaces the legacy `calling_module` (Pusher + Laravel polling) with a
server-authoritative signaling architecture. The legacy module is untouched
and can be deleted once v2 is verified in production.

## Architecture

```
Flutter ──REST──▶ doctak-node /api/calls/*        (initiate, ws-ticket, action, history)
Flutter ◀─WS───▶ CallSession Durable Object       (lifecycle signaling, state machine)
Flutter ◀─media─▶ Agora RTC                        (channel = callId, string-uid scheme)
Flutter ◀─FCM/VoIP── doctak-node push layer        (killed-app incoming delivery)
```

- The **server owns the state machine** (`IDLE → INITIATING → RINGING →
  CONNECTING → ACTIVE → ENDED`, plus `RECONNECTING`). Every `call.state`
  snapshot reconciles the local mirror — server wins.
- Agora **channel name = callId**; both sides join with
  `joinChannelWithUserAccount` using the same `u_<userId>` account scheme as
  the web client, so cross-platform calls render correctly.
- Tokens are minted server-side and delivered via `call.join_channel` /
  `call.token_renew` — the client never talks to a token endpoint.

## Files

| File | Role |
|---|---|
| `models/call_protocol.dart` | Wire-format mirror of `doctak-node/lib/calls/protocol.ts` |
| `services/call_api_v2.dart` | REST control plane (Bearer auth, nodeApiUrl) |
| `services/call_signaling_v2.dart` | Per-call WebSocket (heartbeat, backoff reconnect) |
| `services/call_agora_v2.dart` | Agora engine wrapper (§3.3 event mapping, audio routing) |
| `services/callkit_v2.dart` | flutter_callkit_incoming bridge (incoming UI, events) |
| `services/call_push_v2.dart` | FCM data-push entries (foreground + background isolate) |
| `controller/call_controller_v2.dart` | Orchestrator / state mirror (singleton ChangeNotifier) |
| `screens/call_screen_v2.dart` | Single in-call screen (all phases) |
| `widgets/call_controls_v2.dart` | Control bar (mute/video/speaker/flip/end, accept/decline) |
| `calling_module_v2.dart` | Public entry points + exports |

## Integration points (already wired)

1. **App start** — `main.dart` calls `CallingModuleV2.initialize()` after
   `NotificationService.initialize()`. Safe to call again after login (VoIP
   token registration + live-call reconcile re-run; listeners attach once).
2. **FCM** — `notification_service.dart` routes data messages with
   `signalVersion == "2"` to `CallPushV2.maybeHandle` (foreground) and
   `CallPushV2.maybeHandleBackground` (killed-app isolate) before any legacy
   handling.
3. **Chat call buttons** — `chat_room_screen.dart` calls
   `startOutgoingCallV2(userId, username, profilePic, isVideo)` (same
   signature as the legacy `startOutgoingCall`).

## Killed-app delivery

- **Android**: the server sends a high-priority **data-only** FCM message →
  background isolate → `CallKitV2.showIncoming` full-screen UI over the lock
  screen. Accept/decline from the killed state flows through CallKit events
  on next launch (`CallControllerV2._resumeAfterColdStart`).
  Requirements (already present for the legacy module — verify on upgrade):
  `POST_NOTIFICATIONS`, `USE_FULL_SCREEN_INTENT`, foreground service with
  `android:foregroundServiceType="microphone|camera"`.
- **iOS**: true killed-state ringing requires **APNs VoIP + PushKit**.
  The module registers the VoIP token via `/api/calls/register-voip-token`
  on init. Server-side the `APNS_*` secrets must be configured (see
  `doctak-node/docs/CALLING_MODULE.md`). Native side needs the standard
  `flutter_callkit_incoming` PushKit handler in `AppDelegate.swift`
  (`didReceiveIncomingPushWith` → `showCallkitIncoming`) and the `voip` +
  `audio` background modes. Without APNs VoIP, iOS falls back to an FCM
  alert push: the user sees a notification banner and the call rings only
  while the app process is alive.

## Edge-case behavior (spec §9)

- **Busy** (rows 8/20): server refuses `initiate` when either party has a
  live session; an incoming push during a live call auto-rejects with
  reason `busy`.
- **Multi-device** (row 9): first `accept` wins; other devices get
  `call.taken` and stop ringing.
- **Stale push / ghost ring** (row 26): pushes carry `expiresAt`; the
  controller additionally verifies `GET /api/calls/:id` is still `RINGING`
  before ringing, and `call_cancelled` pushes dismiss the native UI.
- **Reconnection** (rows 11–13): Agora `connectionStateReconnecting` →
  `call.reconnecting` → server grace (30 s) → `network_failed` if not
  recovered.
- **Glare** (row 21): server resolves deterministically — the
  lexicographically smaller callId survives.
- **Token expiry** (row 23): server renews proactively and pushes
  `call.token_renew` → `engine.renewToken`.

## Tests

`flutter test test/calling_module_v2/` — protocol wire-format tests.
The full state machine is tested server-side
(`doctak-node && npm run test:calls`, 22 cases covering the matrix).
