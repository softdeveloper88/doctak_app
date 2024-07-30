import 'dart:convert';
CaseComments caseCommentsFromJson(String str) => CaseComments.fromJson(json.decode(str));
String caseCommentsToJson(CaseComments data) => json.encode(data.toJson());
class CaseComments {
  CaseComments({
      this.comments, 
      this.offset,});

  CaseComments.fromJson(dynamic json) {
    if (json['comments'] != null) {
      comments = [];
      json['comments'].forEach((v) {
        comments?.add(Comments.fromJson(v));
      });
    }
    offset = json['offset'];
  }
  List<Comments>? comments;
  int? offset;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (comments != null) {
      map['comments'] = comments?.map((v) => v.toJson()).toList();
    }
    map['offset'] = offset;
    return map;
  }

}

Comments commentsFromJson(String str) => Comments.fromJson(json.decode(str));
String commentsToJson(Comments data) => json.encode(data.toJson());
class Comments {
  Comments({
      this.id, 
      this.comment, 
      this.likes, 
      this.dislikes, 
      this.createdAt, 
      this.name, 
      this.profilePic, 
      this.likedByUser, 
      this.actionType,});

  Comments.fromJson(dynamic json) {
    id = json['id'];
    comment = json['comment'];
    likes = json['likes'];
    dislikes = json['dislikes'];
    createdAt = json['created_at'];
    name = json['name'];
    profilePic = json['profile_pic'];
    likedByUser = json['liked_by_user'];
    actionType = json['action_type'];
  }
  int? id;
  String? comment;
  int? likes;
  int? dislikes;
  String? createdAt;
  String? name;
  String? profilePic;
  int? likedByUser;
  dynamic actionType;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['comment'] = comment;
    map['likes'] = likes;
    map['dislikes'] = dislikes;
    map['created_at'] = createdAt;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    map['liked_by_user'] = likedByUser;
    map['action_type'] = actionType;
    return map;
  }

}