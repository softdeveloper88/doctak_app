import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/followers_model/follower_data_model.dart';
import 'package:doctak_app/data/models/profile_model/family_relationship_model.dart';
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/place_live_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Profile API Service
/// Handles all user profile related API calls
class ProfileApiService {
  static final ProfileApiService _instance = ProfileApiService._internal();
  factory ProfileApiService() => _instance;
  ProfileApiService._internal();

  /// Get user profile
  Future<ApiResponse<UserProfile>> getProfile({
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/profile?user_id=$userId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(UserProfile.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get profile: $e');
    }
  }

  /// Update profile information
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String licenseNo,
    required String specialty,
    required String dob,
    required String gender,
    required String country,
    required String city,
    required String countryOrigin,
    required String dobPrivacy,
    required String emailPrivacy,
    required String genderPrivacy,
    required String phonePrivacy,
    required String licenseNoPrivacy,
    required String specialtyPrivacy,
    required String countryPrivacy,
    required String cityPrivacy,
    required String countryOriginPrivacy,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/profile/update',
          method: networkUtils.HttpMethod.POST,
          request: {
            'first_name': firstName,
            'last_name': lastName,
            'phone': phone,
            'license_no': licenseNo,
            'specialty': specialty,
            'dob': dob,
            'gender': gender,
            'country': country,
            'city': city,
            'country_origin': countryOrigin,
            'dob_privacy': dobPrivacy,
            'email_privacy': emailPrivacy,
            'gender_privacy': genderPrivacy,
            'phone_privacy': phonePrivacy,
            'license_no_privacy': licenseNoPrivacy,
            'specialty_privacy': specialtyPrivacy,
            'country_privacy': countryPrivacy,
            'city_privacy': cityPrivacy,
            'country_origin_privacy': countryOriginPrivacy,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update profile: $e');
    }
  }

  /// Upload profile picture
  Future<ApiResponse<Map<String, dynamic>>> uploadProfilePicture({
    required String filePath,
  }) async {
    try {
      // Note: This needs proper file upload handling in networkUtils
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/upload-profile-pic',
          method: networkUtils.HttpMethod.POST,
          request: {'profile_pic': filePath},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to upload profile picture: $e');
    }
  }

  /// Upload cover picture
  Future<ApiResponse<Map<String, dynamic>>> uploadCoverPicture({
    required String filePath,
  }) async {
    try {
      // Note: This needs proper file upload handling in networkUtils
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/upload-cover-pic',
          method: networkUtils.HttpMethod.POST,
          request: {'background': filePath},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to upload cover picture: $e');
    }
  }

  /// Get user interests
  Future<ApiResponse<List<InterestModel>>> getInterests({
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/interests?user_id=$userId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final List<dynamic> interestsData = response as List<dynamic>;
      final interests = interestsData.map((json) => InterestModel.fromJson(json)).toList();
      return ApiResponse.success(interests);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get interests: $e');
    }
  }

  /// Update user interests
  Future<ApiResponse<Map<String, dynamic>>> updateInterests({
    required List<InterestModel> interests,
  }) async {
    try {
      // Note: This needs proper JSON encoding for list data
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/interests/update',
          method: networkUtils.HttpMethod.POST,
          request: {'interests': interests.map((i) => i.toJson()).toList()},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update interests: $e');
    }
  }

  /// Get work and education information
  Future<ApiResponse<List<WorkEducationModel>>> getWorkEducation({
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/work-and-education?user_id=$userId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final List<dynamic> workEducationData = response as List<dynamic>;
      final workEducation = workEducationData.map((json) => WorkEducationModel.fromJson(json)).toList();
      return ApiResponse.success(workEducation);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get work education: $e');
    }
  }

  /// Add or update work/education entry
  Future<ApiResponse<Map<String, dynamic>>> updateWorkEducation({
    required String id,
    required String companyName,
    required String position,
    required String address,
    required String degree,
    required String course,
    required String workType,
    required String startDate,
    required String endDate,
    required String currentStatus,
    required String description,
    required String privacy,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/update-work-and-education',
          method: networkUtils.HttpMethod.POST,
          request: {
            'id': id,
            'name': companyName,
            'position': position,
            'city': address,
            'degree': degree,
            'course': course,
            'type': workType,
            'from': startDate,
            'to': endDate,
            'current_status': currentStatus,
            'description': description,
            'privacy': privacy,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update work education: $e');
    }
  }

  /// Delete work/education entry
  Future<ApiResponse<Map<String, dynamic>>> deleteWorkEducation({
    required String id,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/delete-work-and-education',
          method: networkUtils.HttpMethod.POST,
          request: {'id': id},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete work education: $e');
    }
  }

  /// Get places lived information
  Future<ApiResponse<PlaceLiveModel>> getPlacesLived({
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/places-lived?user_id=$userId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(PlaceLiveModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get places lived: $e');
    }
  }

  /// Update places lived information
  Future<ApiResponse<Map<String, dynamic>>> updatePlacesLived({
    required String place,
    required String description,
    required String privacy,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/places-lived/update?place=$place&description=$description&privacy=$privacy',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update places lived: $e');
    }
  }

  /// Get family relationship information
  Future<ApiResponse<FamilyRelationshipModel>> getFamilyRelationship({
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/family-relationship?user_id=$userId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(FamilyRelationshipModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get family relationship: $e');
    }
  }

  /// Update about me information
  Future<ApiResponse<Map<String, dynamic>>> updateAboutMe({
    required String aboutMe,
    required String address,
    required String birthplace,
    required String liveIn,
    required String languages,
    required String aboutMePrivacy,
    required String addressPrivacy,
    required String birthplacePrivacy,
    required String languagesPrivacy,
    required String livesInPrivacy,
    required String phonePrivacy,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/about-me/update',
          method: networkUtils.HttpMethod.POST,
          request: {
            'about_me': aboutMe,
            'address': address,
            'birthplace': birthplace,
            'lives_in': liveIn,
            'languages': languages,
            'about_me_privacy': aboutMePrivacy,
            'address_privacy': addressPrivacy,
            'birthplace_privacy': birthplacePrivacy,
            'language_privacy': languagesPrivacy,
            'lives_in_privacy': livesInPrivacy,
            'phone_privacy': phonePrivacy,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update about me: $e');
    }
  }

  /// Get about me information
  Future<ApiResponse<Map<String, dynamic>>> getAboutMe() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/about-me',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get about me: $e');
    }
  }

  /// Follow/Unfollow user
  Future<ApiResponse<Map<String, dynamic>>> followUser({
    required String userId,
    required String followAction, // "follow" or "unfollow"
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/user/$userId/$followAction',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to $followAction user: $e');
    }
  }

  /// Get user followers and following
  Future<ApiResponse<FollowerDataModel>> getUserFollowers({
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/followers-and-following',
          method: networkUtils.HttpMethod.POST,
          request: {'user_id': userId},
        ),
      );
      return ApiResponse.success(FollowerDataModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get followers: $e');
    }
  }

  /// Update hobbies and interests
  Future<ApiResponse<Map<String, dynamic>>> updateHobbiesInterests({
    required String id,
    required String favTvShows,
    required String favMovies,
    required String favBooks,
    required String favWriters,
    required String favMusicBands,
    required String favGames,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/update-hobbies-interests',
          method: networkUtils.HttpMethod.POST,
          request: {
            'id': id,
            'favt_tv_shows': favTvShows,
            'favt_movies': favMovies,
            'favt_books': favBooks,
            'favt_writers': favWriters,
            'favt_music_bands': favMusicBands,
            'favt_games': favGames,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update hobbies interests: $e');
    }
  }

  // ================================== BACKWARD COMPATIBILITY ==================================

  /// Get profile update method (backward compatibility)  
  Future<ApiResponse<Map<String, dynamic>>> getProfileUpdate({
    required String firstName,
    required String lastName,
    required String phone,
    required String licenseNo,
    required String specialty,
    required String dob,
    required String gender,
    required String country,
    required String city,
    required String countryOrigin,
    required String dobPrivacy,
    required String emailPrivacy,
    required String genderPrivacy,
    required String phonePrivacy,
    required String licenseNoPrivacy,
    required String specialtyPrivacy,
    required String countryPrivacy,
    required String cityPrivacy,
    required String countryOriginPrivacy,
  }) async {
    return updateProfile(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      licenseNo: licenseNo,
      specialty: specialty,
      dob: dob,
      gender: gender,
      country: country,
      city: city,
      countryOrigin: countryOrigin,
      dobPrivacy: dobPrivacy,
      emailPrivacy: emailPrivacy,
      genderPrivacy: genderPrivacy,
      phonePrivacy: phonePrivacy,
      licenseNoPrivacy: licenseNoPrivacy,
      specialtyPrivacy: specialtyPrivacy,
      countryPrivacy: countryPrivacy,
      cityPrivacy: cityPrivacy,
      countryOriginPrivacy: countryOriginPrivacy,
    );
  }
}