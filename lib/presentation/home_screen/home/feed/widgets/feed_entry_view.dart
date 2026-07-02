import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_cards.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/case_comment_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/blog_comment_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_comment_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_strip.dart';
import 'package:flutter/material.dart';

/// Renders a single [FeedEntry] — either an inline typed card or a strip rail.
class FeedEntryView extends StatelessWidget {
  final FeedEntry entry;
  final VoidCallback? onFeedChanged;
  final HomeBloc? homeBloc;

  const FeedEntryView(
    this.entry, {
    super.key,
    this.onFeedChanged,
    this.homeBloc,
  });

  @override
  Widget build(BuildContext context) {
    if (entry.kind == FeedEntryKind.strip) {
      return FeedStrip(stripType: entry.stripType, items: entry.items);
    }
    final item = entry.item;
    if (item == null) return const SizedBox.shrink();
    return _cardForItem(context, item);
  }

  Widget _cardForItem(BuildContext context, FeedItem item) {
    switch (item.type) {
      case 'post':
        final postId = int.tryParse(item.id);
        return FeedPostCard(
          item,
          options: FeedPostCardOptions(
            onProfileTap: () => ProfileNavigation.openFromFeedItem(context, item),
            onFeedChanged: onFeedChanged,
            postIdForComments: postId,
            homeBloc: homeBloc,
          ),
        );
      case 'blog':
        return FeedBlogCard(
          item,
          onFeedChanged: onFeedChanged,
          onComment: () => showBlogCommentSheet(context, blogId: item.id),
        );
      case 'case':
        final caseId = int.tryParse(item.id);
        return FeedCaseCard(
          item,
          onComment: caseId != null
              ? () => showCaseCommentSheet(context, caseId: caseId)
              : null,
        );
      case 'job':
        return FeedJobCard(item);
      case 'cme':
        return FeedCmeCard(item);
      case 'survey':
        return FeedSurveyCard(item);
      case 'group_post':
        return FeedPostCard(
          item,
          options: FeedPostCardOptions(
            onProfileTap: () => ProfileNavigation.openFromFeedItem(context, item),
            onFeedChanged: onFeedChanged,
            postIdForComments: int.tryParse(
              item.str('postId') ?? item.id,
            ),
            homeBloc: homeBloc,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
