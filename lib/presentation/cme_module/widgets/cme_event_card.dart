import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_credit_badge.dart';
import 'package:doctak_app/presentation/cme_module/widgets/cme_status_badge.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CmeEventCard extends StatelessWidget {
  final CmeEventData event;
  final VoidCallback? onTap;

  const CmeEventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: theme.cardDecoration,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / Banner
            if (event.thumbnail != null || event.bannerImage != null)
              _buildBanner(theme),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status + Type row
                  Row(
                    children: [
                      if (event.status != null)
                        CmeStatusBadge(status: event.status!),
                      if (event.status != null && event.type != null)
                        const SizedBox(width: 8),
                      if (event.type != null)
                        _buildTypeChip(theme),
                      const Spacer(),
                      if (event.creditType != null)
                        CmeCreditBadge(
                          creditType: event.creditType!,
                          creditAmount: event.creditAmount,
                          compact: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    event.title ?? '',
                    style: theme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Short description
                  if (event.shortDescription != null)
                    Text(
                      event.shortDescription!,
                      style: theme.bodySecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 10),

                  // Date + Location row
                  _buildInfoRow(theme),

                  // Speakers row
                  if (event.speakers != null && event.speakers!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildSpeakersRow(theme),
                  ],

                  // Capacity bar
                  if (event.maxParticipants != null) ...[
                    const SizedBox(height: 10),
                    _buildCapacityBar(theme),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
          // Live indicator overlay
          if (event.isLive)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, size: 8, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'LIVE NOW',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Format badge
          if (event.format != null)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  event.format!.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        event.type ?? '',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: theme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(OneUITheme theme) {
    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 14, color: theme.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            _formatDateRange(),
            style: theme.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_hasLocation) ...[
          const SizedBox(width: 12),
          Icon(Icons.location_on_outlined, size: 14, color: theme.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _formatLocation(),
              style: theme.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpeakersRow(OneUITheme theme) {
    final speakers = event.speakers!.take(3).toList();
    return Row(
      children: [
        Icon(Icons.people_outline, size: 14, color: theme.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            speakers.map((s) => s.name ?? '').join(', '),
            style: theme.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (event.speakers!.length > 3)
          Text(
            ' +${event.speakers!.length - 3}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildCapacityBar(OneUITheme theme) {
    final current = event.currentParticipants ?? 0;
    final max = event.maxParticipants ?? 1;
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;

    Color barColor;
    if (ratio >= 0.9) {
      barColor = const Color(0xFFFF3B30);
    } else if (ratio >= 0.7) {
      barColor = const Color(0xFFFF9500);
    } else {
      barColor = theme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$current / $max spots filled',
              style: theme.caption,
            ),
            if (event.isFull)
              Text(
                'FULL',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF3B30),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 3,
            backgroundColor: theme.textTertiary.withValues(alpha: 0.15),
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
        if (start.year == end.year && start.month == end.month && start.day == end.day) {
          return dateFormat.format(start);
        }
        return '${DateFormat('MMM d').format(start)} - ${dateFormat.format(end)}';
      }
      return dateFormat.format(start);
    } catch (_) {
      return event.startDate ?? '';
    }
  }

  bool get _hasLocation =>
      event.city != null || event.country != null || event.venue != null;

  String _formatLocation() {
    final parts = <String>[];
    if (event.venue != null) parts.add(event.venue!);
    if (event.city != null) parts.add(event.city!);
    if (event.country != null) parts.add(event.country!);
    return parts.join(', ');
  }
}
