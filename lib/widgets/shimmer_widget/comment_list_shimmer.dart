import 'package:doctak_app/widgets/shimmer_widget/enhanced_comment_shimmer.dart';
import 'package:flutter/material.dart';

class CommentListShimmer extends StatelessWidget {
  const CommentListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnhancedCommentShimmer(itemCount: 6);
  }
}

/// Single comment shimmer row — same layout as the comment bottom sheet.
class CommentShimmer extends StatelessWidget {
  const CommentShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommentSheetShimmerItem();
  }
}
