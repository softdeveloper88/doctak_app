import 'package:doctak_app/data/models/profile_model/award_model.dart';
import 'package:doctak_app/data/models/profile_model/business_hour_model.dart';
import 'package:doctak_app/data/models/profile_model/education_detail_model.dart';
import 'package:doctak_app/data/models/profile_model/experience_model.dart';
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/medical_license_model.dart';
import 'package:doctak_app/data/models/profile_model/publication_model.dart';
import 'package:doctak_app/data/models/profile_model/social_profile_model.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';

/// Comprehensive profile model from v5/full-profile API
/// Contains all profile sections in a single response
class FullProfileModel {
  bool? success;
  bool? isOwnProfile;
  bool? isFollowing;
  bool? isFriend;
  String? connectionStatus;
  String? friendRequestId;
  FullProfileUser? user;
  FullProfileInfo? profile;
  Map<String, dynamic>? contactInfo;
  FullProfileStats? stats;
  List<ExperienceModel> experiences;
  List<EducationDetailModel> education;
  List<PublicationModel> publications;
  List<AwardModel> awards;
  List<MedicalLicenseModel> licenses;
  List<SocialProfileModel> socialProfiles;
  List<BusinessHourModel> businessHours;
  List<InterestModel> interests;
  Map<String, dynamic>? privacySettings;
  int? profileCompletionPercentage;
  Map<String, dynamic>? profileCompletionSections;

  FullProfileModel({
    this.success,
    this.isOwnProfile,
    this.isFollowing,
    this.isFriend,
    this.connectionStatus,
    this.friendRequestId,
    this.user,
    this.profile,
    this.contactInfo,
    this.stats,
    this.experiences = const [],
    this.education = const [],
    this.publications = const [],
    this.awards = const [],
    this.licenses = const [],
    this.socialProfiles = const [],
    this.businessHours = const [],
    this.interests = const [],
    this.privacySettings,
    this.profileCompletionPercentage,
    this.profileCompletionSections,
  });

  factory FullProfileModel.fromJson(Map<String, dynamic> json) {
    return FullProfileModel(
      success: json['success'] as bool?,
      isOwnProfile: json['is_own_profile'] as bool?,
      isFollowing: json['is_following'] as bool?,
      isFriend: json['is_friend'] as bool?,
      connectionStatus: json['connection_status'] as String?,
      friendRequestId: json['friend_request_id']?.toString(),
      user: json['user'] != null
          ? FullProfileUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      profile: json['profile'] != null
          ? FullProfileInfo.fromJson(json['profile'] as Map<String, dynamic>)
          : null,
      contactInfo: json['contact_info'] as Map<String, dynamic>?,
      stats: json['stats'] != null
          ? FullProfileStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      experiences: (json['experiences'] as List<dynamic>?)
              ?.map((e) => ExperienceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      education: (json['education'] as List<dynamic>?)
              ?.map((e) =>
                  EducationDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      publications: (json['publications'] as List<dynamic>?)
              ?.map(
                  (e) => PublicationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      awards: (json['awards'] as List<dynamic>?)
              ?.map((e) => AwardModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      licenses: (json['licenses'] as List<dynamic>?)
              ?.map((e) =>
                  MedicalLicenseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      socialProfiles: (json['social_profiles'] as List<dynamic>?)
              ?.map((e) =>
                  SocialProfileModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      businessHours: (json['business_hours'] as List<dynamic>?)
              ?.map((e) =>
                  BusinessHourModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => InterestModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      privacySettings: json['privacy_settings'] != null
          ? Map<String, dynamic>.from(json['privacy_settings'] as Map)
          : null,
      profileCompletionPercentage: json['profile_completion'] != null
          ? (json['profile_completion']['percentage'] as num?)?.toInt()
          : null,
      profileCompletionSections: json['profile_completion'] != null
          ? (json['profile_completion']['sections'] as Map?)?.cast<String, dynamic>()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'is_own_profile': isOwnProfile,
      'is_following': isFollowing,
      'is_friend': isFriend,
      'connection_status': connectionStatus,
      'friend_request_id': friendRequestId,
      'user': user?.toJson(),
      'profile': profile?.toJson(),
      'contact_info': contactInfo,
      'stats': stats?.toJson(),
      'experiences': experiences.map((e) => e.toJson()).toList(),
      'education': education.map((e) => e.toJson()).toList(),
      'publications': publications.map((e) => e.toJson()).toList(),
      'awards': awards.map((e) => e.toJson()).toList(),
      'licenses': licenses.map((e) => e.toJson()).toList(),
      'social_profiles': socialProfiles.map((e) => e.toJson()).toList(),
      'business_hours': businessHours.map((e) => e.toJson()).toList(),
      'interests': interests.map((e) => e.toJson()).toList(),
      'privacy_settings': privacySettings,
      'profile_completion': {
        'percentage': profileCompletionPercentage,
        'sections': profileCompletionSections,
      },
    };
  }

  /// Display name
  String get fullName =>
      '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
}

/// User basic info from v5 response
class FullProfileUser {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? specialty;
  String? licenseNo;
  String? clinicName;
  String? college;
  String? city;
  String? state;
  String? country;
  String? countryOrigin;
  String? stateOrigin;
  String? practicingCountry;
  String? gender;
  String? dob;
  String? userType;
  bool? verified;
  String? username;
  String? title;
  String? profilePic;
  String? coverPic;
  String? createdAt;

  FullProfileUser({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.specialty,
    this.licenseNo,
    this.clinicName,
    this.college,
    this.city,
    this.state,
    this.country,
    this.countryOrigin,
    this.stateOrigin,
    this.practicingCountry,
    this.gender,
    this.dob,
    this.userType,
    this.verified,
    this.username,
    this.title,
    this.profilePic,
    this.coverPic,
    this.createdAt,
  });

  factory FullProfileUser.fromJson(Map<String, dynamic> json) {
    return FullProfileUser(
      id: json['id']?.toString(),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      specialty: json['specialty'] as String?,
      licenseNo: json['license_no'] as String?,
      clinicName: json['clinic_name'] as String?,
      college: json['college'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      countryOrigin: json['country_origin'] as String?,
      stateOrigin: json['state_origin'] as String?,
      practicingCountry: json['practicing_country'] as String?,
      gender: json['gender'] as String?,
      dob: json['dob'] as String?,
      userType: json['user_type'] as String?,
      verified: json['verified'] is bool ? json['verified'] : false,
      username: json['username'] as String?,
      title: json['title'] as String?,
      profilePic: AppData.fullImageUrl(json['profile_pic'] as String?),
      coverPic: AppData.fullImageUrl(json['cover_pic'] as String?),
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'specialty': specialty,
      'license_no': licenseNo,
      'clinic_name': clinicName,
      'college': college,
      'city': city,
      'state': state,
      'country': country,
      'country_origin': countryOrigin,
      'practicing_country': practicingCountry,
      'gender': gender,
      'dob': dob,
      'user_type': userType,
      'verified': verified,
      'username': username,
      'title': title,
      'profile_pic': profilePic,
      'cover_pic': coverPic,
      'created_at': createdAt,
    };
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
}

/// Profile info section from v5 response
class FullProfileInfo {
  String? aboutMe;
  String? address;
  String? birthplace;
  String? livesIn;
  String? languages;

  FullProfileInfo({
    this.aboutMe,
    this.address,
    this.birthplace,
    this.livesIn,
    this.languages,
  });

  factory FullProfileInfo.fromJson(Map<String, dynamic> json) {
    return FullProfileInfo(
      aboutMe: json['about_me'] as String?,
      address: json['address'] as String?,
      birthplace: json['birthplace'] as String?,
      livesIn: json['lives_in'] as String?,
      languages: json['languages'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'about_me': aboutMe,
      'address': address,
      'birthplace': birthplace,
      'lives_in': livesIn,
      'languages': languages,
    };
  }
}

/// Stats from v5 response
class FullProfileStats {
  int? totalFollowers;
  int? totalFollowing;
  int? totalPosts;
  int? totalConnections;
  int? pendingFriendRequests;

  FullProfileStats({
    this.totalFollowers,
    this.totalFollowing,
    this.totalPosts,
    this.totalConnections,
    this.pendingFriendRequests,
  });

  factory FullProfileStats.fromJson(Map<String, dynamic> json) {
    return FullProfileStats(
      totalFollowers: json['total_followers'] as int?,
      totalFollowing: json['total_following'] as int?,
      totalPosts: json['total_posts'] as int?,
      totalConnections: json['total_connections'] as int?,
      pendingFriendRequests: json['pending_friend_requests'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_followers': totalFollowers,
      'total_following': totalFollowing,
      'total_posts': totalPosts,
      'total_connections': totalConnections,
      'pending_friend_requests': pendingFriendRequests,
    };
  }
}
