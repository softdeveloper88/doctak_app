import 'dart:convert';
import 'package:doctak_app/core/utils/app/AppData.dart';

JobsModel jobsModelFromJson(String str) => JobsModel.fromJson(json.decode(str));
String jobsModelToJson(JobsModel data) => json.encode(data.toJson());

class JobsModel {
  JobsModel({this.jobs});

  JobsModel.fromJson(dynamic json) {
    jobs = json['jobs'] != null ? Jobs.fromJson(json['jobs']) : null;
  }
  Jobs? jobs;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (jobs != null) {
      map['jobs'] = jobs?.toJson();
    }
    return map;
  }
}

Jobs jobsFromJson(String str) => Jobs.fromJson(json.decode(str));
String jobsToJson(Jobs data) => json.encode(data.toJson());

class Jobs {
  Jobs({
    this.currentPage,
    this.data,
    this.firstPageUrl,
    this.from,
    this.lastPage,
    this.lastPageUrl,
    this.links,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    this.total,
  });

  Jobs.fromJson(dynamic json) {
    currentPage = json['current_page'] is int ? json['current_page'] : int.tryParse(json['current_page']?.toString() ?? '');
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Data.fromJson(v));
      });
    }
    firstPageUrl = json['first_page_url']?.toString();
    from = json['from'] is int ? json['from'] : int.tryParse(json['from']?.toString() ?? '');
    lastPage = json['last_page'] is int ? json['last_page'] : int.tryParse(json['last_page']?.toString() ?? '');
    lastPageUrl = json['last_page_url']?.toString();
    if (json['links'] != null) {
      links = [];
      json['links'].forEach((v) {
        links?.add(Links.fromJson(v));
      });
    }
    nextPageUrl = json['next_page_url']?.toString();
    path = json['path']?.toString();
    perPage = json['per_page'] is int ? json['per_page'] : int.tryParse(json['per_page']?.toString() ?? '');
    prevPageUrl = json['prev_page_url'];
    to = json['to'] is int ? json['to'] : int.tryParse(json['to']?.toString() ?? '');
    total = json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '');
  }
  int? currentPage;
  List<Data>? data;
  String? firstPageUrl;
  int? from;
  int? lastPage;
  String? lastPageUrl;
  List<Links>? links;
  String? nextPageUrl;
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

Data dataFromJson(String str) => Data.fromJson(json.decode(str));
String dataToJson(Data data) => json.encode(data.toJson());

class Data {
  Data({
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
    this.applicants,
    this.user,
  });

  Data.fromJson(dynamic json) {
    id = json['id'];
    jobTitle = json['job_title']?.toString();
    jobType = json['job_type']?.toString();
    companyName = json['company_name']?.toString();
    experience = json['experience']?.toString();
    location = json['location']?.toString();
    description = json['description']?.toString();
    link = json['link']?.toString();
    preferredLanguage = json['preferred_language']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    userId = json['user_id']?.toString();
    jobImage = json['job_image'];
    countryId = json['country_id']?.toString();
    lastDate = json['last_date']?.toString();
    totalJobs = json['total_jobs'];
    specialty = json['specialty'];
    noOfJobs = json['no_of_jobs'];
    postedAt = json['posted_at']?.toString();
    salaryRange = json['salary_range']?.toString();
    promoted = json['promoted'] == true || json['promoted'] == 1;
    views = json['views'];
    clicks = json['clicks'];
    if (json['specialties'] != null) {
      specialties = [];
      json['specialties'].forEach((v) {
        specialties?.add(Specialties.fromJson(v));
      });
    }
    if (json['applicants'] != null) {
      applicants = [];
      json['applicants'].forEach((v) {
        applicants?.add(Applicants.fromJson(v));
      });
    }
    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }
  dynamic id;
  String? jobTitle;
  String? jobType;
  String? companyName;
  String? experience;
  String? location;
  String? description;
  String? link;
  String? preferredLanguage;
  String? createdAt;
  String? updatedAt;
  String? userId;
  dynamic jobImage;
  String? countryId;
  String? lastDate;
  dynamic totalJobs;
  dynamic specialty;
  dynamic noOfJobs;
  dynamic postedAt;
  String? salaryRange;
  bool? promoted;
  dynamic views;
  dynamic clicks;
  List<Specialties>? specialties;
  List<Applicants>? applicants;
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
    map['preferred_language'] = preferredLanguage;
    map['created_at'] = createdAt;
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
    if (applicants != null) {
      map['applicants'] = applicants?.map((v) => v.toJson()).toList();
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
  User({this.id, this.name, this.profilePic});

  User.fromJson(dynamic json) {
    id = json['id']?.toString();
    name = json['name']?.toString();
    profilePic = AppData.fullImageUrl(json['profile_pic']?.toString());
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

Applicants applicantsFromJson(String str) =>
    Applicants.fromJson(json.decode(str));
String applicantsToJson(Applicants data) => json.encode(data.toJson());

class Applicants {
  Applicants({
    this.id,
    this.firstName,
    this.lastName,
    this.emailVerifiedAt,
    this.userType,
    this.name,
    this.email,
    this.token,
    this.phone,
    this.licenseNo,
    this.specialty,
    this.status,
    this.role,
    this.gender,
    this.dob,
    this.clinicName,
    this.college,
    this.countryOrigin,
    this.profilePic,
    this.practicingCountry,
    this.otpCode,
    this.balance,
    this.title,
    this.city,
    this.country,
    this.isAdmin,
    this.createdAt,
    this.updatedAt,
    this.activeStatus,
    this.avatar,
    this.darkMode,
    this.messengerColor,
    this.isPremium,
    this.background,
    this.lastActivity,
    this.pivot,
  });

  Applicants.fromJson(dynamic json) {
    id = json['id']?.toString();
    firstName = json['first_name']?.toString();
    lastName = json['last_name']?.toString();
    emailVerifiedAt = json['email_verified_at']?.toString();
    userType = json['user_type']?.toString();
    name = json['name']?.toString();
    email = json['email']?.toString();
    token = json['token'];
    phone = json['phone']?.toString();
    licenseNo = json['license_no']?.toString();
    specialty = json['specialty']?.toString();
    status = json['status']?.toString();
    role = json['role']?.toString();
    gender = json['gender']?.toString();
    dob = json['dob']?.toString();
    clinicName = json['clinic_name']?.toString();
    college = json['college']?.toString();
    countryOrigin = json['country_origin']?.toString();
    profilePic = AppData.fullImageUrl(json['profile_pic']?.toString());
    practicingCountry = json['practicing_country']?.toString();
    otpCode = json['otp_code'];
    balance = json['balance']?.toString();
    title = json['title']?.toString();
    city = json['city']?.toString();
    country = json['country']?.toString();
    isAdmin = json['is_admin'];
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    activeStatus = json['active_status']?.toString();
    avatar = json['avatar'];
    darkMode = json['dark_mode']?.toString();
    messengerColor = json['messenger_color'];
    isPremium = json['is_premium']?.toString();
    background = AppData.fullImageUrl(json['background']?.toString());
    lastActivity = json['last_activity']?.toString();
    pivot = json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null;
  }
  String? id;
  String? firstName;
  String? lastName;
  String? emailVerifiedAt;
  String? userType;
  String? name;
  String? email;
  dynamic token;
  String? phone;
  String? licenseNo;
  String? specialty;
  String? status;
  String? role;
  String? gender;
  String? dob;
  String? clinicName;
  String? college;
  String? countryOrigin;
  String? profilePic;
  String? practicingCountry;
  dynamic otpCode;
  String? balance;
  String? title;
  String? city;
  String? country;
  dynamic isAdmin;
  String? createdAt;
  String? updatedAt;
  String? activeStatus;
  dynamic avatar;
  String? darkMode;
  dynamic messengerColor;
  String? isPremium;
  String? background;
  String? lastActivity;
  Pivot? pivot;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['email_verified_at'] = emailVerifiedAt;
    map['user_type'] = userType;
    map['name'] = name;
    map['email'] = email;
    map['token'] = token;
    map['phone'] = phone;
    map['license_no'] = licenseNo;
    map['specialty'] = specialty;
    map['status'] = status;
    map['role'] = role;
    map['gender'] = gender;
    map['dob'] = dob;
    map['clinic_name'] = clinicName;
    map['college'] = college;
    map['country_origin'] = countryOrigin;
    map['profile_pic'] = profilePic;
    map['practicing_country'] = practicingCountry;
    map['otp_code'] = otpCode;
    map['balance'] = balance;
    map['title'] = title;
    map['city'] = city;
    map['country'] = country;
    map['is_admin'] = isAdmin;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    map['active_status'] = activeStatus;
    map['avatar'] = avatar;
    map['dark_mode'] = darkMode;
    map['messenger_color'] = messengerColor;
    map['is_premium'] = isPremium;
    map['background'] = background;
    map['last_activity'] = lastActivity;
    if (pivot != null) {
      map['pivot'] = pivot?.toJson();
    }
    return map;
  }
}

Pivot pivotFromJson(String str) => Pivot.fromJson(json.decode(str));
String pivotToJson(Pivot data) => json.encode(data.toJson());

class Pivot {
  Pivot({this.jobId, this.userId, this.isViewedByAdmin});

  Pivot.fromJson(dynamic json) {
    jobId = json['job_id']?.toString();
    userId = json['user_id']?.toString();
    isViewedByAdmin = json['is_viewed_by_admin']?.toString();
  }
  String? jobId;
  String? userId;
  String? isViewedByAdmin;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['job_id'] = jobId;
    map['user_id'] = userId;
    map['is_viewed_by_admin'] = isViewedByAdmin;
    return map;
  }
}

Specialties specialtiesFromJson(String str) =>
    Specialties.fromJson(json.decode(str));
String specialtiesToJson(Specialties data) => json.encode(data.toJson());

class Specialties {
  Specialties({this.id, this.name, this.createdAt, this.updatedAt, this.pivot});

  Specialties.fromJson(dynamic json) {
    id = json['id']?.toString();
    name = json['name']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    pivot = json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null;
  }
  String? id;
  String? name;
  String? createdAt;
  String? updatedAt;
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
