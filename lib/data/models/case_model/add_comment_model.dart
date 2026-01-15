import 'dart:convert';

AddCommentModel addCommentModelFromJson(String str) => AddCommentModel.fromJson(json.decode(str));
String addCommentModelToJson(AddCommentModel data) => json.encode(data.toJson());

class AddCommentModel {
  AddCommentModel({this.comment, this.message});

  AddCommentModel.fromJson(dynamic json) {
    comment = json['comment'] != null ? Comment.fromJson(json['comment']) : null;
    message = json['message'];
  }
  Comment? comment;
  String? message;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (comment != null) {
      map['comment'] = comment?.toJson();
    }
    map['message'] = message;
    return map;
  }
}

Comment commentFromJson(String str) => Comment.fromJson(json.decode(str));
String commentToJson(Comment data) => json.encode(data.toJson());

class Comment {
  Comment({this.discussCaseId, this.userId, this.comment, this.updatedAt, this.createdAt, this.id});

  Comment.fromJson(dynamic json) {
    discussCaseId = json['discuss_case_id'];
    userId = json['user_id'];
    comment = json['comment'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    id = json['id'];
  }
  String? discussCaseId;
  String? userId;
  String? comment;
  String? updatedAt;
  String? createdAt;
  int? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['discuss_case_id'] = discussCaseId;
    map['user_id'] = userId;
    map['comment'] = comment;
    map['updated_at'] = updatedAt;
    map['created_at'] = createdAt;
    map['id'] = id;
    return map;
  }
}
