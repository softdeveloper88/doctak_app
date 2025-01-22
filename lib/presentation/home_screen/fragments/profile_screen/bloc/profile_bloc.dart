import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../widgets/toast_widget.dart';
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
  String? aboutMePrivacy;
  String? personalInfoPrivacy;
  List<String>? specialtyList;

  ProfileBloc() : super(DataInitial()) {
    on<UpdateFirstDropdownValue>(_updateFirstDropdownValue);
    on<UpdateSecondDropdownValues>(_updateSecondDropdownValues);
    on<UpdateSpecialtyDropdownValue>(_updateSpecialtyDropdownValues);
    on<UpdateSpecialtyDropdownValue1>(_specialityData);
    on<UpdateUniversityDropdownValues>(_updateUniversityDropdownValues);
    on<LoadPageEvent>(_onGetProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateProfilePicEvent>(_updateProfilePicture);
    on<UpdateAddWorkEductionEvent>(_updateAddWorkEduction);
    on<UpdateAddHobbiesInterestEvent>(_updateAddHobbiesInterest);
    on<LoadPageEvent1>(_onGetPosts);
    on<DeleteWorkEducationEvent>(_deleteAddWorkEduction);
    on<SetUserFollow>(_setUserFollow);

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

    try {
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
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState());

      emit(DataError('An error occurred $e'));
    }
  }

  _onGetProfile(LoadPageEvent event, Emitter<ProfileState> emit) async {
    emit(PaginationLoadingState());
    try {
    if (pageNumber == 1) {
      print("data ${event.userId}");
      PostDataModel postDataModelResponse = await postService.getMyPosts(
          'Bearer ${AppData.userToken}', '1', event.userId ?? '');
      print('repsones$postDataModelResponse');
      UserProfile response = await postService.getProfile(
          'Bearer ${AppData.userToken}', event.userId!);
      print(response.toJson());
      List<InterestModel> response1 = await postService.getInterests(
          'Bearer ${AppData.userToken}', event.userId!);
      add(UpdateSecondDropdownValues(''));

      // var  response3 = await postService.getAboutMe(
      //     'Bearer ${AppData.userToken}');

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
    List<Countries>? countriesList = await _onGetCountries();
    List<String>? stateList = await _onGetStates(
        userProfile?.user?.country ?? countriesList?.first.countryName ?? '');
    print('countriesList $countriesList');
    print('user country ${userProfile?.user?.country}');
    List<String>? specialtyList = await _onGetSpecialty();
    emit(PaginationLoadedState(
        countriesList ?? [],
        userProfile?.user?.country ?? countriesList?.first.countryName ?? '',
        stateList ?? [],
        userProfile?.user?.city ?? stateList?.first ?? '',
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
    } catch (e) {
      print(e);

      // emit(PaginationLoadedState(e.toString()));

      emit(DataError('An error occurred $e'));
    }
  }

  Future<void> _updateFirstDropdownValue(
      UpdateFirstDropdownValue event, Emitter<ProfileState> emit) async {
    List<Countries>? countriesList = await _onGetCountries();
      print(countriesList);
    emit(PaginationLoadedState(countriesList ?? [], countriesList?.first.countryName ?? '',
        [], 'Select State', [], 'Select Specialty', [], ''));

    add(UpdateSecondDropdownValues(countriesList?.first.countryName ?? 'United Arab Emirates'));
    add(UpdateSpecialtyDropdownValue(countriesList?.first.countryName ?? 'United Arab Emirates'));
  }

  Future<void> _updateProfilePicture(
      UpdateProfilePicEvent event, Emitter<ProfileState> emit) async {
    var response;
    ProgressDialogUtils.showProgressDialog();

    if (event.isProfilePicture ?? false) {
      response = await postService.uploadProfilePicture(
          'Bearer ${AppData.userToken}', event.filePath!);
    } else {
      print(event.isProfilePicture);
      response = await postService.uploadCoverPicture(
          'Bearer ${AppData.userToken}', event.filePath!);
    }
    UserProfile response1 = await postService.getProfile(
        'Bearer ${AppData.userToken}', AppData.logInUserId);
    print(AppData.userToken);
    userProfile = response1;
    print("DD ${response.data}");
    ProgressDialogUtils.hideProgressDialog();

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
    try {
    // print((specialtyName ?? event.userProfile?.user?.specialty ?? ''));
    int privacyLength = (event.userProfile?.privacySetting?.length ?? 0);
    event.userProfile?.privacySetting?.forEach((e) {
      print('privacy ${e.recordType}');
    });
    if (event.updateProfileSection == 1) {
      final response = await postService.getProfileUpdate(
        'Bearer ${AppData.userToken}',
        event.userProfile?.user?.firstName ?? '',
        event.userProfile?.user?.lastName ?? "",
        event.userProfile?.user?.phone ?? '',
        event.userProfile?.user?.licenseNo ?? " ",
        specialtyName ?? event.userProfile?.user?.specialty ?? '',
        event.userProfile?.user?.dob ?? "",
        'male',
        country ?? event.userProfile?.user?.country ?? 'United Arab Emirates',
        stateName ?? event.userProfile?.user?.city ?? 'Dubai',
        country ?? event.userProfile?.user?.country ?? "United Arab Emirates",
        // event.userProfile?.privacySetting?[3].visibility ?? 'globe',
        // event.userProfile?.privacySetting?[4].visibility ?? 'globe',
        // event.userProfile?.privacySetting?[5].visibility ?? 'globe',
        // event.userProfile?.privacySetting?[8].visibility ?? 'globe',
        privacyLength >= 3
            ? event.userProfile?.privacySetting![3].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 4
            ? event.userProfile?.privacySetting![4].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 5
            ? event.userProfile?.privacySetting![5].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 8
            ? event.userProfile?.privacySetting![8].visibility ?? 'globe'
            : 'globe',
        'globe',
        'globe',
        privacyLength >= 10
            ? event.userProfile?.privacySetting![10].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 11
            ? event.userProfile?.privacySetting![11].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 12
            ? event.userProfile?.privacySetting![12].visibility ?? 'globe'
            : 'globe',
      );
    } else if (event.updateProfileSection == 2) {
      final response = await postService.getProfileUpdate(
        'Bearer ${AppData.userToken}',
        event.userProfile?.user?.firstName ?? '',
        event.userProfile?.user?.lastName ?? "",
        event.userProfile?.user?.phone ?? '',
        event.userProfile?.user?.licenseNo ?? " ",
        specialtyName ?? event.userProfile?.user?.specialty ?? '',
        event.userProfile?.user?.dob ?? "",
        'male',
        country ?? event.userProfile?.user?.country ?? 'United Arab Emirates',
        stateName ?? event.userProfile?.user?.city ?? 'Dubai',
        country ?? event.userProfile?.user?.country ?? "United Arab Emirates",
        // event.userProfile?.privacySetting?[3].visibility ?? 'globe',
        // event.userProfile?.privacySetting?[4].visibility ?? 'globe',
        // event.userProfile?.privacySetting?[5].visibility ?? 'globe',
        // event.userProfile?.privacySetting?[8].visibility ?? 'globe',
        privacyLength >= 3
            ? event.userProfile?.privacySetting![3].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 4
            ? event.userProfile?.privacySetting![4].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 5
            ? event.userProfile?.privacySetting![5].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 8
            ? event.userProfile?.privacySetting![8].visibility ?? 'globe'
            : 'globe',
        'globe',
        'globe',
        privacyLength >= 10
            ? event.userProfile?.privacySetting![10].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 11
            ? event.userProfile?.privacySetting![11].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 12
            ? event.userProfile?.privacySetting![12].visibility ?? 'globe'
            : 'globe',
      );
      final response2 = await postService.updateAboutMe(
        'Bearer ${AppData.userToken}',
        event.userProfile?.profile?.aboutMe ?? '...',
        event.userProfile?.profile?.address ?? '...',
        event.userProfile?.profile?.birthplace ?? '...',
        event.userProfile?.profile?.livesIn ?? '...',
        event.userProfile?.profile?.languages ?? '...',
        privacyLength >= 0
            ? event.userProfile?.privacySetting![0].visibility ?? 'lock'
            : 'lock',
        privacyLength >= 1
            ? event.userProfile?.privacySetting![1].visibility ?? 'lock'
            : 'lock',
        privacyLength >= 2
            ? event.userProfile?.privacySetting![2].visibility ?? 'lock'
            : 'lock',
        privacyLength >= 6
            ? event.userProfile?.privacySetting![6].visibility ?? 'lock'
            : 'lock',
        privacyLength >= 7
            ? event.userProfile?.privacySetting![7].visibility ?? 'lock'
            : 'lock',
        privacyLength >= 7
            ? event.userProfile?.privacySetting![7].visibility ?? 'lock'
            : 'lock',
      );
    } else if (event.updateProfileSection == 3) {
      // final response1 = await postService.getWorkEducationUpdate(
      //     'Bearer ${AppData.userToken}', event.workEducationModel ?? []);
      //
      // print(response1.data);
      // final response3 = await postService.getInterestsUpdate(
      //     'Bearer ${AppData.userToken}', event.interestModel!);
      //
      //   String dobPrivacy,
      //  String emailPrivacy,
      // String genderPrivacy,
      // String phonePrivacy,
      // String licenseNoPrivacy,
      // String specialtyPrivacy,
      // String countryPrivacy,
      // String cityPrivacy,
      // String countryOriginPrivacy
      // privacyLength >= 3 ? event.userProfile?.privacySetting![3].visibility ?? 'globe' : 'globe';
      // privacyLength >= 4 ? event.userProfile?.privacySetting![4].visibility ?? 'globe' : 'globe';
      // privacyLength >= 5 ? event.userProfile?.privacySetting![5].visibility ?? 'globe' : 'globe';
      // privacyLength >= 8 ? event.userProfile?.privacySetting![8].visibility ?? 'globe' : 'globe';
      // privacyLength >= 10
      // ? event.userProfile?.privacySetting![10].visibility ?? 'globe' : 'globe';
      // privacyLength >= 11 ? event.userProfile?.privacySetting![11].visibility ?? 'globe' : 'globe';
      // privacyLength >= 12 ? event.userProfile?.privacySetting![12].visibility ?? 'globe' : 'globe';
      print(privacyLength);
      final response = await postService.getProfileUpdate(
        'Bearer ${AppData.userToken}',
        event.userProfile?.user?.firstName ?? '',
        event.userProfile?.user?.lastName ?? "",
        event.userProfile?.user?.phone ?? '',
        event.userProfile?.user?.licenseNo ?? " ",
        specialtyName ?? event.userProfile?.user?.specialty ?? '',
        event.userProfile?.user?.dob ?? "",
        'male',
        country ?? event.userProfile?.user?.country ?? 'United Arab Emirates',
        stateName ?? event.userProfile?.user?.city ?? 'Dubai',
        country ?? event.userProfile?.user?.country ?? "United Arab Emirates",
        // event.userProfile?.privacySetting?[3].visibility ?? 'globe',
        // event.userProfile?.privacySetting?[4].visibility ?? 'globe',
        // event.userProfile?.privacySetting?[5].visibility ?? 'globe',
        // event.userProfile?.privacySetting?[8].visibility ?? 'globe',
        privacyLength >= 3
            ? event.userProfile?.privacySetting![3].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 4
            ? event.userProfile?.privacySetting![4].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 5
            ? event.userProfile?.privacySetting![5].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 8
            ? event.userProfile?.privacySetting![8].visibility ?? 'globe'
            : 'globe',
        'lock',
        'globe',
        'lock',
        // privacyLength >= 10
        //     ? event.userProfile?.privacySetting![10].visibility ?? 'globe'
        //     : 'globe',
        privacyLength >= 11
            ? event.userProfile?.privacySetting![11].visibility ?? 'globe'
            : 'globe',
        privacyLength >= 12
            ? event.userProfile?.privacySetting![12].visibility ?? 'globe'
            : 'globe',
      );
      print(event.userProfile?.profile?.aboutMe ?? '');
      final response2 = await postService.updateAboutMe(
        'Bearer ${AppData.userToken}',
        event.userProfile?.profile?.aboutMe ?? '...',
        event.userProfile?.profile?.address ?? '...',
        event.userProfile?.profile?.birthplace ?? '...',
        event.userProfile?.profile?.livesIn ?? '...',
        event.userProfile?.profile?.languages ?? '...',
        privacyLength >= 0
            ? event.userProfile?.privacySetting![0].visibility ?? 'lock'
            : 'lock',
        privacyLength >= 1
            ? event.userProfile?.privacySetting![1].visibility ?? 'lock'
            : 'lock',
        privacyLength >= 2
            ? event.userProfile?.privacySetting![2].visibility ?? 'lock'
            : 'lock',
        privacyLength >= 6
            ? event.userProfile?.privacySetting![6].visibility ?? 'lock'
            : 'lock',
        privacyLength >= 7
            ? event.userProfile?.privacySetting![7].visibility ?? 'lock'
            : 'lock',
        privacyLength >= 8
            ? event.userProfile?.privacySetting![8].visibility ?? 'globe'
            : 'globe',
      );
      print(response2.response);
    }

    // final response3 = await postService.getPlacesLivedUpdate(
    //   'Bearer ${AppData.userToken}',
    //   '','',
    //   event.userProfile?.privacySetting?[0].visibility??'lock'
    //
    // );
    // emit(PaginationLoadedState());
    // ProgressDialogUtils.hideProgressDialog();
    // globalMessengerKey.currentState?.showSnackBar(
    //     const SnackBar(content: Text('profile info updated successfully')));
    showToast('profile info updated successfully');
    // showTopSnackBar(globalMessengerKey.currentState!.context, 'profile info updated successfully');
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
      } catch (e) {
        print(e);
        emit(DataError('An error occurred'));
      }
  }

  void _updateSecondDropdownValues(
      UpdateSecondDropdownValues event, Emitter<ProfileState> emit) async {
    List<String> secondDropdownValues = [];
    secondDropdownValues = await _onGetStates(event.selectedFirstDropdownValue) ?? 'United Arab Emirates';
    print(secondDropdownValues.toList());
    if (secondDropdownValues.isNotEmpty) {
      List<String>? universityDropdownValues =
          await _onGetUniversities(secondDropdownValues.first ?? '');
    }
    // add(UpdateSpecialtyDropdownValue(secondDropdownValues.first ?? ''));

    emit(PaginationLoadedState(
        (state as PaginationLoadedState).firstDropdownValues,
        event.selectedFirstDropdownValue,
        secondDropdownValues ?? [],
        secondDropdownValues.isNotEmpty ? secondDropdownValues.first : '',
        (state as PaginationLoadedState).specialtyDropdownValue,
        (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
        [],
        ''));
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
      (state as PaginationLoadedState).selectedSecondDropdownValue,
      (state as PaginationLoadedState).specialtyDropdownValue,
      (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
      secondDropdownValues ?? [],
      secondDropdownValues!.isEmpty ? '' : secondDropdownValues.first,
    ));
  }

  void _updateAddWorkEduction(
      UpdateAddWorkEductionEvent event, Emitter<ProfileState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    print(event.id);
    print(event.companyName);
    print(event.position);
    print(event.address);
    print(event.degree);
    print(event.course);
    print(event.workType == '' ? "work" : event.workType);
    print(event.startDate);
    print(event.endDate);
    print(event.currentStatus);
    print(event.description);
    print(event.privacy);
    var response = await postService.updateAddWorkEduction(
        'Bearer ${AppData.userToken}',
        event.id,
        event.companyName,
        event.position,
        event.address,
        event.degree,
        event.course,
        event.workType == '' ? "work" : event.workType,
        event.startDate,
        event.endDate,
        event.currentStatus,
        event.description,
        event.privacy);

    List<WorkEducationModel> response2 = await postService.getWorkEducation(
        'Bearer ${AppData.userToken}', AppData.logInUserId);
    workEducationList!.clear();
    workEducationList!.addAll(response2);
    print(response.data.toString());
    // globalMessengerKey.currentState?.showSnackBar(
    //     const SnackBar(content: Text('Work info updated successfully')));
    showToast('Work info updated successfully');

    emit(PaginationLoadedState(
        (state as PaginationLoadedState).firstDropdownValues,
        (state as PaginationLoadedState).selectedFirstDropdownValue,
        (state as PaginationLoadedState).secondDropdownValues,
        (state as PaginationLoadedState).selectedSecondDropdownValue,
        (state as PaginationLoadedState).specialtyDropdownValue,
        (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
        (state as PaginationLoadedState).universityDropdownValue,
        (state as PaginationLoadedState).selectedUniversityDropdownValue));
  }

  void _updateAddHobbiesInterest(
      UpdateAddHobbiesInterestEvent event, Emitter<ProfileState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    print(event.id);
    print(event.favt_tv_shows);
    print(event.favt_movies);
    print(event.favt_games);
    print(event.favt_writers);
    print(event.favt_books);
    print(event.favt_music_bands);

    var response = await postService.updateAddHobbiesInterest(
      'Bearer ${AppData.userToken}',
      event.id,
      event.favt_tv_shows,
      event.favt_movies,
      event.favt_books,
      event.favt_writers,
      event.favt_music_bands,
      event.favt_games,
    );

    List<InterestModel> response1 = await postService.getInterests(
        'Bearer ${AppData.userToken}', AppData.logInUserId!);
    interestList!.clear();
    interestList!.addAll(response1);
    print(response.data.toString());
    showToast('Hobbies and Interest info updated successfully');

    emit(PaginationLoadedState(
        (state as PaginationLoadedState).firstDropdownValues,
        (state as PaginationLoadedState).selectedFirstDropdownValue,
        (state as PaginationLoadedState).secondDropdownValues,
        (state as PaginationLoadedState).selectedSecondDropdownValue,
        (state as PaginationLoadedState).specialtyDropdownValue,
        (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
        (state as PaginationLoadedState).universityDropdownValue,
        (state as PaginationLoadedState).selectedUniversityDropdownValue));
  }

  void _deleteAddWorkEduction(
      DeleteWorkEducationEvent event, Emitter<ProfileState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    var response = await postService.deleteWorkEduction(
        'Bearer ${AppData.userToken}', event.id);
    List<WorkEducationModel> response2 = await postService.getWorkEducation(
        'Bearer ${AppData.userToken}', AppData.logInUserId);
    workEducationList!.clear();
    workEducationList!.addAll(response2);
    showToast('Work Info deleted successfully');

    // globalMessengerKey.currentState?.showSnackBar(
    //     const SnackBar(content: Text('Work Info deleted successfully')));
    emit(PaginationLoadedState(
        (state as PaginationLoadedState).firstDropdownValues,
        (state as PaginationLoadedState).selectedFirstDropdownValue,
        (state as PaginationLoadedState).secondDropdownValues,
        (state as PaginationLoadedState).selectedSecondDropdownValue,
        (state as PaginationLoadedState).specialtyDropdownValue,
        (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
        (state as PaginationLoadedState).universityDropdownValue,
        (state as PaginationLoadedState).selectedUniversityDropdownValue));
  }

  void _updateSpecialtyDropdownValues(
      UpdateSpecialtyDropdownValue event, Emitter<ProfileState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    List<String>? secondDropdownValues = await _onGetSpecialty();
    emit(PaginationLoadedState(
        (state as PaginationLoadedState).firstDropdownValues,
        (state as PaginationLoadedState).selectedFirstDropdownValue,
        (state as PaginationLoadedState).secondDropdownValues,
        (state as PaginationLoadedState).selectedSecondDropdownValue,
        secondDropdownValues ?? [],
        secondDropdownValues?.first ?? '',
        [],
        ''));
  }

  void _specialityData(
      UpdateSpecialtyDropdownValue1 event, Emitter<ProfileState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    List<String>? secondDropdownValues = await _onGetSpecialty();
    specialtyList = secondDropdownValues ?? [];
  }

  Future<List<Countries>?> _onGetCountries() async {
    // emit(DataLoading());
    try {
      final response = await postService.getCountries();
      print(response.countries!.length.toString());
      if (response.countries!.isNotEmpty) {
        // emit(DataSuccess(countriesModel: response));
        // List<String> list = [];
        // // list.add('Select Country');
        // for (var element in response.countries!) {
        //   list.add(element.countryName!);
        // }
        return response.countries;
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
        list.add('Select Specialty');
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
      print(response.data);

      response.data?.forEach((element) {
        list.add(element['state_name']);
      });
      print("states : ${list.toString()}");
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

  _setUserFollow(SetUserFollow event, Emitter<ProfileState> emit) async {
    // emit(DrugsDataInitial());
    // ProgressDialogUtils.showProgressDialog();
    print(
      event.userId,
    );
    try {
      var response = await postService.setUserFollow(
          'Bearer ${AppData.userToken}', event.userId, event.follow ?? '');
      // setLoading(false);
      emit(PaginationLoadedState(
          (state as PaginationLoadedState).firstDropdownValues,
          (state as PaginationLoadedState).selectedFirstDropdownValue,
          (state as PaginationLoadedState).secondDropdownValues,
          (state as PaginationLoadedState).selectedSecondDropdownValue,
          (state as PaginationLoadedState).specialtyDropdownValue,
          (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
          (state as PaginationLoadedState).universityDropdownValue,
          (state as PaginationLoadedState).selectedUniversityDropdownValue));
    } catch (e) {
      print(e);

      emit(DataError('No Data Found'));
    }
  }
}
