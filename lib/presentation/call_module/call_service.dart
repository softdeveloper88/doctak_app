import 'package:doctak_app/core/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:doctak_app/core/call_service/callkit_service.dart';
import 'package:doctak_app/presentation/call_module/call_api_service.dart';
import 'package:doctak_app/presentation/call_module/ui/call_screen.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallService extends ChangeNotifier {
  // Singleton implementation
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // Services
  final CallKitService _callKitService = CallKitService();
  late CallApiService _callApiService;

  // Call state
  bool get hasActiveCall => _activeCallId != null;
  String? _activeCallId;
  String? _activeContactId;
  bool _isCallInitializing = false;

  // Initialization
  Future<void> initialize({
    required String baseUrl,
    String? authToken,
  }) async {
    // Initialize API service
    _callApiService = CallApiService(
      baseUrl: baseUrl,
      authToken: authToken,
    );

    // Initialize CallKit service
    await _callKitService.initialize(
      baseUrl: baseUrl,
      authToken: authToken,
    );

    // Register device token with server using existing NotificationService
    await NotificationService.registerDeviceToken(_callApiService);

    // Listen to CallKit events
    _callKitService.listenToCallEvents();

    // Check for active calls after app restart
    await _callKitService.resumeCallScreenIfNeeded();

    // Update user status to available
    try {
      await _callApiService.updateCallStatus(status: 'available');
    } catch (e) {
      debugPrint('Error updating call status: $e');
    }

    debugPrint('Call service initialized');
  }

  // Update user's call status
  Future<void> updateCallStatus(String status) async {
    try {
      await _callApiService.updateCallStatus(status: status);
    } catch (e) {
      debugPrint('Error updating call status: $e');
    }
  }

  // Make an outgoing call
  Future<void> makeCall({
    required String userId,
    required String userName,
    required String userAvatar,
    required bool isVideoCall,
  }) async {
    if (_isCallInitializing || hasActiveCall) {
      debugPrint('Call already in progress or initializing');
      return;
    }

    _isCallInitializing = true;
    notifyListeners();

    try {
      // Update status to busy
      await updateCallStatus('busy');

      // Call the API to initiate the call
      final response = await _callKitService.startOutgoingCall(
        // userId: userId,
        calleeName: userName,
        avatar: userAvatar,
        hasVideo: isVideoCall, userId: userId,
      );

      final callId = response['callId'];
      _activeCallId = callId;
      _activeContactId = userId;

      // Save call info for potential resuming
      await _saveCallInfo(callId, userId, userName, userAvatar, isVideoCall);

      // Navigate to call screen for outgoing call
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NavigatorService.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              callId: callId,
              contactId: userId,
              contactName: userName,
              contactAvatar: userAvatar,
              isIncoming: false,
              isVideoCall: isVideoCall,
            ),
          ),
        );
      });

      notifyListeners();
    } catch (e) {
      debugPrint('Error making call: $e');
      // Update status back to available
      await updateCallStatus('available');
    } finally {
      _isCallInitializing = false;
      notifyListeners();
    }
  }

  // End current call
  Future<void> endCall() async {
    if (!hasActiveCall) return;

    try {
      // End the call in CallKit
      await _callKitService.endCall(_activeCallId!);

      // End the call via API
      await _callApiService.endCall(callId: _activeCallId!);

      // Update status to available
      await updateCallStatus('available');

      // Clear saved call info
      await _clearCallInfo();

      // Reset state
      _activeCallId = null;
      _activeContactId = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }

  // Handle a busy state when receiving a call while in another call
  Future<void> handleBusyCall(String callId, String callerId) async {
    try {
      await _callApiService.sendBusySignal(
        callId: callId,
        callerId: callerId,
      );
    } catch (e) {
      debugPrint('Error sending busy signal: $e');
    }
  }

  // Handle incoming call notification
  Future<void> handleIncomingCall({
    required String callId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required bool isVideoCall,
  }) async {
    try {
      // Save the call info
      await _saveCallInfo(callId, callerId, callerName, callerAvatar, isVideoCall);

      // Display the incoming call UI via CallKit
      await _callKitService.displayIncomingCall(
        uuid: callId,
        callerName: callerName,
        callerId: callerId,
        avatar: callerAvatar,
        hasVideo: isVideoCall,
      );
    } catch (e) {
      debugPrint('Error handling incoming call: $e');
    }
  }

  // Save call info to SharedPreferences for potential resuming
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

  // Clear saved call info
  Future<void> _clearCallInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_call_id');
    await prefs.remove('active_call_user_id');
    await prefs.remove('active_call_name');
    await prefs.remove('active_call_avatar');
    await prefs.remove('active_call_has_video');
  }

  // Handle app lifecycle changes
  void handleAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
      // App came to foreground
        if (!hasActiveCall) {
          // Update status to available if no active call
          await updateCallStatus('available');
        }
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      // App went to background, but don't change status if in a call
        if (!hasActiveCall) {
          // Only set to offline if we're not in a call
          await updateCallStatus('offline');
        }
        break;

      case AppLifecycleState.detached:
      // App is terminated
        if (hasActiveCall) {
          // End any active calls
          await endCall();
        } else {
          // Set status to offline
          await updateCallStatus('offline');
        }
        break;

      default:
        break;
    }
  }

  // Cleanup on app exit
  @override
  Future<void> dispose() async {
    // End any active calls
    if (hasActiveCall) {
      await endCall();
    }

    // Set status to offline
    await updateCallStatus('offline');

    super.dispose();
  }
}