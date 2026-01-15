import 'dart:convert';

import 'package:doctak_app/data/models/post_model/post_data_model.dart';

PostDetailModel postDetailModelFromJson(String str) => PostDetailModel.fromJson(json.decode(str));
String postDetailModelToJson(PostDetailModel data) => json.encode(data.toJson());

class PostDetailModel {
  PostDetailModel({this.post});

  PostDetailModel.fromJson(dynamic json) {
    post = json['post'] != null ? Post.fromJson(json['post']) : null;
  }
  Post? post;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (post != null) {
      map['post'] = post?.toJson();
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
