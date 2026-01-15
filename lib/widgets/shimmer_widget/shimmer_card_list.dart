import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerCardList extends StatelessWidget {
  const ShimmerCardList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.3) : Colors.grey[300]!;
    final highlightColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.5) : Colors.grey[100]!;

    return ListView.builder(
      itemCount: 6, // Number of shimmer cards to show
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Card(
              color: theme.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: isDark ? 0 : 2,
              child: Container(
                height: 120,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shimmer for image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(8)),
                    ),
                    const SizedBox(width: 16),
                    // Shimmer for text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 16,
                            width: MediaQuery.of(context).size.width * 0.5,
                            decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 16,
                            width: MediaQuery.of(context).size.width * 0.3,
                            decoration: BoxDecoration(color: baseColor, borderRadius: BorderRadius.circular(4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
