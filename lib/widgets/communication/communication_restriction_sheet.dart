import 'package:doctak_app/data/apiClient/services/communication_service.dart';
import 'package:doctak_app/data/apiClient/services/network_api_service.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// A bottom sheet that explains why communication is restricted,
/// with a call-to-action (connect / unblock / accept request).
///
/// Usage:
/// ```dart
/// CommunicationRestrictionSheet.show(
///   context: context,
///   permission: permission,
///   targetUserName: 'Dr. Smith',
///   targetUserId: 'abc123',
/// );
/// ```
class CommunicationRestrictionSheet extends StatelessWidget {
  final CommunicationPermission permission;
  final String targetUserName;
  final String targetUserId;
  final VoidCallback? onActionDone;

  const CommunicationRestrictionSheet({
    super.key,
    required this.permission,
    required this.targetUserName,
    required this.targetUserId,
    this.onActionDone,
  });

  /// Convenience method to show as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required CommunicationPermission permission,
    required String targetUserName,
    required String targetUserId,
    VoidCallback? onActionDone,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommunicationRestrictionSheet(
        permission: permission,
        targetUserName: targetUserName,
        targetUserId: targetUserId,
        onActionDone: onActionDone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isBlocked = permission.reasonCode == 'blocked';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ──
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // ── Icon ──
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isBlocked
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isBlocked ? Icons.block_rounded : Icons.lock_outline_rounded,
                  size: 36,
                  color: isBlocked ? Colors.red : Colors.orange[700],
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ──
              Text(
                _title(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // ── Description ──
              Text(
                _description(context),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  color: theme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── Call-to-Action ──
              _buildAction(context, theme),

              const SizedBox(height: 12),

              // ── Dismiss ──
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  translation(context).lbl_cancel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _title(BuildContext context) {
    if (permission.reasonCode == 'blocked') {
      if (permission.blockedDirection == 'you_blocked') {
        return 'User Blocked';
      }
      return 'Communication Restricted';
    }
    if (permission.connectionStatus == 'pending_sent') {
      return 'Request Pending';
    }
    if (permission.connectionStatus == 'pending_received') {
      return 'Accept Connection';
    }
    return 'Not Connected';
  }

  String _description(BuildContext context) {
    if (permission.reason != null && permission.reason!.isNotEmpty) {
      return permission.reason!;
    }

    if (permission.reasonCode == 'blocked') {
      return 'Communication with this user is restricted.';
    }
    return 'You can only message and call users in your connections. '
        'Send a connection request to $targetUserName to start communicating.';
  }

  Widget _buildAction(BuildContext context, OneUITheme theme) {
    // Blocked by you → offer unblock
    if (permission.blockedDirection == 'you_blocked') {
      return _ActionButton(
        icon: Icons.lock_open_rounded,
        label: 'Unblock $targetUserName',
        color: Colors.red,
        onTap: () {
          Navigator.of(context).pop();
          // The caller should handle unblock externally
          onActionDone?.call();
        },
      );
    }

    // Blocked by them or mutual → just dismiss
    if (permission.reasonCode == 'blocked') {
      return const SizedBox.shrink();
    }

    // Pending received → accept
    if (permission.connectionStatus == 'pending_received') {
      return _ActionButton(
        icon: Icons.check_circle_outline_rounded,
        label: 'Accept Connection Request',
        color: Colors.green,
        onTap: () async {
          Navigator.of(context).pop();
          onActionDone?.call();
        },
      );
    }

    // Pending sent → already waiting
    if (permission.connectionStatus == 'pending_sent') {
      return _ActionButton(
        icon: Icons.hourglass_top_rounded,
        label: 'Waiting for Response',
        color: Colors.grey,
        enabled: false,
        onTap: () {},
      );
    }

    // Not connected → send request
    return _ActionButton(
      icon: Icons.person_add_alt_1_rounded,
      label: 'Send Connection Request',
      color: theme.primary,
      onTap: () async {
        try {
          await NetworkApiService().sendFriendRequest(targetUserId);
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Connection request sent!')),
            );
          }
          onActionDone?.call();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send request: $e')),
            );
          }
        }
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.3),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
