import 'package:doctak_app/presentation/jobs_module/widgets/jobs_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class JobCardShimmer extends StatelessWidget {
  const JobCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    const base = JobsTheme.surfaceContainer;
    const highlight = JobsTheme.surfaceContainerLow;

    Widget bar({double w = double.infinity, double h = 12}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return JobsSurfaceCard(
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(w: 180, h: 15),
                      const SizedBox(height: 8),
                      bar(w: 160, h: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _chip(),
                const SizedBox(width: 6),
                _chip(w: 60),
                const SizedBox(width: 6),
                _chip(w: 70),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                bar(w: 60, h: 11),
                const Spacer(),
                bar(w: 50, h: 11),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({double w = 72}) => Container(
        width: w,
        height: 22,
        decoration: BoxDecoration(
          color: JobsTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
      );
}

class JobCardShimmerList extends StatelessWidget {
  const JobCardShimmerList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: JobsTheme.listPadding(context, top: 8),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) => const JobCardShimmer(),
    );
  }
}
