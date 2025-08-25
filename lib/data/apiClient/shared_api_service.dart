import 'dart:io';
import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/apiClient/services/search_api_service.dart';
import 'package:doctak_app/data/models/ads_model/ads_setting_model.dart';
import 'package:doctak_app/data/models/ads_model/ads_type_model.dart';
import 'package:doctak_app/data/models/case_model/add_comment_model.dart';
import 'package:doctak_app/data/models/case_model/case_comments.dart';
import 'package:doctak_app/data/models/case_model/case_discuss_model.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_ask_question_response.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'package:doctak_app/data/models/chat_model/contacts_model.dart';
import 'package:doctak_app/data/models/chat_model/message_model.dart';
import 'package:doctak_app/data/models/chat_model/search_contacts_model.dart';
import 'package:doctak_app/data/models/chat_model/send_message_model.dart';
import 'package:doctak_app/data/models/check_in_search_model/check_in_search_model.dart';
import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/data/models/followers_model/follower_data_model.dart';
import 'package:doctak_app/data/models/group_model/group_about_model.dart';
import 'package:doctak_app/data/models/group_model/group_details_model.dart';
import 'package:doctak_app/data/models/group_model/group_list_model.dart';
import 'package:doctak_app/data/models/group_model/group_member_request_model.dart';
import 'package:doctak_app/data/models/group_model/group_post_model.dart';
import 'package:doctak_app/data/models/guidelines_model/guidelines_model.dart';
import 'package:doctak_app/data/models/jobs_model/job_applicants_model.dart';
import 'package:doctak_app/data/models/jobs_model/job_detail_model.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
import 'package:doctak_app/data/models/meeting_model/create_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/fetching_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/meeting_details_model.dart';
import 'package:doctak_app/data/models/meeting_model/search_user_model.dart';
import 'package:doctak_app/data/models/news_model/news_model.dart';
import 'package:doctak_app/data/models/notification_model/notification_model.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/data/models/post_model/post_detail_model.dart';
import 'package:doctak_app/data/models/post_model/post_details_data_model.dart';
import 'package:doctak_app/data/models/post_model/post_likes_model.dart';
import 'package:doctak_app/data/models/profile_model/family_relationship_model.dart';
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/place_live_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/data/models/search_people_model/search_people_model.dart';
import 'package:doctak_app/data/models/search_user_tag_model/search_user_tag_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// SharedApiService - A unified API service for the entire DocTak application
/// Replaces retrofit implementation with a cleaner, more maintainable approach
class SharedApiService {
  static final SharedApiService _instance = SharedApiService._internal();
  factory SharedApiService() => _instance;
  SharedApiService._internal();

  final ApiCaller _apiCaller = ApiCaller();
  final SearchApiService _searchService = SearchApiService();

  // ================================== AUTH ENDPOINTS ==================================

  /// User login with email/password
  Future<ApiResponse<PostLoginDeviceAuthResp>> login({
    required String email,
    required String password,
    required String deviceType,
    required String deviceId,
    required String deviceToken,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/login',
          method: networkUtils.HttpMethod.POST,
          request: {
            'email': email,
            'password': password,
            'device_type': deviceType,
            'device_id': deviceId,
            'device_token': deviceToken,
          },
        ),
      );
      return ApiResponse.success(PostLoginDeviceAuthResp.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Login failed: $e');
    }
  }

  /// Social login (Google, Apple, etc.)
  Future<ApiResponse<PostLoginDeviceAuthResp>> loginWithSocial({
    required String email,
    required String firstName,
    required String lastName,
    required String deviceType,
    required String deviceId,
    required String deviceToken,
    required String provider,
    required String token,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/login',
          method: networkUtils.HttpMethod.POST,
          request: {
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'device_type': deviceType,
            'device_id': deviceId,
            'device_token': deviceToken,
            'isSocialLogin': 'true',
            'provider': provider,
            'token': token,
          },
        ),
      );
      return ApiResponse.success(PostLoginDeviceAuthResp.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Social login failed: $e');
    }
  }

  /// User registration
  Future<ApiResponse<Map<String, String>>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String userType,
    required String deviceToken,
    required String deviceType,
    required String deviceId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/register',
          method: networkUtils.HttpMethod.POST,
          request: {
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'password': password,
            'user_type': userType,
            'device_token': deviceToken,
            'device_type': deviceType,
            'device_id': deviceId,
          },
        ),
      );
      return ApiResponse.success(Map<String, String>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Registration failed: $e');
    }
  }

  /// Complete user profile after registration
  Future<ApiResponse<PostLoginDeviceAuthResp>> completeProfile({
    required String firstName,
    required String lastName,
    required String country,
    required String state,
    required String specialty,
    required String phone,
    required String userType,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/complete-profile',
          method: networkUtils.HttpMethod.POST,
          request: {
            'first_name': firstName,
            'last_name': lastName,
            'country': country,
            'state': state,
            'specialty': specialty,
            'phone': phone,
            'user_type': userType,
          },
        ),
      );
      return ApiResponse.success(PostLoginDeviceAuthResp.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Profile completion failed: $e');
    }
  }

  /// Forgot password
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/forgot_password',
          method: networkUtils.HttpMethod.POST,
          request: {'email': email},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Password reset failed: $e');
    }
  }

  // ================================== DATA ENDPOINTS ==================================

  /// Get countries list
  Future<ApiResponse<CountriesModel>> getCountries() async {
    try {
      print('🌍 Attempting to fetch countries from: /country-list');
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/country-list',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      print('🌍 Countries API response received successfully');
      return ApiResponse.success(CountriesModel.fromJson(response));
    } on ApiException catch (e) {
      print('🌍 Countries API Exception: ${e.message}');
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      print('🌍 Countries API Error: $e');
      // Provide a fallback response if server is not responding
      if (e.toString().contains('Timeout')) {
        print('🌍 Server timeout detected, providing fallback countries data');
        return _getFallbackCountries();
      }
      return ApiResponse.error('Failed to get countries: $e');
    }
  }

  /// Fallback countries data when server is not responding
  Future<ApiResponse<CountriesModel>> _getFallbackCountries() async {
    try {
      final fallbackData = {
        'countries': [
          {'id': 1, 'name': 'United States', 'code': 'US'},
          {'id': 2, 'name': 'United Kingdom', 'code': 'UK'},
          {'id': 3, 'name': 'Canada', 'code': 'CA'},
          {'id': 4, 'name': 'Australia', 'code': 'AU'},
          {'id': 5, 'name': 'Germany', 'code': 'DE'},
          {'id': 6, 'name': 'France', 'code': 'FR'},
          {'id': 7, 'name': 'India', 'code': 'IN'},
          {'id': 8, 'name': 'Japan', 'code': 'JP'},
          {'id': 9, 'name': 'China', 'code': 'CN'},
          {'id': 10, 'name': 'Brazil', 'code': 'BR'},
        ],
        'specialty': [
          {'id': 1, 'name': 'General Medicine'},
          {'id': 2, 'name': 'Cardiology'},
          {'id': 3, 'name': 'Dermatology'},
          {'id': 4, 'name': 'Neurology'},
          {'id': 5, 'name': 'Orthopedics'},
        ]
      };
      print('🌍 Using fallback countries data');
      return ApiResponse.success(CountriesModel.fromJson(fallbackData));
    } catch (e) {
      print('🌍 Error creating fallback countries: $e');
      return ApiResponse.error('Failed to load countries data: $e');
    }
  }

  /// Get states by country
  Future<ApiResponse<Map<String, dynamic>>> getStates({
    required String countryId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/get-states?country_id=$countryId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      
      // API returns a List directly, wrap it in a Map for backward compatibility
      if (response is List) {
        return ApiResponse.success({'data': response});
      } else if (response is Map<String, dynamic>) {
        return ApiResponse.success(response);
      } else {
        return ApiResponse.success({'data': []});
      }
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get states: $e');
    }
  }

  /// Get specialty list
  Future<ApiResponse<List<dynamic>>> getSpecialty() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/specialty',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      
      // API returns a List directly
      if (response is List) {
        return ApiResponse.success(response);
      } else if (response is Map<String, dynamic> && response['data'] is List) {
        // If it's wrapped in a Map with 'data' key
        return ApiResponse.success(response['data']);
      } else {
        // Fallback: return empty list
        return ApiResponse.success([]);
      }
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get specialties: $e');
    }
  }

  // ================================== POSTS ENDPOINTS ==================================

  /// Get posts feed
  Future<ApiResponse<Map<String, dynamic>>> getPosts({
    required String page,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/posts?page=$page',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get posts: $e');
    }
  }

  /// Get post details by ID
  Future<ApiResponse<PostDetailsDataModel>> getPostDetails({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/post-by-comment/$postId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(PostDetailsDataModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get post details: $e');
    }
  }

  /// Get post details with likes
  Future<ApiResponse<PostDetailModel>> getPostDetailsWithLikes({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/posts/$postId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(PostDetailModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get post with likes: $e');
    }
  }

  /// Get user posts
  Future<ApiResponse<PostDataModel>> getMyPosts({
    required String page,
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/user-profile-post?page=$page&user_id=$userId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(PostDataModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get user posts: $e');
    }
  }

  /// Like/Unlike post
  Future<ApiResponse<Map<String, dynamic>>> likePost({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/like?post_id=$postId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to like post: $e');
    }
  }

  /// Delete post
  Future<ApiResponse<Map<String, dynamic>>> deletePost({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/delete_post?post_id=$postId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete post: $e');
    }
  }

  // ================================== COMMENTS ENDPOINTS ==================================

  /// Get post comments
  Future<ApiResponse<PostCommentModel>> getPostComments({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/get-post-comments?post_id=$postId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(PostCommentModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get comments: $e');
    }
  }

  /// Add comment to post
  Future<ApiResponse<Map<String, dynamic>>> makeComment({
    required String postId,
    required String comment,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/post-comment?post_id=$postId&comment=$comment',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to add comment: $e');
    }
  }

  /// Delete comment
  Future<ApiResponse<Map<String, dynamic>>> deleteComment({
    required String commentId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/delete-comment',
          method: networkUtils.HttpMethod.POST,
          request: {'comment_id': commentId},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete comment: $e');
    }
  }

  // ================================== CHATGPT ENDPOINTS ==================================

  /// Ask question to ChatGPT with images
  Future<ApiResponse<ChatGptAskQuestionResponse>> askQuestionWithImages({
    required String sessionId,
    required String question,
    required String imageType,
    String? imageUrl1,
    String? imageUrl2,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/ask-question',
          method: networkUtils.HttpMethod.POST,
          request: {
            'id': sessionId,
            'question': question,
            'image_type': imageType,
            if (imageUrl1 != null) 'image1': imageUrl1,
            if (imageUrl2 != null) 'image2': imageUrl2,
          },
        ),
      );
      return ApiResponse.success(ChatGptAskQuestionResponse.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to ask question: $e');
    }
  }

  /// Ask question to ChatGPT without images
  Future<ApiResponse<ChatGptAskQuestionResponse>> askQuestionWithoutImages({
    required String sessionId,
    required String question,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/ask-question',
          method: networkUtils.HttpMethod.POST,
          request: {
            'id': sessionId,
            'question': question,
          },
        ),
      );
      return ApiResponse.success(ChatGptAskQuestionResponse.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to ask question: $e');
    }
  }

  /// Get ChatGPT sessions
  Future<ApiResponse<ChatGptSession>> getChatGptSessions() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/gptChat-session',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(ChatGptSession.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get sessions: $e');
    }
  }

  /// Get ChatGPT message history
  Future<ApiResponse<ChatGptMessageHistory>> getChatGptMessages({
    required String sessionId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/gptChat-history/$sessionId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(ChatGptMessageHistory.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get messages: $e');
    }
  }

  /// Create new ChatGPT session
  Future<ApiResponse<Map<String, dynamic>>> createNewChatSession() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/new-chat',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to create new session: $e');
    }
  }

  /// Delete ChatGPT session
  Future<ApiResponse<Map<String, dynamic>>> deleteChatGptSession({
    required String sessionId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/delete-chatgpt-session?session_id=$sessionId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete session: $e');
    }
  }

  // ================================== MEETING ENDPOINTS ==================================

  /// Get scheduled meetings
  Future<ApiResponse<GetMeetingModel>> getMeetings() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/get-schedule-meetings',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(GetMeetingModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get meetings: $e');
    }
  }

  /// Start/Create meeting
  Future<ApiResponse<CreateMeetingModel>> startMeeting() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/create-meeting',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(CreateMeetingModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to start meeting: $e');
    }
  }

  /// Join meeting by code
  Future<ApiResponse<MeetingDetailsModel>> joinMeeting({
    required String meetingCode,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/join-meeting?meeting_channel=$meetingCode',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(MeetingDetailsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to join meeting: $e');
    }
  }

  /// Search users for meeting invitation
  Future<ApiResponse<SearchUserModel>> searchUsersForMeeting({
    required String query,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/users?query=$query',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(SearchUserModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search users: $e');
    }
  }

  /// End meeting
  Future<ApiResponse<Map<String, dynamic>>> endMeeting({
    required String meetingId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/close-meeting',
          method: networkUtils.HttpMethod.POST,
          request: {'meeting_id': meetingId},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to end meeting: $e');
    }
  }

  // ================================== JOBS ENDPOINTS ==================================

  /// Get jobs list
  Future<ApiResponse<JobsModel>> getJobsList({
    required String page,
    required String countryId,
    required String searchTerm,
    required String expiredJob,
  }) async {
    // try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs?page=$page&country_id=$countryId&searchTerm=$searchTerm&expired_job=$expiredJob',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobsModel.fromJson(response));
    // } on ApiException catch (e) {
    //   return ApiResponse.error(e.message, statusCode: e.statusCode);
    // } catch (e) {
    //   return ApiResponse.error('Failed to get jobs: $e');
    // }
  }

  /// Get job details
  Future<ApiResponse<JobDetailModel>> getJobDetails({
    required String jobId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/job_detail?job_id=$jobId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(JobDetailModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get job details: $e');
    }
  }

  /// Withdraw job application
  Future<ApiResponse<Map<String, dynamic>>> withdrawJobApplication({
    required String jobId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/withdraw-job-application?job_id=$jobId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to withdraw application: $e');
    }
  }

  /// Get job applicants
  Future<ApiResponse<JobApplicantsModel>> getJobApplicants({
    required String jobId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/job-applicants?job_id=$jobId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobApplicantsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get job applicants: $e');
    }
  }

  // ================================== NOTIFICATIONS ENDPOINTS ==================================

  /// Get notifications
  Future<ApiResponse<NotificationModel>> getNotifications({
    required String page,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/notifications?page=$page',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(NotificationModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get notifications: $e');
    }
  }

  /// Mark notification as read
  Future<ApiResponse<Map<String, dynamic>>> markNotificationAsRead({
    required String notificationId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/notifications/$notificationId/mark-read',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to mark notification as read: $e');
    }
  }

  // ================================== PROFILE ENDPOINTS ==================================

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

  /// Update profile
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

  /// Get user work education
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

  // ================================== CHAT ENDPOINTS ==================================

  /// Get contacts for chat
  Future<ApiResponse<ContactsModel>> getContacts({
    required String page,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/get-contacts?page=$page',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(ContactsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get contacts: $e');
    }
  }

  /// Get chat messages
  Future<ApiResponse<MessageModel>> getChatMessages({
    required String page,
    required String userId,
    required String roomId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/messenger?page=$page&user_id=$userId&room_id=$roomId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(MessageModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get messages: $e');
    }
  }

  /// Send text message
  Future<ApiResponse<SendMessageModel>> sendTextMessage({
    required String userId,
    required String roomId,
    required String receiverId,
    required String message,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/send-message',
          method: networkUtils.HttpMethod.POST,
          request: {
            'user_id': userId,
            'room_id': roomId,
            'receiver_id': receiverId,
            'attachment_type': 'text',
            'message': message,
          },
        ),
      );
      return ApiResponse.success(SendMessageModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to send message: $e');
    }
  }

  // ================================== SEARCH ENDPOINTS ==================================

  /// Search posts
  Future<ApiResponse<PostDataModel>> searchPosts({
    required String page,
    required String searchTerm,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search-post?page=$page&search=$searchTerm',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(PostDataModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search posts: $e');
    }
  }

  /// Search people
  Future<ApiResponse<SearchPeopleModel>> searchPeople({
    required String page,
    required String searchTerm,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/searchPeople?page=$page&searchTerm=$searchTerm',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(SearchPeopleModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search people: $e');
    }
  }

  /// Search drugs
  Future<ApiResponse<DrugsModel>> searchDrugs({
    required String page,
    required String countryId,
    required String searchTerm,
    required String type,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/drug-search?page=$page&countryId=$countryId&searchTerm=$searchTerm&type=$type',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(DrugsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search drugs: $e');
    }
  }

  // ================================== UTILITY METHODS ==================================

  /// Test API connectivity
  Future<ApiResponse<Map<String, dynamic>>> testConnection() async {
    try {
      print('🔗 Testing API connectivity...');
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/country-list',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      print('🔗 API connectivity test successful');
      return ApiResponse.success({'status': 'connected', 'message': 'API is reachable'});
    } catch (e) {
      print('🔗 API connectivity test failed: $e');
      return ApiResponse.error('API connectivity failed: $e');
    }
  }

  /// Generic method for handling common API patterns
  Future<ApiResponse<T>> _makeRequest<T>(
    String endpoint,
    networkUtils.HttpMethod method,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, dynamic>? request,
    Map<String, String>? queryParams,
  }) async {
    try {
      String fullEndpoint = endpoint;
      if (queryParams != null && queryParams.isNotEmpty) {
        final query = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        fullEndpoint += (endpoint.contains('?') ? '&' : '?') + query;
      }

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          fullEndpoint,
          method: method,
          request: request,
        ),
      );
      return ApiResponse.success(fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Request failed: $e');
    }
  }

  /// Generic method for simple responses
  Future<ApiResponse<Map<String, dynamic>>> _makeSimpleRequest(
    String endpoint,
    networkUtils.HttpMethod method, {
    Map<String, dynamic>? request,
    Map<String, String>? queryParams,
  }) async {
    return _makeRequest<Map<String, dynamic>>(
      endpoint,
      method,
      (response) => Map<String, dynamic>.from(response),
      request: request,
      queryParams: queryParams,
    );
  }

  // ================================== SEARCH ENDPOINTS ==================================

  /// Search conferences
  Future<ApiResponse<SearchConferenceModel>> searchConferences({
    required String page,
    required String keyword,
  }) async {
    return await _searchService.searchConferences(
      page: page,
      keyword: keyword,
    );
  }

  /// Search guidelines
  Future<ApiResponse<GuidelinesModel>> searchGuidelines({
    required String page,
    required String keyword,
  }) async {
    return await _searchService.searchGuides(
      page: page,
      keyword: keyword,
    );
  }
}