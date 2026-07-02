import 'dart:async';
import 'package:flutter/material.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/core/utils/call_permission_handler.dart';
import 'package:doctak_app/presentation/calling_module/services/callkit_service.dart';
import 'package:doctak_app/presentation/calling_module/services/call_api_service.dart';
import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/data/apiClient/services/communication_service.dart';
import 'package:doctak_app/widgets/communication/communication_restriction_sheet.dart';

import '../../user_chat_screen/chat_ui_sceen/call_loading_screen.dart';

Future<void> startOutgoingCall(String userId, String username, String profilePic, bool isVideoCall) async {
  final context = NavigatorService.navigatorKey.currentState?.context;

  if (context != null) {
    final permission = await CommunicationService().checkPermission(userId);
    if (!permission.canCall) {
      if (context.mounted) {
        CommunicationRestrictionSheet.show(
          context: context,
          permission: permission,
          targetUserName: username,
          targetUserId: userId,
        );
      }
      return;
    }
  }

  if (context != null) {
    final hasPermissions = await callPermissionHandler.hasCallPermissions(isVideoCall: isVideoCall);

    if (!hasPermissions) {
      final granted = await callPermissionHandler.requestWithUI(context, isVideoCall: isVideoCall, showRationale: true);
      if (!granted) return;
    }
  }

  final GlobalKey<CallLoadingScreenState> loadingScreenKey = GlobalKey<CallLoadingScreenState>();
  String? callId;
  bool callAccepted = false;
  bool callNavigatedToScreen = false;
  bool isCleanedUp = false;
  Timer? pollingTimer;

  Future<void> cleanupResources({bool forceEnd = false}) async {
    if (isCleanedUp) return;
    isCleanedUp = true;

    pollingTimer?.cancel();
    pollingTimer = null;

    if (callAccepted && callNavigatedToScreen && !forceEnd) {
      return;
    }

    final currentCallId = callId;
    if (currentCallId != null && !callAccepted) {
      try {
        final apiService = CallApiService(baseUrl: AppData.remoteUrl3);
        await apiService.cancelCall(callId: currentCallId, calleeId: userId);
      } catch (_) {}
    }

    if (!callAccepted || forceEnd) {
      try {
        if (callId != null) {
          CallKitService().forceEndOutgoingCall(callId);
        } else {
          CallKitService().endAllCalls();
        }
      } catch (_) {}
    }
  }

  void navigateToCallScreen(Map<String, dynamic> callData) {
    if (callNavigatedToScreen) return;
    callAccepted = true;
    callNavigatedToScreen = true;
    pollingTimer?.cancel();

    loadingScreenKey.currentState?.updateStatus(CallStatus.accepted);

    NavigatorService.navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/call'),
        builder: (context) => CallScreen(
          callId: callId!,
          contactId: userId,
          contactName: username,
          contactAvatar: AppData.fullImageUrl(profilePic),
          isIncoming: false,
          isVideoCall: isVideoCall,
          token: callData['token']?.toString(),
        ),
      ),
    );
  }

  void processCallStatus(String status) {
    if (isCleanedUp || callNavigatedToScreen) return;
    final normalizedStatus = status.toLowerCase().trim();

    switch (normalizedStatus) {
      case 'calling':
        break;
      case 'ringing':
        loadingScreenKey.currentState?.updateStatus(CallStatus.ringing);
        break;
      case 'accepted':
        navigateToCallScreen({});
        break;
      case 'rejected':
        loadingScreenKey.currentState?.updateStatus(CallStatus.rejected);
        _popAfterDelay(cleanupResources);
        break;
      case 'busy':
        loadingScreenKey.currentState?.updateStatus(CallStatus.busy);
        _popAfterDelay(cleanupResources);
        break;
      case 'no_answer':
      case 'noanswer':
      case 'no-answer':
      case 'unanswered':
        loadingScreenKey.currentState?.updateStatus(CallStatus.timeout);
        _popAfterDelay(cleanupResources);
        break;
      case 'ended':
      case 'missed':
      case 'cancelled':
        if (!callNavigatedToScreen) {
          loadingScreenKey.currentState?.updateStatus(CallStatus.timeout);
          _popAfterDelay(cleanupResources);
        }
        break;
      case 'offline':
        loadingScreenKey.currentState?.updateStatus(CallStatus.offline);
        _popAfterDelay(cleanupResources);
        break;
    }
  }

  NavigatorService.navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => CallLoadingScreen(
        key: loadingScreenKey,
        contactName: username,
        contactAvatar: AppData.fullImageUrl(profilePic),
        isVideoCall: isVideoCall,
        onCancel: () {
          Navigator.of(context).pop();
          cleanupResources();
        },
      ),
    ),
  );

  try {
    Map<String, dynamic> callData;

    try {
      loadingScreenKey.currentState?.updateStatus(CallStatus.calling);
      final response = await CallKitService().startOutgoingCall(
        userId: userId,
        calleeName: username,
        avatar: AppData.fullImageUrl(profilePic),
        hasVideo: isVideoCall,
      );
      callData = response;
    } catch (e) {
      rethrow;
    }

    if (callData['success'] == true && callData['callId'] != null) {
      callId = callData['callId'].toString();

      final apiService = CallApiService(baseUrl: AppData.remoteUrl3);
      pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (callAccepted || isCleanedUp || callNavigatedToScreen) {
          timer.cancel();
          return;
        }

        try {
          final result = await apiService.checkCallActive(callId: callId!);
          final polledStatus = result['status']?.toString();

          if (polledStatus != null && polledStatus != 'not_found') {
            processCallStatus(polledStatus);
          }

          if (result['is_active'] != true && polledStatus != 'ringing' && polledStatus != 'accepted') {
            if (polledStatus != null) {
              processCallStatus(polledStatus);
            }
          }
        } catch (_) {}
      });

      Future.delayed(const Duration(seconds: 30), () {
        if (callAccepted || isCleanedUp || callNavigatedToScreen) return;

        final currentStatus = loadingScreenKey.currentState?.status;
        if (currentStatus == CallStatus.ringing || currentStatus == CallStatus.calling) {
          loadingScreenKey.currentState?.updateStatus(CallStatus.timeout);
          _popAfterDelay(cleanupResources);
        }
      });
    } else {
      NavigatorService.navigatorKey.currentState?.pop();
      _showCallError(translation(NavigatorService.navigatorKey.currentState!.context).lbl_failed_to_establish_call);
      cleanupResources();
    }
  } catch (error) {
    NavigatorService.navigatorKey.currentState?.pop();
    _showCallError(translation(NavigatorService.navigatorKey.currentState!.context).lbl_error_starting_call);
    cleanupResources();
  }
}

void _popAfterDelay(Future<void> Function() cleanup) {
  Future.delayed(const Duration(seconds: 2), () {
    NavigatorService.navigatorKey.currentState?.pop();
    cleanup();
  });
}

void _showCallError(String message) {
  final context = NavigatorService.navigatorKey.currentState?.overlay?.context;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, duration: const Duration(seconds: 3)),
    );
  }
}
