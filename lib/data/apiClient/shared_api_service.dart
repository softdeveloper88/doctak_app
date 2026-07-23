import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/apiClient/services/search_api_service.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_ask_question_response.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_message_history/chat_gpt_message_history.dart';
import 'package:doctak_app/data/models/chat_gpt_model/chat_gpt_sesssion/chat_gpt_session.dart';
import 'package:doctak_app/data/models/chat_model/contacts_model.dart';
import 'package:doctak_app/data/models/chat_model/message_model.dart';
import 'package:doctak_app/data/models/chat_model/send_message_model.dart';
import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:doctak_app/data/models/countries_model/countries_model.dart';
import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/data/models/feed_model/feed_models.dart';
import 'package:doctak_app/data/models/survey_model/survey_detail_model.dart';
import 'package:doctak_app/data/models/followers_model/follower_data_model.dart';
import 'package:doctak_app/data/models/guidelines_model/guidelines_model.dart';
import 'package:doctak_app/data/models/jobs_model/job_applicants_model.dart';
import 'package:doctak_app/data/models/jobs_model/job_detail_model.dart';
import 'package:doctak_app/data/models/jobs_model/jobs_model.dart';
import 'package:doctak_app/data/models/login_device_auth/post_login_device_auth_resp.dart';
import 'package:doctak_app/data/models/meeting_model/create_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/fetching_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/meeting_details_model.dart';
import 'package:doctak_app/data/models/meeting_model/search_user_model.dart';
import 'package:doctak_app/data/models/notification_model/notification_model.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/data/models/post_model/post_reactions_model.dart';
import 'package:doctak_app/data/models/post_model/post_detail_model.dart';
import 'package:doctak_app/data/models/post_model/post_details_data_model.dart';
import 'package:doctak_app/data/models/profile_model/interest_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_completed_survey_model.dart';
import 'package:doctak_app/data/models/profile_model/profile_model.dart';
import 'package:doctak_app/data/models/profile_model/work_education_model.dart';
import 'package:doctak_app/data/models/search_people_model/search_people_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// SharedApiService - A unified API service for the entire DocTak application
/// Replaces retrofit implementation with a cleaner, more maintainable approach
class SharedApiService {
  static final SharedApiService _instance = SharedApiService._internal();
  factory SharedApiService() => _instance;
  SharedApiService._internal();

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
        await networkUtils.buildHttpResponseV6(
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
        await networkUtils.buildHttpResponseV6(
          '/social-login',
          method: networkUtils.HttpMethod.POST,
          request: {
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'device_type': deviceType,
            'device_id': deviceId,
            'device_token': deviceToken,
            'provider': provider,
            'id_token': token,
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
        await networkUtils.buildHttpResponseV6(
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
        await networkUtils.buildHttpResponseV6(
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

  /// Forgot password — checks email exists, then emails a mobile-friendly reset link.
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/forgot_password',
          method: networkUtils.HttpMethod.POST,
          request: {
            'email': email,
            'device_type': Platform.isIOS ? 'ios' : 'android',
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Password reset failed: $e');
    }
  }

  /// Logout via doctak-node (`POST /api/v1/logout`).
  /// Removes this device's FCM token server-side and clears the session.
  Future<ApiResponse<Map<String, dynamic>>> logout({
    required String deviceId,
    String? deviceToken,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/logout',
          method: networkUtils.HttpMethod.POST,
          body: {
            'device_id': deviceId,
            if (deviceToken != null && deviceToken.isNotEmpty)
              'device_token': deviceToken,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Logout failed: $e');
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
        ],
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

  // ================================== FEED ENDPOINTS ==================================

  /// Get the typed home feed from doctak-node (`GET /api/feed`).
  ///
  /// Returns typed entries (post/poll/blog/case/job/cme/survey) plus
  /// horizontal strips, with cursor-based pagination.
  Future<ApiResponse<FeedResponse>> getHomeFeed({
    String? cursor,
    int limit = 20,
    bool initial = false,
  }) async {
    try {
      final params = <String, String>{'limit': '$limit'};
      if (initial) {
        params['initial'] = '1';
      }
      if (cursor != null && cursor.isNotEmpty) {
        params['cursor'] = cursor;
      }
      final query = params.entries
          .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/feed?$query',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(
        FeedResponse.fromJson(Map<String, dynamic>.from(response)),
      );
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load feed: $e');
    }
  }

  /// Fallback: load discuss cases for home feed when `/api/feed` omits them.
  Future<List<FeedItem>> fetchCasesForFeed({int limit = 3}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/cases?page=1&per_page=$limit',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final data = response['data'];
      if (data is! Map) return const [];
      final cases = data['cases'];
      if (cases is! Map) return const [];
      final list = cases['data'];
      if (list is! List) return const [];

      return list.whereType<Map>().map((raw) {
        final row = Map<String, dynamic>.from(raw);
        final id = '${row['id'] ?? ''}';
        return FeedItem(
          type: 'case',
          id: id,
          createdAt: row['created_at']?.toString(),
          authorId: row['user_id']?.toString(),
          engagement: FeedEngagement(
            views: _parseInt(row['views']),
            likes: _parseInt(row['likes']),
            comments: _parseInt(row['comments_count']),
          ),
          payload: {
            'title': row['title']?.toString(),
            'description': row['description']?.toString(),
            'tags': row['tags']?.toString(),
            'authorName': row['name']?.toString(),
            'authorAvatar': row['profile_pic']?.toString(),
            'authorSpecialty': row['specialty']?.toString(),
            'is_liked': row['is_liked'] == true || row['is_liked'] == 1,
          },
        );
      }).where((item) => item.id.isNotEmpty).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Load a single survey with questions (`GET /api/v1/surveys/{id}`).
  Future<ApiResponse<SurveyDetail>> getSurveyDetail(String surveyId) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/surveys/$surveyId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      if (response is Map && response['success'] == false) {
        return ApiResponse.error(
          response['message']?.toString() ?? 'Failed to load survey',
        );
      }
      final survey = response['survey'];
      if (survey is! Map) {
        return ApiResponse.error('Survey not found');
      }
      return ApiResponse.success(
        SurveyDetail.fromJson(Map<String, dynamic>.from(survey)),
      );
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load survey: $e');
    }
  }

  /// Submit survey answers (`POST /api/v1/surveys/{id}/respond`).
  Future<ApiResponse<void>> submitSurveyResponse({
    required String surveyId,
    required List<Map<String, String>> answers,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/surveys/$surveyId/respond',
          method: networkUtils.HttpMethod.POST,
          body: {'answers': answers},
        ),
      );
      if (response is Map && response['success'] == false) {
        return ApiResponse.error(
          response['message']?.toString() ?? 'Failed to submit survey',
        );
      }
      return ApiResponse.success(null);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to submit survey: $e');
    }
  }

  /// Fallback: extract survey items from a larger feed page when strips are missing.
  Future<List<FeedItem>> fetchSurveysForFeed({int limit = 3}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/surveys/browse?limit=$limit',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final raw = response['surveys'];
      if (raw is! List) return const [];
      final out = <FeedItem>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        out.add(FeedItem.fromJson(Map<String, dynamic>.from(entry)));
        if (out.length >= limit) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static int _parseInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? 0}') ?? 0;
  }

  // ================================== CREATE (doctak-node) ==================================

  /// Create a poll (`POST /api/polls`).
  Future<ApiResponse<Map<String, dynamic>>> createPoll({
    required String title,
    String? description,
    required List<String> options,
    int durationValue = 1,
    String durationUnit = 'days',
    bool isMultipleChoice = false,
    bool showVoters = true,
    bool isAnonymous = false,
    bool allowAddOptions = false,
    bool allowChangeVote = false,
    String privacy = 'public',
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/polls',
          method: networkUtils.HttpMethod.POST,
          body: {
            'title': title,
            'description': description,
            'options': options,
            'durationValue': durationValue,
            'durationUnit': durationUnit,
            'isMultipleChoice': isMultipleChoice,
            'showVoters': showVoters,
            'isAnonymous': isAnonymous,
            'allowAddOptions': allowAddOptions,
            'allowChangeVote': allowChangeVote,
            'privacy': privacy,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to create poll: $e');
    }
  }

  /// List blog categories (`GET /api/blogs/categories`).
  Future<ApiResponse<List<Map<String, dynamic>>>> getBlogCategories() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/categories',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final raw = response['categories'];
      final list = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            list.add(Map<String, dynamic>.from(item));
          }
        }
      }
      return ApiResponse.success(list);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load blog categories: $e');
    }
  }

  /// Upload media for posts/blogs (`POST /api/posts/media`).
  Future<ApiResponse<Map<String, dynamic>>> uploadPostMedia(File file) async {
    try {
      final base = AppData.nodeApiUrl.endsWith('/')
          ? AppData.nodeApiUrl.substring(0, AppData.nodeApiUrl.length - 1)
          : AppData.nodeApiUrl;
      final uri = Uri.parse('$base/api/posts/media');
      final request = http.MultipartRequest('POST', uri);

      final token = AppData.userToken?.trim();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      request.headers.addAll(ActingContextService.instance.actingHeaders());

      final name = file.path.split('/').last.toLowerCase();
      var mime = 'image/jpeg';
      if (name.endsWith('.png')) mime = 'image/png';
      if (name.endsWith('.webp')) mime = 'image/webp';
      if (name.endsWith('.gif')) mime = 'image/gif';

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mime),
      ));

      final streamed = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw ApiException(message: 'Upload timed out', statusCode: 408),
      );
      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded is Map &&
          decoded['success'] == true) {
        return ApiResponse.success(Map<String, dynamic>.from(decoded));
      }
      final message = decoded is Map
          ? (decoded['message']?.toString() ?? 'Upload failed')
          : 'Upload failed';
      return ApiResponse.error(message, statusCode: response.statusCode);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to upload media: $e');
    }
  }

  /// Create a blog/article (`POST /api/blogs`).
  Future<ApiResponse<Map<String, dynamic>>> createBlog({
    required String title,
    required String content,
    String? slug,
    String? excerpt,
    String? coverImage,
    dynamic categoryId,
    String? metaTitle,
    String? metaDescription,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs',
          method: networkUtils.HttpMethod.POST,
          body: {
            'title': title,
            'content': content,
            'slug': slug,
            'excerpt': excerpt,
            'coverImage': coverImage,
            'categoryId': categoryId,
            'metaTitle': metaTitle,
            'metaDescription': metaDescription,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to create blog: $e');
    }
  }

  /// Update a poll question/description (`PATCH /api/polls/{id}`).
  Future<ApiResponse<Map<String, dynamic>>> updatePoll({
    required String pollId,
    required String title,
    String? description,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/polls/$pollId',
          method: networkUtils.HttpMethod.PATCH,
          body: {
            'title': title,
            'description': description,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update poll: $e');
    }
  }

  /// Update a blog/article (`PATCH /api/blogs/{id}`).
  Future<ApiResponse<Map<String, dynamic>>> updateBlog({
    required String blogId,
    required String title,
    String? excerpt,
    String? content,
    String? slug,
    String? coverImage,
  }) async {
    try {
      final body = <String, dynamic>{'title': title};
      if (excerpt != null) body['excerpt'] = excerpt;
      if (content != null) body['content'] = content;
      if (slug != null) body['slug'] = slug;
      if (coverImage != null) body['coverImage'] = coverImage;

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId',
          method: networkUtils.HttpMethod.PATCH,
          body: body,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update blog: $e');
    }
  }

  /// Delete a blog/article (`DELETE /api/blogs/{id}`).
  Future<ApiResponse<Map<String, dynamic>>> deleteBlog({
    required String blogId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId',
          method: networkUtils.HttpMethod.DELETE,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete blog: $e');
    }
  }

  /// Fetch a single post for edit (`GET /api/v1/posts/{id}`).
  Future<ApiResponse<Map<String, dynamic>>> getPostV1({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseV6(
          '/posts/$postId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load post: $e');
    }
  }

  /// Edit a post body/title/media (`PATCH /api/v1/posts/{id}`).
  Future<ApiResponse<Map<String, dynamic>>> updatePost({
    required String postId,
    required String body,
    String? title,
    List<Map<String, dynamic>>? newMedia,
    List<String>? removeMediaIds,
  }) async {
    try {
      final payload = <String, dynamic>{'body': body};
      if (title != null) payload['title'] = title;
      if (newMedia != null && newMedia.isNotEmpty) {
        payload['newMedia'] = newMedia;
      }
      if (removeMediaIds != null && removeMediaIds.isNotEmpty) {
        payload['removeMediaIds'] = removeMediaIds;
      }

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseV6(
          '/posts/$postId',
          method: networkUtils.HttpMethod.PATCH,
          request: payload,
          jsonBody: true,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update post: $e');
    }
  }

  /// Delete a post/poll via doctak-node (`DELETE /api/v1/posts/{id}`).
  Future<ApiResponse<Map<String, dynamic>>> deletePostV1({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseV6(
          '/posts/$postId',
          method: networkUtils.HttpMethod.DELETE,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete post: $e');
    }
  }

  // ================================== REACTIONS / SHARE / REPOST ==================================

  /// React to a post with a specific reaction type (`POST /api/v1/like?post_id=&reaction=`).
  ///
  /// Sending the same reaction again removes it (toggle). [reaction] is one of
  /// like/love/insightful/care/haha/wow/sad/angry.
  Future<ApiResponse<Map<String, dynamic>>> reactToPost({
    required String postId,
    String reaction = 'like',
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/like?post_id=${Uri.encodeQueryComponent(postId)}&reaction=${Uri.encodeQueryComponent(reaction)}',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to react: $e');
    }
  }

  /// Paginated users who reacted to a post or blog
  /// (`GET /api/v1/getPostLikes?type=&id=&reaction_type=&page=`).
  Future<ApiResponse<PostReactionsPage>> getPostReactions({
    required String contentId,
    String contentType = 'post',
    String? reactionType,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{
        'type': contentType,
        'id': contentId,
        'page': '$page',
        'per_page': '20',
      };
      if (reactionType != null && reactionType.isNotEmpty && reactionType != 'all') {
        params['reaction_type'] = reactionType;
      }
      final query = params.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/getPostLikes?$query',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(
        PostReactionsPage.fromJson(Map<String, dynamic>.from(response)),
      );
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load reactions: $e');
    }
  }

  /// Top reaction types for a post (`GET /api/v1/getPostReactionSummary?postId=`).
  Future<ApiResponse<Map<String, dynamic>>> getPostReactionSummary({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/getPostReactionSummary?postId=${Uri.encodeQueryComponent(postId)}',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load reaction summary: $e');
    }
  }

  /// Fetch the current viewer's blog reaction state + counts
  /// (`GET /api/blogs/{id}/like`).
  Future<ApiResponse<Map<String, dynamic>>> getBlogReaction({
    required String blogId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId/like',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load reaction: $e');
    }
  }

  /// React to a blog (`POST /api/blogs/{id}/like?reaction=`).
  Future<ApiResponse<Map<String, dynamic>>> reactToBlog({
    required String blogId,
    String reaction = 'like',
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId/like?reaction=${Uri.encodeQueryComponent(reaction)}',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to react to blog: $e');
    }
  }

  /// Toggle a Doctak repost of a post (`POST /api/v1/repost?post_id=`).
  Future<ApiResponse<Map<String, dynamic>>> repostPost({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/repost?post_id=${Uri.encodeQueryComponent(postId)}',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to repost: $e');
    }
  }

  /// Toggle a Doctak repost of a blog (`POST /api/blogs/{id}/repost`).
  Future<ApiResponse<Map<String, dynamic>>> repostBlog({
    required String blogId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId/repost',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to repost blog: $e');
    }
  }

  /// Record an external share of a post (`POST /api/v1/post-share?post_id=`).
  Future<ApiResponse<Map<String, dynamic>>> recordShare({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/post-share?post_id=${Uri.encodeQueryComponent(postId)}',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to record share: $e');
    }
  }

  /// Record a feed interaction (share, click, etc.) via the node batch API
  /// (`POST /api/feed/interactions/batch`).
  Future<ApiResponse<Map<String, dynamic>>> recordFeedInteraction({
    required String contentType,
    required String contentId,
    required String type,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/feed/interactions/batch',
          method: networkUtils.HttpMethod.POST,
          body: {
            'events': [
              {
                'contentType': contentType,
                'contentId': contentId,
                'type': type,
              },
            ],
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to record interaction: $e');
    }
  }

  /// Fetch blog repost state (`GET /api/blogs/{id}/repost`).
  Future<ApiResponse<Map<String, dynamic>>> getBlogRepost({
    required String blogId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId/repost',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load repost state: $e');
    }
  }

  // ================================== BLOG READ (doctak-node) ==================================

  /// Fetch a single blog detail (`GET /api/blogs/{id}`).
  Future<ApiResponse<Map<String, dynamic>>> getBlogDetail({
    required String blogId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load blog: $e');
    }
  }

  /// Fetch blog comments (`GET /api/blogs/{id}/comments`).
  Future<ApiResponse<Map<String, dynamic>>> getBlogComments({
    required String blogId,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId/comments?page=$page&per_page=$perPage',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load blog comments: $e');
    }
  }

  /// Add a comment to a blog (`POST /api/blogs/{id}/comments`).
  Future<ApiResponse<Map<String, dynamic>>> addBlogComment({
    required String blogId,
    required String body,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId/comments',
          method: networkUtils.HttpMethod.POST,
          body: {'body': body, 'comment': body},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to add blog comment: $e');
    }
  }

  /// Add blog comment replies (`GET /api/blogs/{blogId}/comments/{commentId}/replies`).
  Future<ApiResponse<Map<String, dynamic>>> getBlogCommentReplies({
    required String blogId,
    required String commentId,
    int page = 1,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId/comments/$commentId/replies?page=$page',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load blog replies: $e');
    }
  }

  /// Post a reply to a blog comment (`POST /api/blogs/{blogId}/comments/{commentId}/replies`).
  Future<ApiResponse<Map<String, dynamic>>> addBlogCommentReply({
    required String blogId,
    required String commentId,
    required String body,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/blogs/$blogId/comments/$commentId/replies',
          method: networkUtils.HttpMethod.POST,
          body: {'body': body, 'comment_text': body},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to post blog reply: $e');
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

  /// Completed surveys for the signed-in user's profile (`GET /api/profile/tab?tab=surveys`).
  Future<ApiResponse<List<ProfileCompletedSurvey>>> getProfileCompletedSurveys() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/profile/tab?tab=surveys',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      if (response is Map && response['success'] == false) {
        return ApiResponse.error(
          response['message']?.toString() ?? 'Failed to load profile surveys',
        );
      }
      final raw = response['surveys'];
      final surveys = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => ProfileCompletedSurvey.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : <ProfileCompletedSurvey>[];
      return ApiResponse.success(surveys);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to load profile surveys: $e');
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

  /// Vote on a poll option or add a new option via [optionText].
  Future<ApiResponse<Map<String, dynamic>>> votePoll({
    required String pollId,
    String? optionId,
    String? optionText,
  }) async {
    try {
      final params = <String, String>{'poll_id': pollId};
      if (optionText != null && optionText.trim().isNotEmpty) {
        params['option_text'] = optionText.trim();
      } else if (optionId != null) {
        params['option_id'] = optionId;
      }
      final query = params.entries
          .map((e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/poll-vote?$query',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to vote: $e');
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
    int page = 1,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/get-post-comments?post_id=${Uri.encodeComponent(postId)}&page=$page',
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
          '/post-comment?post_id=${Uri.encodeComponent(postId)}&comment=${Uri.encodeComponent(comment)}',
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

  /// Toggle like on a comment or reply (post, blog, or unified feed comment).
  Future<ApiResponse<Map<String, dynamic>>> toggleCommentLike({
    required String commentId,
    String? targetType,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseV6(
          '/comments/$commentId/like',
          method: networkUtils.HttpMethod.POST,
          request: targetType != null && targetType.isNotEmpty
              ? {'target_type': targetType}
              : null,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response as Map));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update comment like: $e');
    }
  }

  /// Legacy alias — some callers still post to /like-comment.
  Future<ApiResponse<Map<String, dynamic>>> likeCommentLegacy({
    required String commentId,
    String? targetType,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/like-comment',
          method: networkUtils.HttpMethod.POST,
          request: {
            'comment_id': commentId,
            if (targetType != null && targetType.isNotEmpty) 'target_type': targetType,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response as Map));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update comment like: $e');
    }
  }

  // ================================== CHATGPT / MEDICAL IMAGE ANALYSIS (API v6) ==================================
  // All AI endpoints now use v6 to include citation sources per Apple Guideline 1.4.1

  /// Maps display image-type labels to v6 analysis_type slugs
  static String _toAnalysisType(String imageType) {
    switch (imageType.toLowerCase().trim()) {
      case 'x-ray':
      case 'xray':
        return 'xray';
      case 'ct scan':
      case 'ctscan':
        return 'ctscan';
      case 'mri':
      case 'mri scan':
        return 'mri';
      case 'mammography':
      case 'mammogram':
        return 'mammogram';
      case 'dermatological':
      case 'dermatology':
        return 'dermatology';
      default:
        return 'general';
    }
  }

  /// Analyze a medical image using v6 endpoint.
  /// Returns response with `sources` citations (Apple Guideline 1.4.1).
  Future<ApiResponse<ChatGptAskQuestionResponse>> askQuestionWithImages({
    required String sessionId,
    required String question,
    required String imageType,
    String? imageUrl1,
    String? imageUrl2,
  }) async {
    try {
      // v6 endpoint for medical image analysis
      final Uri url = Uri.parse('${AppData.remoteUrlV6}/medical-image-analysis/analyze');

      var request = http.MultipartRequest('POST', url);

      if (AppData.userToken != null) {
        request.headers['Authorization'] = 'Bearer ${AppData.userToken}';
      }
      // Tell Laravel to return JSON errors (not HTML 404 pages)
      request.headers['Accept'] = 'application/json';

      // v6 field names: session_id, message, file, analysis_type
      request.fields['session_id']    = sessionId;
      request.fields['message']       = question;
      request.fields['analysis_type'] = _toAnalysisType(imageType);

      String getMimeType(String filePath) {
        final name = filePath.split('/').last.toLowerCase();
        if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
        if (name.endsWith('.png')) return 'image/png';
        if (name.endsWith('.gif')) return 'image/gif';
        if (name.endsWith('.webp')) return 'image/webp';
        // iPhone camera roll often yields HEIC — label correctly so Gemini can decode it.
        if (name.endsWith('.heic')) return 'image/heic';
        if (name.endsWith('.heif')) return 'image/heif';
        return 'image/jpeg';
      }

      // v6 accepts a single `file` field
      if (imageUrl1 != null && imageUrl1.isNotEmpty) {
        final file1 = File(imageUrl1);
        if (await file1.exists()) {
          final mimeType = getMimeType(imageUrl1);
          request.files.add(http.MultipartFile(
            'file',
            http.ByteStream(file1.openRead()),
            await file1.length(),
            filename: imageUrl1.split('/').last,
            contentType: MediaType.parse(mimeType),
          ));
          debugPrint('📎 Medical image v6: added file');
        }
      }

      debugPrint('🚀 Medical image v6 analyze → $url');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw ApiException(message: 'Request timed out', statusCode: 408),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 v6 analyze status: ${response.statusCode}');
      debugPrint('📥 v6 analyze body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(ChatGptAskQuestionResponse.fromJson(jsonDecode(response.body)));
      } else {
        String errorMessage = 'Failed to analyze image';
        try {
          final errorJson = jsonDecode(response.body);
          errorMessage = errorJson['message'] ?? errorJson['error']?['message'] ?? errorMessage;
        } catch (_) {}
        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
      }
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      debugPrint('❌ Error in askQuestionWithImages (v6): $e');
      return ApiResponse.error('Failed to analyze image: $e');
    }
  }

  /// Continue a text-only conversation in the medical image session (v6)
  Future<ApiResponse<ChatGptAskQuestionResponse>> askQuestionWithoutImages({
    required String sessionId,
    required String question,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseV6(
          '/medical-image-analysis/chat',
          method: networkUtils.HttpMethod.POST,
          request: {'session_id': sessionId, 'message': question},
        ),
      );
      return ApiResponse.success(ChatGptAskQuestionResponse.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to continue chat: $e');
    }
  }

  /// Get medical image analysis sessions (v6)
  Future<ApiResponse<ChatGptSession>> getChatGptSessions() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseV6(
          '/medical-image-analysis/sessions',
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

  /// Get messages for a medical image analysis session (v6)
  Future<ApiResponse<ChatGptMessageHistory>> getChatGptMessages({
    required String sessionId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseV6(
          '/medical-image-analysis/sessions/$sessionId/messages',
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

  /// Create a new medical image analysis session (v6)
  Future<ApiResponse<Map<String, dynamic>>> createNewChatSession() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseV6(
          '/medical-image-analysis/sessions',
          method: networkUtils.HttpMethod.POST,
          request: {},
        ),
      );
      // Map v6 create-session response to legacy format expected by BLoC
      final Map<String, dynamic> result = Map<String, dynamic>.from(response);
      if (result.containsKey('session')) {
        final session = result['session'] as Map<String, dynamic>;
        result['newSessionId'] = session['id'];
        result['session_id']   = session['id'];
      }
      return ApiResponse.success(result);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to create session: $e');
    }
  }

  /// Delete a medical image analysis session (v6)
  Future<ApiResponse<Map<String, dynamic>>> deleteChatGptSession({
    required String sessionId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseV6(
          '/medical-image-analysis/sessions/$sessionId',
          method: networkUtils.HttpMethod.DELETE,
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
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/jobs?page=$page&country_id=$countryId&searchTerm=$searchTerm&expired_job=$expiredJob',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(JobsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get jobs: $e');
    }
  }

  /// Get job details
  Future<ApiResponse<JobDetailModel>> getJobDetails({
    required String jobId,
  }) async {
    try {
      // Try V6 first, fall back to V4 if route not found
      dynamic response;
      try {
        response = await networkUtils.handleResponse(
          await networkUtils.buildHttpResponseV6(
            '/job_detail',
            method: networkUtils.HttpMethod.POST,
            request: {'job_id': jobId},
          ),
        );
      } catch (e) {
        // If V6 fails (e.g. 404 route not deployed), fall back to V4
        print('📋 [JobDetails] V6 failed: $e, trying V4 fallback');
        response = await networkUtils.handleResponse(
          await networkUtils.buildHttpResponse(
            '/job_detail',
            method: networkUtils.HttpMethod.POST,
            request: {'job_id': jobId},
          ),
        );
      }

      // If the server returned a structured error (success: false) or an explicit message,
      // convert that into an ApiResponse.error so UI can display a friendly message.
      try {
        if (response is Map) {
          // Server returned a success flag but with failure
          if (response.containsKey('success') && response['success'] == false) {
            final serverMsg =
                (response['message'] ?? response['error'])?.toString() ??
                'Job not found';
            return ApiResponse.error(serverMsg);
          }

          // Server returned without a job payload - treat as 'removed/not found'
          if (response.containsKey('job') && response['job'] == null) {
            final serverMsg =
                (response['message'] ?? response['error'])?.toString() ??
                'This job is no longer available';
            return ApiResponse.error(serverMsg);
          }
        }
      } catch (_) {
        // ignore parsing issues and continue with model mapping
      }

      return ApiResponse.success(JobDetailModel.fromJson(response));
    } on ApiException catch (e) {
      // Try to extract a useful server message from the API error response
      String serverMessage = e.message;
      try {
        if (e.response != null) {
          if (e.response is Map) {
            final Map resp = e.response as Map;
            if (resp.containsKey('message') && resp['message'] != null) {
              serverMessage = resp['message'].toString();
            } else if (resp.containsKey('error') && resp['error'] != null) {
              serverMessage = resp['error'].toString();
            }
          } else if (e.response is String) {
            serverMessage = e.response as String;
          }
        }
      } catch (_) {
        // ignore parsing errors and fallback to ApiException message
      }

      return ApiResponse.error(serverMessage, statusCode: e.statusCode);
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

  /// Get notifications (Node API with Laravel fallback)
  Future<ApiResponse<NotificationModel>> getNotifications({
    required String page,
    String? filter,
  }) async {
    final filterQuery =
        filter != null && filter.isNotEmpty ? '&filter=$filter' : '';

    NotificationModel? nodeModel;
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/notifications?page=$page$filterQuery',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      nodeModel = NotificationModel.fromJson(response);
      // Trust the Node API whenever the request succeeds — do not fall through
      // to Laravel when the list is empty but unread_count is non-zero.
      return ApiResponse.success(nodeModel);
    } on ApiException catch (e) {
      if (e.statusCode != null && e.statusCode! >= 500) {
        // fall through to Laravel
      } else if (e.statusCode == 401) {
        return ApiResponse.error(e.message, statusCode: e.statusCode);
      }
    } catch (_) {
      // fall through to Laravel fallback
    }

    try {
      final legacyPath = filter == 'unread'
          ? '/notifications/unread?page=$page'
          : '/notifications?page=$page';
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          legacyPath,
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(NotificationModel.fromJson(response));
    } on ApiException catch (e) {
      if (nodeModel != null) {
        return ApiResponse.success(nodeModel);
      }
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      if (nodeModel != null) {
        return ApiResponse.success(nodeModel);
      }
      return ApiResponse.error('Failed to get notifications: $e');
    }
  }

  /// Mark all notifications as read
  Future<ApiResponse<Map<String, dynamic>>> markAllNotificationsAsRead() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/notifications/mark-read',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to mark all notifications as read: $e');
    }
  }

  /// Mark notification as read
  Future<ApiResponse<Map<String, dynamic>>> markNotificationAsRead({
    required String notificationId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/v1/notifications/$notificationId/mark-read',
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
  Future<ApiResponse<UserProfile>> getProfile({required String userId}) async {
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
      // Build a sanitized request map: trim strings, ensure values are strings,
      // and omit invalid/empty optional fields (notably 'dob' when not a valid date).
      final Map<String, dynamic> requestMap = {};

      void put(String key, String? value) {
        if (value == null) return;
        final v = value.trim();
        // include empty strings for fields that should be set to empty string explicitly
        requestMap[key] = v;
      }

      // Required / common fields
      put('first_name', firstName);
      put('last_name', lastName);

      // Phone and license should be string values (send empty string if blank)
      requestMap['phone'] = phone.trim();
      requestMap['license_no'] = licenseNo.trim();

      put('specialty', specialty);

      // dob: only include if it parses as a valid date. Format as YYYY-MM-DD.
      final dobTrim = dob.trim();
      if (dobTrim.isNotEmpty) {
        DateTime? parsed;
        try {
          parsed = DateTime.tryParse(dobTrim);
        } catch (_) {
          parsed = null;
        }
        if (parsed != null) {
          requestMap['dob'] = parsed.toIso8601String().split('T').first;
        }
      }

      put('gender', gender);
      put('country', country);
      put('city', city);
      put('state', city);
      put('country_origin', countryOrigin);

      // Privacy fields (include even if blank)
      requestMap['dob_privacy'] = dobPrivacy.trim();
      requestMap['email_privacy'] = emailPrivacy.trim();
      requestMap['gender_privacy'] = genderPrivacy.trim();
      requestMap['phone_privacy'] = phonePrivacy.trim();
      requestMap['license_no_privacy'] = licenseNoPrivacy.trim();
      requestMap['specialty_privacy'] = specialtyPrivacy.trim();
      requestMap['country_privacy'] = countryPrivacy.trim();
      requestMap['city_privacy'] = cityPrivacy.trim();
      requestMap['country_origin_privacy'] = countryOriginPrivacy.trim();

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/profile/update',
          method: networkUtils.HttpMethod.POST,
          request: requestMap,
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
      final interests = interestsData
          .map((json) => InterestModel.fromJson(json))
          .toList();
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
      final workEducation = workEducationData
          .map((json) => WorkEducationModel.fromJson(json))
          .toList();
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
  Future<ApiResponse<ContactsModel>> getContacts({required String page}) async {
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
      await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/country-list',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      print('🔗 API connectivity test successful');
      return ApiResponse.success({
        'status': 'connected',
        'message': 'API is reachable',
      });
    } catch (e) {
      print('🔗 API connectivity test failed: $e');
      return ApiResponse.error('API connectivity failed: $e');
    }
  }

  // ================================== SEARCH ENDPOINTS ==================================

  Future<ApiResponse<Map<String, dynamic>>> getConferenceDetail({
    required String id,
  }) async {
    return _searchService.getConferenceDetail(id: id);
  }

  /// Search conferences
  Future<ApiResponse<SearchConferenceModel>> searchConferences({
    required String page,
    String? keyword,
    String? country,
    String? month,
  }) async {
    return await _searchService.searchConferences(
      page: page,
      keyword: keyword,
      country: country,
      month: month,
    );
  }

  /// Search guidelines
  Future<ApiResponse<GuidelinesModel>> searchGuidelines({
    required String page,
    required String keyword,
  }) async {
    return await _searchService.searchGuides(page: page, keyword: keyword);
  }
}
