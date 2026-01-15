import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../theme/one_ui_theme.dart';

/// Shimmer loader for specialty dropdown loading in create discussion screen
class SpecialtyLoadingShimmer extends StatelessWidget {
  const SpecialtyLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.divider,
      highlightColor: theme.cardBackground,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Loading icon
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: theme.divider, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            // Loading text
            Expanded(child: Container(height: 14, color: theme.divider)),
            const SizedBox(width: 12),
            // Spinner placeholder
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: theme.divider, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}
