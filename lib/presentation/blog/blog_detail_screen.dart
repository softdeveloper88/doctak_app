import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/likes_list_screen.dart';
import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/blog_model/blog_detail_model.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/blog_comment_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_shell.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/reaction_picker.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';

/// Native article reader for a doctak-node blog (`GET /api/blogs/{id}`),
/// with website-parity reactions, comments sheet, repost and share.
class BlogDetailScreen extends StatefulWidget {
  final String blogId;
  const BlogDetailScreen({super.key, required this.blogId});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final SharedApiService _api = SharedApiService();
  final ScrollController _scrollCtrl = ScrollController();

  bool _loading = true;
  String? _error;
  BlogDetailModel? _blog;
  String _authorSubtitle = 'Doctor';

  String? _reaction;
  int _likeCount = 0;
  int _commentCount = 0;
  bool _reposted = false;
  bool _reposting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _api.getBlogDetail(blogId: widget.blogId),
      _api.getBlogReaction(blogId: widget.blogId),
      _api.getBlogRepost(blogId: widget.blogId),
      _api.getBlogComments(blogId: widget.blogId, perPage: 1),
    ]);
    if (!mounted) return;

    final detailRes = results[0];
    final reactionRes = results[1];
    final repostRes = results[2];
    final commentsRes = results[3];

    if (detailRes.success && detailRes.data != null) {
      _blog = BlogDetailModel.fromJson(detailRes.data!);
      final specialty = await displaySpecialtyAsync(_blog?.authorSpecialty);
      _authorSubtitle = specialty.isNotEmpty ? specialty : 'Doctor';
    } else {
      _error = detailRes.message ?? 'Failed to load article';
    }

    if (reactionRes.success && reactionRes.data != null) {
      final d = reactionRes.data!;
      _reaction = (d['currentReaction'] as String?);
      _likeCount = (d['likes'] as num?)?.toInt() ?? 0;
    }

    if (repostRes.success && repostRes.data != null) {
      _reposted = repostRes.data!['reposted'] == true;
    }

    final commentsNode = commentsRes.data?['comments'];
    if (commentsNode is Map) {
      _commentCount = (commentsNode['total'] as num?)?.toInt() ?? 0;
    }

    setState(() => _loading = false);
  }

  Future<void> _onReact(String? type) async {
    final previous = _reaction;
    setState(() {
      _reaction = type;
      final has = type != null;
      final had = previous != null;
      if (has && !had) _likeCount += 1;
      if (!has && had) _likeCount -= 1;
      if (_likeCount < 0) _likeCount = 0;
    });
    final toSend = type ?? previous ?? 'like';
    final res = await _api.reactToBlog(blogId: widget.blogId, reaction: toSend);
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
    final res = await _api.repostBlog(blogId: widget.blogId);
    if (!mounted) return;
    setState(() {
      _reposting = false;
      final reposted = res.data?['reposted'];
      if (reposted is bool) _reposted = reposted;
    });
    if (res.success) toast(_reposted ? 'Reposted' : 'Repost removed');
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text: DeepLinkService.generateBlogLink(widget.blogId),
        title: _blog?.title ?? 'DocTak Article',
      ),
    );
    _api.recordFeedInteraction(
      contentType: 'blog',
      contentId: widget.blogId,
      type: 'share',
    );
  }

  void _openComments() {
    showBlogCommentSheet(context, blogId: widget.blogId);
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
            onPressed: _blog == null ? null : _share,
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
    final blog = _blog!;
    final coverUrl = AppData.fullImageUrl(blog.coverImage);

    return ListView(
      controller: _scrollCtrl,
      padding: EdgeInsets.zero,
      children: [
        if (coverUrl.isNotEmpty)
          AppCachedNetworkImage(
            imageUrl: coverUrl,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => _coverFallback(theme),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (blog.title != null)
                Text(blog.title!, style: theme.titleLarge),
              if (blog.excerpt != null && blog.excerpt!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  blog.excerpt!,
                  style: theme.bodySecondary.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FeedAuthorHeader(
                name: blog.authorName,
                avatarUrl: AppData.fullImageUrl(blog.authorAvatar),
                subtitle: _authorSubtitle,
                verified: blog.authorVerified,
                createdAt: blog.createdAt,
              ),
              if (_likeCount > 0) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => openReactionsForBlog(
                    context,
                    blogId: widget.blogId,
                    title: blog.title,
                    totalCount: _likeCount,
                  ),
                  child: Text(
                    '$_likeCount ${_likeCount == 1 ? 'reaction' : 'reactions'}',
                    style: theme.caption.copyWith(color: theme.primary),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (blog.content != null)
                HtmlWidget(
                  blog.content!,
                  textStyle:
                      theme.bodyMedium.copyWith(fontSize: 15, height: 1.6),
                )
              else if (blog.excerpt != null)
                Text(blog.excerpt!, style: theme.bodyMedium),
              const SizedBox(height: 8),
              Divider(color: theme.divider),
              _buildActions(theme),
              Divider(color: theme.divider),
              const SizedBox(height: 8),
              _buildCommentsEntry(theme),
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

  Widget _buildActions(OneUITheme theme) {
    return FeedActionRow(actions: [
      Expanded(
        child: Center(
          child: ReactionButton(
            currentReaction: _reaction,
            onChanged: _onReact,
          ),
        ),
      ),
      FeedActionButton(
        icon: Icons.mode_comment_outlined,
        onTap: _openComments,
      ),
      FeedActionButton(
        icon: Icons.repeat,
        active: _reposted,
        onTap: _toggleRepost,
      ),
      FeedActionButton(
        icon: Icons.share_outlined,
        onTap: _share,
      ),
    ]);
  }

  Widget _buildCommentsEntry(OneUITheme theme) {
    final label = _commentCount == 0
        ? 'Add a comment'
        : '$_commentCount ${_commentCount == 1 ? 'comment' : 'comments'}';
    return InkWell(
      onTap: _openComments,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: theme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 20, color: theme.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: theme.bodyMedium),
            ),
            Icon(Icons.chevron_right, color: theme.textTertiary),
          ],
        ),
      ),
    );
  }
}
