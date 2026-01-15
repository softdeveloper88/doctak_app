import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader that exactly matches MemoryOptimizedDrugItem structure
class DrugsShimmerLoader extends StatelessWidget {
  const DrugsShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.3) : Colors.grey[300]!;
    final highlightColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.5) : Colors.grey[100]!;
    final shimmerColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.4) : Colors.grey[300]!;

    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        final bool hasLongName = index % 2 == 0;
        final bool hasLongManufacturer = index % 2 == 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 0, offset: const Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDrugHeader(context, hasLongName, shimmerColor, theme),
                  _buildDrugInfo(context, hasLongManufacturer, shimmerColor, theme),
                  _buildActionRow(context, shimmerColor, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrugHeader(BuildContext context, bool hasLongName, Color shimmerColor, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardBackground),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: shimmerColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: hasLongName ? double.infinity : MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.4,
                  decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        width: 40,
                        height: 12,
                        decoration: BoxDecoration(color: shimmerColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        width: 30,
                        height: 12,
                        decoration: BoxDecoration(color: shimmerColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrugInfo(BuildContext context, bool hasLongManufacturer, Color shimmerColor, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withValues(alpha: 0.3),
        border: Border(top: BorderSide(color: theme.divider.withValues(alpha: 0.5), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 90,
                        decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: 14,
                        width: hasLongManufacturer ? 120 : 80,
                        decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 30,
              height: 14,
              decoration: BoxDecoration(color: shimmerColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, Color shimmerColor, OneUITheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.divider.withValues(alpha: 0.5), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ),
    );
  }
}
