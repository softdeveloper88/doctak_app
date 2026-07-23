import 'package:doctak_app/presentation/jobs_module/widgets/job_display_utils.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_filter_sheet.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Removable filter chips shown below the jobs hub tabs on Browse.
class JobsActiveFiltersRow extends StatelessWidget {
  const JobsActiveFiltersRow({
    super.key,
    required this.filters,
    required this.onChanged,
    required this.onClearAll,
  });

  final JobsFilterState filters;
  final ValueChanged<JobsFilterState> onChanged;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (filters.activeCount == 0) return const SizedBox.shrink();

    final theme = OneUITheme.of(context);
    final chips = <Widget>[];

    void removeSpecialty(String value) {
      final next = filters.copy();
      next.specialties = next.specialties.where((s) => s != value).toList();
      onChanged(next);
    }

    void removeLocation(String value) {
      final next = filters.copy();
      next.locations = next.locations.where((l) => l != value).toList();
      onChanged(next);
    }

    void removeJobType(String value) {
      final next = filters.copy();
      next.jobTypes = next.jobTypes.where((t) => t != value).toList();
      onChanged(next);
    }

    void removeApplyType(String value) {
      final next = filters.copy();
      next.applyTypes = next.applyTypes.where((t) => t != value).toList();
      onChanged(next);
    }

    for (final s in filters.specialties) {
      chips.add(_FilterChip(
        label: s,
        onRemove: () => removeSpecialty(s),
      ));
    }
    for (final l in filters.locations) {
      chips.add(_FilterChip(label: l, onRemove: () => removeLocation(l)));
    }
    for (final t in filters.jobTypes) {
      chips.add(_FilterChip(
        label: JobDisplayUtils.jobTypeLabel(t),
        onRemove: () => removeJobType(t),
      ));
    }
    for (final t in filters.applyTypes) {
      chips.add(_FilterChip(label: t, onRemove: () => removeApplyType(t)));
    }
    if (filters.postedWithin != 'all') {
      chips.add(_FilterChip(
        label: _postedWithinLabel(filters.postedWithin),
        onRemove: () {
          final next = filters.copy();
          next.postedWithin = 'all';
          onChanged(next);
        },
      ));
    }
    if (filters.locationQ.trim().isNotEmpty) {
      chips.add(_FilterChip(
        label: filters.locationQ.trim(),
        onRemove: () {
          final next = filters.copy();
          next.locationQ = '';
          onChanged(next);
        },
      ));
    }

    return ColoredBox(
      color: theme.cardBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: chips,
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Clear',
                style: theme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _postedWithinLabel(String value) {
    switch (value) {
      case '24h':
        return 'Last 24 hours';
      case '7d':
        return 'Last 7 days';
      case '30d':
        return 'Last 30 days';
      default:
        return value;
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return InputChip(
      label: Text(
        label,
        style: theme.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.primary,
        ),
      ),
      onDeleted: onRemove,
      deleteIconColor: theme.primary,
      backgroundColor: theme.accentSoft,
      side: BorderSide(color: theme.primary.withValues(alpha: 0.22)),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
