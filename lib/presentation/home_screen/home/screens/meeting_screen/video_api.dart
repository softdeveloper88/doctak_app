import 'package:doctak_app/data/models/meeting_model/meeting_history_model.dart';
import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/meeting_model/create_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/fetching_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/meeting_details_model.dart' show MeetingDetailsModel;
import 'package:doctak_app/data/models/meeting_model/search_user_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'api_response.dart';

/// start meeting api
///

Future<GetMeetingModel> getMeetings() async {
  return GetMeetingModel.fromJson(await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/get-schedule-meetings', method: networkUtils.HttpMethod.GET)));
}

/// start meeting api
///

Future<CreateMeetingModel> startMeetings() async {
  return CreateMeetingModel.fromJson(await networkUtils.handleResponse(await networkUtils.buildHttpResponseNode('/api/meetings/create', method: networkUtils.HttpMethod.POST)));
}

Future<MeetingDetailsModel> joinMeetings(String meetingCode) async {
  return MeetingDetailsModel.fromJson(await networkUtils.handleResponse(await networkUtils.buildHttpResponseNode('/api/meetings/join/$meetingCode', method: networkUtils.HttpMethod.POST)));
}

/// Fetches meeting details WITHOUT re-registering the participant.
/// Use this for in-call refreshes (participant list updates, settings changes).
/// Use [joinMeetings] only on the initial join.
Future<MeetingDetailsModel> getMeetingDetails(String meetingCode) async {
  return MeetingDetailsModel.fromJson(await networkUtils.handleResponse(await networkUtils.buildHttpResponseNode('/api/meetings/$meetingCode', method: networkUtils.HttpMethod.GET)));
}

Future<SearchUserModel> searchUserForMeeting(String query) async {
  return SearchUserModel.fromJson(await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/search/users?query=$query', method: networkUtils.HttpMethod.GET)));
}

///
/// ask to join meeting api
///

Future<ApiResponse> askToJoin(context, channelName) async {
  try {
    print(channelName);

    var response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/ask-to-join?meeting_code=$channelName', method: networkUtils.HttpMethod.GET));
    print(response);

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> allowJoinMeet(context, meetingId, userId) async {
  try {
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse('/allow-join-request?participantId=$userId&meetingId=$meetingId', method: networkUtils.HttpMethod.GET),
    );

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> testFCMCall(userId) async {
  try {
    // ProgressDialogUtils.showProgressDialog();
    Map<String, dynamic> response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse1('/test-fcm-calling?user_id=$userId', method: networkUtils.HttpMethod.GET));

    // ProgressDialogUtils.hideProgressDialog();

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    // ProgressDialogUtils.hideProgressDialog();
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> rejectJoinMeet(context, meetingId, userId) async {
  try {
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse('/reject-join-request?participantId=$userId&meetingId=$meetingId', method: networkUtils.HttpMethod.GET),
    );

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> endMeeting(context, meetingChannel) async {
  try {
    // meetingChannel is the Agora channel code, e.g. "abc123"
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponseNode('/api/meetings/$meetingChannel/end', method: networkUtils.HttpMethod.POST),
    );
    return ApiResponse.success(response);
  } on ApiException catch (e) {
    debugPrint('End meeting API error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Failed to end meeting: ${e.message}");
  } catch (e) {
    debugPrint('Unexpected error ending meeting: $e');
    return ApiResponse.error("Unexpected error occurred while ending meeting");
  }
}

Future<ApiResponse> sendMessage(channel, message, senderId) async {
  try {
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponseNode(
        '/api/meetings/$channel/messages',
        method: networkUtils.HttpMethod.POST,
        body: {'message': message},
      ),
    );
    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

/// Polls chat messages from the server (same approach as the web).
/// [channel] is the Agora meeting channel code (e.g. "FUb-Awks-29").
/// [afterIso] is the ISO timestamp of the last known message; when null,
/// all messages for the meeting are returned.
Future<ApiResponse> getMessages(String channel, {String? afterIso}) async {
  try {
    final path = afterIso != null
        ? '/api/meetings/$channel/messages?after=${Uri.encodeQueryComponent(afterIso)}'
        : '/api/meetings/$channel/messages';
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponseNode(path, method: networkUtils.HttpMethod.GET),
    );
    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> changeMeetingStatus(context, meetingId, userId, action, status) async {
  try {
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse('/meeting-update-status?meeting_id=$meetingId&user_id=$userId&action=$action&status=$status', method: networkUtils.HttpMethod.GET),
    );

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> closeMeetingStatus(context, meetingId, userId, action, status) async {
  try {
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse('/meeting-update-status?meeting_id=$meetingId&user_id=$userId&action=$action&status=$status', method: networkUtils.HttpMethod.GET),
    );

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> sendInviteMeeting(channel, userId) async {
  try {
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponseNode(
        '/api/meetings/$channel/invite',
        method: networkUtils.HttpMethod.POST,
        body: {'userId': userId},
      ),
    );
    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> updateMeetingSetting({
  meetingChannel,
  muteAll,
  shareScreen,
  raisedHand,
  sendReactions,
  toggleMicrophone,
  toggleVideo,
  enableWaitingRoom,
}) async {
  try {
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponseNode(
        '/api/meetings/$meetingChannel/settings',
        method: networkUtils.HttpMethod.POST,
        body: {
          if (muteAll != null) 'muteAll': muteAll,
          if (shareScreen != null) 'shareScreen': shareScreen,
          if (raisedHand != null) 'raisedHand': raisedHand,
          if (sendReactions != null) 'sendReactions': sendReactions,
          if (toggleMicrophone != null) 'toggleMicrophone': toggleMicrophone,
          if (toggleVideo != null) 'toggleVideo': toggleVideo,
          if (enableWaitingRoom != null) 'enableWaitingRoom': enableWaitingRoom,
        },
      ),
    );
    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}


/// Update the caller's own participant-state row via the Node backend.
/// [participantId] is the `meeting_details` primary-key UUID returned in the
/// join response (stored in `Users.meetingDetails[0].id`).
///
/// Triggers a `meeting-status` Pusher event so all other participants (Flutter
/// AND web) see the change in real-time.
Future<ApiResponse> updateMeetingParticipantState(
  String participantId, {
  bool? isHandUp,
  bool? isMicOn,
  bool? isVideoOn,
  bool? isScreenShared,
}) async {
  try {
    final Map<String, dynamic> body = {};
    if (isHandUp != null) body['isHandUp'] = isHandUp;
    if (isMicOn != null) body['isMicOn'] = isMicOn;
    if (isVideoOn != null) body['isVideoOn'] = isVideoOn;
    if (isScreenShared != null) body['isScreenShared'] = isScreenShared;

    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponseNode(
        '/api/meetings/participants/$participantId/state',
        method: networkUtils.HttpMethod.POST,
        body: body,
      ),
    );
    return ApiResponse.success(response);
  } on ApiException catch (e) {
    debugPrint('updateMeetingParticipantState error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> setScheduleMeeting({
  title,
  date,
  time,
  int duration = 60,
  String type = 'meeting',
  String description = '',
  bool enableWaitingRoom = false,
  bool requireRegistration = false,
  bool autoRecord = false,
}) async {
  try {
    ProgressDialogUtils.showProgressDialog();
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponseNode(
        '/api/meetings/scheduled',
        method: networkUtils.HttpMethod.POST,
        body: {
          'title': title,
          'date': date,
          'time': time,
          'duration': duration,
          'type': type,
          'description': description,
          'enableWaitingRoom': enableWaitingRoom,
          'requireRegistration': requireRegistration,
          'autoRecord': autoRecord,
        },
      ),
    );
    ProgressDialogUtils.hideProgressDialog();

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    ProgressDialogUtils.hideProgressDialog();

    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<MeetingHistoryResponse> getMeetingHistory({
  String filter = 'all',
  String search = '',
  int page = 1,
}) async {
  final status = filter == 'all' ? 'ended' : filter;
  final response = await networkUtils.handleResponse(
    await networkUtils.buildHttpResponseNode(
      '/api/v1/meeting-history?filter=$filter&search=${Uri.encodeComponent(search)}&page=$page&status=$status',
      method: networkUtils.HttpMethod.GET,
    ),
  );
  if (response is Map<String, dynamic>) {
    return MeetingHistoryResponse.fromJson(response);
  }
  return MeetingHistoryResponse(
    success: false,
    data: [],
    pagination: MeetingHistoryPagination(currentPage: 1, lastPage: 1, perPage: 10, total: 0),
  );
}

Future<ApiResponse> cancelScheduledMeeting(int meetingId) async {
  try {
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponseNode(
        '/api/meetings/scheduled/$meetingId',
        method: networkUtils.HttpMethod.DELETE,
      ),
    );
    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

///
/// allow to join meeting api
///
