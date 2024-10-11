import 'dart:convert';
JobApplicantsModel jobApplicantsModelFromJson(String str) => JobApplicantsModel.fromJson(json.decode(str));
String jobApplicantsModelToJson(JobApplicantsModel data) => json.encode(data.toJson());
class JobApplicantsModel {
  JobApplicantsModel({
      this.applicants,});

  JobApplicantsModel.fromJson(dynamic json) {
    if (json['applicants'] != null) {
      applicants = [];
      json['applicants'].forEach((v) {
        applicants?.add(Applicants.fromJson(v));
      });
    }
  }
  List<Applicants>? applicants;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (applicants != null) {
      map['applicants'] = applicants?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Applicants applicantsFromJson(String str) => Applicants.fromJson(json.decode(str));
String applicantsToJson(Applicants data) => json.encode(data.toJson());
class Applicants {
  Applicants({
      this.id, 
      this.userId, 
      this.jobId, 
      this.isViewedByAdmin, 
      this.createdAt, 
      this.updatedAt, 
      this.cv, 
      this.user,});

  Applicants.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    jobId = json['job_id'];
    isViewedByAdmin = json['is_viewed_by_admin'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    cv = json['cv'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }
  int? id;
  String? userId;
  String? jobId;
  String? isViewedByAdmin;
  String? createdAt;
  String? updatedAt;
  String? cv;
  User? user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['job_id'] = jobId;
    map['is_viewed_by_admin'] = isViewedByAdmin;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['cv'] = cv;
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
      this.name, 
      this.profilePic, 
      this.email,});

  User.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    profilePic = json['profile_pic'];
    email = json['email'];
  }
  String? id;
  String? name;
  String? profilePic;
  String? email;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    map['email'] = email;
    return map;
  }

}