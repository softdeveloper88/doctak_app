import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/data/models/group_model/group_enhanced_models.dart';

/// Maps enhanced group feed entries to [FeedItem] for home-feed card widgets.
class GroupFeedMapper {
  static List<FeedItem> mapEntries(
    List<GroupFeedEntryModel> entries,
    GroupDetailModel group,
  ) {
    return entries
        .map((e) => mapEntry(e, group))
        .whereType<FeedItem>()
        .toList();
  }

  static FeedItem? mapEntry(GroupFeedEntryModel entry, GroupDetailModel group) {
    if (entry.kind == 'poll' && entry.poll != null) {
      return _mapPoll(entry.poll!, group, entry.createdAt);
    }
    if (entry.post != null) {
      return _mapPost(entry.post!, group, entry.createdAt);
    }
    return null;
  }

  static FeedItem _mapPost(
    GroupFeedPostModel post,
    GroupDetailModel group,
    String createdAt,
  ) {
    final groupId = group.routeId;
    final mediaFiles = post.media
        .map((m) => {
              'url': AppData.fullImageUrl(m.url ?? m.mediaPath),
              'type': m.mediaType ?? 'image',
            })
        .where((m) => (m['url'] as String).isNotEmpty)
        .toList();

    final postType = (post.postType ?? '').toLowerCase();
    final isBlog = postType == 'blog' || postType == 'article';
    final body = post.body ?? post.caption ?? '';
    final resolvedPostType = post.postType ??
        (mediaFiles.any((f) => f['type'] == 'video')
            ? 'video'
            : mediaFiles.isNotEmpty
                ? 'photo'
                : 'text');

    return FeedItem(
      type: 'group_post',
      id: post.postId.isNotEmpty ? post.postId : post.id,
      createdAt: post.createdAt ?? createdAt,
      authorId: groupId,
      engagement: FeedEngagement(
        likes: post.likesCount,
        comments: post.commentsCount,
      ),
      payload: {
        'postId': post.postId,
        'title': post.title,
        'body': body,
        'content': body,
        'excerpt': post.caption ?? body,
        'postType': resolvedPostType,
        'mediaFiles': mediaFiles,
        'image': mediaFiles.isNotEmpty ? mediaFiles.first['url'] : null,
        'coverImage': mediaFiles.isNotEmpty ? mediaFiles.first['url'] : null,
        'mediaUrl': mediaFiles.isNotEmpty ? mediaFiles.first['url'] : null,
        'mediaCount': mediaFiles.length,
        'groupId': groupId,
        'groupName': group.name,
        'groupLogo': AppData.fullImageUrl(group.logoImage),
        'groupPostId': post.postId,
        'groupPostEntryId': post.id,
        'groupHref': '/groups/$groupId',
        'authorName': post.author?.name,
        'authorAvatar': AppData.fullImageUrl(post.author?.avatar),
        'authorUserId': post.author?.id,
        'posterName': post.author?.name,
        'posterAvatar': AppData.fullImageUrl(post.author?.avatar),
        'posterUserId': post.author?.id,
        'posterVerified': post.author?.verified == true,
        'authorVerified': post.author?.verified == true,
        'likedByMe': post.likedByMe,
        'userReaction': post.likedByMe ? 'like' : null,
        'isPinned': post.isPinned,
        'isAnnouncement': post.isAnnouncement,
        'isGroupPagePost': true,
        if (isBlog && post.caption?.trim().isNotEmpty == true) 'displayBody': post.caption,
      },
    );
  }

  static FeedItem _mapPoll(
    GroupPollModel poll,
    GroupDetailModel group,
    String createdAt,
  ) {
    final groupId = group.routeId;
    final postId = poll.id;
    final voteCounts = poll.options.map((o) => o.votes).toList();
    final totalVoters = poll.totalVotes > 0
        ? poll.totalVotes
        : voteCounts.fold<int>(0, (sum, c) => sum + c);
    final userVotedIndices = (poll.myVote ?? [])
        .map((id) => poll.options.indexWhere((o) => o.id == id))
        .where((i) => i >= 0)
        .toList();

    return FeedItem(
      type: 'group_post',
      id: postId,
      createdAt: poll.createdAt ?? createdAt,
      authorId: groupId,
      engagement: const FeedEngagement(),
      payload: {
        'postId': postId,
        'title': poll.title,
        'body': poll.description ?? '',
        'content': poll.description ?? '',
        'postType': 'poll',
        'groupId': groupId,
        'groupName': group.name,
        'groupLogo': AppData.fullImageUrl(group.logoImage),
        'groupPollId': poll.id,
        'groupPostId': postId,
        'groupPostEntryId': 'group-poll-${poll.id}',
        'groupHref': '/groups/$groupId',
        'isGroupPagePost': true,
        'authorName': poll.author?.name,
        'authorAvatar': poll.author?.avatar,
        'authorUserId': poll.author?.id,
        'posterName': poll.author?.name,
        'posterAvatar': poll.author?.avatar,
        'posterUserId': poll.author?.id,
        'poll': {
          'pollId': poll.id,
          'description': poll.description,
          'options': poll.options.map((o) => o.label).toList(),
          'optionIds': poll.options.map((o) => o.id).toList(),
          'isMultipleChoice': poll.allowMultipleSelections,
          'showVoters': true,
          'isAnonymous': false,
          'voteCounts': voteCounts,
          'totalVoters': totalVoters,
          'userVotedIndex': userVotedIndices.isNotEmpty ? userVotedIndices.first : null,
          'userVotedIndices': userVotedIndices,
        },
      },
    );
  }
}
