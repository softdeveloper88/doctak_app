import 'dart:convert';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart'
    show Commenter, resolveCommentProfilePic;

ReplyCommentModel replyCommentModelFromJson(String str) => ReplyCommentModel.fromJson(json.decode(str));
String replyCommentModelToJson(ReplyCommentModel data) => json.encode(data.toJson());

class ReplyCommentModel {
  ReplyCommentModel({this.success, this.pagination, this.comments});

  ReplyCommentModel.fromJson(dynamic json) {
    success = json['success'];
    pagination = json['pagination'] != null ? Pagination.fromJson(json['pagination']) : null;
    if (json['comments'] != null) {
      comments = [];
      json['comments'].forEach((v) {
        comments?.add(CommentsModel.fromJson(v));
      });
    }
  }
  bool? success;
  Pagination? pagination;
  List<CommentsModel>? comments;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (pagination != null) {
      map['pagination'] = pagination?.toJson();
    }
    if (comments != null) {
      map['comments'] = comments?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

CommentsModel commentsFromJson(String str) => CommentsModel.fromJson(json.decode(str));
String commentsToJson(CommentsModel data) => json.encode(data.toJson());

class CommentsModel {
  CommentsModel({this.id, this.commentableId, this.commenterId, this.comment, this.createdAt, this.likeCount, this.userHasLiked, this.commenter});

  CommentsModel.fromJson(dynamic json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    commentableId = json['commentable_id']?.toString();
    commenterId = json['commenter_id']?.toString();
    comment = json['comment'] ?? json['body'] ?? json['reply'];
    createdAt = json['created_at'];
    likeCount = _parseReplyLikeCount(json);
    userHasLiked = _parseReplyUserHasLiked(json['user_has_liked']);
    commenter = json['commenter'] != null ? ReplyCommenter.fromJson(json['commenter']) : null;
  }
  int? id;
  String? commentableId;
  String? commenterId;
  String? comment;
  String? createdAt;
  int? likeCount;
  bool? userHasLiked;
  ReplyCommenter? commenter;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['commentable_id'] = commentableId;
    map['commenter_id'] = commenterId;
    map['comment'] = comment;
    map['created_at'] = createdAt;
    map['like_count'] = likeCount;
    map['user_has_liked'] = userHasLiked;
    if (commenter != null) {
      map['commenter'] = commenter?.toJson();
    }
    return map;
  }
}

ReplyCommenter commenterFromJson(String str) => ReplyCommenter.fromJson(json.decode(str));
String commenterToJson(ReplyCommenter data) => json.encode(data.toJson());

class ReplyCommenter {
  ReplyCommenter({this.name, this.profilePic, this.specialty, this.isVerified});

  ReplyCommenter.fromJson(dynamic json) {
    name = json['name']?.toString();
    if (name == null || name!.trim().isEmpty) {
      final fn = json['first_name']?.toString() ?? '';
      final ln = json['last_name']?.toString() ?? '';
      name = '$fn $ln'.trim();
    }
    profilePic = resolveCommentProfilePic(json);
    specialty = json['specialty']?.toString() ?? json['specialization']?.toString();
    isVerified = Commenter.parseCommenterVerified(json);
  }
  String? name;
  String? profilePic;
  String? specialty;
  bool? isVerified;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['profile_pic'] = profilePic;
    map['specialty'] = specialty;
    map['is_verified'] = isVerified;
    return map;
  }
}

int? _parseReplyLikeCount(dynamic json) {
  if (json is! Map) return null;
  final raw = json['like_count'] ?? json['reaction_count'] ?? json['likes'];
  if (raw == null) return null;
  return int.tryParse(raw.toString());
}

bool? _parseReplyUserHasLiked(dynamic raw) {
  if (raw == null) return false;
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final s = raw.toString().toLowerCase();
  return s == 'true' || s == '1';
}

Pagination paginationFromJson(String str) => Pagination.fromJson(json.decode(str));
String paginationToJson(Pagination data) => json.encode(data.toJson());

class Pagination {
  Pagination({this.total, this.perPage, this.currentPage, this.lastPage, this.nextPageUrl, this.prevPageUrl});

  Pagination.fromJson(dynamic json) {
    total = json['total'];
    perPage = json['per_page'];
    currentPage = json['current_page'];
    lastPage = json['last_page'];
    nextPageUrl = json['next_page_url'];
    prevPageUrl = json['prev_page_url'];
  }
  int? total;
  int? perPage;
  int? currentPage;
  int? lastPage;
  String? nextPageUrl;
  dynamic prevPageUrl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['total'] = total;
    map['per_page'] = perPage;
    map['current_page'] = currentPage;
    map['last_page'] = lastPage;
    map['next_page_url'] = nextPageUrl;
    map['prev_page_url'] = prevPageUrl;
    return map;
  }
}
