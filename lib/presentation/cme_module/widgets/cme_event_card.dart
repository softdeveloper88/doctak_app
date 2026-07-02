import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/data/models/cme/cme_segment_utils.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_status_badge.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CmeEventCard extends StatelessWidget {
  const CmeEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.showProviderMeta = false,
  });

  final CmeEventData event;
  final VoidCallback? onTap;
  final bool showProviderMeta;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final hasCover = (event.thumbnail != null && event.thumbnail!.isNotEmpty) ||
        (event.bannerImage != null && event.bannerImage!.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: theme.cardDecoration,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasCover) _buildBanner(theme) else _buildPlaceholderHeader(theme),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -22),
                      child: _buildProviderAvatar(theme),
                    ),
                    const SizedBox(height: 2),
                    _buildMetaLine(theme),
                    const SizedBox(height: 8),
                    Text(
                      event.title ?? 'Untitled activity',
                      style: theme.titleMedium.copyWith(height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.shortDescription != null &&
                        event.shortDescription!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        event.shortDescription!,
                        style: theme.bodySecondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    _buildProviderLine(theme),
                    if (event.speakers != null && event.speakers!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildFacultyStack(theme),
                    ],
                    if (event.maxParticipants != null) ...[
                      const SizedBox(height: 12),
                      _buildCapacityBar(theme),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderHeader(OneUITheme theme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primary.withValues(alpha: 0.85),
                theme.primary.withValues(alpha: 0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                bottom: -16,
                child: Icon(
                  _typeIcon(),
                  size: 72,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: _buildCoverBadges(theme),
              ),
              if (event.isLive)
                Positioned(
                  top: 10,
                  right: 10,
                  child: _livePill(),
                ),
              Positioned(
                right: 12,
                bottom: 12,
                child: _buildCreditPill(theme),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _typeIcon() {
    switch ((event.type ?? '').toLowerCase()) {
      case 'recorded':
      case 'on_demand':
        return Icons.play_circle_outline;
      case 'hybrid':
        return Icons.hub_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  Widget _buildBanner(OneUITheme theme) {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppCachedNetworkImage(
            imageUrl: event.bannerImage ?? event.thumbnail ?? '',
            fit: BoxFit.cover,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          Positioned(top: 10, left: 10, child: _buildCoverBadges(theme)),
          if (event.isLive)
            Positioned(top: 10, right: 10, child: _livePill()),
          Positioned(
            right: 12,
            bottom: 12,
            child: _buildCreditPill(theme, onDark: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverBadges(OneUITheme theme) {
    final badgeStatus = cmeCardCoverBadgeStatus(event);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (badgeStatus != null)
          CmeStatusBadge(status: badgeStatus, onDark: true),
        if (event.type != null) _buildTypeChip(theme, onDark: true),
      ],
    );
  }

  Widget _buildCreditPill(OneUITheme theme, {bool onDark = false}) {
    final amount = event.creditAmount?.toString() ?? '0';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.black.withValues(alpha: 0.55)
            : theme.cardBackground.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amount,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: onDark ? Colors.white : theme.textPrimary,
            ),
          ),
          Text(
            'CME credit${(double.tryParse(amount) ?? 0) > 1 ? 's' : ''}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              color: onDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderAvatar(OneUITheme theme) {
    final name = event.organizer?.name ?? 'CME provider';
    final logo = event.organizer?.profilePic;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'C';

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.cardBackground, width: 3),
        color: theme.primary,
      ),
      clipBehavior: Clip.antiAlias,
      child: logo != null && logo.isNotEmpty
          ? AppCachedNetworkImage(
              imageUrl: logo,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _avatarInitial(initial, theme),
            )
          : _avatarInitial(initial, theme),
    );
  }

  Widget _avatarInitial(String initial, OneUITheme theme) {
    return Container(
      color: theme.primary,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMetaLine(OneUITheme theme) {
    final date = _formatDateRange();
    final location = _formatLocation();
    final parts = <String>[];
    if (date.isNotEmpty) parts.add(date);
    if (location.isNotEmpty) parts.add(location);
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' · '),
      style: theme.caption,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProviderLine(OneUITheme theme) {
    final provider = event.organizer?.name ?? 'CME provider';
    final accred = event.accreditationBody ?? 'ACCME';
    final count = event.currentParticipants ?? 0;
    return Text(
      '$accred · $provider · $count registered',
      style: theme.caption,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFacultyStack(OneUITheme theme) {
    final speakers = event.speakers!.take(4).toList();
    final total = event.speakers!.length;
    return Row(
      children: [
        SizedBox(
          height: 28,
          width: (speakers.length * 20.0) + 8,
          child: Stack(
            children: [
              for (var i = 0; i < speakers.length; i++)
                Positioned(
                  left: i * 20.0,
                  child: _facultyAvatar(speakers[i], theme),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            total > speakers.length
                ? '+${total - speakers.length} faculty'
                : '$total faculty',
            style: theme.caption,
          ),
        ),
      ],
    );
  }

  Widget _facultyAvatar(CmeSpeaker speaker, OneUITheme theme) {
    final pic = speaker.profilePic;
    final initial = (speaker.name ?? '?').trim().isNotEmpty
        ? speaker.name!.trim()[0].toUpperCase()
        : '?';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.cardBackground, width: 2),
        color: theme.primary.withValues(alpha: 0.12),
      ),
      clipBehavior: Clip.antiAlias,
      child: pic != null && pic.isNotEmpty
          ? AppCachedNetworkImage(
              imageUrl: pic,
              width: 28,
              height: 28,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Center(
                child: Text(initial, style: theme.caption),
              ),
            )
          : Center(child: Text(initial, style: theme.caption)),
    );
  }

  Widget _livePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, size: 8, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(OneUITheme theme, {bool onDark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.black.withValues(alpha: 0.55)
            : theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        (event.type ?? '').replaceAll('_', ' '),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: onDark ? Colors.white : theme.primary,
        ),
      ),
    );
  }

  Widget _buildCapacityBar(OneUITheme theme) {
    final current = event.currentParticipants ?? 0;
    final max = event.maxParticipants ?? 1;
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    final barColor = ratio >= 0.9
        ? theme.error
        : ratio >= 0.7
            ? theme.warning
            : theme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$current / $max spots filled', style: theme.caption),
            if (event.isFull)
              Text(
                'FULL',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: theme.textTertiary.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }

  String _formatDateRange() {
    try {
      if (event.startDate == null) return '';
      final start = DateTime.parse(event.startDate!);
      final dateFormat = DateFormat('MMM d, yyyy');
      if (event.endDate != null) {
        final end = DateTime.parse(event.endDate!);
        if (start.year == end.year &&
            start.month == end.month &&
            start.day == end.day) {
          return dateFormat.format(start);
        }
        return '${DateFormat('MMM d').format(start)} – ${dateFormat.format(end)}';
      }
      return dateFormat.format(start);
    } catch (_) {
      return event.startDate ?? '';
    }
  }

  String _formatLocation() {
    if (event.location != null && event.location!.trim().isNotEmpty) {
      return event.location!.trim();
    }
    final parts = <String>[];
    if (event.venue != null && event.venue!.trim().isNotEmpty) {
      parts.add(event.venue!.trim());
    }
    if (event.city != null && event.city!.trim().isNotEmpty) {
      parts.add(event.city!.trim());
    }
    if (event.country != null && event.country!.trim().isNotEmpty) {
      parts.add(event.country!.trim());
    }
    return parts.join(', ');
  }
}
