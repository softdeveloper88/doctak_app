import 'dart:convert';
PostCommentModel postCommentModelFromJson(String str) => PostCommentModel.fromJson(json.decode(str));
String postCommentModelToJson(PostCommentModel data) => json.encode(data.toJson());
class PostCommentModel {
  PostCommentModel({
      this.postComments,});

  PostCommentModel.fromJson(dynamic json) {
    if (json['postComments'] != null) {
      postComments = [];
      json['postComments'].forEach((v) {
        postComments?.add(PostComments.fromJson(v));
      });
    }
  }
  List<PostComments>? postComments;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (postComments != null) {
      map['postComments'] = postComments?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

PostComments postCommentsFromJson(String str) => PostComments.fromJson(json.decode(str));
String postCommentsToJson(PostComments data) => json.encode(data.toJson());
class PostComments {
  PostComments({
      this.id, 
      this.userId, 
      this.postId, 
      this.comment, 
      this.createdAt, 
      this.updatedAt, 
      this.profilePic, 
      this.name,});

  PostComments.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    postId = json['post_id'];
    comment = json['comment'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    profilePic = json['profile_pic'];
    name = json['name'];
  }
  int? id;
  String? userId;
  String? postId;
  String? comment;
  String? createdAt;
  String? updatedAt;
  String? profilePic;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['post_id'] = postId;
    map['comment'] = comment;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['profile_pic'] = profilePic;
    map['name'] = name;
    return map;
  }

}