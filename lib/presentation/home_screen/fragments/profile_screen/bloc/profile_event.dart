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

  UpdateProfilePicEvent({this.filePath,this.isProfilePicture});

  @override
  List<Object?> get props => [filePath,isProfilePicture
  ];
}

class UpdateProfileEvent extends ProfileEvent {
  UserProfile? userProfile;
  List<InterestModel>? interestModel;
  List<WorkEducationModel>? workEducationModel;
  List<PlaceLiveModel>? placeLiveModel;
  UserProfilePrivacyModel? userProfilePrivacyModel;

  UpdateProfileEvent(
      {this.userProfile,
      this.interestModel,
      this.workEducationModel,
      this.userProfilePrivacyModel});

  @override
  List<Object?> get props =>
      [userProfile, interestModel, workEducationModel, userProfilePrivacyModel];
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
