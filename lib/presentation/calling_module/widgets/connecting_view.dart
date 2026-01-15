// lib/presentation/call_module/widgets/connecting_view.dart
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

import '../models/call_state.dart';

/// Widget that displays connecting state with animations and OneUI 8.5 theming
/// Note: Calling screens always use dark background for consistent experience
/// Auto-reconnects when network becomes stable - no manual retry needed
class ConnectingView extends StatelessWidget {
  final String contactName;
  final bool isIncoming;
  final bool isVideoCall;
  final VoidCallback onRetry; // Kept for backward compatibility but not shown
  final bool showRetry; // Deprecated - auto-reconnect is used instead
  final String? customMessage;
  final CallEndReason? callEndReason;
  final int reconnectCountdown;

  const ConnectingView({
    super.key,
    required this.contactName,
    required this.isIncoming,
    required this.isVideoCall,
    required this.onRetry,
    this.showRetry = false,
    this.customMessage,
    this.callEndReason,
    this.reconnectCountdown = 0,
  });

  // Calling screen colors - always dark for consistent experience
  static const _callBackgroundDark = Color(0xFF1A2332);
  static const _callBackgroundLight = Color(0xFF243447);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    // Determine the display message and icon based on state
    String displayMessage;
    IconData displayIcon;
    Color indicatorColor;
    bool showSpinner = true;

    if (callEndReason != null && callEndReason != CallEndReason.none) {
      showSpinner = false;
      switch (callEndReason!) {
        case CallEndReason.remoteUserEnded:
          displayMessage = translation(context).lbl_call_ended;
          displayIcon = Icons.call_end_rounded;
          indicatorColor = theme.error;
          break;
        case CallEndReason.remoteUserNoAnswer:
          displayMessage = translation(context).lbl_no_answer;
          displayIcon = Icons.phone_missed_rounded;
          indicatorColor = theme.warning;
          break;
        case CallEndReason.callerCancelled:
        case CallEndReason.callCancelledByRemote:
          displayMessage = translation(context).lbl_call_cancelled;
          displayIcon = Icons.phone_missed_rounded;
          indicatorColor = theme.warning;
          break;
        case CallEndReason.networkDisconnect:
          displayMessage = translation(context).lbl_connection_lost;
          displayIcon = Icons.signal_wifi_off_rounded;
          indicatorColor = theme.warning;
          break;
        case CallEndReason.callFailed:
          displayMessage = translation(context).lbl_call_failed;
          displayIcon = Icons.error_outline_rounded;
          indicatorColor = theme.error;
          break;
        case CallEndReason.permissionDenied:
          displayMessage = translation(context).lbl_permission_denied;
          displayIcon = Icons.block_rounded;
          indicatorColor = theme.error;
          break;
        default:
          displayMessage = translation(context).lbl_call_ended;
          displayIcon = Icons.call_end_rounded;
          indicatorColor = Colors.white70;
      }
    } else if (customMessage != null) {
      displayMessage = customMessage!;
      displayIcon = isVideoCall ? Icons.videocam_rounded : Icons.phone_rounded;
      indicatorColor = theme.primary;
    } else {
      displayMessage = isIncoming ? translation(context).lbl_connecting : "${translation(context).lbl_ringing}...";
      displayIcon = isVideoCall ? Icons.videocam_rounded : Icons.phone_rounded;
      indicatorColor = theme.primary;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_callBackgroundLight, _callBackgroundDark]),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated connecting indicator
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsating circle animation (only when still connecting)
                  if (showSpinner)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: 1.0 - value,
                          child: Transform.scale(
                            scale: 1.0 + value * 0.5,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(color: indicatorColor.withValues(alpha: 0.3), shape: BoxShape.circle),
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        (context as Element).markNeedsBuild();
                      },
                    ),

                  // Static circle for ended state
                  if (!showSpinner)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: indicatorColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: indicatorColor, width: 2),
                      ),
                    ),

                  // Main indicator (only when still connecting)
                  if (showSpinner) SizedBox(width: 80, height: 80, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(indicatorColor), strokeWidth: 3)),

                  // Center icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(color: showSpinner ? indicatorColor : indicatorColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: Icon(displayIcon, color: showSpinner ? Colors.white : indicatorColor, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Contact name - WHITE text for visibility
            Text(
              contactName,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Poppins', letterSpacing: 0.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Status message
            Text(
              displayMessage,
              style: TextStyle(color: showSpinner ? Colors.white70 : indicatorColor, fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),

            // Reconnect countdown (if applicable)
            if (reconnectCountdown > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_rounded, color: theme.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${translation(context).lbl_disconnecting_in} $reconnectCountdown ${translation(context).lbl_seconds}',
                      style: TextStyle(color: theme.warning, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Auto-reconnect status indicator (replaces manual Try Again button)
            // Shows when connection is being established or reconnecting
            if (callEndReason == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.primary.withValues(alpha: 0.8)))),
                    const SizedBox(width: 10),
                    Text(
                      translation(context).lbl_auto_connecting,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
