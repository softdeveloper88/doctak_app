import 'dart:async';

import 'package:flutter/material.dart';

import '../controller/call_controller_v2.dart';

/// WhatsApp-style "tap to return to call" bar.
///
/// Mounted app-wide (in `MaterialApp.builder`) so that whenever a call is live
/// but the in-app call screen isn't on top, a slim green bar appears at the top
/// of every screen. Tapping it re-opens [CallScreenV2] via the controller.
class OngoingCallBannerV2 extends StatefulWidget {
  const OngoingCallBannerV2({super.key});

  @override
  State<OngoingCallBannerV2> createState() => _OngoingCallBannerV2State();
}

class _OngoingCallBannerV2State extends State<OngoingCallBannerV2> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh once per second so the live-call duration stays current while
    // the banner is shown (controller only notifies on state changes).
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _statusText(CallControllerV2 c) {
    switch (c.phase) {
      case CallPhaseV2.outgoing:
        return 'Calling…';
      case CallPhaseV2.incoming:
        return 'Incoming call';
      case CallPhaseV2.connecting:
        return 'Connecting…';
      case CallPhaseV2.reconnecting:
        return 'Reconnecting…';
      case CallPhaseV2.active:
        final start = c.connectedAt;
        if (start == null) return 'On call';
        final d = DateTime.now().difference(start);
        final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
        final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
        final hh = d.inHours;
        return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
      case CallPhaseV2.idle:
      case CallPhaseV2.ended:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CallControllerV2.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Only show when a call is live AND the call screen isn't already open.
        final show = controller.isLive && !controller.isCallScreenVisible;
        if (!show) return const SizedBox.shrink();

        final peerName = controller.peer?.name ?? 'In call';
        return Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: InkWell(
              onTap: controller.reopenCallScreen,
              child: Container(
                width: double.infinity,
                color: const Color(0xFF00A884), // WhatsApp-style green
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.call, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$peerName · ${_statusText(controller)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tap to return',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
