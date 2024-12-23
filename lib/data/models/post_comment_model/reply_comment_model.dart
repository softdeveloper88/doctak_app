import 'dart:convert';
ReplyCommentModel replyCommentModelFromJson(String str) => ReplyCommentModel.fromJson(json.decode(str));
String replyCommentModelToJson(ReplyCommentModel data) => json.encode(data.toJson());
class ReplyCommentModel {
  ReplyCommentModel({
      this.success, 
      this.pagination, 
      this.comments,});

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
  CommentsModel({
      this.id, 
      this.commentableId, 
      this.commenterId, 
      this.comment, 
      this.createdAt, 
      this.likeCount, 
      this.userHasLiked, 
      this.commenter,});

  CommentsModel.fromJson(dynamic json) {
    id = json['id'];
    commentableId = json['commentable_id'];
    commenterId = json['commenter_id'];
    comment = json['comment'];
    createdAt = json['created_at'];
    likeCount = json['like_count'];
    userHasLiked = json['user_has_liked'];
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
  ReplyCommenter({
      this.name, 
      this.profilePic,});

  ReplyCommenter.fromJson(dynamic json) {
    name = json['name'];
    profilePic = json['profile_pic'];
  }
  String? name;
  String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = name;
    map['profile_pic'] = profilePic;
    return map;
  }

}

Pagination paginationFromJson(String str) => Pagination.fromJson(json.decode(str));
String paginationToJson(Pagination data) => json.encode(data.toJson());
class Pagination {
  Pagination({
      this.total, 
      this.perPage, 
      this.currentPage, 
      this.lastPage, 
      this.nextPageUrl, 
      this.prevPageUrl,});

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