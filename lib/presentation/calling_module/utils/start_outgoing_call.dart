import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/core/utils/call_permission_handler.dart';
import 'package:doctak_app/core/utils/pusher_service.dart';
import 'package:doctak_app/presentation/calling_module/services/callkit_service.dart';
import 'package:doctak_app/presentation/calling_module/services/call_api_service.dart';
import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
import 'package:doctak_app/localization/app_localization.dart';
import 'package:doctak_app/data/apiClient/services/communication_service.dart';
import 'package:doctak_app/widgets/communication/communication_restriction_sheet.dart';

import '../../user_chat_screen/chat_ui_sceen/call_loading_screen.dart';

// Use PusherService singleton which handles initialization and connection
PusherService get pusherService => PusherService();

Future<void> startOutgoingCall(String userId, String username, String profilePic, bool isVideoCall) async {
  // Get the current context for permission dialogs
  final context = NavigatorService.navigatorKey.currentState?.context;

  // ── Communication permission check (connection + block) ──
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

  // Check and request permissions before starting the call
  if (context != null) {
    final hasPermissions = await callPermissionHandler.hasCallPermissions(isVideoCall: isVideoCall);

    if (!hasPermissions) {
      // Request permissions with professional UI
      final granted = await callPermissionHandler.requestWithUI(context, isVideoCall: isVideoCall, showRationale: true);

      if (!granted) {
        // User denied permissions, don't start the call
        return;
      }
    }
  }

  // Create a key to access the loading screen state
  final GlobalKey<CallLoadingScreenState> loadingScreenKey = GlobalKey<CallLoadingScreenState>();

  // Reference to the Pusher channel name
  String? channelName;
  String? callId;

  // Track if call was accepted - don't force end accepted calls
  bool callAccepted = false;
  bool callNavigatedToScreen = false;
  bool isCleanedUp = false;

  // Polling timer for API fallback
  Timer? pollingTimer;

  // List of registered listener references for clean unregistration
  final List<_ListenerEntry> registeredListeners = [];

  // Function to clean up resources (only for failed/cancelled calls)
  Future<void> cleanupResources({bool forceEnd = false}) async {
    if (isCleanedUp) return;
    isCleanedUp = true;

    debugPrint('📞 cleanupResources() called - callAccepted: $callAccepted, forceEnd: $forceEnd');

    // Cancel polling timer
    pollingTimer?.cancel();
    pollingTimer = null;

    // Don't cleanup if call was accepted and navigated to call screen
    if (callAccepted && callNavigatedToScreen && !forceEnd) {
      debugPrint('📞 Skipping cleanup - call was accepted and is active');
      // Still unregister Pusher listeners
      _unregisterAllListeners(registeredListeners);
      return;
    }

    // Notify server that caller is cancelling the call
    final currentCallId = callId;
    if (currentCallId != null && !callAccepted) {
      try {
        final apiService = CallApiService(baseUrl: AppData.remoteUrl3);
        await apiService.cancelCall(callId: currentCallId, calleeId: userId);
        debugPrint('📞 Server notified of call cancellation');
      } catch (e) {
        debugPrint('📞 Error notifying server of cancellation: $e');
      }
    }

    // Unregister all Pusher listeners
    _unregisterAllListeners(registeredListeners);

    // Unsubscribe from Pusher channel if needed
    final currentChannel = channelName;
    if (currentChannel != null) {
      try {
        pusherService.unsubscribeFromChannel(currentChannel);
        debugPrint('📞 Unsubscribed from Pusher channel: $channelName');
      } catch (e) {
        debugPrint('📞 Error unsubscribing from Pusher: $e');
      }
    }

    // Only end calls if they weren't accepted or if forced
    if (!callAccepted || forceEnd) {
      try {
        if (callId != null) {
          CallKitService().forceEndOutgoingCall(callId);
        } else {
          CallKitService().endAllCalls();
        }
      } catch (e) {
        debugPrint('📞 Error ending calls during cleanup: $e');
      }
    }
  }

  // ── Navigate to CallScreen helper ───────────────────────────────
  void navigateToCallScreen(Map<String, dynamic> callData) {
    if (callNavigatedToScreen) return;
    callAccepted = true;
    callNavigatedToScreen = true;
    pollingTimer?.cancel();

    loadingScreenKey.currentState?.updateStatus(CallStatus.accepted);
    debugPrint('📞 Navigating to CallScreen with callId: $callId');

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

  // ── Process status from any source (Pusher or polling) ──────────
  void processCallStatus(String status) {
    if (isCleanedUp || callNavigatedToScreen) return;
    final normalizedStatus = status.toLowerCase().trim();
    debugPrint('📞 processCallStatus: $normalizedStatus');

    switch (normalizedStatus) {
      case 'calling':
        // Still in calling phase - callee hasn't received notification yet
        // Keep showing "Calling..." (no change needed)
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

  // ── Unified Pusher event handler ────────────────────────────────
  void handleCallEvent(dynamic eventData) {
    debugPrint('📞 handleCallEvent received: $eventData (${eventData.runtimeType})');

    Map<String, dynamic> eventDataMap = {};
    if (eventData is Map<String, dynamic>) {
      eventDataMap = eventData;
    } else if (eventData is Map) {
      eventDataMap = Map<String, dynamic>.from(eventData);
    } else if (eventData is String) {
      try {
        eventDataMap = jsonDecode(eventData);
      } catch (e) {
        debugPrint('📞 Error parsing event data: $e');
        return;
      }
    }

    // Extract call status from different possible locations
    String? callStatus;
    for (final key in ['callData', 'statusData', 'data']) {
      if (callStatus != null) break;
      final nested = eventDataMap[key];
      if (nested is Map) {
        callStatus = nested['status']?.toString() ?? nested['call_status']?.toString();
      }
    }
    callStatus ??= eventDataMap['status']?.toString() ?? eventDataMap['call_status']?.toString();

    if (callStatus != null) processCallStatus(callStatus);
  }

  // Show calling screen immediately
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
    // Initialize call in the background with proper error handling
    Map<String, dynamic> callData;

    try {
      loadingScreenKey.currentState?.updateStatus(CallStatus.calling);

      debugPrint('📞 Calling CallKitService().startOutgoingCall...');
      final response = await CallKitService().startOutgoingCall(
        userId: userId,
        calleeName: username,
        avatar: AppData.fullImageUrl(profilePic),
        hasVideo: isVideoCall,
      );
      debugPrint('📞 CallKitService response: $response');
      callData = response;
    } catch (e) {
      debugPrint('📞 Error calling CallKitService.startOutgoingCall: $e');
      rethrow;
    }

    // Handle success - subscribe to Pusher for call status updates
    if (callData['success'] == true && callData['callId'] != null) {
      callId = callData['callId'].toString();
      debugPrint('📞 Call initiated successfully with callId: $callId');

      // ── Subscribe to Pusher ──
      try {
        channelName = "user.${AppData.logInUserId}";
        debugPrint('📞 Subscribing to Pusher channel: $channelName');

        if (!pusherService.isConnected) {
          await pusherService.initialize();
          await pusherService.connect();
          await Future.delayed(const Duration(milliseconds: 500));
        }

        await pusherService.subscribeToChannel(channelName);
        await Future.delayed(const Duration(milliseconds: 300));

        // Register consolidated event listeners
        void registerListener(String event, Function(dynamic) cb) {
          pusherService.registerEventListener(event, cb);
          registeredListeners.add(_ListenerEntry(event, cb));
        }

        // Ringing event — dedicated handler
        registerListener('call.ringing', (data) {
          debugPrint('📞 Received call.ringing event');
          processCallStatus('ringing');
        });

        // Status events — unified handler
        registerListener('call.status', handleCallEvent);

        // Accepted events — direct handlers
        registerListener('call.accepted', (data) {
          debugPrint('📞 Received call.accepted event');
          processCallStatus('accepted');
        });

        // Busy / ended events
        registerListener('call.busy', (data) {
          debugPrint('📞 Received call.busy event');
          processCallStatus('busy');
        });

        registerListener('call.ended', (data) {
          debugPrint('📞 Received call.ended event');
          if (!callNavigatedToScreen) processCallStatus('ended');
        });
      } catch (e) {
        debugPrint('📞 Error subscribing to Pusher: $e');
      }

      // ── API Polling fallback every 3 seconds ──
      // Covers cases where Pusher events are missed or delayed
      final apiService = CallApiService(baseUrl: AppData.remoteUrl3);
      pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (callAccepted || isCleanedUp || callNavigatedToScreen) {
          timer.cancel();
          return;
        }

        try {
          final result = await apiService.checkCallActive(callId: callId!);
          final polledStatus = result['status']?.toString();
          debugPrint('📞 Poll result: status=$polledStatus, is_active=${result['is_active']}');

          if (polledStatus != null && polledStatus != 'not_found') {
            processCallStatus(polledStatus);
          }

          // If call is no longer active and not accepted, it was probably rejected/ended
          if (result['is_active'] != true && polledStatus != 'ringing' && polledStatus != 'accepted') {
            if (polledStatus != null) {
              processCallStatus(polledStatus);
            }
          }
        } catch (e) {
          debugPrint('📞 Polling error: $e');
        }
      });

      // ── 30-second timeout ──
      Future.delayed(const Duration(seconds: 30), () {
        if (callAccepted || isCleanedUp || callNavigatedToScreen) return;

        final currentStatus = loadingScreenKey.currentState?.status;
        if (currentStatus == CallStatus.ringing || currentStatus == CallStatus.calling) {
          debugPrint('📞 Call timeout after 30 seconds');
          loadingScreenKey.currentState?.updateStatus(CallStatus.timeout);
          _popAfterDelay(cleanupResources);
        }
      });
    } else {
      // Handle API error
      NavigatorService.navigatorKey.currentState?.pop();
      _showCallError(translation(NavigatorService.navigatorKey.currentState!.context).lbl_failed_to_establish_call);
      cleanupResources();
    }
  } catch (error) {
    debugPrint('📞 Error starting outgoing call: $error');
    NavigatorService.navigatorKey.currentState?.pop();
    _showCallError(translation(NavigatorService.navigatorKey.currentState!.context).lbl_error_starting_call);
    cleanupResources();
  }
}

// ── Helper: pop loading screen after a delay ──
void _popAfterDelay(Future<void> Function() cleanup) {
  Future.delayed(const Duration(seconds: 2), () {
    if (NavigatorService.navigatorKey.currentState != null) {
      NavigatorService.navigatorKey.currentState?.pop();
    }
    cleanup();
  });
}

// ── Helper: unregister all Pusher listeners ──
void _unregisterAllListeners(List<_ListenerEntry> entries) {
  for (final entry in entries) {
    try {
      pusherService.unregisterEventListener(entry.event, entry.callback);
    } catch (_) {}
  }
  entries.clear();
}

// ── Simple class to track registered listeners ──
class _ListenerEntry {
  final String event;
  final Function(dynamic) callback;
  _ListenerEntry(this.event, this.callback);
}

// Helper function to show call errors
void _showCallError(String message) {
  final context = NavigatorService.navigatorKey.currentState?.overlay?.context;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red, duration: Duration(seconds: 3)));
  }
}
