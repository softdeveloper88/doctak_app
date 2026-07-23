import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';

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
    comment = json['comment'] ?? json['body'];
    createdAt = json['created_at'];
    userHasLiked = _parseCommentUserHasLiked(json['user_has_liked']);
    reactionCount = json['reaction_count'] != null
        ? int.tryParse(json['reaction_count'].toString())
        : (json['like_count'] != null ? int.tryParse(json['like_count'].toString()) : null);
    replyCount = json['reply_count'] != null ? int.tryParse(json['reply_count'].toString()) : null;
    commenter = json['commenter'] != null ? Commenter.fromJson(json['commenter']) : null;
    if (commenter != null &&
        (json['commenterIsVerified'] != null || json['commenter_is_verified'] != null)) {
      commenter!.isVerified = Commenter.parseCommenterVerified(json);
    }
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
  Commenter({
    this.id,
    this.firstName,
    this.lastName,
    this.profilePic,
    this.specialty,
    this.isVerified,
    this.isPremium,
  });

  Commenter.fromJson(dynamic json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    if ((firstName == null || '$firstName'.trim().isEmpty) && json['name'] != null) {
      final parts = json['name'].toString().trim().split(' ');
      firstName = parts.isNotEmpty ? parts.first : '';
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    profilePic = resolveCommentProfilePic(json);
    specialty = json['specialty']?.toString() ?? json['specialization']?.toString();
    isVerified = parseCommenterVerified(json);
    isPremium = parseCommenterPremium(json);
  }

  static bool parseCommenterVerified(dynamic json) {
    if (json is! Map) return false;
    final raw = json['is_verified'] ??
        json['commenterIsVerified'] ??
        json['commenter_is_verified'];
    return raw == true || raw == 1 || raw == '1';
  }

  static bool parseCommenterPremium(dynamic json) {
    if (json is! Map) return false;
    final raw = json['is_premium'] ??
        json['commenterIsPremium'] ??
        json['commenter_is_premium'];
    return raw == true || raw == 1 || raw == '1';
  }

  dynamic id;
  String? firstName;
  String? lastName;
  String? profilePic;
  String? specialty;
  bool? isVerified;
  bool? isPremium;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['profile_pic'] = profilePic;
    map['specialty'] = specialty;
    map['is_verified'] = isVerified;
    map['is_premium'] = isPremium;
    return map;
  }
}

bool? _parseCommentUserHasLiked(dynamic raw) {
  if (raw == null) return false;
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final s = raw.toString().toLowerCase();
  return s == 'true' || s == '1';
}

String? resolveCommentProfilePic(dynamic json) {
  if (json is! Map) return null;
  final user = json['user'];
  final raw = json['profile_pic'] ??
      json['profilePic'] ??
      json['avatar'] ??
      json['avatar_url'] ??
      json['author_avatar'] ??
      json['display_pic'] ??
      (user is Map ? user['profile_pic'] ?? user['profilePic'] : null);
  final resolved = AppData.fullImageUrl(raw?.toString());
  return resolved.isEmpty ? null : resolved;
}
