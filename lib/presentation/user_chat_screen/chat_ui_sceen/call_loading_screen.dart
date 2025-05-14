import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:doctak_app/localization/app_localization.dart';

enum CallStatus {
  calling,
  ringing,
  busy,
  offline,
  rejected,
  timeout,
  accepted
}

class CallLoadingScreen extends StatefulWidget {
  final String contactName;
  final String contactAvatar;
  final bool isVideoCall;
  final VoidCallback onCancel;

  const CallLoadingScreen({
    Key? key,
    required this.contactName,
    required this.contactAvatar,
    required this.isVideoCall,
    required this.onCancel,
  }) : super(key: key);

  @override
  CallLoadingScreenState createState() => CallLoadingScreenState();
}

class CallLoadingScreenState extends State<CallLoadingScreen> with SingleTickerProviderStateMixin {
  CallStatus _status = CallStatus.calling;
  late AnimationController _animationController;

  // Getter to allow external access to the current status
  CallStatus get status => _status;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void updateStatus(CallStatus status) {
    if (mounted) {
      setState(() {
        _status = status;
      });
    }
  }

  String get statusText {
    switch (_status) {
       case CallStatus.calling:
        return translation(context).lbl_calling_status;
      case CallStatus.ringing:
        return translation(context).lbl_ringing;
      case CallStatus.busy:
        return translation(context).lbl_user_busy;
      case CallStatus.offline:
        return translation(context).lbl_user_offline;
      case CallStatus.rejected:
        return translation(context).lbl_call_rejected;
      case CallStatus.timeout:
        return translation(context).lbl_no_answer;
      case CallStatus.accepted:
        return translation(context).lbl_call_accepted;
    }
  }

  Color get statusColor {
    switch (_status) {
      case CallStatus.ringing:
      case CallStatus.accepted:
        return Colors.green;
      case CallStatus.busy:
      case CallStatus.offline:
      case CallStatus.rejected:
      case CallStatus.timeout:
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),

            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // User avatar with animation
                _buildUserAvatar(),

                const SizedBox(height: 24),

                // User name
                Text(
                  widget.contactName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // Call status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isVideoCall ? Icons.videocam : Icons.phone,
                        color: statusColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Status-specific indicators
                _buildStatusIndicator(),

                const Spacer(flex: 2),

                // End call button
                GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated rings for ringing status
        if (_status == CallStatus.ringing)
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (index + 1) * 0.3 * _animationController.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(
                        (1 - _animationController.value) * 0.2,
                      ),
                    ),
                  ),
                );
              },
            );
          }),

        // Pulsating border for calling status
        if (_status == CallStatus.calling)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(
                      0.3 + _animationController.value * 0.5,
                    ),
                    width: 3,
                  ),
                ),
              );
            },
          ),

        // Main avatar
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade800,
          backgroundImage: widget.contactAvatar.isNotEmpty
              ? NetworkImage(widget.contactAvatar)
              : null,
          child: widget.contactAvatar.isEmpty
              ? const Icon(Icons.person, size: 60, color: Colors.white)
              : null,
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    switch (_status) {
      case CallStatus.calling:
        return const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        );

      case CallStatus.ringing:
        return _buildRingingDots();

      case CallStatus.accepted:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 40,
        );

      case CallStatus.busy:
        return  const Icon(
          Icons.phone_disabled,
          color: Colors.red,
          size: 40,
        );

      case CallStatus.offline:
        return const Icon(
          Icons.signal_wifi_off,
          color: Colors.red,
          size: 40,
        );

      case CallStatus.rejected:
        return const Icon(
          Icons.call_end,
          color: Colors.red,
          size: 40,
        );

      case CallStatus.timeout:
        return const Icon(
          Icons.access_time,
          color: Colors.red,
          size: 40,
        );
    }
  }

  Widget _buildRingingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final double delay = index * 0.2;
            final double animValue = (_animationController.value - delay) % 1.0;
            final double opacity = animValue > 0 ? animValue : 0.3;
            final double size = animValue > 0 ? 10.0 + 5.0 * animValue : 10.0;

            return Container(
              width: size,
              height: size,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}