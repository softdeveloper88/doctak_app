import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/case_discussion/models/case_discussion_models.dart';
import 'package:doctak_app/presentation/case_discussion/repository/case_discussion_repository.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_shell.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Case discussion comments — same bottom-sheet UX as post/blog comments.
class SVCaseCommentScreen extends StatefulWidget {
  final int caseId;

  const SVCaseCommentScreen({required this.caseId, super.key});

  @override
  State<SVCaseCommentScreen> createState() => _SVCaseCommentScreenState();
}

class _SVCaseCommentScreenState extends State<SVCaseCommentScreen> {
  late final CaseDiscussionRepository _repo = CaseDiscussionRepository(
    baseUrl: AppData.base2,
    getAuthToken: () => AppData.userToken ?? '',
  );

  final TextEditingController _commentCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<CaseComment> _comments = [];
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

    try {
      final res = await _repo.getCaseComments(
        caseId: widget.caseId,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        if (append) {
          _comments.addAll(res.items);
        } else {
          _comments
            ..clear()
            ..addAll(res.items);
        }
        _page = page;
        _lastPage = res.pagination.lastPage;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        if (!append) _error = e.toString();
      });
    }
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await _repo.addComment(caseId: widget.caseId, comment: text);
      if (!mounted) return;
      _commentCtrl.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      await _load(page: 1);
    } catch (e) {
      if (mounted) toast('Failed to post comment');
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

  Widget _commentTile(OneUITheme theme, CaseComment c) {
    final avatar = c.author.profilePic ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.avatarBackground,
            backgroundImage: avatar.isNotEmpty
                ? CachedNetworkImageProvider(avatar)
                : null,
            child: avatar.isEmpty
                ? Text(feedAvatarInitial(c.author.name),
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
                          c.author.name,
                          style: theme.bodySecondary.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                      Text(feedRelativeTime(c.createdAt.toIso8601String()),
                          style: theme.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(c.comment, style: theme.bodyMedium),
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
