import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/reactions_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Truncated title shown under "Reactions" in the list header.
String reactionContentTitle({
  String? title,
  String? body,
  int maxLen = 72,
}) {
  final raw = (body?.trim().isNotEmpty == true ? body! : (title ?? '')).trim();
  if (raw.isEmpty) return '';
  if (raw.length <= maxLen) return raw;
  return '${raw.substring(0, maxLen - 3)}...';
}

/// Title for feed/blog/case cards (same rules as web home feed).
String reactionContentTitleFromFeedItem(FeedItem item) {
  final payload = item.payload;
  switch (item.type) {
    case 'blog':
      return reactionContentTitle(title: (payload['title'] ?? '').toString());
    case 'case':
      return reactionContentTitle(
        title: (payload['title'] ?? payload['caseTitle'] ?? '').toString(),
      );
    default:
      return reactionContentTitle(
        title: (payload['title'] ?? '').toString(),
        body: (payload['body'] ?? '').toString(),
      );
  }
}

int reactionCountFromPost(Post post) => post.likes?.length ?? 0;

void openReactionsList(
  BuildContext context, {
  required String contentId,
  String contentType = 'post',
  String? contentTitle,
  int totalCount = 0,
}) {
  ReactionsListScreen(
    contentId: contentId,
    contentType: contentType,
    contentTitle: contentTitle,
    totalCount: totalCount,
  ).launch(context);
}

void openReactionsForPost(BuildContext context, Post post) {
  openReactionsList(
    context,
    contentId: '${post.id ?? 0}',
    contentType: 'post',
    contentTitle: reactionContentTitle(title: post.title),
    totalCount: reactionCountFromPost(post),
  );
}

void openReactionsForFeedItem(
  BuildContext context,
  FeedItem item, {
  String? contentType,
  int? totalCount,
}) {
  openReactionsList(
    context,
    contentId: item.id,
    contentType: contentType ?? item.type,
    contentTitle: reactionContentTitleFromFeedItem(item),
    totalCount: totalCount ?? item.engagement.likes,
  );
}

void openReactionsForBlog(
  BuildContext context, {
  required String blogId,
  required String? title,
  required int totalCount,
}) {
  openReactionsList(
    context,
    contentId: blogId,
    contentType: 'blog',
    contentTitle: reactionContentTitle(title: title),
    totalCount: totalCount,
  );
}
