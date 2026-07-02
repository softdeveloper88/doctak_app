import 'dart:ui';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

const _kCoverHeight = 140.0;
const _kAvatarSize = 72.0;
const _kHorizontalPadding = 12.0;
/// Pulls the group logo halfway onto the cover (matches web `margin-top: -36px`).
const _kAvatarOverlap = _kAvatarSize / 2;
const _kIdentityMainTopPadding = 8.0;
const _kAvatarTextGap = 10.0;

/// Profile-style group header aligned with web group hero layout.
class GroupProfileHeader extends StatelessWidget {
  final GroupDetailModel group;
  final VoidCallback onBack;
  final VoidCallback? onMenuTap;
  final VoidCallback? onInviteTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onJoinTap;
  final bool membershipBusy;

  /// When false, back/menu are provided by the parent [SliverAppBar].
  final bool showCoverActions;

  const GroupProfileHeader({
    super.key,
    required this.group,
    required this.onBack,
    this.onMenuTap,
    this.onInviteTap,
    this.onShareTap,
    this.onJoinTap,
    this.membershipBusy = false,
    this.showCoverActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final start = _parseColor(group.primaryColor) ?? const Color(0xFF0D9488);
    final end = _parseColor(group.secondaryColor) ?? const Color(0xFF115E59);
    final bannerUrl = AppData.fullImageUrl(group.bannerImage);
    final logoUrl = AppData.fullImageUrl(group.logoImage);
    final topInset = MediaQuery.paddingOf(context).top;
    final metaLine = formatGroupMetaLine(group);
    final coverBlockHeight = _kCoverHeight + topInset;
    final isMember = group.membership?.isActiveMember == true;
    final isPending = group.membership?.isPending == true;
    final description = group.description?.trim();

    return ColoredBox(
      color: theme.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        SizedBox(
          height: coverBlockHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bannerUrl.isNotEmpty)
                AppCachedNetworkImage(imageUrl: bannerUrl, fit: BoxFit.cover)
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [start, end],
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.32),
                    ],
                  ),
                ),
              ),
              if (showCoverActions)
                Positioned(
                  top: topInset + 6,
                  left: _kHorizontalPadding,
                  right: _kHorizontalPadding,
                  child: Row(
                    children: [
                      _CoverButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
                      const Spacer(),
                      if (onShareTap != null) ...[
                        _CoverButton(
                          icon: Icons.share_outlined,
                          onTap: onShareTap!,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (onMenuTap != null)
                        _CoverButton(icon: Icons.more_horiz_rounded, onTap: onMenuTap!),
                    ],
                  ),
                ),
              Positioned(
                right: _kHorizontalPadding,
                bottom: 10,
                child: _CoverBottomActions(
                  group: group,
                  isMember: isMember,
                  isPending: isPending,
                  membershipBusy: membershipBusy,
                  onInviteTap: onInviteTap,
                  onJoinTap: onJoinTap,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _kHorizontalPadding,
            0,
            _kHorizontalPadding,
            12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, -_kAvatarOverlap),
                child: _GroupAvatar(
                  logoUrl: logoUrl,
                  name: group.name,
                  start: start,
                  end: end,
                ),
              ),
              SizedBox(width: _kAvatarTextGap),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: _kIdentityMainTopPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: theme.textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          if (group.isVerified)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: theme.primary,
                              ),
                            ),
                        ],
                      ),
                      if (metaLine.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          metaLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _MemberActivityRow(group: group),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: theme.textPrimary,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            _kHorizontalPadding,
            0,
            _kHorizontalPadding,
            8,
          ),
          child: _ContentStatsRow(group: group),
        ),
      ],
      ),
    );
  }

}

class _CoverBottomActions extends StatelessWidget {
  final GroupDetailModel group;
  final bool isMember;
  final bool isPending;
  final bool membershipBusy;
  final VoidCallback? onInviteTap;
  final VoidCallback? onJoinTap;

  const _CoverBottomActions({
    required this.group,
    required this.isMember,
    required this.isPending,
    required this.membershipBusy,
    this.onInviteTap,
    this.onJoinTap,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _CoverActionButton(
        label: 'Invite',
        icon: Icons.person_add_alt_1_outlined,
        filled: true,
        onTap: onInviteTap,
      ),
    ];

    if (!isMember) {
      if (isPending) {
        children.add(const SizedBox(width: 8));
        children.add(
          const _CoverActionButton(
            label: 'Pending',
            icon: Icons.schedule_rounded,
          ),
        );
      } else if (group.privacy == 'invitation_only') {
        children.add(const SizedBox(width: 8));
        children.add(
          const _CoverActionButton(
            label: 'Invite only',
            icon: Icons.lock_outline_rounded,
          ),
        );
      } else if (onJoinTap != null && !group.capabilities.canManage) {
        children.add(const SizedBox(width: 8));
        children.add(
          _CoverActionButton(
            label: group.privacy == 'private' ? 'Request' : 'Join',
            icon: Icons.group_add_outlined,
            filled: true,
            busy: membershipBusy,
            onTap: onJoinTap,
          ),
        );
      }
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _CoverActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool busy;

  const _CoverActionButton({
    required this.label,
    this.icon,
    this.onTap,
    this.filled = false,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && (onTap != null || !filled);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: filled
                    ? const Color(0xFF2563EB).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: filled
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 15,
                      color: filled ? Colors.white : Colors.grey[900],
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    busy ? 'Joining…' : label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: filled ? Colors.white : Colors.grey[900],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberActivityRow extends StatelessWidget {
  final GroupDetailModel group;

  const _MemberActivityRow({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final members = group.membersCount;
    final membersLabel = members == 1 ? 'member' : 'members';
    final activity = formatGroupActivityLabel(group.lastActivityAt ?? group.createdAt);
    final preview = _memberPreview(group);
    final overflow = members > preview.length ? members - preview.length : 0;

    return Row(
      children: [
        _MemberAvatarStack(
          members: preview,
          overflowCount: overflow,
          theme: theme,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '${_formatCount(members)} $membersLabel',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: _ActivityStatus(theme: theme, label: activity),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

List<GroupUserStubModel> _memberPreview(GroupDetailModel group) {
  final seen = <String>{};
  final list = <GroupUserStubModel>[];

  void add(GroupUserStubModel? user) {
    if (user == null || user.id.isEmpty || seen.contains(user.id)) return;
    seen.add(user.id);
    list.add(user);
  }

  add(group.creator);
  for (final admin in group.admins) {
    add(admin);
  }
  for (final mod in group.moderators) {
    add(mod);
  }

  return list.take(4).toList();
}

class _MemberAvatarStack extends StatelessWidget {
  final List<GroupUserStubModel> members;
  final int overflowCount;
  final OneUITheme theme;

  const _MemberAvatarStack({
    required this.members,
    required this.overflowCount,
    required this.theme,
  });

  static const _size = 26.0;
  static const _overlap = 9.0;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty && overflowCount <= 0) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(color: theme.cardBackground, width: 2),
        ),
        child: Icon(Icons.people_outline_rounded, size: 14, color: theme.textTertiary),
      );
    }

    final visible = members.take(4).toList();
    final width = _size + (visible.length + (overflowCount > 0 ? 1 : 0) - 1) * (_size - _overlap);

    return SizedBox(
      width: width.clamp(_size, double.infinity),
      height: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * (_size - _overlap),
              child: _MemberFace(user: visible[i], theme: theme),
            ),
          if (overflowCount > 0)
            Positioned(
              left: visible.length * (_size - _overlap),
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.cardBackground, width: 2),
                ),
                child: Text(
                  '+${_formatOverflow(overflowCount)}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: theme.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatOverflow(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _MemberFace extends StatelessWidget {
  final GroupUserStubModel user;
  final OneUITheme theme;

  const _MemberFace({required this.user, required this.theme});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = AppData.fullImageUrl(user.avatar);
    final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

    return Container(
      width: _MemberAvatarStack._size,
      height: _MemberAvatarStack._size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.cardBackground, width: 2),
        color: theme.surfaceVariant,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl.isNotEmpty
          ? AppCachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover)
          : Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.textSecondary,
                ),
              ),
            ),
    );
  }
}

class _ContentStatsRow extends StatelessWidget {
  final GroupDetailModel group;

  const _ContentStatsRow({required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _InlineStat(
            count: group.postsCount,
            label: 'Posts',
            theme: theme,
          ),
          _StatSeparator(theme: theme),
          _InlineStat(
            count: group.pollsCount,
            label: 'Polls',
            theme: theme,
          ),
          _StatSeparator(theme: theme),
          _InlineStat(
            count: group.articlesCount,
            label: 'Articles',
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StatSeparator extends StatelessWidget {
  final OneUITheme theme;

  const _StatSeparator({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        width: 1,
        height: 22,
        color: theme.divider,
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final int count;
  final String label;
  final OneUITheme theme;

  const _InlineStat({
    required this.count,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatCount(count),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: theme.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: theme.textTertiary),
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ActivityStatus extends StatelessWidget {
  final OneUITheme theme;
  final String label;

  const _ActivityStatus({required this.theme, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final String logoUrl;
  final String name;
  final Color start;
  final Color end;

  const _GroupAvatar({
    required this.logoUrl,
    required this.name,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    return Container(
      width: _kAvatarSize,
      height: _kAvatarSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.cardBackground, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: logoUrl.isNotEmpty
          ? AppCachedNetworkImage(imageUrl: logoUrl, fit: BoxFit.cover)
          : DecoratedBox(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [start, end])),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
    );
  }
}

class _CoverButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CoverButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.grey[800]),
          ),
        ),
      ),
    );
  }
}

Color? _parseColor(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  var hex = raw.trim();
  if (hex.startsWith('#')) hex = hex.substring(1);
  if (hex.length == 6) hex = 'FF$hex';
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  return Color(value);
}
