import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';

/// Shimmer placeholder for the discussion list while loading.
class CaseDiscussionListShimmer extends StatelessWidget {
  const CaseDiscussionListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.surfaceVariant,
      highlightColor: theme.cardBackground,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for the discussion detail screen.
class CaseDiscussionDetailShimmer extends StatelessWidget {
  const CaseDiscussionDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.surfaceVariant,
      highlightColor: theme.cardBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                const CircleAvatar(radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 140, color: Colors.white),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 100, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Title
            Container(height: 20, width: double.infinity, color: Colors.white),
            const SizedBox(height: 10),
            Container(height: 20, width: 200, color: Colors.white),
            const SizedBox(height: 16),
            // Description lines
            for (int i = 0; i < 6; i++) ...[
              Container(
                  height: 12,
                  width: double.infinity,
                  color: Colors.white),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 20),
            // Image placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            // Action row
            Row(
              children: List.generate(
                4,
                (_) => Expanded(
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
