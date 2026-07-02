import 'dart:convert';

ReplyCommentResponse replyCommentResponseFromJson(String str) => ReplyCommentResponse.fromJson(json.decode(str));
String replyCommentResponseToJson(ReplyCommentResponse data) => json.encode(data.toJson());

class ReplyCommentResponse {
  ReplyCommentResponse({this.success, this.message, this.comment});

  ReplyCommentResponse.fromJson(dynamic json) {
    success = json['success'];
    message = json['message'];
    comment = json['comment'] != null ? Comment.fromJson(json['comment']) : null;
  }
  bool? success;
  String? message;
  Comment? comment;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    map['message'] = message;
    if (comment != null) {
      map['comment'] = comment?.toJson();
    }
    return map;
  }
}

Comment commentFromJson(String str) => Comment.fromJson(json.decode(str));
String commentToJson(Comment data) => json.encode(data.toJson());

class Comment {
  Comment({this.id, this.commentableId, this.commenterId, this.childId, this.comment, this.createdAt});

  Comment.fromJson(dynamic json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    commentableId = json['commentable_id']?.toString();
    commenterId = json['commenter_id']?.toString();
    childId = json['child_id']?.toString();
    comment = json['comment'];
    createdAt = json['created_at'];
  }
  int? id;
  String? commentableId;
  String? commenterId;
  String? childId;
  String? comment;
  String? createdAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['commentable_id'] = commentableId;
    map['commenter_id'] = commenterId;
    map['child_id'] = childId;
    map['comment'] = comment;
    map['created_at'] = createdAt;
    return map;
  }
}
