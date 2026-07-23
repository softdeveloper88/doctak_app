import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Pipeline progress — matches website `VerticalTimelineStepper` / stage dots.
class JobApplicationStageStepper extends StatelessWidget {
  const JobApplicationStageStepper({
    super.key,
    required this.stage,
    this.compact = false,
  });

  final String stage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return compact
        ? _CompactStageDots(stage: stage)
        : _VerticalStageTimeline(stage: stage);
  }
}

class _CompactStageDots extends StatelessWidget {
  const _CompactStageDots({required this.stage});

  final String stage;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final stages = JobStageLabels.pipeline;
    final isRejected = stage == 'rejected';
    final currentIdx = isRejected ? -1 : stages.indexOf(stage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < stages.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: (!isRejected && currentIdx >= 0 && i <= currentIdx)
                        ? theme.primary
                        : theme.border,
                  ),
                ),
              _Dot(
                filled: !isRejected && currentIdx >= 0 && i <= currentIdx,
                current: !isRejected && i == currentIdx,
                error: false,
                primary: theme.primary,
                border: theme.border,
                danger: JobsTheme.danger,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (isRejected)
          Text(
            'Application rejected',
            style: JobsTheme.caption.copyWith(
              color: JobsTheme.danger,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Row(
            children: [
              for (var i = 0; i < stages.length; i++)
                Expanded(
                  child: Text(
                    JobStageLabels.shortLabel(stages[i]),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: JobsTheme.caption.copyWith(
                      fontSize: 9,
                      fontWeight: i == currentIdx
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: i == currentIdx
                          ? theme.primary
                          : theme.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _VerticalStageTimeline extends StatelessWidget {
  const _VerticalStageTimeline({required this.stage});

  final String stage;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final stages = JobStageLabels.order;
    final currentIdx = JobStageLabels.indexOf(stage);
    final isRejected = stage == 'rejected';

    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          _TimelineRow(
            label: JobStageLabels.label(stages[i]),
            isLast: i == stages.length - 1,
            completed: !isRejected && i < currentIdx,
            current: i == currentIdx,
            rejected: isRejected && i == currentIdx,
            pending: i > currentIdx ||
                (isRejected && i > JobStageLabels.indexOf('rejected')),
            primary: theme.primary,
            border: theme.border,
            textPrimary: theme.textPrimary,
            textMuted: theme.textSecondary,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.isLast,
    required this.completed,
    required this.current,
    required this.rejected,
    required this.pending,
    required this.primary,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
  });

  final String label;
  final bool isLast;
  final bool completed;
  final bool current;
  final bool rejected;
  final bool pending;
  final Color primary;
  final Color border;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    final circleColor = rejected
        ? JobsTheme.danger
        : completed
            ? primary
            : Colors.transparent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: rejected || completed
                        ? null
                        : Border.all(
                            color: current ? primary : border,
                            width: 2,
                          ),
                    boxShadow: current && !rejected
                        ? [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.22),
                              blurRadius: 0,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: completed
                      ? const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white)
                      : rejected
                          ? const Icon(Icons.close_rounded,
                              size: 12, color: Colors.white)
                          : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: completed ? primary : border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Opacity(
                opacity: pending ? 0.45 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: JobsTheme.body.copyWith(
                        fontWeight: current || completed
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: rejected
                            ? JobsTheme.danger
                            : current
                                ? primary
                                : textPrimary,
                      ),
                    ),
                    if (current)
                      Text(
                        rejected ? 'Not moving forward' : 'Current stage',
                        style: JobsTheme.caption.copyWith(
                          color: rejected ? JobsTheme.danger : textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.filled,
    required this.current,
    required this.error,
    required this.primary,
    required this.border,
    required this.danger,
  });

  final bool filled;
  final bool current;
  final bool error;
  final Color primary;
  final Color border;
  final Color danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: current ? 10 : 8,
      height: current ? 10 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: error
            ? danger
            : filled
                ? primary
                : border,
        boxShadow: current && !error
            ? [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
    );
  }
}
