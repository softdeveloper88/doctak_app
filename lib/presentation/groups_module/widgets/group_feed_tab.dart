import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/groups_module/utils/group_feed_mapper.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_nested_tab_scroll.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_tab_shimmers.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/compose_content_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_entry_view.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/home_compose_card.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

class GroupFeedTab extends StatelessWidget {
  final GroupDetailModel group;
  final List<GroupFeedEntryModel> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final VoidCallback onPosted;
  final bool nested;

  const GroupFeedTab({
    super.key,
    required this.group,
    required this.items,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onPosted,
    this.nested = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final feedItems = GroupFeedMapper.mapEntries(items, group);
    final canPost = group.capabilities.canPost;

    if (loading && items.isEmpty) {
      return _loadingBody(context);
    }

    final scrollView = nested
        ? GroupNestedTabScroll(
            slivers: _buildSlivers(
              context,
              theme,
              feedItems,
              canPost,
            ),
          )
        : ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: _buildListChildren(feedItems, canPost, theme),
          );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 && hasMore) {
            onLoadMore();
          }
          return false;
        },
        child: scrollView,
      ),
    );
  }

  Widget _loadingBody(BuildContext context) {
    final shimmer = GroupFeedTabShimmer(showCompose: group.capabilities.canPost);
    if (nested) {
      return GroupTabShimmerScroll(shimmer: shimmer);
    }
    return shimmer;
  }

  List<Widget> _buildSlivers(
    BuildContext context,
    OneUITheme theme,
    List<FeedItem> feedItems,
    bool canPost,
  ) {
    return [
      if (canPost)
        SliverToBoxAdapter(
          child: HomeComposeCard(
            groupTarget: ComposeGroupTarget.fromDetail(group),
            onComposed: onPosted,
          ),
        ),
      if (feedItems.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              'No posts yet in this group.',
              style: TextStyle(color: theme.textSecondary),
            ),
          ),
        )
      else ...[
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = feedItems[index];
              return RepaintBoundary(
                key: ValueKey('group-feed-${item.type}-${item.id}'),
                child: FeedEntryView(
                  FeedEntry.itemEntry(item),
                  onFeedChanged: onPosted,
                ),
              );
            },
            childCount: feedItems.length,
          ),
        ),
        if (loadingMore)
          const SliverToBoxAdapter(
            child: GroupFeedTabShimmer(showCompose: false, itemCount: 1),
          ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ];
  }

  List<Widget> _buildListChildren(
    List<FeedItem> feedItems,
    bool canPost,
    OneUITheme theme,
  ) {
    return [
      if (canPost)
        HomeComposeCard(
          groupTarget: ComposeGroupTarget.fromDetail(group),
          onComposed: onPosted,
        ),
      if (feedItems.isEmpty) ...[
        const SizedBox(height: 80),
        Center(
          child: Text(
            'No posts yet in this group.',
            style: TextStyle(color: theme.textSecondary),
          ),
        ),
      ] else ...[
        ...feedItems.map((item) {
          return RepaintBoundary(
            key: ValueKey('group-feed-${item.type}-${item.id}'),
            child: FeedEntryView(
              FeedEntry.itemEntry(item),
              onFeedChanged: onPosted,
            ),
          );
        }),
        if (loadingMore)
          const GroupFeedTabShimmer(showCompose: false, itemCount: 1),
      ],
    ];
  }
}
