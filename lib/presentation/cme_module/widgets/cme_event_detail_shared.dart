import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CmeEventDetailRow extends StatelessWidget {
  const CmeEventDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.textTertiary),
          const SizedBox(width: 12),
          SizedBox(width: 90, child: Text(label, style: theme.caption)),
          Expanded(child: Text(value, style: theme.bodyMedium)),
        ],
      ),
    );
  }
}

class CmeOrganizerRow extends StatelessWidget {
  const CmeOrganizerRow({super.key, required this.organizer});

  final CmeOrganizer organizer;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final pic = organizer.profilePic;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.border.withValues(alpha: 0.4)),
          ),
          clipBehavior: Clip.antiAlias,
          child: pic != null && pic.isNotEmpty
              ? AppCachedNetworkImage(
                  imageUrl: pic,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _fallback(theme),
                )
              : _fallback(theme),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                organizer.name ?? 'CME provider',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              if (organizer.specialty != null)
                Text(organizer.specialty!, style: theme.caption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallback(OneUITheme theme) {
    return Container(
      color: theme.primary.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: Icon(Icons.business_outlined, size: 18, color: theme.primary),
    );
  }
}

class CmeSpeakerTile extends StatelessWidget {
  const CmeSpeakerTile({super.key, required this.speaker, this.compact = false});

  final CmeSpeaker speaker;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 16 : 8),
      padding: compact ? EdgeInsets.zero : const EdgeInsets.all(12),
      decoration: compact ? null : theme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.border.withValues(alpha: 0.4)),
              color: theme.primary.withValues(alpha: 0.1),
            ),
            clipBehavior: Clip.antiAlias,
            child: speaker.profilePic != null && speaker.profilePic!.isNotEmpty
                ? AppCachedNetworkImage(
                    imageUrl: speaker.profilePic!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        Icon(Icons.person, size: 20, color: theme.primary),
                  )
                : Icon(Icons.person, size: 20, color: theme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speaker.name ?? '',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.textPrimary,
                  ),
                ),
                if (speaker.title != null) Text(speaker.title!, style: theme.caption),
                if (speaker.specialty != null)
                  Text(
                    speaker.specialty!,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: theme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String formatCmeEventDateRange(CmeEventData event) {
  try {
    if (event.startDate == null) return '';
    final start = DateTime.parse(event.startDate!);
    final fmt = DateFormat('MMM d, yyyy · h:mm a');
    if (event.endDate != null) {
      final end = DateTime.parse(event.endDate!);
      return '${fmt.format(start)}\n→ ${fmt.format(end)}';
    }
    return fmt.format(start);
  } catch (_) {
    return event.startDate ?? '';
  }
}
