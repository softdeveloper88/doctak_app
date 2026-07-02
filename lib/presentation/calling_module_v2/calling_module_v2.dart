/// Calling module v2 — public entry points.
///
/// Self-contained 1:1 audio/video calling built on:
///   - doctak-node `/api/calls/*` control plane (Bearer auth)
///   - CallSession Durable Object signaling (WebSocket, server-authoritative
///     state machine)
///   - Agora RTC media (channel = callId, string-uid scheme shared with web)
///   - FCM data push + CallKit for killed-app incoming delivery
///
/// Integration surface:
///   CallingModuleV2.initialize()        — once after login/app start
///   startOutgoingCallV2(...)            — same signature as the legacy
///                                         startOutgoingCall for drop-in use
///   CallPushV2.maybeHandle(...)         — from the FCM foreground handler
///   CallPushV2.maybeHandleBackground()  — from the FCM background isolate
library;

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/call_permission_handler.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';

import 'controller/call_controller_v2.dart';
import 'models/call_protocol.dart';

export 'controller/call_controller_v2.dart';
export 'models/call_protocol.dart';
export 'screens/call_screen_v2.dart';
export 'services/call_api_v2.dart';
export 'services/call_push_v2.dart';
export 'services/callkit_v2.dart';

class CallingModuleV2 {
  CallingModuleV2._();

  /// Idempotent module bootstrap: CallKit listeners, VoIP token
  /// registration (iOS) and live-call reconciliation after cold start.
  static Future<void> initialize() => CallControllerV2.instance.init();
}

/// Starts an outgoing call — drop-in replacement for the legacy
/// `startOutgoingCall(userId, username, profilePic, isVideoCall)`.
Future<void> startOutgoingCallV2(
  String userId,
  String username,
  String profilePic,
  bool isVideoCall,
) async {
  // Mic/camera permission UX (edge 24) — reuse the app's permission flow.
  final context = NavigatorService.navigatorKey.currentState?.context;
  if (context != null) {
    final hasPermissions =
        await callPermissionHandler.hasCallPermissions(isVideoCall: isVideoCall);
    if (!hasPermissions) {
      if (!context.mounted) return;
      final granted = await callPermissionHandler.requestWithUI(
        context,
        isVideoCall: isVideoCall,
        showRationale: true,
      );
      if (!granted) return;
    }
  }

  await CallControllerV2.instance.startOutgoing(
    callee: CallParticipant(
      id: userId,
      name: username,
      avatar: AppData.fullImageUrl(profilePic),
    ),
    type: isVideoCall ? CallTypeV2.video : CallTypeV2.audio,
  );
}
