import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/blog_model/blog_detail_model.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_shell.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Blog/article comments — same UX as [SVCommentScreen] for posts.
class SVBlogCommentScreen extends StatefulWidget {
  final String blogId;

  const SVBlogCommentScreen({required this.blogId, super.key});

  @override
  State<SVBlogCommentScreen> createState() => _SVBlogCommentScreenState();
}

class _SVBlogCommentScreenState extends State<SVBlogCommentScreen> {
  final SharedApiService _api = SharedApiService();
  final TextEditingController _commentCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<BlogComment> _comments = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _posting = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;

  @override
  void initState() {
    super.initState();
    _load(page: 1);
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _page >= _lastPage) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 120) {
      _load(page: _page + 1, append: true);
    }
  }

  Future<void> _load({required int page, bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final res = await _api.getBlogComments(blogId: widget.blogId, page: page);
    if (!mounted) return;

    if (res.success && res.data != null) {
      final node = res.data!['comments'];
      final list = node is Map ? node['data'] : null;
      final lastPage = node is Map ? (node['last_page'] as num?)?.toInt() : 1;

      final parsed = <BlogComment>[];
      if (list is List) {
        for (final c in list) {
          if (c is Map) {
            parsed.add(BlogComment.fromJson(c.cast<String, dynamic>()));
          }
        }
      }

      setState(() {
        if (append) {
          _comments.addAll(parsed);
        } else {
          _comments
            ..clear()
            ..addAll(parsed);
        }
        _page = page;
        _lastPage = lastPage ?? 1;
        _loading = false;
        _loadingMore = false;
      });
    } else {
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (!append) _error = res.message ?? 'Failed to load comments';
      });
    }
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    final res = await _api.addBlogComment(blogId: widget.blogId, body: text);
    if (!mounted) return;
    if (res.success) {
      _commentCtrl.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      await _load(page: 1);
    } else {
      toast(res.message ?? 'Failed to post comment');
    }
    if (mounted) setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.appBarBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Comments', style: theme.titleMedium),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(theme)),
          _buildInput(theme),
        ],
      ),
    );
  }

  Widget _buildBody(OneUITheme theme) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: theme.primary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: theme.bodyMedium),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => _load(page: 1),
                style: FilledButton.styleFrom(backgroundColor: theme.primary),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_comments.isEmpty) {
      return Center(
        child: Text(
          'No comments yet. Be the first to comment.',
          style: theme.bodySecondary,
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _comments.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _comments.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.primary,
                ),
              ),
            ),
          );
        }
        return _commentTile(theme, _comments[index]);
      },
    );
  }

  Widget _commentTile(OneUITheme theme, BlogComment c) {
    final avatar = AppData.fullImageUrl(c.authorAvatar);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.avatarBackground,
            backgroundImage:
                avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
            child: avatar.isEmpty
                ? Text(feedAvatarInitial(c.authorName),
                    style: TextStyle(color: theme.avatarText, fontSize: 13))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.authorName,
                          style: theme.bodySecondary.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                      if (c.createdAt != null)
                        Text(feedRelativeTime(c.createdAt),
                            style: theme.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(c.body, style: theme.bodyMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(OneUITheme theme) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset > 0 ? bottomInset + 8 : 16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        border: Border(top: BorderSide(color: theme.divider, width: 0.5)),
      ),
      child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                style: theme.bodyMedium,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add a comment…',
                  hintStyle: theme.bodySecondary,
                  filled: true,
                  fillColor: theme.surfaceVariant,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _posting ? null : _postComment,
              icon: _posting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primary,
                      ),
                    )
                  : Icon(Icons.send_rounded, color: theme.primary),
            ),
          ],
        ),
    );
  }
}
