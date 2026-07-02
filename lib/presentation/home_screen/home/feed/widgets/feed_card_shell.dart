import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_menu.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_icons.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Horizontal inset for home feed cards and strip sections (matches reference `.post` margin).
const double kFeedHorizontalGutter = 12.0;

/// Vertical spacing between stacked feed cards.
const double kFeedCardVerticalGap = 8.0;

String feedCompactNumber(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return '$value';
}

String feedAvatarInitial(String? name) {
  final trimmed = (name ?? '').trim();
  if (trimmed.isEmpty) return 'D';
  return trimmed[0].toUpperCase();
}

String feedRelativeTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return '';
  return timeago.format(parsed.toLocal());
}

/// Action row label with optional count, e.g. "Repost 3".
String feedActionLabel(String label, int count) {
  if (count <= 0) return label;
  return '$label ${feedCompactNumber(count)}';
}

/// Pixels for [CachedNetworkImage.memCacheWidth/Height] from logical size.
int feedMemCachePx(BuildContext context, double logicalSize) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalSize * dpr).round().clamp(1, 2048);
}

/// Outer container for every feed card.
class FeedCardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const FeedCardShell({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(14, 14, 14, 6),
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          kFeedHorizontalGutter,
          kFeedCardVerticalGap,
          kFeedHorizontalGutter,
          kFeedCardVerticalGap,
        ),
        decoration: theme.feedCardDecoration,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Semantic badge colors matching doctak-web feed cards.
Color feedBadgeColor(String label, OneUITheme theme) {
  switch (label.toLowerCase()) {
    case 'poll':
      return theme.success;
    case 'case':
      return theme.error;
    case 'article':
    case 'blog':
    case 'survey':
      return theme.primary;
    case 'job':
      return theme.primary;
    case 'cme':
      return theme.secondary;
    default:
      return theme.primary;
  }
}

/// Primary-theme pill CTA (Respond, Join, Apply, Register).
class FeedAccentButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const FeedAccentButton({
    super.key,
    required this.label,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: padding,
          decoration: theme.primaryButtonDecoration,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Muted status chip for joined / registered / pending states in feed strips.
class FeedStatusChip extends StatelessWidget {
  final String label;
  final double fontSize;

  const FeedStatusChip({
    super.key,
    required this.label,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.border.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: theme.textSecondary,
        ),
      ),
    );
  }
}

/// Section header for horizontal feed strips (Surveys, Groups, Jobs…).
class FeedStripHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String seeAllLabel;
  final VoidCallback? onSeeAll;

  const FeedStripHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.seeAllLabel = 'See all',
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: theme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.titleSmall),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: theme.caption),
                  ),
              ],
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                seeAllLabel,
                style: theme.bodySecondary.copyWith(
                  color: theme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small pill badge (JOB, CASE, ARTICLE, POLL, etc.).
class FeedBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const FeedBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final c = color ?? feedBadgeColor(label, theme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: c,
        ),
      ),
    );
  }
}

/// Overlapping avatars — group/page logo with poster badge (website parity).
class FeedOverlapAvatar extends StatelessWidget {
  final String primaryName;
  final String? primaryAvatarUrl;
  final String secondaryName;
  final String? secondaryAvatarUrl;
  final double size;

  const FeedOverlapAvatar({
    super.key,
    required this.primaryName,
    this.primaryAvatarUrl,
    required this.secondaryName,
    this.secondaryAvatarUrl,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final badgeSize = size < 44 ? 18.0 : 22.0;
    final outer = size + badgeSize * 0.42;

    return SizedBox(
      width: outer,
      height: outer,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: _circleAvatar(
              context: context,
              theme: theme,
              name: primaryName,
              url: primaryAvatarUrl,
              diameter: size,
              fontSize: size * 0.4,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: theme.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: theme.cardBackground, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _circleAvatar(
                  context: context,
                  theme: theme,
                  name: secondaryName,
                  url: secondaryAvatarUrl,
                  diameter: badgeSize,
                  fontSize: badgeSize * 0.42,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleAvatar({
    required BuildContext context,
    required OneUITheme theme,
    required String name,
    required String? url,
    required double diameter,
    required double fontSize,
  }) {
    final fallback = Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.avatarBackground,
        shape: BoxShape.circle,
      ),
      child: Text(
        feedAvatarInitial(name),
        style: TextStyle(
          color: theme.avatarText,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          fontFamily: 'Poppins',
        ),
      ),
    );
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: AppCachedNetworkImage(
        imageUrl: url,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        memCacheWidth: feedMemCachePx(context, diameter),
        memCacheHeight: feedMemCachePx(context, diameter),
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        filterQuality: FilterQuality.low,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

/// Group post attribution — group name, poster name + time, overlap avatars.
class FeedGroupPostHeader extends StatelessWidget {
  final String groupName;
  final String? groupLogoUrl;
  final String posterName;
  final String? posterAvatarUrl;
  final String? createdAt;
  final bool posterVerified;
  final String? trailingBadge;
  final VoidCallback? onGroupTap;
  final VoidCallback? onPosterTap;

  const FeedGroupPostHeader({
    super.key,
    required this.groupName,
    this.groupLogoUrl,
    required this.posterName,
    this.posterAvatarUrl,
    this.createdAt,
    this.posterVerified = false,
    this.trailingBadge,
    this.onGroupTap,
    this.onPosterTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final time = feedRelativeTime(createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onGroupTap,
          child: FeedOverlapAvatar(
            primaryName: groupName,
            primaryAvatarUrl: groupLogoUrl,
            secondaryName: posterName,
            secondaryAvatarUrl: posterAvatarUrl,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onGroupTap,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  groupName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Row(
                  children: [
                    Flexible(
                      child: GestureDetector(
                        onTap: onPosterTap,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                posterName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.caption.copyWith(
                                  color: theme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (posterVerified) ...[
                              const SizedBox(width: 4),
                              theme.buildVerifiedBadge(size: 14),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (time.isNotEmpty) ...[
                      Text(' · ', style: theme.caption),
                      Text(time, style: theme.caption),
                    ],
                    if (trailingBadge != null) ...[
                      if (time.isNotEmpty) Text(' · ', style: theme.caption),
                      FeedBadge(
                        label: trailingBadge!,
                        color: feedBadgeColor(trailingBadge!, theme),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Author row: avatar + name (+ verified) + subtitle + time/label row.
/// Post-type labels (Article, Poll, …) appear on the time row; overflow menu
/// sits at the far right, aligned with the name.
class FeedAuthorHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String subtitle;
  final String? createdAt;
  final bool verified;
  final String? trailingBadge;
  final Color? trailingBadgeColor;
  final String? visibility;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Moderation — report / block / not interested (other users only).
  final bool isCurrentUser;
  final String? postId;
  final String? userId;
  final String contentType;
  final VoidCallback? onDismiss;
  final VoidCallback? onUserBlocked;

  const FeedAuthorHeader({
    super.key,
    required this.name,
    this.avatarUrl,
    this.subtitle = '',
    this.createdAt,
    this.verified = false,
    this.trailingBadge,
    this.trailingBadgeColor,
    this.visibility,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isCurrentUser = false,
    this.postId,
    this.userId,
    this.contentType = 'post',
    this.onDismiss,
    this.onUserBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final time = feedRelativeTime(createdAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: _avatar(context, theme),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.titleSmall,
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 4),
                            theme.buildVerifiedBadge(size: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.caption.copyWith(color: theme.textSecondary),
                  ),
                ),
              if (time.isNotEmpty ||
                  visibility != null ||
                  trailingBadge != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Row(
                    children: [
                      if (time.isNotEmpty)
                        Text(time, style: theme.caption),
                      if (time.isNotEmpty && visibility != null)
                        Text(' · ', style: theme.caption),
                      if (visibility != null) ...[
                        Icon(Icons.public, size: 11, color: theme.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          visibility!,
                          style: theme.caption,
                        ),
                      ],
                      if (trailingBadge != null) ...[
                        if (time.isNotEmpty || visibility != null)
                          Text(' · ', style: theme.caption),
                        FeedBadge(
                          label: trailingBadge!,
                          color: trailingBadgeColor ??
                              feedBadgeColor(trailingBadge!, theme),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (onEdit != null ||
            onDelete != null ||
            (!isCurrentUser && postId != null && userId != null))
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 2),
            child: FeedCardOverflowMenu(
              isCurrentUser: isCurrentUser,
              postId: postId,
              userId: userId,
              authorName: name,
              contentType: contentType,
              onEdit: onEdit,
              onDelete: onDelete,
              onDismiss: onDismiss,
              onUserBlocked: onUserBlocked,
            ),
          ),
      ],
    );
  }

  Widget _avatar(BuildContext context, OneUITheme theme) {
    const size = 48.0;
    const radius = size / 2;
    final url = avatarUrl;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.avatarBackground,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        feedAvatarInitial(name),
        style: TextStyle(
          color: theme.avatarText,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          fontFamily: 'Poppins',
        ),
      ),
    );
    if (url == null || url.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AppCachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: feedMemCachePx(context, size),
        memCacheHeight: feedMemCachePx(context, size),
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        filterQuality: FilterQuality.low,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}

/// A single action button used in the action row (Like / Comment / Share…).
class FeedActionButton extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  /// When true, renders icon only — no text label.
  final bool iconOnly;

  /// Optional count appended to [label], e.g. "Comment 5".
  final int? count;

  const FeedActionButton({
    super.key,
    this.icon,
    this.svgAsset,
    this.label = '',
    this.onTap,
    this.active = false,
    this.iconOnly = false,
    this.count,
  }) : assert(icon != null || svgAsset != null);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final color = active ? theme.primary : theme.textSecondary;
    final displayLabel =
        iconOnly ? label : feedActionLabel(label, count ?? 0);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: theme.radiusM,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (svgAsset != null)
                FeedIcon(asset: svgAsset!, size: 18, color: color)
              else if (icon != null)
                Icon(icon, size: 18, color: color)
              else
                const SizedBox.shrink(),
              if (!iconOnly && displayLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin divider + actions row wrapper.
class FeedActionRow extends StatelessWidget {
  final List<Widget> actions;
  const FeedActionRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Divider(height: 1, thickness: 0.5, color: theme.divider),
        ),
        Row(children: actions),
      ],
    );
  }
}
