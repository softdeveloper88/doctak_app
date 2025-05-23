import 'dart:convert';
AnnouncementDetailModel announcementDetailModelFromJson(String str) => AnnouncementDetailModel.fromJson(json.decode(str));
String announcementDetailModelToJson(AnnouncementDetailModel data) => json.encode(data.toJson());
class AnnouncementDetailModel {
  AnnouncementDetailModel({
      this.success, 
      this.data,});

  AnnouncementDetailModel.fromJson(dynamic json) {
    success = json['success'];
    data = json['data'] != null ? AnnouncementDetailData.fromJson(json['data']) : null;
  }
  bool? success;
  AnnouncementDetailData? data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['success'] = success;
    if (data != null) {
      map['data'] = data?.toJson();
    }
    return map;
  }

}

AnnouncementDetailData dataFromJson(String str) => AnnouncementDetailData.fromJson(json.decode(str));
String dataToJson(AnnouncementDetailData data) => json.encode(data.toJson());
class AnnouncementDetailData {
  AnnouncementDetailData({
      this.id, 
      this.userId, 
      this.title, 
      this.details, 
      this.image, 
      this.isActive, 
      this.createdAt, 
      this.updatedAt, 
      this.deletedAt, 
      this.user,});

  AnnouncementDetailData.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    title = json['title'];
    details = json['details'];
    image = json['image'];
    isActive = json['is_active'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }
  int? id;
  String? userId;
  String? title;
  String? details;
  String? image;
  dynamic isActive;
  String? createdAt;
  String? updatedAt;
  dynamic deletedAt;
  User? user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['title'] = title;
    map['details'] = details;
    map['image'] = image;
    map['is_active'] = isActive;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['deleted_at'] = deletedAt;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    return map;
  }

}

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());
class User {
  User({
      this.id, 
      this.firstName, 
      this.lastName, 
      this.specialty, 
      this.profilePic,});

  User.fromJson(dynamic json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    specialty = json['specialty'];
    profilePic = json['profile_pic'];
  }
  String? id;
  String? firstName;
  String? lastName;
  String? specialty;
  String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['specialty'] = specialty;
    map['profile_pic'] = profilePic;
    return map;
  }

}