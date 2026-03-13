import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/network/network_utils.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/data/models/cme/cme_certificate_model.dart';
import 'package:doctak_app/data/models/cme/cme_dashboard_model.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/data/models/cme/cme_notification_model.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CmeApiService {
  static String get _baseUrl => '${AppData.base2}/api/v6/cme';

  // ──────────────────────── Dashboard ────────────────────────

  static Future<CmeDashboardResponse> getDashboard() async {
    final response = await buildHttpResponse1('$_baseUrl/dashboard');
    final data = await handleResponse(response);
    return CmeDashboardResponse.fromJson(data);
  }

  static Future<Map<String, dynamic>> getStats() async {
    final response = await buildHttpResponse1('$_baseUrl/stats');
    return await handleResponse(response);
  }

  // ──────────────────────── Events ────────────────────────

  static Future<CmeEventsResponse> getEvents({
    int page = 1,
    String? search,
    String? type,
    String? format,
    String? specialty,
    String? status,
  }) async {
    final params = <String, String>{'page': '$page'};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (type != null && type != 'all') params['type'] = type;
    if (format != null && format != 'all') params['format'] = format;
    if (specialty != null && specialty != 'all') params['specialty'] = specialty;
    if (status != null && status != 'all') params['status'] = status;

    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response =
        await buildHttpResponse1('$_baseUrl/events?$query');
    final data = await handleResponse(response);
    return CmeEventsResponse.fromJson(data);
  }

  static Future<CmeEventData> getEventDetail(String eventId) async {
    final response = await buildHttpResponse1('$_baseUrl/events/$eventId');
    final data = await handleResponse(response);
    if (data['event'] != null) {
      return CmeEventData.fromJson(data['event']);
    }
    return CmeEventData.fromJson(data);
  }

  // ──────────────────────── My Events ────────────────────────

  static Future<CmeEventsResponse> getMyEvents({int page = 1, String? search}) async {
    var url = '$_baseUrl/events/my/events?page=$page';
    if (search != null && search.isNotEmpty) url += '&search=${Uri.encodeComponent(search)}';
    final response = await buildHttpResponse1(url);
    final data = await handleResponse(response);
    return CmeEventsResponse.fromJson(data);
  }

  static Future<CmeEventsResponse> getUpcomingEvents({int page = 1, String? search}) async {
    var url = '$_baseUrl/events/my/upcoming?page=$page';
    if (search != null && search.isNotEmpty) url += '&search=${Uri.encodeComponent(search)}';
    final response = await buildHttpResponse1(url);
    final data = await handleResponse(response);
    return CmeEventsResponse.fromJson(data);
  }

  static Future<CmeEventsResponse> getAttendedEvents({int page = 1, String? search}) async {
    var url = '$_baseUrl/events/my/attended?page=$page';
    if (search != null && search.isNotEmpty) url += '&search=${Uri.encodeComponent(search)}';
    final response = await buildHttpResponse1(url);
    final data = await handleResponse(response);
    return CmeEventsResponse.fromJson(data);
  }

  static Future<CmeEventsResponse> getCreatedEvents({int page = 1, String? search}) async {
    var url = '$_baseUrl/events/my/created?page=$page';
    if (search != null && search.isNotEmpty) url += '&search=${Uri.encodeComponent(search)}';
    final response = await buildHttpResponse1(url);
    final data = await handleResponse(response);
    return CmeEventsResponse.fromJson(data);
  }

  // ──────────────────────── Registration ────────────────────────

  static Future<Map<String, dynamic>> registerForEvent(String eventId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/register',
      method: HttpMethod.POST,
    );
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> unregisterFromEvent(String eventId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/unregister',
      method: HttpMethod.DELETE,
    );
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getRegistrationStatus(
      String eventId) async {
    final response = await buildHttpResponse1(
        '$_baseUrl/events/$eventId/registration-status');
    return await handleResponse(response);
  }

  // ──────────────────────── Attendance ────────────────────────

  static Future<Map<String, dynamic>> joinEvent(String eventId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/join',
      method: HttpMethod.POST,
    );
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> leaveEvent(String eventId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/leave',
      method: HttpMethod.POST,
    );
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> trackParticipation(
    String eventId, {
    int? duration,
  }) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/track-participation',
      method: HttpMethod.POST,
      request: duration != null ? {'duration': '$duration'} : null,
    );
    return await handleResponse(response);
  }

  // ──────────────────────── Certificates ────────────────────────

  static Future<CmeCertificatesResponse> getCertificates() async {
    final response = await buildHttpResponse1('$_baseUrl/certificates');
    final data = await handleResponse(response);
    return CmeCertificatesResponse.fromJson(data);
  }

  static Future<CmeCertificateData> getCertificateDetail(
      String certificateId) async {
    final response =
        await buildHttpResponse1('$_baseUrl/certificates/$certificateId');
    final data = await handleResponse(response);
    if (data['certificate'] != null) {
      return CmeCertificateData.fromJson(data['certificate']);
    }
    return CmeCertificateData.fromJson(data);
  }

  static Future<String> getCertificateDownloadUrl(String certificateId) async {
    final response = await buildHttpResponse1(
        '$_baseUrl/certificates/$certificateId/download');
    final data = await handleResponse(response);
    return data['download_url'] ?? '';
  }

  // ──────────────────────── Notifications ────────────────────────

  static Future<CmeNotificationsResponse> getNotifications() async {
    final response = await buildHttpResponse1('$_baseUrl/notifications');
    final data = await handleResponse(response);
    return CmeNotificationsResponse.fromJson(data);
  }

  static Future<int> getUnreadNotificationCount() async {
    final response = await buildHttpResponse1('$_baseUrl/notifications/count');
    final data = await handleResponse(response);
    return data['count'] ?? 0;
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/notifications/$notificationId/read',
      method: HttpMethod.POST,
    );
    await handleResponse(response);
  }

  static Future<void> markAllNotificationsRead() async {
    final response = await buildHttpResponse1(
      '$_baseUrl/notifications/mark-all-read',
      method: HttpMethod.POST,
    );
    await handleResponse(response);
  }

  // ──────────────────────── Waitlist ────────────────────────

  static Future<Map<String, dynamic>> joinWaitlist(String eventId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/waitlist/$eventId/join',
      method: HttpMethod.POST,
    );
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> leaveWaitlist(String waitlistId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/waitlist/$waitlistId/leave',
      method: HttpMethod.DELETE,
    );
    return await handleResponse(response);
  }

  // ──────────────────────── Search & Filters ────────────────────────

  static Future<Map<String, dynamic>> getFilters() async {
    final response = await buildHttpResponse1('$_baseUrl/filters');
    return await handleResponse(response);
  }

  static Future<List<String>> getCategories() async {
    final response = await buildHttpResponse1('$_baseUrl/categories');
    final data = await handleResponse(response);
    if (data['categories'] != null) {
      return List<String>.from(data['categories']);
    }
    return [];
  }

  static Future<List<String>> getSpecialties() async {
    final response = await buildHttpResponse1('$_baseUrl/specialties');
    final data = await handleResponse(response);
    if (data['specialties'] != null) {
      return List<String>.from(data['specialties']);
    }
    return [];
  }

  // ──────────────────────── Chat ────────────────────────

  static Future<List<Map<String, dynamic>>> getChatMessages(
      String eventId) async {
    final response =
        await buildHttpResponse1('$_baseUrl/events/$eventId/chat/messages');
    final data = await handleResponse(response);
    if (data['messages'] != null) {
      return List<Map<String, dynamic>>.from(data['messages']);
    }
    return [];
  }

  static Future<Map<String, dynamic>> sendChatMessage(
    String eventId,
    String message,
  ) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/chat',
      method: HttpMethod.POST,
      request: {'message': message},
    );
    return await handleResponse(response);
  }

  // ──────────────────────── Polls ────────────────────────

  static Future<List<Map<String, dynamic>>> getPolls(String eventId) async {
    final response =
        await buildHttpResponse1('$_baseUrl/events/$eventId/polls');
    final data = await handleResponse(response);
    if (data['polls'] != null) {
      return List<Map<String, dynamic>>.from(data['polls']);
    }
    return [];
  }

  static Future<Map<String, dynamic>> votePoll(
      String eventId, String pollId, Map<String, String> vote) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/polls/$pollId/vote',
      method: HttpMethod.POST,
      request: vote,
    );
    return await handleResponse(response);
  }

  // ──────────────────────── Quiz ────────────────────────

  static Future<Map<String, dynamic>> getQuiz(
      String eventId, String moduleId, String quizId) async {
    final response = await buildHttpResponse1(
        '$_baseUrl/events/$eventId/modules/$moduleId/quiz/$quizId');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> submitQuiz(
    String eventId,
    String moduleId,
    String quizId,
    Map<String, String> answers,
  ) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/modules/$moduleId/quiz/$quizId/submit',
      method: HttpMethod.POST,
      request: answers,
    );
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getQuizResults(
      String eventId, String moduleId, String quizId, String resultId) async {
    final response = await buildHttpResponse1(
        '$_baseUrl/events/$eventId/modules/$moduleId/quiz/$quizId/results/$resultId');
    return await handleResponse(response);
  }

  static Future<void> autoSaveQuiz(
    String eventId,
    String moduleId,
    String quizId,
    Map<String, String> answers,
  ) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/modules/$moduleId/quiz/$quizId/auto-save',
      method: HttpMethod.POST,
      request: answers,
    );
    await handleResponse(response);
  }

  static Future<List<Map<String, dynamic>>> getQuizAttempts(
      String eventId, String moduleId, String quizId) async {
    final response = await buildHttpResponse1(
        '$_baseUrl/events/$eventId/modules/$moduleId/quiz/$quizId/attempts');
    final data = await handleResponse(response);
    if (data['attempts'] != null) {
      return List<Map<String, dynamic>>.from(data['attempts']);
    }
    return [];
  }

  // ──────────────────────── Profile/Credits ────────────────────────

  static Future<Map<String, dynamic>> getUserCredits() async {
    final response = await buildHttpResponse1('$_baseUrl/profile/credits');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTranscript() async {
    final response = await buildHttpResponse1('$_baseUrl/profile/transcript');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAchievements() async {
    final response = await buildHttpResponse1('$_baseUrl/profile/achievements');
    return await handleResponse(response);
  }

  // ──────────────────────── Learning Paths ────────────────────────

  static Future<Map<String, dynamic>> getLearningPaths({int page = 1}) async {
    final response =
        await buildHttpResponse1('$_baseUrl/learning-paths?page=$page');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> browseLearningPaths({int page = 1}) async {
    final response =
        await buildHttpResponse1('$_baseUrl/learning-paths/browse?page=$page');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMyEnrolledPaths() async {
    final response =
        await buildHttpResponse1('$_baseUrl/learning-paths/my/enrolled');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMyCompletedPaths() async {
    final response =
        await buildHttpResponse1('$_baseUrl/learning-paths/my/completed');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getLearningPathDetail(
      String pathId) async {
    final response =
        await buildHttpResponse1('$_baseUrl/learning-paths/$pathId');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> enrollInLearningPath(
      String pathId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/learning-paths/$pathId/enroll',
      method: HttpMethod.POST,
    );
    return await handleResponse(response);
  }

  static Future<void> unenrollFromLearningPath(String enrollmentId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/learning-paths/enrollment/$enrollmentId/unenroll',
      method: HttpMethod.DELETE,
    );
    await handleResponse(response);
  }

  static Future<void> pauseLearningPath(String enrollmentId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/learning-paths/enrollment/$enrollmentId/pause',
      method: HttpMethod.POST,
    );
    await handleResponse(response);
  }

  static Future<void> resumeLearningPath(String enrollmentId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/learning-paths/enrollment/$enrollmentId/resume',
      method: HttpMethod.POST,
    );
    await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getEnrollmentProgress(
      String enrollmentId) async {
    final response = await buildHttpResponse1(
        '$_baseUrl/learning-paths/enrollment/$enrollmentId/progress');
    return await handleResponse(response);
  }

  // ──────────────────────── Analytics ────────────────────────

  static Future<Map<String, dynamic>> getAnalyticsDashboard() async {
    final response = await buildHttpResponse1('$_baseUrl/analytics');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCreditAnalytics() async {
    final response = await buildHttpResponse1('$_baseUrl/analytics/credits');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getComplianceAnalytics() async {
    final response = await buildHttpResponse1('$_baseUrl/analytics/compliance');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPerformanceAnalytics() async {
    final response =
        await buildHttpResponse1('$_baseUrl/analytics/performance');
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> getTrends() async {
    final response = await buildHttpResponse1('$_baseUrl/analytics/trends');
    return await handleResponse(response);
  }

  static Future<String> exportAnalytics() async {
    final response = await buildHttpResponse1('$_baseUrl/analytics/export');
    final data = await handleResponse(response);
    return data['download_url'] ?? '';
  }

  // ──────────────────────── Event Creation ────────────────────────

  static Future<Map<String, dynamic>> createEvent(
      Map<String, String> eventData) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events',
      method: HttpMethod.POST,
      request: eventData,
    );
    return await handleResponse(response);
  }

  /// Create event with optional cover image via multipart upload.
  static Future<Map<String, dynamic>> createEventWithImage(
      Map<String, String> eventData, File? coverImage) async {
    if (coverImage == null) return createEvent(eventData);

    final url = Uri.parse('$_baseUrl/events');
    final request = http.MultipartRequest('POST', url);

    if (AppData.userToken != null) {
      request.headers['Authorization'] = 'Bearer ${AppData.userToken}';
    }
    request.headers['Accept'] = 'application/json';

    eventData.forEach((key, value) {
      request.fields[key] = value;
    });

    final fileName = coverImage.path.split('/').last.toLowerCase();
    String mimeType = 'image/jpeg';
    if (fileName.endsWith('.png')) mimeType = 'image/png';
    if (fileName.endsWith('.webp')) mimeType = 'image/webp';

    request.files.add(http.MultipartFile(
      'cover_image',
      http.ByteStream(coverImage.openRead()),
      await coverImage.length(),
      filename: fileName,
      contentType: MediaType.parse(mimeType),
    ));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    if (streamedResponse.statusCode >= 200 &&
        streamedResponse.statusCode < 300) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      throw Exception(
          jsonDecode(responseBody)['message'] ?? 'Failed to create event');
    }
  }

  static Future<Map<String, dynamic>> updateEvent(
      String eventId, Map<String, String> eventData) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId',
      method: HttpMethod.PUT,
      request: eventData,
    );
    return await handleResponse(response);
  }

  static Future<void> deleteEvent(String eventId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId',
      method: HttpMethod.DELETE,
    );
    await handleResponse(response);
  }

  // ──────────────────────── Certificate Sharing ────────────────────────

  static Future<Map<String, dynamic>> shareCertificate(
      String certificateId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/certificates/$certificateId/share',
      method: HttpMethod.POST,
    );
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> verifyCertificate(
      String certificateNumber) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/public/verify-certificate',
      method: HttpMethod.POST,
      request: {'certificate_number': certificateNumber},
    );
    return await handleResponse(response);
  }

  // ──────────────────────── Search ────────────────────────

  static Future<Map<String, dynamic>> searchEvents({
    String? query,
    String? type,
    String? specialty,
    String? format,
    int page = 1,
  }) async {
    final params = <String, String>{};
    if (query != null) params['query'] = query;
    if (type != null) params['type'] = type;
    if (specialty != null) params['specialty'] = specialty;
    if (format != null) params['format'] = format;
    params['page'] = '$page';

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await buildHttpResponse1(
      '$_baseUrl/search?$queryString',
      method: HttpMethod.GET,
    );
    return await handleResponse(response);
  }

  // ──────────────────────── My Waitlists ────────────────────────

  static Future<Map<String, dynamic>> getMyWaitlists() async {
    final response = await buildHttpResponse1(
      '$_baseUrl/waitlist/my-waitlists',
      method: HttpMethod.GET,
    );
    return await handleResponse(response);
  }

  // ──────────────────────── Module Detail & Completion ────────────────────────

  static Future<Map<String, dynamic>> getModuleDetail(String moduleId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/modules/$moduleId',
      method: HttpMethod.GET,
    );
    return await handleResponse(response);
  }

  static Future<void> completeModule(String moduleId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/modules/$moduleId/complete',
      method: HttpMethod.POST,
    );
    await handleResponse(response);
  }

  // ──────────────────────── Poll Creation ────────────────────────

  static Future<Map<String, dynamic>> createPoll(
    String eventId,
    String question,
    List<String> options,
  ) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/polls/create',
      method: HttpMethod.POST,
      request: {
        'question': question,
        for (int i = 0; i < options.length; i++) 'options[$i]': options[i],
      },
    );
    return await handleResponse(response);
  }

  // ──────────────────────── Participants ────────────────────────

  static Future<Map<String, dynamic>> getParticipants(String eventId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/participants',
    );
    return await handleResponse(response);
  }

  // ──────────────────────── Agora Token ────────────────────────

  static Future<Map<String, dynamic>> getAgoraToken(String eventId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/agora-token',
      method: HttpMethod.POST,
    );
    return await handleResponse(response);
  }

  // ──────────────────────── Host Controls ────────────────────────

  static Future<Map<String, dynamic>> endEvent(String eventId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/end-event',
      method: HttpMethod.POST,
    );
    return await handleResponse(response);
  }

  static Future<Map<String, dynamic>> generateCertificates(
      String eventId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/generate-certificates',
      method: HttpMethod.POST,
    );
    return await handleResponse(response);
  }

  static Future<List<dynamic>> getSpeakers(String eventId) async {
    final response =
        await buildHttpResponse1('$_baseUrl/events/$eventId/speakers');
    final data = await handleResponse(response);
    return data['speakers'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> switchModule(
      String eventId, String moduleId) async {
    final response = await buildHttpResponse1(
      '$_baseUrl/events/$eventId/switch-module',
      method: HttpMethod.POST,
      request: {'module_id': moduleId},
    );
    return await handleResponse(response);
  }
}
