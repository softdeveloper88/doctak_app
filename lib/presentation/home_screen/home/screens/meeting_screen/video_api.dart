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
  return CreateMeetingModel.fromJson(await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/create-meeting', method: networkUtils.HttpMethod.POST)));
}

Future<MeetingDetailsModel> joinMeetings(String meetingCode) async {
  return MeetingDetailsModel.fromJson(await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/join-meeting?meeting_channel=$meetingCode', method: networkUtils.HttpMethod.GET)));
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
    // ProgressDialogUtils.showProgressDialog();
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse('/allow-join-request?userId=$userId&meetingId=$meetingId', method: networkUtils.HttpMethod.GET),
    );

    // ProgressDialogUtils.hideProgressDialog();

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    // ProgressDialogUtils.hideProgressDialog();
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
    ProgressDialogUtils.showProgressDialog();
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse('/reject-join-request', method: networkUtils.HttpMethod.GET, request: {'userId': userId, 'meetingId': meetingId}),
    );

    ProgressDialogUtils.hideProgressDialog();

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    ProgressDialogUtils.hideProgressDialog();
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> endMeeting(context, meetingId) async {
  try {
    // Don't show progress dialog here - let the caller handle UI feedback
    Map<String, dynamic> response = await networkUtils.handleResponse(await networkUtils.buildHttpResponse('/close-meeting', method: networkUtils.HttpMethod.POST, request: {'meeting_id': meetingId}));

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    debugPrint('End meeting API error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Failed to end meeting: ${e.message}");
  } catch (e) {
    debugPrint('Unexpected error ending meeting: $e');
    return ApiResponse.error("Unexpected error occurred while ending meeting");
  }
}

Future<ApiResponse> sendMessage(meetingId, message, senderId) async {
  try {
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse('/send-message-meeting', method: networkUtils.HttpMethod.POST, request: {'meeting_id': meetingId, 'message': message, 'user_id': senderId}),
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
      await networkUtils.buildHttpResponse('/send-meeting-invitation', method: networkUtils.HttpMethod.POST, request: {'channel': channel, 'userId': userId}),
    );

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> updateMeetingSetting({
  meetingId,
  startStopMeeting,
  addRemoveHost,
  shareScreen,
  raisedHand,
  sendReactions,
  toggleMicrophone,
  toggleVideo,
  enableWaitingRoom,
  requirePassword,
}) async {
  try {
    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse(
        '/meeting-settings/update',
        method: networkUtils.HttpMethod.POST,
        request: {
          'meeting_id': meetingId,
          'start_stop_meetingCheckbox': startStopMeeting,
          'addRemoveHostCheckbox': addRemoveHost,
          'shareScreenCheckbox': shareScreen,
          'raiseHandCheckbox': raisedHand,
          'sendReactionsCheckbox': sendReactions,
          'toggleMicCheckbox': toggleMicrophone,
          'toggleVideoCheckbox': toggleVideo,
          'enableWaitingRoomCheckbox': enableWaitingRoom,
          'requirePasswordCheckbox': requirePassword,
        },
      ),
    );

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

Future<ApiResponse> setScheduleMeeting({title, date, time}) async {
  try {
    ProgressDialogUtils.showProgressDialog();

    Map<String, dynamic> response = await networkUtils.handleResponse(
      await networkUtils.buildHttpResponse('/save-schedule-meeting?title=$title&date=$date&time=$time', method: networkUtils.HttpMethod.GET),
    );
    ProgressDialogUtils.hideProgressDialog();

    return ApiResponse.success(response);
  } on ApiException catch (e) {
    ProgressDialogUtils.hideProgressDialog();

    print('Error: ${e.statusCode} - ${e.message}');
    return ApiResponse.error("Something went wrong");
  }
}

///
/// allow to join meeting api
///
