import 'dart:convert';

UserProfile profileModelFromJson(String str) =>
    UserProfile.fromJson(json.decode(str));
String profileModelToJson(UserProfile data) => json.encode(data.toJson());

class UserProfile {
  UserProfile({
    this.totalFollows,
    this.profilePicture,
    this.coverPicture,
    this.isFollowing,
    this.totalPosts,
    this.user,
    this.profile,
    this.followers,
    this.privacySetting,
  });

  UserProfile.fromJson(dynamic json) {
    totalFollows = json['total_follows'] != null
        ? TotalFollows.fromJson(json['total_follows'])
        : null;
    profilePicture = json['profile_picture'];
    coverPicture = json['cover_picture'];
    isFollowing = json['isFollowing'];
    totalPosts = json['total_posts'];
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    profile =
        json['profile'] != null ? Profile.fromJson(json['profile']) : null;
    if (json['followers'] != null) {
      followers = [];
      json['followers'].forEach((v) {
        followers?.add(Followers.fromJson(v));
      });
    }
    if (json['privacy_setting'] != null) {
      privacySetting = [];
      json['privacy_setting'].forEach((v) {
        privacySetting?.add(PrivacySetting.fromJson(v));
      });
    }
  }
  TotalFollows? totalFollows;
  String? profilePicture;
  String? coverPicture;
  bool? isFollowing;
  int? totalPosts;
  User? user;
  Profile? profile;
  List<Followers>? followers;
  List<PrivacySetting>? privacySetting;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (totalFollows != null) {
      map['total_follows'] = totalFollows?.toJson();
    }
    map['profile_picture'] = profilePicture;
    map['cover_picture'] = coverPicture;
    map['isFollowing'] = isFollowing;
    map['total_posts'] = totalPosts;
    if (user != null) {
      map['user'] = user?.toJson();
    }
    if (profile != null) {
      map['profile'] = profile?.toJson();
    }
    if (followers != null) {
      map['followers'] = followers?.map((v) => v.toJson()).toList();
    }
    if (privacySetting != null) {
      map['privacy_setting'] = privacySetting?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

PrivacySetting privacySettingFromJson(String str) =>
    PrivacySetting.fromJson(json.decode(str));
String privacySettingToJson(PrivacySetting data) => json.encode(data.toJson());

class PrivacySetting {
  PrivacySetting({
    this.id,
    this.userId,
    this.recordType,
    this.recordId,
    this.visibility,
    this.createdAt,
    this.updatedAt,
  });

  PrivacySetting.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    recordType = json['record_type'];
    recordId = json['record_id'];
    visibility = json['visibility'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  int? id;
  String? userId;
  String? recordType;
  dynamic recordId;
  String? visibility;
  dynamic createdAt;
  dynamic updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['record_type'] = recordType;
    map['record_id'] = recordId;
    map['visibility'] = visibility;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}

Followers followersFromJson(String str) => Followers.fromJson(json.decode(str));
String followersToJson(Followers data) => json.encode(data.toJson());

class Followers {
  Followers({
    this.id,
  });

  Followers.fromJson(dynamic json) {
    id = json['id'];
  }
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    return map;
  }
}

Profile profileFromJson(String str) => Profile.fromJson(json.decode(str));
String profileToJson(Profile data) => json.encode(data.toJson());

class Profile {
  Profile({
    this.id,
    this.userId,
    this.aboutMe,
    this.address,
    this.birthplace,
    this.livesIn,
    this.languages,
    this.hobbies,
    this.createdAt,
    this.updatedAt,
  });

  Profile.fromJson(dynamic json) {
    id = json['id'];
    userId = json['user_id'];
    aboutMe = json['about_me'];
    address = json['address'];
    birthplace = json['birthplace'];
    livesIn = json['lives_in'];
    languages = json['languages'];
    hobbies = json['hobbies'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }
  int? id;
  String? userId;
  String? aboutMe;
  String? address;
  String? birthplace;
  String? livesIn;
  dynamic languages;
  String? hobbies;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['user_id'] = userId;
    map['about_me'] = aboutMe;
    map['address'] = address;
    map['birthplace'] = birthplace;
    map['lives_in'] = livesIn;
    map['languages'] = languages;
    map['hobbies'] = hobbies;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());

class User {
  User({
    this.role,
    this.country,
    this.firstName,
    this.lastName,
    this.licenseNo,
    this.specialty,
    this.clinicName,
    this.phone,
    this.college,
    this.city,
    this.state,
    this.dob,
    this.id,
  });

  User.fromJson(dynamic json) {
    role = json['role'];
    country = json['country'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    licenseNo = json['license_no'];
    specialty = json['specialty'];
    clinicName = json['clinic_name'];
    phone = json['phone'];
    college = json['college'];
    city = json['city'];
    state = json['state'];
    dob = json['dob'];
    id = json['id'];
  }
  String? role;
  String? country;
  String? firstName;
  String? lastName;
  String? licenseNo;
  String? specialty;
  String? clinicName;
  String? phone;
  String? college;
  String? city;
  String? state;
  String? dob;
  String? id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['role'] = role;
    map['country'] = country;
    map['first_name'] = firstName;
    map['last_name'] = lastName;
    map['license_no'] = licenseNo;
    map['specialty'] = specialty;
    map['clinic_name'] = clinicName;
    map['phone'] = phone;
    map['college'] = college;
    map['city'] = city;
    map['state'] = state;
    map['dob'] = dob;
    map['id'] = id;
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
