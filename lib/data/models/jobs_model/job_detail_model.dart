import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/display_identity.dart';

JobDetailModel jobDetailModelFromJson(String str) =>
    JobDetailModel.fromJson(json.decode(str));
String jobDetailModelToJson(JobDetailModel data) => json.encode(data.toJson());

class JobDetailModel {
  JobDetailModel({
    this.job,
    this.hasApplied,
    this.totalApplicants,
    this.isViewedByAdmin,
  });

  JobDetailModel.fromJson(dynamic json) {
    job = json['job'] != null ? Job.fromJson(json['job']) : null;
    hasApplied = json['hasApplied'] == true || json['hasApplied'] == 1;
    totalApplicants = json['totalApplicants'] is int ? json['totalApplicants'] : int.tryParse(json['totalApplicants']?.toString() ?? '');
    isViewedByAdmin = json['isViewedByAdmin'];
  }
  Job? job;
  bool? hasApplied;
  int? totalApplicants;
  dynamic isViewedByAdmin;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (job != null) {
      map['job'] = job?.toJson();
    }
    map['hasApplied'] = hasApplied;
    map['totalApplicants'] = totalApplicants;
    map['isViewedByAdmin'] = isViewedByAdmin;
    return map;
  }
}

Job jobFromJson(String str) => Job.fromJson(json.decode(str));
String jobToJson(Job data) => json.encode(data.toJson());

class Job {
  Job({
    this.id,
    this.jobTitle,
    this.jobType,
    this.companyName,
    this.experience,
    this.location,
    this.description,
    this.link,
    this.createdAt,
    this.preferredLanguage,
    this.updatedAt,
    this.userId,
    this.jobImage,
    this.countryId,
    this.lastDate,
    this.totalJobs,
    this.specialty,
    this.noOfJobs,
    this.postedAt,
    this.salaryRange,
    this.promoted,
    this.views,
    this.clicks,
    this.specialties,
    this.user,
  });

  Job.fromJson(dynamic json) {
    id = json['id'];
    jobTitle = json['job_title']?.toString();
    jobType = json['job_type']?.toString();
    companyName = formatDisplayName(json['company_name']?.toString());
    experience = json['experience']?.toString();
    location = json['location']?.toString();
    description = json['description']?.toString();
    link = json['link']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    userId = json['user_id'];
    jobImage = json['job_image'];
    countryId = json['country_id']?.toString();
    lastDate = json['last_date']?.toString();
    totalJobs = json['total_jobs'];
    specialty = json['specialty'];
    noOfJobs = json['no_of_jobs']?.toString();
    postedAt = json['posted_at']?.toString();
    preferredLanguage = json['preferred_language']?.toString();
    salaryRange = json['salary_range']?.toString();
    promoted = json['promoted'] is bool
        ? (json['promoted'] ? 1 : 0)
        : json['promoted'];
    views = json['views'] is int ? json['views'] : int.tryParse(json['views']?.toString() ?? '');
    clicks = json['clicks'] is int ? json['clicks'] : int.tryParse(json['clicks']?.toString() ?? '');
    if (json['specialties'] != null) {
      specialties = [];
      json['specialties'].forEach((v) {
        if (v is int) {
          specialties?.add(Specialties(id: v));
        } else if (v is Map<String, dynamic>) {
          specialties?.add(Specialties.fromJson(v));
        } else {
          specialties?.add(Specialties(id: v));
        }
      });
    }
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }
  int? id;
  String? jobTitle;
  String? jobType;
  String? companyName;
  String? experience;
  String? location;
  String? description;
  String? link;
  String? createdAt;
  String? preferredLanguage;
  String? updatedAt;
  dynamic userId;
  dynamic jobImage;
  dynamic countryId;
  String? lastDate;
  dynamic totalJobs;
  dynamic specialty;
  dynamic noOfJobs;
  dynamic postedAt;
  String? salaryRange;
  dynamic promoted;
  int? views;
  int? clicks;
  List<Specialties>? specialties;
  User? user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['job_title'] = jobTitle;
    map['job_type'] = jobType;
    map['company_name'] = companyName;
    map['experience'] = experience;
    map['location'] = location;
    map['description'] = description;
    map['link'] = link;
    map['created_at'] = createdAt;
    map['preferred_language'] = preferredLanguage;
    map['updated_at'] = updatedAt;
    map['user_id'] = userId;
    map['job_image'] = jobImage;
    map['country_id'] = countryId;
    map['last_date'] = lastDate;
    map['total_jobs'] = totalJobs;
    map['specialty'] = specialty;
    map['no_of_jobs'] = noOfJobs;
    map['posted_at'] = postedAt;
    map['salary_range'] = salaryRange;
    map['promoted'] = promoted;
    map['views'] = views;
    map['clicks'] = clicks;
    if (specialties != null) {
      map['specialties'] = specialties?.map((v) => v.toJson()).toList();
    }
    if (user != null) {
      map['user'] = user?.toJson();
    }
    return map;
  }
}

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());

class User {
  User({this.id, this.name, this.profilePic, this.isVerified});

  User.fromJson(dynamic json) {
    id = json['id'];
    name = formatDisplayName(json['name']?.toString());
    profilePic = AppData.fullImageUrl(json['profile_pic']?.toString());
    isVerified = json['is_verified'] == true || json['is_verified'] == 1;
  }
  dynamic id;
  dynamic name;
  String? profilePic;
  bool? isVerified;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    map['is_verified'] = isVerified;
    return map;
  }
}

Specialties specialtiesFromJson(String str) =>
    Specialties.fromJson(json.decode(str));
String specialtiesToJson(Specialties data) => json.encode(data.toJson());

class Specialties {
  Specialties({this.id, this.name, this.createdAt, this.updatedAt, this.pivot});

  Specialties.fromJson(dynamic json) {
    id = json['id'];
    name = json['name']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    pivot = json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null;
  }
  dynamic id;
  String? name;
  dynamic createdAt;
  dynamic updatedAt;
  Pivot? pivot;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    if (pivot != null) {
      map['pivot'] = pivot?.toJson();
    }
    return map;
  }
}

Pivot pivotFromJson(String str) => Pivot.fromJson(json.decode(str));
String pivotToJson(Pivot data) => json.encode(data.toJson());

class Pivot {
  Pivot({this.jobId, this.specialityId});

  Pivot.fromJson(dynamic json) {
    jobId = json['job_id']?.toString();
    specialityId = json['speciality_id']?.toString();
  }
  String? jobId;
  String? specialityId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['job_id'] = jobId;
    map['speciality_id'] = specialityId;
    return map;
  }
}
