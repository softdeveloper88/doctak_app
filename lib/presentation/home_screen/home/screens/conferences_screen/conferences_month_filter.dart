import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

class ConferencesMonthFilter extends StatelessWidget {
  const ConferencesMonthFilter({
    super.key,
    required this.monthBuckets,
    required this.selectedMonth,
    required this.showing,
    required this.total,
    required this.onChanged,
  });

  final List<ConferenceMonthBucket> monthBuckets;
  final String selectedMonth;
  final int showing;
  final int total;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MonthChip(
                  label: 'All',
                  selected: selectedMonth.isEmpty,
                  theme: theme,
                  onTap: () => onChanged(''),
                ),
                ...monthBuckets.map(
                  (bucket) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _MonthChip(
                      label: bucket.label,
                      selected: selectedMonth == (bucket.key ?? ''),
                      theme: theme,
                      onTap: () => onChanged(bucket.key ?? ''),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Showing $showing of $total upcoming',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final OneUITheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.primary : theme.cardBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? theme.primary : theme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : theme.textPrimary,
          ),
        ),
      ),
    );
  }
}
