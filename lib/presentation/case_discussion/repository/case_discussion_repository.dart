// ============================================================================
// Case Discussion Repository - v6 API
// Clean Dio-based repository for all case discussion API interactions.
// ============================================================================

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import '../models/case_discussion_models.dart';

class CaseDiscussionRepository {
  final Dio _dio;
  final String baseUrl;
  final String Function() getAuthToken;

  // Cache for filter data (5 min TTL)
  List<SpecialtyFilter>? _cachedSpecialties;
  List<CountryFilter>? _cachedCountries;
  DateTime? _filterCacheTime;

  CaseDiscussionRepository({
    required this.baseUrl,
    required this.getAuthToken,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['Authorization'] = 'Bearer ${getAuthToken()}';
        options.headers['Accept'] = 'application/json';
        if (options.headers['Content-Type'] == null) {
          options.headers['Content-Type'] = 'application/json';
        }
        debugPrint('API ${options.method} ${options.uri}');
        handler.next(options);
      },
      onError: (error, handler) async {
        debugPrint('API Error: ${error.response?.statusCode} ${error.message}');
        // Retry on 429 Too Many Requests with exponential backoff
        if (error.response?.statusCode == 429) {
          final retryCount = (error.requestOptions.extra['retryCount'] ?? 0) as int;
          if (retryCount < 3) {
            final delay = Duration(milliseconds: 1000 * (retryCount + 1));
            await Future.delayed(delay);
            error.requestOptions.extra['retryCount'] = retryCount + 1;
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER DATA
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getFilterData() async {
    // Check cache
    if (_cachedSpecialties != null &&
        _cachedCountries != null &&
        _filterCacheTime != null &&
        DateTime.now().difference(_filterCacheTime!).inMinutes < 5) {
      return {
        'specialties': _cachedSpecialties!,
        'countries': _cachedCountries!,
      };
    }

    List<SpecialtyFilter> specialties = [];
    List<CountryFilter> countries = [];

    try {
      final response = await _dio.get('$baseUrl/api/v1/specialty');
      final data = response.data;
      List items = [];
      if (data is List) {
        items = data;
      } else if (data is Map && data['data'] is List) {
        items = data['data'];
      }
      specialties = items
          .map((item) => SpecialtyFilter.fromJson({
                'id': item['id'] ?? 0,
                'name': item['name'] ?? item['specialty_name'] ?? 'Unknown',
              }))
          .toList();
    } catch (e) {
      debugPrint('Error fetching specialties: $e');
    }

    try {
      final response = await _dio.get('$baseUrl/api/v1/country-list');
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['countries'] is List) {
          countries = (data['countries'] as List)
              .map((item) => CountryFilter.fromJson({
                    'id': item['id'] ?? 0,
                    'name': item['countryName'] ?? item['name'] ?? '',
                    'code': item['countryCode'] ?? item['code'] ?? '',
                    'flag': item['flag'] ?? '',
                  }))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching countries: $e');
    }

    _cachedSpecialties = specialties;
    _cachedCountries = countries;
    _filterCacheTime = DateTime.now();

    return {'specialties': specialties, 'countries': countries};
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CASE LIST
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<CaseDiscussionListItem>> getCaseDiscussions({
    int page = 1,
    int perPage = 12,
    CaseDiscussionFilters? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (filters != null) {
        queryParams.addAll(filters.toQueryParameters());
      }

      final response = await _dio.get(
        '$baseUrl/api/v6/cases',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        final casesData = data['cases'] as Map<String, dynamic>;
        final casesList = casesData['data'] as List;

        final cases = casesList
            .map((item) => CaseDiscussionListItem.fromJson(item))
            .toList();

        final pagination = PaginationMeta(
          currentPage: casesData['current_page'] ?? 1,
          lastPage: casesData['last_page'] ?? 1,
          perPage:
              int.tryParse(casesData['per_page']?.toString() ?? '12') ?? 12,
          total: casesData['total'] ?? 0,
        );

        return PaginatedResponse<CaseDiscussionListItem>(
          items: cases,
          pagination: pagination,
        );
      } else {
        throw Exception(
            responseData['message'] ?? 'Failed to load case discussions');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load discussions: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CASE DETAIL
  // ═══════════════════════════════════════════════════════════════════════════

  Future<CaseDiscussion> getCaseDiscussion(int caseId) async {
    try {
      final response = await _dio.get('$baseUrl/api/v6/cases/$caseId');

      if (response.data == null || response.data is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        return CaseDiscussion.fromJson(data);
      } else {
        throw Exception(
            responseData['message'] ?? 'Failed to load case discussion');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load case discussion: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATE / UPDATE / DELETE CASE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<CaseDiscussion> createCaseDiscussion(CreateCaseRequest request) async {
    try {
      final formData = _buildCaseFormData(request);
      await attachFiles(formData, request);

      final response = await _dio.post(
        '$baseUrl/api/v6/cases',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      return _parseCaseResponse(response, 'create');
    } on DioException catch (e) {
      throw _handleCaseMutationError(e);
    } catch (e) {
      throw Exception('Failed to create case: $e');
    }
  }

  Future<CaseDiscussion> updateCaseDiscussion(
      int caseId, CreateCaseRequest request) async {
    try {
      final formData = _buildCaseFormData(request);
      await attachFiles(formData, request);

      final response = await _dio.post(
        '$baseUrl/api/v6/cases/$caseId',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      return _parseCaseResponse(response, 'update');
    } on DioException catch (e) {
      throw _handleCaseMutationError(e);
    } catch (e) {
      throw Exception('Failed to update case: $e');
    }
  }

  Future<void> deleteCase(int caseId) async {
    try {
      await _dio.delete('$baseUrl/api/v6/cases/$caseId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<CaseComment>> getCaseComments({
    required int caseId,
    int page = 1,
    int perPage = 15,
    String? sortBy, // likes, date
    bool? verified,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };
      if (sortBy != null) queryParams['sort'] = sortBy;
      if (verified != null) queryParams['verified'] = verified ? '1' : '0';

      final response = await _dio.get(
        '$baseUrl/api/v6/cases/$caseId/comments',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        final commentsData = data['comments'] as Map<String, dynamic>;
        final commentsList = commentsData['data'] as List;

        final comments =
            commentsList.map((item) => CaseComment.fromJson(item)).toList();

        final pagination = PaginationMeta(
          currentPage: commentsData['current_page'] ?? 1,
          lastPage: commentsData['last_page'] ?? 1,
          perPage: int.tryParse(
                  commentsData['per_page']?.toString() ?? '15') ??
              15,
          total: commentsData['total'] ?? 0,
        );

        return PaginatedResponse<CaseComment>(
          items: comments,
          pagination: pagination,
        );
      } else {
        throw Exception(
            responseData['message'] ?? 'Failed to load comments');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      // Log the error for debugging instead of silently swallowing
      debugPrint('⚠️ getCaseComments error: $e');
      debugPrint('⚠️ Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      return PaginatedResponse<CaseComment>(
        items: [],
        pagination: PaginationMeta(
            currentPage: 1, lastPage: 1, perPage: perPage, total: 0),
      );
    }
  }

  Future<CaseComment> addComment({
    required int caseId,
    required String comment,
    String? clinicalTags,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/v6/cases/comments',
        data: {
          'case_id': caseId,
          'comment': comment,
          if (clinicalTags != null && clinicalTags.isNotEmpty)
            'clinical_tags': clinicalTags,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        final data = responseData['data'] as Map<String, dynamic>;
        if (data['comment'] != null) {
          return CaseComment.fromJson(data['comment']);
        }
      }

      // Fallback: create a local comment object
      return CaseComment(
        id: DateTime.now().millisecondsSinceEpoch,
        caseId: caseId,
        userId: 0,
        comment: comment,
        clinicalTags: clinicalTags,
        likes: 0,
        createdAt: DateTime.now(),
        author: CaseAuthor(id: 0, name: 'You', specialty: ''),
        isOwner: true,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> updateComment(int commentId, String comment) async {
    try {
      await _dio.put(
        '$baseUrl/api/v6/cases/comments/$commentId',
        data: {'comment': comment},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _dio.delete('$baseUrl/api/v6/cases/comments/$commentId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPLIES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<CaseReply>> getReplies(int commentId) async {
    try {
      final response =
          await _dio.get('$baseUrl/api/v6/cases/comments/$commentId/replies');
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true && responseData['data'] != null) {
        final data = responseData['data'] as Map<String, dynamic>;
        if (data['replies'] is List) {
          return (data['replies'] as List)
              .map((r) => CaseReply.fromJson(r))
              .toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CaseReply> addReply({
    required int commentId,
    required String reply,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/v6/cases/replies',
        data: {
          'comment_id': commentId,
          'reply': reply,
        },
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true &&
          responseData['data']?['reply'] != null) {
        return CaseReply.fromJson(responseData['data']['reply']);
      }

      return CaseReply(
        id: DateTime.now().millisecondsSinceEpoch,
        commentId: commentId,
        userId: 0,
        reply: reply,
        createdAt: DateTime.now(),
        author: CaseAuthor(id: 0, name: 'You', specialty: ''),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteReply(int replyId) async {
    try {
      await _dio.delete('$baseUrl/api/v6/cases/replies/$replyId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS (like, bookmark, report)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> performCaseAction({
    required int caseId,
    required String action, // like, unlike, bookmark, unbookmark, report
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/v6/cases/action',
        data: {
          'case_id': caseId,
          'action': action,
          if (reason != null) 'reason': reason,
        },
      );
      return response.data as Map<String, dynamic>? ?? {'success': true};
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> performCommentAction({
    required int commentId,
    required String action, // comment_like, comment_unlike
  }) async {
    try {
      await _dio.post(
        '$baseUrl/api/v6/cases/comment-action',
        data: {
          'comment_id': commentId,
          'action': action,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOLLOW / UNFOLLOW
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> followCase(int caseId) async {
    try {
      await _dio.post('$baseUrl/api/v6/cases/$caseId/follow');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> unfollowCase(int caseId) async {
    try {
      await _dio.delete('$baseUrl/api/v6/cases/$caseId/follow');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Throws [AISummaryUpgradeException] when the free quota is exhausted.
  Future<({AISummary summary, int? remaining})> generateAISummary(
      int caseId) async {
    try {
      final response =
          await _dio.post('$baseUrl/api/v6/cases/$caseId/ai-summary');
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true &&
          responseData['data']?['summary'] != null) {
        final summaryJson = responseData['data']['summary'];
        final remaining = responseData['data']['remaining'] as int?;
        return (
          summary: AISummary.fromJson(summaryJson),
          remaining: remaining,
        );
      }
      throw Exception('Failed to generate AI summary');
    } on DioException catch (e) {
      // 429 = free quota exhausted → show upgrade prompt
      if (e.response?.statusCode == 429) {
        final data = e.response?.data;
        final message = data is Map ? (data['message'] ?? 'Quota exceeded') : 'Quota exceeded';
        throw AISummaryUpgradeException(message.toString());
      }
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPDATES TIMELINE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<CaseUpdate>> getCaseUpdates(int caseId) async {
    try {
      final response =
          await _dio.get('$baseUrl/api/v6/cases/$caseId/updates');
      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true &&
          responseData['data']?['updates'] != null) {
        final updatesData = responseData['data']['updates'];
        // Handle paginated response: actual list is in ['data']
        List items;
        if (updatesData is List) {
          items = updatesData;
        } else if (updatesData is Map && updatesData['data'] is List) {
          items = updatesData['data'] as List;
        } else {
          return [];
        }
        return items
            .map((item) => CaseUpdate.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CaseUpdate> createCaseUpdate({
    required int caseId,
    required String updateType,
    required String content,
    List<String> imagePaths = const [],
  }) async {
    try {
      FormData formData = FormData();
      formData.fields.add(MapEntry('update_title', updateType));
      formData.fields.add(MapEntry('update_content', content));
      for (final path in imagePaths) {
        final file = await MultipartFile.fromFile(path,
            filename: path.split('/').last);
        formData.files.add(MapEntry('attached_files[]', file));
      }
      final response = await _dio.post(
        '$baseUrl/api/v6/cases/$caseId/updates',
        data: formData,
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true &&
          responseData['data']?['update'] != null) {
        return CaseUpdate.fromJson(responseData['data']['update']);
      }
      throw Exception('Failed to create update');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<CaseUpdate> editCaseUpdate({
    required int updateId,
    String? updateTitle,
    String? updateContent,
    List<String> newImagePaths = const [],
    List<String> removedImagePaths = const [],
  }) async {
    try {
      final formData = FormData();
      if (updateTitle != null) formData.fields.add(MapEntry('update_title', updateTitle));
      if (updateContent != null) formData.fields.add(MapEntry('update_content', updateContent));
      if (removedImagePaths.isNotEmpty) {
        formData.fields.add(MapEntry('removed_images', jsonEncode(removedImagePaths)));
      }
      for (final path in newImagePaths) {
        final file = await MultipartFile.fromFile(path,
            filename: path.split('/').last);
        formData.files.add(MapEntry('attached_files[]', file));
      }
      final response = await _dio.put(
        '$baseUrl/api/v6/cases/updates/$updateId',
        data: formData,
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true &&
          responseData['data']?['update'] != null) {
        return CaseUpdate.fromJson(responseData['data']['update']);
      }
      throw Exception('Failed to edit update');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> deleteCaseUpdate(int updateId) async {
    try {
      final response = await _dio.delete(
        '$baseUrl/api/v6/cases/updates/$updateId',
      );

      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] != true) {
        throw Exception('Failed to delete update');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  FormData _buildCaseFormData(CreateCaseRequest request) {
    final formData = FormData();

    formData.fields.add(MapEntry('title', request.title));
    formData.fields.add(MapEntry('description', request.description));

    if (request.tags != null && request.tags!.isNotEmpty) {
      // Handle JSON tags format or plain text
      try {
        if (request.tags!.startsWith('[')) {
          final parsed = json.decode(request.tags!) as List;
          final tagValues =
              parsed.map((tag) => tag['value'].toString()).join(', ');
          formData.fields.add(MapEntry('tags', tagValues));
        } else {
          formData.fields.add(MapEntry('tags', request.tags!));
        }
      } catch (_) {
        formData.fields.add(MapEntry('tags', request.tags!));
      }
    }

    formData.fields.add(const MapEntry('specialty_id', '1'));

    if (request.patientDemographics != null) {
      final demographics = request.patientDemographics!;
      if (demographics['age'] != null) {
        formData.fields
            .add(MapEntry('patient_age', demographics['age'].toString()));
      }
      if (demographics['gender'] != null) {
        formData.fields.add(
            MapEntry('patient_gender', demographics['gender'].toString()));
      }
      if (demographics['ethnicity'] != null) {
        formData.fields.add(MapEntry(
            'patient_ethnicity', demographics['ethnicity'].toString()));
      }
    }

    if (request.clinicalComplexity != null) {
      formData.fields.add(
          MapEntry('clinical_complexity', request.clinicalComplexity!));
    }
    if (request.teachingValue != null) {
      formData.fields
          .add(MapEntry('teaching_value', request.teachingValue!));
    }
    if (request.isAnonymized != null) {
      formData.fields.add(
          MapEntry('is_anonymized', request.isAnonymized! ? '1' : '0'));
    }

    return formData;
  }

  /// Attach files to an existing FormData — called separately so
  /// the caller can `await` MultipartFile.fromFile for each path.
  Future<void> attachFiles(
      FormData formData, CreateCaseRequest request) async {
    if (request.existingFileUrls != null) {
      for (int i = 0; i < request.existingFileUrls!.length; i++) {
        formData.fields
            .add(MapEntry('existing_files[$i]', request.existingFileUrls![i]));
      }
    }

    if (request.attachedFiles != null) {
      for (final filePath in request.attachedFiles!) {
        if (filePath.startsWith('http')) {
          formData.fields.add(MapEntry(
              'existing_files[${formData.files.length}]', filePath));
        } else {
          final file = await MultipartFile.fromFile(filePath,
              filename: path.basename(filePath));
          formData.files.add(MapEntry('attached_files[]', file));
        }
      }
    }
  }

  CaseDiscussion _parseCaseResponse(Response response, String action) {
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      if (responseData['success'] == true ||
          response.statusCode == 200 ||
          response.statusCode == 201) {
        Map<String, dynamic>? caseData;
        Map<String, dynamic>? metadataData;

        if (responseData['data'] != null) {
          final data = responseData['data'];
          caseData = data['case'];
          metadataData = data['metadata'];
        } else if (responseData['case'] != null) {
          caseData = responseData['case'];
        }

        if (caseData != null) {
          // Build a structure that CaseDiscussion.fromJson can handle
          final combined = <String, dynamic>{
            'case': caseData,
            if (metadataData != null) 'metadata': metadataData,
          };
          return CaseDiscussion.fromJson(combined);
        }
        throw Exception('Invalid response: case data not found');
      } else {
        final message =
            responseData['message'] ?? 'Failed to $action case';
        final errors = responseData['errors'];
        if (errors != null) {
          throw ValidationException(message, errors);
        }
        throw Exception(message);
      }
    }
    throw Exception('Invalid response format');
  }

  Exception _handleCaseMutationError(DioException e) {
    switch (e.response?.statusCode) {
      case 422:
        final errors = e.response?.data?['errors'];
        final message =
            e.response?.data?['message'] ?? 'Validation failed';
        return ValidationException(message, errors);
      case 401:
        return UnauthorizedException('Authentication required');
      case 403:
        return ForbiddenException('Access denied');
      case 413:
        return Exception('File too large');
      default:
        return _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message =
            error.response?.data?['message'] ?? 'Server error occurred';
        return Exception('Server error ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      default:
        return Exception('Network error occurred. Please try again.');
    }
  }
}

class AISummaryUpgradeException implements Exception {
  final String message;
  const AISummaryUpgradeException(this.message);
  @override
  String toString() => message;
}
