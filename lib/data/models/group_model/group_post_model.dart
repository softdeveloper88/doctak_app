import 'dart:convert';

GroupPostModel groupPostModelFromJson(String str) => GroupPostModel.fromJson(json.decode(str));
String groupPostModelToJson(GroupPostModel data) => json.encode(data.toJson());

class GroupPostModel {
  GroupPostModel({this.posts, this.offset});

  GroupPostModel.fromJson(dynamic json) {
    if (json['posts'] != null) {
      posts = [];
      json['posts'].forEach((v) {
        posts?.add(Posts.fromJson(v));
      });
    }
    offset = json['offset'];
  }
  List<Posts>? posts;
  int? offset;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (posts != null) {
      map['posts'] = posts?.map((v) => v.toJson()).toList();
    }
    map['offset'] = offset;
    return map;
  }
}

Posts postsFromJson(String str) => Posts.fromJson(json.decode(str));
String postsToJson(Posts data) => json.encode(data.toJson());

class Posts {
  Posts({this.id, this.title, this.createdAt, this.feelings, this.tagging, this.privacy, this.media, this.likesCount, this.commentsCount});

  Posts.fromJson(dynamic json) {
    id = json['id'];
    title = json['title'];
    createdAt = json['created_at'];
    feelings = json['feelings'];
    tagging = json['tagging'];
    privacy = json['privacy'];
    media = json['media'] != null ? json['media'].cast<String>() : [];
    likesCount = json['likes_count'];
    commentsCount = json['comments_count'];
  }
  int? id;
  dynamic title;
  String? createdAt;
  dynamic feelings;
  String? tagging;
  String? privacy;
  List<String>? media;
  int? likesCount;
  int? commentsCount;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['title'] = title;
    map['created_at'] = createdAt;
    map['feelings'] = feelings;
    map['tagging'] = tagging;
    map['privacy'] = privacy;
    map['media'] = media;
    map['likes_count'] = likesCount;
    map['comments_count'] = commentsCount;
    return map;
  }
}
