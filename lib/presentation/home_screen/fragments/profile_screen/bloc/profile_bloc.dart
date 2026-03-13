import 'package:dio/dio.dart';
import 'package:doctak_app/core/network/custom_cache_manager.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_service_manager.dart';
import 'package:doctak_app/data/apiClient/services/network_api_service.dart';
import 'package:doctak_app/data/apiClient/services/v5_profile_api_service.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/data/models/profile_model/award_model.dart';
import 'package:doctak_app/data/models/profile_model/business_hour_model.dart';
import 'package:doctak_app/data/models/profile_model/education_detail_model.dart';
import 'package:doctak_app/data/models/profile_model/experience_model.dart';
import 'package:doctak_app/data/models/profile_model/full_profile_model.dart';
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/medical_license_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/data/models/profile_model/publication_model.dart';
import 'package:doctak_app/data/models/profile_model/social_profile_model.dart';
import 'package:doctak_app/data/models/profile_model/user_profile_privacy_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../widgets/toast_widget.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ApiServiceManager apiManager = ApiServiceManager();
  final V5ProfileApiService v5Api = V5ProfileApiService();

  // Legacy fields (kept for backward compatibility)
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

  // ── V5 Full Profile Data ──
  FullProfileModel? fullProfile;
  String? currentUserId; // Track which user's profile is loaded
  int _imageVersion = 0; // Incremented after profile/cover pic upload
  int get imageVersion => _imageVersion;
  List<ExperienceModel> experiences = [];
  List<EducationDetailModel> educationList = [];
  List<PublicationModel> publications = [];
  List<AwardModel> awards = [];
  List<MedicalLicenseModel> licenses = [];
  List<SocialProfileModel> socialProfiles = [];
  List<BusinessHourModel> businessHours = [];
  Map<String, dynamic> interestMap = {}; // v5 interests (key-value)

  ProfileBloc() : super(DataInitial()) {
    on<UpdateFirstDropdownValue>(_updateFirstDropdownValue);
    on<UpdateSecondDropdownValues>(_updateSecondDropdownValues);
    on<UpdateSpecialtyDropdownValue>(_updateSpecialtyDropdownValues);
    on<UpdateSpecialtyDropdownValue1>(_specialityData);
    // on<UpdateUniversityDropdownValues>(_updateUniversityDropdownValues);
    on<LoadPageEvent>(_onGetProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateProfilePicEvent>(_updateProfilePicture);
    on<UpdateAddWorkEductionEvent>(_updateAddWorkEduction);
    on<UpdateAddHobbiesInterestEvent>(_updateAddHobbiesInterest);
    on<LoadPageEvent1>(_onGetPosts);
    on<DeleteWorkEducationEvent>(_deleteAddWorkEduction);
    on<SetUserFollow>(_setUserFollow);
    on<SendConnectionRequestEvent>(_onSendConnectionRequest);
    on<CancelConnectionRequestEvent>(_onCancelConnectionRequest);

    // ── V5 Full Profile Handlers ──
    on<LoadFullProfileEvent>(_onLoadFullProfile);
    on<RefreshProfileSectionEvent>(_onRefreshSection);
    on<StoreExperienceEvent>(_onStoreExperience);
    on<UpdateExperienceEvent>(_onUpdateExperience);
    on<DeleteExperienceEvent>(_onDeleteExperience);
    on<StoreEducationEvent>(_onStoreEducation);
    on<UpdateEducationDetailEvent>(_onUpdateEducation);
    on<DeleteEducationEvent>(_onDeleteEducation);
    on<StorePublicationEvent>(_onStorePublication);
    on<UpdatePublicationEvent>(_onUpdatePublication);
    on<DeletePublicationEvent>(_onDeletePublication);
    on<StoreAwardEvent>(_onStoreAward);
    on<UpdateAwardEvent>(_onUpdateAward);
    on<DeleteAwardEvent>(_onDeleteAward);
    on<StoreLicenseEvent>(_onStoreLicense);
    on<UpdateLicenseEvent>(_onUpdateLicense);
    on<DeleteLicenseEvent>(_onDeleteLicense);
    on<StoreSocialProfileEvent>(_onStoreSocialProfile);
    on<UpdateSocialProfileEvent>(_onUpdateSocialProfile);
    on<DeleteSocialProfileEvent>(_onDeleteSocialProfile);
    on<StoreBusinessHourEvent>(_onStoreBusinessHour);
    on<UpdateBusinessHourEvent>(_onUpdateBusinessHour);
    on<DeleteBusinessHourEvent>(_onDeleteBusinessHour);

    // ── V5 Profile & About Me Update Handlers ──
    on<UpdateProfileV5Event>(_onUpdateProfileV5);
    on<UpdateAboutMeV5Event>(_onUpdateAboutMeV5);

    on<CheckIfNeedMoreDataEvent>((event, emit) async {
      if (event.index == postList.length - nextPageTrigger) {
        add(LoadPageEvent1(page: pageNumber));
      }
    });
  }

  Future<void> _onGetPosts(LoadPageEvent1 event, Emitter<ProfileState> emit) async {
    if (event.page == 1) {
      postList.clear();
      pageNumber = 1;
      // emit(PaginationLoadingState());
    }

    try {
      PostDataModel response = await apiManager.getMyPosts('Bearer ${AppData.userToken}', '$pageNumber', AppData.logInUserId);
      print('repsones$response');
      numberOfPage = response.posts?.lastPage ?? 0;
      if (pageNumber < numberOfPage + 1) {
        pageNumber = pageNumber + 1;
        postList.addAll(response.posts?.data ?? []);
      }

      // Re-emit the current loaded state to trigger rebuild
      _emitCurrentLoadedState(emit);
    } catch (e) {
      print('Error in _onGetPosts: $e');

      // emit(PaginationLoadedState());

      emit(DataError('An error occurred $e'));
    }
  }

  Future<void> _onGetProfile(LoadPageEvent event, Emitter<ProfileState> emit) async {
    emit(PaginationLoadingState());
    try {
      if (pageNumber == 1) {
        print("data ${event.userId}");
        PostDataModel postDataModelResponse = await apiManager.getMyPosts('Bearer ${AppData.userToken}', '1', event.userId ?? '');
        print('repsones$postDataModelResponse');
        UserProfile response = await apiManager.getProfile('Bearer ${AppData.userToken}', event.userId!);
        print(response.toJson());
        List<InterestModel> response1 = await apiManager.getInterests('Bearer ${AppData.userToken}', event.userId!);
        add(UpdateSecondDropdownValues(''));

        // var  response3 = await apiManager.getAboutMe(
        //     'Bearer ${AppData.userToken}');

        List<WorkEducationModel> response2 = await apiManager.getWorkEducation('Bearer ${AppData.userToken}', event.userId!);
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
      List<Countries>? countriesList = await getCountries();

      // Get the country to use for states lookup
      String selectedCountry = userProfile?.user?.country ?? (countriesList?.isNotEmpty == true ? countriesList!.first.countryName ?? '' : '');

      List<String>? stateList = [];
      if (selectedCountry.isNotEmpty) {
        stateList = await getStates(selectedCountry);
        // If states loading fails, provide empty list instead of null
        stateList ??= [];
      }

      print('countriesList: ${countriesList?.length ?? 0} countries');
      print('user country: ${userProfile?.user?.country}');
      print('selected country: $selectedCountry');
      print('states loaded: ${stateList.length} states');

      List<String>? specialtyList = await getSpecialties();

      emit(
        PaginationLoadedState(
          countriesList ?? [],
          selectedCountry,
          stateList,
          userProfile?.user?.state ?? userProfile?.user?.city ?? (stateList.isNotEmpty ? stateList.first : ''),
          specialtyList ?? [],
          userProfile?.user?.specialty ?? (specialtyList?.isNotEmpty == true ? specialtyList!.first : ''),
          [],
          '',
        ),
      );
    } catch (e) {
      print(e);
      emit(DataError('An error occurred $e'));
    }
  }

  Future<void> _updateFirstDropdownValue(UpdateFirstDropdownValue event, Emitter<ProfileState> emit) async {
    List<Countries>? countriesList = await getCountries();
    print(countriesList);
    emit(PaginationLoadedState(countriesList ?? [], countriesList?.first.countryName ?? '', [], 'Select State', [], 'Select Specialty', [], ''));

    add(UpdateSecondDropdownValues(countriesList?.first.countryName ?? 'United Arab Emirates'));
    add(UpdateSpecialtyDropdownValue(countriesList?.first.countryName ?? 'United Arab Emirates'));
  }

  Future<void> _updateProfilePicture(UpdateProfilePicEvent event, Emitter<ProfileState> emit) async {
    var response;
    ProgressDialogUtils.showProgressDialog();

    try {
      // Store old URLs before upload for cache eviction
      final oldProfilePicUrl = userProfile?.profilePicture;
      final oldCoverPicUrl = userProfile?.coverPicture;

      if (event.isProfilePicture ?? false) {
        response = await apiManager.uploadProfilePicture('Bearer ${AppData.userToken}', event.filePath!);
      } else {
        print(event.isProfilePicture);
        response = await apiManager.uploadCoverPicture('Bearer ${AppData.userToken}', event.filePath!);
      }
      UserProfile response1 = await apiManager.getProfile('Bearer ${AppData.userToken}', AppData.logInUserId);
      print('🔍 getProfile returned profilePicture: ${response1.profilePicture}');
      print('🔍 getProfile returned coverPicture: ${response1.coverPicture}');
      print('🔍 Old userProfile profilePicture: ${userProfile?.profilePicture}');
      userProfile = response1;
      print('🔍 Updated userProfile profilePicture: ${userProfile?.profilePicture}');

      // Evict old AND new cached images so the new ones download fresh
      if (event.isProfilePicture ?? false) {
        // Evict old cached image
        if (oldProfilePicUrl != null && oldProfilePicUrl.isNotEmpty) {
          try {
            await CustomCacheManager().removeFile(oldProfilePicUrl);
          } catch (_) {}
        }
        // Evict new URL from cache too (in case S3 reuses the same path)
        if (response1.profilePicture != null && response1.profilePicture!.isNotEmpty) {
          try {
            await CustomCacheManager().removeFile(response1.profilePicture!);
          } catch (_) {}
        }
        // Update AppData.profile_pic so other parts of the app show the new photo
        await AppData.updateProfilePic(response1.profilePicture ?? '');
      } else {
        // Evict old cached image
        if (oldCoverPicUrl != null && oldCoverPicUrl.isNotEmpty) {
          try {
            await CustomCacheManager().removeFile(oldCoverPicUrl);
          } catch (_) {}
        }
        // Evict new URL from cache too (in case S3 reuses the same path)
        if (response1.coverPicture != null && response1.coverPicture!.isNotEmpty) {
          try {
            await CustomCacheManager().removeFile(response1.coverPicture!);
          } catch (_) {}
        }
        // Update AppData.background so other parts of the app show the new cover photo
        await AppData.updateBackground(response1.coverPicture ?? '');
      }

      // Increment the image version counter so profile widgets rebuild with fresh keys
      _imageVersion++;

      print("DD $response");
      ProgressDialogUtils.hideProgressDialog();

      // Re-emit loaded state to refresh the UI
      _emitCurrentLoadedState(emit);
    } catch (e) {
      print('Error updating profile picture: $e');
      ProgressDialogUtils.hideProgressDialog();
      // Re-emit loaded state even on error so the profile screen doesn't break
      _emitCurrentLoadedState(emit);
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<ProfileState> emit) async {
    try {
      final userGender = event.userProfile?.user?.gender ?? fullProfile?.user?.gender ?? 'male';

      // Helper: get privacy by record_type from the privacy settings list
      String getPrivacy(String recordType, {String fallback = 'public'}) {
        final settings = event.userProfile?.privacySetting;
        if (settings == null || settings.isEmpty) return fallback;
        final match = settings.where((e) => e.recordType == recordType).toList();
        if (match.isNotEmpty) return match.first.visibility ?? fallback;
        return fallback;
      }

      if (event.updateProfileSection == 1 || event.updateProfileSection == 2 || event.updateProfileSection == 3) {
        // Use v5 endpoint for user table fields
        final effectiveCountry = country ?? event.userProfile?.user?.country ?? '';
        final effectiveState = stateName ?? event.userProfile?.user?.state ?? event.userProfile?.user?.city ?? '';
        await v5Api.updateProfile(
          firstName: event.userProfile?.user?.firstName ?? '',
          lastName: event.userProfile?.user?.lastName ?? '',
          phone: event.userProfile?.user?.phone?.toString() ?? '',
          licenseNo: event.userProfile?.user?.licenseNo?.toString() ?? '',
          specialty: specialtyName ?? event.userProfile?.user?.specialty ?? '',
          dob: event.userProfile?.user?.dob ?? '',
          gender: userGender,
          country: effectiveCountry,
          city: effectiveState,
          state: effectiveState,
          countryOrigin: effectiveCountry,
          dobPrivacy: getPrivacy('dob'),
          emailPrivacy: getPrivacy('email'),
          genderPrivacy: getPrivacy('gender'),
          phonePrivacy: getPrivacy('phone'),
          licenseNoPrivacy: getPrivacy('license_no'),
          specialtyPrivacy: getPrivacy('specialty'),
          countryPrivacy: getPrivacy('country'),
          cityPrivacy: getPrivacy('state'),
          countryOriginPrivacy: getPrivacy('country_origin'),
        );
      }

      if (event.updateProfileSection == 2 || event.updateProfileSection == 3) {
        // Use v5 endpoint for profile table fields
        await v5Api.updateAboutMe(
          aboutMe: event.userProfile?.profile?.aboutMe ?? '',
          address: event.userProfile?.profile?.address ?? '',
          birthplace: event.userProfile?.profile?.birthplace ?? '',
          livesIn: event.userProfile?.profile?.livesIn ?? '',
          languages: event.userProfile?.profile?.languages ?? '',
          aboutMePrivacy: getPrivacy('about_me'),
          addressPrivacy: getPrivacy('address'),
          birthplacePrivacy: getPrivacy('birthplace'),
          languagesPrivacy: getPrivacy('languages'),
          livesInPrivacy: getPrivacy('lives_in'),
          phonePrivacy: getPrivacy('phone'),
        );
      }

      showToast('Profile updated successfully');

      // Re-fetch the full profile (v5) to sync all display widgets
      await _refreshFullProfile(emit);

      _emitCurrentLoadedState(emit);
    } catch (e) {
      print('Error updating profile: $e');
      emit(DataError('An error occurred'));
    }
  }

  // ─────────────────────────────────────────────
  //  V5 PROFILE UPDATE (bottom sheet forms)
  // ─────────────────────────────────────────────

  Future<void> _onUpdateProfileV5(UpdateProfileV5Event event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final response = await v5Api.updateProfile(
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        licenseNo: event.licenseNo,
        specialty: event.specialty,
        dob: event.dob,
        gender: event.gender,
        country: event.country,
        city: event.city,
        state: event.state,
        countryOrigin: event.countryOrigin,
        stateOrigin: event.stateOrigin,
        clinicName: event.clinicName,
        college: event.college,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (response.success) {
        showToast('Profile updated successfully');
        // Re-fetch full profile to sync
        await _refreshFullProfile(emit);
      } else {
        showToast(response.message ?? 'Failed to update profile');
      }
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      print('Error updating profile v5: $e');
      showToast('Failed to update profile');
    }
  }

  Future<void> _onUpdateAboutMeV5(UpdateAboutMeV5Event event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final response = await v5Api.updateAboutMe(
        aboutMe: event.aboutMe,
        address: event.address,
        birthplace: event.birthplace,
        livesIn: event.livesIn,
        languages: event.languages,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (response.success) {
        showToast('About me updated successfully');
        // Re-fetch full profile to sync
        await _refreshFullProfile(emit);
      } else {
        showToast(response.message ?? 'Failed to update about me');
      }
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      print('Error updating about me v5: $e');
      showToast('Failed to update about me');
    }
  }

  /// Shared method to re-fetch full profile after any update
  Future<void> _refreshFullProfile(Emitter<ProfileState> emit) async {
    try {
      final userId = currentUserId ?? AppData.logInUserId;
      final profileResponse = await v5Api.getFullProfile(userId: userId.toString());
      if (profileResponse.success && profileResponse.data != null) {
        fullProfile = profileResponse.data!;
        experiences = fullProfile!.experiences;
        educationList = fullProfile!.education;
        publications = fullProfile!.publications;
        awards = fullProfile!.awards;
        licenses = fullProfile!.licenses;
        socialProfiles = fullProfile!.socialProfiles;
        businessHours = fullProfile!.businessHours;

        // Refresh legacy userProfile
        final fpUser = fullProfile!.user;
        final fpProfile = fullProfile!.profile;
        final fpStats = fullProfile!.stats;
        userProfile = UserProfile(
          profilePicture: fpUser?.profilePic,
          coverPicture: fpUser?.coverPic,
          isFollowing: fullProfile!.isFollowing,
          totalPosts: fpStats?.totalPosts ?? 0,
          user: User(
            id: fpUser?.id,
            firstName: fpUser?.firstName,
            lastName: fpUser?.lastName,
            country: fpUser?.country,
            state: fpUser?.state,
            city: fpUser?.city,
            specialty: fpUser?.specialty,
            licenseNo: fpUser?.licenseNo,
            clinicName: fpUser?.clinicName,
            phone: fpUser?.phone,
            college: fpUser?.college,
            dob: fpUser?.dob,
            gender: fpUser?.gender,
          ),
          profile: Profile(
            aboutMe: fpProfile?.aboutMe,
            address: fpProfile?.address,
            birthplace: fpProfile?.birthplace,
            livesIn: fpProfile?.livesIn,
            languages: fpProfile?.languages,
          ),
          totalFollows: TotalFollows(
            totalFollowers: fpStats?.totalFollowers?.toString() ?? '0',
            totalFollowings: fpStats?.totalFollowing?.toString() ?? '0',
          ),
        );
        if (fullProfile!.privacySettings != null && fullProfile!.privacySettings!.isNotEmpty) {
          userProfile!.privacySetting = fullProfile!.privacySettings!.entries.map((entry) {
            return PrivacySetting(
              recordType: entry.key,
              visibility: entry.value?.toString(),
            );
          }).toList();
        }
        _emitCurrentLoadedState(emit);
        print('📋 [ProfileBloc] Profile re-fetched after v5 update');
      }
    } catch (e) {
      print('📋 [ProfileBloc] Failed to refresh profile: $e');
    }
  }

  void _updateSecondDropdownValues(UpdateSecondDropdownValues event, Emitter<ProfileState> emit) async {
    // Check if current state is a loaded state before proceeding
    if (state is! PaginationLoadedState && state is! FullProfileLoadedState) {
      print('Error: Current state is not a loaded state, it is ${state.runtimeType}');
      return;
    }

    final d = _getDropdownData();

    try {
      List<String> secondDropdownValues = [];
      secondDropdownValues = await getStates(event.selectedFirstDropdownValue) ?? [];

      // If no states found, provide fallback
      if (secondDropdownValues.isEmpty) {
        secondDropdownValues = ['No states available'];
      }

      print('States loaded: ${secondDropdownValues.toList()}');

      // Find the user's current state in the loaded states
      String selectedState = '';
      if (userProfile?.user?.state != null && userProfile!.user!.state!.isNotEmpty) {
        // Check if user's state exists in the loaded states
        if (secondDropdownValues.contains(userProfile!.user!.state!)) {
          selectedState = userProfile!.user!.state!;
        } else {
          // If not found, use the first available state
          selectedState = secondDropdownValues.isNotEmpty ? secondDropdownValues.first : '';
        }
      } else {
        selectedState = secondDropdownValues.isNotEmpty ? secondDropdownValues.first : '';
      }

      emit(
        PaginationLoadedState(
          d.firstDropdownValues,
          event.selectedFirstDropdownValue,
          secondDropdownValues,
          selectedState,
          d.specialtyDropdownValue,
          d.selectedSpecialtyDropdownValue,
          [],
          '',
        ),
      );
    } catch (e) {
      print('Error in _updateSecondDropdownValues: $e');
      emit(DataError('Failed to load states: ${e.toString()}'));
    }
  }

  // void _updateUniversityDropdownValues(
  //     UpdateUniversityDropdownValues event, Emitter<ProfileState> emit) async {
  //   // Simulate fetching second dropdown values based on the first dropdown selection
  //   // List<String>? secondDropdownValues =
  //   //     await _onGetUniversities(event.selectedStateDropdownValue);
  //   emit(PaginationLoadedState(
  //     (state as PaginationLoadedState).firstDropdownValues,
  //     (state as PaginationLoadedState).selectedFirstDropdownValue,
  //     (state as PaginationLoadedState).secondDropdownValues,
  //     (state as PaginationLoadedState).selectedSecondDropdownValue,
  //     (state as PaginationLoadedState).specialtyDropdownValue,
  //     (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
  //     [],
  //     ''
  //     // secondDropdownValues ?? [],
  //     // secondDropdownValues!.isEmpty ? '' : secondDropdownValues.first,
  //   ));
  // }

  void _updateAddWorkEduction(UpdateAddWorkEductionEvent event, Emitter<ProfileState> emit) async {
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
    var response = await apiManager.updateAddWorkEduction(
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
      event.privacy,
    );

    List<WorkEducationModel> response2 = await apiManager.getWorkEducation('Bearer ${AppData.userToken}', AppData.logInUserId);
    workEducationList!.clear();
    workEducationList!.addAll(response2);
    print(response.data.toString());
    // globalMessengerKey.currentState?.showSnackBar(
    //     const SnackBar(content: Text('Work info updated successfully')));
    showToast('Work info updated successfully');

    _emitCurrentLoadedState(emit);
  }

  void _updateAddHobbiesInterest(UpdateAddHobbiesInterestEvent event, Emitter<ProfileState> emit) async {
    try {
      // Use v5 API to save interests
      final v5Api = V5ProfileApiService();
      final result = await v5Api.saveInterests(
        hobbies: event.hobbies,
        favtTvShows: event.favt_tv_shows,
        favtMovies: event.favt_movies,
        favtGames: event.favt_games,
        favtMusicBands: event.favt_music_bands,
        favtBooks: event.favt_books,
        favtWriters: event.favt_writers,
      );

      if (result.success) {
        // Store the returned interest map
        interestMap = result.data ?? {};
        showToast('Hobbies and Interest info updated successfully');
      } else {
        showToast('Failed to save interests');
      }
    } catch (e) {
      print('Error saving interests: $e');
      showToast('Failed to save interests');
    }

    _emitCurrentLoadedState(emit);
  }

  void _deleteAddWorkEduction(DeleteWorkEducationEvent event, Emitter<ProfileState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    var response = await apiManager.deleteWorkEduction('Bearer ${AppData.userToken}', event.id);
    List<WorkEducationModel> response2 = await apiManager.getWorkEducation('Bearer ${AppData.userToken}', AppData.logInUserId);
    workEducationList!.clear();
    workEducationList!.addAll(response2);
    showToast('Work Info deleted successfully');

    // globalMessengerKey.currentState?.showSnackBar(
    //     const SnackBar(content: Text('Work Info deleted successfully')));
    _emitCurrentLoadedState(emit);
  }

  void _updateSpecialtyDropdownValues(UpdateSpecialtyDropdownValue event, Emitter<ProfileState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    List<String>? secondDropdownValues = await getSpecialties();
    _emitCurrentLoadedState(emit,
      specialtyDropdownValue: secondDropdownValues ?? [],
      selectedSpecialtyDropdownValue: secondDropdownValues?.isNotEmpty == true ? secondDropdownValues!.first : '',
    );
  }

  void _specialityData(UpdateSpecialtyDropdownValue1 event, Emitter<ProfileState> emit) async {
    // Simulate fetching second dropdown values based on the first dropdown selection
    List<String>? secondDropdownValues = await getSpecialties();
    specialtyList = secondDropdownValues ?? [];
  }

  Future<List<Countries>?> getCountries() async {
    // emit(DataLoading());
    try {
      final response = await apiManager.getCountries();
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
    return null;
  }

  Future<List<String>?> getSpecialties() async {
    // emit(DataLoading());
    try {
      final response = await apiManager.getSpecialty();
      // response is now a List directly, not wrapped in an object with .data
      if (response != null && response.isNotEmpty) {
        List<String> list = [];
        list.add('Select Specialty');
        for (var element in response) {
          if (element is Map && element['name'] != null) {
            list.add(element['name']!);
          }
        }
        return list;
      } else {
        return [];
      }
    } catch (e) {
      print(e);
      return null; // Return null on error
    }
  }

  Future<List<String>?> getStates(String value) async {
    try {
      // Validate input
      if (value.isEmpty) {
        print('Warning: Empty country value provided to _onGetStates');
        return null;
      }

      print('Fetching states for country: $value');
      final response = await apiManager.getStates(value);

      List<String> list = [];

      // response is already the data (Map with 'data' key containing the list)
      if (response != null && response['data'] != null && response['data'].isNotEmpty) {
        response['data'].forEach((element) {
          if (element != null && element['state_name'] != null) {
            list.add(element['state_name'].toString());
          }
        });
        print("States loaded successfully: ${list.toString()}");
        return list;
      } else {
        print('No states found for country: $value');
        return [];
      }
    } catch (e) {
      print('Error fetching states for country "$value": $e');
      // Return null to indicate error, let caller handle fallback
      return null;
    }
  }

  // Future<List<String>>? _onGetUniversities(String value) async {
  //   // emit(DataLoading());
  //   try {
  //     final response = await apiManager.getUniversityByStates(value);
  //     print(response.data);
  //     // if (response.data!.isNotEmpty) {
  //     // emit(DataSuccess(countriesModel: response));
  //     log('response ${response.data}');
  //     List<String> list = [];
  //     // list.clear();
  //     // list.add('Add new University');
  //     response.data?.forEach((element) {
  //       if (element['name'] != null) {
  //         list.add(element['name']!);
  //       }
  //     });
  //     return list;
  //     // } else {
  //     //   return [];
  //     //   // emit(DataFailure(error: 'Failed to load data'));
  //     // }
  //   } catch (e) {
  //     return [];
  //     print(e);
  //     // emit(DataFailure(error: 'An error occurred'));
  //   }
  // }

  Future<void> _setUserFollow(SetUserFollow event, Emitter<ProfileState> emit) async {
    print(event.userId);
    try {
      await apiManager.setUserFollow('Bearer ${AppData.userToken}', event.userId, event.follow ?? '');
      // Re-emit current state to rebuild UI
      if (state is FullProfileLoadedState) {
        final s = state as FullProfileLoadedState;
        emit(FullProfileLoadedState(
          firstDropdownValues: s.firstDropdownValues,
          selectedFirstDropdownValue: s.selectedFirstDropdownValue,
          secondDropdownValues: s.secondDropdownValues,
          selectedSecondDropdownValue: s.selectedSecondDropdownValue,
          specialtyDropdownValue: s.specialtyDropdownValue,
          selectedSpecialtyDropdownValue: s.selectedSpecialtyDropdownValue,
        ));
      } else if (state is PaginationLoadedState) {
        emit(
          PaginationLoadedState(
            (state as PaginationLoadedState).firstDropdownValues,
            (state as PaginationLoadedState).selectedFirstDropdownValue,
            (state as PaginationLoadedState).secondDropdownValues,
            (state as PaginationLoadedState).selectedSecondDropdownValue,
            (state as PaginationLoadedState).specialtyDropdownValue,
            (state as PaginationLoadedState).selectedSpecialtyDropdownValue,
            (state as PaginationLoadedState).universityDropdownValue,
            (state as PaginationLoadedState).selectedUniversityDropdownValue,
          ),
        );
      }
    } catch (e) {
      print(e);
      emit(DataError('No Data Found'));
    }
  }

  // ── Connection (Friend Request) handlers ──

  final NetworkApiService _networkApi = NetworkApiService();

  Future<void> _onSendConnectionRequest(
      SendConnectionRequestEvent event, Emitter<ProfileState> emit) async {
    try {
      final result = await _networkApi.sendFriendRequest(event.userId);
      if (result['success'] == true) {
        // Update local model
        fullProfile?.connectionStatus = 'pending_sent';
        fullProfile?.friendRequestId = result['friend_request_id']?.toString();
        _reemitFullProfileState(emit);
      }
    } catch (e) {
      print('Error sending connection request: $e');
    }
  }

  Future<void> _onCancelConnectionRequest(
      CancelConnectionRequestEvent event, Emitter<ProfileState> emit) async {
    try {
      final result = await _networkApi.cancelFriendRequest(event.requestId);
      if (result['success'] == true) {
        fullProfile?.connectionStatus = 'none';
        fullProfile?.friendRequestId = null;
        _reemitFullProfileState(emit);
      }
    } catch (e) {
      print('Error cancelling connection request: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  V5 FULL PROFILE HANDLERS
  // ═══════════════════════════════════════════════════════════

  /// Helper to emit FullProfileLoadedState with current dropdown data
  void _emitFullProfileLoaded(Emitter<ProfileState> emit, {
    List<Countries>? countries,
    String? selectedCountry,
    List<String>? states,
    String? selectedState,
    List<String>? specialties,
    String? selectedSpecialty,
  }) {
    if (isClosed) return;
    emit(FullProfileLoadedState(
      firstDropdownValues: countries ?? [],
      selectedFirstDropdownValue: selectedCountry ?? '',
      secondDropdownValues: states ?? [],
      selectedSecondDropdownValue: selectedState ?? '',
      specialtyDropdownValue: specialties ?? specialtyList ?? [],
      selectedSpecialtyDropdownValue: selectedSpecialty ?? specialtyName ?? '',
    ));
  }

  /// Re-emit the current FullProfileLoadedState (after CRUD)
  void _reemitFullProfileState(Emitter<ProfileState> emit) {
    if (isClosed) return;
    if (state is FullProfileLoadedState) {
      final s = state as FullProfileLoadedState;
      emit(FullProfileLoadedState(
        firstDropdownValues: s.firstDropdownValues,
        selectedFirstDropdownValue: s.selectedFirstDropdownValue,
        secondDropdownValues: s.secondDropdownValues,
        selectedSecondDropdownValue: s.selectedSecondDropdownValue,
        specialtyDropdownValue: s.specialtyDropdownValue,
        selectedSpecialtyDropdownValue: s.selectedSpecialtyDropdownValue,
      ));
    } else {
      emit(FullProfileLoadedState());
    }
  }

  /// Helper to extract dropdown values from either PaginationLoadedState or FullProfileLoadedState
  ProfileDropdownData _getDropdownData() {
    if (state is PaginationLoadedState) {
      final s = state as PaginationLoadedState;
      return ProfileDropdownData(
        firstDropdownValues: s.firstDropdownValues,
        selectedFirstDropdownValue: s.selectedFirstDropdownValue,
        secondDropdownValues: s.secondDropdownValues,
        selectedSecondDropdownValue: s.selectedSecondDropdownValue,
        specialtyDropdownValue: s.specialtyDropdownValue,
        selectedSpecialtyDropdownValue: s.selectedSpecialtyDropdownValue,
      );
    } else if (state is FullProfileLoadedState) {
      final s = state as FullProfileLoadedState;
      return ProfileDropdownData(
        firstDropdownValues: s.firstDropdownValues,
        selectedFirstDropdownValue: s.selectedFirstDropdownValue,
        secondDropdownValues: s.secondDropdownValues,
        selectedSecondDropdownValue: s.selectedSecondDropdownValue,
        specialtyDropdownValue: s.specialtyDropdownValue,
        selectedSpecialtyDropdownValue: s.selectedSpecialtyDropdownValue,
      );
    }
    return ProfileDropdownData();
  }

  /// Emit the appropriate loaded state preserving dropdown data
  void _emitCurrentLoadedState(Emitter<ProfileState> emit, {
    List<Countries>? firstDropdownValues,
    String? selectedFirstDropdownValue,
    List<String>? secondDropdownValues,
    String? selectedSecondDropdownValue,
    List<String>? specialtyDropdownValue,
    String? selectedSpecialtyDropdownValue,
  }) {
    if (isClosed) return;
    final d = _getDropdownData();
    if (state is FullProfileLoadedState) {
      emit(FullProfileLoadedState(
        firstDropdownValues: firstDropdownValues ?? d.firstDropdownValues,
        selectedFirstDropdownValue: selectedFirstDropdownValue ?? d.selectedFirstDropdownValue,
        secondDropdownValues: secondDropdownValues ?? d.secondDropdownValues,
        selectedSecondDropdownValue: selectedSecondDropdownValue ?? d.selectedSecondDropdownValue,
        specialtyDropdownValue: specialtyDropdownValue ?? d.specialtyDropdownValue,
        selectedSpecialtyDropdownValue: selectedSpecialtyDropdownValue ?? d.selectedSpecialtyDropdownValue,
      ));
    } else {
      emit(PaginationLoadedState(
        firstDropdownValues ?? d.firstDropdownValues,
        selectedFirstDropdownValue ?? d.selectedFirstDropdownValue,
        secondDropdownValues ?? d.secondDropdownValues,
        selectedSecondDropdownValue ?? d.selectedSecondDropdownValue,
        specialtyDropdownValue ?? d.specialtyDropdownValue,
        selectedSpecialtyDropdownValue ?? d.selectedSpecialtyDropdownValue,
        [],
        '',
      ));
    }
  }

  /// Load full profile from v5 API (with v4 fallback)
  Future<void> _onLoadFullProfile(LoadFullProfileEvent event, Emitter<ProfileState> emit) async {
    if (isClosed) return;
    emit(PaginationLoadingState());
    try {
      final userId = event.userId ?? AppData.logInUserId;
      currentUserId = userId;
      pageNumber = 1;

      print('📋 [ProfileBloc] _onLoadFullProfile start, userId=$userId');

      bool v5Loaded = false;

      // ── Step 1: Try v5 Full Profile API ──
      try {
        print('📋 [ProfileBloc] Trying v5 API...');
        final profileResponse = await v5Api.getFullProfile(userId: userId.toString());
        if (isClosed) return;
        if (profileResponse.success && profileResponse.data != null) {
          v5Loaded = true;
          fullProfile = profileResponse.data!;
          isMe = fullProfile!.isOwnProfile ?? (userId.toString() == AppData.logInUserId.toString());
          print('📋 [ProfileBloc] v5 loaded OK, isMe=$isMe');

          // Populate section lists from full profile
          experiences = fullProfile!.experiences;
          educationList = fullProfile!.education;
          publications = fullProfile!.publications;
          awards = fullProfile!.awards;
          licenses = fullProfile!.licenses;
          socialProfiles = fullProfile!.socialProfiles;
          businessHours = fullProfile!.businessHours;
          interestList = fullProfile!.interests;

          // Load interest map from v5 API (key-value hobbies)
          try {
            final interestResult = await v5Api.getInterests(userId: userId);
            if (interestResult.success && interestResult.data != null) {
              interestMap = interestResult.data!;
            }
          } catch (e) {
            print('Could not load interest map: $e');
          }

          // Populate legacy userProfile from v5 data for backward-compatible header
          final fpUser = fullProfile!.user;
          final fpProfile = fullProfile!.profile;
          final fpStats = fullProfile!.stats;
          userProfile = UserProfile(
            profilePicture: fpUser?.profilePic,
            coverPicture: fpUser?.coverPic,
            isFollowing: fullProfile!.isFollowing,
            totalPosts: fpStats?.totalPosts ?? 0,
            user: User(
              id: fpUser?.id,
              firstName: fpUser?.firstName,
              lastName: fpUser?.lastName,
              country: fpUser?.country,
              state: fpUser?.state,
              city: fpUser?.city,
              specialty: fpUser?.specialty,
              licenseNo: fpUser?.licenseNo,
              clinicName: fpUser?.clinicName,
              phone: fpUser?.phone,
              college: fpUser?.college,
              dob: fpUser?.dob,
            ),
            profile: Profile(
              aboutMe: fpProfile?.aboutMe,
              address: fpProfile?.address,
              birthplace: fpProfile?.birthplace,
              livesIn: fpProfile?.livesIn,
              languages: fpProfile?.languages,
            ),
            totalFollows: TotalFollows(
              totalFollowers: fpStats?.totalFollowers?.toString() ?? '0',
              totalFollowings: fpStats?.totalFollowing?.toString() ?? '0',
            ),
          );

          // Populate privacy settings from v5 response (Map<record_type, visibility> → List<PrivacySetting>)
          if (fullProfile!.privacySettings != null && fullProfile!.privacySettings!.isNotEmpty) {
            userProfile!.privacySetting = fullProfile!.privacySettings!.entries.map((entry) {
              return PrivacySetting(
                recordType: entry.key,
                visibility: entry.value?.toString(),
              );
            }).toList();
            print('📋 [ProfileBloc] Privacy settings populated: ${userProfile!.privacySetting!.length} entries');
          }
        } else {
          print('📋 [ProfileBloc] v5 API returned error: ${profileResponse.message}');
        }
      } catch (v5Error) {
        print('📋 [ProfileBloc] v5 API failed, falling back to v4: $v5Error');
      }

      if (isClosed) return;

      // ── Step 2: If v5 failed, fall back to v4 API ──
      if (!v5Loaded) {
        print('📋 [ProfileBloc] Using v4 fallback for profile data...');
        try {
          UserProfile response = await apiManager.getProfile(
            'Bearer ${AppData.userToken}', userId.toString(),
          );
          if (isClosed) return;
          userProfile = response;
          isMe = (userId.toString() == AppData.logInUserId.toString());
          print('📋 [ProfileBloc] v4 profile loaded: ${response.user?.firstName}');

          List<InterestModel> interests = await apiManager.getInterests(
            'Bearer ${AppData.userToken}', userId.toString(),
          );
          interestList = interests;

          List<WorkEducationModel> workEdu = await apiManager.getWorkEducation(
            'Bearer ${AppData.userToken}', userId.toString(),
          );
          workEducationList = workEdu;
        } catch (v4Error) {
          print('📋 [ProfileBloc] v4 fallback also failed: $v4Error');
        }

        // Also try loading section data individually (v5Api will auto-fallback to v4 URL)
        if (isClosed) return;
        try {
          print('📋 [ProfileBloc] Loading section data individually...');
          final expResult = await v5Api.getExperiences(userId: userId.toString());
          if (expResult.success) experiences = expResult.data ?? [];
        } catch (_) {}
        try {
          final eduResult = await v5Api.getEducation(userId: userId.toString());
          if (eduResult.success) educationList = eduResult.data ?? [];
        } catch (_) {}
        try {
          final pubResult = await v5Api.getPublications(userId: userId.toString());
          if (pubResult.success) publications = pubResult.data ?? [];
        } catch (_) {}
        try {
          final awardResult = await v5Api.getAwards(userId: userId.toString());
          if (awardResult.success) awards = awardResult.data ?? [];
        } catch (_) {}
        try {
          final licResult = await v5Api.getLicenses(userId: userId.toString());
          if (licResult.success) licenses = licResult.data ?? [];
        } catch (_) {}
        try {
          final socialResult = await v5Api.getSocialProfiles(userId: userId.toString());
          if (socialResult.success) socialProfiles = socialResult.data ?? [];
        } catch (_) {}
        try {
          final bhResult = await v5Api.getBusinessHours(userId: userId.toString());
          if (bhResult.success) businessHours = bhResult.data ?? [];
        } catch (_) {}
        print('📋 [ProfileBloc] Section data: exp=${experiences.length} edu=${educationList.length} pub=${publications.length} awards=${awards.length}');
      }

      if (isClosed) return;

      // ── Step 3: Load posts (always v4) ──
      try {
        postList.clear();
        PostDataModel postDataModelResponse = await apiManager.getMyPosts(
          'Bearer ${AppData.userToken}', '1', userId.toString(),
        );
        if (isClosed) return;
        numberOfPage = postDataModelResponse.posts?.lastPage ?? 0;
        if (pageNumber < numberOfPage + 1) {
          pageNumber = pageNumber + 1;
          postList.addAll(postDataModelResponse.posts?.data ?? []);
        }
        print('📋 [ProfileBloc] Posts loaded: ${postList.length}');
      } catch (postError) {
        print('📋 [ProfileBloc] Posts loading failed: $postError');
      }

      if (isClosed) return;

      // ── Step 4: Load dropdown data for editing ──
      List<Countries>? countriesList;
      String selectedCountry = '';
      List<String>? stateList = [];
      List<String>? specialties;
      try {
        countriesList = await getCountries();
        if (isClosed) return;
        selectedCountry = userProfile?.user?.country ?? '';
        if (selectedCountry.isNotEmpty) {
          stateList = await getStates(selectedCountry) ?? [];
        }
        if (isClosed) return;
        specialties = await getSpecialties();
        specialtyList = specialties;
        print('📋 [ProfileBloc] Dropdown data loaded');
      } catch (dropError) {
        print('📋 [ProfileBloc] Dropdown loading failed: $dropError');
      }

      if (isClosed) return;

      // ── Step 5: Emit loaded state ──
      if (userProfile != null) {
        _emitFullProfileLoaded(
          emit,
          countries: countriesList,
          selectedCountry: selectedCountry,
          states: stateList,
          selectedState: userProfile?.user?.state ?? userProfile?.user?.city ?? '',
          specialties: specialties,
          selectedSpecialty: userProfile?.user?.specialty ?? '',
        );
        print('📋 [ProfileBloc] FullProfileLoadedState emitted');
      } else {
        print('📋 [ProfileBloc] No profile data loaded, emitting error');
        emit(DataError('Failed to load profile data'));
      }
    } catch (e) {
      print('📋 [ProfileBloc] Fatal error in _onLoadFullProfile: $e');
      if (!isClosed) emit(DataError('An error occurred: $e'));
    }
  }

  /// Refresh a specific section by re-fetching from v5
  Future<void> _onRefreshSection(RefreshProfileSectionEvent event, Emitter<ProfileState> emit) async {
    if (isClosed) return;
    final userId = currentUserId ?? AppData.logInUserId!;
    try {
      switch (event.section) {
        case 'experiences':
          final r = await v5Api.getExperiences(userId: userId);
          if (r.success) experiences = r.data ?? [];
          break;
        case 'education':
          final r = await v5Api.getEducation(userId: userId);
          if (r.success) educationList = r.data ?? [];
          break;
        case 'publications':
          final r = await v5Api.getPublications(userId: userId);
          if (r.success) publications = r.data ?? [];
          break;
        case 'awards':
          final r = await v5Api.getAwards(userId: userId);
          if (r.success) awards = r.data ?? [];
          break;
        case 'licenses':
          final r = await v5Api.getLicenses(userId: userId);
          if (r.success) licenses = r.data ?? [];
          break;
        case 'social_profiles':
          final r = await v5Api.getSocialProfiles(userId: userId);
          if (r.success) socialProfiles = r.data ?? [];
          break;
        case 'business_hours':
          final r = await v5Api.getBusinessHours(userId: userId);
          if (r.success) businessHours = r.data ?? [];
          break;
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      _reemitFullProfileState(emit);
    }
  }

  // ── Experience CRUD ──

  Future<void> _onStoreExperience(StoreExperienceEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.storeExperience(
        position: event.position, companyName: event.companyName,
        startDate: event.startDate, endDate: event.endDate,
        location: event.location, description: event.description,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        experiences.add(r.data!);
        showToast('Experience added successfully');
      } else {
        showToast(r.message ?? 'Failed to add experience');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      showToast('Error: $e');
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onUpdateExperience(UpdateExperienceEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.updateExperience(
        id: event.id, position: event.position, companyName: event.companyName,
        startDate: event.startDate, endDate: event.endDate,
        location: event.location, description: event.description,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        final idx = experiences.indexWhere((e) => e.id == event.id);
        if (idx != -1) experiences[idx] = r.data!;
        showToast('Experience updated successfully');
      } else {
        showToast(r.message ?? 'Failed to update experience');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      showToast('Error: $e');
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onDeleteExperience(DeleteExperienceEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.deleteExperience(id: event.id);
      ProgressDialogUtils.hideProgressDialog();
      if (r.success) {
        experiences.removeWhere((e) => e.id == event.id);
        showToast('Experience deleted successfully');
      } else {
        showToast(r.message ?? 'Failed to delete experience');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      showToast('Error: $e');
      _reemitFullProfileState(emit);
    }
  }

  // ── Education CRUD ──

  Future<void> _onStoreEducation(StoreEducationEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.storeEducation(
        degree: event.degree, institution: event.institution,
        fieldOfStudy: event.fieldOfStudy, startYear: event.startYear,
        endYear: event.endYear, currentStudy: event.currentStudy,
        gpa: event.gpa, honors: event.honors,
        thesisTitle: event.thesisTitle, description: event.description,
        location: event.location, specialization: event.specialization,
        activities: event.activities, privacy: event.privacy,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        educationList.add(r.data!);
        showToast('Education added successfully');
      } else {
        showToast(r.message ?? 'Failed to add education');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      showToast('Error: $e');
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onUpdateEducation(UpdateEducationDetailEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.updateEducation(
        id: event.id, degree: event.degree, institution: event.institution,
        fieldOfStudy: event.fieldOfStudy, startYear: event.startYear,
        endYear: event.endYear, currentStudy: event.currentStudy,
        gpa: event.gpa, honors: event.honors,
        thesisTitle: event.thesisTitle, description: event.description,
        location: event.location, specialization: event.specialization,
        activities: event.activities, privacy: event.privacy,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        final idx = educationList.indexWhere((e) => e.id == event.id);
        if (idx != -1) educationList[idx] = r.data!;
        showToast('Education updated successfully');
      } else {
        showToast(r.message ?? 'Failed to update education');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      showToast('Error: $e');
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onDeleteEducation(DeleteEducationEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.deleteEducation(id: event.id);
      ProgressDialogUtils.hideProgressDialog();
      if (r.success) {
        educationList.removeWhere((e) => e.id == event.id);
        showToast('Education deleted successfully');
      } else {
        showToast(r.message ?? 'Failed to delete education');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      showToast('Error: $e');
      _reemitFullProfileState(emit);
    }
  }

  // ── Publication CRUD ──

  Future<void> _onStorePublication(StorePublicationEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.storePublication(
        title: event.title, journalName: event.journalName,
        publicationDate: event.publicationDate, coAuthor: event.coAuthor,
        abstract_: event.abstract_, keywords: event.keywords,
        impactFactor: event.impactFactor, citations: event.citations,
        doiLink: event.doiLink, privacy: event.privacy,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        publications.add(r.data!);
        showToast('Publication added successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onUpdatePublication(UpdatePublicationEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.updatePublication(
        id: event.id, title: event.title, journalName: event.journalName,
        publicationDate: event.publicationDate, coAuthor: event.coAuthor,
        abstract_: event.abstract_, keywords: event.keywords,
        impactFactor: event.impactFactor, citations: event.citations,
        doiLink: event.doiLink, privacy: event.privacy,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        final idx = publications.indexWhere((e) => e.id == event.id);
        if (idx != -1) publications[idx] = r.data!;
        showToast('Publication updated successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onDeletePublication(DeletePublicationEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.deletePublication(id: event.id);
      ProgressDialogUtils.hideProgressDialog();
      if (r.success) {
        publications.removeWhere((e) => e.id == event.id);
        showToast('Publication deleted successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  // ── Award CRUD ──

  Future<void> _onStoreAward(StoreAwardEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.storeAward(
        awardName: event.awardName, awardingBody: event.awardingBody,
        dateReceived: event.dateReceived, description: event.description,
        level: event.level, privacy: event.privacy,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        awards.add(r.data!);
        showToast('Award added successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onUpdateAward(UpdateAwardEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.updateAward(
        id: event.id, awardName: event.awardName, awardingBody: event.awardingBody,
        dateReceived: event.dateReceived, description: event.description,
        level: event.level, privacy: event.privacy,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        final idx = awards.indexWhere((e) => e.id == event.id);
        if (idx != -1) awards[idx] = r.data!;
        showToast('Award updated successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onDeleteAward(DeleteAwardEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.deleteAward(id: event.id);
      ProgressDialogUtils.hideProgressDialog();
      if (r.success) {
        awards.removeWhere((e) => e.id == event.id);
        showToast('Award deleted successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  // ── License CRUD ──

  Future<void> _onStoreLicense(StoreLicenseEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.storeLicense(
        licenseType: event.licenseType, licenseNumber: event.licenseNumber,
        issuingAuthority: event.issuingAuthority, issueDate: event.issueDate,
        expiryDate: event.expiryDate, privacy: event.privacy,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        licenses.add(r.data!);
        showToast('License added successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onUpdateLicense(UpdateLicenseEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.updateLicense(
        id: event.id, licenseType: event.licenseType, licenseNumber: event.licenseNumber,
        issuingAuthority: event.issuingAuthority, issueDate: event.issueDate,
        expiryDate: event.expiryDate, privacy: event.privacy,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        final idx = licenses.indexWhere((e) => e.id == event.id);
        if (idx != -1) licenses[idx] = r.data!;
        showToast('License updated successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onDeleteLicense(DeleteLicenseEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.deleteLicense(id: event.id);
      ProgressDialogUtils.hideProgressDialog();
      if (r.success) {
        licenses.removeWhere((e) => e.id == event.id);
        showToast('License deleted successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  // ── Social Profile CRUD ──

  Future<void> _onStoreSocialProfile(StoreSocialProfileEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.storeSocialProfile(
        platform: event.platform, profileUrl: event.profileUrl,
        username: event.username, isPublic: event.isPublic,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        socialProfiles.add(r.data!);
        showToast('Social profile added successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onUpdateSocialProfile(UpdateSocialProfileEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.updateSocialProfile(
        id: event.id, platform: event.platform, profileUrl: event.profileUrl,
        username: event.username, isPublic: event.isPublic,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        final idx = socialProfiles.indexWhere((e) => e.id == event.id);
        if (idx != -1) socialProfiles[idx] = r.data!;
        showToast('Social profile updated successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onDeleteSocialProfile(DeleteSocialProfileEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.deleteSocialProfile(id: event.id);
      ProgressDialogUtils.hideProgressDialog();
      if (r.success) {
        socialProfiles.removeWhere((e) => e.id == event.id);
        showToast('Social profile deleted successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  // ── Business Hours CRUD ──

  Future<void> _onStoreBusinessHour(StoreBusinessHourEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.storeBusinessHour(
        locationName: event.locationName, locationAddress: event.locationAddress,
        dayOfWeek: event.dayOfWeek, startTime: event.startTime,
        endTime: event.endTime, isAvailable: event.isAvailable, notes: event.notes,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        businessHours.add(r.data!);
        showToast('Business hours added successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onUpdateBusinessHour(UpdateBusinessHourEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.updateBusinessHour(
        id: event.id, locationName: event.locationName,
        locationAddress: event.locationAddress, dayOfWeek: event.dayOfWeek,
        startTime: event.startTime, endTime: event.endTime,
        isAvailable: event.isAvailable, notes: event.notes,
      );
      ProgressDialogUtils.hideProgressDialog();
      if (r.success && r.data != null) {
        final idx = businessHours.indexWhere((e) => e.id == event.id);
        if (idx != -1) businessHours[idx] = r.data!;
        showToast('Business hours updated successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }

  Future<void> _onDeleteBusinessHour(DeleteBusinessHourEvent event, Emitter<ProfileState> emit) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final r = await v5Api.deleteBusinessHour(id: event.id);
      ProgressDialogUtils.hideProgressDialog();
      if (r.success) {
        businessHours.removeWhere((e) => e.id == event.id);
        showToast('Business hours deleted successfully');
      }
      _reemitFullProfileState(emit);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      _reemitFullProfileState(emit);
    }
  }
}
