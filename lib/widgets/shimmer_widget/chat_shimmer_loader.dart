import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatShimmerLoader extends StatelessWidget {
  const ChatShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final baseColor = isDark ? theme.surfaceVariant.withOpacity(0.3) : Colors.grey[300]!;
    final highlightColor = isDark ? theme.surfaceVariant.withOpacity(0.5) : Colors.grey[100]!;
    final avatarColor = isDark ? theme.surfaceVariant : Colors.grey[300]!;
    
    return ListView.builder(
      itemCount: 20, // Number of placeholders
      itemBuilder: (context, index) {
        // Alternate between sent and received messages
        bool isSent = index % 2 == 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            mainAxisAlignment: isSent
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isSent) ...[
                CircleAvatar(radius: 16, backgroundColor: avatarColor),
                const SizedBox(width: 8),
              ],
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  height: 30,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (isSent) const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}
