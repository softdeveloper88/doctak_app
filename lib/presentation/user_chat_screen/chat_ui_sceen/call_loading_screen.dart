import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';

enum CallStatus { calling, ringing, busy, offline, rejected, timeout, accepted }

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

class CallLoadingScreenState extends State<CallLoadingScreen>
    with SingleTickerProviderStateMixin {
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

  Color _getStatusColor(OneUITheme theme) {
    switch (_status) {
      case CallStatus.ringing:
      case CallStatus.accepted:
        return theme.success;
      case CallStatus.busy:
      case CallStatus.offline:
      case CallStatus.rejected:
      case CallStatus.timeout:
        return theme.error;
      default:
        return theme.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final statusColor = _getStatusColor(theme);

    return Scaffold(
      backgroundColor: theme.isDark
          ? const Color(0xFF0D1B2A)
          : const Color(0xFF1B2838),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: theme.isDark
                    ? const Color(0xFF0D1B2A).withOpacity(0.8)
                    : const Color(0xFF1B2838).withOpacity(0.8),
              ),
            ),

            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 1),

                // User avatar with animation
                _buildUserAvatar(theme),

                const SizedBox(height: 24),

                // User name
                Text(
                  widget.contactName,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),

                const SizedBox(height: 12),

                // Call status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isVideoCall
                            ? Icons.videocam_rounded
                            : Icons.phone_rounded,
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
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Status-specific indicators
                _buildStatusIndicator(theme),

                const Spacer(flex: 2),

                // End call button
                _buildEndCallButton(theme),

                const SizedBox(height: 50),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndCallButton(OneUITheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onCancel,
        borderRadius: BorderRadius.circular(35),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: theme.error,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.error.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.call_end_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(OneUITheme theme) {
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
                      color: theme.success.withOpacity(
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
                    color: theme.primary.withOpacity(
                      0.3 + _animationController.value * 0.5,
                    ),
                    width: 3,
                  ),
                ),
              );
            },
          ),

        // Main avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.surfaceVariant,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.contactAvatar.isNotEmpty
                ? Image.network(
                    widget.contactAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person_rounded,
                      size: 60,
                      color: theme.textSecondary,
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    size: 60,
                    color: theme.textSecondary,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(OneUITheme theme) {
    switch (_status) {
      case CallStatus.calling:
        return CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          strokeWidth: 3,
        );

      case CallStatus.ringing:
        return _buildRingingDots(theme);

      case CallStatus.accepted:
        return Icon(Icons.check_circle_rounded, color: theme.success, size: 40);

      case CallStatus.busy:
        return Icon(Icons.phone_disabled_rounded, color: theme.error, size: 40);

      case CallStatus.offline:
        return Icon(
          Icons.signal_wifi_off_rounded,
          color: theme.error,
          size: 40,
        );

      case CallStatus.rejected:
        return Icon(Icons.call_end_rounded, color: theme.error, size: 40);

      case CallStatus.timeout:
        return Icon(Icons.access_time_rounded, color: theme.error, size: 40);
    }
  }

  Widget _buildRingingDots(OneUITheme theme) {
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
                color: theme.success.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
