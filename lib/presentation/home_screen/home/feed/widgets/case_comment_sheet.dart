import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_comment_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_content_type.dart';
import 'package:flutter/material.dart';

void showCaseCommentSheet(
  BuildContext context, {
  required int caseId,
}) {
  showCommentBottomSheetForContent(
    context,
    contentId: caseId.toString(),
    contentType: CommentContentType.caseDiscussion,
  );
}
