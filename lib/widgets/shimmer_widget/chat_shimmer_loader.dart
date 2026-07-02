import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatShimmerLoader extends StatelessWidget {
  const ChatShimmerLoader({super.key});

  static const List<double> _widthFactors = [0.52, 0.38, 0.64, 0.44, 0.58, 0.36];
  static const List<double> _heights = [40.0, 28.0, 52.0, 32.0, 44.0, 36.0];

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final baseColor =
        isDark ? theme.surfaceVariant.withValues(alpha: 0.35) : const Color(0xFFE8ECF1);
    final highlightColor =
        isDark ? theme.surfaceVariant.withValues(alpha: 0.55) : const Color(0xFFF5F7FA);
    final avatarColor =
        isDark ? theme.surfaceVariant.withValues(alpha: 0.45) : const Color(0xFFDDE3EA);

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: 8,
      itemBuilder: (context, index) {
        final isMe = index.isEven;
        final bubbleWidth = screenWidth * _widthFactors[index % _widthFactors.length];
        final bubbleHeight = _heights[index % _heights.length];

        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: CircleAvatar(radius: 14, backgroundColor: avatarColor),
                ),
                const SizedBox(width: 8),
              ],
              Shimmer.fromColors(
                baseColor: baseColor,
                highlightColor: highlightColor,
                child: Container(
                  height: bubbleHeight,
                  width: bubbleWidth,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: isMe
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(4),
                          )
                        : const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(18),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
