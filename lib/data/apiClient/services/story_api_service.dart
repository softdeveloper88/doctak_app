import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/story_model/story_model.dart';
import 'package:http/http.dart' as http;

/// API service for Stories/Status feature
/// Uses v5 API endpoints
class StoryApiService {
  static final StoryApiService _instance = StoryApiService._internal();
  factory StoryApiService() => _instance;
  StoryApiService._internal();

  /// v5 base URL
  static String get _baseUrl =>
      AppData.remoteUrl2.replaceAll('/v4', '/v5');

  /// Build headers with Bearer token
  Map<String, String> _headers() {
    return {
      'Authorization': 'Bearer ${AppData.userToken}',
      'Accept': 'application/json',
    };
  }

  // ═══════════════════════════════════════════════
  // GET /stories — Feed of active stories from connected users
  // ═══════════════════════════════════════════════
  Future<StoryFeedResponse> getStoryFeed() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/stories'), headers: _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return StoryFeedResponse.fromJson(json);
      } else {
        throw Exception('Failed to load stories: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 StoryApiService.getStoryFeed error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════
  // POST /stories — Create a new story
  // ═══════════════════════════════════════════════
  Future<Map<String, dynamic>> createStory({
    required String type,
    File? mediaFile,
    String? content,
    String? backgroundColor,
    int? duration,
    String? privacy,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/stories');
      final request = http.MultipartRequest('POST', uri);

      // Auth header
      request.headers['Authorization'] = 'Bearer ${AppData.userToken}';
      request.headers['Accept'] = 'application/json';

      // Fields
      request.fields['type'] = type;
      if (content != null) request.fields['content'] = content;
      if (backgroundColor != null) {
        request.fields['background_color'] = backgroundColor;
      }
      if (duration != null) request.fields['duration'] = duration.toString();
      if (privacy != null) request.fields['privacy'] = privacy;

      // Media file
      if (mediaFile != null && (type == 'image' || type == 'video')) {
        request.files.add(
          await http.MultipartFile.fromPath('media', mediaFile.path),
        );
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      print('🌐 createStory response: ${response.statusCode} ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Extract best error message from server response
        String errorMsg = 'Failed to create story (${response.statusCode})';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map<String, dynamic>) {
            errorMsg = errorBody['message']?.toString() ??
                errorBody['errors']?.toString() ??
                errorMsg;
          }
        } catch (_) {
          // Response is not JSON (e.g. HTML error page)
          errorMsg = 'Server error ${response.statusCode}';
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('🔴 StoryApiService.createStory error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════
  // GET /stories/user/{userId} — Get a specific user's stories
  // ═══════════════════════════════════════════════
  Future<List<StoryItemModel>> getUserStories(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/stories/user/$userId'),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final storiesList = json['stories'] as List<dynamic>? ?? [];
        return storiesList
            .map((s) => StoryItemModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
            'Failed to load user stories: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 StoryApiService.getUserStories error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════
  // POST /stories/{storyId}/view — Mark story as viewed
  // ═══════════════════════════════════════════════
  Future<void> markStoryViewed(int storyId) async {
    try {
      await http
          .post(
            Uri.parse('$_baseUrl/stories/$storyId/view'),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print('🔴 StoryApiService.markStoryViewed error: $e');
      // Don't rethrow — view tracking failure shouldn't break UX
    }
  }

  // ═══════════════════════════════════════════════
  // GET /stories/{storyId}/viewers — Get story viewers (own only)
  // ═══════════════════════════════════════════════
  Future<List<StoryViewerModel>> getStoryViewers(int storyId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/stories/$storyId/viewers'),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final viewers = json['viewers'] as List<dynamic>? ?? [];
        return viewers
            .map((v) => StoryViewerModel.fromJson(v as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load viewers: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 StoryApiService.getStoryViewers error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════
  // DELETE /stories/{storyId} — Delete own story
  // ═══════════════════════════════════════════════
  Future<bool> deleteStory(int storyId) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/stories/$storyId'),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to delete story: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 StoryApiService.deleteStory error: $e');
      rethrow;
    }
  }
}
