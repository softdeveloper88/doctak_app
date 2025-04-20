import 'dart:convert';
import 'dart:io';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:http/http.dart' as http;
import '../models/meeting.dart';
import '../models/participant.dart';
import '../models/message.dart';
import '../models/meeting_settings.dart';

class ApiService {
  final String baseUrl;
  final http.Client client;

  ApiService({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  // Meetings API
  Future<Meeting> createMeeting({String? meetingTitle}) async {
    final response = await client.post(
      Uri.parse('$baseUrl/create-meeting'),
      headers: await _getHeaders(),
      body: json.encode(meetingTitle != null ? {'meeting_title': meetingTitle} : {}),
    );

    if (response.statusCode == 200) {
      return Meeting.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create meeting: ${response.body}');
    }
  }

  Future<Meeting> getMeeting(String meetingId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/meeting/$meetingId/settings'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Meeting.fromJson(json.decode(response.body)['meeting']);
    } else {
      throw Exception('Failed to get meeting: ${response.body}');
    }
  }

  Future<void> joinMeeting(String meetingCode) async {
    final response = await client.post(
      Uri.parse('$baseUrl/join-meeting/$meetingCode'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to join meeting: ${response.body}');
    }
  }

  Future<void> askToJoin(String meetingId, String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/join-meeting-request?meetingId=$meetingId&userId=$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send join request: ${response.body}');
    }
  }

  Future<void> endMeeting(String meetingId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/meeting/end'),
      headers: await _getHeaders(),
      body: json.encode({'meeting_id': meetingId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to end meeting: ${response.body}');
    }
  }

  Future<void> leaveMeeting(String meetingId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/meeting/leave'),
      headers: await _getHeaders(),
      body: json.encode({'meeting_id': meetingId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to leave meeting: ${response.body}');
    }
  }

  // Participants API
  Future<List<Participant>> getMeetingParticipants(String meetingId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/meeting/$meetingId/participants'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['participants'];
      return data.map((json) => Participant.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get participants: ${response.body}');
    }
  }

  Future<void> allowJoinRequest(String meetingId, String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/allow-join-request?meetingId=$meetingId&userId=$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to allow join request: ${response.body}');
    }
  }

  Future<void> rejectJoinRequest(String meetingId, String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/reject-join-request?meetingId=$meetingId&userId=$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reject join request: ${response.body}');
    }
  }

  // Meeting Settings API
  Future<MeetingSettings> getMeetingSettings(String meetingId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/meeting/$meetingId/settings'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return MeetingSettings.fromJson(json.decode(response.body)['settings']);
    } else {
      throw Exception('Failed to get meeting settings: ${response.body}');
    }
  }

  Future<void> updateMeetingSettings(String meetingId, Map<String, dynamic> settings) async {
    final response = await client.post(
      Uri.parse('$baseUrl/meeting-settings/update'),
      headers: await _getHeaders(),
      body: json.encode({
        'meeting_id': meetingId,
        ...settings,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update meeting settings: ${response.body}');
    }
  }

  // Meeting Status Updates
  Future<void> updateMeetingStatus({
    required String userId,
    required String meetingId,
    required String action,
    required bool status,
  }) async {
    print("api call $baseUrl/meeting-update-status?user_id=$userId&meeting_id=$meetingId&action=$action&status=${status ? '1' : '0'}");
    final response = await client.get(
      Uri.parse('$baseUrl/meeting-update-status?user_id=$userId&meeting_id=$meetingId&action=$action&status=${status ? '1' : '0'}'),
      headers: await _getHeaders(),
    );
    print(response.body);
    if (response.statusCode != 200) {
      print(response.body);
      throw Exception('Failed to update meeting status: ${response.body}');
    }
  }

  // Chat API
  Future<List<Message>> getChatHistory(String meetingId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/meeting/$meetingId/chat-history'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['messages'];
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to get chat history: ${response.body}');
    }
  }

  Future<void> sendMessage({
    required String meetingId,
    required String userId,
    required String message,
    String? attachmentUrl,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/send-message-meeting'),
      headers: await _getHeaders(),
      body: json.encode({
        'meeting_id': meetingId,
        'user_id': userId,
        'message': message,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  Future<String> uploadChatAttachment(String meetingId, File file) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/meeting/upload-attachment'),
    );

    final headers = await _getHeaders();
    request.headers.addAll(headers);

    request.fields['meeting_id'] = meetingId;
    request.files.add(await http.MultipartFile.fromPath('attachment', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['attachment_url'];
    } else {
      throw Exception('Failed to upload attachment: ${response.body}');
    }
  }

  // Recording API
  Future<void> startRecording(String meetingId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/meeting/start-recording'),
      headers: await _getHeaders(),
      body: json.encode({'meeting_id': meetingId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to start recording: ${response.body}');
    }
  }

  Future<void> stopRecording(String meetingId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/meeting/stop-recording'),
      headers: await _getHeaders(),
      body: json.encode({'meeting_id': meetingId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to stop recording: ${response.body}');
    }
  }

  // Announcements
  Future<void> makeAnnouncement(String meetingId, String message) async {
    final response = await client.post(
      Uri.parse('$baseUrl/meeting/announcement'),
      headers: await _getHeaders(),
      body: json.encode({
        'meeting_id': meetingId,
        'message': message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send announcement: ${response.body}');
    }
  }

  // Mute all participants
  Future<void> muteAllParticipants(String meetingId) async {
    final response = await client.post(
      Uri.parse('$baseUrl/meeting/mute-all'),
      headers: await _getHeaders(),
      body: json.encode({'meeting_id': meetingId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mute all participants: ${response.body}');
    }
  }

  // Helper for headers
  Future<Map<String, String>> _getHeaders() async {

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${AppData.userToken}',
    };
  }
}
