import 'package:doctak_app/core/network/network_utils.dart';
import 'package:doctak_app/data/models/cme/cme_capabilities_model.dart';
import 'package:doctak_app/data/models/cme/cme_credit_history_model.dart';
import 'package:doctak_app/data/models/cme/cme_dashboard_model.dart';
import 'package:doctak_app/data/models/cme/cme_certificate_model.dart';
import 'package:doctak_app/data/models/cme/cme_event_model.dart';
import 'package:doctak_app/data/models/cme/cme_quiz_model.dart';
import 'package:doctak_app/data/models/cme/cme_speaker_invitation_model.dart';

export 'package:doctak_app/data/models/cme/cme_segment_utils.dart'
    show matchesLearningSegment;

/// Mobile CME APIs on doctak-node (`/api/v1/cme/*`).
class CmeNodeApiService {
  static const _cme = '/api/v1/cme';

  static Future<CmeDashboardResponse> getDashboard() async {
    final response = await buildHttpResponseNode('$_cme/dashboard');
    final data = await handleResponse(response);
    final dashboard = data['dashboard'] as Map<String, dynamic>? ?? data;
    return CmeDashboardResponse.fromJson(dashboard);
  }

  static Future<CmeCapabilities> getCapabilities() async {
    final response = await buildHttpResponseNode('$_cme/me/capabilities');
    final data = await handleResponse(response);
    final caps = data['capabilities'] as Map<String, dynamic>? ?? {};
    return CmeCapabilities.fromJson(caps);
  }

  static Future<List<CmeCertificateData>> getCertificates({int limit = 50}) async {
    final response =
        await buildHttpResponseNode('$_cme/me/certificates?limit=$limit');
    final data = await handleResponse(response);
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => CmeCertificateData.fromNodeJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<CmeCertificateData> getCertificateDetail(String id) async {
    final response = await buildHttpResponseNode('$_cme/certificates/$id');
    final data = await handleResponse(response);
    final cert = data['certificate'] as Map<String, dynamic>? ?? {};
    return CmeCertificateData.fromNodeDetailJson(cert);
  }

  static Future<Map<String, dynamic>> shareCertificate(String id) async {
    final response = await buildHttpResponseNode(
      '$_cme/certificates/$id/share',
      method: HttpMethod.POST,
    );
    return Map<String, dynamic>.from(await handleResponse(response) as Map);
  }

  static Future<String?> getMyCertificateIdForEvent(String eventId) async {
    final response =
        await buildHttpResponseNode('$_cme/events/$eventId/my-certificate');
    final data = await handleResponse(response);
    final id = data['certificateId'];
    return id == null ? null : id.toString();
  }

  static Future<String?> issueMyCertificateForEvent(String eventId) async {
    final response = await buildHttpResponseNode(
      '$_cme/events/$eventId/my-certificate',
      method: HttpMethod.POST,
    );
    final data = await handleResponse(response);
    final id = data['certificateId'];
    return id == null ? null : id.toString();
  }

  static Future<Map<String, dynamic>> generateCertificatesForEvent(
    String eventId,
  ) async {
    final response = await buildHttpResponseNode(
      '$_cme/events/$eventId/generate-certificates',
      method: HttpMethod.POST,
    );
    return Map<String, dynamic>.from(await handleResponse(response) as Map);
  }

  static Future<List<CmeCreditHistoryItem>> getCreditHistory({int limit = 100}) async {
    final response =
        await buildHttpResponseNode('$_cme/me/credits?limit=$limit');
    final data = await handleResponse(response);
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => CmeCreditHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<CmeSpeakerInvitation>> getSpeakerInvitations() async {
    final response = await buildHttpResponseNode('$_cme/me/speaker-invitations');
    final data = await handleResponse(response);
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => CmeSpeakerInvitation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<void> respondSpeakerInvitation(String invitationId, bool accept) async {
    final response = await buildHttpResponseNode(
      '$_cme/speaker-invitations/$invitationId',
      method: HttpMethod.PATCH,
      body: {'response': accept ? 'accepted' : 'declined'},
    );
    await handleResponse(response);
  }

  static Future<CmeEventData> getEventDetail(String eventId) async {
    final response = await buildHttpResponseNode('$_cme/events/$eventId');
    final data = await handleResponse(response);
    final eventJson = data['event'] as Map<String, dynamic>? ?? {};
    return CmeEventData.fromNodeDetailJson(eventJson);
  }

  static Future<void> registerEvent(String eventId) async {
    final response = await buildHttpResponseNode(
      '$_cme/events/$eventId/register',
      method: HttpMethod.POST,
    );
    await handleResponse(response);
  }

  static Future<void> cancelRegistration(String eventId) async {
    final response = await buildHttpResponseNode(
      '$_cme/events/$eventId/register',
      method: HttpMethod.DELETE,
    );
    await handleResponse(response);
  }

  static Future<Map<String, dynamic>> joinLiveEvent(String eventId) async {
    final response = await buildHttpResponseNode(
      '$_cme/events/$eventId/join',
      method: HttpMethod.POST,
    );
    return Map<String, dynamic>.from(await handleResponse(response) as Map);
  }

  static Future<void> endLiveSession(String eventId) async {
    final response = await buildHttpResponseNode(
      '$_cme/events/$eventId/end-live-session',
      method: HttpMethod.POST,
    );
    await handleResponse(response);
  }

  static Future<void> trackParticipation(
    String eventId, {
    required int durationSeconds,
  }) async {
    final response = await buildHttpResponseNode(
      '$_cme/events/$eventId/track-participation',
      method: HttpMethod.POST,
      body: {'durationSeconds': durationSeconds},
    );
    await handleResponse(response);
  }

  static Future<List<CmeSegment>> listSegments(String eventId) async {
    final response = await buildHttpResponseNode('$_cme/events/$eventId/segments');
    final data = await handleResponse(response);
    final items = data['segments'] as List<dynamic>? ?? [];
    return items
        .map((e) => CmeSegment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<List<CmeSpeaker>> listSpeakers(String eventId) async {
    final response = await buildHttpResponseNode('$_cme/events/$eventId/speakers');
    final data = await handleResponse(response);
    final items = data['speakers'] as List<dynamic>? ?? [];
    return items.map((e) => CmeSpeaker.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  static Future<void> submitFeedback(
    String eventId, {
    required int overallRating,
    required int contentQuality,
    required int presenterEffectiveness,
    required int relevanceToPractice,
    String? comments,
  }) async {
    final response = await buildHttpResponseNode(
      '$_cme/events/$eventId/feedback',
      method: HttpMethod.POST,
      body: {
        'overallRating': overallRating,
        'contentQuality': contentQuality,
        'presenterEffectiveness': presenterEffectiveness,
        'technicalQuality': contentQuality,
        'relevanceToPractice': relevanceToPractice,
        'comments': comments,
        'suggestions': null,
        'wouldRecommend': overallRating >= 4,
      },
    );
    await handleResponse(response);
  }

  static Future<CmeQuizData?> getQuiz(
    String eventId, {
    String? moduleId,
    bool reveal = false,
  }) async {
    final params = <String, String>{
      if (moduleId != null && moduleId.isNotEmpty) 'moduleId': moduleId,
      if (reveal) 'reveal': '1',
    };
    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final path = '$_cme/events/$eventId/quiz${query.isEmpty ? '' : '?$query'}';
    final response = await buildHttpResponseNode(path);
    final data = await handleResponse(response);
    final quizJson = data['quiz'];
    if (quizJson == null) return null;
    return CmeQuizData.fromNodeJson(Map<String, dynamic>.from(quizJson as Map));
  }

  static Future<CmeQuizSubmissionResult> submitQuiz(
    String eventId, {
    required String quizId,
    required Map<String, dynamic> answers,
    String? startedAt,
  }) async {
    final response = await buildHttpResponseNode(
      '$_cme/events/$eventId/quiz/submit',
      method: HttpMethod.POST,
      body: {
        'quizId': quizId,
        'answers': answers,
        if (startedAt != null) 'startedAt': startedAt,
      },
    );
    final data = Map<String, dynamic>.from(await handleResponse(response) as Map);
    return CmeQuizSubmissionResult.fromJson(data);
  }

  static Future<NodeCmeEventsPage> listEvents({
    String scope = 'all',
    String? status,
    String? segment,
    String? keyword,
    String? sort,
    String? cursor,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'scope': scope,
      'limit': '$limit',
      if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      if (segment != null && segment.isNotEmpty && segment != 'all') 'segment': segment,
      if (keyword != null && keyword.isNotEmpty) 'q': keyword,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    final query = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final response = await buildHttpResponseNode('$_cme/events/browse?$query');
    final data = await handleResponse(response);
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => CmeEventData.fromNodeJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return NodeCmeEventsPage(
      items: items,
      nextCursor: data['nextCursor'] as String?,
      total: data['total'] is int ? data['total'] as int : items.length,
    );
  }
}

class NodeCmeEventsPage {
  NodeCmeEventsPage({
    required this.items,
    this.nextCursor,
    required this.total,
  });

  final List<CmeEventData> items;
  final String? nextCursor;
  final int total;
}
