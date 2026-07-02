import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_shell.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_comment_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_icons.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/reaction_picker.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/reactions_navigation.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nb_utils/nb_utils.dart';

/// Full-screen article reader for posts with `post_type` blog/article (incl. group articles).
class PostArticleDetailScreen extends StatefulWidget {
  final int postId;

  const PostArticleDetailScreen({super.key, required this.postId});

  @override
  State<PostArticleDetailScreen> createState() => _PostArticleDetailScreenState();
}

class _PostArticleDetailScreenState extends State<PostArticleDetailScreen> {
  final SharedApiService _api = SharedApiService();

  bool _loading = true;
  String? _error;
  Post? _post;
  String _authorSubtitle = 'Doctor';

  String? _reaction;
  int _likeCount = 0;
  int _commentCount = 0;
  int _repostCount = 0;
  bool _reposted = false;
  bool _reposting = false;
  List<dynamic> _topReactions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final postId = '${widget.postId}';
    final detailRes = await _api.getPostV1(postId: postId);
    final reactionRes = await _api.getPostReactionSummary(postId: postId);
    if (!mounted) return;

    Post? loaded;
    if (detailRes.success && detailRes.data?['post'] != null) {
      try {
        loaded = Post.fromJson(detailRes.data!['post']);
      } catch (_) {
        loaded = null;
      }
    }

    if (loaded == null) {
      final legacyRes = await _api.getPostDetailsWithLikes(postId: postId);
      if (!mounted) return;
      if (legacyRes.success && legacyRes.data?.post != null) {
        loaded = legacyRes.data!.post;
      } else {
        _error = detailRes.message ??
            legacyRes.message ??
            'Failed to load article';
      }
    }

    if (loaded != null) {
      _post = loaded;
      final specialty = await displaySpecialtyAsync(_post?.user?.specialty);
      _authorSubtitle = specialty.isNotEmpty ? specialty : 'Doctor';
      _commentCount = _post?.comments?.length ?? 0;
    }

    if (reactionRes.success && reactionRes.data != null) {
      _applyReactionSummary(reactionRes.data!);
    } else {
      _likeCount = _post?.likes?.length ?? 0;
    }

    setState(() => _loading = false);
  }

  String? get _title {
    final post = _post;
    if (post == null) return null;
    final t = post.displayTitle?.trim().isNotEmpty == true
        ? post.displayTitle!.trim()
        : post.title?.trim();
    return (t != null && t.isNotEmpty) ? t : 'Article';
  }

  String? get _excerpt {
    final post = _post;
    if (post == null) return null;
    final excerpt = post.displayBody?.trim();
    if (excerpt != null && excerpt.isNotEmpty) return _stripHtml(excerpt);
    final body = post.body?.trim();
    if (body == null || body.isEmpty) return null;
    final plain = _stripHtml(body);
    if (plain == null) return null;
    if (plain.length <= 180) return plain;
    return '${plain.substring(0, 177)}...';
  }

  String? get _bodyHtml => _post?.body?.trim();

  String? get _coverUrl {
    final post = _post;
    if (post == null) return null;
    final media = post.media;
    if (media != null && media.isNotEmpty) {
      final path = media.first.mediaPath?.trim();
      if (path != null && path.isNotEmpty) {
        return AppData.fullImageUrl(path);
      }
    }
    final image = post.image?.toString().trim();
    if (image != null && image.isNotEmpty) {
      return AppData.fullImageUrl(image);
    }
    return null;
  }

  void _applyReactionSummary(Map<String, dynamic> d) {
    _reaction = d['viewerReaction'] as String?;
    if (d['viewerReposted'] is bool) {
      _reposted = d['viewerReposted'] as bool;
    }
    final reactions = d['reactions'];
    if (reactions is List) {
      _topReactions = List<dynamic>.from(reactions);
      var total = 0;
      for (final entry in reactions) {
        if (entry is Map) {
          total += (entry['count'] as num?)?.toInt() ?? 0;
        }
      }
      if (total > 0) _likeCount = total;
    } else {
      _likeCount = _post?.likes?.length ?? 0;
    }
    final reposts = d['reposts'];
    if (reposts is num) _repostCount = reposts.toInt();
  }

  FeedItem _engagementFeedItem(Post post) {
    return FeedItem(
      type: 'post',
      id: '${widget.postId}',
      createdAt: post.createdAt ?? '',
      engagement: FeedEngagement(
        likes: _likeCount,
        comments: _commentCount,
        shares: _repostCount,
        views: post.views ?? 0,
      ),
      payload: {'topReactions': _topReactions},
    );
  }

  String? _stripHtml(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (!s.contains('<')) return s;
    return s
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _onReact(String? type) async {
    final previous = _reaction;
    final prevLike = _likeCount;
    final has = type != null;
    final had = previous != null;
    var nextLike = prevLike;
    if (has && !had) nextLike += 1;
    if (!has && had) nextLike -= 1;
    if (nextLike < 0) nextLike = 0;

    updateFeedTopReactionsCache(
      contentType: 'post',
      itemId: '${widget.postId}',
      previousType: previous,
      newType: type,
      likeCount: nextLike,
    );

    setState(() {
      _reaction = type;
      _likeCount = nextLike;
    });

    final toSend = type ?? previous ?? 'like';
    final res = await _api.reactToPost(
      postId: '${widget.postId}',
      reaction: toSend,
    );
    if (!mounted) return;
    if (res.success && res.data != null) {
      setState(() {
        _reaction = res.data!['currentReaction'] as String?;
        _likeCount = (res.data!['likes'] as num?)?.toInt() ?? _likeCount;
      });
    }
  }

  Future<void> _toggleRepost() async {
    if (_reposting) return;
    setState(() {
      _reposting = true;
      _reposted = !_reposted;
    });
    final res = await _api.repostPost(postId: '${widget.postId}');
    if (!mounted) return;
    setState(() {
      _reposting = false;
      final reposted = res.data?['reposted'];
      if (reposted is bool) _reposted = reposted;
      final reposts = res.data?['reposts'];
      if (reposts is num) _repostCount = reposts.toInt();
    });
    if (res.success) toast(_reposted ? 'Reposted' : 'Repost removed');
  }

  void _share() {
    DeepLinkService.sharePost(
      postId: widget.postId,
      title: _title,
      description: _excerpt,
    );
    _api.recordShare(postId: '${widget.postId}');
  }

  Future<void> _openComments() async {
    final count = await showFeedCommentSheet(
      context,
      postId: widget.postId,
    );
    if (!mounted) return;
    if (count != null) setState(() => _commentCount = count);
  }

  void _openAuthor() {
    final userId = _post?.userId ?? _post?.user?.id;
    if (userId != null && userId.isNotEmpty) {
      ProfileNavigation.open(context, userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: DoctakAppBar(
        title: 'Article',
        titleIcon: Icons.article_outlined,
        toolbarHeight: 56,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: theme.iconColor),
            onPressed: _post == null ? null : _share,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.primary))
          : _error != null
              ? _buildError(theme)
              : _buildContent(theme),
    );
  }

  Widget _buildError(OneUITheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.error),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: theme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _load();
              },
              style: FilledButton.styleFrom(backgroundColor: theme.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OneUITheme theme) {
    final post = _post!;
    final coverUrl = _coverUrl;
    final authorName = post.authorName ?? post.user?.name ?? 'Member';
    final authorAvatar = AppData.fullImageUrl(
      post.authorAvatar ?? post.user?.profilePic,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (coverUrl != null && coverUrl.isNotEmpty)
          AppCachedNetworkImage(
            imageUrl: coverUrl,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _coverFallback(theme),
          )
        else
          _coverFallback(theme),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_title != null)
                Text(_title!, style: theme.titleLarge),
              if (_excerpt != null && _excerpt!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _excerpt!,
                  style: theme.bodySecondary.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FeedAuthorHeader(
                name: authorName,
                avatarUrl: authorAvatar,
                subtitle: _authorSubtitle,
                verified: post.authorVerified == true || post.user?.isVerified == true,
                createdAt: post.createdAt,
                onTap: _openAuthor,
              ),
              const SizedBox(height: 16),
              if (_bodyHtml != null && _bodyHtml!.isNotEmpty)
                HtmlWidget(
                  _bodyHtml!,
                  textStyle: theme.bodyMedium.copyWith(fontSize: 15, height: 1.6),
                ),
              _buildEngagementStats(theme, post),
              _buildActions(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coverFallback(OneUITheme theme) {
    return Container(
      height: 220,
      width: double.infinity,
      color: theme.surfaceVariant,
      child: Icon(Icons.article_outlined, size: 48, color: theme.textTertiary),
    );
  }

  Widget _buildEngagementStats(OneUITheme theme, Post post) {
    final item = _engagementFeedItem(post);
    final likes = _likeCount;
    final comments = _commentCount;
    final reposts = _repostCount;
    final views = post.views ?? 0;
    final topReactions = resolveFeedTopReactions(
      item: item,
      contentType: 'post',
      likeCount: likes,
      showFaces: true,
    );

    if (likes == 0 && comments == 0 && reposts == 0 && views == 0) {
      return const SizedBox.shrink();
    }

    final right = <String>[
      if (views > 0) '${feedCompactNumber(views)} views',
      if (comments > 0)
        '${feedCompactNumber(comments)} ${comments == 1 ? 'comment' : 'comments'}',
      if (reposts > 0)
        '${feedCompactNumber(reposts)} ${reposts == 1 ? 'repost' : 'reposts'}',
    ].join(' · ');

    final reactionsLabel = likes > 0
        ? '${feedCompactNumber(likes)} ${likes == 1 ? 'reaction' : 'reactions'}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          if (likes > 0)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => openReactionsForPost(context, post),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (topReactions.isNotEmpty) ...[
                    ReactionFacesStack(reactions: topReactions),
                    const SizedBox(width: 6),
                  ],
                  Text(reactionsLabel, style: theme.caption),
                ],
              ),
            ),
          Expanded(
            child: Text(
              right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: theme.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(OneUITheme theme) {
    return FeedActionRow(actions: [
      FeedReactionAction(
        currentReaction: _reaction,
        onChanged: _onReact,
      ),
      FeedActionButton(
        svgAsset: FeedIconAssets.comment,
        label: 'Comment',
        onTap: _openComments,
      ),
      FeedActionButton(
        svgAsset: FeedIconAssets.repost,
        label: _reposted ? 'Reposted' : 'Repost',
        active: _reposted,
        onTap: _toggleRepost,
      ),
      FeedActionButton(
        svgAsset: FeedIconAssets.send,
        label: 'Send',
        onTap: _share,
      ),
    ]);
  }
}
