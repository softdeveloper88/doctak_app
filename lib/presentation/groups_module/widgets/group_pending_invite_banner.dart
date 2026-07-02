import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Accept/decline banner shown when opening a group from an invite notification.
class GroupPendingInviteBanner extends StatefulWidget {
  final String invitationId;
  final String? inviterName;
  final VoidCallback? onResponded;

  const GroupPendingInviteBanner({
    super.key,
    required this.invitationId,
    this.inviterName,
    this.onResponded,
  });

  @override
  State<GroupPendingInviteBanner> createState() => _GroupPendingInviteBannerState();
}

class _GroupPendingInviteBannerState extends State<GroupPendingInviteBanner> {
  bool _busy = false;
  bool _hidden = false;

  Future<void> _respond(bool accept) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await GroupsNodeApiService.respondInvitation(widget.invitationId, accept);
      if (!mounted) return;
      setState(() => _hidden = true);
      widget.onResponded?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'You joined the group.' : 'Invitation declined.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();

    final theme = OneUITheme.of(context);
    final who = widget.inviterName?.trim().isNotEmpty == true
        ? widget.inviterName!
        : 'Someone';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$who invited you to this group',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Decline',
                  height: 40,
                  enabled: !_busy,
                  color: theme.surfaceVariant,
                  textColor: theme.textPrimary,
                  onTap: _busy ? null : () => _respond(false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  text: 'Accept',
                  height: 40,
                  enabled: !_busy,
                  onTap: _busy ? null : () => _respond(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
