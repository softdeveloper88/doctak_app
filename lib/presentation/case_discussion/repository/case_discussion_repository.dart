import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import '../models/case_discussion_models.dart';

class CaseDiscussionRepository {
  final Dio _dio;
  final String baseUrl;
  final String Function() getAuthToken;

  // Cache for filter data
  List<SpecialtyFilter>? _cachedSpecialties;
  List<CountryFilter>? _cachedCountries;
  DateTime? _lastFilterDataFetch;

  CaseDiscussionRepository({required this.baseUrl, required this.getAuthToken, Dio? dio}) : _dio = dio ?? Dio() {
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
      if (_cachedSpecialties != null && _cachedCountries != null && _lastFilterDataFetch != null && DateTime.now().difference(_lastFilterDataFetch!).inMinutes < 5) {
        return {'specialties': _cachedSpecialties!, 'countries': _cachedCountries!};
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
          specialties = specialtiesData
              .map(
                (item) => SpecialtyFilter.fromJson({
                  'id': item['id'] ?? 0,
                  'name': item['name'] ?? item['specialty_name'] ?? 'Unknown',
                  'slug': (item['name'] ?? item['specialty_name'] ?? 'unknown').toString().toLowerCase().replaceAll(' ', '-'),
                  'is_active': true,
                }),
              )
              .toList();
        } else if (specialtyResponse.data is Map) {
          final responseMap = specialtyResponse.data as Map<String, dynamic>;
          if (responseMap['data'] is List) {
            final specialtiesData = responseMap['data'] as List;
            specialties = specialtiesData
                .map(
                  (item) => SpecialtyFilter.fromJson({
                    'id': item['id'] ?? 0,
                    'name': item['name'] ?? item['specialty_name'] ?? 'Unknown',
                    'slug': (item['name'] ?? item['specialty_name'] ?? 'unknown').toString().toLowerCase().replaceAll(' ', '-'),
                    'is_active': true,
                  }),
                )
                .toList();
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
            countries = countriesData
                .map(
                  (item) => CountryFilter.fromJson({
                    'id': item['id'] ?? 0,
                    'name': item['countryName'] ?? item['name'] ?? 'Unknown',
                    'code': item['countryCode'] ?? item['code'] ?? '',
                    'flag': item['flag'] ?? '',
                  }),
                )
                .toList();
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

      return {'specialties': specialties, 'countries': countries};
    } catch (e) {
      print('Error loading filter patient data: $e');
      // Return empty data, not fallback - let the UI handle empty state
      return {'specialties': <SpecialtyFilter>[], 'countries': <CountryFilter>[]};
    }
  }

  // Get paginated list of case discussions
  Future<PaginatedResponse<CaseDiscussionListItem>> getCaseDiscussions({
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
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

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

      final response = await _dio.get('$baseUrl/api/v3/cases', queryParameters: queryParams);

      final responseData = response.data as Map<String, dynamic>;
      print('API Response Success: ${responseData['success']}');

      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>;
        final casesData = data['cases'] as Map<String, dynamic>;
        final casesList = casesData['data'] as List;

        print('Found ${casesList.length} cases');

        final cases = casesList.map((item) {
          print('📋 Processing case item: ${item['id']} - Name: ${item['name']} - Specialty: ${item['specialty']}');
          return CaseDiscussionListItem.fromJson(item);
        }).toList();

        final pagination = PaginationMeta(
          currentPage: casesData['current_page'] ?? 1,
          lastPage: casesData['last_page'] ?? 1,
          perPage: int.parse(casesData['per_page']?.toString() ?? '12'),
          total: casesData['total'] ?? 0,
        );

        print('Returning ${cases.length} cases with pagination: page ${pagination.currentPage}/${pagination.lastPage}');

        return PaginatedResponse<CaseDiscussionListItem>(items: cases, pagination: pagination);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load case discussions');
      }
    } on DioException catch (e) {
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

      final response = await _dio.get('$baseUrl/api/v3/cases/$caseId');

      print('📱 Response Status: ${response.statusCode}');
      print('📄 Response Data Type: ${response.data.runtimeType}');

      // Handle potential null response data
      if (response.data == null) {
        throw Exception('Empty response from server');
      }

      // Additional check for response data type
      if (response.data is! Map<String, dynamic>) {
        print('❌ Unexpected response type: ${response.data.runtimeType}');
        print('📄 Raw response: ${response.data}');
        throw Exception('Invalid response format from server');
      }

      final responseData = response.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>?;

        if (data == null) {
          throw Exception('No data in response');
        }

        final caseData = data['case'] as Map<String, dynamic>?;

        if (caseData == null) {
          throw Exception('No case data in response');
        }

        // Handle user data - could be nested under 'user' or directly in caseData
        Map<String, dynamic>? userData;
        String authorName = 'Unknown User';

        if (caseData['user'] != null && caseData['user'] is Map<String, dynamic>) {
          // Case detail API: user data is nested under 'user'
          userData = caseData['user'] as Map<String, dynamic>;
          authorName = '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim();
        } else if (caseData['name'] != null) {
          // Case list API: user data is directly in caseData
          userData = {
            'id': caseData['user_id'] ?? 0,
            'first_name': caseData['name']?.toString().split(' ').first ?? 'Unknown',
            'last_name': caseData['name']?.toString().split(' ').skip(1).join(' ') ?? '',
            'specialty': caseData['specialty'],
            'profile_pic': caseData['profile_pic'],
          };
          authorName = caseData['name']?.toString() ?? 'Unknown User';
        } else {
          // Fallback for missing user data
          userData = null;
          authorName = 'Unknown User';
        }

        // Handle comments data - could be List or int (count)
        List commentsData = [];
        final commentsRaw = caseData['comments'];
        if (commentsRaw is List) {
          commentsData = commentsRaw;
        } else if (commentsRaw is int) {
          // If it's an int, it's probably a count, so we'll use empty list for now
          print('📊 Comments field is count ($commentsRaw), not list');
          commentsData = [];
        } else {
          print('⚠️ Comments field is neither List nor int: ${commentsRaw.runtimeType}');
          commentsData = [];
        }

        // Handle related_cases safely
        final relatedCases = (data['related_cases'] is List) ? data['related_cases'] as List : [];

        // Handle is_following safely
        final isFollowing = (data['is_following'] is bool) ? data['is_following'] as bool : false;

        // Debug logging
        print('🔍 Debug Info:');
        print('   - userData is null: ${userData == null}');
        print('   - commentsRaw value: $commentsRaw');
        print('   - commentsRaw type: ${commentsRaw.runtimeType}');
        print('   - commentsData type: ${commentsData.runtimeType} (length: ${commentsData.length})');
        print('   - caseData keys: ${caseData.keys.toList()}');
        print('   - data keys: ${data.keys.toList()}');
        if (userData != null) {
          print('   - userData keys: ${userData.keys.toList()}');
        }

        print('✅ Case loaded: ${caseData['title']}');
        print('👤 Author: $authorName');
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

        // authorName is already built above based on the data source

        // Create the JSON structure that matches the new API response
        final caseJson = Map<String, dynamic>.from(caseData);

        // Add the additional data from the API response
        if (data['is_like'] != null) {
          caseJson['is_like'] = data['is_like'];
        }
        if (data['is_following'] != null) {
          caseJson['is_following'] = data['is_following'];
        }
        if (data['ai_summary'] != null) {
          caseJson['ai_summary'] = data['ai_summary'];
        }
        if (data['metadata'] != null) {
          caseJson['metadata'] = data['metadata'];
        }
        if (data['decision_supports'] != null) {
          caseJson['decision_supports'] = data['decision_supports'];
        }
        if (data['updates'] != null) {
          caseJson['updates'] = data['updates'];
        }
        if (data['followers_count'] != null) {
          caseJson['followers_count'] = data['followers_count'];
        }

        return CaseDiscussion.fromJson(caseJson);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load case discussion');
      }
    } on DioException catch (e) {
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
      // Prepare FormData for the API endpoint
      final formData = FormData();

      // Add required fields
      formData.fields.add(MapEntry('title', request.title));
      formData.fields.add(MapEntry('description', request.description));

      // Add optional basic fields - parse JSON tags and send as simple comma-separated string
      if (request.tags != null && request.tags!.isNotEmpty) {
        try {
          // Parse the JSON tags: [{"value":"tag1"},{"value":"tag2"}]
          final parsed = json.decode(request.tags!) as List;
          final tagValues = parsed
              .map((tag) => tag['value'].toString()) // Extract values
              .join(', '); // Format as "tag1, tag2"
          formData.fields.add(MapEntry('tags', tagValues));
        } catch (e) {
          // Fallback: send as-is if parsing fails
          formData.fields.add(MapEntry('tags', request.tags!));
        }
      }

      // Add specialty_id field (currently hardcoded to "1" as shown in Postman)
      formData.fields.add(MapEntry('specialty_id', '1'));

      // Add individual patient demographic fields instead of nested object
      if (request.patientDemographics != null) {
        final demographics = request.patientDemographics!;
        if (demographics['age'] != null) {
          formData.fields.add(MapEntry('patient_age', demographics['age'].toString()));
        }
        if (demographics['gender'] != null) {
          formData.fields.add(MapEntry('patient_gender', demographics['gender'].toString()));
        }
        if (demographics['ethnicity'] != null) {
          formData.fields.add(MapEntry('patient_ethnicity', demographics['ethnicity'].toString()));
        }
      }

      // Add clinical metadata fields
      if (request.clinicalComplexity != null) {
        formData.fields.add(MapEntry('clinical_complexity', request.clinicalComplexity!));
      }

      if (request.teachingValue != null) {
        formData.fields.add(MapEntry('teaching_value', request.teachingValue!));
      }

      if (request.isAnonymized != null) {
        formData.fields.add(MapEntry('is_anonymized', request.isAnonymized! ? '1' : '0'));
      }

      // Add multiple file attachments
      if (request.attachedFiles != null && request.attachedFiles!.isNotEmpty) {
        for (int i = 0; i < request.attachedFiles!.length; i++) {
          final filePath = request.attachedFiles![i];

          if (filePath.startsWith('http')) {
            // Handle URL case (existing files)
            formData.fields.add(MapEntry('existing_files[$i]', filePath));
          } else {
            // Local file - use array notation for multiple files
            final file = await MultipartFile.fromFile(filePath, filename: path.basename(filePath));
            formData.files.add(MapEntry('attached_files[]', file));
          }
        }
      }

      print('Creating case discussion with URL: $baseUrl/api/v3/cases');
      print('Form fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');
      print('Form files: ${formData.files.map((e) => '${e.key}: ${e.value.filename}').join(', ')}');

      // Make the API request with FormData
      final response = await _dio.post(
        '$baseUrl/api/v3/cases',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data', 'Accept': 'application/json'},
          validateStatus: (status) => status! < 500, // Accept 4xx responses for better error handling
        ),
      );

      print('Create case response status:patient_demographic ${response.statusCode}');
      print('Create case response data: ${response.data}');

      // Handle the response according to your Laravel API structure
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        // Check for successful response
        if ((responseData['success'] == true || response.statusCode == 200 || response.statusCode == 201)) {
          // Extract case data from the expected API response structure
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
            // Transform the Laravel response to match your Flutter model
            final transformedCase = _transformLaravelCaseToFlutter(caseData, metadataData);
            return CaseDiscussion.fromJson(transformedCase);
          } else {
            throw Exception('Invalid response structure: case data not found');
          }
        } else {
          // Handle API errors
          final message = responseData['message'] ?? 'Failed to create case discussion';
          final errors = responseData['errors'];

          if (errors != null) {
            throw ValidationException(message, errors);
          } else {
            throw Exception(message);
          }
        }
      } else {
        throw Exception('Invalid response format from server');
      }
    } on DioException catch (e) {
      print('DioException creating case discussion: ${e.message}');
      print('Response: ${e.response?.data}');

      // Handle specific HTTP error codes
      switch (e.response?.statusCode) {
        case 422:
          // Validation errors
          final errors = e.response?.data['errors'];
          final message = e.response?.data['message'] ?? 'Validation failed';
          throw ValidationException(message, errors);

        case 401:
          throw UnauthorizedException('Authentication required');

        case 403:
          throw ForbiddenException('Access denied');

        case 413:
          throw Exception('File too large');

        case 500:
          throw Exception('Server error occurred');

        default:
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('General error creating case discussion: $e');
      throw Exception('Failed to create case discussion: $e');
    }
  }

  // Update existing case discussion - same format as create
  Future<CaseDiscussion> updateCaseDiscussion(int caseId, CreateCaseRequest request) async {
    try {
      // Prepare FormData for the API endpoint - same format as create
      final formData = FormData();

      // Add required fields
      formData.fields.add(MapEntry('title', request.title));
      formData.fields.add(MapEntry('description', request.description));

      // Add optional basic fields - parse JSON tags and send as simple comma-separated string
      if (request.tags != null && request.tags!.isNotEmpty) {
        try {
          // Parse the JSON tags: [{"value":"tag1"},{"value":"tag2"}]
          final parsed = json.decode(request.tags!) as List;
          final tagValues = parsed
              .map((tag) => tag['value'].toString()) // Extract values
              .join(', '); // Format as "tag1, tag2"
          formData.fields.add(MapEntry('tags', tagValues));
        } catch (e) {
          // Fallback: send as-is if parsing fails
          formData.fields.add(MapEntry('tags', request.tags!));
        }
      }

      // Add specialty_id field (currently hardcoded to "1" as shown in Postman)
      formData.fields.add(MapEntry('specialty_id', '1'));

      // Add individual patient demographic fields instead of nested object
      if (request.patientDemographics != null) {
        final demographics = request.patientDemographics!;
        if (demographics['age'] != null) {
          formData.fields.add(MapEntry('patient_age', demographics['age'].toString()));
        }
        if (demographics['gender'] != null) {
          formData.fields.add(MapEntry('patient_gender', demographics['gender'].toString()));
        }
        if (demographics['ethnicity'] != null) {
          formData.fields.add(MapEntry('patient_ethnicity', demographics['ethnicity'].toString()));
        }
      }

      // Add clinical metadata fields
      if (request.clinicalComplexity != null) {
        formData.fields.add(MapEntry('clinical_complexity', request.clinicalComplexity!));
      }

      if (request.teachingValue != null) {
        formData.fields.add(MapEntry('teaching_value', request.teachingValue!));
      }

      if (request.isAnonymized != null) {
        formData.fields.add(MapEntry('is_anonymized', request.isAnonymized! ? '1' : '0'));
      }

      // Add multiple file attachments
      if (request.attachedFiles != null && request.attachedFiles!.isNotEmpty) {
        for (int i = 0; i < request.attachedFiles!.length; i++) {
          final filePath = request.attachedFiles![i];

          if (filePath.startsWith('http')) {
            // Handle URL case (existing files)
            formData.fields.add(MapEntry('existing_files[$i]', filePath));
          } else {
            // Local file - use array notation for multiple files
            final file = await MultipartFile.fromFile(filePath, filename: path.basename(filePath));
            formData.files.add(MapEntry('attached_files[]', file));
          }
        }
      }

      print('Updating case discussion with URL: $baseUrl/api/v3/cases/$caseId');
      print('Form fields: ${formData.fields.map((e) => '${e.key}: ${e.value}').join(', ')}');
      print('Form files: ${formData.files.map((e) => '${e.key}: ${e.value.filename}').join(', ')}');

      // Make the API request with FormData - same as create method
      final response = await _dio.post(
        '$baseUrl/api/v3/cases/update-case/$caseId',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data', 'Accept': 'application/json'},
          validateStatus: (status) => status! < 500, // Accept 4xx responses for better error handling
        ),
      );

      print('Update case response status: ${response.statusCode}');
      print('Update case response data: ${response.data}');

      // Handle the response according to your Laravel API structure
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        // Check for successful response
        if ((responseData['success'] == true || response.statusCode == 200 || response.statusCode == 201)) {
          // Extract case data from the expected API response structure
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
            // Transform the Laravel response to match your Flutter model
            final transformedCase = _transformLaravelCaseToFlutter(caseData, metadataData);
            return CaseDiscussion.fromJson(transformedCase);
          } else {
            throw Exception('Invalid response structure: case data not found');
          }
        } else {
          // Handle API errors
          final message = responseData['message'] ?? 'Failed to update case discussion';
          final errors = responseData['errors'];

          if (errors != null) {
            throw ValidationException(message, errors);
          } else {
            throw Exception(message);
          }
        }
      } else {
        throw Exception('Invalid response format from server');
      }
    } on DioException catch (e) {
      print('DioException updating case discussion: ${e.message}');
      print('Response: ${e.response?.data}');

      // Handle specific HTTP error codes
      switch (e.response?.statusCode) {
        case 422:
          // Validation errors
          final errors = e.response?.data['errors'];
          final message = e.response?.data['message'] ?? 'Validation failed';
          throw ValidationException(message, errors);

        case 401:
          throw UnauthorizedException('Authentication required');

        case 403:
          throw ForbiddenException('Access denied');

        case 404:
          throw Exception('Case not found');

        case 413:
          throw Exception('File too large');

        case 500:
          throw Exception('Server error occurred');

        default:
          throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('General error updating case discussion: $e');
      throw Exception('Failed to update case discussion: $e');
    }
  }

  // Get comments for a case (now using the case detail API response)
  Future<PaginatedResponse<CaseComment>> getCaseComments({required int caseId, int page = 1, int perPage = 10}) async {
    try {
      print('💬 Loading comments for case ID: $caseId');

      // Get the case details which includes comments
      final caseDetailResponse = await _dio.get('$baseUrl/api/v3/cases/$caseId');

      // Handle potential null response data
      if (caseDetailResponse.data == null) {
        throw Exception('Empty response from server');
      }

      final responseData = caseDetailResponse.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        final data = responseData['data'] as Map<String, dynamic>?;

        if (data == null) {
          throw Exception('No data in response');
        }

        final caseData = data['case'] as Map<String, dynamic>?;

        if (caseData == null) {
          throw Exception('No case data in response');
        }

        // Handle comments data - could be List or int (count)
        List commentsList = [];
        final commentsRaw = caseData['comments'];
        if (commentsRaw is List) {
          commentsList = commentsRaw;
        } else if (commentsRaw is int) {
          print('📊 Comments field is count ($commentsRaw), not list - no comments to load');
          commentsList = [];
        } else {
          print('⚠️ Comments field is neither List nor int: ${commentsRaw.runtimeType}');
          commentsList = [];
        }

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
              userData = {'id': item['user_id'] ?? 'unknown', 'first_name': 'Anonymous', 'last_name': 'User', 'specialty': 'Unknown', 'profile_pic': null};
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

        final pagination = PaginationMeta(currentPage: 1, lastPage: 1, perPage: comments.length, total: comments.length);

        return PaginatedResponse<CaseComment>(items: comments, pagination: pagination);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to load comments');
      }
    } on DioException catch (e) {
      print('❌ Error loading comments: ${e.message}');
      if (e.response != null) {
        print('📱 Response Status: ${e.response?.statusCode}');
        print('📄 Response Data: ${e.response?.data}');
      }
      throw _handleDioError(e);
    } catch (e) {
      print('❌ General error loading comments: $e');
      // Return empty list instead of throwing error
      return PaginatedResponse<CaseComment>(items: [], pagination: PaginationMeta(currentPage: 1, lastPage: 1, perPage: 10, total: 0));
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
      } else {
        discussCaseId ??= 0;
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
        'user':
            commentData['user'] ??
            {
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
  Future<CaseComment> addComment({required int caseId, required String comment, String? clinicalTags}) async {
    try {
      final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

      final queryParameters = <String, dynamic>{'id': caseId.toString(), 'comment': comment, if (clinicalTags != null && clinicalTags.trim().isNotEmpty) 'clinical_tags': clinicalTags.trim()};

      // Server variants observed in this codebase:
      // - Legacy: /comment-discuss-case?id=...&comment=...
      // - Newer:  /api/v4/comment-discuss-case
      // - Current (broken for some envs): /api/v3/comment-discuss-case (404)
      final endpoints = <String>['$normalizedBaseUrl/api/v4/comment-discuss-case', '$normalizedBaseUrl/comment-discuss-case', '$normalizedBaseUrl/api/v3/comment-discuss-case'];

      Response<dynamic>? response;

      for (final endpoint in endpoints) {
        try {
          if (endpoint.endsWith('/api/v3/comment-discuss-case')) {
            // Some servers expect form data for this path.
            final formData = FormData.fromMap({'id': caseId.toString(), 'comment': comment, if (clinicalTags != null && clinicalTags.trim().isNotEmpty) 'clinical_tags': clinicalTags.trim()});

            response = await _dio.post(endpoint, data: formData);
          } else {
            // Legacy/newer endpoints accept query params.
            response = await _dio.post(endpoint, queryParameters: queryParameters);
          }

          // Success
          break;
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          if (status == 404) {
            continue;
          }
          rethrow;
        }
      }

      if (response == null) {
        throw Exception('Comment endpoint not found (404)');
      }

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
    } on DioException catch (e) {
      print('Error adding comment: ${e.message}');
      print('Response: ${e.response?.data}');
      throw _handleDioError(e);
    }
  }

  // Perform case action (like, unlike, bookmark, etc.) using new API v3
  Future<Map<String, dynamic>> performCaseAction({
    required int caseId,
    required String action, // 'like', 'unlike', 'bookmark', 'share', etc.
    String? reason, // Optional reason for reporting
  }) async {
    try {
      // Use the new API v3 endpoint for case actions
      final response = await _dio.post('$baseUrl/api/v3/cases/action', data: {'discuss_case_id': caseId, 'action': action, if (reason != null) 'reason': reason});

      print('Case action response: ${response.data}');

      // Return response data
      return {'success': true, 'action': action, 'case_id': caseId, 'response': response.data};
    } on DioException catch (e) {
      print('Error performing case action: ${e.message}');
      throw _handleDioError(e);
    }
  }

  // Like/unlike comment using new API v3
  Future<void> likeComment({
    required int commentId,
    required String action, // 'like' or 'unlike'
    String? reason,
  }) async {
    try {
      await _dio.post('$baseUrl/api/v3/cases/action', data: {'discuss_case_id': commentId, 'action': action, if (reason != null) 'reason': reason});
    } on DioException catch (e) {
      print('Error liking/unliking comment: ${e.message}');
      throw _handleDioError(e);
    }
  }

  // Delete comment
  Future<void> deleteComment(int commentId) async {
    try {
      await _dio.delete('$baseUrl/api/v3/cases/comments/$commentId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Delete case discussion
  Future<void> deleteCase(int caseId) async {
    try {
      print('🗑️ Deleting case discussion with ID: $caseId');
      print('🌐 API URL: $baseUrl/api/v3/cases/cases-delete/$caseId');

      final response = await _dio.post('$baseUrl/api/v3/cases/cases-delete/$caseId');

      print('✅ Case deleted successfully. Response: ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Error deleting case: ${e.message}');
      if (e.response != null) {
        print('📱 Response Status: ${e.response?.statusCode}');
        print('📄 Response Data: ${e.response?.data}');
      }
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

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Server error occurred';
        return Exception('Server error ($statusCode): $message');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      case DioExceptionType.unknown:
        return Exception('Network error occurred. Please try again.');
      default:
        return Exception('An unexpected error occurred');
    }
  }

  // Helper method to transform Laravel API response to Flutter model format
  Map<String, dynamic> _transformLaravelCaseToFlutter(Map<String, dynamic> caseData, Map<String, dynamic>? metadataData) {
    return {
      'id': caseData['id'],
      'title': caseData['title'],
      'description': caseData['description'],
      'status': 'active', // Default status
      'specialty': caseData['user']?['specialty'] ?? 'General',
      'tags': caseData['tags'],
      'created_at': caseData['created_at'],
      'updated_at': caseData['updated_at'],
      'attachments': caseData['attached_file'] != null ? _parseAttachedFilesFromList(caseData['attached_file']) : [],

      // Author information from the user relationship
      'author': {
        'id': caseData['user']?['id'] ?? 0,
        'name': caseData['user']?['name'] ?? 'Unknown',
        'specialty': caseData['user']?['specialty'] ?? '',
        'profile_pic': caseData['user']?['profile_pic'],
      },

      // Case statistics
      'stats': {
        'comments_count': caseData['comments_count'] ?? 0,
        'followers_count': 0, // Will be updated when followers are implemented
        'updates_count': 0, // Will be updated when updates are implemented
        'likes': caseData['likes'] ?? 0,
        'views': caseData['views'] ?? 0,
      },

      // Metadata if available
      'metadata': metadataData != null
          ? {
              'patient_demographics': metadataData['patient_demographics'],
              'clinical_complexity': metadataData['clinical_complexity'],
              'teaching_value': metadataData['teaching_value'],
              'is_anonymized': metadataData['is_anonymized'],
            }
          : null,
    };
  }

  // Helper method to parse attached files from Laravel response
  List<Map<String, dynamic>> _parseAttachedFiles(dynamic attachedFileData) {
    try {
      if (attachedFileData is String) {
        // If it's a JSON string, decode it
        final decoded = json.decode(attachedFileData);
        if (decoded is List) {
          return decoded
              .map((item) {
                if (item is String) {
                  // If it's just a URL string, create a basic attachment object
                  return {'id': DateTime.now().millisecondsSinceEpoch, 'type': 'image', 'url': item, 'description': path.basename(item)};
                } else if (item is Map<String, dynamic>) {
                  // If it's already an attachment object, return as is
                  return item;
                }
                return {'id': DateTime.now().millisecondsSinceEpoch, 'type': 'unknown', 'url': item.toString(), 'description': 'attachment'};
              })
              .cast<Map<String, dynamic>>()
              .toList();
        }
      } else if (attachedFileData is List) {
        // If it's already a list, process each item
        return attachedFileData
            .map((item) {
              if (item is String) {
                return {'id': DateTime.now().millisecondsSinceEpoch, 'type': 'image', 'url': item, 'description': path.basename(item)};
              } else if (item is Map<String, dynamic>) {
                return item;
              }
              return {'id': DateTime.now().millisecondsSinceEpoch, 'type': 'unknown', 'url': item.toString(), 'description': 'attachment'};
            })
            .cast<Map<String, dynamic>>()
            .toList();
      }
    } catch (e) {
      print('Error parsing attached files: $e');
    }

    return []; // Return empty list if parsing fails
  }

  // Enhanced helper method to parse attached files from various formats in list response
  List<Map<String, dynamic>>? _parseAttachedFilesFromList(dynamic attachedFile) {
    if (attachedFile == null || attachedFile.toString().isEmpty || attachedFile == "null") {
      return null;
    }

    try {
      final attachedFileString = attachedFile.toString();

      // Handle empty arrays
      if (attachedFileString == "\"[]\"" || attachedFileString == "[]") {
        return null;
      }

      // Handle complex JSON string format like "\"[\\\"uploads\\\\\\/...\\\"]\""
      if (attachedFileString.startsWith('"[') && attachedFileString.endsWith(']"')) {
        // Remove outer quotes and unescape
        String cleanedString = attachedFileString.substring(1, attachedFileString.length - 1);
        cleanedString = cleanedString.replaceAll('\\"', '"').replaceAll('\\\\', '\\');

        final parsed = json.decode(cleanedString) as List;
        return parsed.asMap().entries.map((entry) {
          final index = entry.key;
          final url = entry.value.toString();
          return {'id': index, 'type': _getFileTypeFromUrl(url), 'url': url, 'description': 'Attachment ${index + 1}'};
        }).toList();
      }

      // Handle simple JSON array format
      if (attachedFileString.startsWith('[') && attachedFileString.endsWith(']')) {
        final parsed = json.decode(attachedFileString) as List;
        return parsed.asMap().entries.map((entry) {
          final index = entry.key;
          final url = entry.value.toString();
          return {'id': index, 'type': _getFileTypeFromUrl(url), 'url': url, 'description': 'Attachment ${index + 1}'};
        }).toList();
      }

      // Handle single file URL
      if (attachedFileString.isNotEmpty) {
        return [
          {'id': 0, 'type': _getFileTypeFromUrl(attachedFileString), 'url': attachedFileString, 'description': 'Attached file'},
        ];
      }
    } catch (e) {
      print('Error parsing attached files from list: $e');
    }

    return null;
  }

  // Helper method to determine file type from URL
  String _getFileTypeFromUrl(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.jpg') || lowerUrl.contains('.jpeg') || lowerUrl.contains('.png') || lowerUrl.contains('.gif')) {
      return 'image';
    } else if (lowerUrl.contains('.pdf')) {
      return 'pdf';
    } else if (lowerUrl.contains('.doc') || lowerUrl.contains('.docx')) {
      return 'document';
    }
    return 'file';
  }
}

// Custom exception classes for better error handling
class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;

  ValidationException(this.message, this.errors);

  @override
  String toString() => 'ValidationException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);

  @override
  String toString() => 'ForbiddenException: $message';
}
