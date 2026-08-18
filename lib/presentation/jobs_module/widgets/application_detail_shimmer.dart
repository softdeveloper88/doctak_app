import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton for `MyApplicationDetailScreen` — mirrors its summary card,
/// pipeline-progress stepper, and "Open submitted CV" row so the loading
/// state doesn't jump around once real content lands.
class ApplicationDetailShimmer extends StatelessWidget {
  const ApplicationDetailShimmer({super.key});

  static const int _stageCount = 7;

  @override
  Widget build(BuildContext context) {
    const base = JobsTheme.surfaceContainer;
    const highlight = JobsTheme.surfaceContainerLow;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          JobsSurfaceCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chip(w: 64),
                const SizedBox(height: 12),
                _bar(w: 200, h: 16),
                const SizedBox(height: 8),
                _bar(w: 140, h: 14),
                const SizedBox(height: 8),
                _bar(w: 150, h: 12),
                const SizedBox(height: 8),
                _chip(w: 96),
              ],
            ),
          ),
          const SizedBox(height: 12),
          JobsSurfaceCard(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(w: 130, h: 11),
                const SizedBox(height: 14),
                for (var i = 0; i < _stageCount; i++)
                  _timelineRow(isLast: i == _stageCount - 1, current: i == 0),
              ],
            ),
          ),
          const SizedBox(height: 12),
          JobsSurfaceCard(
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _bar(h: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar({double w = double.infinity, double h = 12}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: JobsTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(6),
        ),
      );

  Widget _chip({double w = 72}) => Container(
        width: w,
        height: 22,
        decoration: BoxDecoration(
          color: JobsTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
      );

  Widget _timelineRow({required bool isLast, required bool current}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: JobsTheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 20, height: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: JobsTheme.surfaceContainer,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(w: current ? 90 : 70, h: 13),
                  if (current) ...[
                    const SizedBox(height: 6),
                    _bar(w: 80, h: 11),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
