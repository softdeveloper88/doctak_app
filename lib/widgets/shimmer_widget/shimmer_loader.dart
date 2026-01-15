import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.3) : Colors.grey[300]!;
    final highlightColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.5) : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 100, // Example size
        width: double.infinity,
        decoration: BoxDecoration(color: theme.cardBackground, borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
