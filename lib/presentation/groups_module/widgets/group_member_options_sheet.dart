import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

typedef GroupMemberAction = Future<void> Function(String action);

Future<void> showGroupMemberOptionsSheet(
  BuildContext context, {
  required GroupMemberModel member,
  required GroupDetailModel group,
  required GroupMemberAction onAction,
}) {
  final theme = OneUITheme.of(context);
  final caps = group.capabilities;
  final items = _buildItems(member, caps);

  if (items.isEmpty) return Future.value();

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
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              ...items.map((item) {
                return ListTile(
                  tileColor: theme.cardBackground,
                  splashColor: theme.primary.withValues(alpha: 0.08),
                  leading: Icon(
                    item.icon,
                    color: item.destructive ? theme.error : theme.textPrimary,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: item.destructive ? theme.error : theme.textPrimary,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await onAction(item.action);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class _MenuItem {
  final String action;
  final String label;
  final IconData icon;
  final bool destructive;

  const _MenuItem({
    required this.action,
    required this.label,
    required this.icon,
    this.destructive = false,
  });
}

List<_MenuItem> _buildItems(GroupMemberModel member, GroupCapabilitiesModel caps) {
  if (!caps.canModerate) return [];

  if (member.status == 'pending') {
    return const [
      _MenuItem(action: 'approve', label: 'Approve request', icon: Icons.check_circle_outline),
      _MenuItem(
        action: 'reject',
        label: 'Reject request',
        icon: Icons.cancel_outlined,
        destructive: true,
      ),
    ];
  }

  if (member.status == 'rejected') {
    final items = <_MenuItem>[
      const _MenuItem(action: 'approve', label: 'Approve member', icon: Icons.check_circle_outline),
    ];
    if (_canRemove(member, caps)) {
      items.add(const _MenuItem(
        action: 'remove',
        label: 'Remove from group',
        icon: Icons.person_remove_outlined,
        destructive: true,
      ));
    }
    return items;
  }

  if (member.status == 'suspended') {
    final items = <_MenuItem>[
      const _MenuItem(action: 'approve', label: 'Restore access', icon: Icons.restore),
    ];
    if (_canRemove(member, caps)) {
      items.add(const _MenuItem(
        action: 'remove',
        label: 'Remove from group',
        icon: Icons.person_remove_outlined,
        destructive: true,
      ));
    }
    return items;
  }

  if (member.role == 'owner') return [];

  final items = <_MenuItem>[];

  if (caps.isOwner && member.role == 'member') {
    items.add(const _MenuItem(
      action: 'make_admin',
      label: 'Make admin',
      icon: Icons.admin_panel_settings_outlined,
    ));
  }
  if ((caps.isOwner || caps.canRemoveMembers) && member.role == 'member') {
    items.add(const _MenuItem(
      action: 'make_moderator',
      label: 'Make moderator',
      icon: Icons.shield_outlined,
    ));
  }
  if (caps.isOwner && member.role == 'admin') {
    items.add(const _MenuItem(
      action: 'remove_admin',
      label: 'Remove admin role',
      icon: Icons.shield_outlined,
    ));
  }
  if ((caps.isOwner || caps.canRemoveMembers) && member.role == 'moderator') {
    items.add(const _MenuItem(
      action: 'remove_moderator',
      label: 'Remove moderator role',
      icon: Icons.shield_outlined,
    ));
  }

  if (_canRemove(member, caps)) {
    items.add(const _MenuItem(
      action: 'suspend',
      label: 'Block member',
      icon: Icons.block_outlined,
      destructive: true,
    ));
    items.add(const _MenuItem(
      action: 'remove',
      label: 'Remove from group',
      icon: Icons.person_remove_outlined,
      destructive: true,
    ));
  }

  return items;
}

bool _canRemove(GroupMemberModel member, GroupCapabilitiesModel caps) {
  if (!caps.canRemoveMembers) return false;
  if (member.role == 'owner') return false;
  if (member.role == 'admin' && !caps.isOwner) return false;
  return true;
}
