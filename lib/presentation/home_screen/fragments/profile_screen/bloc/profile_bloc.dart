import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ApiService postService = ApiService(Dio());
  UserProfile? userProfile;
  List<InterestModel>? interestList = [];
  bool isMe = true;
  List<WorkEducationModel>? workEducationList = [];
  UserProfilePrivacyModel? userProfilePrivacyModel;
  int pageNumber = 1;
  int numberOfPage = 1;
  List<Post> postList = [];
  final int nextPageTrigger = 1;
  String? country;
  String? stateName;
  String? university;
  String? specialtyName;

  ProfileBloc() : super(DataInitial()) {
    on<UpdateFirstDropdownValue>(_updateFirstDropdownValue);
    on<UpdateSecondDropdownValues>(_updateSecondDropdownValues);
    on<UpdateSpecialtyDropdownValue>(_updateSpecialtyDropdownValues);
    on<UpdateUniversityDropdownValues>(_updateUniversityDropdownValues);
    on<LoadPageEvent>(_onGetProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateProfilePicEvent>(_updateProfilePicture);
    on<LoadPageEvent1>(_onGetPosts);

    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == postList.length - nextPageTrigger) {
        add(LoadPageEvent1(page: pageNumber));
      }
    });
  }

  _onGetPosts(LoadPageEvent1 event, Emitter<ProfileState> emit) async {
    if (event.page == 1) {
      postList.clear();
      pageNumber = 1;
      // emit(PaginationLoadingState());
    }
    print('repsones1');
    // try {
    PostDataModel response = await postService.getMyPosts(
        'Bearer ${AppData.userToken}', '$pageNumber', AppData.logInUserId);
    print('repsones$response');
    numberOfPage = response.posts?.lastPage ?? 0;
    if (pageNumber < numberOfPage + 1) {
      pageNumber = pageNumber + 1;
      postList.addAll(response.posts?.data ?? []);
    }
    emit(PaginationLoadedState(
        (state as PaginationLoadedState).firstDropdownValues,
        (state as PaginationLoadedState).selectedFirstDropdownValue,
        (state as PaginationLoadedState).secondDropdownValues,
        (state as PaginationLoadedState).selectedSecondDropdownValue,
        (state as PaginationLoadedState).specialtyDropdownValue,
        (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
        [],
        ''));
    // emit(PaginationLoadedState());
    // emit(DataLoaded(postList));
    // } catch (e) {
    //   print(e);
    //
    //   emit(PaginationLoadedState());
    //
    //   // emit(DataError('An error occurred $e'));
    // }
  }

  _onGetProfile(LoadPageEvent event, Emitter<ProfileState> emit) async {
    emit(PaginationLoadingState());
    // try {
    if (pageNumber == 1) {
      print(event.userId);
      PostDataModel postDataModelResponse = await postService.getMyPosts(
          'Bearer ${AppData.userToken}', '1', event.userId!);
      print('repsones$postDataModelResponse');
      UserProfile response = await postService.getProfile(
          'Bearer ${AppData.userToken}', event.userId!);
      List<InterestModel> response1 = await postService.getInterests(
          'Bearer ${AppData.userToken}', event.userId!);

      List<WorkEducationModel> response2 = await postService.getWorkEducation(
          'Bearer ${AppData.userToken}', event.userId!);
      numberOfPage = postDataModelResponse.posts?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        postList.addAll(postDataModelResponse.posts?.data ?? []);
      }
      if (event.userId == AppData.logInUserId) {
        isMe = true;
      } else {
        isMe = false;
      }

      interestList!.clear();
      interestList!.addAll(response1);
      workEducationList!.clear();
      workEducationList!.addAll(response2);
      userProfile = response;
    }
    List<String>? countriesList = await _onGetCountries();
    List<String>? stateList =
        await _onGetStates(userProfile?.user?.country ?? countriesList!.first);
    List<String>? specialtyList = await _onGetSpecialty();
    print('data ${userProfile?.user?.city ?? stateList!.first}');
    emit(PaginationLoadedState(
        countriesList!,
        userProfile?.user?.country ?? countriesList.first,
        stateList!,
        userProfile?.user?.city ?? stateList.first,
        specialtyList!,
        userProfile?.user?.specialty ?? specialtyList.first,
        [],
        ''));
    // add(UpdateSecondDropdownValues(countriesList.first));
    // emit(PaginationLoadedState(
    //   (state as PaginationLoadedState).firstDropdownValues,
    //   (state as PaginationLoadedState).selectedFirstDropdownValue,
    //   // secondDropdownValues,
    //   // secondDropdownValues.first,
    //   (state as PaginationLoadedState).secondDropdownValues,
    //   (state as PaginationLoadedState).selectedSecondDropdownValue,
    //
    //   (state as PaginationLoadedState).specialtyDropdownValue,
    //   (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
    //   [],
    //   ''
    // ));
    // emit(PaginationLoadedState());
    // emit(DataLoaded(postList));
    // } catch (e) {
    //   print(e);
    //
    //   emit(PaginationLoadedState());
    //
    //   // emit(DataError('An error occurred $e'));
    // }
  }

  void _updateFirstDropdownValue(
      UpdateFirstDropdownValue event, Emitter<ProfileState> emit) {
    emit(PaginationLoadedState(
        (state as PaginationLoadedState).firstDropdownValues,
        event.newValue,
        [],
        'Select State',
        [],
        'select Specialty',
        [],
        ''));
    print("DD ${event.newValue}");
    add(UpdateSecondDropdownValues(event.newValue));
  }

  Future<void> _updateProfilePicture(
      UpdateProfilePicEvent event, Emitter<ProfileState> emit) async {
    var response;
    if (event.isProfilePicture ?? false) {
      response = await postService.uploadProfilePicture(
          'Bearer ${AppData.userToken}', event.filePath!);
    } else {
      response = await postService.uploadCoverPicture(
          'Bearer ${AppData.userToken}', event.filePath!);
    }
    UserProfile response1 = await postService.getProfile(
        'Bearer ${AppData.userToken}', AppData.logInUserId);
    print(AppData.userToken);
    userProfile = response1;
    print("DD ${response.data}");
    emit(PaginationLoadedState(
      (state as PaginationLoadedState).firstDropdownValues,
      (state as PaginationLoadedState).selectedFirstDropdownValue,
      (state as PaginationLoadedState).secondDropdownValues,
      (state as PaginationLoadedState).selectedSecondDropdownValue,
      (state as PaginationLoadedState).specialtyDropdownValue,
      (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
      (state as PaginationLoadedState).universityDropdownValue,
      (state as PaginationLoadedState).selectedUniversityDropdownValue,
    ));

    // add(UpdateSecondDropdownValues(event.newValue));
  }

  _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    // emit(DataInitial());
    // ProgressDialogUtils.showProgressDialog();
    // try {
    print((state as PaginationLoadedState).selectedSecondDropdownValue);
    final response = await postService.getProfileUpdate(
      'Bearer ${AppData.userToken}',
      event.userProfile!.user?.firstName ?? '',
      event.userProfile!.user?.lastName ?? "",
      event.userProfile!.user?.phone ?? ' ',
      event.userProfile!.user?.licenseNo ?? " ",
      specialtyName ?? event.userProfile?.user?.specialty ?? ' ',
      // (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
      // event.userProfile!.user?.specialty ?? "",
      event.userProfile?.user?.dob ?? " ",
      country ?? event.userProfile?.user?.country ?? ' ',
      // event.userProfile!.user?.country ?? AppData.countryName,
      stateName ?? event.userProfile?.user?.city ?? ' ',
      country ?? event.userProfile?.user?.country ?? " ",
      // event.userProfile!.user?.country ?? AppData.countryName,
      event.userProfile?.privacySetting?[3].visibility ?? 'globe',
      event.userProfile?.privacySetting?[4].visibility ?? 'globe',
      event.userProfile?.privacySetting?[5].visibility ?? 'globe',
      event.userProfile?.privacySetting?[8].visibility ?? 'globe',
      'globe',
      // event.userProfile?.privacySetting?[5].visibility ?? 'globe',
      'globe',
      // event.userProfile?.privacySetting?[11].visibility ?? 'globe',
      event.userProfile?.privacySetting?[10].visibility ?? 'globe',
      event.userProfile?.privacySetting?[11].visibility ?? 'globe',
      event.userProfile?.privacySetting?[12].visibility ?? 'globe',
    );
    print('profile Update : ${response.response.data}');
    // print(response.response.data);
    // print(event.userProfile!.user?.firstName);
    // print(event.userProfile!.user?.lastName);
    // print(event.userProfile!.user?.phone);
    // print(event.userProfile!.user?.licenseNo);
    // print(event.userProfile!.user?.specialty);
    // print(event.userProfile!.user?.dob);
    // print(event.userProfile!.user?.country);
    // print(event.userProfile!.user?.city);
    // print(event.userProfile!.user?.country);
    // print(event.userProfilePrivacyModel!.dobPrivacy);
    // print(event.userProfilePrivacyModel!.emailPrivacy);
    // print(event.userProfilePrivacyModel!.genderPrivacy);
    // print(event.userProfilePrivacyModel!.phonePrivacy);
    // print(event.userProfilePrivacyModel!.licenseNumberPrivacy);
    // print(event.userProfilePrivacyModel!.specialtyPrivacy);
    // print(event.userProfilePrivacyModel!.countryPrivacy);
    // print(event.userProfilePrivacyModel!.cityPrivacy);
    // print(event.userProfilePrivacyModel!.countryOrigin);

    final response1 = await postService.getWorkEducationUpdate(
        'Bearer ${AppData.userToken}', event.workEducationModel ?? []);

    print(response1.response.data);
    final response3 = await postService.getInterestsUpdate(
        'Bearer ${AppData.userToken}', event.interestModel!);

    final response2 = await postService.updateAboutMe(
      'Bearer ${AppData.userToken}',
      event.userProfile?.profile?.aboutMe ?? '',
      event.userProfile?.profile?.address ?? '',
      event.userProfile?.profile?.birthplace ?? '',
      event.userProfile?.profile?.livesIn ?? '',
      event.userProfile?.privacySetting?[0].visibility ?? 'lock',
      event.userProfile?.privacySetting?[1].visibility ?? 'lock',
      event.userProfile?.privacySetting?[2].visibility ?? 'lock',
      event.userProfile?.privacySetting?[6].visibility ?? 'lock',
      event.userProfile?.privacySetting?[7].visibility ?? 'lock',
    );

    // final response3 = await postService.getPlacesLivedUpdate(
    //   'Bearer ${AppData.userToken}',
    //   '','',
    //   event.userProfile?.privacySetting?[0].visibility??'lock'
    //
    // );
    // emit(PaginationLoadedState());
    emit(PaginationLoadedState(
        (state as PaginationLoadedState).firstDropdownValues,
        (state as PaginationLoadedState).selectedFirstDropdownValue,
        // secondDropdownValues,
        // secondDropdownValues.first,
        (state as PaginationLoadedState).secondDropdownValues,
        (state as PaginationLoadedState).selectedSecondDropdownValue,
        (state as PaginationLoadedState).specialtyDropdownValue,
        (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
        [],
        ''));
    // } else {
    //   ProgressDialogUtils.hideProgressDialog();
    //   emit(LoginFailure(error: 'Invalid credentials'));
    // }
    //   } catch (e) {
    //     print(e);
    //     emit(DataError('An error occurred'));
    //   }
  }

  void _updateSecondDropdownValues(
      UpdateSecondDropdownValues event, Emitter<ProfileState> emit) async {
    List<String>? secondDropdownValues =
        await _onGetStates(event.selectedFirstDropdownValue);

    if (secondDropdownValues?.first.isNotEmpty ?? false) {
      List<String>? universityDropdownValues =
          await _onGetUniversities(secondDropdownValues!.first ?? '');
    }
    emit(PaginationLoadedState(
        (state as PaginationLoadedState).firstDropdownValues,
        event.selectedFirstDropdownValue,
        secondDropdownValues ?? [],
        secondDropdownValues?.first ?? '',
        (state as PaginationLoadedState).specialtyDropdownValue,
        (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
        [],
        ''));
    print("DD ${secondDropdownValues?.first}");
    // add(UpdateSpecialtyDropdownValue(secondDropdownValues!.first));
  }

  void _updateUniversityDropdownValues(
      UpdateUniversityDropdownValues event, Emitter<ProfileState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    List<String>? secondDropdownValues =
        await _onGetUniversities(event.selectedStateDropdownValue);
    emit(PaginationLoadedState(
      (state as PaginationLoadedState).firstDropdownValues,
      (state as PaginationLoadedState).selectedFirstDropdownValue,
      (state as PaginationLoadedState).secondDropdownValues,
      event.selectedStateDropdownValue,
      (state as PaginationLoadedState).specialtyDropdownValue,
      (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
      secondDropdownValues ?? [],
      secondDropdownValues!.isEmpty ? '' : secondDropdownValues.first,
    ));
  }

  void _updateSpecialtyDropdownValues(
      UpdateSpecialtyDropdownValue event, Emitter<ProfileState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    List<String>? secondDropdownValues = await _onGetSpecialty();
    print("specialty1${event.newValue}");
    emit(PaginationLoadedState(
        (state as PaginationLoadedState).firstDropdownValues,
        (state as PaginationLoadedState).selectedFirstDropdownValue,
        (state as PaginationLoadedState).secondDropdownValues,
        (state as PaginationLoadedState).selectedSecondDropdownValue,
        secondDropdownValues!,
        secondDropdownValues.first,
        [],
        ''));
  }

  Future<List<String>?> _onGetCountries() async {
    // emit(DataLoading());
    try {
      final response = await postService.getCountries();
      print(response.countries!.length.toString());
      if (response.countries!.isNotEmpty) {
        // emit(DataSuccess(countriesModel: response));
        List<String> list = [];
        // list.add('Select Country');
        for (var element in response.countries!) {
          list.add(element.countryName!);
        }
        return list;
      } else {
        return [];
        // emit(DataFailure(error: 'Failed to load data'));
      }
    } catch (e) {
      print(e);
      // emit(DataFailure(error: 'An error occurred'));
    }
  }

  Future<List<String>?> _onGetSpecialty() async {
    // emit(DataLoading());
    try {
      final response = await postService.getSpecialty();
      if (response.data!.isNotEmpty) {
        // emit(DataSuccess(countriesModel: response));
        List<String> list = [];
        list.add('select Specialty');
        response.data!.forEach((element) {
          list.add(element['name']!);
        });
        return list;
      } else {
        return [];
        // emit(DataFailure(error: 'Failed to load data'));
      }
    } catch (e) {
      print(e);
      // emit(DataFailure(error: 'An error occurred'));
    }
  }

  _onGetStates(String value) async {
    // emit(DataLoading());
    try {
      final response = await postService.getStates(value);
      // if (response.data!.isNotEmpty) {
      // emit(DataSuccess(countriesModel: response));
      List<String> list = [];
      response.data!.forEach((element) {
        list.add(element['state_name']!);
      });
      return list;
    } catch (e) {
      print(e);
      // emit(DataFailure(error: 'An error occurred'));
    }
  }

  Future<List<String>>? _onGetUniversities(String value) async {
    // emit(DataLoading());
    try {
      final response = await postService.getUniversityByStates(value);
      print(response.data);
      // if (response.data!.isNotEmpty) {
      // emit(DataSuccess(countriesModel: response));
      log('response ${response.data}');
      List<String> list = [];
      // list.clear();
      // list.add('Add new University');
      response.data?.forEach((element) {
        if (element['name'] != null) {
          list.add(element['name']!);
        }
      });
      return list;
      // } else {
      //   return [];
      //   // emit(DataFailure(error: 'Failed to load data'));
      // }
    } catch (e) {
      return [];
      print(e);
      // emit(DataFailure(error: 'An error occurred'));
    }
  }
}
