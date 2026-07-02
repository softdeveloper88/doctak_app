import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/notification_model/notification_model.dart';
import 'package:doctak_app/theme/doctak_palette.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

class NotificationTokens {
  NotificationTokens._();

  static const Color reactionBadge = Color(0xFFE0245E);
  static const Color replyBadge = Color(0xFF0B6BCB);
  static const Color connectionBadge = Color(0xFF7C3AED);
  static const Color mentionBadge = Color(0xFF059669);
  static const Color jobBadge = Color(0xFFEA580C);
  static const Color messageBadge = Color(0xFF059669);
}

class NotificationFilterBar extends StatelessWidget {
  final int selectedIndex;
  final int unreadCount;
  final ValueChanged<int> onChanged;

  const NotificationFilterBar({
    super.key,
    required this.selectedIndex,
    required this.unreadCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.segmentedTrack,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: _FilterPill(
                label: 'All',
                selected: selectedIndex == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _FilterPill(
                label: 'Unread',
                selected: selectedIndex == 1,
                badgeCount: unreadCount,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.selected,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? theme.segmentedSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected && !theme.isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? theme.textPrimary : theme.textSecondary,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.textSecondary.withValues(alpha: 0.12)
                      : theme.textSecondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NotificationSectionHeader extends StatelessWidget {
  final String title;

  const NotificationSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: theme.divider),
        ],
      ),
    );
  }
}

class NotificationListTile extends StatelessWidget {
  final Data notification;
  final String timeLabel;
  final VoidCallback onTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const NotificationListTile({
    super.key,
    required this.notification,
    required this.timeLabel,
    required this.onTap,
    this.onAvatarTap,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final unread = notification.isUnread;
    final badge = _badgeFor(notification);
    final showActions = notification.showConnectionActions == true &&
        onAccept != null &&
        onDecline != null;

    return Material(
      color: unread ? theme.unreadNotificationBackground : theme.cardBackground,
      child: InkWell(
        onTap: showActions ? null : onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (unread)
                Container(
                  width: 4,
                  color: theme.unreadNotificationAccent,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NotificationAvatar(
                        name: notification.displayActorName,
                        imageUrl: notification.senderProfilePic,
                        badgeIcon: badge.icon,
                        badgeColor: badge.color,
                        onTap: onAvatarTap,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _NotificationRichText(notification: notification, theme: theme),
                            if (showActions) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  FilledButton(
                                    onPressed: onAccept,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: theme.primary,
                                      minimumSize: const Size(0, 34),
                                      padding: const EdgeInsets.symmetric(horizontal: 18),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Accept',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: onDecline,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: theme.textPrimary,
                                      side: BorderSide(color: theme.border),
                                      minimumSize: const Size(0, 34),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Decline',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 13, color: theme.textTertiary),
                                const SizedBox(width: 4),
                                Text(
                                  timeLabel,
                                  style: theme.caption.copyWith(color: theme.textTertiary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!showActions) ...[
                        if (unread)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 6),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.unreadNotificationAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(left: 6, top: 2),
                          child: Material(
                            color: theme.primary.withValues(alpha: 0.08),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onTap,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: theme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
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

class _NotificationRichText extends StatelessWidget {
  final Data notification;
  final OneUITheme theme;

  const _NotificationRichText({
    required this.notification,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final actor = notification.displayActorName;
    final others = notification.othersCount ?? 0;
    final action = (notification.actionText ?? notification.text ?? '').trim();
    final snippet = (notification.snippet ?? '').trim();

    final spans = <InlineSpan>[
      TextSpan(
        text: actor,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: theme.textPrimary,
        ),
      ),
    ];

    if (others > 0) {
      spans.add(TextSpan(
        text: ' and $others ${others == 1 ? 'other' : 'others'}',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: theme.textPrimary,
        ),
      ));
    }

    if (action.isNotEmpty) {
      final actionText = snippet.isNotEmpty && action.contains(':')
          ? action
          : (snippet.isNotEmpty ? '$action: "$snippet"' : ' $action');
      spans.add(TextSpan(
        text: actionText.startsWith(' ') ? actionText : ' $actionText',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: theme.textSecondary,
        ),
      ));
    }

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final IconData badgeIcon;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _NotificationAvatar({
    required this.name,
    required this.imageUrl,
    required this.badgeIcon,
    required this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final pic = AppData.fullImageUrl(imageUrl);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'M';
    final color = _avatarColor(name);

    Widget avatar = ClipOval(
      child: pic.isNotEmpty
          ? AppCachedNetworkImage(
              imageUrl: pic,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            )
          : Container(
              width: 44,
              height: 44,
              color: color,
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
    );

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: theme.cardBackground, width: 2),
              ),
              child: Icon(badgeIcon, size: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBadge {
  final IconData icon;
  final Color color;

  const _NotificationBadge(this.icon, this.color);
}

_NotificationBadge _badgeFor(Data notification) {
  final category = (notification.category ?? _categoryFromType(notification.type)).toLowerCase();
  switch (category) {
    case 'reaction':
      return const _NotificationBadge(Icons.favorite, NotificationTokens.reactionBadge);
    case 'reply':
      return const _NotificationBadge(Icons.chat_bubble, NotificationTokens.replyBadge);
    case 'connection':
      return const _NotificationBadge(Icons.person, NotificationTokens.connectionBadge);
    case 'mention':
      return const _NotificationBadge(Icons.alternate_email, NotificationTokens.mentionBadge);
    case 'job':
      return const _NotificationBadge(Icons.work_outline, NotificationTokens.jobBadge);
    case 'message':
      return const _NotificationBadge(Icons.message, NotificationTokens.messageBadge);
    default:
      return const _NotificationBadge(Icons.notifications, DoctakPalette.textSoft);
  }
}

String _categoryFromType(String? type) {
  final t = (type ?? '').toLowerCase();
  if (['likes_on_posts', 'new_like', 'like_on_posts', 'post_liked', 'post.liked'].contains(t)) {
    return 'reaction';
  }
  if (['comments_on_posts', 'reply_to_comment', 'comment.reply', 'like_comment_on_post', 'case.reply'].contains(t)) {
    return 'reply';
  }
  if (['friend_request', 'follow_request', 'friend_request.sent'].contains(t)) {
    return 'connection';
  }
  if (['connection_accepted', 'friend_request.accepted', 'follower_notification', 'follow.new'].contains(t)) {
    return 'connection';
  }
  if (['mentions', 'mention.created'].contains(t)) return 'mention';
  if (['new_job_posted', 'job_post_notification', 'job_update', 'job.posted', 'job.suggested'].contains(t)) {
    return 'job';
  }
  if (['message', 'message_received', 'message.received'].contains(t)) return 'message';
  if (['like_comments', 'comment.liked'].contains(t)) return 'reaction';
  return 'other';
}

Color _avatarColor(String seed) {
  const palette = [
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFF7C3AED),
    Color(0xFFDC2626),
    Color(0xFF0891B2),
    Color(0xFF4B5563),
  ];
  if (seed.trim().isEmpty) return palette.first;
  return palette[seed.hashCode.abs() % palette.length];
}
