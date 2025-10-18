import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/ads_model/ads_setting_model.dart';
import 'package:doctak_app/data/models/ads_model/ads_type_model.dart';
import 'package:doctak_app/data/models/news_model/news_model.dart';
import 'package:doctak_app/data/models/post_comment_model/post_comment_model.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
import 'package:doctak_app/data/models/post_model/post_detail_model.dart';
import 'package:doctak_app/data/models/post_model/post_details_data_model.dart';
import 'package:doctak_app/data/models/post_model/post_likes_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Post API Service
/// Handles all posts, comments, and likes related API calls
class PostApiService {
  static final PostApiService _instance = PostApiService._internal();
  factory PostApiService() => _instance;
  PostApiService._internal();

  /// Get posts feed with pagination
  Future<ApiResponse<PostDataModel>> getPosts({required String page}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/posts?page=$page',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(PostDataModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get posts: $e');
    }
  }

  /// Get post details by ID with comments
  Future<ApiResponse<PostDetailsDataModel>> getPostDetails({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
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

  /// Get post details with likes information
  Future<ApiResponse<PostDetailModel>> getPostDetailsWithLikes({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
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

  /// Get user's posts (profile posts)
  Future<ApiResponse<PostDataModel>> getUserPosts({
    required String page,
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
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

  /// Create a new post with media
  Future<ApiResponse<Map<String, dynamic>>> createPost({
    required String title,
    required String name,
    String? locationName,
    String? lat,
    String? lng,
    String? backgroundColor,
    List<String>? imagePaths,
    List<String>? videoPaths,
    String? tagging,
    String? feelings,
  }) async {
    try {
      final request = <String, dynamic>{'title': title, 'name': name};

      if (locationName != null) request['location_name'] = locationName;
      if (lat != null) request['lat'] = lat;
      if (lng != null) request['lng'] = lng;
      if (backgroundColor != null)
        request['background_color'] = backgroundColor;
      if (tagging != null) request['tagging'] = tagging;
      if (feelings != null) request['feelings'] = feelings;

      // Note: File uploads need special handling in network_utils
      // This would need to be enhanced for actual file upload

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/new_post',
          method: networkUtils.HttpMethod.POST,
          request: request,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to create post: $e');
    }
  }

  /// Like or unlike a post
  Future<ApiResponse<Map<String, dynamic>>> likePost({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
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

  /// Get users who liked a post
  Future<ApiResponse<List<PostLikesModel>>> getPostLikes({
    required String postId,
  }) async {
    try {
      // The server expects GET for this route (405 returned for POST).
      // Send postId as query parameter.
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/getPostLikes?postId=$postId',
          method: networkUtils.HttpMethod.GET,
        ),
      );

      // Handle response - API may return List directly or wrapped in a Map with 'data' key
      List<dynamic> likesData;
      if (response is List) {
        likesData = response;
      } else if (response is Map) {
        // Handle wrapped response like {"data": [...]} or {"likes": [...]}
        likesData = response['data'] ?? response['likes'] ?? [];
      } else {
        likesData = [];
      }

      final likes = likesData
          .map((json) => PostLikesModel.fromJson(json))
          .toList();
      return ApiResponse.success(likes);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get post likes: $e');
    }
  }

  /// Delete a post
  Future<ApiResponse<Map<String, dynamic>>> deletePost({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
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

  /// Search posts by keyword
  Future<ApiResponse<PostDataModel>> searchPosts({
    required String page,
    required String keyword,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/search-post?page=$page&search=$keyword',
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

  /// Get advertisement settings
  Future<ApiResponse<AdsSettingModel>> getAdvertisementSettings() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/advertisement-setting',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(AdsSettingModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get advertisement settings: $e');
    }
  }

  /// Get advertisement types
  Future<ApiResponse<List<AdsTypeModel>>> getAdvertisementTypes() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/advertisement-types',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final List<dynamic> adsData = response is List
          ? response
          : response['data'] ?? [];
      final adTypes = adsData
          .map((json) => AdsTypeModel.fromJson(json))
          .toList();
      return ApiResponse.success(adTypes);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get advertisement types: $e');
    }
  }

  /// Make comment (backward compatibility)
  Future<ApiResponse<Map<String, dynamic>>> makeComment({
    required String postId,
    required String comment,
    String? replyId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/comment',
          method: networkUtils.HttpMethod.POST,
          request: {
            'post_id': postId,
            'comment': comment,
            if (replyId != null) 'reply_id': replyId,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to make comment: $e');
    }
  }

  /// Delete comment (backward compatibility)
  Future<ApiResponse<Map<String, dynamic>>> deleteComments({
    required String commentId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/delete-comment?comment_id=$commentId',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to delete comment: $e');
    }
  }

  /// Get my posts (backward compatibility)
  Future<ApiResponse<PostDataModel>> getMyPosts({
    required String page,
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/get_my_posts?page=$page&user_id=$userId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(PostDataModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get my posts: $e');
    }
  }

  /// Save suggestion (backward compatibility)
  Future<ApiResponse<Map<String, dynamic>>> saveSuggestion({
    required String name,
    required String email,
    required String suggestion,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/save-suggestion',
          method: networkUtils.HttpMethod.POST,
          request: {'name': name, 'email': email, 'suggestion': suggestion},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to save suggestion: $e');
    }
  }

  /// Get news channel (backward compatibility)
  Future<ApiResponse<List<NewsModel>>> getNewsChannel({
    required String channel,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/news/$channel',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final List<dynamic> newsData = response is List
          ? response
          : response['data'] ?? [];
      final news = newsData.map((json) => NewsModel.fromJson(json)).toList();
      return ApiResponse.success(news);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get news channel: $e');
    }
  }

  // ================================== COMMENTS ==================================

  /// Get comments for a post
  Future<ApiResponse<PostCommentModel>> getPostComments({
    required String postId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
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

  /// Add a comment to a post
  Future<ApiResponse<Map<String, dynamic>>> addComment({
    required String postId,
    required String comment,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
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

  /// Delete a comment
  Future<ApiResponse<Map<String, dynamic>>> deleteComment({
    required String commentId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
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
}
