import 'package:doctak_app/ads_setting/ads_widget/native_ads_widget.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/adapters/post_feed_adapter.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_cards.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/blog_comment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// How the list participates in parent scrolling.
enum PostFeedScrollMode {
  /// Inside a parent scroll view (profile) — shrink-wrap, no own scroll.
  nested,

  /// Own scroll view (search) — standalone controller + bounce physics.
  standalone,
}

/// Optional per-screen hooks for legacy [Post] lists rendered as [FeedPostCard].
class PostFeedCardHooks {
  final void Function(Post post)? onDelete;
  final void Function(Post post)? onLikeMutate;
  final void Function(Post post)? onDismiss;
  final void Function(Post post)? onUserBlocked;

  const PostFeedCardHooks({
    this.onDelete,
    this.onLikeMutate,
    this.onDismiss,
    this.onUserBlocked,
  });
}

/// Optimized, shared post list used by profile and search screens.
///
/// Renders every [Post] through [FeedPostCard] via [PostFeedAdapter] so the
/// UI matches the home feed without duplicating card code.
class PostFeedListView extends StatelessWidget {
  final List<Post> posts;
  final HomeBloc homeBloc;
  final PostFeedScrollMode scrollMode;
  final ScrollController? scrollController;
  final bool showPaginationFooter;
  final Widget? header;
  final void Function(int index)? onNearEnd;
  final bool insertAds;
  final PostFeedCardHooks hooks;
  final EdgeInsetsGeometry? padding;
  final bool trimTopCardGap;

  /// Treat every post as owned by the viewer (org owner/admin managing their
  /// business page) so edit/delete actions are available on all cards.
  final bool canModerate;

  const PostFeedListView({
    super.key,
    required this.posts,
    required this.homeBloc,
    this.scrollMode = PostFeedScrollMode.standalone,
    this.scrollController,
    this.showPaginationFooter = false,
    this.header,
    this.onNearEnd,
    this.insertAds = false,
    this.hooks = const PostFeedCardHooks(),
    this.padding,
    this.trimTopCardGap = false,
    this.canModerate = false,
  });

  int get _itemCount {
    var count = posts.length;
    if (header != null) count += 1;
    if (showPaginationFooter) count += 1;
    return count;
  }

  int _postIndex(int listIndex) {
    var index = listIndex;
    if (header != null) index -= 1;
    return index;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey<String>('unified_post_feed_list'),
      controller: scrollMode == PostFeedScrollMode.standalone
          ? scrollController
          : null,
      padding: padding,
      shrinkWrap: scrollMode == PostFeedScrollMode.nested,
      physics: scrollMode == PostFeedScrollMode.nested
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      cacheExtent: 600,
      itemCount: _itemCount,
      itemBuilder: (context, index) {
        if (header != null && index == 0) return header!;

        final adjusted = _postIndex(index);
        if (adjusted >= posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        onNearEnd?.call(adjusted);

        if (insertAds &&
            AppData.isShowGoogleNativeAds &&
            adjusted > 0 &&
            adjusted % 8 == 0) {
          return const NativeAdWidget();
        }

        final post = posts[adjusted];
        final postId = post.id ?? 0;
        final isOwner = canModerate || post.userId == AppData.logInUserId;
        final feedItem = PostFeedAdapter.fromPost(post);
        final options = FeedPostCardOptions(
          treatAsOwner: canModerate,
          onDelete: isOwner && hooks.onDelete != null
              ? () => hooks.onDelete!(post)
              : null,
          onProfileTap: () => ProfileNavigation.openFromPost(context, post),
          homeBloc: homeBloc,
          postIdForComments: postId,
          onLikeMutate: hooks.onLikeMutate == null
              ? null
              : () => hooks.onLikeMutate!(post),
          onDismiss: hooks.onDismiss == null
              ? null
              : () => hooks.onDismiss!(post),
          onUserBlocked: hooks.onUserBlocked == null
              ? null
              : () => hooks.onUserBlocked!(post),
        );

        final card = feedItem.type == 'blog'
            ? FeedBlogCard(
                feedItem,
                onComment: () =>
                    showBlogCommentSheet(context, blogId: feedItem.id),
              )
            : FeedPostCard(
                feedItem,
                options: options,
              );

        return RepaintBoundary(
          child: trimTopCardGap && adjusted == 0
              ? Transform.translate(
                  offset: const Offset(0, -6),
                  child: card,
                )
              : card,
        );
      },
    );
  }
}
