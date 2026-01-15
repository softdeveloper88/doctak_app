import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Ultra-detailed shimmer loader for comments that precisely mirrors the comment card layout
class EnhancedCommentShimmer extends StatelessWidget {
  const EnhancedCommentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.3) : Colors.grey[300]!;
    final highlightColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.5) : Colors.grey[100]!;
    final shimmerColor = isDark ? theme.surfaceVariant.withValues(alpha: 0.4) : Colors.grey[400]!;

    return ListView.builder(
      itemCount: 6, // Number of shimmer cards to show
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        // Create variations for each card to make it look more realistic
        final bool hasLongName = index % 2 == 0;
        final bool hasLongComment = index % 3 == 0;
        final bool hasReplies = index % 2 == 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 0, offset: const Offset(0, 2))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User and comment header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),

                        // Comment content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User info row
                              Row(
                                children: [
                                  // Username
                                  Container(
                                    width: hasLongName ? 120 : 90,
                                    height: 16,
                                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                                  ),
                                  const SizedBox(width: 8),
                                  // Verification badge
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
                                  ),
                                  const Spacer(),
                                  // Menu icon (only on some items)
                                  if (index % 3 == 0)
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Comment text lines with varying width
                              Container(
                                width: double.infinity,
                                height: 14,
                                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: hasLongComment ? MediaQuery.of(context).size.width * 0.7 : MediaQuery.of(context).size.width * 0.5,
                                height: 14,
                                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                              ),
                              if (hasLongComment) ...[
                                const SizedBox(height: 6),
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  height: 14,
                                  decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                                ),
                              ],

                              const SizedBox(height: 8),

                              // Timestamp
                              Container(
                                width: 80,
                                height: 12,
                                decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                              ),

                              const SizedBox(height: 12),

                              // Action buttons
                              Row(
                                children: [
                                  // Reply button
                                  Container(
                                    width: 70,
                                    height: 24,
                                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12)),
                                  ),
                                  const SizedBox(width: 16),

                                  // Like button
                                  Container(
                                    width: 60,
                                    height: 24,
                                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Reply section (only for some items)
                    if (hasReplies) ...[
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.only(left: 30),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Reply avatar
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(color: shimmerColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),

                            // Reply content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Reply username
                                  Container(
                                    width: 80,
                                    height: 14,
                                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                                  ),

                                  const SizedBox(height: 6),

                                  // Reply text
                                  Container(
                                    width: double.infinity,
                                    height: 12,
                                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.4,
                                    height: 12,
                                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
