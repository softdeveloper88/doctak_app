import 'dart:convert';

import 'package:doctak_app/data/models/post_model/post_data_model.dart';
PostDetailModel postDetailModelFromJson(String str) => PostDetailModel.fromJson(json.decode(str));
String postDetailModelToJson(PostDetailModel data) => json.encode(data.toJson());
class PostDetailModel {
  PostDetailModel({
      this.post,});

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
