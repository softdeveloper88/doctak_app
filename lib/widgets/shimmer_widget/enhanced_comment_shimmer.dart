import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_sheet_widgets.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer placeholder matching [CommentSheetBubble] + action row layout.
class CommentSheetShimmerItem extends StatelessWidget {
  final int index;

  const CommentSheetShimmerItem({super.key, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;

    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : CommentSheetTokens.bubbleBackground;
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white;
    final boneColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : CommentSheetTokens.threadLine;

    final bubbleBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : CommentSheetTokens.bubbleBackground;

    final hasLongBody = index % 3 == 0;
    final showSpecialty = index % 2 == 0;
    final showViewReplies = index == 1;

    BoxDecoration bone({double radius = 4}) => BoxDecoration(
          color: boneColor,
          borderRadius: BorderRadius.circular(radius),
        );

    Widget boneBox({double? width, required double height, double radius = 4}) {
      return Container(
        width: width,
        height: height,
        decoration: bone(radius: radius),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CommentSheetTokens.horizontalPadding,
        10,
        CommentSheetTokens.horizontalPadding,
        0,
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: CommentSheetTokens.avatarMain,
              height: CommentSheetTokens.avatarMain,
              decoration: const BoxDecoration(
                color: CommentSheetTokens.threadLine,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: isDark
                        ? BoxDecoration(
                            color: bubbleBg,
                            borderRadius: BorderRadius.circular(
                              CommentSheetTokens.bubbleRadius,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          )
                        : CommentSheetTokens.bubbleDecoration(isDark: false)
                            .copyWith(color: bubbleBg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            boneBox(width: showSpecialty ? 72 : 96, height: 12),
                            if (showSpecialty) ...[
                              const Spacer(),
                              boneBox(width: 56, height: 10),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        boneBox(width: double.infinity, height: 12),
                        if (hasLongBody) ...[
                          const SizedBox(height: 5),
                          boneBox(
                            width: MediaQuery.sizeOf(context).width * 0.46,
                            height: 12,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 2, top: 6),
                    child: Row(
                      children: [
                        boneBox(width: 28, height: 10),
                        const SizedBox(width: 12),
                        boneBox(width: 14, height: 14, radius: 7),
                        const SizedBox(width: 4),
                        boneBox(width: 12, height: 10),
                        const SizedBox(width: 12),
                        boneBox(width: 14, height: 14, radius: 7),
                        const SizedBox(width: 4),
                        boneBox(width: 32, height: 10),
                        const Spacer(),
                        boneBox(width: 18, height: 18, radius: 9),
                      ],
                    ),
                  ),
                  if (showViewReplies)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 1,
                            color: CommentSheetTokens.threadLine,
                          ),
                          const SizedBox(width: 10),
                          boneBox(width: 108, height: 11, radius: 5),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header shimmer while comments are loading in the bottom sheet.
class CommentSheetHeaderShimmer extends StatelessWidget {
  const CommentSheetHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final isDark = theme.isDark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : CommentSheetTokens.bubbleBackground;
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white;
    final boneColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : CommentSheetTokens.threadLine;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CommentSheetTokens.horizontalPadding,
        4,
        CommentSheetTokens.horizontalPadding,
        0,
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 96,
                  height: 16,
                  decoration: BoxDecoration(
                    color: boneColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: CommentSheetTokens.threadLine,
                    shape: BoxShape.circle,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: CommentSheetTokens.threadLine,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(
              height: 1,
              thickness: 1,
              color: CommentSheetTokens.threadLine,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pre-loader for the comment bottom sheet — mirrors real comment list UX.
class EnhancedCommentShimmer extends StatelessWidget {
  final int itemCount;

  const EnhancedCommentShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) => CommentSheetShimmerItem(index: index),
    );
  }
}
