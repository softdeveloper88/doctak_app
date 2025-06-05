import 'dart:convert';
JobsModel jobsModelFromJson(String str) => JobsModel.fromJson(json.decode(str));
String jobsModelToJson(JobsModel data) => json.encode(data.toJson());
class JobsModel {
  JobsModel({
      this.jobs,});

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
      this.total,});

  Jobs.fromJson(dynamic json) {
    currentPage = json['current_page'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data?.add(Data.fromJson(v));
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
  Links({
      this.url, 
      this.label, 
      this.active,});

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
      this.user,});

  Data.fromJson(dynamic json) {
    id = json['id'];
    jobTitle = json['job_title'];
    companyName = json['company_name'];
    experience = json['experience'];
    location = json['location'];
    description = json['description'];
    link = json['link'];
    preferredLanguage = json['preferred_language'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    userId = json['user_id'];
    jobImage = json['job_image'];
    countryId = json['country_id'];
    lastDate = json['last_date'];
    totalJobs = json['total_jobs'];
    specialty = json['specialty'];
    noOfJobs = json['no_of_jobs'];
    postedAt = json['posted_at'];
    salaryRange = json['salary_range'];
    promoted = json['promoted'];
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
  int? id;
  String? jobTitle;
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
  int? views;
  int? clicks;
  List<Specialties>? specialties;
  List<Applicants>? applicants;
  User? user;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['job_title'] = jobTitle;
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
  dynamic name;
  String? profilePic;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    return map;
  }

}

Applicants applicantsFromJson(String str) => Applicants.fromJson(json.decode(str));
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
      this.pivot,});

  Applicants.fromJson(dynamic json) {
    id = json['id'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    emailVerifiedAt = json['email_verified_at'];
    userType = json['user_type'];
    name = json['name'];
    email = json['email'];
    token = json['token'];
    phone = json['phone'];
    licenseNo = json['license_no'];
    specialty = json['specialty'];
    status = json['status'];
    role = json['role'];
    gender = json['gender'];
    dob = json['dob'];
    clinicName = json['clinic_name'];
    college = json['college'];
    countryOrigin = json['country_origin'];
    profilePic = json['profile_pic'];
    practicingCountry = json['practicing_country'];
    otpCode = json['otp_code'];
    balance = json['balance'];
    title = json['title'];
    city = json['city'];
    country = json['country'];
    isAdmin = json['is_admin'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    activeStatus = json['active_status'];
    avatar = json['avatar'];
    darkMode = json['dark_mode'];
    messengerColor = json['messenger_color'];
    isPremium = json['is_premium'];
    background = json['background'];
    lastActivity = json['last_activity'];
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
  int? balance;
  String? title;
  String? city;
  String? country;
  dynamic isAdmin;
  String? createdAt;
  String? updatedAt;
  String? activeStatus;
  dynamic avatar;
  int? darkMode;
  dynamic messengerColor;
  int? isPremium;
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
  Pivot({
      this.jobId, 
      this.userId, 
      this.isViewedByAdmin,});

  Pivot.fromJson(dynamic json) {
    jobId = json['job_id'];
    userId = json['user_id'];
    isViewedByAdmin = json['is_viewed_by_admin'];
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

Specialties specialtiesFromJson(String str) => Specialties.fromJson(json.decode(str));
String specialtiesToJson(Specialties data) => json.encode(data.toJson());
class Specialties {
  Specialties({
      this.id, 
      this.name, 
      this.createdAt, 
      this.updatedAt, 
      this.pivot,});

  Specialties.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    pivot = json['pivot'] != null ? Pivot.fromJson(json['pivot']) : null;
  }
  String? id;
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
