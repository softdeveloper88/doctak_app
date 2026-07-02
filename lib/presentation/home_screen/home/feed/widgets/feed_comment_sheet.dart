import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/comment_content_type.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/comment_screen/sv_comment_screen.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Shared comment bottom sheet used across feed, profile, and search.
/// Returns the final comment count when the sheet closes.
Future<int?> showFeedCommentSheet(
  BuildContext context, {
  required int postId,
  HomeBloc? homeBloc,
  ValueChanged<int>? onCommentCountChanged,
}) {
  return _showCommentBottomSheet(
    context,
    child: SVCommentScreen(
      id: postId,
      homeBloc: homeBloc,
      isBottomSheet: true,
      onCommentCountChanged: onCommentCountChanged,
    ),
  );
}

Future<int?> showCommentBottomSheetForContent(
  BuildContext context, {
  required CommentContentType contentType,
  int? id,
  String? contentId,
  HomeBloc? homeBloc,
  ValueChanged<int>? onCommentCountChanged,
}) {
  return _showCommentBottomSheet(
    context,
    child: SVCommentScreen(
      id: id,
      contentId: contentId,
      contentType: contentType,
      homeBloc: homeBloc,
      isBottomSheet: true,
      onCommentCountChanged: onCommentCountChanged,
    ),
  );
}

Future<int?> _showCommentBottomSheet(
  BuildContext context, {
  required Widget child,
}) {
  final theme = OneUITheme.of(context);

  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final keyboardInset = MediaQuery.viewInsetsOf(ctx).bottom;
      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(top: false, child: child),
          ),
        ),
      );
    },
  );
}
