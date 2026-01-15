import 'dart:convert';

import 'post_data_model.dart';

PostDetailsDataModel postDetailsDataModelFromJson(String str) => PostDetailsDataModel.fromJson(json.decode(str));
String postDetailsDataModelToJson(PostDetailsDataModel data) => json.encode(data.toJson());

class PostDetailsDataModel {
  PostDetailsDataModel({this.post, this.specificComment});

  PostDetailsDataModel.fromJson(dynamic json) {
    post = json['post'] != null ? Post.fromJson(json['post']) : null;
    specificComment = json['specificComment'] != null ? SpecificComment.fromJson(json['specificComment']) : null;
  }
  Post? post;
  SpecificComment? specificComment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (post != null) {
      map['post'] = post?.toJson();
    }
    if (specificComment != null) {
      map['specificComment'] = specificComment?.toJson();
    }
    return map;
  }
}

SpecificComment specificCommentFromJson(String str) => SpecificComment.fromJson(json.decode(str));
String specificCommentToJson(SpecificComment data) => json.encode(data.toJson());

class SpecificComment {
  SpecificComment({this.id, this.userId, this.postId, this.comment, this.createdAt, this.updatedAt, this.commenterName, this.commenterProfilePic});

  SpecificComment.fromJson(dynamic json) {
    id = json['id'];
    userId = json['userId'];
    postId = json['postId'];
    comment = json['comment'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    commenterName = json['commenterName'];
    commenterProfilePic = json['commenterProfilePic'];
  }
  int? id;
  String? userId;
  String? postId;
  String? comment;
  String? createdAt;
  String? updatedAt;
  String? commenterName;
  String? commenterProfilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['userId'] = userId;
    map['postId'] = postId;
    map['comment'] = comment;
    map['createdAt'] = createdAt;
    map['updatedAt'] = updatedAt;
    map['commenterName'] = commenterName;
    map['commenterProfilePic'] = commenterProfilePic;
    return map;
  }
}
