import 'dart:io';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/presentation/call_module/call_api_service.dart';
import 'package:doctak_app/presentation/call_module/ui/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  // Add CallApiService
  late CallApiService _callApiService;

  // Initialize method to set up the API service
  Future<void> initialize({required String baseUrl, String? authToken}) async {
    _callApiService = CallApiService(
      baseUrl: baseUrl,
      authToken: authToken,
    );
  }

  /// Display incoming call UI using CallKit
  Future<void> displayIncomingCall({
    required String uuid,
    required String callerName,
    required String callerId,
    required String avatar,
    required bool hasVideo,
  }) async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      debugPrint('CallKit is only supported on iOS and Android');
      return;
    }

    final params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'Doctak.net',
      avatar: avatar,
      handle: callerId,
      type: hasVideo ? 1 : 0,
      textAccept: 'Accept',
      textDecline: 'Decline',
      duration: 30000,
      extra: {
        'userId': callerId,
        'has_video': hasVideo,
        'avatar': avatar,
        'callerName': callerName,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        isShowCallID: false,
      ),
      ios: const IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  /// Listen to CallKit events
  void listenToCallEvents() {
    FlutterCallkitIncoming.onEvent.listen((event) async {
      final eventType = event?.event;
      final extra = event?.body['extra'] ?? {};
      final callId = event?.body['id'] ?? '';
      final callerName = extra['callerName'] ?? 'Unknown';
      final avatar = extra['avatar'] ?? '';
      final userId = extra['userId'] ?? '';
      final hasVideo = extra['has_video'] == true || extra['has_video'] == 'true';

      switch (eventType) {
        case Event.actionCallAccept:
          try {
            // Call accept API
            // final response = await _callApiService.acceptCall(
            //   callId: callId,
            //   callerId: userId,
            // );

            // Save call info for potential resuming
            await _saveCallInfo(callId, userId, callerName, avatar, hasVideo);

            // Ensure navigator is available before pushing the screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              NavigatorService.navigatorKey.currentState?.push(MaterialPageRoute(
                builder: (context) => CallScreen(
                  callId: callId,
                  contactId: userId,
                  contactName: callerName,
                  contactAvatar: avatar,
                  isIncoming: true,
                  isVideoCall: hasVideo,
                  token: '', // Pass token from API
                ),
              ));
            });
          } catch (e) {
            debugPrint('Error accepting call: $e');
          }
          break;

        case Event.actionCallDecline:
          try {
            // Call reject API
            await _callApiService.rejectCall(
              callId: callId,
              callerId: userId,
            );
          } catch (e) {
            debugPrint('Error rejecting call: $e');
          }
          break;

        case Event.actionCallTimeout:
          try {
            // Call missed API
            await _callApiService.missCall(
              callId: callId,
              callerId: userId,
            );
          } catch (e) {
            debugPrint('Error marking call missed: $e');
          }
          break;

        case Event.actionCallEnded:
          try {
            // Call end API
            await _callApiService.endCall(
              callId: callId,
            );
            NavigatorService.navigatorKey.currentState?.maybePop();
          } catch (e) {
            debugPrint('Error ending call: $e');
          }
          break;

        default:
          break;
      }
    });
  }

  /// End an active call (dismisses CallKit UI)
  Future<void> endCall(String uuid) async {
    try {
      // Call the API to end the call
      await _callApiService.endCall(callId: uuid);

      // Also end the callkit UI
      await FlutterCallkitIncoming.endCall(uuid);

      // Clear saved call info
      await _clearCallInfo();
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  /// Start an outgoing call
  Future<Map<String, dynamic>> startOutgoingCall({
    required String userId,
    required String calleeName,
    required String avatar,
    required bool hasVideo,
  }) async {
    try {
      // Call the API to initiate the call
      final response = await _callApiService.initiateCall(
        userId: userId,
        hasVideo: hasVideo,
      );

      final callId = response['callId'];

      // Save call info for potential resuming
      await _saveCallInfo(callId, userId, calleeName, avatar, hasVideo);

      // Show the outgoing call UI with CallKit
      final params = CallKitParams(
        id: callId,
        nameCaller: calleeName,
        handle: userId,
        type: hasVideo ? 1 : 0,
        extra: {
          'userId': userId,
          'has_video': hasVideo,
          'callerName': calleeName,
          'avatar': avatar,
        },
        ios: const IOSParams(
          handleType: 'generic',
          supportsVideo: true,
        ),
        android: const AndroidParams(
          isCustomNotification: false,
          isShowLogo: true,
          ringtonePath: 'system_ringtone_default',
        ),
      );
      await FlutterCallkitIncoming.startCall(params);

      return response;
    } catch (e) {
      debugPrint('Error starting outgoing call: $e');
      rethrow;
    }
  }

  /// Check if there are any active calls
  Future<bool> hasActiveCalls() async {
    final result = await FlutterCallkitIncoming.activeCalls();
    final calls = result as List?;
    return calls != null && calls.isNotEmpty;
  }

  /// Get all active calls
  Future<List<dynamic>> getActiveCalls() async {
    final result = await FlutterCallkitIncoming.activeCalls();
    return result as List? ?? [];
  }

  /// End all active calls
  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
    await _clearCallInfo();
  }

  /// Update user call status
  Future<void> updateCallStatus(String status) async {
    try {
      await _callApiService.updateCallStatus(status: status);
    } catch (e) {
      debugPrint('Error updating call status: $e');
    }
  }

  /// Save call info to SharedPreferences for potential resuming
  Future<void> _saveCallInfo(
      String callId,
      String userId,
      String name,
      String avatar,
      bool hasVideo
      ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_call_id', callId);
    await prefs.setString('active_call_user_id', userId);
    await prefs.setString('active_call_name', name);
    await prefs.setString('active_call_avatar', avatar);
    await prefs.setBool('active_call_has_video', hasVideo);
  }

  /// Clear saved call info
  Future<void> _clearCallInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_call_id');
    await prefs.remove('active_call_user_id');
    await prefs.remove('active_call_name');
    await prefs.remove('active_call_avatar');
    await prefs.remove('active_call_has_video');
  }

  /// Resume call screen if app launched from callkit event
  Future<void> resumeCallScreenIfNeeded() async {
    final calls = await getActiveCalls();
    if (calls.isNotEmpty) {
      final call = calls.first;
      final callId = call['id'];
      final callerName = call['nameCaller'] ?? 'Unknown';
      final avatar = call['extra']['avatar'] ?? '';
      final userId = call['extra']['userId'] ?? '';
      final hasVideo = call['extra']['has_video'] == true || call['extra']['has_video'] == 'true';

      // Get call token from API
      try {
        final tokenResponse = await _callApiService.getCallToken(
          callId: callId,
          userId: userId,
        );

        // Ensure navigator is available before pushing the screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NavigatorService.navigatorKey.currentState?.push(MaterialPageRoute(
            builder: (context) => CallScreen(
              callId: callId,
              contactId: userId,
              contactName: callerName,
              contactAvatar: avatar,
              isIncoming: true,
              isVideoCall: hasVideo,
              token: tokenResponse['token'],
            ),
          ));
        });
      } catch (e) {
        debugPrint('Error resuming call: $e');
      }
    } else {
      // Check if we have saved call info
      final prefs = await SharedPreferences.getInstance();
      final savedCallId = prefs.getString('active_call_id');

      if (savedCallId != null) {
        final userId = prefs.getString('active_call_user_id') ?? '';
        final name = prefs.getString('active_call_name') ?? 'Unknown';
        final avatar = prefs.getString('active_call_avatar') ?? '';
        final hasVideo = prefs.getBool('active_call_has_video') ?? false;

        try {
          final tokenResponse = await _callApiService.getCallToken(
            callId: savedCallId,
            userId: userId,
          );

          // Ensure navigator is available before pushing the screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NavigatorService.navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (context) => CallScreen(
                callId: savedCallId,
                contactId: userId,
                contactName: name,
                contactAvatar: avatar,
                isIncoming: true,
                isVideoCall: hasVideo,
                token: tokenResponse['token'],
              ),
            ));
          });
        } catch (e) {
          debugPrint('Error resuming saved call: $e');
          // Clear saved call info if we failed to resume
          await _clearCallInfo();
        }
      }
    }
  }
}