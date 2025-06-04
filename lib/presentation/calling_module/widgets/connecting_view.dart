// lib/presentation/call_module/widgets/connecting_view.dart
import 'package:doctak_app/core/app_export.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';

/// Widget that displays connecting state with animations
class ConnectingView extends StatelessWidget {
  final String contactName;
  final bool isIncoming;
  final bool isVideoCall;
  final VoidCallback onRetry;
  final bool showRetry;
  final String? customMessage; // Add option for custom message

  const ConnectingView({
    Key? key,
    required this.contactName,
    required this.isIncoming,
    required this.isVideoCall,
    required this.onRetry,
    this.showRetry = false,
    this.customMessage, // Optional custom message
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  // Pulsating circle animation
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
                              color: Colors.blue.withOpacity(0.3),
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

                  // Main indicator
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),

                  // Center icon
                  Icon(
                    isVideoCall ? Icons.videocam : Icons.phone,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Text(
              // Use custom message if provided, otherwise use default
              customMessage ?? (isIncoming
                  ? translation(context).lbl_connecting
                  : "${translation(context).lbl_ringing} $contactName..."),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (showRetry)
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