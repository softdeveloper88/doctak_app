import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loader that exactly matches MemoryOptimizedConferenceItem structure
class ConferencesShimmerLoader extends StatelessWidget {
  const ConferencesShimmerLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? theme.surfaceVariant.withOpacity(0.3)
        : Colors.grey[300]!;
    final highlightColor = isDark
        ? theme.surfaceVariant.withOpacity(0.5)
        : Colors.grey[100]!;
    final shimmerColor = isDark
        ? theme.surfaceVariant.withOpacity(0.4)
        : Colors.grey[200]!;

    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        final bool hasImage = index % 2 == 0;
        final bool hasLongTitle = index % 3 == 0;
        final bool hasDescription = index % 4 != 0;
        final bool hasRegistration = index % 5 != 0;

        return Container(
          margin: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConferenceImageOrPlaceholder(hasImage, shimmerColor),
                  _buildConferenceHeader(
                    context,
                    hasLongTitle,
                    shimmerColor,
                    theme,
                  ),
                  if (hasDescription)
                    _buildConferenceDescription(context, shimmerColor, theme),
                  _buildConferenceDetails(context, index, shimmerColor, theme),
                  _buildActionRow(
                    context,
                    hasRegistration,
                    shimmerColor,
                    theme,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConferenceImageOrPlaceholder(bool hasImage, Color shimmerColor) {
    if (hasImage) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(color: shimmerColor),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: shimmerColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    } else {
      return Container(
        height: 100,
        width: double.infinity,
        color: shimmerColor,
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: shimmerColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildConferenceHeader(
    BuildContext context,
    bool hasLongTitle,
    Color shimmerColor,
    OneUITheme theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: hasLongTitle
                      ? double.infinity
                      : MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: shimmerColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConferenceDescription(
    BuildContext context,
    Color shimmerColor,
    OneUITheme theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 12,
            width: 80,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 14,
            width: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 14,
            width: MediaQuery.of(context).size.width * 0.6,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConferenceDetails(
    BuildContext context,
    int index,
    Color shimmerColor,
    OneUITheme theme,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.divider.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          _buildDetailRow(shimmerColor, 100),
          const SizedBox(height: 8),
          _buildDetailRow(shimmerColor, 120),
          const SizedBox(height: 8),
          _buildDetailRow(shimmerColor, 80),
        ],
      ),
    );
  }

  Widget _buildDetailRow(Color shimmerColor, double textWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: shimmerColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 14,
            width: textWidth,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    bool hasRegistration,
    Color shimmerColor,
    OneUITheme theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.divider.withOpacity(0.5), width: 1),
        ),
      ),
      child: hasRegistration
          ? Container(
              height: 44,
              width: double.infinity,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(22),
              ),
            )
          : Center(
              child: Container(
                height: 14,
                width: 140,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
    );
  }
}
