import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/groups/groups_node_api_service.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_nested_tab_scroll.dart';
import 'package:doctak_app/presentation/groups_module/widgets/group_tab_shimmers.dart';
import 'package:doctak_app/presentation/groups_module/widgets/groups_empty_state.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:flutter/material.dart';

class _VisualMediaItem {
  final String url;
  final String mediaType;
  final String authorName;
  final String? caption;

  const _VisualMediaItem({
    required this.url,
    required this.mediaType,
    required this.authorName,
    this.caption,
  });
}

class GroupMediaTab extends StatefulWidget {
  final String groupId;
  final bool nested;

  const GroupMediaTab({super.key, required this.groupId, this.nested = false});

  @override
  State<GroupMediaTab> createState() => _GroupMediaTabState();
}

class _GroupMediaTabState extends State<GroupMediaTab> {
  final List<_VisualMediaItem> _media = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  List<_VisualMediaItem> _extractMedia(List<GroupFeedPostModel> posts) {
    final out = <_VisualMediaItem>[];
    for (final post in posts) {
      for (final m in post.media) {
        if (!m.isVisual) continue;
        final url = AppData.fullImageUrl(m.url ?? m.mediaPath);
        if (url.isEmpty) continue;
        out.add(_VisualMediaItem(
          url: url,
          mediaType: (m.mediaType ?? 'image').toLowerCase(),
          authorName: post.author?.name ?? 'Member',
          caption: post.caption ?? post.body,
        ));
      }
    }
    return out;
  }

  Future<void> _load({bool refresh = false, bool loadMore = false}) async {
    if (loadMore && (!_hasMore || _loadingMore)) return;
    setState(() {
      if (refresh) _loading = true;
      if (loadMore) _loadingMore = true;
    });

    try {
      final result = await GroupsNodeApiService.getPosts(
        widget.groupId,
        cursor: loadMore ? _cursor : null,
        limit: 30,
      );
      final extracted = _extractMedia(result.items);
      if (!mounted) return;
      setState(() {
        if (refresh) _media.clear();
        _media.addAll(extracted);
        _cursor = result.nextCursor;
        _hasMore = result.nextCursor != null;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    if (_loading) {
      const shimmer = GroupMediaTabShimmer();
      if (widget.nested) {
        return const GroupTabShimmerScroll(shimmer: shimmer);
      }
      return shimmer;
    }
    if (_media.isEmpty) {
      const empty = GroupsEmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No media yet',
        subtitle: 'Photos and videos from group posts will appear here.',
      );
      if (widget.nested) {
        return const GroupNestedTabScroll(
          slivers: [SliverFillRemaining(hasScrollBody: false, child: empty)],
        );
      }
      return empty;
    }

    final grid = widget.nested
        ? GroupNestedTabScroll(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _mediaTile(context, theme, index),
                    childCount: _media.length + (_loadingMore ? 1 : 0),
                  ),
                ),
              ),
            ],
          )
        : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: _media.length + (_loadingMore ? 1 : 0),
            itemBuilder: (context, index) => _mediaTile(context, theme, index),
          );

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 && _hasMore) {
          _load(loadMore: true);
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => _media.clear());
          await _load(refresh: true);
        },
        child: grid,
      ),
    );
  }

  Widget _mediaTile(BuildContext context, OneUITheme theme, int index) {
    if (index >= _media.length) {
      return const GroupMediaTileShimmer();
    }
    final item = _media[index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          item.mediaType == 'video'
              ? Container(
                  color: theme.surfaceVariant,
                  child: Icon(Icons.videocam_rounded, color: theme.textSecondary),
                )
              : AppCachedNetworkImage(imageUrl: item.url, fit: BoxFit.cover),
          if (item.mediaType == 'video')
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}
