import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../controller/call_controller_v2.dart';
import '../models/call_protocol.dart';
import '../widgets/call_controls_v2.dart';

/// Calling module v2 — single in-call screen for every phase:
/// dialing → ringing → connecting → active (audio/video) → reconnecting →
/// ended. Listens to [CallControllerV2] and renders accordingly.
class CallScreenV2 extends StatefulWidget {
  const CallScreenV2({super.key});

  @override
  State<CallScreenV2> createState() => _CallScreenV2State();
}

class _CallScreenV2State extends State<CallScreenV2> {
  final CallControllerV2 controller = CallControllerV2.instance;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
    WakelockPlus.enable();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final connectedAt = controller.connectedAt;
      if (connectedAt != null && mounted) {
        setState(() => _elapsed = DateTime.now().difference(connectedAt));
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    controller.removeListener(_onControllerChanged);
    WakelockPlus.disable();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  String get _statusLine {
    switch (controller.phase) {
      case CallPhaseV2.outgoing:
        return controller.callId == null ? 'Calling…' : 'Ringing…';
      case CallPhaseV2.incoming:
        return 'Incoming call…';
      case CallPhaseV2.connecting:
        return 'Connecting…';
      case CallPhaseV2.reconnecting:
        return 'Reconnecting…';
      case CallPhaseV2.active:
        return _formatDuration(_elapsed);
      case CallPhaseV2.ended:
        return controller.errorMessage ?? _endReasonLabel(controller.endReason);
      case CallPhaseV2.idle:
        return '';
    }
  }

  static String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  static String _endReasonLabel(CallEndReason? reason) {
    switch (reason) {
      case CallEndReason.declined:
        return 'Call declined';
      case CallEndReason.busy:
        return 'User is busy';
      case CallEndReason.cancelled:
        return 'Call cancelled';
      case CallEndReason.noAnswer:
      case CallEndReason.missed:
        return 'No answer';
      case CallEndReason.unreachable:
        return 'User unreachable';
      case CallEndReason.connectFailed:
        return 'Could not connect';
      case CallEndReason.networkFailed:
        return 'Connection lost';
      case CallEndReason.error:
        return 'Call failed';
      case CallEndReason.completed:
      case null:
        return 'Call ended';
    }
  }

  bool get _showVideo =>
      controller.callType == CallTypeV2.video ||
      controller.videoEnabled ||
      controller.peerMedia.videoEnabled;

  @override
  Widget build(BuildContext context) {
    final peer = controller.peer;

    return PopScope(
      // Back gesture must not silently leave a live call (§10) — the call
      // continues; only the red button hangs up.
      canPop: controller.phase == CallPhaseV2.ended || controller.phase == CallPhaseV2.idle,
      child: Scaffold(
        backgroundColor: const Color(0xFF101826),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_showVideo) _buildVideoStage() else _buildAudioStage(peer),

            // Status banner (reconnecting / poor network)
            if (controller.phase == CallPhaseV2.reconnecting ||
                (controller.phase == CallPhaseV2.active && controller.networkQuality < 2))
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      controller.phase == CallPhaseV2.reconnecting
                          ? 'Reconnecting…'
                          : 'Poor connection',
                      style: TextStyle(
                        color: controller.phase == CallPhaseV2.reconnecting
                            ? Colors.amber
                            : Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

            // Peer name + status
            Positioned(
              top: MediaQuery.of(context).padding.top + 48,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  Text(
                    peer?.name ?? 'Unknown',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      _statusLine,
                      if (controller.peerMedia.muted &&
                          controller.phase == CallPhaseV2.active)
                        'muted',
                    ].join(' · '),
                    style: const TextStyle(color: Colors.white70, fontSize: 14.5),
                  ),
                ],
              ),
            ),

            // Video upgrade prompt
            if (controller.upgradeRequestFrom != null)
              Positioned(
                bottom: 170,
                left: 24,
                right: 24,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${peer?.name ?? 'Caller'} wants to turn on video',
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                        ),
                      ),
                      TextButton(
                        onPressed: () => controller.respondVideoUpgrade(true),
                        child: const Text('Turn on'),
                      ),
                      TextButton(
                        onPressed: () => controller.respondVideoUpgrade(false),
                        child: const Text('Not now',
                            style: TextStyle(color: Colors.white60)),
                      ),
                    ],
                  ),
                ),
              ),

            // Controls
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 28,
              child: CallControlsV2(controller: controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioStage(CallParticipant? peer) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(peer: peer, size: 132, pulsing: controller.phase == CallPhaseV2.outgoing),
        ],
      ),
    );
  }

  Widget _buildVideoStage() {
    final engine = controller.agora.engine;
    final remoteUid = controller.agora.remoteUid;
    final channelId = controller.callId ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Remote video full-screen
        if (engine != null && remoteUid != null && controller.peerMedia.videoEnabled)
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: engine,
              canvas: VideoCanvas(uid: remoteUid),
              connection: RtcConnection(channelId: channelId),
            ),
          )
        else
          Center(child: _Avatar(peer: controller.peer, size: 120, pulsing: false)),

        // Local preview PiP
        if (engine != null && controller.videoEnabled)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 100,
            width: 110,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final CallParticipant? peer;
  final double size;
  final bool pulsing;

  const _Avatar({required this.peer, required this.size, required this.pulsing});

  @override
  Widget build(BuildContext context) {
    final avatar = peer?.avatar ?? '';
    final initials = (peer?.name ?? '?')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 3),
        boxShadow: pulsing
            ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.35), blurRadius: 36, spreadRadius: 6)]
            : null,
      ),
      child: ClipOval(
        child: avatar.isNotEmpty
            ? Image.network(
                avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(initials),
              )
            : _fallback(initials),
      ),
    );
  }

  Widget _fallback(String initials) {
    return Container(
      color: const Color(0xFF1E293B),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
      ),
    );
  }
}
