import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class PostShimmerLoader extends StatelessWidget {
  final int itemCount;

  const PostShimmerLoader({
    super.key,
    this.itemCount = 3, // Default item count is 3
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.3) : Colors.grey[300]!;
    final highlightColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.5) : Colors.grey[100]!;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Padding(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(radius: 20, backgroundColor: baseColor),
                  title: _ShimmerBox(height: 10, color: baseColor),
                  subtitle: _ShimmerBox(height: 10, color: baseColor),
                ),
                const SizedBox(height: 8.0),
                _ShimmerBox(height: 300, color: baseColor),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final Color color;

  const _ShimmerBox({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.0)),
    );
  }
}
