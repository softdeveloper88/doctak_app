import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Group actions not already on the profile header / tab bar.
Future<void> showGroupOptionsMenu(
  BuildContext context, {
  required GroupDetailModel group,
  VoidCallback? onManageNotifications,
  VoidCallback? onPostRequests,
  VoidCallback? onSettings,
  VoidCallback? onLeave,
  VoidCallback? onDelete,
  int postRequestCount = 0,
}) {
  final theme = OneUITheme.of(context);
  final canManage = group.capabilities.canManage || group.capabilities.canModerate;
  final isOwner = group.capabilities.isOwner;
  final member = group.membership?.isActiveMember == true;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Material(
        color: theme.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Text(
                  group.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.25,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              if (member && onManageNotifications != null)
                _OptionTile(
                  icon: Icons.notifications_outlined,
                  label: 'Manage notifications',
                  onTap: () {
                    Navigator.pop(ctx);
                    onManageNotifications();
                  },
                ),
              if (canManage && onPostRequests != null)
                _OptionTile(
                  icon: Icons.post_add_outlined,
                  label: 'Review pending posts',
                  trailing: postRequestCount > 0 ? '$postRequestCount' : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    onPostRequests();
                  },
                ),
              if (group.capabilities.canManage && onSettings != null)
                _OptionTile(
                  icon: Icons.settings_outlined,
                  label: 'Edit group settings',
                  onTap: () {
                    Navigator.pop(ctx);
                    onSettings();
                  },
                ),
              if (isOwner && onDelete != null)
                _OptionTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete group',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete();
                  },
                )
              else if (member && !isOwner && onLeave != null)
                _OptionTile(
                  icon: Icons.exit_to_app_rounded,
                  label: 'Leave group',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    onLeave();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final bool destructive;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.destructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final color = destructive ? theme.error : theme.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                    height: 1.25,
                    color: color,
                  ),
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trailing!,
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
