import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

class JobChip extends StatelessWidget {
  const JobChip({
    super.key,
    required this.label,
    this.tone = JobChipTone.neutral,
    this.dense = true,
    this.outlined = false,
  });

  final String label;
  final JobChipTone tone;
  final bool dense;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final colors = _colors(theme);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: outlined ? theme.cardBackground : colors.$1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: outlined ? theme.border : colors.$1,
        ),
      ),
      child: Text(
        label,
        style: JobsTheme.label.copyWith(
          color: outlined ? theme.textSecondary : colors.$2,
          fontWeight: FontWeight.w600,
          fontSize: dense ? 11 : 12,
        ),
      ),
    );
  }

  (Color, Color) _colors(OneUITheme theme) {
    switch (tone) {
      case JobChipTone.primary:
        return (theme.accentSoft, theme.primary);
      case JobChipTone.success:
        return (theme.accentSoft, theme.primary);
      case JobChipTone.warning:
        return (JobsTheme.warningSoft, JobsTheme.warning);
      case JobChipTone.danger:
        return (JobsTheme.dangerSoft, JobsTheme.danger);
      case JobChipTone.neutral:
        return (theme.surfaceVariant, theme.textSecondary);
    }
  }
}

enum JobChipTone { neutral, primary, success, warning, danger }

class PromotedBadge extends StatelessWidget {
  const PromotedBadge({super.key, this.tier});

  final String? tier;

  @override
  Widget build(BuildContext context) {
    final label = (tier == 'premium')
        ? 'Premium'
        : (tier == 'standard')
            ? 'Promoted'
            : 'Featured';
    return JobChip(label: label, tone: JobChipTone.warning);
  }
}

JobChipTone jobStageChipTone(String stage) {
  switch (stage) {
    case 'interview':
    case 'offer':
    case 'accepted':
    case 'shortlisted':
      return JobChipTone.success;
    case 'reviewed':
      return JobChipTone.warning;
    case 'rejected':
      return JobChipTone.danger;
    default:
      return JobChipTone.primary;
  }
}
