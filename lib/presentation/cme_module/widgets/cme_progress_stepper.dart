import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/presentation/cme_module/utils/cme_progress.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

typedef CmeProgressStepTap = void Function(String stepId);

class CmeProgressStepper extends StatelessWidget {
  const CmeProgressStepper({
    super.key,
    required this.event,
    this.onStepTap,
    this.action,
    this.onAction,
  });

  final CmeEventData event;
  final CmeProgressStepTap? onStepTap;
  final CmeProgressAction? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final steps = buildCmeProgressSteps(event);
    final progress = cmeProgressFraction(event);
    final cta = action ?? resolveCmeProgressAction(event);
    final blocker = cmeProgressBlockerMessage(event);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: theme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your progress', style: theme.titleSmall),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: theme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.divider,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 18),
          _HorizontalStepTrack(
            theme: theme,
            steps: steps,
            onStepTap: onStepTap,
          ),
          if (cta.label.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: cta.kind == CmeProgressActionKind.none ? null : onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: theme.radiusM),
                ),
                child: Text(
                  cta.label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ] else if (blocker != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.warning.withValues(alpha: 0.1),
                borderRadius: theme.radiusM,
                border: Border.all(color: theme.warning.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: theme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      blocker,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        height: 1.35,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HorizontalStepTrack extends StatelessWidget {
  const _HorizontalStepTrack({
    required this.theme,
    required this.steps,
    this.onStepTap,
  });

  final OneUITheme theme;
  final List<CmeProgressStep> steps;
  final CmeProgressStepTap? onStepTap;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _StepCell(
              theme: theme,
              step: steps[i],
              isFirst: i == 0,
              isLast: i == steps.length - 1,
              leftLineDone:
                  i > 0 && steps[i - 1].state == CmeProgressStepState.done,
              rightLineDone: steps[i].state == CmeProgressStepState.done,
              onTap: onStepTap == null ? null : () => onStepTap!(steps[i].id),
            ),
          ),
      ],
    );
  }
}

class _StepCell extends StatelessWidget {
  const _StepCell({
    required this.theme,
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.leftLineDone,
    required this.rightLineDone,
    this.onTap,
  });

  final OneUITheme theme;
  final CmeProgressStep step;
  final bool isFirst;
  final bool isLast;
  final bool leftLineDone;
  final bool rightLineDone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (step.state) {
      CmeProgressStepState.done => theme.success,
      CmeProgressStepState.current => theme.primary,
      CmeProgressStepState.upcoming => theme.textTertiary,
    };

    final icon = switch (step.state) {
      CmeProgressStepState.done => Icons.check_circle_rounded,
      CmeProgressStepState.current => Icons.radio_button_checked,
      CmeProgressStepState.upcoming => Icons.radio_button_off,
    };

    const iconSize = 24.0;
    const trackHeight = 28.0;

    final node = Icon(icon, size: iconSize, color: color);

    return Column(
      children: [
        SizedBox(
          height: trackHeight,
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: isFirst
                      ? const SizedBox.shrink()
                      : _TrackLine(theme: theme, done: leftLineDone),
                ),
              ),
              node,
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: isLast
                      ? const SizedBox.shrink()
                      : _TrackLine(theme: theme, done: rightLineDone),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: theme.radiusS,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              children: [
                Text(
                  step.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: step.state == CmeProgressStepState.current
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: step.state == CmeProgressStepState.upcoming
                        ? theme.textTertiary
                        : theme.textPrimary,
                    height: 1.2,
                  ),
                ),
                if (step.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.detail!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 8,
                      color: theme.textTertiary,
                      height: 1.1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackLine extends StatelessWidget {
  const _TrackLine({required this.theme, required this.done});

  final OneUITheme theme;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2.5,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      color: done ? theme.success : theme.divider,
    );
  }
}
