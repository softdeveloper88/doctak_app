import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/groups_module/screens/group_detail_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/app_surface_card.dart';
import 'package:flutter/material.dart';

enum GroupCardVariant { browse, mine, suggested, invitation }

class GroupSummaryCard extends StatefulWidget {
  final GroupSummaryModel group;
  final GroupCardVariant variant;
  final bool isJoining;
  final String? pendingInvitationId;
  final String? inviterName;
  final void Function(GroupSummaryModel group)? onJoin;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const GroupSummaryCard({
    super.key,
    required this.group,
    this.variant = GroupCardVariant.browse,
    this.isJoining = false,
    this.pendingInvitationId,
    this.inviterName,
    this.onJoin,
    this.onAccept,
    this.onDecline,
  });

  @override
  State<GroupSummaryCard> createState() => _GroupSummaryCardState();
}

class _GroupSummaryCardState extends State<GroupSummaryCard> {
  late String _navigationGroupId;

  @override
  void initState() {
    super.initState();
    _navigationGroupId = widget.group.routeId.trim();
  }

  @override
  void didUpdateWidget(covariant GroupSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextId = widget.group.routeId.trim();
    if (nextId != _navigationGroupId) {
      _navigationGroupId = nextId;
    }
  }

  GroupSummaryModel get group => widget.group;

  Color _gradientStart() =>
      _parseColor(group.primaryColor) ?? const Color(0xFF0D9488);

  Color _gradientEnd() =>
      _parseColor(group.secondaryColor) ?? const Color(0xFF115E59);

  void _openDetail() {
    final routeId = _navigationGroupId;
    if (routeId.isEmpty) return;
    openGroupDetailById(
      context,
      routeId,
      pendingInvitationId: widget.pendingInvitationId,
      inviterName: widget.inviterName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final member = group.membership?.isActiveMember == true;
    final pending = group.membership?.isPending == true;
    final start = _gradientStart();
    final end = _gradientEnd();

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _openDetail,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Cover(
                  bannerUrl: group.bannerImage,
                  start: start,
                  end: end,
                  roleLabel:
                      widget.variant == GroupCardVariant.mine ? _roleLabel(group) : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -28),
                        child: _Logo(
                          logoUrl: group.logoImage,
                          name: group.name,
                          start: start,
                          end: end,
                        ),
                      ),
                      Text(
                        group.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.01,
                          color: theme.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatGroupMetaLine(group),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: theme.textTertiary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        group.description?.trim().isNotEmpty == true
                            ? group.description!.trim()
                            : 'No description yet.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontStyle: group.description?.trim().isNotEmpty == true
                              ? FontStyle.normal
                              : FontStyle.italic,
                          color: group.description?.trim().isNotEmpty == true
                              ? theme.textSecondary
                              : theme.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatsRow(group: group, theme: theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: _Footer(
              theme: theme,
              group: group,
              variant: widget.variant,
              member: member,
              pending: pending,
              isJoining: widget.isJoining,
              onOpen: _openDetail,
              onJoin: widget.onJoin == null ? null : () => widget.onJoin!(group),
              onAccept: widget.onAccept,
              onDecline: widget.onDecline,
            ),
          ),
        ],
      ),
    );
  }

  String? _roleLabel(GroupSummaryModel group) {
    final role = group.membership?.role;
    if (role == null || group.membership?.isActiveMember != true) return null;
    if (role == 'owner' || role == 'admin') return 'Admin';
    if (role == 'moderator') return 'Moderator';
    return 'Member';
  }
}

class _StatsRow extends StatelessWidget {
  final GroupSummaryModel group;
  final OneUITheme theme;

  const _StatsRow({required this.group, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.divider),
          bottom: BorderSide(color: theme.divider),
        ),
      ),
      child: Row(
        children: [
          _Stat(value: group.membersCount, label: 'Members', theme: theme),
          _Stat(value: group.postsCount, label: 'Posts', theme: theme),
          _Stat(value: group.pollsCount, label: 'Polls', theme: theme),
          _Stat(value: group.articlesCount, label: 'Articles', theme: theme),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  final OneUITheme theme;

  const _Stat({
    required this.value,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            _formatCount(value),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: theme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _Footer extends StatelessWidget {
  final OneUITheme theme;
  final GroupSummaryModel group;
  final GroupCardVariant variant;
  final bool member;
  final bool pending;
  final bool isJoining;
  final VoidCallback onOpen;
  final VoidCallback? onJoin;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _Footer({
    required this.theme,
    required this.group,
    required this.variant,
    required this.member,
    required this.pending,
    required this.isJoining,
    required this.onOpen,
    this.onJoin,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == GroupCardVariant.invitation) {
      return Row(
        children: [
          Expanded(
            child: _CompactActionButton(
              label: 'Decline',
              filled: false,
              theme: theme,
              onTap: onDecline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CompactActionButton(
              label: 'Accept',
              filled: true,
              theme: theme,
              onTap: onAccept,
            ),
          ),
        ],
      );
    }

    final joinable = variant == GroupCardVariant.browse && !member && !pending;
    final showOpen = member || pending || variant == GroupCardVariant.mine;
    final showView = variant == GroupCardVariant.suggested && !member && !pending;

    return Row(
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
        Expanded(
          child: Text(
            formatGroupActivityLabel(group.lastActivityAt),
            style: TextStyle(fontSize: 11, color: theme.textSecondary),
          ),
        ),
        if (showOpen)
          _CompactActionButton(
            label: 'Open',
            filled: false,
            theme: theme,
            onTap: onOpen,
          )
        else if (pending)
          Text(
            'Pending',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.warning,
            ),
          )
        else if (joinable)
          _CompactActionButton(
            label: isJoining ? 'Joining…' : 'Join',
            filled: true,
            theme: theme,
            enabled: !isJoining,
            onTap: onJoin,
          )
        else if (showView)
          _CompactActionButton(
            label: 'View',
            filled: true,
            theme: theme,
            onTap: onOpen,
          ),
      ],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final OneUITheme theme;
  final VoidCallback? onTap;
  final bool enabled;

  const _CompactActionButton({
    required this.label,
    required this.filled,
    required this.theme,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onTap != null;

    return GestureDetector(
      onTap: canTap ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: filled ? theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: filled ? null : Border.all(color: theme.divider),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: filled
                ? theme.buttonPrimaryText
                : (canTap ? theme.textPrimary : theme.textTertiary),
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final String? bannerUrl;
  final Color start;
  final Color end;
  final String? roleLabel;

  const _Cover({
    required this.bannerUrl,
    required this.start,
    required this.end,
    this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    final url = AppData.fullImageUrl(bannerUrl);
    return SizedBox(
      height: 96,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url.isNotEmpty)
            AppCachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          if (roleLabel != null)
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roleLabel == 'Admin'
                      ? Colors.black.withValues(alpha: 0.72)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      roleLabel == 'Admin'
                          ? Icons.shield_outlined
                          : Icons.check_circle_outline_rounded,
                      size: 12,
                      color: roleLabel == 'Admin' ? Colors.white : Colors.grey[800],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      roleLabel!,
                      style: TextStyle(
                        color: roleLabel == 'Admin' ? Colors.white : Colors.grey[900],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? logoUrl;
  final String name;
  final Color start;
  final Color end;

  const _Logo({
    required this.logoUrl,
    required this.name,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final url = AppData.fullImageUrl(logoUrl);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'G';

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.cardBackground, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isNotEmpty
          ? AppCachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [start, end]),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
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
