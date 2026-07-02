import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_shell.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Composer bar for group feed — post, poll, and article actions (web FeedComposerBar parity).
class GroupComposeBar extends StatelessWidget {
  final GroupDetailModel group;
  final VoidCallback onPostTap;
  final VoidCallback? onPollTap;
  final VoidCallback? onArticleTap;
  final bool pollDisabled;

  const GroupComposeBar({
    super.key,
    required this.group,
    required this.onPostTap,
    this.onPollTap,
    this.onArticleTap,
    this.pollDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!group.capabilities.canPost) return const SizedBox.shrink();

    final theme = OneUITheme.of(context);
    final logoUrl = AppData.fullImageUrl(group.logoImage);
    final userAvatar = AppData.profilePicUrl;
    final userName = AppData.name.trim().isNotEmpty ? AppData.name.trim() : 'You';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FeedOverlapAvatar(
                primaryName: userName,
                primaryAvatarUrl: userAvatar.isEmpty ? null : userAvatar,
                secondaryName: group.name,
                secondaryAvatarUrl: logoUrl.isEmpty ? null : logoUrl,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onPostTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post to ${group.name}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share an update, case, or question…',
                        style: TextStyle(fontSize: 14, color: theme.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionChip(
                icon: Icons.edit_outlined,
                label: 'Post',
                color: theme.primary,
                onTap: onPostTap,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.poll_outlined,
                label: 'Poll',
                color: const Color(0xFF7C3AED),
                onTap: pollDisabled ? null : onPollTap,
                disabled: pollDisabled,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.article_outlined,
                label: 'Article',
                color: const Color(0xFFEA580C),
                onTap: onArticleTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Expanded(
      child: Material(
        color: disabled ? theme.surfaceVariant : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: disabled ? theme.textTertiary : color,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: disabled ? theme.textTertiary : color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
