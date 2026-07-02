import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_caller.dart' show ApiException;
import 'package:doctak_app/data/models/meeting_model/create_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/fetching_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/meeting_details_model.dart';
import 'package:doctak_app/data/models/meeting_model/search_user_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Meeting API Service — aligned with doctak-node Next.js routes.
///
/// All meeting routes live under /api/meetings/* on the doctak-node server.
/// Auth is Bearer-token based (standard header).
class MeetingApiService {
  static final MeetingApiService _instance = MeetingApiService._internal();
  factory MeetingApiService() => _instance;
  MeetingApiService._internal();

  /// GET /api/meetings/scheduled — list scheduled meetings
  Future<ApiResponse<GetMeetingModel>> getMeetings() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode('/api/meetings/scheduled'),
      );
      return ApiResponse.success(GetMeetingModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get meetings: $e');
    }
  }

  /// POST /api/meetings/create — create/start a new live meeting
  Future<ApiResponse<CreateMeetingModel>> startMeeting({String? name, String? title}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode('/api/meetings/create', method: networkUtils.HttpMethod.POST, body: {
          if (name != null) 'name': name,
          if (title != null) 'title': title,
        }),
      );
      return ApiResponse.success(CreateMeetingModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to start meeting: $e');
    }
  }

  /// POST /api/meetings/join/{code} — join an existing live meeting by channel code
  Future<ApiResponse<MeetingDetailsModel>> joinMeeting({required String meetingCode}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode('/api/meetings/join/$meetingCode', method: networkUtils.HttpMethod.POST),
      );
      return ApiResponse.success(MeetingDetailsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to join meeting: $e');
    }
  }

  /// Search users for meeting invitation — still proxied through the main API
  Future<ApiResponse<SearchUserModel>> searchUsersForMeeting({required String query}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse('/search/users?query=$query', method: networkUtils.HttpMethod.GET),
      );
      return ApiResponse.success(SearchUserModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search users: $e');
    }
  }

  /// POST /api/meetings/join/{code} — ask to join; server places user in waiting room if enabled
  Future<ApiResponse<MeetingDetailsModel>> askToJoin({required String channelName}) async {
    return joinMeeting(meetingCode: channelName);
  }

  /// POST /api/meetings/participants/{participantId}/state — allow user to join
  Future<ApiResponse<Map<String, dynamic>>> allowJoinMeeting({required String participantId}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/meetings/participants/$participantId/state',
          method: networkUtils.HttpMethod.POST,
          body: {'isAllowed': true},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to allow user to join: $e');
    }
  }

  /// POST /api/meetings/participants/{participantId}/state — reject join request
  Future<ApiResponse<Map<String, dynamic>>> rejectJoinMeeting({required String participantId}) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/meetings/participants/$participantId/state',
          method: networkUtils.HttpMethod.POST,
          body: {'isAllowed': false},
        ),
      );
      ProgressDialogUtils.hideProgressDialog();
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      return ApiResponse.error('Failed to reject join request: $e');
    }
  }

  /// POST /api/meetings/{channel}/end — end a live meeting (host only)
  Future<ApiResponse<Map<String, dynamic>>> endMeeting({required String channel}) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode('/api/meetings/$channel/end', method: networkUtils.HttpMethod.POST),
      );
      ProgressDialogUtils.hideProgressDialog();
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      return ApiResponse.error('Failed to end meeting: $e');
    }
  }

  /// POST /api/meetings/{channel}/messages — send a chat message in a live meeting
  Future<ApiResponse<Map<String, dynamic>>> sendMeetingMessage({
    required String channel,
    required String message,
    String? attachmentUrl,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/meetings/$channel/messages',
          method: networkUtils.HttpMethod.POST,
          body: {
            'message': message,
            if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to send meeting message: $e');
    }
  }

  /// POST /api/meetings/participants/{participantId}/state — update participant state
  /// [state] is a map of fields to update, e.g. {isMicOn: true}, {isVideoOn: false}, {isHandUp: true}
  Future<ApiResponse<Map<String, dynamic>>> updateParticipantState({
    required String participantId,
    required Map<String, dynamic> state,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/meetings/participants/$participantId/state',
          method: networkUtils.HttpMethod.POST,
          body: state,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update participant state: $e');
    }
  }

  /// POST /api/meetings/{channel}/invite — send meeting invitation to a user
  Future<ApiResponse<Map<String, dynamic>>> sendMeetingInvitation({required String channel, required String userId}) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/meetings/$channel/invite',
          method: networkUtils.HttpMethod.POST,
          body: {'userId': userId},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to send meeting invitation: $e');
    }
  }

  /// POST /api/meetings/{channel}/settings — update meeting settings (host only)
  Future<ApiResponse<Map<String, dynamic>>> updateMeetingSettings({
    required String channel,
    bool? muteAll,
    bool? shareScreen,
    bool? raisedHand,
    bool? toggleMicrophone,
    bool? toggleVideo,
    bool? enableWaitingRoom,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/meetings/$channel/settings',
          method: networkUtils.HttpMethod.POST,
          body: {
            if (muteAll != null) 'muteAll': muteAll,
            if (shareScreen != null) 'shareScreen': shareScreen,
            if (raisedHand != null) 'raisedHand': raisedHand,
            if (toggleMicrophone != null) 'toggleMicrophone': toggleMicrophone,
            if (toggleVideo != null) 'toggleVideo': toggleVideo,
            if (enableWaitingRoom != null) 'enableWaitingRoom': enableWaitingRoom,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to update meeting settings: $e');
    }
  }

  /// POST /api/meetings/scheduled — schedule a future meeting
  Future<ApiResponse<Map<String, dynamic>>> scheduleMeeting({
    required String title,
    required String date,
    required String time,
    String? description,
    bool? isCmeMeeting,
  }) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/meetings/scheduled',
          method: networkUtils.HttpMethod.POST,
          body: {
            'title': title,
            'date': date,
            'time': time,
            if (description != null) 'description': description,
            if (isCmeMeeting != null) 'isCmeMeeting': isCmeMeeting,
          },
        ),
      );
      ProgressDialogUtils.hideProgressDialog();
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      ProgressDialogUtils.hideProgressDialog();
      return ApiResponse.error('Failed to schedule meeting: $e');
    }
  }

  /// GET /api/meetings/agora-token — obtain an Agora RTC token for a meeting channel
  Future<ApiResponse<Map<String, dynamic>>> getAgoraToken({
    required String channel,
    required int uid,
    String role = 'publisher',
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponseNode(
          '/api/meetings/agora-token',
          method: networkUtils.HttpMethod.POST,
          body: {'channel': channel, 'uid': uid, 'role': role},
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get Agora token: $e');
    }
  }

  // ─── Convenience wrappers ─────────────────────────────────────

  Future<ApiResponse<Map<String, dynamic>>> muteParticipant({required String participantId}) =>
      updateParticipantState(participantId: participantId, state: {'isMicOn': false});

  Future<ApiResponse<Map<String, dynamic>>> unmuteParticipant({required String participantId}) =>
      updateParticipantState(participantId: participantId, state: {'isMicOn': true});

  Future<ApiResponse<Map<String, dynamic>>> turnOffVideo({required String participantId}) =>
      updateParticipantState(participantId: participantId, state: {'isVideoOn': false});

  Future<ApiResponse<Map<String, dynamic>>> turnOnVideo({required String participantId}) =>
      updateParticipantState(participantId: participantId, state: {'isVideoOn': true});

  Future<ApiResponse<Map<String, dynamic>>> raiseHand({required String participantId}) =>
      updateParticipantState(participantId: participantId, state: {'isHandUp': true});

  Future<ApiResponse<Map<String, dynamic>>> lowerHand({required String participantId}) =>
      updateParticipantState(participantId: participantId, state: {'isHandUp': false});
}
