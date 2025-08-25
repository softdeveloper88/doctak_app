import 'dart:convert';

FollowerDataModel followerDataModelFromJson(String str) =>
    FollowerDataModel.fromJson(json.decode(str));
String followerDataModelToJson(FollowerDataModel data) =>
    json.encode(data.toJson());

class FollowerDataModel {
  FollowerDataModel({
    this.totalFollows,
    this.profilePicture,
    this.coverPicture,
    this.totalPosts,
    this.user,
    this.followers,
    this.following,
  });

  FollowerDataModel.fromJson(dynamic json) {
    totalFollows = json['total_follows'] != null
        ? TotalFollows.fromJson(json['total_follows'])
        : null;
    profilePicture = json['profile_picture'];
    coverPicture = json['cover_picture'];
    totalPosts = json['total_posts'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    if (json['followers'] != null) {
      followers = [];
      json['followers'].forEach((v) {
        followers?.add(Followers.fromJson(v));
      });
    }
    if (json['following'] != null) {
      following = [];
      json['following'].forEach((v) {
        following?.add(Following.fromJson(v));
      });
    }
  }
  TotalFollows? totalFollows;
  String? profilePicture;
  String? coverPicture;
  int? totalPosts;
  User? user;
  List<Followers>? followers;
  List<Following>? following;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (totalFollows != null) {
      map['total_follows'] = totalFollows?.toJson();
    }
    map['profile_picture'] = profilePicture;
    map['cover_picture'] = coverPicture;
    map['total_posts'] = totalPosts;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    if (followers != null) {
      map['followers'] = followers?.map((v) => v.toJson()).toList();
    }
    if (following != null) {
      map['following'] = following?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

Following followingFromJson(String str) => Following.fromJson(json.decode(str));
String followingToJson(Following data) => json.encode(data.toJson());

class Following {
  Following({
    this.id,
    this.profileUrl,
    this.isCurrentlyFollow,
    this.name,
    this.profilePic,
    this.specialty,
  });

  Following.fromJson(dynamic json) {
    id = json['user_id'];
    isCurrentlyFollow = json['isCurrentlyFollow'];
    profileUrl = json['profile_url'];
    name = json['name'];
    profilePic = json['profile_pic'];
    specialty = json['specialty'];
  }
  String? id;
  bool? isCurrentlyFollow;
  String? profileUrl;
  String? name;
  String? profilePic;
  dynamic specialty;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = id;
    map['isCurrentlyFollow'] = isCurrentlyFollow;
    map['profile_url'] = profileUrl;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    map['specialty'] = specialty;
    return map;
  }
}

Followers followersFromJson(String str) => Followers.fromJson(json.decode(str));
String followersToJson(Followers data) => json.encode(data.toJson());

class Followers {
  Followers({
    this.id,
    this.profileUrl,
    this.isCurrentlyFollow,
    this.name,
    this.profilePic,
    this.specialty,
  });

  Followers.fromJson(dynamic json) {
    id = json['user_id'];
    isCurrentlyFollow = json['isCurrentlyFollow'];
    profileUrl = json['profile_url'];
    name = json['name'];
    profilePic = json['profile_pic'];
    specialty = json['specialty'];
  }
  String? id;
  bool? isCurrentlyFollow;
  String? profileUrl;
  String? name;
  String? profilePic;
  dynamic specialty;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['user_id'] = id;
    map['isCurrentlyFollow'] = isCurrentlyFollow;
    map['profile_url'] = profileUrl;
    map['name'] = name;
    map['profile_pic'] = profilePic;
    map['specialty'] = specialty;
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
  });

  User.fromJson(dynamic json) {
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
  dynamic status;
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
  dynamic activeStatus;
  dynamic avatar;
  int? darkMode;
  dynamic messengerColor;
  int? isPremium;
  String? background;

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
    return map;
  }
}

TotalFollows totalFollowsFromJson(String str) =>
    TotalFollows.fromJson(json.decode(str));
String totalFollowsToJson(TotalFollows data) => json.encode(data.toJson());

class TotalFollows {
  TotalFollows({
    this.totalFollowers,
    this.totalFollowings,
  });

  TotalFollows.fromJson(dynamic json) {
    totalFollowers = json['total_followers'];
    totalFollowings = json['total_followings'];
  }
  String? totalFollowers;
  String? totalFollowings;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['total_followers'] = totalFollowers;
    map['total_followings'] = totalFollowings;
    return map;
  }
}
