import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/drugs_model/drugs_model.dart';
import 'package:doctak_app/data/models/search_people_model/search_people_model.dart';
import 'package:doctak_app/data/models/guidelines_model/guidelines_model.dart';
import 'package:doctak_app/data/models/case_model/case_discuss_model.dart';
import 'package:doctak_app/data/models/conference_model/search_conference_model.dart';
import 'package:doctak_app/data/models/check_in_search_model/check_in_search_model.dart';
import 'package:doctak_app/data/models/post_model/post_data_model.dart';
// Note: some search models don't exist, using Map for those search results
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Search API Service
/// Handles all search-related API calls
class SearchApiService {
  static final SearchApiService _instance = SearchApiService._internal();
  factory SearchApiService() => _instance;
  SearchApiService._internal();

  /// Global search across all content types
  Future<ApiResponse<Map<String, dynamic>>> globalSearch({
    required String page,
    required String keyword,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search?page=$page&keyword=$keyword',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to perform global search: $e');
    }
  }

  /// Search users by name or specialty
  Future<ApiResponse<SearchPeopleModel>> searchUsers({
    required String page,
    required String keyword,
    String? specialty,
    String? location,
  }) async {
    try {
      String queryParams = 'page=$page&searchTerm=$keyword';
      if (specialty != null && specialty.isNotEmpty) {
        queryParams += '&specialty=$specialty';
      }
      if (location != null && location.isNotEmpty) {
        queryParams += '&location=$location';
      }

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/searchPeople?$queryParams',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(SearchPeopleModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search users: $e');
    }
  }

  /// Search posts by content
  Future<ApiResponse<PostDataModel>> searchPosts({
    required String page,
    required String keyword,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/posts?page=$page&keyword=$keyword',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(PostDataModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search posts: $e');
    }
  }

  /// Search drugs/medications
  Future<ApiResponse<DrugsModel>> searchDrugs({
    required String page,
    required String keyword,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/drugs?page=$page&keyword=$keyword',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(DrugsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search drugs: $e');
    }
  }

  /// Search medical guidelines
  Future<ApiResponse<GuidelinesModel>> searchGuidelines({
    required String page,
    required String keyword,
    String? category,
  }) async {
    try {
      String queryParams = 'page=$page&keyword=$keyword';
      if (category != null && category.isNotEmpty) {
        queryParams += '&category=$category';
      }

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/guidelines?$queryParams',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(GuidelinesModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search guidelines: $e');
    }
  }

  /// Search case discussions
  Future<ApiResponse<CaseDiscussModel>> searchCases({
    required String page,
    required String keyword,
    String? specialty,
    String? difficulty,
  }) async {
    try {
      String queryParams = 'page=$page&keyword=$keyword';
      if (specialty != null && specialty.isNotEmpty) {
        queryParams += '&specialty=$specialty';
      }
      if (difficulty != null && difficulty.isNotEmpty) {
        queryParams += '&difficulty=$difficulty';
      }

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/cases?$queryParams',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(CaseDiscussModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search cases: $e');
    }
  }

  /// Advanced search with multiple filters
  Future<ApiResponse<Map<String, dynamic>>> advancedSearch({
    required String page,
    required String keyword,
    List<String>? contentTypes, // ["users", "posts", "groups", "jobs"]
    String? dateRange,
    String? sortBy,
    String? location,
    String? specialty,
  }) async {
    try {
      final request = {
        'keyword': keyword,
        'page': page,
      };
      
      if (contentTypes != null && contentTypes.isNotEmpty) {
        request['content_types'] = contentTypes.join(',');
      }
      if (dateRange != null) request['date_range'] = dateRange;
      if (sortBy != null) request['sort_by'] = sortBy;
      if (location != null) request['location'] = location;
      if (specialty != null) request['specialty'] = specialty;

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/advanced',
          method: networkUtils.HttpMethod.POST,
          request: request,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to perform advanced search: $e');
    }
  }

  /// Get search suggestions/autocomplete
  Future<ApiResponse<List<String>>> getSearchSuggestions({
    required String query,
    String? type, // "users", "posts", "drugs", etc.
  }) async {
    try {
      String queryParams = 'query=$query';
      if (type != null && type.isNotEmpty) {
        queryParams += '&type=$type';
      }

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/suggestions?$queryParams',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final List<dynamic> suggestionsData = response as List<dynamic>;
      final suggestions = suggestionsData.map((item) => item.toString()).toList();
      return ApiResponse.success(suggestions);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get search suggestions: $e');
    }
  }

  /// Get popular/trending search terms
  Future<ApiResponse<List<String>>> getTrendingSearches() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/trending',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final List<dynamic> trendingData = response as List<dynamic>;
      final trending = trendingData.map((item) => item.toString()).toList();
      return ApiResponse.success(trending);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get trending searches: $e');
    }
  }

  /// Get user's search history
  Future<ApiResponse<List<Map<String, dynamic>>>> getSearchHistory() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/history',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      final List<dynamic> historyData = response as List<dynamic>;
      final history = historyData.map((item) => Map<String, dynamic>.from(item)).toList();
      return ApiResponse.success(history);
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get search history: $e');
    }
  }

  /// Clear search history
  Future<ApiResponse<Map<String, dynamic>>> clearSearchHistory() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/history/clear',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to clear search history: $e');
    }
  }

  /// Save search query to history
  Future<ApiResponse<Map<String, dynamic>>> saveSearchQuery({
    required String query,
    String? category,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/history/save',
          method: networkUtils.HttpMethod.POST,
          request: {
            'query': query,
            if (category != null) 'category': category,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to save search query: $e');
    }
  }

  /// Search within specific group
  Future<ApiResponse<Map<String, dynamic>>> searchInGroup({
    required String groupId,
    required String page,
    required String keyword,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/group/$groupId?page=$page&keyword=$keyword',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search in group: $e');
    }
  }

  /// Search medical conditions/diseases
  Future<ApiResponse<Map<String, dynamic>>> searchConditions({
    required String page,
    required String keyword,
    String? category,
  }) async {
    try {
      String queryParams = 'page=$page&keyword=$keyword';
      if (category != null && category.isNotEmpty) {
        queryParams += '&category=$category';
      }

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/conditions?$queryParams',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search conditions: $e');
    }
  }

  /// Search medical procedures/treatments
  Future<ApiResponse<Map<String, dynamic>>> searchProcedures({
    required String page,
    required String keyword,
    String? specialty,
  }) async {
    try {
      String queryParams = 'page=$page&keyword=$keyword';
      if (specialty != null && specialty.isNotEmpty) {
        queryParams += '&specialty=$specialty';
      }

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/procedures?$queryParams',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search procedures: $e');
    }
  }

  /// Filter search results
  Future<ApiResponse<Map<String, dynamic>>> filterSearchResults({
    required String query,
    required String page,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final request = {
        'query': query,
        'page': page,
        if (filters != null) ...filters,
      };

      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/filter',
          method: networkUtils.HttpMethod.POST,
          request: request,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to filter search results: $e');
    }
  }

  // ================================== ADDITIONAL SEARCH METHODS ==================================

  /// Search conferences (backward compatibility)
  Future<ApiResponse<SearchConferenceModel>> searchConferences({
    required String page,
    required String keyword,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search-conferences?page=$page&keyword=$keyword',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(SearchConferenceModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search conferences: $e');
    }
  }

  /// Search guidelines (backward compatibility)
  Future<ApiResponse<GuidelinesModel>> searchGuides({
    required String page,
    required String keyword,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/guideline?page=$page&search_term=$keyword',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(GuidelinesModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search guidelines: $e');
    }
  }

  /// Search places for check-in (backward compatibility)
  Future<ApiResponse<CheckInSearchModel>> searchPlaces({
    required String page,
    required String query,
    required String latitude,
    required String longitude,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/check_in_search?page=$page&name=$query&latitude=$latitude&longitude=$longitude',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(CheckInSearchModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search places: $e');
    }
  }
}