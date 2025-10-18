// lib/presentation/call_module/widgets/connecting_view.dart
import 'package:doctak_app/core/app_export.dart';
import 'package:flutter/material.dart';

import '../models/call_state.dart';

/// Widget that displays connecting state with animations
class ConnectingView extends StatelessWidget {
  final String contactName;
  final bool isIncoming;
  final bool isVideoCall;
  final VoidCallback onRetry;
  final bool showRetry;
  final String? customMessage; // Add option for custom message
  final CallEndReason? callEndReason; // Add call end reason for proper messaging
  final int reconnectCountdown; // Add countdown for reconnect timer

  const ConnectingView({
    Key? key,
    required this.contactName,
    required this.isIncoming,
    required this.isVideoCall,
    required this.onRetry,
    this.showRetry = false,
    this.customMessage, // Optional custom message
    this.callEndReason,
    this.reconnectCountdown = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the display message and icon based on state
    String displayMessage;
    IconData displayIcon;
    Color indicatorColor;
    bool showSpinner = true;

    if (callEndReason != null && callEndReason != CallEndReason.none) {
      // Call has ended with a reason - show appropriate message
      showSpinner = false;
      switch (callEndReason!) {
        case CallEndReason.remoteUserEnded:
          displayMessage = translation(context).lbl_call_ended;
          displayIcon = Icons.call_end;
          indicatorColor = Colors.red;
          break;
        case CallEndReason.remoteUserNoAnswer:
          displayMessage = translation(context).lbl_no_answer;
          displayIcon = Icons.phone_missed;
          indicatorColor = Colors.orange;
          break;
        case CallEndReason.networkDisconnect:
          displayMessage = translation(context).lbl_connection_lost;
          displayIcon = Icons.signal_wifi_off;
          indicatorColor = Colors.orange;
          break;
        case CallEndReason.callFailed:
          displayMessage = translation(context).lbl_call_failed;
          displayIcon = Icons.error_outline;
          indicatorColor = Colors.red;
          break;
        case CallEndReason.permissionDenied:
          displayMessage = translation(context).lbl_permission_denied;
          displayIcon = Icons.block;
          indicatorColor = Colors.red;
          break;
        default:
          displayMessage = translation(context).lbl_call_ended;
          displayIcon = Icons.call_end;
          indicatorColor = Colors.grey;
      }
    } else if (customMessage != null) {
      displayMessage = customMessage!;
      displayIcon = isVideoCall ? Icons.videocam : Icons.phone;
      indicatorColor = Colors.blue;
    } else {
      displayMessage = isIncoming
          ? translation(context).lbl_connecting
          : "${translation(context).lbl_ringing} $contactName...";
      displayIcon = isVideoCall ? Icons.videocam : Icons.phone;
      indicatorColor = Colors.blue;
    }

    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated connecting indicator
            SizedBox(
              width: 100,
              height: 100,
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
                              decoration: BoxDecoration(
                                color: indicatorColor.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        // This causes the animation to rebuild and repeat
                        (context as Element).markNeedsBuild();
                      },
                    ),

                  // Static circle for ended state
                  if (!showSpinner)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: indicatorColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: indicatorColor, width: 2),
                      ),
                    ),

                  // Main indicator (only when still connecting)
                  if (showSpinner)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                      strokeWidth: 3,
                    ),

                  // Center icon
                  Icon(
                    displayIcon,
                    color: showSpinner ? Colors.white : indicatorColor,
                    size: 30,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Contact name
            Text(
              contactName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Status message
            Text(
              displayMessage,
              style: TextStyle(
                color: showSpinner ? Colors.white70 : indicatorColor,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),

            // Reconnect countdown (if applicable)
            if (reconnectCountdown > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${translation(context).lbl_disconnecting_in} $reconnectCountdown ${translation(context).lbl_seconds}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Retry button (only show when appropriate)
            if (showRetry && callEndReason == null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(translation(context).lbl_try_again),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}