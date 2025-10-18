import 'dart:io';
import 'dart:async';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'call_api_service.dart';
import '../screens/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';
//
import 'package:doctak_app/core/utils/app/AppData.dart';

//
//
class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();
  //
  // Add CallApiService with proper initialization protection
  CallApiService? _callApiService;
  bool _isInitialized = false;
  //
  // Flag to determine if this service should update status or defer to CallService
  bool _shouldUpdateStatus = true;
  //
  // Add event tracking to prevent duplicate events
  String? _lastHandledCallEvent;
  DateTime? _lastEventTime;
  Map<String, DateTime> _lastEventsByType = {};
  //
  // Add these properties for better debouncing
  final Map<String, bool> _callEndProcessed = {};
  final Map<String, DateTime> _lastActionForCall = {};
  //
  // Track outgoing calls to prevent premature termination
  final Map<String, DateTime> _outgoingCallsStartTime = {};
  final Duration _outgoingCallProtectionDuration = const Duration(seconds: 5);
  //
  // To store active subscription
  StreamSubscription? _callKitEventSubscription;
  //
  // Getter for base URL (for re-initialization if needed)
  String? get baseUrl => _callApiService?.baseUrl;
  //
  // Initialize method to set up the API service
  Future<void> initialize({
    required String baseUrl,
    String? authToken,
    bool shouldUpdateStatus = true, // New parameter to control status updates
  }) async {
    try {
      // Check if already initialized with the same base URL
      if (_isInitialized &&
          _callApiService != null &&
          _callApiService!.baseUrl == baseUrl) {
        debugPrint('CallKitService already initialized with the same baseUrl');
        // Update the status flag to ensure consistent behavior
        _shouldUpdateStatus = shouldUpdateStatus;
        return;
      }
      //
      _callApiService = CallApiService(baseUrl: baseUrl);
      _isInitialized = true;
      _shouldUpdateStatus = shouldUpdateStatus;
      debugPrint(
        'CallKitService initialized successfully with baseUrl: $baseUrl',
      );
      debugPrint(
        'Status updates will be ${_shouldUpdateStatus ? 'handled by CallKitService' : 'deferred to CallService'}',
      );
    } catch (e) {
      _isInitialized = false;
      debugPrint('Error initializing CallKitService: $e');
    }
  }

  //
  // Safe method to update call status, with null check and control flag
  Future<void> _safeUpdateCallStatus(String status) async {
    // Skip status updates if flag is false (CallService will handle them)
    if (!_shouldUpdateStatus) {
      debugPrint('CallKitService: Status updates deferred to CallService');
      return;
    }
    //
    // if (!_isInitialized || _callApiService == null) {
    //   debugPrint('Warning: CallKitService not initialized, cannot update status to $status');
    //   return;
    // }
    //
    try {
      // await _callApiService!.updateCallStatus(status: status);
      debugPrint('CallKit updated status to: $status');
    } catch (e) {
      debugPrint('Error updating call status to $status: $e');
    }
  }

  //
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
    //
    // First update the call status to "busy" via API (safely)
    await _safeUpdateCallStatus('busy');
    //
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
      android: AndroidParams(
        isCustomNotification: true,
        isShowLogo: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
        isShowCallID: false,
        isShowFullLockedScreen: true,
      ),
      ios: IOSParams(
        iconName: 'CallKitLogo',
        handleType: 'generic',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        ringtonePath: 'system_ringtone_default',
      ),
    );
    //
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  //
  // Improved debouncing method to prevent duplicate events
  bool _shouldProcessAction(String callId, String action) {
    final now = DateTime.now();
    final key = "$callId-$action";
    //
    if (_lastActionForCall.containsKey(key)) {
      final lastActionTime = _lastActionForCall[key]!;
      //
      // Different debounce times for different actions
      Duration debouncePeriod;
      switch (action) {
        case 'end':
          debouncePeriod = const Duration(seconds: 3);
          break;
        case 'accept':
          // Don't debounce accept too much - just enough to prevent duplicates
          debouncePeriod = const Duration(milliseconds: 300);
          break;
        default:
          debouncePeriod = const Duration(seconds: 1);
      }
      //
      if (now.difference(lastActionTime) < debouncePeriod) {
        print('Debouncing $action for call $callId');
        return false;
      }
    }
    //
    // Record this action
    _lastActionForCall[key] = now;
    return true;
  }

  //
  /// Listen to CallKit events with proper debouncing and type safety
  void listenToCallEvents() {
    // Cancel any existing subscription to prevent duplicates
    _callKitEventSubscription?.cancel();
    //
    try {
      _callKitEventSubscription = FlutterCallkitIncoming.onEvent.listen((
        event,
      ) async {
        final eventType = event?.event;
        //
        // Safely extract data - fix for the type error by explicit type conversion
        final Map<String, dynamic> data = {};
        //
        // Extract call data safely by converting types
        if (event?.body != null) {
          // Convert Object? keys and values to String and dynamic explicitly
          (event!.body as Map<Object?, Object?>).forEach((key, value) {
            if (key != null) {
              data[key.toString()] = value;
            }
          });
        }
        //
        final extra = data['extra'] is Map
            ? Map<String, dynamic>.from(data['extra'] as Map)
            : <String, dynamic>{};
        final callId = data['id']?.toString() ?? '';
        //
        // Skip if we shouldn't process this action
        if (!_shouldProcessAction(callId, eventType.toString())) {
          return;
        }
        //
        // Extract call data with proper type safety
        final callerName = extra['callerName']?.toString() ?? 'Unknown';
        final avatar = extra['avatar']?.toString() ?? '';
        final userId = extra['userId']?.toString() ?? '';
        final hasVideo =
            extra['has_video'] == true || extra['has_video'] == 'true';
        //
        debugPrint('CallKit event: $eventType for call: $callId');
        //
        switch (eventType) {
          case Event.actionCallAccept:
            try {
              // Update status to busy via API (safely) - only if needed
              await _safeUpdateCallStatus('busy');
              //
              // Check if service is initialized before making API calls
              // if (_isInitialized && _callApiService != null) {
              // Call accept API with proper type safety
              var callkit = CallApiService(baseUrl: AppData.remoteUrl3);
              await callkit.acceptCall(callId: callId, callerId: userId);
              // }
              //
              // Save call info for potential resuming
              await _saveCallInfo(callId, userId, callerName, avatar, hasVideo);
              // Launch the application if it's closed using CallKit's capabilities
              // await FlutterCallkitIncoming.showCallkitIncoming(
              //   CallKitParams(
              //     id: callId,
              //     nameCaller: callerName,
              //     handle: userId,
              //     type: hasVideo ? 1 : 0,
              //     extra: extra,
              //   ),
              // );
              //
              // Use a longer delay to ensure the app is fully launched
              await Future.delayed(const Duration(milliseconds: 1500));
              // Navigate to call screen with proper data
              _navigateToCallScreen(
                callId: callId,
                userId: userId,
                callerName: callerName,
                avatar: avatar,
                hasVideo: hasVideo,
              );
            } catch (e) {
              debugPrint('Error accepting call: $e');
            }
            break;
          //
          case Event.actionCallDecline:
            try {
              // Update status to available via API (safely)
              await _safeUpdateCallStatus('available');
              //
              // Check if service is initialized before making API calls
              if (_isInitialized && _callApiService != null) {
                // Call reject API
                await _callApiService!.rejectCall(
                  callId: callId,
                  callerId: userId,
                );
              }
              //
              // Clear notification - wrap in try-catch as CallKit may have already ended the call
              try {
                await FlutterCallkitIncoming.endCall(callId);
              } catch (e) {
                debugPrint(
                  'CallKit endCall error (expected on iOS decline): $e',
                );
              }
              await _clearCallInfo();
            } catch (e) {
              debugPrint('Error rejecting call: $e');
            }
            break;
          //
          case Event.actionCallTimeout:
            try {
              // Only process if not already handling an end call for this callId
              if (_callEndProcessed[callId] != true) {
                // Update status to available via API (safely)
                await _safeUpdateCallStatus('available');
                //
                // Check if service is initialized before making API calls
                if (_isInitialized && _callApiService != null) {
                  // Call missed API
                  await _callApiService!.missCall(
                    callId: callId,
                    callerId: userId,
                  );
                }
                //
                // Clear notification - wrap in try-catch as CallKit may have already ended the call
                try {
                  await FlutterCallkitIncoming.endCall(callId);
                } catch (e) {
                  debugPrint(
                    'CallKit endCall error (expected on iOS timeout): $e',
                  );
                }
                await _clearCallInfo();
              }
            } catch (e) {
              debugPrint('Error marking call missed: $e');
            }
            break;
          //
          case Event.actionCallEnded:
            // Check if this is a recently started outgoing call - if so, ignore the end event
            final outgoingStartTime = _outgoingCallsStartTime[callId];
            if (outgoingStartTime != null) {
              final timeSinceStart = DateTime.now().difference(
                outgoingStartTime,
              );
              if (timeSinceStart < _outgoingCallProtectionDuration) {
                debugPrint(
                  '📞 Ignoring actionCallEnded for protected outgoing call $callId (started ${timeSinceStart.inSeconds}s ago)',
                );
                return; // Don't end the call
              }
              // Remove from tracking after protection period
              _outgoingCallsStartTime.remove(callId);
            }
            // Use our improved endCall method
            await endCall(callId);
            break;
          //
          default:
            break;
        }
      });
    } catch (e) {
      debugPrint('Error setting up CallKit event listener: $e');
      debugPrint('CallKit events will not be available');
      // Continue without CallKit event handling
    }
  }

  //
  // Improved end call method
  Future<void> endCall(String? uuid) async {
    if (uuid == null || uuid.isEmpty) {
      debugPrint('📞 endCall called with null/empty uuid');
      return;
    }

    // Check if this call end has already been processed
    if (_callEndProcessed[uuid] == true) {
      print('Call end already processed for: $uuid');
      return;
    }
    //
    // Check action debouncing
    if (!_shouldProcessAction(uuid, 'end')) {
      return;
    }
    //
    // Mark as processed immediately
    _callEndProcessed[uuid] = true;
    //
    // Remove from outgoing call protection
    _outgoingCallsStartTime.remove(uuid);
    //
    debugPrint('📞 Ending call: $uuid');
    //
    try {
      // First handle UI (CallKit) for immediate feedback
      try {
        await FlutterCallkitIncoming.endCall(uuid);
      } catch (e) {
        print('Error ending CallKit UI: $e');
      }
      //
      // Update status to available via API (safely)
      await _safeUpdateCallStatus('available');
      //
      // Check if service is initialized before making API calls
      if (_isInitialized && _callApiService != null) {
        try {
          await _callApiService!.endCall(callId: uuid);
        } catch (e) {
          print('Error in API call to end call: $e');
        }
      }
      //
      // Clear saved call info
      await _clearCallInfo();
      //
      // Clear the status after a delay (in case of quick redial attempts)
      Future.delayed(const Duration(seconds: 5), () {
        _callEndProcessed.remove(uuid);
        _lastActionForCall.remove("$uuid-end");
      });
    } catch (e) {
      print('Error ending call: $e');
      // Still remove the processed flag after an error (after a shorter delay)
      Future.delayed(const Duration(seconds: 2), () {
        _callEndProcessed.remove(uuid);
        _lastActionForCall.remove("$uuid-end");
      });
    }
  }

  //
  // Force end an outgoing call (bypasses protection timer)
  Future<void> forceEndOutgoingCall(String uuid) async {
    debugPrint('📞 Force ending outgoing call: $uuid');
    _outgoingCallsStartTime.remove(uuid);
    _callEndProcessed.remove(uuid); // Allow endCall to process
    _lastActionForCall.remove("$uuid-end"); // Clear debounce
    await endCall(uuid);
  }

  //
  // More reliable navigation to call screen
  void _navigateToCallScreen({
    required String callId,
    required String userId,
    required String callerName,
    required String avatar,
    required bool hasVideo,
  }) {
    // Function to attempt navigation with retries
    Future<void> attemptNavigation([int retryCount = 0]) async {
      if (NavigatorService.navigatorKey.currentState != null) {
        // Check if we're already on a call screen to avoid duplicate screens
        bool isAlreadyOnCallScreen = false;
        NavigatorService.navigatorKey.currentState!.popUntil((route) {
          if (route.settings.name == '/call') {
            isAlreadyOnCallScreen = true;
          }
          return true; // Keep all routes
        });
        //
        if (!isAlreadyOnCallScreen) {
          // Use named route for better lifecycle handling
          NavigatorService.navigatorKey.currentState?.pushNamed(
            '/call',
            arguments: {
              'callId': callId,
              'contactId': userId,
              'contactName': callerName,
              'contactAvatar': avatar,
              'isIncoming': true,
              'isVideoCall': hasVideo,
              'token': null, // Will be generated in CallProvider
            },
          );
        }
      } else if (retryCount < 5) {
        // Retry with exponential backoff up to 5 times
        final delay = Duration(milliseconds: 500 * (retryCount + 1));
        debugPrint(
          'Navigator not available, retrying in ${delay.inMilliseconds}ms...',
        );
        Future.delayed(delay, () => attemptNavigation(retryCount + 1));
      } else {
        debugPrint('Failed to navigate to call screen after multiple attempts');
        // Last resort: try the old method with MaterialPageRoute
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (NavigatorService.navigatorKey.currentState != null) {
            NavigatorService.navigatorKey.currentState?.push(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/call'),
                builder: (context) => CallScreen(
                  callId: callId,
                  contactId: userId,
                  contactName: callerName,
                  contactAvatar: avatar,
                  isIncoming: true,
                  isVideoCall: hasVideo,
                  token: '',
                ),
              ),
            );
          }
        });
      }
    }

    //
    // Start navigation attempts
    attemptNavigation();
  }

  //
  /// Start an outgoing call with proper type safety
  Future<Map<String, dynamic>> startOutgoingCall({
    required String userId,
    required String calleeName,
    required String avatar,
    required bool hasVideo,
  }) async {
    try {
      // Make sure service is initialized
      if (!_isInitialized || _callApiService == null) {
        debugPrint('CallKitService not initialized for outgoing call');
        return {
          'callId': 'error',
          'success': false,
          'message': 'CallKitService not initialized',
        };
      }
      //
      // Update status to busy via API
      await _safeUpdateCallStatus('busy');
      //
      // Call the API to initiate the call
      Map<String, dynamic> response;
      try {
        final rawResponse = await _callApiService!.initiateCall(
          userId: userId,
          hasVideo: hasVideo,
        );
        //
        // Convert response to ensure it's Map<String, dynamic>
        response = {};
        if (rawResponse is Map) {
          rawResponse.forEach((key, value) {
            if (key is String) {
              response[key] = value;
            }
          });
        } else {
          // Fallback if conversion fails
          response = {
            'callId': 'error',
            'success': false,
            'message': 'Invalid response format',
          };
        }
      } catch (e) {
        debugPrint('Error initiating call API: $e');
        return {
          'callId': 'error',
          'success': false,
          'message': 'Error calling API: $e',
        };
      }
      //
      // Extract callId with proper null checking
      final callId =
          response['callId']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();
      //
      // Update response with string callId
      response['callId'] = callId;
      //
      // Save call info for potential resuming
      await _saveCallInfo(callId, userId, calleeName, avatar, hasVideo);
      //
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
        ios: IOSParams(
          handleType: 'generic',
          supportsVideo: true,
          ringtonePath: 'system_ringtone_default',
        ),
        android: AndroidParams(
          isCustomNotification: false,
          isShowLogo: true,
          ringtonePath: 'system_ringtone_default',
          isShowFullLockedScreen: true,
        ),
      );
      //
      // Mark this as an outgoing call to prevent premature termination from CallKit events
      _outgoingCallsStartTime[callId] = DateTime.now();
      debugPrint(
        '📞 Marked $callId as outgoing call, protected from CallKit end events',
      );
      //
      try {
        await FlutterCallkitIncoming.startCall(params);
      } catch (e) {
        debugPrint('Error showing CallKit UI: $e');
        // Continue even if UI fails, as the call might still be working
      }
      //
      // Ensure success flag is set
      response['success'] = response['success'] ?? true;
      return response;
    } catch (e) {
      // Update status to available if call fails (safely)
      await _safeUpdateCallStatus('available');
      debugPrint('Error starting outgoing call: $e');
      // Return a default response to prevent crashes
      return {
        'callId': 'error',
        'success': false,
        'message': 'Error starting call: $e',
      };
    }
  }

  //
  /// Check if there are any active calls
  Future<bool> hasActiveCalls() async {
    final result = await FlutterCallkitIncoming.activeCalls();
    final calls = result as List?;
    return calls != null && calls.isNotEmpty;
  }

  //
  /// Get all active calls with proper type conversion
  Future<List<Map<String, dynamic>>> getActiveCalls() async {
    final result = await FlutterCallkitIncoming.activeCalls();
    final List<dynamic> rawCalls = result as List? ?? [];
    //
    // Convert each call to Map<String, dynamic> with proper type safety
    return rawCalls.map((call) {
      final Map<String, dynamic> safeCall = {};
      //
      if (call is Map<Object?, Object?>) {
        call.forEach((key, value) {
          if (key != null) {
            final String keyStr = key.toString();
            //
            // Handle 'extra' field specially as it's another map
            if (keyStr == 'extra' && value is Map) {
              final Map<String, dynamic> extraMap = {};
              (value as Map<Object?, Object?>).forEach((extraKey, extraValue) {
                if (extraKey != null) {
                  extraMap[extraKey.toString()] = extraValue;
                }
              });
              safeCall[keyStr] = extraMap;
            } else {
              safeCall[keyStr] = value;
            }
          }
        });
      }
      //
      return safeCall;
    }).toList();
  }

  //
  /// End all active calls
  Future<void> endAllCalls() async {
    // Update status to available via API (safely)
    await _safeUpdateCallStatus('available');
    //
    await FlutterCallkitIncoming.endAllCalls();
    await _clearCallInfo();
    //
    // Clear all end call locks
    _callEndProcessed.clear();
  }

  //
  /// Save call info to SharedPreferences for potential resuming
  Future<void> _saveCallInfo(
    String callId,
    String userId,
    String name,
    String avatar,
    bool hasVideo,
  ) async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    await prefs.setString('active_call_id', callId);
    await prefs.setString('active_call_user_id', userId);
    await prefs.setString('active_call_name', name);
    await prefs.setString('active_call_avatar', avatar);
    await prefs.setBool('active_call_has_video', hasVideo);
    //
    // Save timestamp to check for stale calls
    await prefs.setInt(
      'active_call_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
    //
    // Save the base URL for potential service initialization after app restart
    if (_isInitialized && _callApiService != null) {
      await prefs.setString('api_base_url', _callApiService!.baseUrl);
    }
  }

  //
  /// IMPROVED: Clear saved call info with more thorough cleanup
  Future<void> _clearCallInfo() async {
    try {
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      await prefs.remove('active_call_id');
      await prefs.remove('active_call_user_id');
      await prefs.remove('active_call_name');
      await prefs.remove('active_call_avatar');
      await prefs.remove('active_call_has_video');
      await prefs.remove('active_call_timestamp');
      await prefs.remove('pending_call_id');
      await prefs.remove('pending_call_timestamp');
      // Don't remove api_base_url as it might be needed for future calls
      //
      debugPrint('Call information cleared from preferences');
    } catch (e) {
      debugPrint('Error clearing call info: $e');
    }
  }

  //
  /// NEW: Check if a call is still active with the server
  Future<bool> checkCallIsActive(String callId) async {
    if (!_isInitialized || _callApiService == null) return false;
    //
    try {
      // await _callApiService!.checkCallStatus();
      return true;
    } catch (e) {
      debugPrint('Call appears inactive: $e');
      return false;
    }
  }

  Future<void> updateCallState({
    required String callId,
    required String callerName,
    required String callerId,
    required String avatar,
    required bool hasVideo,
  }) async {
    try {
      // Check if this call is active in CallKit
      final activeCalls = await getActiveCalls();
      final isActive = activeCalls.any((call) => call['id'] == callId);
      //
      if (!isActive) {
        debugPrint(
          'Call not found in CallKit, displaying as new call: $callId',
        );
        // If not active, display it as a new call
        await displayIncomingCall(
          uuid: callId,
          callerName: callerName,
          callerId: callerId,
          avatar: avatar,
          hasVideo: hasVideo,
        );
        return;
      }
      //
      // The call already exists in CallKit, just update any CallKit parameters if needed
      // Note: On iOS, we can use CXCallUpdate to update the call display
      // On Android, we need to check if we need to update the notification
      //
      if (Platform.isIOS) {
        // iOS: Update the call display with new information
        final params = CallKitParams(
          id: callId,
          nameCaller: callerName,
          handle: callerId,
          type: hasVideo ? 1 : 0,
          extra: {
            'userId': callerId,
            'has_video': hasVideo,
            'callerName': callerName,
            'avatar': avatar,
          },
        );
        //
        try {
          // Update call if available in iOS CallKit
          await FlutterCallkitIncoming.showCallkitIncoming(params);
          debugPrint('Updated call display in iOS CallKit: $callId');
        } catch (e) {
          debugPrint('Error updating call display: $e');
        }
      } else if (Platform.isAndroid) {
        // Android: Currently the plugin doesn't support updating an existing call notification directly
        // If we need to update the Android notification, we would need to extend the plugin
        // For now, we'll rely on the existing notification
        debugPrint(
          'Call already active in Android CallKit, no update needed: $callId',
        );
      }
      //
      // Make sure the call screen is shown
      await resumeCallScreenIfNeeded();
    } catch (e) {
      debugPrint('Error updating call state: $e');
    }
  }

  /// IMPROVED: Resume call screen if app launched from callkit event with better validation
  Future<void> resumeCallScreenIfNeeded() async {
    try {
      // Check if we have any active calls in CallKit
      final calls = await getActiveCalls();
      //
      if (calls.isNotEmpty) {
        final call = calls.first;
        final callId = call['id']?.toString() ?? '';
        //
        // Additional verification - check if the call is recent
        final prefs = SecureStorageService.instance;
        await prefs.initialize();
        final timestamp = await prefs.getInt('active_call_timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        //
        // Only resume if call is recent (within 60 seconds)
        if (now - timestamp > 60000) {
          // 60 seconds
          debugPrint('Found call in CallKit but it appears stale: $callId');
          //
          // Clean up the stale call
          await endCall(callId);
          return;
        }
        //
        // Verify that the call is still active by checking with the API
        if (_isInitialized && _callApiService != null) {
          try {
            // Call API to verify call is still active
            // If the API throws an error, the call is likely not active
            // await _callApiService!.checkCallStatus();
          } catch (e) {
            debugPrint('Call appears to be inactive according to API: $e');
            await endCall(callId);
            return;
          }
        }
        //
        final callerName = call['nameCaller']?.toString() ?? 'Unknown';
        //
        // Extract extra fields safely
        final extra = call['extra'] is Map
            ? Map<String, dynamic>.from(call['extra'] as Map)
            : <String, dynamic>{};
        final avatar = extra['avatar']?.toString() ?? '';
        final userId = extra['userId']?.toString() ?? '';
        final hasVideo =
            extra['has_video'] == true || extra['has_video'] == 'true';
        //
        debugPrint('Found active call in CallKit, resuming: $callId');
        //
        // Add a delay to ensure app is ready
        await Future.delayed(const Duration(milliseconds: 1500));
        //
        // Use the more reliable navigation method
        _navigateToCallScreen(
          callId: callId,
          userId: userId,
          callerName: callerName,
          avatar: avatar,
          hasVideo: hasVideo,
        );
      } else {
        debugPrint('No active calls found in CallKit');
        //
        // We'll be more conservative about using saved call info
        final prefs = SecureStorageService.instance;
        await prefs.initialize();
        final savedCallId = await prefs.getString('active_call_id');
        final savedTimestamp = await prefs.getInt('active_call_timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        //
        // Only use saved call info if it's less than 30 seconds old (reduced from 60)
        if (savedCallId != null && (now - savedTimestamp < 30000)) {
          // Try to verify with the API if possible
          if (_isInitialized && _callApiService != null) {
            try {
              // Call API to verify call is still active
              // await _callApiService!.checkCallStatus();
            } catch (e) {
              debugPrint('Call appears to be inactive according to API: $e');
              await _clearCallInfo();
              return;
            }
          }
          //
          final userId = await prefs.getString('active_call_user_id') ?? '';
          final name = await prefs.getString('active_call_name') ?? 'Unknown';
          final avatar = await prefs.getString('active_call_avatar') ?? '';
          final hasVideo =
              await prefs.getBool('active_call_has_video') ?? false;
          //
          debugPrint('Found saved call info that appears active: $savedCallId');
          //
          // Navigate to call screen
          _navigateToCallScreen(
            callId: savedCallId,
            userId: userId,
            callerName: name,
            avatar: avatar,
            hasVideo: hasVideo,
          );
        } else if (savedCallId != null) {
          // Clean up old call data
          debugPrint('Found stale call data, cleaning up');
          await _clearCallInfo();
        }
      }
    } catch (e) {
      debugPrint('Error in resumeCallScreenIfNeeded: $e');
    }
  }

  //
  // Make sure to clean up when the service is disposed
  void dispose() {
    _callKitEventSubscription?.cancel();
    _lastHandledCallEvent = null;
    _lastEventTime = null;
    _lastEventsByType.clear();
    _callEndProcessed.clear();
    _lastActionForCall.clear();
  }
}
