// ignore_for_file: must_be_immutable
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/place_live_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {}

class LoadDataValues extends ProfileEvent {
  @override
  List<Object?> get props => [];
}

class ChangePasswordVisibilityEvent extends ProfileEvent {
  ChangePasswordVisibilityEvent({required this.value});

  bool value;

  @override
  List<Object?> get props => [
        value,
      ];
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
  List<Object?> get props => [
        value,
      ];
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

  UpdateProfileEvent({
    this.userProfile,
    this.updateProfileSection,
    this.interestModel,
    this.workEducationModel,
    this.userProfilePrivacyModel,
    this.personalInfoPrivacy,
    this.aboutMePrivacy,
  });

  @override
  List<Object?> get props => [
        updateProfileSection,
        userProfile,
        interestModel,
        workEducationModel,
        userProfilePrivacyModel,
        personalInfoPrivacy,
        aboutMePrivacy
      ];
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
      this.privacy);

  @override
  // TODO: implement props
  List<Object?> get props => [
        id,
        companyName,
        position,
        address,
        degree,
        course,
        workType,
        startDate,
        endDate,
        currentStatus,
        description,
        privacy
      ];
}

class UpdateAddHobbiesInterestEvent extends ProfileEvent {
  String id;
  String favt_tv_shows;
  String favt_movies;
  String favt_books;
  String favt_writers;
  String favt_music_bands;
  String favt_games;

  UpdateAddHobbiesInterestEvent(
    this.id,
    this.favt_tv_shows,
    this.favt_movies,
    this.favt_books,
    this.favt_writers,
    this.favt_music_bands,
    this.favt_games,
  );

  @override
  // TODO: implement props
  List<Object?> get props => [
        id,
        favt_tv_shows,
        favt_movies,
        favt_books,
        favt_writers,
        favt_music_bands,
        favt_games,
      ];
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

class UpdateUniversityDropdownValues extends ProfileEvent {
  final String selectedStateDropdownValue;

  UpdateUniversityDropdownValues(this.selectedStateDropdownValue);

  @override
  // TODO: implement props
  List<Object?> get props => [selectedStateDropdownValue];
}
