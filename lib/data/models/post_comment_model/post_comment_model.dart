import 'dart:convert';

PostCommentModel postCommentModelFromJson(String str) => PostCommentModel.fromJson(json.decode(str));
String postCommentModelToJson(PostCommentModel data) => json.encode(data.toJson());

class PostCommentModel {
  PostCommentModel({this.success, this.comments});

  PostCommentModel.fromJson(dynamic json) {
    success = json['success'];
    comments = json['comments'] != null ? Comments.fromJson(json['comments']) : null;
  }
  bool? success;
  Comments? comments;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (comments != null) {
      map['comments'] = comments?.toJson();
    }
    return map;
  }
}

Comments commentsFromJson(String str) => Comments.fromJson(json.decode(str));
String commentsToJson(Comments data) => json.encode(data.toJson());

class Comments {
  Comments({this.currentPage, this.data, this.firstPageUrl, this.from, this.lastPage, this.lastPageUrl, this.links, this.nextPageUrl, this.path, this.perPage, this.prevPageUrl, this.to, this.total});

  Comments.fromJson(dynamic json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(PostComments.fromJson(v));
      });
    }
    firstPageUrl = json['first_page_url'];
    from = json['from'];
    lastPage = json['last_page'];
    lastPageUrl = json['last_page_url'];
    if (json['links'] != null) {
      links = [];
      json['links'].forEach((v) {
        links?.add(Links.fromJson(v));
      });
    }
    nextPageUrl = json['next_page_url'];
    path = json['path'];
    perPage = json['per_page'];
    prevPageUrl = json['prev_page_url'];
    to = json['to'];
    total = json['total'];
  }
  int? currentPage;
  List<PostComments>? data;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  String? lastPageUrl;
  List<Links>? links;
  dynamic nextPageUrl;
  String? path;
  int? perPage;
  dynamic prevPageUrl;
  int? to;
  int? total;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['current_page'] = currentPage;
    if (data != null) {
      map['data'] = data?.map((v) => v.toJson()).toList();
    }
    map['first_page_url'] = firstPageUrl;
    map['from'] = from;
    map['last_page'] = lastPage;
    map['last_page_url'] = lastPageUrl;
    if (links != null) {
      map['links'] = links?.map((v) => v.toJson()).toList();
    }
    map['next_page_url'] = nextPageUrl;
    map['path'] = path;
    map['per_page'] = perPage;
    map['prev_page_url'] = prevPageUrl;
    map['to'] = to;
    map['total'] = total;
    return map;
  }
}

Links linksFromJson(String str) => Links.fromJson(json.decode(str));
String linksToJson(Links data) => json.encode(data.toJson());

class Links {
  Links({this.url, this.label, this.active});

  Links.fromJson(dynamic json) {
    url = json['url'];
    label = json['label'];
    active = json['active'];
  }
  dynamic url;
  String? label;
  bool? active;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['url'] = url;
    map['label'] = label;
    map['active'] = active;
    return map;
  }
}

PostComments dataFromJson(String str) => PostComments.fromJson(json.decode(str));
String dataToJson(PostComments data) => json.encode(data.toJson());

class PostComments {
  PostComments({this.id, this.comment, this.createdAt, this.userHasLiked, this.reactionCount, this.replyCount, this.commenter});

  PostComments.fromJson(dynamic json) {
    id = json['id'];
    comment = json['comment'];
    createdAt = json['created_at'];
    userHasLiked = json['user_has_liked'];
    reactionCount = json['reaction_count'];
    replyCount = json['reply_count'];
    commenter = json['commenter'] != null ? Commenter.fromJson(json['commenter']) : null;
  }
  int? id;
  String? comment;
  String? createdAt;
  bool? userHasLiked;
  int? reactionCount;
  int? replyCount;
  Commenter? commenter;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['comment'] = comment;
    map['created_at'] = createdAt;
    map['user_has_liked'] = userHasLiked;
    map['reaction_count'] = reactionCount;
    map['reply_count'] = replyCount;
    if (commenter != null) {
      map['commenter'] = commenter?.toJson();
    }
    return map;
  }
}

Commenter commenterFromJson(String str) => Commenter.fromJson(json.decode(str));
String commenterToJson(Commenter data) => json.encode(data.toJson());

class Commenter {
  Commenter({this.id, this.firstName, this.lastName, this.profilePic});

  Commenter.fromJson(dynamic json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    profilePic = json['profile_pic'];
  }
  dynamic id;
  String? firstName;
  String? lastName;
  String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['profile_pic'] = profilePic;
    return map;
  }
}
