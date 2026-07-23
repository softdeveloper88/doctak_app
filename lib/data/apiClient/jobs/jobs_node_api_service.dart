import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/acting/acting_context_service.dart';
import 'package:doctak_app/core/network/network_utils.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/jobs/job_dto.dart';
import 'package:http/http.dart' as http;

/// Mobile Jobs APIs on doctak-node (`/api/v1/jobs/*`).
class JobsNodeApiService {
  static const _base = '/api/v1/jobs';

  static String get _origin {
    final base = AppData.nodeApiUrl;
    return base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  }

  static Future<JobListResult> browseJobs({
    String? keyword,
    String? locationQ,
    String? countryId,
    List<String> specialties = const [],
    List<String> locations = const [],
    List<String> jobTypes = const [],
    List<String> applyTypes = const [],
    String postedWithin = 'all',
    String sort = 'newest',
    String? cursor,
    int page = 1,
    int limit = 12,
    String expiredJob = '0',
  }) async {
    final params = <String, String>{
      'postedWithin': postedWithin,
      'sort': sort,
      'page': '$page',
      'limit': '$limit',
      'expired_job': expiredJob,
    };
    if (keyword != null && keyword.trim().isNotEmpty) {
      params['q'] = keyword.trim();
    }
    if (locationQ != null && locationQ.trim().isNotEmpty) {
      params['locationQ'] = locationQ.trim();
    }
    if (countryId != null && countryId.trim().isNotEmpty) {
      params['country_id'] = countryId.trim();
    }
    if (cursor != null && cursor.isNotEmpty) {
      params['cursor'] = cursor;
    }

    final parts = <String>[
      ...params.entries.map(
        (e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
      ),
      ...specialties.map((s) => 'specialty=${Uri.encodeQueryComponent(s)}'),
      ...locations.map((s) => 'location=${Uri.encodeQueryComponent(s)}'),
      ...jobTypes.map((s) => 'jobType=${Uri.encodeQueryComponent(s)}'),
      ...applyTypes.map((s) => 'applyType=${Uri.encodeQueryComponent(s)}'),
    ];

    final response = await buildHttpResponseNode('$_base?${parts.join('&')}');
    final data = await handleResponse(response);
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => JobCardDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return JobListResult(
      items: items,
      nextCursor: data['nextCursor']?.toString(),
      facets: JobFacetsDto.fromJson(
        data['facets'] is Map
            ? Map<String, dynamic>.from(data['facets'] as Map)
            : null,
      ),
      page: int.tryParse(data['page']?.toString() ?? '') ?? page,
      total: int.tryParse(data['total']?.toString() ?? '') ??
          (data['facets'] is Map
              ? int.tryParse(
                      (data['facets'] as Map)['total']?.toString() ?? '') ??
                  items.length
              : items.length),
    );
  }

  static Future<JobDetailDto> getJobDetail(String jobId) async {
    final response = await buildHttpResponseNode('$_base/$jobId');
    final data = await handleResponse(response);
    final job = data['job'] as Map<String, dynamic>? ?? data;
    return JobDetailDto.fromJson(Map<String, dynamic>.from(job));
  }

  static Future<JobCapabilitiesDto> getCapabilities() async {
    final response = await buildHttpResponseNode('$_base/me/capabilities');
    final data = await handleResponse(response);
    return JobCapabilitiesDto.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<bool> toggleBookmark(String jobId) async {
    final response = await buildHttpResponseNode(
      '$_base/$jobId/bookmark',
      method: HttpMethod.POST,
    );
    final data = await handleResponse(response);
    return data['bookmarked'] == true;
  }

  static Future<List<JobCardDto>> getBookmarks() async {
    final response = await buildHttpResponseNode('$_base/me/bookmarks');
    final data = await handleResponse(response);
    final list = data['items'] as List<dynamic>? ?? data['bookmarks'] as List?;
    return (list ?? [])
        .whereType<Map>()
        .map((e) => JobCardDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<JobApplicationDto>> getMyApplications() async {
    final response = await buildHttpResponseNode('$_base/me/applications');
    final data = await handleResponse(response);
    final list =
        data['applications'] as List<dynamic>? ?? data['items'] as List?;
    return (list ?? [])
        .whereType<Map>()
        .map((e) => JobApplicationDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> withdrawApplication(String applicationId) async {
    final response = await buildHttpResponseNode(
      '$_base/applications/$applicationId',
      method: HttpMethod.DELETE,
    );
    await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getApplicationDetail(
    String applicationId,
  ) async {
    final response =
        await buildHttpResponseNode('$_base/applications/$applicationId');
    final data = await handleResponse(response);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<Map<String, dynamic>> applyToJob({
    required String jobId,
    File? cvFile,
    String? existingCvPath,
    String? cvText,
    Map<String, dynamic>? extraFields,
  }) async {
    final uri = Uri.parse('$_origin$_base/$jobId/apply');
    final request = http.MultipartRequest('POST', uri);
    final token = AppData.userToken?.trim();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    request.headers.addAll(ActingContextService.instance.actingHeaders());

    if (cvFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('cv', cvFile.path),
      );
    }
    if (existingCvPath != null && existingCvPath.isNotEmpty) {
      request.fields['existingCvPath'] = existingCvPath;
    }
    if (cvText != null && cvText.trim().isNotEmpty) {
      request.fields['cvText'] = cvText.trim();
    }
    if (extraFields != null && extraFields.isNotEmpty) {
      request.fields['extraFields'] = jsonEncode(extraFields);
    }

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    final data = await handleResponse(response);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<String> createJob(Map<String, dynamic> body) async {
    final response = await buildHttpResponseNode(
      _base,
      method: HttpMethod.POST,
      body: body,
    );
    final data = await handleResponse(response);
    return data['id']?.toString() ?? '';
  }

  static Future<void> updateJob(String jobId, Map<String, dynamic> body) async {
    final response = await buildHttpResponseNode(
      '$_base/$jobId',
      method: HttpMethod.PATCH,
      body: body,
    );
    await handleResponse(response);
  }

  static Future<void> deleteJob(String jobId) async {
    final response = await buildHttpResponseNode(
      '$_base/$jobId',
      method: HttpMethod.DELETE,
    );
    await handleResponse(response);
  }

  static Future<MyPostedJobsResult> getMyPosted() async {
    final response = await buildHttpResponseNode('$_base/me/posted');
    final data = await handleResponse(response);
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => JobCardDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return MyPostedJobsResult(
      items: items,
      summary: MyPostedJobsSummaryDto.fromJson(
        data['summary'] is Map
            ? Map<String, dynamic>.from(data['summary'] as Map)
            : null,
      ),
    );
  }

  static Future<JobApplicantsResult> getApplicants(String jobId) async {
    final response = await buildHttpResponseNode('$_base/$jobId/applicants');
    final data = await handleResponse(response);
    return JobApplicantsResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  static Future<void> updateApplicationStage({
    required String applicationId,
    required String stage,
  }) async {
    final response = await buildHttpResponseNode(
      '$_base/applications/$applicationId/stage',
      method: HttpMethod.PATCH,
      body: {'stage': stage},
    );
    await handleResponse(response);
  }

  static Future<void> track(String jobId, {required String type}) async {
    try {
      final response = await buildHttpResponseNode(
        '$_base/$jobId/track',
        method: HttpMethod.POST,
        body: {
          'events': [
            {'type': type}
          ]
        },
      );
      await handleResponse(response);
    } catch (_) {
      /* non-blocking */
    }
  }

  static Future<List<Map<String, dynamic>>> getSpecialties() async {
    final response = await buildHttpResponseNode('$_base/specialties');
    final data = await handleResponse(response);
    final list =
        data['specialties'] as List<dynamic>? ?? data['items'] as List?;
    return (list ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> getCountries() async {
    final response = await buildHttpResponseNode('$_base/countries');
    final data = await handleResponse(response);
    final list = data['countries'] as List<dynamic>? ?? data['items'] as List?;
    return (list ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<List<String>> autocomplete({
    required String q,
    String type = 'keyword',
  }) async {
    final query =
        'q=${Uri.encodeQueryComponent(q)}&type=${Uri.encodeQueryComponent(type)}';
    final response = await buildHttpResponseNode('$_base/autocomplete?$query');
    final data = await handleResponse(response);
    final list = data['suggestions'] as List?;
    return (list ?? []).map((e) {
      if (e is String) return e;
      if (e is Map) {
        return e['label']?.toString() ?? e['name']?.toString() ?? '';
      }
      return e.toString();
    }).where((s) => s.isNotEmpty).toList();
  }

  static Future<String?> uploadCover(File file) async {
    final uri = Uri.parse('$_origin$_base/media');
    final request = http.MultipartRequest('POST', uri);
    final token = AppData.userToken?.trim();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    request.headers.addAll(ActingContextService.instance.actingHeaders());

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);
    final data = await handleResponse(response);
    return data['path']?.toString() ?? data['url']?.toString();
  }

  /// Stripe checkout URL for paid promotion (open in browser; website returns to app).
  static Future<String?> createPromoteCheckout({
    required String jobId,
    required String tier,
    String? jobTitle,
  }) async {
    final response = await buildHttpResponseNode(
      '$_base/$jobId/promote',
      method: HttpMethod.POST,
      body: {
        'tier': tier,
        'jobTitle': jobTitle,
        'from': 'app',
      },
    );
    final data = await handleResponse(response);
    return data['url']?.toString() ?? data['checkoutUrl']?.toString();
  }

  /// Candidate: AI-generated brief for a promoted job. Returns null if gated
  /// (free-tier job) or unavailable; [gateMessage] carries the reason.
  static Future<JobAiBriefDto?> getAiBrief(
    String jobId, {
    void Function(String message)? onGated,
  }) async {
    final response = await buildHttpResponseNode(
      '$_base/$jobId/ai-brief',
      method: HttpMethod.POST,
    );
    final data = await handleResponse(response);
    if (data['success'] == false) {
      onGated?.call(data['message']?.toString() ?? 'AI Brief is not available for this job.');
      return null;
    }
    final insight = data['insight'];
    if (insight is Map) {
      return JobAiBriefDto.fromJson(Map<String, dynamic>.from(insight));
    }
    return null;
  }

  /// Candidate: "Analyze my fit" preview before applying.
  static Future<JobAiMatchDto> getFitPreview({
    required String jobId,
    String? existingCvPath,
    File? cvFile,
    Map<String, dynamic>? extraFields,
  }) async {
    final uri = Uri.parse('$_origin$_base/$jobId/fit-preview');
    final request = http.MultipartRequest('POST', uri);
    final token = AppData.userToken?.trim();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    request.headers.addAll(ActingContextService.instance.actingHeaders());

    if (existingCvPath != null && existingCvPath.isNotEmpty) {
      request.fields['existingCvPath'] = existingCvPath;
    }
    if (cvFile != null) {
      request.files.add(await http.MultipartFile.fromPath('cv', cvFile.path));
    }
    if (extraFields != null && extraFields.isNotEmpty) {
      request.fields['extraFields'] = jsonEncode(extraFields);
    }

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final data = await handleResponse(response);
    return JobAiMatchDto.fromJson(Map<String, dynamic>.from(data['insight'] as Map));
  }

  /// Recruiter: current AI applicant-ranking state (results + plan policy).
  static Future<ApplicantAnalysisStateDto> getApplicantAnalysisState(
    String jobId,
  ) async {
    final response =
        await buildHttpResponseNode('$_base/$jobId/applicant-analysis');
    final data = await handleResponse(response);
    return ApplicantAnalysisStateDto.fromJson(Map<String, dynamic>.from(data));
  }

  /// Recruiter: run/re-run AI applicant ranking. Throws with a user-facing
  /// message on plan-gate rejection (upgrade required / limit exceeded).
  static Future<ApplicantAnalysisStateDto> runApplicantAnalysis(
    String jobId,
  ) async {
    final response = await buildHttpResponseNode(
      '$_base/$jobId/applicant-analysis',
      method: HttpMethod.POST,
      body: const {},
    );
    final data = await handleResponse(response);
    if (data['success'] == false) {
      throw data['message']?.toString() ??
          'AI applicant analysis is not available for your plan.';
    }
    final analysis = data['analysis'];
    return ApplicantAnalysisStateDto.fromJson(
      Map<String, dynamic>.from(analysis is Map ? analysis : data),
    );
  }

  /// Recruiter: job analytics (views/clicks/funnel). Returns null if gated
  /// (job isn't on a paid promotion tier); [gateMessage] carries the reason.
  static Future<JobAnalyticsDto?> getAnalytics(
    String jobId, {
    void Function(String message)? onGated,
  }) async {
    final response = await buildHttpResponseNode('$_base/$jobId/analytics');
    final data = await handleResponse(response);
    final analytics = data['analytics'];
    if (analytics is! Map) {
      onGated?.call(
        data['reason']?.toString() ??
            'Analytics require a paid promotion tier.',
      );
      return null;
    }
    return JobAnalyticsDto.fromJson(Map<String, dynamic>.from(analytics));
  }
}

