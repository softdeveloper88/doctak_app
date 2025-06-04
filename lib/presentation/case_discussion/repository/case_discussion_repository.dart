import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import '../models/case_discussion_models.dart';

class CaseDiscussionRepository {
  final Dio _dio;
  final String baseUrl;
  final String Function() getAuthToken;

  // Cache for filter data
  List<SpecialtyFilter>? _cachedSpecialties;
  List<CountryFilter>? _cachedCountries;
  DateTime? _lastFilterDataFetch;

  CaseDiscussionRepository({
    required this.baseUrl,
    required this.getAuthToken,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer ${getAuthToken()}';
          options.headers['Accept'] = 'application/json';
          
          // Only set Content-Type to JSON if it's not already set (for FormData it's automatically set to multipart)
          if (options.headers['Content-Type'] == null) {
            options.headers['Content-Type'] = 'application/json';
          }
          
          print('🌐 API Request: ${options.method} ${options.uri}');
          print('🔐 Authorization: Bearer ${getAuthToken().substring(0, 20)}...');
          print('📋 Headers: ${options.headers}');
          if (options.data is FormData) {
            final formData = options.data as FormData;
            print('📄 Form Fields: ${formData.fields.map((e) => '${e.key}=${e.value}').join(', ')}');
            print('📎 Form Files: ${formData.files.map((e) => '${e.key}=${e.value.filename}').join(', ')}');
          }
          
          handler.next(options);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.message}');
          if (error.response != null) {
            print('📱 Response Status: ${error.response?.statusCode}');
            print('📝 Response Data: ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  // Get filter data (specialties and countries) from the proper API endpoints
  Future<Map<String, dynamic>> getFilterData() async {
    try {
      // Check cache first (cache for 5 minutes)
      if (_cachedSpecialties != null &&
          _cachedCountries != null &&
          _lastFilterDataFetch != null &&
          DateTime.now().difference(_lastFilterDataFetch!).inMinutes < 5) {
        return {
          'specialties': _cachedSpecialties!,
          'countries': _cachedCountries!,
        };
      }

      print('Fetching specialties from main API...');
      
      List<SpecialtyFilter> specialties = [];
      List<CountryFilter> countries = [];
      
      // Fetch specialties from the main specialty endpoint
      try {
        print('Fetching specialties from: $baseUrl/api/v1/specialty');
        final specialtyResponse = await _dio.get('$baseUrl/api/v1/specialty');
        print('Specialty response: ${specialtyResponse.data}');
        
        if (specialtyResponse.data is List) {
          final specialtiesData = specialtyResponse.data as List;
          specialties = specialtiesData.map((item) => SpecialtyFilter.fromJson({
            'id': item['id'] ?? 0,
            'name': item['name'] ?? item['specialty_name'] ?? 'Unknown',
            'slug': (item['name'] ?? item['specialty_name'] ?? 'unknown').toString().toLowerCase().replaceAll(' ', '-'),
            'is_active': true,
          })).toList();
        } else if (specialtyResponse.data is Map) {
          final responseMap = specialtyResponse.data as Map<String, dynamic>;
          if (responseMap['data'] is List) {
            final specialtiesData = responseMap['data'] as List;
            specialties = specialtiesData.map((item) => SpecialtyFilter.fromJson({
              'id': item['id'] ?? 0,
              'name': item['name'] ?? item['specialty_name'] ?? 'Unknown',
              'slug': (item['name'] ?? item['specialty_name'] ?? 'unknown').toString().toLowerCase().replaceAll(' ', '-'),
              'is_active': true,
            })).toList();
          }
        }
      } catch (e) {
        print('Error fetching specialties: $e');
      }
      
      // Fetch countries from the country-list endpoint
      try {
        print('Fetching countries from: $baseUrl/api/v1/country-list');
        final countryResponse = await _dio.get('$baseUrl/api/v1/country-list');
        print('Country response type: ${countryResponse.data.runtimeType}');
        
        if (countryResponse.data is Map) {
          final responseMap = countryResponse.data as Map<String, dynamic>;
          if (responseMap['countries'] is List) {
            final countriesData = responseMap['countries'] as List;
            countries = countriesData.map((item) => CountryFilter.fromJson({
              'id': item['id'] ?? 0,
              'name': item['countryName'] ?? item['name'] ?? 'Unknown',
              'code': item['countryCode'] ?? item['code'] ?? '',
              'flag': item['flag'] ?? '',
            })).toList();
          }
        }
      } catch (e) {
        print('Error fetching countries: $e');
      }
      
      // Cache the results
      _cachedSpecialties = specialties;
      _cachedCountries = countries;
      _lastFilterDataFetch = DateTime.now();
      
      print('Loaded ${specialties.length} specialties and ${countries.length} countries from main API');
      
      return {
        'specialties': specialties,
        'countries': countries,
      };
      
    } catch (e) {
      print('Error loading filter data: $e');
      // Return empty data, not fallback - let the UI handle empty state
      return {
        'specialties': <SpecialtyFilter>[],
        'countries': <CountryFilter>[],
      };
    }
  }

  // Get paginated list of case discussions
  Future<PaginatedResponse<CaseDiscussion>> getCaseDiscussions({
    int page = 1,
    int perPage = 12,
    String? search,
    String? specialty,
    String? countryId,
    String? sortBy,
    String? sortOrder,
    CaseDiscussionFilters? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      // Apply filters if provided
      if (filters != null) {
        if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
          queryParams['keyword'] = filters.searchQuery;
        }
        if (filters.selectedCountry != null) {
          queryParams['country'] = filters.selectedCountry!.id.toString();
        }
        if (filters.selectedSpecialty != null) {
          queryParams['specialty'] = filters.selectedSpecialty!.id.toString();
        }
        if (filters.sortBy != null) {
          queryParams['sort'] = filters.sortBy;
        }
      } else {
        // Apply individual parameters if no filters object
        if (search != null && search.isNotEmpty) {
          queryParams['keyword'] = search;
        }
        if (countryId != null) {
          queryParams['country'] = countryId;
        }
        if (specialty != null) {
          queryParams['specialty'] = specialty;
        }
        if (sortBy != null) {
          queryParams['sort'] = sortBy;
        }
      }

      print('API Request: $baseUrl/api/v3/cases');
      print('Query Parameters: $queryParams');

      final response = await _dio.get(
        '$baseUrl/api/v3/cases',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>;
      print('API Response Success: ${responseData['success']}');

      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        final casesData = data['cases'] as Map<String, dynamic>;
        final casesList = casesData['data'] as List;

        print('Found ${casesList.length} cases');

        final cases = casesList.map((item) {
          // Parse tags if available
          List<String>? symptoms;
          if (item['tags'] != null && item['tags'].toString().isNotEmpty) {
            try {
              final tagsString = item['tags'].toString();
              if (tagsString.startsWith('[') && tagsString.endsWith(']')) {
                final parsed = json.decode(tagsString) as List;
                symptoms = parsed.map((tag) => tag['value'].toString()).toList();
              }
            } catch (e) {
              print('Error parsing tags: $e');
            }
          }

          return CaseDiscussion.fromJson({
            'id': item['id'],
            'title': item['title'] ?? '',
            'description': item['title'] ?? '', // Use title as description
            'status': 'active',
            'specialty': item['specialty'] ?? 'General',
            'created_at': item['created_at'] ?? DateTime.now().toIso8601String(),
            'updated_at': item['created_at'] ?? DateTime.now().toIso8601String(),
            'author': {
              'id': 0, // Not available in response
              'name': item['name'] ?? 'Unknown',
              'specialty': item['specialty'] ?? '',
              'profile_pic': item['profile_pic'],
            },
            'stats': {
              'comments_count': item['comments'] ?? 0,
              'followers_count': 0, // Not available
              'updates_count': 0, // Not available
              'likes': item['likes'] ?? 0,
              'views': item['views'] ?? 0,
            },
            'symptoms': symptoms,
            'patient_info': null,
            'diagnosis': null,
            'treatment_plan': null,
            'attachments': item['attached_file'] != null
                ? [
                    {
                      'id': 0,
                      'type': 'file',
                      'url': item['attached_file'],
                      'description': 'Attached file',
                    }
                  ]
                : null,
          });
        }).toList();

        final pagination = PaginationMeta(
          currentPage: casesData['current_page'] ?? 1,
          lastPage: casesData['last_page'] ?? 1,
          perPage: int.parse(casesData['per_page']?.toString() ?? '12'),
          total: casesData['total'] ?? 0,
        );

        print('Returning ${cases.length} cases with pagination: page ${pagination.currentPage}/${pagination.lastPage}');

        return PaginatedResponse<CaseDiscussion>(
          items: cases,
          pagination: pagination,
        );
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load case discussions');
      }
    } on DioError catch (e) {
      print('DioError in getCaseDiscussions: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      print('General error in getCaseDiscussions: $e');
      throw Exception('Failed to load discussions: $e');
    }
  }

  // Get single case discussion details using the new API endpoint
  Future<CaseDiscussion> getCaseDiscussion(int caseId) async {
    try {
      print('🔍 Loading case discussion details for ID: $caseId');
      print('🌐 API URL: $baseUrl/api/v3/cases/$caseId');
      
      final response = await _dio.get(
        '$baseUrl/api/v3/cases/$caseId',
      );
      
      print('📱 Response Status: ${response.statusCode}');
      print('📄 Response Data Type: ${response.data.runtimeType}');
      
      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        final caseData = data['case'] as Map<String, dynamic>;
        final userData = caseData['user'] as Map<String, dynamic>;
        final commentsData = caseData['comments'] as List;
        final metadata = data['metadata'] as Map<String, dynamic>?;
        final relatedCases = data['related_cases'] as List? ?? [];
        final isFollowing = data['is_following'] as bool? ?? false;
        
        print('✅ Case loaded: ${caseData['title']}');
        print('👤 Author: ${userData['first_name']} ${userData['last_name']}');
        print('💬 Comments: ${commentsData.length}');
        print('🔗 Related cases: ${relatedCases.length}');
        
        // Parse tags if available
        List<String>? symptoms;
        if (caseData['tags'] != null && caseData['tags'].toString().isNotEmpty) {
          try {
            final tagsString = caseData['tags'].toString();
            if (tagsString.startsWith('[') && tagsString.endsWith(']')) {
              final parsed = json.decode(tagsString) as List;
              symptoms = parsed.map((tag) => tag['value'].toString()).toList();
            }
          } catch (e) {
            print('Error parsing tags: $e');
          }
        }

        // Build author name from first_name and last_name
        final authorName = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
        
        return CaseDiscussion.fromJson({
          'id': caseData['id'],
          'title': caseData['title'] ?? '',
          'description': caseData['description'] ?? '',
          'status': 'active',
          'specialty': userData['specialty'] ?? 'General',
          'created_at': caseData['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': caseData['updated_at'] ?? DateTime.now().toIso8601String(),
          'author': {
            'id': userData['id'] ?? 0,
            'name': authorName.isNotEmpty ? authorName : 'Unknown User',
            'specialty': userData['specialty'] ?? '',
            'profile_pic': userData['profile_pic'],
          },
          'stats': {
            'comments_count': commentsData.length,
            'followers_count': (data['followers'] as List?)?.length ?? 0,
            'updates_count': 0,
            'likes': caseData['likes'] ?? 0,
            'views': caseData['views'] ?? 0,
          },
          'symptoms': symptoms,
          'attachments': caseData['attached_file'] != null
              ? [
                  {
                    'id': 0,
                    'type': 'file',
                    'url': caseData['attached_file'],
                    'description': 'Attached file',
                  }
                ]
              : null,
          'patient_info': metadata != null ? {
            'age': 0, // Not provided in current API
            'gender': '', // Not provided in current API  
            'medical_history': metadata['clinical_complexity'] ?? '',
          } : null,
          // Store additional data for the screen
          'metadata': metadata,
          'is_following': isFollowing,
          'related_cases': relatedCases,
        });
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load case discussion');
      }
    } on DioError catch (e) {
      print('❌ Error loading case discussion: ${e.message}');
      if (e.response != null) {
        print('📱 Response Status: ${e.response?.statusCode}');
        print('📄 Response Data: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      print('❌ General error loading case discussion: $e');
      print('📋 Stack trace: $stackTrace');
      throw Exception('Failed to load case discussion: $e');
    }
  }

  // Create new case discussion
  Future<CaseDiscussion> createCaseDiscussion(CreateCaseRequest request) async {
    try {
      // Prepare form data for the new API endpoint format
      final formData = FormData();
      
      // Add required fields
      formData.fields.add(MapEntry('title', request.title));
      formData.fields.add(MapEntry('description', request.description));
      
      // Add optional fields
      if (request.tags != null) {
        formData.fields.add(MapEntry('tags', request.tags!));
      }
      if (request.specialtyId != null) {
        formData.fields.add(MapEntry('specialty_id', request.specialtyId!));
      }
      
      // Add file attachment if provided
      if (request.attachedFile != null) {
        if (request.attachedFile!.startsWith('http')) {
          // If it's a URL, add it as a field
          formData.fields.add(MapEntry('attached_file', request.attachedFile!));
        } else {
          // If it's a local file path, add it as a file
          formData.files.add(MapEntry(
            'attached_file',
            await MultipartFile.fromFile(request.attachedFile!),
          ));
        }
      }

      print('Creating case discussion with URL: $baseUrl/api/v3/cases');
      print('Form data fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');
      print('Form data files: ${formData.files.map((e) => '${e.key}: ${e.value.filename}').join(', ')}');
      
      final response = await _dio.post(
        '$baseUrl/api/v3/cases',
        data: formData,
      );

      print('Create case response status: ${response.statusCode}');
      print('Create case response data: ${response.data}');

      // Handle different response formats
      final responseData = response.data;
      
      if (responseData is Map<String, dynamic>) {
        // Check if response indicates success
        if (responseData['success'] == true || response.statusCode == 200 || response.statusCode == 201) {
          // Try to extract case data from different possible structures
          Map<String, dynamic>? caseData;
          
          if (responseData['data'] != null && responseData['data']['case'] != null) {
            caseData = responseData['data']['case'];
          } else if (responseData['case'] != null) {
            caseData = responseData['case'];
          } else if (responseData['data'] != null) {
            caseData = responseData['data'];
          } else {
            // If no specific case data, create a minimal case object
            caseData = {
              'id': DateTime.now().millisecondsSinceEpoch,
              'title': request.title,
              'description': request.description,
              'status': 'active',
              'specialty': request.specialty ?? 'General',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'author': {
                'id': 0,
                'name': 'Me',
                'specialty': request.specialty ?? '',
                'profile_pic': null,
              },
              'stats': {
                'comments_count': 0,
                'followers_count': 0,
                'updates_count': 0,
                'likes': 0,
                'views': 0,
              },
            };

          }
          
          return CaseDiscussion.fromJson(caseData!);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create case discussion');
        }
      } else {
        // If response is not a map, assume success and create a minimal case
        return CaseDiscussion.fromJson({
          'id': DateTime.now().millisecondsSinceEpoch,
          'title': request.title,
          'description': request.description,
          'status': 'active',
          'specialty': request.specialty ?? 'General',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'author': {
            'id': 0,
            'name': 'Me',
            'specialty': request.specialty ?? '',
            'profile_pic': null,
          },
          'stats': {
            'comments_count': 0,
            'followers_count': 0,
            'updates_count': 0,
            'likes': 0,
            'views': 0,
          },
        });
      }
    } on DioError catch (e) {
      print('Error creating case discussion: ${e.message}');
      print('Response: ${e.response?.data}');
      throw _handleDioError(e);
    } catch (e) {
      print('General error creating case discussion: $e');
      throw Exception('Failed to create case discussion: $e');
    }
  }

  // Get comments for a case (now using the case detail API response)
  Future<PaginatedResponse<CaseComment>> getCaseComments({
    required int caseId,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      print('💬 Loading comments for case ID: $caseId');
      
      // Get the case details which includes comments
      final caseDetailResponse = await _dio.get(
        '$baseUrl/api/v3/cases/$caseId',
      );
      
      final responseData = caseDetailResponse.data as Map<String, dynamic>;
      
      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        final caseData = data['case'] as Map<String, dynamic>;
        final commentsList = caseData['comments'] as List;
        
        print('✅ Found ${commentsList.length} comments for case $caseId');

        final comments = <CaseComment>[];
        
        for (var item in commentsList) {
          try {
            print('🔍 Raw comment item: $item');
            
            // Handle null user data gracefully
            final userDataRaw = item['user'];
            Map<String, dynamic> userData;
            String authorName;
            
            if (userDataRaw != null && userDataRaw is Map<String, dynamic>) {
              userData = userDataRaw;
              authorName = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
              print('👤 Found user data: $userData');
            } else {
              print('⚠️ User data is null or invalid, creating fallback user');
              // Create fallback user data when user is null
              userData = {
                'id': item['user_id'] ?? 'unknown',
                'first_name': 'Anonymous',
                'last_name': 'User',
                'specialty': 'Unknown',
                'profile_pic': null,
              };
              authorName = 'Anonymous User';
            }
            
            print('👤 Author name: $authorName');
            print('💬 Comment text: ${item['comment']}');
            print('🆔 Comment ID: ${item['id']}');
            
            // Convert discuss_case_id if it's a string
            dynamic rawDiscussCaseId = item['discuss_case_id'];
            int discussCaseIdInt = caseId; // Default to current caseId
            if (rawDiscussCaseId != null) {
              if (rawDiscussCaseId is String) {
                discussCaseIdInt = int.tryParse(rawDiscussCaseId) ?? caseId;
                print('📊 Converted discuss_case_id from String "$rawDiscussCaseId" to int $discussCaseIdInt');
              } else if (rawDiscussCaseId is int) {
                discussCaseIdInt = rawDiscussCaseId;
              }
            }
            
            final commentData = {
              'id': item['id'] ?? 0,
              'discuss_case_id': discussCaseIdInt, // Now guaranteed to be int
              'user_id': item['user_id'] ?? '0', // Keep as dynamic - could be string
              'comment': item['comment'] ?? '',
              'clinical_tags': item['specialty'],
              'likes': item['likes'] ?? 0,
              'dislikes': item['dislikes'] ?? 0,
              'created_at': item['created_at'] ?? DateTime.now().toIso8601String(),
              'updated_at': item['updated_at'] ?? DateTime.now().toIso8601String(),
              'replies_count': 0, // Not provided in current API
              'is_liked': false, // Not provided in current API
              'is_disliked': false, // Not provided in current API
              'user': {
                'id': userData['id'] ?? 0,
                'name': authorName,
                'first_name': userData['first_name'] ?? 'Anonymous',
                'last_name': userData['last_name'] ?? 'User',
                'specialty': userData['specialty'] ?? 'Unknown',
                'profile_pic': userData['profile_pic'],
              },
            };
            
            print('📋 Prepared comment data: $commentData');
            
            // Use a safer approach to create the comment
            final parsedComment = _createSafeComment(commentData);
            if (parsedComment != null) {
              print('✅ Parsed comment successfully: ${parsedComment.comment}');
              comments.add(parsedComment);
            } else {
              print('❌ Failed to create comment from data');
            }
          } catch (e) {
            print('❌ Error parsing individual comment: $e');
            print('   Comment data: $item');
            // Continue with other comments even if one fails
            continue;
          }
        }
        
        print('📝 Total comments parsed: ${comments.length}');

        final pagination = PaginationMeta(
          currentPage: 1,
          lastPage: 1,
          perPage: comments.length,
          total: comments.length,
        );

        return PaginatedResponse<CaseComment>(
          items: comments,
          pagination: pagination,
        );
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load comments');
      }
    } on DioError catch (e) {
      print('❌ Error loading comments: ${e.message}');
      if (e.response != null) {
        print('📱 Response Status: ${e.response?.statusCode}');
        print('📄 Response Data: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      print('❌ General error loading comments: $e');
      // Return empty list instead of throwing error
      return PaginatedResponse<CaseComment>(
        items: [],
        pagination: PaginationMeta(
          currentPage: 1,
          lastPage: 1,
          perPage: 10,
          total: 0,
        ),
      );
    }
  }

  // Helper method to safely create comments
  CaseComment? _createSafeComment(Map<String, dynamic> commentData) {
    try {
      print('🛡️ Creating safe comment from: $commentData');
      
      // Convert discuss_case_id to proper type
      dynamic discussCaseId = commentData['discuss_case_id'];
      if (discussCaseId is String) {
        discussCaseId = int.tryParse(discussCaseId) ?? 0;
      } else if (discussCaseId == null) {
        discussCaseId = 0;
      }
      
      // Ensure all required fields have safe defaults
      final safeCommentData = {
        'id': commentData['id'] ?? 0,
        'discuss_case_id': discussCaseId,
        'user_id': commentData['user_id'] ?? '0', // Keep as dynamic - could be string or int
        'comment': commentData['comment'] ?? '',
        'clinical_tags': commentData['clinical_tags'],
        'likes': commentData['likes'] ?? 0,
        'dislikes': commentData['dislikes'] ?? 0,
        'created_at': commentData['created_at'] ?? DateTime.now().toIso8601String(),
        'updated_at': commentData['updated_at'] ?? DateTime.now().toIso8601String(),
        'replies_count': commentData['replies_count'] ?? 0,
        'is_liked': commentData['is_liked'] ?? false,
        'is_disliked': commentData['is_disliked'] ?? false,
        'user': commentData['user'] ?? {
          'id': commentData['user_id'] ?? '0', // Use the same user_id
          'name': 'Anonymous User',
          'first_name': 'Anonymous',
          'last_name': 'User',
          'specialty': 'Unknown',
          'profile_pic': null,
        },
      };
      
      print('🛡️ Safe comment data: $safeCommentData');
      
      return CaseComment.fromJson(safeCommentData);
    } catch (e, stackTrace) {
      print('❌ Error in _createSafeComment: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ Comment data: $commentData');
      return null;
    }
  }

  // Add comment to case
  Future<CaseComment> addComment({
    required int caseId,
    required String comment,
    String? clinicalTags,
  }) async {
    try {
      // Use the old API endpoint with form data
      final formData = FormData.fromMap({
        'id': caseId.toString(),
        'comment': comment,
      });

      final response = await _dio.post(
        '$baseUrl/api/v3/comment-discuss-case',
        data: formData,
      );

      // The old API might return success message
      final responseData = response.data;
      print('Add comment response: $responseData');
      
      // Since the API might not return the full comment data, 
      // create a temporary comment object
      return CaseComment.fromJson({
        'id': DateTime.now().millisecondsSinceEpoch, // Temporary ID
        'case_id': caseId,
        'user_id': 0,
        'comment': comment,
        'author': {
          'id': 0,
          'name': 'Me', // This should be replaced with actual user name
          'profile_pic': null,
          'specialty': '',
        },
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'likes': 0,
        'dislikes': 0,
        'replies_count': 0,
        'is_liked': false,
        'is_disliked': false,
      });
    } on DioError catch (e) {
      print('Error adding comment: ${e.message}');
      print('Response: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  // Perform case action (like, bookmark, etc.)
  Future<Map<String, dynamic>> performCaseAction({
    required int caseId,
    required String action, // 'like', 'bookmark', 'share', etc.
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Use the old API endpoint for case actions
      final response = await _dio.post(
        '$baseUrl/api/v3/discuss-case-action',
        data: {
          'id': caseId.toString(),
          'type': 'case',
          'action_type': action == 'like' ? 'likes' : action,
        },
      );

      // Return a simple success response
      return {
        'success': true,
        'action': action,
        'case_id': caseId,
      };
    } on DioError catch (e) {
      throw _handleDioError(e);
    }
  }

  // Like/unlike comment
  Future<void> likeComment(int commentId) async {
    try {
      await _dio.post(
        '$baseUrl/api/v3/cases/action',
        data: {
          'case_id': commentId,
          'type': 'case_comment',
          'action': 'likes',
        },
      );
    } on DioError catch (e) {
      throw _handleDioError(e);
    }
  }

  // Delete comment
  Future<void> deleteComment(int commentId) async {
    try {
      await _dio.delete('$baseUrl/api/v3/cases/comments/$commentId');
    } on DioError catch (e) {
      throw _handleDioError(e);
    }
  }

  // Get list of specialties for filtering (now using getFilterData)
  Future<List<SpecialtyFilter>> getSpecialties() async {
    try {
      final filterData = await getFilterData();
      return filterData['specialties'];
    } catch (e) {
      print('Error loading specialties: $e');
      return [];
    }
  }

  // Get list of countries for filtering (now using getFilterData)
  Future<List<CountryFilter>> getCountries() async {
    try {
      final filterData = await getFilterData();
      return filterData['countries'];
    } catch (e) {
      print('Error loading countries: $e');
      return [];
    }
  }

  

  Exception _handleDioError(DioError error) {
    switch (error.type) {
      case DioErrorType.connectionTimeout:
      case DioErrorType.sendTimeout:
      case DioErrorType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioErrorType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error occurred';
        return Exception('Server error ($statusCode): $message');
      case DioErrorType.cancel:
        return Exception('Request was cancelled');
      case DioErrorType.unknown:
        return Exception('Network error occurred. Please try again.');
      default:
        return Exception('An unexpected error occurred');
    }
  }
}
