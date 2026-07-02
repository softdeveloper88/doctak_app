import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/data/models/organization_profile/organization_public_profile_model.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/core/utils/specialty_display.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_widget/find_likes.dart';

/// Maps legacy [Post] API rows into [FeedItem] so profile/search reuse the
/// same feed card UI as the home screen.
class PostFeedAdapter {
  PostFeedAdapter._();

  static String? _stripHtml(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (!s.contains('<')) return s;
    return s
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? _normalizePrivacy(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty || value == 'globe') return 'public';
    return value;
  }

  static String? _userReaction(Post post) {
    if (!findIsLiked(post.likes)) return null;
    return 'like';
  }

  static List<Map<String, dynamic>> _mediaFiles(Post post) {
    final files = <Map<String, dynamic>>[];
    final seen = <String>{};

    void addFile(String path, String type) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) return;
      final url = trimmed.startsWith('http://') || trimmed.startsWith('https://')
          ? trimmed
          : AppData.fullImageUrl(trimmed);
      if (url.isEmpty || seen.contains(url)) return;
      seen.add(url);
      files.add({'type': type, 'url': url});
    }

    for (final m in post.media ?? const <Media>[]) {
      final path = m.mediaPath?.trim();
      if (path == null || path.isEmpty) continue;
      addFile(path, (m.mediaType ?? 'image').toLowerCase());
    }

    final image = post.image?.toString().trim();
    if (image != null && image.isNotEmpty) {
      addFile(image, 'image');
    }

    return files;
  }

  static List<String> _hashtagsFromText(String? text) {
    if (text == null || text.isEmpty) return const [];
    final seen = <String>{};
    final out = <String>[];
    for (final match in RegExp(r'#([\w\u0600-\u06FF]+)').allMatches(text)) {
      final token = match.group(1)?.trim();
      if (token == null || token.isEmpty) continue;
      final key = token.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(token);
      if (out.length >= 5) break;
    }
    return out;
  }

  static String? _tagsString(Post post) {
    final tags = <String>[
      ..._hashtagsFromText(_stripHtml(post.body)),
      ..._hashtagsFromText(_stripHtml(post.title)),
    ];
    if (tags.isEmpty) return null;
    final seen = <String>{};
    final unique = <String>[];
    for (final tag in tags) {
      final key = tag.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      unique.add(tag);
      if (unique.length >= 5) break;
    }
    return unique.join(' ');
  }

  static Map<String, dynamic>? _pollPayload(Post post) {
    final poll = post.poll;
    if (poll == null || poll.isEmpty) return null;

    final options = (poll['options'] as List?)?.map((e) => '$e').toList() ?? [];
    if (options.isEmpty) return null;

    return {
      'pollId': poll['pollId']?.toString() ?? '',
      'description': poll['description'],
      'options': options,
      'optionIds':
          (poll['optionIds'] as List?)?.map((e) => '$e').toList() ?? [],
      'endsAt': poll['endsAt'],
      'isMultipleChoice': poll['isMultipleChoice'] == true,
      'showVoters': poll['showVoters'] != false,
      'isAnonymous': poll['isAnonymous'] == true,
      'allowAddOptions': poll['allowAddOptions'] == true,
      'allowChangeVote': poll['allowChangeVote'] == true,
      'voteCounts': (poll['voteCounts'] as List?)
              ?.map((e) => e is num ? e.toInt() : int.tryParse('$e') ?? 0)
              .toList() ??
          List<int>.filled(options.length, 0),
      'totalVoters': poll['totalVoters'] is num
          ? (poll['totalVoters'] as num).toInt()
          : int.tryParse('${poll['totalVoters'] ?? 0}') ?? 0,
      'userVotedIndex': poll['userVotedIndex'],
      'userVotedIndices': poll['userVotedIndices'] ??
          (poll['userVotedIndex'] is num
              ? [poll['userVotedIndex']]
              : const <int>[]),
    };
  }

  static FeedItem fromPost(Post post) {
    final user = post.user;
    final location = [user?.city, user?.state, user?.country]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString().trim())
        .join(', ');

    final title = _stripHtml(post.title);
    final bodyRaw = _stripHtml(post.body);
    final rawType = (post.postType ?? post.meta?.type ?? 'post').toLowerCase();
    final isPoll = rawType == 'poll';
    final isBlog = rawType == 'blog' || rawType == 'article';
    final postType = isBlog ? rawType : (post.postType ?? 'post');

    String? body;
    if (isPoll) {
      final pollDesc = post.poll?['description']?.toString().trim();
      if (bodyRaw != null &&
          bodyRaw.isNotEmpty &&
          bodyRaw.trim() != (title ?? '').trim()) {
        body = bodyRaw;
      } else if (pollDesc != null && pollDesc.isNotEmpty) {
        body = pollDesc;
      }
    } else {
      body = bodyRaw ?? title;
    }
    final mediaFiles = _mediaFiles(post);
    final likes = post.likes?.length ?? 0;
    final comments = post.comments?.length ?? 0;
    final views = post.views ?? 0;

    final useOrgAuthor = post.isBusinessPagePost == true ||
        (post.organizationId != null && post.organizationId!.isNotEmpty);
    final authorPayload = {
      'authorName': useOrgAuthor
          ? (post.authorName ?? user?.name ?? 'Organization')
          : (user?.name ?? 'Member'),
      'authorAvatar': useOrgAuthor
          ? post.authorAvatar ?? user?.profilePic
          : user?.profilePic,
      'authorSpecialty': useOrgAuthor ? null : displaySpecialty(user?.specialty),
      'authorLocation': useOrgAuthor || location.isEmpty ? null : location,
      'authorVerified':
          useOrgAuthor ? (post.authorVerified == true) : (user?.isVerified == true),
      'userReaction': _userReaction(post),
      if (useOrgAuthor && post.organizationId != null)
        'organizationId': post.organizationId,
      if (useOrgAuthor && post.organizationSlug != null)
        'organizationSlug': post.organizationSlug,
      if (useOrgAuthor) 'accountType': 'business',
      if (useOrgAuthor) 'isBusinessPagePost': true,
      if (post.userId != null) 'ownerUserId': '${post.userId}',
    };

    if (isBlog) {
      final excerpt = (body ?? '').length > 260
          ? '${body!.substring(0, 260).trim()}…'
          : body;
      return FeedItem(
        type: 'blog',
        id: '${post.id ?? 0}',
        createdAt: post.createdAt,
        authorId: post.userId ?? user?.id,
        engagement: FeedEngagement(
          likes: likes,
          comments: comments,
          shares: 0,
          views: views,
        ),
        payload: {
          ...authorPayload,
          'title': title,
          'excerpt': excerpt,
          'coverImage': mediaFiles.isNotEmpty ? mediaFiles.first['url'] : null,
          'reposted': false,
        },
      );
    }

    final tags = post.tags ?? _tagsString(post);
    final displayTitle = post.displayTitle;
    final displayBody = post.displayBody;
    final primaryMedia = mediaFiles.isNotEmpty ? mediaFiles.first : null;

    return FeedItem(
      type: 'post',
      id: '${post.id ?? 0}',
      createdAt: post.createdAt,
      authorId: post.userId ?? user?.id,
      engagement: FeedEngagement(
        likes: likes,
        comments: comments,
        shares: 0,
        views: views,
      ),
      payload: {
        ...authorPayload,
        'title': title,
        'body': body,
        if (displayTitle != null) 'displayTitle': displayTitle,
        if (displayBody != null) 'displayBody': displayBody,
        if (post.highlightHashtagsInBody != null)
          'highlightHashtagsInBody': post.highlightHashtagsInBody,
        'postType': postType,
        'privacy': _normalizePrivacy(post.privacy),
        if (tags != null) 'tags': tags,
        'poll': _pollPayload(post),
        'reposted': false,
        'mediaFiles': mediaFiles,
        if (mediaFiles.isNotEmpty) ...{
          'mediaUrl': primaryMedia?['url'],
          'mediaType': primaryMedia?['type'],
          'mediaCount': mediaFiles.length,
          'image': mediaFiles.firstWhere(
            (m) => m['type'] == 'image',
            orElse: () => mediaFiles.first,
          )['url'],
        },
      },
    );
  }

  /// Maps organization public-profile post summaries into legacy [Post] rows so
  /// org profile tabs can reuse [PostFeedListView] / [FeedPostCard].
  static Post organizationPostToPost(
    OrganizationPostSummary summary,
    OrganizationSummary organization,
  ) {
    final media = <Media>[];
    final seen = <String>{};

    void addMedia(String? path, String? type) {
      final resolved = _resolvedMediaUrl(path);
      if (resolved == null || seen.contains(resolved)) return;
      seen.add(resolved);
      media.add(Media(mediaPath: resolved, mediaType: type ?? 'image'));
    }

    for (final file in summary.resolvedMediaFiles) {
      addMedia(file.url, file.type);
    }
    for (final url in summary.mediaUrls) {
      addMedia(url, summary.mediaType);
    }
    addMedia(summary.mediaUrl, summary.mediaType);

    final likesCount = summary.likesCount.clamp(0, 10000);
    final commentsCount = summary.commentsCount.clamp(0, 10000);

    return Post(
      id: int.tryParse(summary.id),
      userId: summary.userId,
      title: summary.title,
      body: summary.body,
      createdAt: summary.createdAt,
      privacy: summary.privacy,
      organizationId: organization.id,
      organizationSlug: organization.slug,
      accountType: 'business',
      authorName: organization.name,
      authorAvatar: organization.logoUrl,
      authorVerified: organization.isVerified,
      isBusinessPagePost: true,
      image: summary.mediaUrl,
      media: media.isEmpty ? null : media,
      likes: likesCount > 0 ? List<Likes>.filled(likesCount, Likes()) : null,
      comments: commentsCount > 0
          ? List<Comments>.filled(commentsCount, Comments())
          : null,
    );
  }

  static String? _resolvedMediaUrl(String? path) {
    if (path == null) return null;
    final resolved = AppData.fullImageUrl(path.trim());
    return resolved.isEmpty ? null : resolved;
  }
}
