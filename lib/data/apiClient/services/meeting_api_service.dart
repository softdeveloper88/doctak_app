import 'package:doctak_app/core/network/network_utils.dart' as networkUtils;
import 'package:doctak_app/core/utils/progress_dialog_utils.dart';
import 'package:doctak_app/data/apiClient/api_caller.dart';
import 'package:doctak_app/data/models/meeting_model/create_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/fetching_meeting_model.dart';
import 'package:doctak_app/data/models/meeting_model/meeting_details_model.dart';
import 'package:doctak_app/data/models/meeting_model/search_user_model.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/meeting_screen/api_response.dart';

/// Meeting API Service
/// Handles all video meeting related API calls
class MeetingApiService {
  static final MeetingApiService _instance = MeetingApiService._internal();
  factory MeetingApiService() => _instance;
  MeetingApiService._internal();

  /// Get scheduled meetings
  Future<ApiResponse<GetMeetingModel>> getMeetings() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/get-schedule-meetings',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(GetMeetingModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to get meetings: $e');
    }
  }

  /// Start/Create a new meeting
  Future<ApiResponse<CreateMeetingModel>> startMeeting() async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/create-meeting',
          method: networkUtils.HttpMethod.POST,
        ),
      );
      return ApiResponse.success(CreateMeetingModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to start meeting: $e');
    }
  }

  /// Join meeting by code
  Future<ApiResponse<MeetingDetailsModel>> joinMeeting({
    required String meetingCode,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/join-meeting?meeting_channel=$meetingCode',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(MeetingDetailsModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to join meeting: $e');
    }
  }

  /// Search users for meeting invitation
  Future<ApiResponse<SearchUserModel>> searchUsersForMeeting({
    required String query,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/search/users?query=$query',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(SearchUserModel.fromJson(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to search users: $e');
    }
  }

  /// Ask to join a meeting
  Future<ApiResponse<Map<String, dynamic>>> askToJoin({
    required String channelName,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/ask-to-join?meeting_code=$channelName',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to ask to join meeting: $e');
    }
  }

  /// Allow user to join meeting
  Future<ApiResponse<Map<String, dynamic>>> allowJoinMeeting({
    required String meetingId,
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/allow-join-request?userId=$userId&meetingId=$meetingId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to allow user to join: $e');
    }
  }

  /// Reject user join request
  Future<ApiResponse<Map<String, dynamic>>> rejectJoinMeeting({
    required String meetingId,
    required String userId,
  }) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/reject-join-request',
          method: networkUtils.HttpMethod.GET,
          request: {
            'userId': userId,
            'meetingId': meetingId,
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
      return ApiResponse.error('Failed to reject join request: $e');
    }
  }

  /// End/Close meeting
  Future<ApiResponse<Map<String, dynamic>>> endMeeting({
    required String meetingId,
  }) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/close-meeting',
          method: networkUtils.HttpMethod.POST,
          request: {'meeting_id': meetingId},
        ),
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

  /// Send message in meeting chat
  Future<ApiResponse<Map<String, dynamic>>> sendMeetingMessage({
    required String meetingId,
    required String message,
    required String senderId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/send-message-meeting',
          method: networkUtils.HttpMethod.POST,
          request: {
            'meeting_id': meetingId,
            'message': message,
            'user_id': senderId,
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

  /// Change meeting status (mute, video on/off, etc.)
  Future<ApiResponse<Map<String, dynamic>>> changeMeetingStatus({
    required String meetingId,
    required String userId,
    required String action,
    required String status,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/meeting-update-status?meeting_id=$meetingId&user_id=$userId&action=$action&status=$status',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to change meeting status: $e');
    }
  }

  /// Send meeting invitation to user
  Future<ApiResponse<Map<String, dynamic>>> sendMeetingInvitation({
    required String channel,
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/send-meeting-invitation',
          method: networkUtils.HttpMethod.POST,
          request: {
            'channel': channel,
            'userId': userId,
          },
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to send meeting invitation: $e');
    }
  }

  /// Update meeting settings
  Future<ApiResponse<Map<String, dynamic>>> updateMeetingSettings({
    required String meetingId,
    bool? startStopMeeting,
    bool? addRemoveHost,
    bool? shareScreen,
    bool? raisedHand,
    bool? sendReactions,
    bool? toggleMicrophone,
    bool? toggleVideo,
    bool? enableWaitingRoom,
    bool? requirePassword,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/meeting-settings/update',
          method: networkUtils.HttpMethod.POST,
          request: {
            'meeting_id': meetingId,
            if (startStopMeeting != null) 'start_stop_meetingCheckbox': startStopMeeting,
            if (addRemoveHost != null) 'addRemoveHostCheckbox': addRemoveHost,
            if (shareScreen != null) 'shareScreenCheckbox': shareScreen,
            if (raisedHand != null) 'raiseHandCheckbox': raisedHand,
            if (sendReactions != null) 'sendReactionsCheckbox': sendReactions,
            if (toggleMicrophone != null) 'toggleMicCheckbox': toggleMicrophone,
            if (toggleVideo != null) 'toggleVideoCheckbox': toggleVideo,
            if (enableWaitingRoom != null) 'enableWaitingRoomCheckbox': enableWaitingRoom,
            if (requirePassword != null) 'requirePasswordCheckbox': requirePassword,
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

  /// Schedule a meeting
  Future<ApiResponse<Map<String, dynamic>>> scheduleMeeting({
    required String title,
    required String date,
    required String time,
  }) async {
    try {
      ProgressDialogUtils.showProgressDialog();
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse(
          '/save-schedule-meeting?title=$title&date=$date&time=$time',
          method: networkUtils.HttpMethod.GET,
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

  /// Test FCM calling functionality
  Future<ApiResponse<Map<String, dynamic>>> testFcmCall({
    required String userId,
  }) async {
    try {
      final response = await networkUtils.handleResponse(
        await networkUtils.buildHttpResponse1(
          '/test-fcm-calling?user_id=$userId',
          method: networkUtils.HttpMethod.GET,
        ),
      );
      return ApiResponse.success(Map<String, dynamic>.from(response));
    } on ApiException catch (e) {
      return ApiResponse.error(e.message, statusCode: e.statusCode);
    } catch (e) {
      return ApiResponse.error('Failed to test FCM call: $e');
    }
  }

  /// Mute participant
  Future<ApiResponse<Map<String, dynamic>>> muteParticipant({
    required String meetingId,
    required String userId,
  }) async {
    return changeMeetingStatus(
      meetingId: meetingId,
      userId: userId,
      action: 'mute',
      status: 'true',
    );
  }

  /// Unmute participant
  Future<ApiResponse<Map<String, dynamic>>> unmuteParticipant({
    required String meetingId,
    required String userId,
  }) async {
    return changeMeetingStatus(
      meetingId: meetingId,
      userId: userId,
      action: 'mute',
      status: 'false',
    );
  }

  /// Turn off participant video
  Future<ApiResponse<Map<String, dynamic>>> turnOffVideo({
    required String meetingId,
    required String userId,
  }) async {
    return changeMeetingStatus(
      meetingId: meetingId,
      userId: userId,
      action: 'video',
      status: 'false',
    );
  }

  /// Turn on participant video
  Future<ApiResponse<Map<String, dynamic>>> turnOnVideo({
    required String meetingId,
    required String userId,
  }) async {
    return changeMeetingStatus(
      meetingId: meetingId,
      userId: userId,
      action: 'video',
      status: 'true',
    );
  }

  /// Raise hand in meeting
  Future<ApiResponse<Map<String, dynamic>>> raiseHand({
    required String meetingId,
    required String userId,
  }) async {
    return changeMeetingStatus(
      meetingId: meetingId,
      userId: userId,
      action: 'hand',
      status: 'true',
    );
  }

  /// Lower hand in meeting
  Future<ApiResponse<Map<String, dynamic>>> lowerHand({
    required String meetingId,
    required String userId,
  }) async {
    return changeMeetingStatus(
      meetingId: meetingId,
      userId: userId,
      action: 'hand',
      status: 'false',
    );
  }
}