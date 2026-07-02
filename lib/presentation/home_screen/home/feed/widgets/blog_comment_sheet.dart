import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_comment_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_content_type.dart';
import 'package:flutter/material.dart';

/// Shared comment bottom sheet for blog/article cards and detail screen.
void showBlogCommentSheet(
  BuildContext context, {
  required String blogId,
}) {
  showCommentBottomSheetForContent(
    context,
    contentType: CommentContentType.blog,
    contentId: blogId,
  );
}
