import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/data/models/post_comment_model/reply_comment_model.dart';
import 'package:doctak_app/presentation/case_discussion/models/case_discussion_models.dart';

PostComments postCommentFromJson(Map<String, dynamic> json) {
  return PostComments.fromJson(json);
}

PostComments caseCommentToPostComments(CaseComment comment) {
  final nameParts = comment.author.name.trim().split(' ');
  return PostComments(
    id: comment.id,
    comment: comment.comment,
    createdAt: comment.createdAt.toIso8601String(),
    userHasLiked: comment.isLiked,
    reactionCount: comment.likes,
    replyCount: comment.repliesCount,
    commenter: Commenter(
      id: comment.author.id,
      firstName: nameParts.isNotEmpty ? nameParts.first : '',
      lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      profilePic: AppData.fullImageUrl(comment.author.profilePic),
    ),
  );
}

CommentsModel caseReplyToCommentsModel(CaseReply reply) {
  return CommentsModel(
    id: reply.id,
    commentableId: reply.commentId.toString(),
    commenterId: reply.userId.toString(),
    comment: reply.reply,
    createdAt: reply.createdAt.toIso8601String(),
    likeCount: reply.likes,
    userHasLiked: reply.isLiked,
    commenter: ReplyCommenter(
      name: reply.author.name,
      profilePic: AppData.fullImageUrl(reply.author.profilePic),
    ),
  );
}

CommentsModel blogReplyToCommentsModel(Map<String, dynamic> json) {
  final commenter = json['commenter'];
  return CommentsModel(
    id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
    commentableId: null,
    commenterId: commenter is Map ? commenter['id']?.toString() : null,
    comment: (json['comment'] ?? json['body'])?.toString(),
    createdAt: json['created_at']?.toString(),
    likeCount: json['like_count'] != null
        ? int.tryParse(json['like_count'].toString())
        : (json['reaction_count'] != null
            ? int.tryParse(json['reaction_count'].toString())
            : null),
    userHasLiked: json['user_has_liked'] == true ||
        json['user_has_liked'] == 1 ||
        '${json['user_has_liked']}'.toLowerCase() == 'true',
    commenter: commenter is Map ? ReplyCommenter.fromJson(commenter) : null,
  );
}
