import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CommentListShimmer extends StatelessWidget {
  const CommentListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return  ListView.builder(
        itemCount: 20, // Number of shimmer placeholders
        itemBuilder: (context, index) {
          return const CommentShimmer();
        },
      
    );
  }
}

class CommentShimmer extends StatelessWidget {
  const CommentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final baseColor = isDark ? theme.surfaceVariant.withOpacity(0.3) : Colors.grey[300]!;
    final highlightColor = isDark ? theme.surfaceVariant.withOpacity(0.5) : Colors.grey[100]!;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular shimmer for profile image
          Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: baseColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          // Shimmer for text area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    width: double.infinity,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 12.0,
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
