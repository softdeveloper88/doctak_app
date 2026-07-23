import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/post_model/post_reactions_model.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/reaction_picker.dart';
import 'package:doctak_app/presentation/home_screen/utils/shimmer_widget.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/widgets/doctak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

const List<String> _reactionTabOrder = [
  'like',
  'love',
  'care',
  'haha',
  'wow',
  'sad',
  'angry',
  'insightful',
];

/// Reactions list matching the web/mobile reference: filter tabs, user rows
/// with avatar badge, specialty · location, and follow button.
class ReactionsListScreen extends StatefulWidget {
  final String contentId;
  final String contentType;
  final String? contentTitle;
  final int totalCount;

  const ReactionsListScreen({
    super.key,
    required this.contentId,
    this.contentType = 'post',
    this.contentTitle,
    this.totalCount = 0,
  });

  @override
  State<ReactionsListScreen> createState() => _ReactionsListScreenState();
}

class _ReactionsListScreenState extends State<ReactionsListScreen> {
  final SharedApiService _api = SharedApiService();
  final ScrollController _scrollCtrl = ScrollController();

  String _filter = 'all';
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  Map<String, int> _reactionCounts = {};
  List<PostReactionUser> _users = [];
  List<FeedReaction> _topReactions = const [];

  @override
  void initState() {
    super.initState();
    preloadSpecialties().then((_) {
      if (mounted) setState(() {});
    });
    _total = widget.totalCount;
    _scrollCtrl.addListener(_onScroll);
    _load(page: 1, reset: true);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _loading || _page >= _lastPage) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _load(page: _page + 1, reset: false);
    }
  }

  Future<void> _load({required int page, required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    final res = await _api.getPostReactions(
      contentId: widget.contentId,
      contentType: widget.contentType,
      reactionType: _filter == 'all' ? null : _filter,
      page: page,
    );

    if (!mounted) return;

    if (res.success && res.data != null) {
      final data = res.data!;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _page = data.currentPage;
        _lastPage = data.lastPage;
        _total = data.total > 0 ? data.total : widget.totalCount;
        _reactionCounts = data.reactionCounts;
        _topReactions = _buildTopReactions(data.reactionCounts);
        if (reset) {
          _users = data.users;
        } else {
          _users = [..._users, ...data.users];
        }
      });
    } else {
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = res.message ?? 'Failed to load reactions';
        if (reset) _users = [];
      });
    }
  }

  List<FeedReaction> _buildTopReactions(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final out = <FeedReaction>[];
    for (final entry in entries) {
      if (out.length >= 3) break;
      final reaction = reactionByType(entry.key);
      if (reaction != null) out.add(reaction);
    }
    return out;
  }

  void _onFilterChanged(String filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _load(page: 1, reset: true);
  }

  Future<void> _toggleFollow(PostReactionUser user, int index) async {
    final userId = user.userId;
    if (userId == null || userId.isEmpty) return;
    final following = !user.isFollowing;
    setState(() {
      _users[index] = PostReactionUser(
        userId: user.userId,
        name: user.name,
        profilePic: user.profilePic,
        reactionType: user.reactionType,
        specialty: user.specialty,
        location: user.location,
        isVerified: user.isVerified,
        isPremium: user.isPremium,
        isFollowing: following,
      );
    });
    final res = await _api.followUser(
      userId: userId,
      followAction: following ? 'follow' : 'unfollow',
    );
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _users[index] = user;
      });
      toast(res.message ?? 'Could not update follow status');
    }
  }

  int get _allCount {
    if (_reactionCounts.isNotEmpty) {
      return _reactionCounts.values.fold<int>(0, (sum, n) => sum + n);
    }
    return _total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final title = (widget.contentTitle ?? '').trim();
    final headerBg = theme.cardBackground;
    final bodyBg = theme.scaffoldBackground;

    return Scaffold(
      backgroundColor: bodyBg,
      appBar: DoctakAppBar(
        title: 'Reactions',
        subtitle: title.isNotEmpty ? "on '$title'" : null,
        titleFontWeight: FontWeight.w700,
        centerTitle: false,
        toolbarHeight: title.isNotEmpty ? 64 : 56,
        backgroundColor: headerBg,
        showShadow: false,
        onBackPressed: () => Navigator.of(context).maybePop(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ColoredBox(
            color: headerBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_allCount > 0) _buildSummary(theme),
                _buildTabs(theme),
                const SizedBox(height: 12),
                Divider(height: 1, thickness: 1, color: theme.divider),
              ],
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: bodyBg,
              child: _buildBody(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(OneUITheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (_topReactions.isNotEmpty) ...[
            ReactionFacesStack(reactions: _topReactions),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              '$_allCount ${_allCount == 1 ? 'person' : 'people'} reacted to your post',
              style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(OneUITheme theme) {
    final chips = <Widget>[
      _ReactionFilterChip(
        label: 'All',
        count: _allCount,
        selected: _filter == 'all',
        onTap: () => _onFilterChanged('all'),
      ),
    ];

    for (final type in _reactionTabOrder) {
      final count = _reactionCounts[type] ?? 0;
      if (count <= 0) continue;
      final reaction = reactionByType(type);
      chips.add(
        _ReactionFilterChip(
          emoji: reaction?.emoji,
          count: count,
          selected: _filter == type,
          onTap: () => _onFilterChanged(type),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  Widget _buildBody(OneUITheme theme) {
    if (_loading) return const Padding(padding: EdgeInsets.all(16), child: UserShimmer());
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
                onPressed: () => _load(page: 1, reset: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'No reactions yet.',
          style: theme.bodyMedium.copyWith(color: theme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      itemCount: _users.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => Divider(height: 1, color: theme.divider),
      itemBuilder: (context, index) {
        if (index >= _users.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(color: theme.primary, strokeWidth: 2)),
          );
        }
        return _ReactionUserRow(
          user: _users[index],
          theme: theme,
          onProfileTap: () {
            final id = _users[index].userId;
            if (id != null && id.isNotEmpty) {
              ProfileNavigation.openUser(context, id);
            }
          },
          onFollowTap: () => _toggleFollow(_users[index], index),
        );
      },
    );
  }
}

class _ReactionFilterChip extends StatelessWidget {
  final String? label;
  final String? emoji;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ReactionFilterChip({
    this.label,
    this.emoji,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final bg = selected ? Colors.black : theme.cardBackground;
    final fg = selected ? Colors.white : theme.textPrimary;
    final border = selected ? Colors.black : theme.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (label != null)
                Text(label!, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13)),
              if (emoji != null)
                Text(emoji!, style: const TextStyle(fontSize: 14)),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionUserRow extends StatelessWidget {
  final PostReactionUser user;
  final OneUITheme theme;
  final VoidCallback onProfileTap;
  final VoidCallback onFollowTap;

  const _ReactionUserRow({
    required this.user,
    required this.theme,
    required this.onProfileTap,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final reaction = reactionByType(user.reactionType);
    final pic = user.profilePic ?? '';
    final name = user.name ?? 'Member';
    final subtitle = user.subtitle;
    final isSelf = user.userId != null && user.userId == AppData.logInUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: user.isPremium
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE6B422), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE6B422).withValues(alpha: 0.45),
                                blurRadius: 0,
                                spreadRadius: 1.5,
                              ),
                            ],
                          )
                        : null,
                    child: ClipOval(
                      child: pic.isNotEmpty
                          ? AppCachedNetworkImage(
                              imageUrl: pic,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              color: theme.primary.withValues(alpha: 0.12),
                              alignment: Alignment.center,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                style: TextStyle(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (reaction != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: theme.cardBackground,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(reaction.emoji, style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onProfileTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.titleSmall.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        theme.buildVerifiedBadge(size: 14, isPremium: user.isPremium),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.caption.copyWith(color: theme.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!isSelf && user.userId != null && user.userId!.isNotEmpty)
            _FollowButton(
              following: user.isFollowing,
              onTap: onFollowTap,
            ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool following;
  final VoidCallback onTap;

  const _FollowButton({required this.following, required this.onTap});

  static const _pillRadius = BorderRadius.all(Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    if (following) {
      // Subtle gray pill on the cream list — not a white outlined chip.
      return Material(
        color: const Color(0xFFE8E8E8),
        borderRadius: _pillRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: _pillRadius,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'Following',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ),
      );
    }

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(borderRadius: _pillRadius),
      ),
      child: const Text('+ Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
