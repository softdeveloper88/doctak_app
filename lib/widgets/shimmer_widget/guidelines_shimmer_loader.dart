import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader that exactly matches MemoryOptimizedGuidelineItem structure
class GuidelinesShimmerLoader extends StatelessWidget {
  const GuidelinesShimmerLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        final bool hasLongName = index % 2 == 0;
        final bool isExpanded =
            index % 3 == 0; // Some cards show expanded state

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.textPrimary.withOpacity(0.05),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Shimmer.fromColors(
              baseColor: isDark
                  ? theme.surfaceVariant
                  : theme.surfaceVariant.withOpacity(0.8),
              highlightColor: isDark
                  ? theme.cardBackground
                  : theme.cardBackground.withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guideline Header
                  _buildGuidelineHeader(
                    context,
                    hasLongName,
                    isExpanded,
                    theme,
                  ),

                  // Guideline Action
                  _buildGuidelineAction(context, isExpanded, theme),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Guideline header section matching MemoryOptimizedGuidelineItem
  Widget _buildGuidelineHeader(
    BuildContext context,
    bool hasLongName,
    bool isExpanded,
    OneUITheme theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardBackground),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical information icon (50x50 with primary background)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary.withOpacity(0.2),
                  theme.primary.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: theme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Disease name and description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Disease name
                Container(
                  width: hasLongName
                      ? double.infinity
                      : MediaQuery.of(context).size.width * 0.6,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),

                // Description (HtmlWidget content)
                _buildDescription(context, isExpanded, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Description section with collapsed/expanded states
  Widget _buildDescription(
    BuildContext context,
    bool isExpanded,
    OneUITheme theme,
  ) {
    if (isExpanded) {
      // Expanded description (more lines)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 14,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 14,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
    } else {
      // Collapsed description (trimmed to ~100 words)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: 14,
            decoration: BoxDecoration(
              color: theme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      );
    }
  }

  // Guideline action section matching MemoryOptimizedGuidelineItem
  Widget _buildGuidelineAction(
    BuildContext context,
    bool isExpanded,
    OneUITheme theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: theme.surfaceVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // TextButton.icon - matching the action button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary.withOpacity(0.15),
                  theme.primary.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon placeholder
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                // Text placeholder - different widths for "See More" vs "Download PDF"
                Container(
                  width: isExpanded ? 80 : 60, // "Download PDF" vs "See More"
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
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
