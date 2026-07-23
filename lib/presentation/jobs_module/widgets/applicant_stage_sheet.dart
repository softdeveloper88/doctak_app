import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/job_application_stage_stepper.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_sheet_shell.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Professional pipeline stage picker for recruiters.
Future<String?> showApplicantStageSheet({
  required BuildContext context,
  required JobApplicantDto applicant,
  List<String> stages = JobStageLabels.order,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ApplicantStageSheet(
      applicant: applicant,
      stages: stages,
    ),
  );
}

IconData jobStageIcon(String stage) {
  switch (stage) {
    case 'new':
      return Icons.inbox_outlined;
    case 'reviewed':
      return Icons.visibility_outlined;
    case 'shortlisted':
      return Icons.star_outline_rounded;
    case 'interview':
      return Icons.event_outlined;
    case 'offer':
      return Icons.local_offer_outlined;
    case 'accepted':
      return Icons.check_circle_outline_rounded;
    case 'rejected':
      return Icons.cancel_outlined;
    default:
      return Icons.flag_outlined;
  }
}

String? jobNextPipelineStage(String current) {
  final pipeline = JobStageLabels.pipeline;
  final i = pipeline.indexOf(current);
  if (i < 0 || i >= pipeline.length - 1) return null;
  return pipeline[i + 1];
}

class _ApplicantStageSheet extends StatelessWidget {
  const _ApplicantStageSheet({
    required this.applicant,
    required this.stages,
  });

  final JobApplicantDto applicant;
  final List<String> stages;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final next = jobNextPipelineStage(applicant.stage);

    return JobsSheetShell(
      title: 'Move ${applicant.name}',
      subtitle: 'Update pipeline stage',
      leading: JobsSheetLeadingIcon(
        icon: Icons.swap_horiz_rounded,
        color: theme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          JobApplicationStageStepper(stage: applicant.stage, compact: true),
          if (next != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, next),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text('Advance to ${JobStageLabels.label(next)}'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Or pick any stage below',
              textAlign: TextAlign.center,
              style: theme.caption.copyWith(color: theme.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          for (final stage in stages)
            _StageOptionTile(
              stage: stage,
              selected: applicant.stage == stage,
              isNext: stage == next,
              onTap: () => Navigator.pop(context, stage),
            ),
        ],
      ),
    );
  }
}

class _StageOptionTile extends StatelessWidget {
  const _StageOptionTile({
    required this.stage,
    required this.selected,
    required this.isNext,
    required this.onTap,
  });

  final String stage;
  final bool selected;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isReject = stage == 'rejected';
    final accent = isReject
        ? JobsTheme.danger
        : selected
            ? theme.primary
            : theme.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? theme.primary.withValues(alpha: 0.08)
            : theme.scaffoldBackground,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? theme.primary.withValues(alpha: 0.35)
                    : theme.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(jobStageIcon(stage), size: 18, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        JobStageLabels.label(stage),
                        style: theme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      if (selected)
                        Text(
                          'Current stage',
                          style: theme.caption.copyWith(
                            color: theme.textSecondary,
                          ),
                        )
                      else if (isNext)
                        Text(
                          'Recommended next',
                          style: theme.caption.copyWith(
                            color: theme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: theme.primary, size: 22)
                else if (isNext)
                  Icon(Icons.arrow_forward_rounded, color: theme.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
