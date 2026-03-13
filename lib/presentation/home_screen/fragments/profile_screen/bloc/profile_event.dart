// ignore_for_file: must_be_immutable
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/place_live_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {}

// ── V5 Full Profile Events ──────────────────────────────

/// Load full profile from v5 API (all sections in one call)
class LoadFullProfileEvent extends ProfileEvent {
  final String? userId;
  LoadFullProfileEvent({this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Refresh a specific profile section after CRUD
class RefreshProfileSectionEvent extends ProfileEvent {
  final String section; // experiences, education, publications, awards, licenses, social_profiles, business_hours
  RefreshProfileSectionEvent({required this.section});

  @override
  List<Object?> get props => [section];
}

/// CRUD events for v5 profile sections
class StoreExperienceEvent extends ProfileEvent {
  final String position;
  final String companyName;
  final String startDate;
  final String? endDate;
  final String? location;
  final String? description;
  StoreExperienceEvent({required this.position, required this.companyName, required this.startDate, this.endDate, this.location, this.description});
  @override
  List<Object?> get props => [position, companyName, startDate];
}

class UpdateExperienceEvent extends ProfileEvent {
  final int id;
  final String position;
  final String companyName;
  final String startDate;
  final String? endDate;
  final String? location;
  final String? description;
  UpdateExperienceEvent({required this.id, required this.position, required this.companyName, required this.startDate, this.endDate, this.location, this.description});
  @override
  List<Object?> get props => [id, position, companyName, startDate];
}

class DeleteExperienceEvent extends ProfileEvent {
  final int id;
  DeleteExperienceEvent({required this.id});
  @override
  List<Object?> get props => [id];
}

class StoreEducationEvent extends ProfileEvent {
  final String degree;
  final String institution;
  final String? fieldOfStudy;
  final int startYear;
  final int? endYear;
  final bool currentStudy;
  final String? gpa;
  final String? honors;
  final String? thesisTitle;
  final String? description;
  final String? location;
  final String? specialization;
  final String? activities;
  final String privacy;
  StoreEducationEvent({required this.degree, required this.institution, this.fieldOfStudy, required this.startYear, this.endYear, this.currentStudy = false, this.gpa, this.honors, this.thesisTitle, this.description, this.location, this.specialization, this.activities, this.privacy = 'public'});
  @override
  List<Object?> get props => [degree, institution, startYear];
}

class UpdateEducationDetailEvent extends ProfileEvent {
  final int id;
  final String degree;
  final String institution;
  final String? fieldOfStudy;
  final int startYear;
  final int? endYear;
  final bool currentStudy;
  final String? gpa;
  final String? honors;
  final String? thesisTitle;
  final String? description;
  final String? location;
  final String? specialization;
  final String? activities;
  final String privacy;
  UpdateEducationDetailEvent({required this.id, required this.degree, required this.institution, this.fieldOfStudy, required this.startYear, this.endYear, this.currentStudy = false, this.gpa, this.honors, this.thesisTitle, this.description, this.location, this.specialization, this.activities, this.privacy = 'public'});
  @override
  List<Object?> get props => [id, degree, institution, startYear];
}

class DeleteEducationEvent extends ProfileEvent {
  final int id;
  DeleteEducationEvent({required this.id});
  @override
  List<Object?> get props => [id];
}

class StorePublicationEvent extends ProfileEvent {
  final String title;
  final String journalName;
  final String publicationDate;
  final String? coAuthor;
  final String? abstract_;
  final String? keywords;
  final String? impactFactor;
  final String? citations;
  final String? doiLink;
  final String privacy;
  StorePublicationEvent({required this.title, required this.journalName, required this.publicationDate, this.coAuthor, this.abstract_, this.keywords, this.impactFactor, this.citations, this.doiLink, this.privacy = 'public'});
  @override
  List<Object?> get props => [title, journalName, publicationDate];
}

class UpdatePublicationEvent extends ProfileEvent {
  final int id;
  final String title;
  final String journalName;
  final String publicationDate;
  final String? coAuthor;
  final String? abstract_;
  final String? keywords;
  final String? impactFactor;
  final String? citations;
  final String? doiLink;
  final String privacy;
  UpdatePublicationEvent({required this.id, required this.title, required this.journalName, required this.publicationDate, this.coAuthor, this.abstract_, this.keywords, this.impactFactor, this.citations, this.doiLink, this.privacy = 'public'});
  @override
  List<Object?> get props => [id, title, journalName, publicationDate];
}

class DeletePublicationEvent extends ProfileEvent {
  final int id;
  DeletePublicationEvent({required this.id});
  @override
  List<Object?> get props => [id];
}

class StoreAwardEvent extends ProfileEvent {
  final String awardName;
  final String? awardingBody;
  final String? dateReceived;
  final String? description;
  final String? level;
  final String privacy;
  StoreAwardEvent({required this.awardName, this.awardingBody, this.dateReceived, this.description, this.level, this.privacy = 'public'});
  @override
  List<Object?> get props => [awardName];
}

class UpdateAwardEvent extends ProfileEvent {
  final int id;
  final String awardName;
  final String? awardingBody;
  final String? dateReceived;
  final String? description;
  final String? level;
  final String privacy;
  UpdateAwardEvent({required this.id, required this.awardName, this.awardingBody, this.dateReceived, this.description, this.level, this.privacy = 'public'});
  @override
  List<Object?> get props => [id, awardName];
}

class DeleteAwardEvent extends ProfileEvent {
  final int id;
  DeleteAwardEvent({required this.id});
  @override
  List<Object?> get props => [id];
}

class StoreLicenseEvent extends ProfileEvent {
  final String licenseType;
  final String licenseNumber;
  final String issuingAuthority;
  final String issueDate;
  final String? expiryDate;
  final String privacy;
  StoreLicenseEvent({required this.licenseType, required this.licenseNumber, required this.issuingAuthority, required this.issueDate, this.expiryDate, this.privacy = 'public'});
  @override
  List<Object?> get props => [licenseType, licenseNumber];
}

class UpdateLicenseEvent extends ProfileEvent {
  final int id;
  final String licenseType;
  final String licenseNumber;
  final String issuingAuthority;
  final String issueDate;
  final String? expiryDate;
  final String privacy;
  UpdateLicenseEvent({required this.id, required this.licenseType, required this.licenseNumber, required this.issuingAuthority, required this.issueDate, this.expiryDate, this.privacy = 'public'});
  @override
  List<Object?> get props => [id, licenseType, licenseNumber];
}

class DeleteLicenseEvent extends ProfileEvent {
  final int id;
  DeleteLicenseEvent({required this.id});
  @override
  List<Object?> get props => [id];
}

class StoreSocialProfileEvent extends ProfileEvent {
  final String platform;
  final String profileUrl;
  final String? username;
  final bool isPublic;
  StoreSocialProfileEvent({required this.platform, required this.profileUrl, this.username, this.isPublic = true});
  @override
  List<Object?> get props => [platform, profileUrl];
}

class UpdateSocialProfileEvent extends ProfileEvent {
  final int id;
  final String platform;
  final String profileUrl;
  final String? username;
  final bool isPublic;
  UpdateSocialProfileEvent({required this.id, required this.platform, required this.profileUrl, this.username, this.isPublic = true});
  @override
  List<Object?> get props => [id, platform, profileUrl];
}

class DeleteSocialProfileEvent extends ProfileEvent {
  final int id;
  DeleteSocialProfileEvent({required this.id});
  @override
  List<Object?> get props => [id];
}

class StoreBusinessHourEvent extends ProfileEvent {
  final String locationName;
  final String? locationAddress;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final String? notes;
  StoreBusinessHourEvent({required this.locationName, this.locationAddress, required this.dayOfWeek, required this.startTime, required this.endTime, this.isAvailable = true, this.notes});
  @override
  List<Object?> get props => [locationName, dayOfWeek, startTime];
}

class UpdateBusinessHourEvent extends ProfileEvent {
  final dynamic id;
  final String locationName;
  final String? locationAddress;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final String? notes;
  UpdateBusinessHourEvent({required this.id, required this.locationName, this.locationAddress, required this.dayOfWeek, required this.startTime, required this.endTime, this.isAvailable = true, this.notes});
  @override
  List<Object?> get props => [id, locationName, dayOfWeek, startTime];
}

class DeleteBusinessHourEvent extends ProfileEvent {
  final dynamic id;
  DeleteBusinessHourEvent({required this.id});
  @override
  List<Object?> get props => [id];
}

/// V5 — Update user table fields via bottom sheet
class UpdateProfileV5Event extends ProfileEvent {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? licenseNo;
  final String? specialty;
  final String? dob;
  final String? gender;
  final String? country;
  final String? city;
  final String? state;
  final String? countryOrigin;
  final String? stateOrigin;
  final String? clinicName;
  final String? college;

  UpdateProfileV5Event({
    this.firstName,
    this.lastName,
    this.phone,
    this.licenseNo,
    this.specialty,
    this.dob,
    this.gender,
    this.country,
    this.city,
    this.state,
    this.countryOrigin,
    this.stateOrigin,
    this.clinicName,
    this.college,
  });
  @override
  List<Object?> get props => [firstName, lastName, phone, specialty, dob, gender];
}

/// V5 — Update profiles table fields via bottom sheet
class UpdateAboutMeV5Event extends ProfileEvent {
  final String? aboutMe;
  final String? address;
  final String? birthplace;
  final String? livesIn;
  final String? languages;

  UpdateAboutMeV5Event({
    this.aboutMe,
    this.address,
    this.birthplace,
    this.livesIn,
    this.languages,
  });
  @override
  List<Object?> get props => [aboutMe, address, birthplace, livesIn, languages];
}

class LoadDataValues extends ProfileEvent {
  @override
  List<Object?> get props => [];
}

class ChangePasswordVisibilityEvent extends ProfileEvent {
  ChangePasswordVisibilityEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [value];
}

class SetUserFollow extends ProfileEvent {
  String userId;
  String follow;
  SetUserFollow(this.userId, this.follow);
  @override
  List<Object?> get props => [userId, follow];
}

//
// ///Event for changing checkbox
class ChangeCheckBoxEvent extends ProfileEvent {
  ChangeCheckBoxEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [value];
}

class LoadPageEvent extends ProfileEvent {
  int? page;
  String? userId;

  LoadPageEvent({this.page, this.userId});

  @override
  List<Object?> get props => [page, userId];
}

class UpdateProfilePicEvent extends ProfileEvent {
  String? filePath;
  bool? isProfilePicture;

  UpdateProfilePicEvent({this.filePath, this.isProfilePicture});

  @override
  List<Object?> get props => [filePath, isProfilePicture];
}

class UpdateProfileEvent extends ProfileEvent {
  int? updateProfileSection;

  UserProfile? userProfile;
  List<InterestModel>? interestModel;
  List<WorkEducationModel>? workEducationModel;
  List<PlaceLiveModel>? placeLiveModel;
  UserProfilePrivacyModel? userProfilePrivacyModel;
  String? personalInfoPrivacy;
  String? aboutMePrivacy;

  UpdateProfileEvent({this.userProfile, this.updateProfileSection, this.interestModel, this.workEducationModel, this.userProfilePrivacyModel, this.personalInfoPrivacy, this.aboutMePrivacy});

  @override
  List<Object?> get props => [updateProfileSection, userProfile, interestModel, workEducationModel, userProfilePrivacyModel, personalInfoPrivacy, aboutMePrivacy];
}

class LoadPageEvent1 extends ProfileEvent {
  int? page;

  LoadPageEvent1({this.page});

  @override
  List<Object?> get props => [page];
}

class CheckIfNeedMoreDataEvent extends ProfileEvent {
  final int index;

  CheckIfNeedMoreDataEvent({required this.index});

  @override
  List<Object?> get props => [index];
}

class UpdateFirstDropdownValue extends ProfileEvent {
  final String newValue;

  UpdateFirstDropdownValue(this.newValue);

  @override
  // TODO: implement props
  List<Object?> get props => [newValue];
}

class UpdateAddWorkEductionEvent extends ProfileEvent {
  String id;
  String companyName;
  String position;
  String address;
  String degree;
  String course;
  String workType;
  String startDate;
  String endDate;
  String currentStatus;
  String description;
  String privacy;

  UpdateAddWorkEductionEvent(
    this.id,
    this.companyName,
    this.position,
    this.address,
    this.degree,
    this.course,
    this.workType,
    this.startDate,
    this.endDate,
    this.currentStatus,
    this.description,
    this.privacy,
  );

  @override
  // TODO: implement props
  List<Object?> get props => [id, companyName, position, address, degree, course, workType, startDate, endDate, currentStatus, description, privacy];
}

class UpdateAddHobbiesInterestEvent extends ProfileEvent {
  String id;
  String hobbies;
  String favt_tv_shows;
  String favt_movies;
  String favt_books;
  String favt_writers;
  String favt_music_bands;
  String favt_games;

  UpdateAddHobbiesInterestEvent(this.id, this.hobbies, this.favt_tv_shows, this.favt_movies, this.favt_books, this.favt_writers, this.favt_music_bands, this.favt_games);

  @override
  List<Object?> get props => [id, hobbies, favt_tv_shows, favt_movies, favt_books, favt_writers, favt_music_bands, favt_games];
}

class UpdateSecondDropdownValues extends ProfileEvent {
  final String selectedFirstDropdownValue;

  UpdateSecondDropdownValues(this.selectedFirstDropdownValue);

  @override
  // TODO: implement props[
  List<Object?> get props => [selectedFirstDropdownValue];
}

class UpdateSpecialtyDropdownValue extends ProfileEvent {
  final String newValue;

  UpdateSpecialtyDropdownValue(this.newValue);

  @override
  // TODO: implement props
  List<Object?> get props => [newValue];
}

class DeleteWorkEducationEvent extends ProfileEvent {
  final String id;

  DeleteWorkEducationEvent(this.id);

  @override
  // TODO: implement props
  List<Object?> get props => [id];
}

class UpdateSpecialtyDropdownValue1 extends ProfileEvent {
  final String newValue;

  UpdateSpecialtyDropdownValue1(this.newValue);

  @override
  // TODO: implement props
  List<Object?> get props => [newValue];
}

// class UpdateUniversityDropdownValues extends ProfileEvent {
//   final String selectedStateDropdownValue;
//
//   UpdateUniversityDropdownValues(this.selectedStateDropdownValue);
//
//   @override
//   // TODO: implement props
//   List<Object?> get props => [selectedStateDropdownValue];
// }

/// Send a connection (friend) request from the profile page
class SendConnectionRequestEvent extends ProfileEvent {
  final String userId;
  SendConnectionRequestEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

/// Cancel a pending sent connection request from the profile page
class CancelConnectionRequestEvent extends ProfileEvent {
  final String requestId;
  CancelConnectionRequestEvent(this.requestId);
  @override
  List<Object?> get props => [requestId];
}
