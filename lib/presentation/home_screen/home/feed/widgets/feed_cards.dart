import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/routes/app_navigator.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_post_display.dart';
import 'package:doctak_app/widgets/hashtag_rich_text.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';
import 'package:doctak_app/data/apiClient/cme/cme_node_api_service.dart';
import 'package:doctak_app/data/apiClient/shared_api_service.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/presentation/case_discussion/screens/discussion_detail_screen.dart';
import 'package:doctak_app/presentation/cme_module/screens/cme_event_detail_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_article_detail_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/core/utils/profile_navigation.dart';
import 'package:doctak_app/presentation/blog/blog_detail_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/compose_content_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/blog_comment_sheet.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/case_comment_sheet.dart';
import 'package:doctak_app/presentation/case_discussion/repository/case_discussion_repository.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_article_content.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/expandable_post_text.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_card_shell.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_icons.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/reaction_picker.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/full_screen_image_widget.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/lazy_video_player_widget.dart';
import 'package:doctak_app/presentation/home_screen/home/components/full_screen_image_page.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/core/utils/deep_link_service.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/survey_screen/survey_fill_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/likes_list_screen/reactions_navigation.dart';
import 'package:doctak_app/presentation/home_screen/home/feed/widgets/feed_comment_sheet.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/groups_module/screens/group_detail_screen.dart';

String _authorSubtitle(FeedItem item, {String fallback = 'Doctor'}) {
  final specialty = displaySpecialty(item.str('authorSpecialty'));
  final location = item.str('authorLocation') ?? '';
  final parts = [specialty, location].where((e) => e.isNotEmpty).toList();
  return parts.isEmpty ? fallback : parts.join(' · ');
}

void _openFeedAuthorProfile(BuildContext context, FeedItem item) {
  ProfileNavigation.openFromFeedItem(context, item);
}

void _openFeedGroup(BuildContext context, FeedItem item) {
  final groupId =
      item.str('groupId') ?? item.str('groupUuid') ?? item.authorId;
  if (groupId != null && groupId.isNotEmpty) {
    GroupDetailScreen(groupId: groupId).launch(context);
  }
}

void _openFeedGroupPosterProfile(BuildContext context, FeedItem item) {
  final posterId = item.str('authorUserId');
  if (posterId != null && posterId.isNotEmpty) {
    ProfileNavigation.open(context, userId: posterId);
    return;
  }
  _openFeedAuthorProfile(context, item);
}

String _groupPostReactionId(FeedItem item) => item.str('postId') ?? item.id;

int? _groupPostIdInt(FeedItem item) => int.tryParse(_groupPostReactionId(item));

/// Underlying posts.id for likes, comments, reposts, and reaction lists.
/// Repost cards use a synthetic feed id (`repost_{postId}_{userId}`).
String _engagementPostId(FeedItem item) {
  final original = item.str('originalPostId');
  if (original != null && original.isNotEmpty) return original;
  if (item.type == 'group_post') return _groupPostReactionId(item);
  final id = item.id;
  if (id.startsWith('repost_')) {
    final parts = id.split('_');
    if (parts.length >= 2 && parts[1].isNotEmpty) return parts[1];
  }
  return id;
}

bool _hasEngagementPostId(FeedItem item) =>
    int.tryParse(_engagementPostId(item)) != null;

int? _engagementPostIdInt(FeedItem item) =>
    int.tryParse(_engagementPostId(item));

void _applyReactionApiResult({
  required void Function(void Function()) setState,
  required String? previousReaction,
  required int previousLikeCount,
  required String contentType,
  required String itemId,
  required Map<String, dynamic>? data,
  required void Function(String? reaction, int likeCount, int refreshBump) onSync,
}) {
  if (data == null) return;
  final liked = data['liked'];
  final reactionRaw = data['reaction'];
  final likesRaw = data['likes'];
  final nextReaction = reactionRaw is String
      ? reactionRaw
      : (liked == false ? null : previousReaction);
  final nextLikes = likesRaw is num ? likesRaw.toInt() : previousLikeCount;

  FeedEngagementStats.applyLocalReactionChange(
    contentType: contentType,
    itemId: itemId,
    previousType: previousReaction,
    newType: nextReaction,
    likeCount: nextLikes,
  );
  onSync(nextReaction, nextLikes, 1);
}

String? _groupPostTypeBadge(FeedItem item) {
  final type = item.str('postType')?.toLowerCase();
  switch (type) {
    case 'poll':
      return 'Poll';
    case 'article':
    case 'blog':
      return 'Article';
    default:
      return null;
  }
}

bool _isFeedItemOwner(FeedItem item) {
  final myId = AppData.logInUserId.toString();
  final posterId =
      item.str('posterUserId') ?? item.str('authorUserId') ?? item.str('userId');
  if (posterId != null && posterId == myId) return true;
  final authorId = item.authorId ?? item.str('authorId');
  if (authorId != null && authorId == myId) return true;
  final ownerUserId = item.str('ownerUserId');
  if (ownerUserId != null && ownerUserId == myId) return true;
  // Acting as the business page that published this post — treat as owner
  // (mirrors web FeedCardShell's isOrganizationOwner check).
  final orgId = item.str('organizationId');
  final actingOrgId = ActingContextService.instance.organization?.id;
  return orgId != null &&
      orgId.isNotEmpty &&
      actingOrgId != null &&
      orgId == actingOrgId;
}

class _FeedMediaEntry {
  final String url;
  final String type;
  final String? thumbnailUrl;
  const _FeedMediaEntry({
    required this.url,
    required this.type,
    this.thumbnailUrl,
  });
}

String _resolveFeedMediaUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return AppData.fullImageUrl(trimmed);
}

List<_FeedMediaEntry> _extractFeedMedia(FeedItem item) {
  final media = <_FeedMediaEntry>[];
  for (final f in item.listVal('mediaFiles')) {
    if (f is! Map) continue;
    final raw = f['url']?.toString().trim();
    if (raw == null || raw.isEmpty) continue;
    final type = (f['type'] ?? 'image').toString().toLowerCase();
    final thumbRaw = (f['thumbnail'] ?? f['thumbnailUrl'] ?? f['poster'])
        ?.toString()
        .trim();
    media.add(
      _FeedMediaEntry(
        url: _resolveFeedMediaUrl(raw),
        type: type,
        thumbnailUrl: thumbRaw != null && thumbRaw.isNotEmpty
            ? _resolveFeedMediaUrl(thumbRaw)
            : null,
      ),
    );
  }
  if (media.isEmpty) {
    final single = item.str('image') ?? item.str('mediaUrl');
    if (single != null && single.isNotEmpty) {
      final type = (item.str('mediaType') ?? 'image').toLowerCase();
      final thumb = item.str('videoThumbnail') ??
          item.str('thumbnail') ??
          item.str('thumbnailUrl');
      media.add(
        _FeedMediaEntry(
          url: _resolveFeedMediaUrl(single),
          type: type,
          thumbnailUrl:
              thumb != null ? _resolveFeedMediaUrl(thumb) : null,
        ),
      );
    }
  }
  return media;
}

List<String> _extractFeedImages(FeedItem item) {
  return _extractFeedMedia(item)
      .where((m) => m.type != 'video' && m.type != 'document')
      .map((m) => m.url)
      .toList();
}

List<_FeedMediaEntry> _extractFeedVideos(FeedItem item) {
  final media = _extractFeedMedia(item);
  final images = media
      .where((m) => m.type != 'video' && m.type != 'document')
      .map((m) => m.url)
      .toList();
  final fallbackThumb = item.str('videoThumbnail') ??
      item.str('thumbnail') ??
      item.str('thumbnailUrl') ??
      (images.isNotEmpty ? images.first : null) ??
      item.str('image');

  return media.where((m) => m.type == 'video').map((video) {
    final thumb = video.thumbnailUrl ??
        (fallbackThumb != null && fallbackThumb.isNotEmpty
            ? _resolveFeedMediaUrl(fallbackThumb)
            : null);
    if (thumb == video.url) {
      return _FeedMediaEntry(url: video.url, type: video.type);
    }
    return _FeedMediaEntry(
      url: video.url,
      type: video.type,
      thumbnailUrl: thumb,
    );
  }).toList();
}

List<String> _extractFeedTags(FeedItem item) => FeedPostDisplay.parseTags(item);

Widget _feedTagChips(OneUITheme theme, List<String> tags) {
  if (tags.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .map(
            (t) => Text(
              t.startsWith('#') ? t : '#$t',
              style: theme.caption.copyWith(
                color: theme.primary,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          )
          .toList(),
    ),
  );
}

List<Map<String, String>> _feedViewerMediaUrls(FeedItem item) {
  return _extractFeedMedia(item)
      .where((m) => m.type != 'document')
      .map((m) => {'url': m.url, 'type': m.type})
      .toList();
}

/// Facebook-style tappable image grid — opens full-screen swipe gallery on tap.
class _FeedPostImageGallery extends StatelessWidget {
  final FeedItem? item;
  final List<String> imageUrls;

  const _FeedPostImageGallery({
    required this.imageUrls,
    this.item,
  });

  static const _gap = 3.0;
  static const _radius = 12.0;

  List<Map<String, String>> _viewerMediaUrls() {
    if (item != null) {
      final fromItem = _feedViewerMediaUrls(item!);
      if (fromItem.isNotEmpty) return fromItem;
    }
    return imageUrls.map((u) => {'url': u, 'type': 'image'}).toList();
  }

  void _openViewer(BuildContext context, String url) {
    final mediaUrls = _viewerMediaUrls();
    if (mediaUrls.isEmpty) return;

    if (item != null) {
      showFeedPostImageViewer(
        context,
        item: item!,
        mediaUrls: mediaUrls,
        initialUrl: url,
      );
      return;
    }
    showImageGalleryViewer(
      context,
      imageUrls: imageUrls,
      initialIndex: imageUrls.indexOf(url).clamp(0, imageUrls.length - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final screenW = MediaQuery.sizeOf(context).width;

    Widget tile(
      String url, {
      double? height,
      bool fillParent = false,
      int? overlayRemaining,
      BorderRadius? borderRadius,
    }) {
      final radius = borderRadius ?? BorderRadius.circular(_radius);
      final cacheH = feedMemCachePx(context, height ?? 200);

      Widget imageContent = AppCachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: feedMemCachePx(context, screenW),
        memCacheHeight: cacheH,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        filterQuality: FilterQuality.low,
        placeholder: (_, _) => Container(color: theme.surfaceVariant),
        errorWidget: (_, _, _) => Container(
          color: theme.surfaceVariant,
          alignment: Alignment.center,
          child: Icon(Icons.broken_image_outlined, color: theme.textTertiary),
        ),
      );

      Widget stack = Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: imageContent),
          if (overlayRemaining != null && overlayRemaining > 0)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Text(
                '+$overlayRemaining',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      );

      Widget child = ClipRRect(
        borderRadius: radius,
        child: fillParent
            ? stack
            : SizedBox(
                height: height ?? 240,
                width: double.infinity,
                child: stack,
              ),
      );

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openViewer(context, url),
        child: child,
      );
    }

    if (imageUrls.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: tile(imageUrls.first, height: 240),
      );
    }

    if (imageUrls.length == 2) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: tile(
                  imageUrls[0],
                  fillParent: true,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(_radius)),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: tile(
                  imageUrls[1],
                  fillParent: true,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(_radius)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (imageUrls.length == 3) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          height: 260,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: tile(
                  imageUrls[0],
                  fillParent: true,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(_radius)),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: tile(
                        imageUrls[1],
                        fillParent: true,
                        borderRadius: const BorderRadius.only(topRight: Radius.circular(_radius)),
                      ),
                    ),
                    const SizedBox(height: _gap),
                    Expanded(
                      child: tile(
                        imageUrls[2],
                        fillParent: true,
                        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(_radius)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4+ images — 2×2 grid with +N overlay on the last visible tile
    final visible = imageUrls.take(4).toList();
    final remaining = imageUrls.length - 4;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 260,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: tile(visible[0], fillParent: true)),
                  const SizedBox(width: _gap),
                  Expanded(child: tile(visible[1], fillParent: true)),
                ],
              ),
            ),
            const SizedBox(height: _gap),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: tile(visible[2], fillParent: true)),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: tile(
                      visible[3],
                      fillParent: true,
                      overlayRemaining: remaining > 0 ? remaining : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Post media — images via [_FeedPostImageGallery], videos via [LazyVideoPlayerWidget].
class _FeedPostMedia extends StatelessWidget {
  final FeedItem item;
  const _FeedPostMedia(this.item);

  @override
  Widget build(BuildContext context) {
    final images = _extractFeedImages(item);
    final videos = _extractFeedVideos(item);
    if (images.isEmpty && videos.isEmpty) return const SizedBox.shrink();

    final postId = int.tryParse(item.id);
    final details = PostImageDetailsContext(
      title: item.str('title'),
      body: item.str('body') ?? item.str('content'),
      authorName: item.str('authorName'),
      likeCount: item.engagement.likes,
      commentCount: item.engagement.comments,
      onOpenPost: postId != null
          ? () => PostDetailsScreen(postId: postId).launch(context)
          : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (images.isNotEmpty) _FeedPostImageGallery(item: item, imageUrls: images),
        for (var i = 0; i < videos.length; i++)
          Padding(
            padding: EdgeInsets.only(top: images.isNotEmpty || i > 0 ? 10 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LazyVideoPlayerWidget(
                videoUrl: videos[i].url,
                thumbnailUrl: videos[i].thumbnailUrl,
                showMinimalControls: true,
                detailsContext: details,
              ),
            ),
          ),
      ],
    );
  }
}

bool _feedUserReposted(FeedItem item) =>
    item.flag('userReposted') || item.flag('reposted');

/// Engagement summary — reaction counts from feed API; emoji faces from
/// `payload.topReactions` (same feed response, no per-card summary API).
class FeedEngagementStats extends StatelessWidget {
  final FeedItem item;
  final int likeCount;
  final int? repostCount;
  final int? commentCount;
  final String contentType;
  final int refreshToken;

  /// When true, shows emoji faces from feed payload / local cache only.
  final bool showReactionFaces;

  /// Override for reactions list API (e.g. group posts use underlying `postId`).
  final String? reactionsContentId;
  final String? reactionsContentType;

  const FeedEngagementStats({
    super.key,
    required this.item,
    required this.likeCount,
    this.repostCount,
    this.commentCount,
    this.contentType = 'post',
    this.refreshToken = 0,
    this.showReactionFaces = false,
    this.reactionsContentId,
    this.reactionsContentType,
  });

  /// Call after the user reacts so emoji faces update without a summary API.
  static void applyLocalReactionChange({
    required String contentType,
    required String itemId,
    required String? previousType,
    required String? newType,
    required int likeCount,
  }) {
    updateFeedTopReactionsCache(
      contentType: contentType,
      itemId: itemId,
      previousType: previousType,
      newType: newType,
      likeCount: likeCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final likes = likeCount;
    final comments = commentCount ?? item.engagement.comments;
    final reposts = repostCount ?? item.engagement.shares;
    final views = item.engagement.views;
    final topReactions = resolveFeedTopReactions(
      item: item,
      contentType: contentType,
      likeCount: likes,
      showFaces: showReactionFaces,
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
              onTap: () => openReactionsList(
                context,
                contentId: reactionsContentId ?? item.id,
                contentType: reactionsContentType ?? contentType,
                contentTitle: reactionContentTitleFromFeedItem(item),
                totalCount: likes,
              ),
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
}

// ─── Post (incl. poll) ───────────────────────────────────────────────

/// Optional hooks for legacy post lists (profile / search) and home feed refresh.
class FeedPostCardOptions {
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onFeedChanged;
  final VoidCallback? onProfileTap;
  final VoidCallback? onComment;
  /// Preferred over [onComment] — opens the sheet and returns updated count.
  final Future<int?> Function()? openCommentSheet;
  final VoidCallback? onLikeMutate;
  final VoidCallback? onDismiss;
  final VoidCallback? onUserBlocked;
  final int? postIdForComments;
  final HomeBloc? homeBloc;

  /// Show owner actions (edit/delete) even when the viewer is not the post's
  /// author — used by org owners/admins managing their business page.
  final bool treatAsOwner;

  const FeedPostCardOptions({
    this.onDelete,
    this.onEdit,
    this.onFeedChanged,
    this.onProfileTap,
    this.onComment,
    this.openCommentSheet,
    this.onLikeMutate,
    this.onDismiss,
    this.onUserBlocked,
    this.postIdForComments,
    this.homeBloc,
    this.treatAsOwner = false,
  });
}

class FeedPostCard extends StatefulWidget {
  final FeedItem item;
  final FeedPostCardOptions? options;
  const FeedPostCard(this.item, {super.key, this.options});

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  bool _hidden = false;
  late String? _reaction = widget.item.str('userReaction');
  late int _likeCount = widget.item.engagement.likes;
  late int _commentCount = widget.item.engagement.comments;
  late int _repostCount = widget.item.engagement.shares;
  late bool _reposted = _feedUserReposted(widget.item);
  bool _reposting = false;
  int _reactionRefresh = 0;
  late List<String> _tags = _extractFeedTags(widget.item);

  // Poll state
  late final Map<String, dynamic>? _poll = widget.item.mapVal('poll');
  late List<String> _options =
      (_poll?['options'] as List?)?.map((e) => '$e').toList() ?? [];
  late List<String> _optionIds =
      (_poll?['optionIds'] as List?)?.map((e) => '$e').toList() ?? [];
  late List<int> _voteCounts =
      (_poll?['voteCounts'] as List?)?.map((e) => (e as num).toInt()).toList() ??
          List<int>.filled(0, 0);
  late int _totalVoters = (_poll?['totalVoters'] as num?)?.toInt() ?? 0;
  late List<int> _selected = _initialSelection();
  bool _voting = false;
  final TextEditingController _newPollOptionCtrl = TextEditingController();

  List<int> _initialSelection() {
    final indices = (_poll?['userVotedIndices'] as List?)
        ?.map((e) => (e as num).toInt())
        .toList();
    if (indices != null && indices.isNotEmpty) return indices;
    final single = _poll?['userVotedIndex'];
    return single is num ? [single.toInt()] : <int>[];
  }

  bool get _isPoll => widget.item.str('postType') == 'poll' && _options.isNotEmpty;

  bool get _isGroupPost =>
      widget.item.type == 'group_post' || widget.item.flag('isGroupPagePost');

  bool get _pollAllowAddOptions => _poll?['allowAddOptions'] == true;

  bool get _pollAllowChangeVote => _poll?['allowChangeVote'] == true;

  bool get _pollMultipleChoice => _poll?['isMultipleChoice'] == true;

  @override
  void dispose() {
    _newPollOptionCtrl.dispose();
    super.dispose();
  }

  bool get _pollClosed {
    final endsAt = _poll?['endsAt']?.toString();
    if (endsAt == null || endsAt.isEmpty) return false;
    final dt = DateTime.tryParse(endsAt);
    return dt != null && dt.isBefore(DateTime.now());
  }

  bool get _canEdit => !_isPoll || !_pollClosed;

  String? _postTypeBadge(FeedItem item) {
    if (_isPoll) return 'Poll';
    final type = item.str('postType')?.toLowerCase();
    switch (type) {
      case 'article':
      case 'blog':
        return 'Article';
      case 'case':
        return 'Case';
      case 'job':
        return 'Job';
      case 'cme':
        return 'CME';
      case 'survey':
        return 'Survey';
      default:
        return null;
    }
  }

  void _openDetail() {
    final id = _engagementPostIdInt(widget.item);
    if (id == null) return;
    if (feedItemIsArticle(widget.item) && !_isPoll) {
      PostArticleDetailScreen(postId: id).launch(context);
      return;
    }
    PostDetailsScreen(postId: id).launch(context);
  }

  Future<void> _openComments() async {
    final opts = widget.options;
    final postId = opts?.postIdForComments ?? _engagementPostIdInt(widget.item);

    final open = opts?.openCommentSheet;
    if (open != null) {
      final count = await open();
      if (!mounted) return;
      if (count != null) setState(() => _commentCount = count);
      opts?.onFeedChanged?.call();
      return;
    }
    if (opts?.onComment != null) {
      opts!.onComment!();
      return;
    }
    if (postId != null) {
      final count = await showFeedCommentSheet(
        context,
        postId: postId,
        homeBloc: opts?.homeBloc,
        onCommentCountChanged: (c) {
          if (mounted) setState(() => _commentCount = c);
        },
      );
      if (!mounted) return;
      if (count != null) setState(() => _commentCount = count);
      opts?.onFeedChanged?.call();
      return;
    }
    _openDetail();
  }

  void _openProfile() {
    final opts = widget.options;
    if (opts?.onProfileTap != null) {
      opts!.onProfileTap!();
      return;
    }
    ProfileNavigation.openFromFeedItem(context, widget.item);
  }

  Future<void> _onReact(String? type) async {
    final postId = _engagementPostId(widget.item);
    if (!_hasEngagementPostId(widget.item)) {
      _openDetail();
      return;
    }
    final previous = _reaction;
    final prevLike = _likeCount;
    final has = type != null;
    final had = previous != null;
    var nextLike = prevLike;
    if (has && !had) nextLike += 1;
    if (!has && had) nextLike -= 1;
    if (nextLike < 0) nextLike = 0;

    FeedEngagementStats.applyLocalReactionChange(
      contentType: _isGroupPost ? 'group_post' : 'post',
      itemId: widget.item.id,
      previousType: previous,
      newType: type,
      likeCount: nextLike,
    );

    setState(() {
      _reaction = type;
      _likeCount = nextLike;
      _reactionRefresh++;
    });
    // The /like endpoint toggles off when the same reaction is resent and
    // updates otherwise, so when removing we resend the previous type.
    final toSend = type ?? previous ?? 'like';
    widget.options?.onLikeMutate?.call();
    final res = await SharedApiService()
        .reactToPost(postId: postId, reaction: toSend);
    if (!mounted) return;
    if (res.success) {
      _applyReactionApiResult(
        setState: setState,
        previousReaction: previous,
        previousLikeCount: _likeCount,
        contentType: _isGroupPost ? 'group_post' : 'post',
        itemId: widget.item.id,
        data: res.data,
        onSync: (reaction, likes, bump) {
          setState(() {
            _reaction = reaction;
            _likeCount = likes;
            _reactionRefresh += bump;
          });
        },
      );
      return;
    }
    FeedEngagementStats.applyLocalReactionChange(
      contentType: _isGroupPost ? 'group_post' : 'post',
      itemId: widget.item.id,
      previousType: type,
      newType: previous,
      likeCount: prevLike,
    );
    setState(() {
      _reaction = previous;
      _likeCount = prevLike;
      _reactionRefresh++;
    });
    toast(res.message ?? 'Failed to update reaction');
  }

  Future<void> _toggleRepost() async {
    final postId = _engagementPostId(widget.item);
    if (!_hasEngagementPostId(widget.item) || _reposting) {
      if (!_hasEngagementPostId(widget.item)) _openDetail();
      return;
    }
    setState(() {
      _reposting = true;
      _reposted = !_reposted;
      if (_reposted) {
        _repostCount += 1;
      } else if (_repostCount > 0) {
        _repostCount -= 1;
      }
    });
    final res = await SharedApiService().repostPost(postId: postId);
    if (!mounted) return;
    setState(() {
      _reposting = false;
      final reposted = res.data?['reposted'];
      if (reposted is bool) _reposted = reposted;
      final reposts = res.data?['reposts'];
      if (reposts is num) _repostCount = reposts.toInt();
    });
    if (res.success) {
      toast(_reposted ? 'Reposted' : 'Repost removed');
    }
  }

  void _share() {
    final id = _engagementPostIdInt(widget.item);
    if (id == null) return;
    DeepLinkService.sharePost(
      postId: id,
      title: widget.item.str('title') ?? widget.item.str('body'),
    );
    SharedApiService().recordShare(postId: _engagementPostId(widget.item));
  }

  Future<void> _vote(int index) async {
    if (_voting || _poll == null) return;
    final pollId = '${_poll['pollId'] ?? ''}';
    if (pollId.isEmpty) return;
    final isMultiple = _poll['isMultipleChoice'] == true;
    final allowChange = _pollAllowChangeVote;
    if (!isMultiple && _selected.isNotEmpty && !allowChange) return;
    if (_selected.contains(index)) return;
    final optionId = index < _optionIds.length ? _optionIds[index] : '$index';
    final previousSelected = List<int>.from(_selected);

    setState(() {
      _voting = true;
      if (_selected.isEmpty) _totalVoters += 1;
      if (!isMultiple && allowChange && previousSelected.isNotEmpty) {
        final prev = previousSelected.first;
        if (prev != index && prev < _voteCounts.length && _voteCounts[prev] > 0) {
          _voteCounts[prev] -= 1;
        }
      }
      _selected = isMultiple ? [..._selected, index] : [index];
      if (index < _voteCounts.length) {
        _voteCounts[index] += 1;
      }
    });
    final res = await SharedApiService().votePoll(pollId: pollId, optionId: optionId);
    if (!mounted) return;
    setState(() {
      _applyPollVoteResponse(res.data);
      _voting = false;
    });
  }

  Future<void> _addPollOption() async {
    if (_voting || _poll == null || !_pollAllowAddOptions) return;
    final pollId = '${_poll['pollId'] ?? ''}';
    final text = _newPollOptionCtrl.text.trim();
    if (pollId.isEmpty || text.isEmpty) return;

    final snapshot = (
      options: List<String>.from(_options),
      optionIds: List<String>.from(_optionIds),
      voteCounts: List<int>.from(_voteCounts),
      selected: List<int>.from(_selected),
      totalVoters: _totalVoters,
    );
    final optimisticIndex = _options.length;

    setState(() {
      _voting = true;
      _options.add(text);
      _optionIds.add('pending');
      _voteCounts.add(1);
      if (_selected.isEmpty) _totalVoters += 1;
      _selected = _pollMultipleChoice
          ? [..._selected, optimisticIndex]
          : [optimisticIndex];
      _newPollOptionCtrl.clear();
    });

    final res = await SharedApiService().votePoll(
      pollId: pollId,
      optionText: text,
    );
    if (!mounted) return;

    if (!res.success) {
      setState(() {
        _options = snapshot.options;
        _optionIds = snapshot.optionIds;
        _voteCounts = snapshot.voteCounts;
        _selected = snapshot.selected;
        _totalVoters = snapshot.totalVoters;
        _voting = false;
      });
      return;
    }

    setState(() {
      _applyPollVoteResponse(res.data, addedOptionText: text);
      _voting = false;
    });
  }

  void _applyPollVoteResponse(
    Map<String, dynamic>? data, {
    String? addedOptionText,
  }) {
    if (data == null) return;

    final newOptions = data['options'];
    final newOptionIds = data['optionIds'];
    if (newOptions is List) {
      _options = newOptions.map((e) => '$e').toList();
    }
    if (newOptionIds is List) {
      _optionIds = newOptionIds.map((e) => '$e').toList();
    }

    final votedOptionId = data['votedOptionId']?.toString();
    if (addedOptionText != null &&
        votedOptionId != null &&
        votedOptionId.isNotEmpty &&
        !_optionIds.contains(votedOptionId)) {
      _options.add(addedOptionText);
      _optionIds.add(votedOptionId);
    }

    final byId = data['votesByOptionId'];
    if (byId is Map && _optionIds.isNotEmpty) {
      _voteCounts = _optionIds
          .map((oid) => (byId[oid] as num?)?.toInt() ?? 0)
          .toList();
    } else if (_voteCounts.length != _options.length) {
      _voteCounts = List.filled(_options.length, 0);
    }

    final total = data['totalVoters'];
    if (total is num) _totalVoters = total.toInt();

    final selectedIds = data['selectedOptionIds'];
    if (selectedIds is List) {
      _selected = selectedIds
          .map((oid) => _optionIds.indexOf('$oid'))
          .where((i) => i >= 0)
          .toList();
    }
  }

  List<ComposeExistingMedia> _existingMediaForEdit() {
    final media = <ComposeExistingMedia>[];
    for (final f in widget.item.listVal('mediaFiles')) {
      if (f is! Map) continue;
      final raw = Map<String, dynamic>.from(f);
      final url = raw['url']?.toString().trim();
      if (url == null || url.isEmpty) continue;
      final type = (raw['type'] ?? 'image').toString();
      final path = raw['path']?.toString().trim();
      media.add(
        ComposeExistingMedia(
          id: raw['id']?.toString() ?? '',
          mediaType: type,
          mediaPath: path?.isNotEmpty == true ? path! : url,
          previewUrl: url,
        ),
      );
    }
    if (media.isEmpty) {
      final single = widget.item.str('image') ?? widget.item.str('mediaUrl');
      if (single != null && single.isNotEmpty) {
        final resolved = _resolveFeedMediaUrl(single);
        media.add(
          ComposeExistingMedia(
            id: '',
            mediaType: (widget.item.str('mediaType') ?? 'image').toLowerCase(),
            mediaPath: single,
            previewUrl: resolved,
          ),
        );
      }
    }
    return media;
  }

  Future<void> _openEdit() async {
    final item = widget.item;
    final ComposeEditData edit;
    if (_isPoll) {
      edit = ComposeEditData(
        id: item.id,
        tab: ComposeTab.poll,
        title: item.str('title'),
        description: _poll?['description']?.toString() ?? item.str('body'),
        pollOptions: _options,
      );
    } else {
      edit = ComposeEditData(
        id: item.id,
        tab: ComposeTab.update,
        title: item.str('title'),
        body: item.str('body'),
        existingMedia: _existingMediaForEdit(),
      );
    }
    await AppNavigator.push(
      context,
      ComposeContentScreen(
        editData: edit,
        initialTab: edit.tab,
        onPosted: () => widget.options?.onFeedChanged?.call(),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final theme = OneUITheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text('Delete post?', style: theme.titleSmall),
        content: Text(
          'This cannot be undone.',
          style: theme.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: theme.deleteRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final res =
        await SharedApiService().deletePostV1(postId: widget.item.id);
    if (!mounted) return;
    if (res.success) {
      setState(() => _hidden = true);
      widget.options?.onFeedChanged?.call();
      widget.options?.onDelete?.call();
      toast('Post deleted');
    } else {
      toast(res.message ?? 'Failed to delete post');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();

    final item = widget.item;
    final theme = OneUITheme.of(context);
    final pollDescription = _poll?['description']?.toString().trim();
    final tags = _tags;
    final display = FeedPostDisplay.resolve(
      item,
      isPoll: _isPoll,
      pollDescription: pollDescription,
    );
    final headline = display.headline;
    final mainText = display.mainText;
    final highlightHashtags = display.highlightHashtags;
    final showHeadline =
        headline != null && headline.isNotEmpty;
    final repostedBy = item.str('repostedByName');

    final isArticle = feedItemIsArticle(item) && !_isPoll;
    final badge = _isGroupPost
        ? (isArticle ? 'Article' : _groupPostTypeBadge(item))
        : _postTypeBadge(item);
    final authorId = item.authorId ?? item.str('authorId');
    final isOwner =
        widget.options?.treatAsOwner == true || _isFeedItemOwner(item);
    final visibility = _formatVisibility(item.str('privacy'));
    final groupPosterName =
        item.str('posterName') ?? item.str('authorName') ?? 'Member';
    final groupPosterAvatar =
        item.str('posterAvatar') ?? item.str('authorAvatar');

    return FeedCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (repostedBy != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.repeat, size: 13, color: theme.textTertiary),
                  const SizedBox(width: 6),
                  Text('$repostedBy reposted', style: theme.caption),
                ],
              ),
            ),
          if (_isGroupPost)
            FeedGroupPostHeader(
              groupName: item.str('groupName') ?? 'Group',
              groupLogoUrl: item.str('groupLogo'),
              posterName: groupPosterName,
              posterAvatarUrl: groupPosterAvatar,
              createdAt: item.createdAt,
              posterVerified:
                  item.flag('posterVerified') || item.flag('authorVerified'),
              posterPremium: item.flag('authorPremium') || item.flag('posterPremium'),
              trailingBadge: badge,
              onGroupTap: () => _openFeedGroup(context, item),
              onPosterTap: () => _openFeedGroupPosterProfile(context, item),
            )
          else
            FeedAuthorHeader(
              name: item.str('authorName') ?? 'Member',
              avatarUrl: item.str('authorAvatar'),
              subtitle: _authorSubtitle(item),
              createdAt: item.createdAt,
              verified: item.flag('authorVerified'),
              isPremium: item.flag('authorPremium') || item.flag('posterPremium'),
              trailingBadge: badge,
              visibility: visibility,
              onTap: _openProfile,
              isCurrentUser: isOwner,
              postId: item.id,
              userId: authorId,
              contentType: 'post',
              onEdit: isOwner && _canEdit
                  ? (widget.options?.onEdit ?? _openEdit)
                  : null,
              onDelete: isOwner
                  ? (widget.options?.onDelete ?? _confirmDelete)
                  : null,
              onDismiss: () {
                setState(() => _hidden = true);
                widget.options?.onDismiss?.call();
              },
              onUserBlocked: () {
                setState(() => _hidden = true);
                widget.options?.onUserBlocked?.call();
              },
            ),
          if (_isGroupPost &&
              (item.flag('isPinned') || item.flag('isAnnouncement')))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (item.flag('isPinned'))
                    const FeedBadge(
                      label: 'Pinned',
                      color: Color(0xFF16A34A),
                    ),
                  if (item.flag('isAnnouncement'))
                    const FeedBadge(
                      label: 'Announcement',
                      color: Color(0xFFD97706),
                    ),
                ],
              ),
            ),
          if (isArticle)
            FeedArticleContent(
              item: item,
              onOpen: _openDetail,
              resolveMediaUrl: _resolveFeedMediaUrl,
            )
          else ...[
            if (showHeadline)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: HashtagRichText(
                  text: headline,
                  style: theme.titleSmall.copyWith(fontSize: 16),
                ),
              ),
            if (mainText != null && mainText.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: showHeadline ? 6 : 10),
                child: ExpandablePostText(
                  text: mainText,
                  style: showHeadline
                      ? theme.bodyMedium
                      : theme.bodyMedium.copyWith(fontSize: 15),
                  collapsedMaxLines: 4,
                  highlightHashtags: highlightHashtags,
                ),
              ),
            _feedTagChips(theme, tags),
            if (_isPoll) _buildPoll(theme),
            if (!_isPoll)
              RepaintBoundary(child: _FeedPostMedia(item)),
          ],
          FeedEngagementStats(
            item: item,
            likeCount: _likeCount,
            repostCount: _repostCount,
            commentCount: _commentCount,
            contentType: _isGroupPost ? 'group_post' : 'post',
            refreshToken: _reactionRefresh,
            showReactionFaces: true,
            reactionsContentId: _engagementPostId(item),
            reactionsContentType: 'post',
          ),
          FeedActionRow(actions: [
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
          ]),
        ],
      ),
    );
  }

  String? _formatVisibility(String? privacy) {
    if (privacy == null || privacy.isEmpty) return 'Public';
    switch (privacy.toLowerCase()) {
      case 'public':
      case 'globe':
        return 'Public';
      case 'network':
      case 'connections':
        return 'Network';
      case 'private':
        return 'Only me';
      default:
        return privacy[0].toUpperCase() + privacy.substring(1);
    }
  }

  Widget _buildPoll(OneUITheme theme) {
    final hasVoted = _selected.isNotEmpty;
    final showVoters = _poll?['showVoters'] != false;
    final isAnonymous = _poll?['isAnonymous'] == true;
    final endsAt = _poll?['endsAt']?.toString();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _options.length; i++)
            _pollRow(theme, i, hasVoted),
          if (_pollAllowAddOptions && !_pollClosed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newPollOptionCtrl,
                      enabled: !_voting,
                      style: theme.bodyMedium,
                      decoration: theme.inputDecoration(hint: 'Add an option…'),
                      onSubmitted: (_) => _addPollOption(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _voting ? null : _addPollOption,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          Text(
            [
              if (_totalVoters > 0)
                '$_totalVoters ${_totalVoters == 1 ? 'vote' : 'votes'}'
              else
                'No votes yet',
              if (showVoters) ' · Voters visible',
              if (_pollMultipleChoice) ' · Multiple choice',
              if (isAnonymous) ' · Anonymous',
              if (endsAt != null && endsAt.isNotEmpty && !_pollClosed)
                ' · Closes ${feedRelativeTime(endsAt)}',
            ].join(),
            style: theme.caption,
          ),
        ],
      ),
    );
  }

  Widget _pollRow(OneUITheme theme, int index, bool hasVoted) {
    final count = index < _voteCounts.length ? _voteCounts[index] : 0;
    final pct = _totalVoters > 0 ? ((count / _totalVoters) * 100).round() : 0;
    final selected = _selected.contains(index);
    final canTap = !_voting &&
        !_pollClosed &&
        (_pollMultipleChoice
            ? !selected
            : _pollAllowChangeVote
                ? !selected
                : !hasVoted);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: canTap ? () => _vote(index) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? theme.primary : theme.border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Stack(
            children: [
              if (hasVoted)
                FractionallySizedBox(
                  widthFactor: (pct / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    if (selected) ...[
                      Icon(Icons.check_circle, size: 16, color: theme.primary),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        _options[index],
                        style: theme.bodyMedium.copyWith(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: hasVoted && selected ? theme.primary : null,
                        ),
                      ),
                    ),
                    if (hasVoted)
                      Text(
                        '$pct%',
                        style: theme.bodySecondary.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Blog / Article ──────────────────────────────────────────────────

class FeedBlogCard extends StatefulWidget {
  final FeedItem item;
  final VoidCallback? onFeedChanged;
  final VoidCallback? onComment;
  const FeedBlogCard(
    this.item, {
    super.key,
    this.onFeedChanged,
    this.onComment,
  });

  @override
  State<FeedBlogCard> createState() => _FeedBlogCardState();
}

class _FeedBlogCardState extends State<FeedBlogCard> {
  bool _hidden = false;
  late String? _reaction =
      widget.item.str('userReaction') ?? widget.item.str('currentReaction');
  late int _likeCount = widget.item.engagement.likes;
  late bool _reposted = _feedUserReposted(widget.item);
  late int _repostCount = widget.item.engagement.shares;
  bool _reposting = false;
  int _reactionRefresh = 0;

  void _open() {
    BlogDetailScreen(blogId: widget.item.id).launch(context);
  }

  void _openComments() {
    if (widget.onComment != null) {
      widget.onComment!();
      return;
    }
    showBlogCommentSheet(context, blogId: widget.item.id);
  }

  Future<void> _onReact(String? type) async {
    final previous = _reaction;
    final has = type != null;
    final had = previous != null;
    var nextLike = _likeCount;
    if (has && !had) nextLike += 1;
    if (!has && had) nextLike -= 1;
    if (nextLike < 0) nextLike = 0;

    FeedEngagementStats.applyLocalReactionChange(
      contentType: 'blog',
      itemId: widget.item.id,
      previousType: previous,
      newType: type,
      likeCount: nextLike,
    );

    setState(() {
      _reaction = type;
      _likeCount = nextLike;
      _reactionRefresh++;
    });
    final toSend = type ?? previous ?? 'like';
    await SharedApiService()
        .reactToBlog(blogId: widget.item.id, reaction: toSend);
  }

  Future<void> _toggleRepost() async {
    if (_reposting) return;
    setState(() {
      _reposting = true;
      _reposted = !_reposted;
      if (_reposted) {
        _repostCount += 1;
      } else if (_repostCount > 0) {
        _repostCount -= 1;
      }
    });
    final res = await SharedApiService().repostBlog(blogId: widget.item.id);
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
    final slug = widget.item.str('slug');
    final url = DeepLinkService.generateBlogLink(
      widget.item.id,
      slug: slug,
    );
    SharePlus.instance.share(
      ShareParams(
        text: url,
        title: widget.item.str('title') ?? 'DocTak Article',
      ),
    );
    SharedApiService().recordFeedInteraction(
      contentType: 'blog',
      contentId: widget.item.id,
      type: 'share',
    );
  }

  Future<void> _openEdit() async {
    final item = widget.item;
    final edit = ComposeEditData(
      id: item.id,
      tab: ComposeTab.blog,
      title: item.str('title'),
      excerpt: item.str('excerpt'),
      slug: item.str('slug'),
      coverImage: item.str('coverImage'),
    );
    await AppNavigator.push(
      context,
      ComposeContentScreen(
        editData: edit,
        initialTab: ComposeTab.blog,
        onPosted: () => widget.onFeedChanged?.call(),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final theme = OneUITheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBackground,
        title: Text('Delete article?', style: theme.titleSmall),
        content: Text(
          'This cannot be undone.',
          style: theme.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: theme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: theme.deleteRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await SharedApiService().deleteBlog(blogId: widget.item.id);
    if (!mounted) return;
    if (res.success) {
      setState(() => _hidden = true);
      widget.onFeedChanged?.call();
      toast('Article deleted');
    } else {
      toast(res.message ?? 'Failed to delete article');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();

    final item = widget.item;
    final authorId = item.authorId ?? item.str('authorId');
    final isOwner = _isFeedItemOwner(item);

    return FeedCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedAuthorHeader(
            name: item.str('authorName') ?? 'Member',
            avatarUrl: item.str('authorAvatar'),
            subtitle: _authorSubtitle(item),
            createdAt: item.createdAt,
            verified: item.flag('authorVerified'),
            isPremium: item.flag('authorPremium') || item.flag('posterPremium'),
            trailingBadge: 'Article',
            onTap: () => _openFeedAuthorProfile(context, item),
            isCurrentUser: isOwner,
            postId: item.id,
            userId: authorId,
            contentType: 'blog',
            onEdit: isOwner ? _openEdit : null,
            onDelete: isOwner ? _confirmDelete : null,
          ),
          FeedArticleContent(
            item: item,
            onOpen: _open,
            resolveMediaUrl: _resolveFeedMediaUrl,
          ),
          FeedEngagementStats(
            item: item,
            likeCount: _likeCount,
            repostCount: _repostCount,
            contentType: 'blog',
            refreshToken: _reactionRefresh,
            showReactionFaces: true,
          ),
          FeedActionRow(actions: [
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
          ]),
        ],
      ),
    );
  }
}

// ─── Case ──────────────────────────────────────────────────────────────

bool _caseIsLiked(FeedItem item) {
  final vote = item.payload['user_vote'] ?? item.payload['userVote'];
  if (vote == 'up') return true;
  if (vote == 'down') return false;
  final v = item.payload['is_liked'] ?? item.payload['isLiked'];
  return v == true || v == 1;
}

bool _caseIsDisliked(FeedItem item) {
  final vote = item.payload['user_vote'] ?? item.payload['userVote'];
  if (vote == 'down') return true;
  final v = item.payload['is_disliked'] ?? item.payload['isDisliked'];
  return v == true || v == 1;
}

class FeedCaseCard extends StatefulWidget {
  final FeedItem item;
  final VoidCallback? onComment;
  const FeedCaseCard(this.item, {super.key, this.onComment});

  @override
  State<FeedCaseCard> createState() => _FeedCaseCardState();
}

class _FeedCaseCardState extends State<FeedCaseCard> {
  late String? _reaction = _caseIsLiked(widget.item) ? 'like' : null;
  late int _likeCount = widget.item.engagement.likes;
  late int _commentCount = widget.item.engagement.comments;
  int _reactionRefresh = 0;
  bool _liking = false;

  late final CaseDiscussionRepository _repo = CaseDiscussionRepository(
    baseUrl: AppData.base2,
    getAuthToken: () => AppData.userToken ?? '',
  );

  int? get _caseId => int.tryParse(widget.item.id);

  void _open() {
    final id = _caseId;
    if (id != null) DiscussionDetailScreen(caseId: id).launch(context);
  }

  void _openComments() {
    final id = _caseId;
    if (id == null) {
      _open();
      return;
    }
    if (widget.onComment != null) {
      widget.onComment!();
      return;
    }
    showCaseCommentSheet(context, caseId: id);
  }

  Future<void> _onReact(String? type) async {
    final id = _caseId;
    if (id == null || _liking) return;
    final previous = _reaction;
    final wasLiked = previous != null;
    setState(() {
      _reaction = type;
      if (type != null && !wasLiked) {
        _likeCount += 1;
      } else if (type == null && wasLiked && _likeCount > 0) {
        _likeCount -= 1;
      }
      _liking = true;
    });
    try {
      if (type == null) {
        await _repo.performCaseAction(caseId: id, action: 'unlike');
      } else if (!wasLiked) {
        final res = await _repo.performCaseAction(caseId: id, action: 'like');
        final likes = res['data']?['likes'];
        if (mounted && likes is num) {
          setState(() => _likeCount = likes.toInt());
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reaction = previous;
          if (type != null && !wasLiked && _likeCount > 0) {
            _likeCount -= 1;
          } else if (type == null && wasLiked) {
            _likeCount += 1;
          }
        });
        toast('Failed to update reaction');
      }
    }
    if (mounted) {
      setState(() {
        _liking = false;
        _reactionRefresh++;
      });
    }
  }

  void _share() {
    final id = _caseId;
    if (id == null) return;
    final title = widget.item.str('title') ?? 'Case discussion';
    SharePlus.instance.share(
      ShareParams(
        text: DeepLinkService.generateCaseLink(id),
        title: title,
      ),
    );
    SharedApiService().recordFeedInteraction(
      contentType: 'case',
      contentId: widget.item.id,
      type: 'share',
    );
  }

  void _repost() {
    _share();
    SharedApiService().recordFeedInteraction(
      contentType: 'case',
      contentId: widget.item.id,
      type: 'repost',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final item = widget.item;
    final title = item.str('title');
    final desc = item.str('description');
    final tags = _extractFeedTags(item);

    return FeedCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedAuthorHeader(
            name: item.str('authorName') ?? 'Member',
            avatarUrl: item.str('authorAvatar'),
            subtitle: _authorSubtitle(item),
            createdAt: item.createdAt,
            verified: item.flag('authorVerified'),
            isPremium: item.flag('authorPremium') || item.flag('posterPremium'),
            trailingBadge: 'Case',
            onTap: () => _openFeedAuthorProfile(context, item),
          ),
          if (title != null && title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(title, style: theme.titleSmall.copyWith(fontSize: 16)),
            ),
          if (desc != null && desc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(desc,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodyMedium),
            ),
          _feedTagChips(theme, tags),
          const SizedBox(height: 10),
          InkWell(
            onTap: _open,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.error.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.error.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 13, color: theme.error),
                      const SizedBox(width: 6),
                      Text('Anonymized case data',
                          style: theme.bodySecondary.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.error,
                          )),
                      const Spacer(),
                      Text('HIPAA-safe', style: theme.caption),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _caseStat(theme, 'Specialty',
                          tags.isNotEmpty ? tags.first : 'Case'),
                      _caseStat(theme, 'Views',
                          feedCompactNumber(item.engagement.views)),
                      _caseStat(theme, 'Replies',
                          feedCompactNumber(_commentCount)),
                      _caseStat(theme, 'Likes',
                          feedCompactNumber(_likeCount)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          FeedEngagementStats(
            item: item,
            likeCount: _likeCount,
            repostCount: item.engagement.shares,
            contentType: 'case',
            refreshToken: _reactionRefresh,
            showReactionFaces: true,
          ),
          FeedActionRow(actions: [
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
              label: 'Repost',
              onTap: _repost,
            ),
            FeedActionButton(
              svgAsset: FeedIconAssets.send,
              label: 'Send',
              onTap: _share,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _caseStat(OneUITheme theme, String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: theme.caption.copyWith(fontSize: 9, letterSpacing: 0.4)),
            const SizedBox(height: 2),
            Text(value,
                style: theme.bodySecondary.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ─── Job ────────────────────────────────────────────────────────────────

class FeedJobCard extends StatelessWidget {
  final FeedItem item;
  const FeedJobCard(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final jobTitle = item.str('jobTitle') ?? 'Job opening';
    final company = item.str('companyName');
    final location = item.str('location');
    final salary = item.str('salaryRange');
    final image = item.str('image');
    final jobTypeRaw = item.str('jobType') ?? item.str('job_type');
    final jobTypeLabel = switch ((jobTypeRaw ?? '').toLowerCase()) {
      'full_time' || 'full-time' => 'Full-time',
      'part_time' || 'part-time' => 'Part-time',
      'contract' => 'Contract',
      'locum' => 'Locum',
      'internship' => 'Internship',
      '' => null,
      _ => jobTypeRaw,
    };

    void open() => JobsDetailsScreen(jobId: item.id).launch(context);

    return FeedCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedAuthorHeader(
            name: company ?? 'Company',
            avatarUrl: image,
            subtitle: 'Hiring · Verified employer',
            createdAt: item.createdAt,
            trailingBadge: 'Job',
            onTap: () => _openFeedAuthorProfile(context, item),
          ),
          const SizedBox(height: 10),
          Text(jobTitle, style: theme.titleSmall.copyWith(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            [company, location, jobTypeLabel]
                .where((e) => e != null && e.isNotEmpty)
                .join(' · '),
            style: theme.bodySecondary,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (salary != null && salary.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(salary,
                      style: theme.bodySecondary.copyWith(
                          color: theme.primary, fontWeight: FontWeight.w600)),
                ),
              const Spacer(),
              FeedAccentButton(label: 'Apply', onTap: open),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── CME ────────────────────────────────────────────────────────────────

class FeedCmeCard extends StatefulWidget {
  final FeedItem item;
  const FeedCmeCard(this.item, {super.key});

  @override
  State<FeedCmeCard> createState() => _FeedCmeCardState();
}

class _FeedCmeCardState extends State<FeedCmeCard> {
  bool _registering = false;
  late bool _registered;
  String? _registrationStatus;

  @override
  void initState() {
    super.initState();
    _registered = feedCmeIsRegistered(widget.item);
    _registrationStatus = widget.item.str('registrationStatus');
  }

  Future<void> _handleRegister() async {
    if (_registering || _registered) return;
    setState(() => _registering = true);
    try {
      await CmeNodeApiService.registerEvent(widget.item.id);
      if (!mounted) return;
      setState(() {
        _registering = false;
        _registered = true;
        _registrationStatus = 'registered';
      });
      toast('Registered for event');
    } catch (e) {
      if (!mounted) return;
      setState(() => _registering = false);
      toast('Could not register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final item = widget.item;
    final title = item.str('title') ?? 'CME event';
    final provider = item.str('organizationName') ?? item.str('eventType') ?? 'CME Provider';
    final credits = item.numOrNull('credits');
    final going = item.intVal('goingCount');
    final startDate = DateTime.tryParse(item.str('startDate') ?? '');

    void open() => CmeEventDetailScreen(eventId: item.id).launch(context);

    final registerLabel = _registered
        ? feedCmeRegistrationLabel(item, overrideStatus: _registrationStatus)
        : (_registering ? 'Registering…' : 'Register');

    return FeedCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedAuthorHeader(
            name: provider,
            avatarUrl: item.str('organizationLogoUrl'),
            subtitle: item.str('providerTagline') ?? 'ACCME-accredited provider',
            createdAt: item.createdAt,
            verified: item.flag('organizationVerified'),
            isPremium: false,
            trailingBadge: 'CME',
            onTap: () => _openFeedAuthorProfile(context, item),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: open,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (startDate != null)
                    Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.cardBackground,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text('${startDate.day}',
                              style: theme.titleMedium.copyWith(color: theme.primary)),
                          Text(_month(startDate.month),
                              style: theme.caption.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  if (startDate != null) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.titleSmall),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          children: [
                            if (credits != null)
                              Text('${credits % 1 == 0 ? credits.toInt() : credits} credit hrs',
                                  style: theme.caption),
                            if (going > 0)
                              Text('${feedCompactNumber(going)} registered', style: theme.caption),
                            if (_registered)
                              Text(
                                feedCmeRegistrationLabel(item, overrideStatus: _registrationStatus),
                                style: theme.caption.copyWith(
                                  color: theme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          FeedActionRow(actions: [
            const FeedActionButton(icon: Icons.star_outline, label: 'Interested'),
            FeedActionButton(
              icon: _registered ? Icons.check_circle_outline : Icons.event_available_outlined,
              label: registerLabel,
              onTap: _registered ? open : (_registering ? null : _handleRegister),
            ),
            FeedActionButton(icon: Icons.open_in_new, label: 'Details', onTap: open),
          ]),
        ],
      ),
    );
  }

  String _month(int m) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return (m >= 1 && m <= 12) ? months[m - 1] : '';
  }
}

// ─── Survey ──────────────────────────────────────────────────────────────

class FeedSurveyCard extends StatelessWidget {
  final FeedItem item;
  const FeedSurveyCard(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final title = item.str('title') ?? 'Survey';
    final org = item.str('organizationName');
    final questions = item.intVal('questionCount');
    final responses = item.intVal('responseCount');

    void open() => SurveyFillScreen(surveyId: item.id).launch(context);

    return FeedCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedAuthorHeader(
            name: org ?? 'Survey',
            avatarUrl: item.str('orgLogo'),
            subtitle: 'Sponsored research',
            createdAt: item.createdAt,
            trailingBadge: 'Survey',
            onTap: () => _openFeedAuthorProfile(context, item),
          ),
          const SizedBox(height: 10),
          Text(title, style: theme.titleSmall.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            [
              if (questions > 0) '$questions questions',
              if (responses > 0) '${feedCompactNumber(responses)} responses',
            ].join(' · '),
            style: theme.caption,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Anonymous', style: theme.caption),
              const Spacer(),
              FeedAccentButton(label: 'Respond', onTap: open),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Group post ───────────────────────────────────────────────────────────

class FeedGroupPostCard extends StatefulWidget {
  final FeedItem item;
  final HomeBloc? homeBloc;
  final VoidCallback? onFeedChanged;

  const FeedGroupPostCard(
    this.item, {
    super.key,
    this.homeBloc,
    this.onFeedChanged,
  });

  @override
  State<FeedGroupPostCard> createState() => _FeedGroupPostCardState();
}

class _FeedGroupPostCardState extends State<FeedGroupPostCard> {
  late String? _reaction = widget.item.str('userReaction') ??
      (widget.item.flag('likedByMe') ? 'like' : null);
  late int _likeCount = widget.item.engagement.likes;
  late int _commentCount = widget.item.engagement.comments;
  late int _repostCount = widget.item.engagement.shares;
  late bool _reposted = _feedUserReposted(widget.item);
  bool _reposting = false;
  int _reactionRefresh = 0;

  String get _postId => _groupPostReactionId(widget.item);

  bool get _hasPostId => int.tryParse(_postId) != null;

  Future<void> _openComments() async {
    final postId = _groupPostIdInt(widget.item);
    if (postId != null) {
      final count = await showFeedCommentSheet(
        context,
        postId: postId,
        homeBloc: widget.homeBloc,
        onCommentCountChanged: (c) {
          if (mounted) setState(() => _commentCount = c);
        },
      );
      if (!mounted) return;
      if (count != null) setState(() => _commentCount = count);
      widget.onFeedChanged?.call();
    }
  }

  Future<void> _onReact(String? type) async {
    if (!_hasPostId) return;
    final previous = _reaction;
    final prevLike = _likeCount;
    final has = type != null;
    final had = previous != null;
    var nextLike = prevLike;
    if (has && !had) nextLike += 1;
    if (!has && had) nextLike -= 1;
    if (nextLike < 0) nextLike = 0;

    FeedEngagementStats.applyLocalReactionChange(
      contentType: 'group_post',
      itemId: widget.item.id,
      previousType: previous,
      newType: type,
      likeCount: nextLike,
    );

    setState(() {
      _reaction = type;
      _likeCount = nextLike;
      _reactionRefresh++;
    });
    final toSend = type ?? previous ?? 'like';
    widget.onFeedChanged?.call();
    final res = await SharedApiService().reactToPost(postId: _postId, reaction: toSend);
    if (!mounted) return;
    if (res.success) {
      _applyReactionApiResult(
        setState: setState,
        previousReaction: previous,
        previousLikeCount: _likeCount,
        contentType: 'group_post',
        itemId: widget.item.id,
        data: res.data,
        onSync: (reaction, likes, bump) {
          setState(() {
            _reaction = reaction;
            _likeCount = likes;
            _reactionRefresh += bump;
          });
        },
      );
      widget.onFeedChanged?.call();
      return;
    }
    FeedEngagementStats.applyLocalReactionChange(
      contentType: 'group_post',
      itemId: widget.item.id,
      previousType: type,
      newType: previous,
      likeCount: prevLike,
    );
    setState(() {
      _reaction = previous;
      _likeCount = prevLike;
      _reactionRefresh++;
    });
    toast(res.message ?? 'Failed to update reaction');
  }

  Future<void> _toggleRepost() async {
    if (!_hasPostId || _reposting) return;
    setState(() {
      _reposting = true;
      _reposted = !_reposted;
      if (_reposted) {
        _repostCount += 1;
      } else if (_repostCount > 0) {
        _repostCount -= 1;
      }
    });
    final res = await SharedApiService().repostPost(postId: _postId);
    if (!mounted) return;
    setState(() {
      _reposting = false;
      final reposted = res.data?['reposted'];
      if (reposted is bool) _reposted = reposted;
      final reposts = res.data?['reposts'];
      if (reposts is num) _repostCount = reposts.toInt();
    });
    if (res.success) {
      toast(_reposted ? 'Reposted' : 'Repost removed');
      widget.onFeedChanged?.call();
    }
  }

  void _share() {
    final postId = _groupPostIdInt(widget.item);
    if (postId == null) return;
    DeepLinkService.sharePost(
      postId: postId,
      title: widget.item.str('title') ?? widget.item.str('content'),
    );
    SharedApiService().recordShare(postId: _postId);
  }

  void _openArticle() {
    final postId = _groupPostIdInt(widget.item);
    if (postId != null) {
      PostArticleDetailScreen(postId: postId).launch(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final item = widget.item;
    final title = item.str('title');
    final content = item.str('content') ?? item.str('body');
    final groupName = item.str('groupName') ?? 'Group';
    final posterName = item.str('authorName') ?? 'Member';
    final isArticle = feedItemIsArticle(item);
    final typeBadge = isArticle ? 'Article' : _groupPostTypeBadge(item);

    return FeedCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedGroupPostHeader(
            groupName: groupName,
            groupLogoUrl: item.str('groupLogo'),
            posterName: posterName,
            posterAvatarUrl: item.str('authorAvatar'),
            createdAt: item.createdAt,
            posterVerified: item.flag('posterVerified'),
            posterPremium: item.flag('authorPremium') || item.flag('posterPremium'),
            trailingBadge: typeBadge,
            onGroupTap: () => _openFeedGroup(context, item),
            onPosterTap: () => _openFeedGroupPosterProfile(context, item),
          ),
          if (item.flag('isPinned') || item.flag('isAnnouncement'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (item.flag('isPinned'))
                    const FeedBadge(label: 'Pinned', color: Color(0xFF16A34A)),
                  if (item.flag('isAnnouncement'))
                    const FeedBadge(label: 'Announcement', color: Color(0xFFD97706)),
                ],
              ),
            ),
          if (isArticle)
            FeedArticleContent(
              item: item,
              onOpen: _openArticle,
              resolveMediaUrl: _resolveFeedMediaUrl,
            )
          else ...[
            if (title != null && title.isNotEmpty && title.trim() != (content ?? '').trim())
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(title, style: theme.titleSmall.copyWith(fontSize: 16)),
              ),
            if (content != null && content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: ExpandablePostText(
                  text: content,
                  style: theme.bodyMedium,
                  collapsedMaxLines: 4,
                ),
              )
            else if (title != null && title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ExpandablePostText(
                  text: title,
                  style: theme.bodyMedium.copyWith(fontSize: 15),
                  collapsedMaxLines: 4,
                ),
              ),
            RepaintBoundary(child: _FeedPostMedia(item)),
          ],
          FeedEngagementStats(
            item: item,
            likeCount: _likeCount,
            repostCount: _repostCount,
            commentCount: _commentCount,
            contentType: 'group_post',
            refreshToken: _reactionRefresh,
            showReactionFaces: true,
            reactionsContentId: _postId,
            reactionsContentType: 'post',
          ),
          FeedActionRow(actions: [
            FeedReactionAction(
              currentReaction: _reaction,
              onChanged: _onReact,
            ),
            FeedActionButton(
              svgAsset: FeedIconAssets.comment,
              label: 'Comment',
              onTap: _hasPostId ? _openComments : null,
            ),
            FeedActionButton(
              svgAsset: FeedIconAssets.repost,
              label: _reposted ? 'Reposted' : 'Repost',
              active: _reposted,
              onTap: _hasPostId ? _toggleRepost : null,
            ),
            FeedActionButton(
              svgAsset: FeedIconAssets.send,
              label: 'Send',
              onTap: _hasPostId ? _share : null,
            ),
          ]),
        ],
      ),
    );
  }
}
