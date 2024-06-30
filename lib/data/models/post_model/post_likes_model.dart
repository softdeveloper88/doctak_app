import 'dart:convert';
PostLikesModel postLikesModelFromJson(String str) => PostLikesModel.fromJson(json.decode(str));
String postLikesModelToJson(PostLikesModel data) => json.encode(data.toJson());
class PostLikesModel {
  PostLikesModel({
      this.id, 
      this.profilePic, 
      this.name,});

  PostLikesModel.fromJson(dynamic json) {
    id = json['id'];
    profilePic = json['profile_pic'];
    name = json['name'];
  }

  String? id;
  String? profilePic;
  String? name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['profile_pic'] = profilePic;
    map['name'] = name;
    return map;
  }

}