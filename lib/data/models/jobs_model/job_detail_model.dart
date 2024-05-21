import 'dart:convert';
JobDetailModel jobDetailModelFromJson(String str) => JobDetailModel.fromJson(json.decode(str));
String jobDetailModelToJson(JobDetailModel data) => json.encode(data.toJson());
class JobDetailModel {
  JobDetailModel({
      this.job,});

  JobDetailModel.fromJson(dynamic json) {
    job = json['job'] != null ? Job.fromJson(json['job']) : null;
  }
  Job? job;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (job != null) {
      map['job'] = job?.toJson();
    }
    return map;
  }

}

Job jobsFromJson(String str) => Job.fromJson(json.decode(str));
String jobsToJson(Job data) => json.encode(data.toJson());

class Job {
  Job({
    this.id,
    this.jobTitle,
    this.companyName,
    this.experience,
    this.location,
    this.description,
    this.link,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.jobImage,
    this.countryId,
    this.lastDate,
    this.applicants,
    this.user,
    this.specialties,});

  Job.fromJson(dynamic json) {
    id = json['id'];
    jobTitle = json['job_title'];
    companyName = json['company_name'];
    experience = json['experience'];
    location = json['location'];
    description = json['description'];
    link = json['link'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    userId = json['user_id'];
    jobImage = json['job_image'];
    countryId = json['country_id'];
    lastDate = json['last_date'];
    if (json['applicants'] != null) {
      applicants = [];
      json['applicants'].forEach((v) {
        applicants?.add(Application.fromJson(v));
      });
    }
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    if (json['specialties'] != null) {
      specialties = [];
      json['specialties'].forEach((v) {
        specialties?.add(Application.fromJson(v));
      });
    }
  }
  int? id;
  String? jobTitle;
  String? companyName;
  String? experience;
  String? location;
  String? description;
  String? link;
  String? createdAt;
  String? updatedAt;
  String? userId;
  String? jobImage;
  String? countryId;
  String? lastDate;
  List<dynamic>? applicants;
  User? user;
  List<dynamic>? specialties;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['job_title'] = jobTitle;
    map['company_name'] = companyName;
    map['experience'] = experience;
    map['location'] = location;
    map['description'] = description;
    map['link'] = link;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['user_id'] = userId;
    map['job_image'] = jobImage;
    map['country_id'] = countryId;
    map['last_date'] = lastDate;
    if (applicants != null) {
      map['applicants'] = applicants?.map((v) => v.toJson()).toList();
    }
    if (user != null) {
      map['user'] = user?.toJson();
    }
    if (specialties != null) {
      map['specialties'] = specialties?.map((v) => v.toJson()).toList();
    }
    return map;
  }

}

Application applicationFromJson(String str) => Application.fromJson(json.decode(str));
String applicationToJson(Application data) => json.encode(data.toJson());
class Application {
  Application({
    this.id,});

  Application.fromJson(dynamic json) {
    id = json['id'];
    // name = json['name'];
    // profilePic = json['profile_pic'];
  }

  dynamic id;

  // String? name;
  // String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    // map['name'] = name;
    // map['profile_pic'] = profilePic;
    return map;
  }
}
User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());
class User {
  User({
    this.id,
    this.name,
    this.profilePic,});

  User.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    profilePic = json['profile_pic'];
  }
  String? id;
  String? name;
  String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    return map;
  }

}