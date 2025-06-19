// import 'dart:io';
// import 'dart:async';
// import 'package:doctak_app/core/utils/navigator_service.dart';
// import 'package:doctak_app/presentation/call_module/call_api_service.dart';
// import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_callkit_incoming/entities/android_params.dart';
// import 'package:flutter_callkit_incoming/entities/call_event.dart';
// import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
// import 'package:flutter_callkit_incoming/entities/ios_params.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../utils/app/AppData.dart';
//
//
// class CallKitService {
//   static final CallKitService _instance = CallKitService._internal();
//   factory CallKitService() => _instance;
//   CallKitService._internal();
//
//   // Add CallApiService with proper initialization protection
//   CallApiService? _callApiService;
//   bool _isInitialized = false;
//
//   // Flag to determine if this service should update status or defer to CallService
//   bool _shouldUpdateStatus = true;
//
//   // Add event tracking to prevent duplicate events
//   String? _lastHandledCallEvent;
//   DateTime? _lastEventTime;
//   Map<String, DateTime> _lastEventsByType = {};
//
//   // Add these properties for better debouncing
//   final Map<String, bool> _callEndProcessed = {};
//   final Map<String, DateTime> _lastActionForCall = {};
//
//   // To store active subscription
//   StreamSubscription? _callKitEventSubscription;
//
//   // Getter for base URL (for re-initialization if needed)
//   String? get baseUrl => _callApiService?.baseUrl;
//
//   // Initialize method to set up the API service
//   Future<void> initialize({
//     required String baseUrl,
//     String? authToken,
//     bool shouldUpdateStatus = true, // New parameter to control status updates
//   }) async {
//     try {
//       // Check if already initialized with the same base URL
//       if (_isInitialized && _callApiService != null && _callApiService!.baseUrl == baseUrl) {
//         debugPrint('CallKitService already initialized with the same baseUrl');
//         // Update the status flag to ensure consistent behavior
//         _shouldUpdateStatus = shouldUpdateStatus;
//         return;
//       }
//
//       _callApiService = CallApiService(
//         baseUrl: baseUrl,
//       );
//       _isInitialized = true;
//       _shouldUpdateStatus = shouldUpdateStatus;
//       debugPrint('CallKitService initialized successfully with baseUrl: $baseUrl');
//       debugPrint('Status updates will be ${_shouldUpdateStatus ? 'handled by CallKitService' : 'deferred to CallService'}');
//     } catch (e) {
//       _isInitialized = false;
//       debugPrint('Error initializing CallKitService: $e');
//     }
//   }
//
//   // Safe method to update call status, with null check and control flag
//   Future<void> _safeUpdateCallStatus(String status) async {
//     // Skip status updates if flag is false (CallService will handle them)
//     if (!_shouldUpdateStatus) {
//       debugPrint('CallKitService: Status updates deferred to CallService');
//       return;
//     }
//
//     // if (!_isInitialized || _callApiService == null) {
//     //   debugPrint('Warning: CallKitService not initialized, cannot update status to $status');
//     //   return;
//     // }
//
//     try {
//       // await _callApiService!.updateCallStatus(status: status);
//       debugPrint('CallKit updated status to: $status');
//     } catch (e) {
//       debugPrint('Error updating call status to $status: $e');
//     }
//   }
//
//   /// Display incoming call UI using CallKit
//   Future<void> displayIncomingCall({
//     required String uuid,
//     required String callerName,
//     required String callerId,
//     required String avatar,
//     required bool hasVideo,
//   }) async {
//     if (!Platform.isIOS && !Platform.isAndroid) {
//       debugPrint('CallKit is only supported on iOS and Android');
//       return;
//     }
//
//     // First update the call status to "busy" via API (safely)
//     await _safeUpdateCallStatus('busy');
//
//     final params = CallKitParams(
//       id: uuid,
//       nameCaller: callerName,
//       appName: 'Doctak.net',
//       avatar: avatar,
//       handle: callerId,
//       type: hasVideo ? 1 : 0,
//       textAccept: 'Accept',
//       textDecline: 'Decline',
//       duration: 30000,
//       extra: {
//         'userId': callerId,
//         'has_video': hasVideo,
//         'avatar': avatar,
//         'callerName': callerName,
//       },
//       android: const AndroidParams(
//         isCustomNotification: true,
//         isShowLogo: true,
//         ringtonePath: 'system_ringtone_default',
//         backgroundColor: '#0955fa',
//         actionColor: '#4CAF50',
//         textColor: '#ffffff',
//         isShowCallID: false,
//       ),
//       ios: const IOSParams(
//         iconName: 'CallKitLogo',
//         handleType: 'generic',
//         supportsVideo: true,
//         maximumCallGroups: 2,
//         maximumCallsPerCallGroup: 1,
//         audioSessionMode: 'default',
//         audioSessionActive: true,
//         audioSessionPreferredSampleRate: 44100.0,
//         audioSessionPreferredIOBufferDuration: 0.005,
//       ),
//     );
//
//     await FlutterCallkitIncoming.showCallkitIncoming(params);
//   }
//
//   // Improved debouncing method to prevent duplicate events
//   bool _shouldProcessAction(String callId, String action) {
//     final now = DateTime.now();
//     final key = "$callId-$action";
//
//     if (_lastActionForCall.containsKey(key)) {
//       final lastActionTime = _lastActionForCall[key]!;
//
//       // Different debounce times for different actions
//       Duration debouncePeriod;
//       switch (action) {
//         case 'end':
//           debouncePeriod = const Duration(seconds: 3);
//           break;
//         case 'accept':
//         // Don't debounce accept too much - just enough to prevent duplicates
//           debouncePeriod = const Duration(milliseconds: 300);
//           break;
//         default:
//           debouncePeriod = const Duration(seconds: 1);
//       }
//
//       if (now.difference(lastActionTime) < debouncePeriod) {
//         print('Debouncing $action for call $callId');
//         return false;
//       }
//     }
//
//     // Record this action
//     _lastActionForCall[key] = now;
//     return true;
//   }
//
//   /// Listen to CallKit events with proper debouncing and type safety
//   void listenToCallEvents() {
//     // Cancel any existing subscription to prevent duplicates
//     _callKitEventSubscription?.cancel();
//
//     _callKitEventSubscription = FlutterCallkitIncoming.onEvent.listen((event) async {
//       final eventType = event?.event;
//
//       // Safely extract data - fix for the type error by explicit type conversion
//       final Map<String, dynamic> data = {};
//
//       // Extract call data safely by converting types
//       if (event?.body != null) {
//         // Convert Object? keys and values to String and dynamic explicitly
//         (event!.body as Map<Object?, Object?>).forEach((key, value) {
//           if (key != null) {
//             data[key.toString()] = value;
//           }
//         });
//       }
//
//       final extra = data['extra'] is Map
//           ? Map<String, dynamic>.from(data['extra'] as Map)
//           : <String, dynamic>{};
//       final callId = data['id']?.toString() ?? '';
//
//       // Skip if we shouldn't process this action
//       if (!_shouldProcessAction(callId, eventType.toString())) {
//         return;
//       }
//
//       // Extract call data with proper type safety
//       final callerName = extra['callerName']?.toString() ?? 'Unknown';
//       final avatar = extra['avatar']?.toString() ?? '';
//       final userId = extra['userId']?.toString() ?? '';
//       final hasVideo = extra['has_video'] == true || extra['has_video'] == 'true';
//
//       debugPrint('CallKit event: $eventType for call: $callId');
//
//       switch (eventType) {
//         case Event.actionCallAccept:
//           try {
//             // Update status to busy via API (safely) - only if needed
//             await _safeUpdateCallStatus('busy');
//
//             // Check if service is initialized before making API calls
//             // if (_isInitialized && _callApiService != null) {
//               // Call accept API with proper type safety
//              var callkit=CallApiService(baseUrl:AppData.remoteUrl3);
//               await callkit.acceptCall(
//                 callId: callId,
//                 callerId: userId,
//               );
//             // }
//
//             // Save call info for potential resuming
//             await _saveCallInfo(callId, userId, callerName, avatar, hasVideo);
//             // Launch the application if it's closed using CallKit's capabilities
//             // await FlutterCallkitIncoming.showCallkitIncoming(
//             //   CallKitParams(
//             //     id: callId,
//             //     nameCaller: callerName,
//             //     handle: userId,
//             //     type: hasVideo ? 1 : 0,
//             //     extra: extra,
//             //   ),
//             // );
//
//             // Use a longer delay to ensure the app is fully launched
//             await Future.delayed(const Duration(milliseconds: 1500));
//             // Navigate to call screen with proper data
//             _navigateToCallScreen(
//                 callId: callId,
//                 userId: userId,
//                 callerName: callerName,
//                 avatar: avatar,
//                 hasVideo: hasVideo
//             );
//           } catch (e) {
//             debugPrint('Error accepting call: $e');
//           }
//           break;
//
//         case Event.actionCallDecline:
//           try {
//             // Update status to available via API (safely)
//             await _safeUpdateCallStatus('available');
//
//             // Check if service is initialized before making API calls
//             if (_isInitialized && _callApiService != null) {
//               // Call reject API
//               await _callApiService!.rejectCall(
//                 callId: callId,
//                 callerId: userId,
//               );
//             }
//
//             // Clear notification and saved info
//             await FlutterCallkitIncoming.endCall(callId);
//             await _clearCallInfo();
//           } catch (e) {
//             debugPrint('Error rejecting call: $e');
//           }
//           break;
//
//         case Event.actionCallTimeout:
//           try {
//             // Only process if not already handling an end call for this callId
//             if (_callEndProcessed[callId] != true) {
//               // Update status to available via API (safely)
//               await _safeUpdateCallStatus('available');
//
//               // Check if service is initialized before making API calls
//               if (_isInitialized && _callApiService != null) {
//                 // Call missed API
//                 await _callApiService!.missCall(
//                   callId: callId,
//                   callerId: userId,
//                 );
//               }
//
//               // Clear notification and saved info
//               await FlutterCallkitIncoming.endCall(callId);
//               await _clearCallInfo();
//             }
//           } catch (e) {
//             debugPrint('Error marking call missed: $e');
//           }
//           break;
//
//         case Event.actionCallEnded:
//         // Use our improved endCall method
//           await endCall(callId);
//           break;
//
//         default:
//           break;
//       }
//     });
//   }
//
//   // Improved end call method
//   Future<void> endCall(String uuid) async {
//     // Check if this call end has already been processed
//     if (_callEndProcessed[uuid] == true) {
//       print('Call end already processed for: $uuid');
//       return;
//     }
//
//     // Check action debouncing
//     if (!_shouldProcessAction(uuid, 'end')) {
//       return;
//     }
//
//     // Mark as processed immediately
//     _callEndProcessed[uuid] = true;
//
//     try {
//       // First handle UI (CallKit) for immediate feedback
//       try {
//         await FlutterCallkitIncoming.endCall(uuid);
//       } catch (e) {
//         print('Error ending CallKit UI: $e');
//       }
//
//       // Update status to available via API (safely)
//       await _safeUpdateCallStatus('available');
//
//       // Check if service is initialized before making API calls
//       if (_isInitialized && _callApiService != null) {
//         try {
//           await _callApiService!.endCall(callId: uuid);
//         } catch (e) {
//           print('Error in API call to end call: $e');
//         }
//       }
//
//       // Clear saved call info
//       await _clearCallInfo();
//
//       // Clear the status after a delay (in case of quick redial attempts)
//       Future.delayed(const Duration(seconds: 5), () {
//         _callEndProcessed.remove(uuid);
//         _lastActionForCall.remove("$uuid-end");
//       });
//     } catch (e) {
//       print('Error ending call: $e');
//       // Still remove the processed flag after an error (after a shorter delay)
//       Future.delayed(const Duration(seconds: 2), () {
//         _callEndProcessed.remove(uuid);
//         _lastActionForCall.remove("$uuid-end");
//       });
//     }
//   }
//
//   // More reliable navigation to call screen
//   void _navigateToCallScreen({
//     required String callId,
//     required String userId,
//     required String callerName,
//     required String avatar,
//     required bool hasVideo,
//   }) {
//     // Function to attempt navigation with retries
//     Future<void> attemptNavigation([int retryCount = 0]) async {
//       if (NavigatorService.navigatorKey.currentState != null) {
//         // Check if we're already on a call screen to avoid duplicate screens
//         bool isAlreadyOnCallScreen = false;
//         NavigatorService.navigatorKey.currentState!.popUntil((route) {
//           if (route.settings.name == '/call') {
//             isAlreadyOnCallScreen = true;
//           }
//           return true; // Keep all routes
//         });
//
//         if (!isAlreadyOnCallScreen) {
//           // Use named route for better lifecycle handling
//           NavigatorService.navigatorKey.currentState?.pushNamed(
//             '/call',
//             arguments: {
//               'callId': callId,
//               'contactId': userId,
//               'contactName': callerName,
//               'contactAvatar': avatar,
//               'isIncoming': true,
//               'isVideoCall': hasVideo,
//               'token': '',
//             },
//           );
//         }
//       } else if (retryCount < 5) {
//         // Retry with exponential backoff up to 5 times
//         final delay = Duration(milliseconds: 500 * (retryCount + 1));
//         debugPrint('Navigator not available, retrying in ${delay.inMilliseconds}ms...');
//         Future.delayed(delay, () => attemptNavigation(retryCount + 1));
//       } else {
//         debugPrint('Failed to navigate to call screen after multiple attempts');
//         // Last resort: try the old method with MaterialPageRoute
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (NavigatorService.navigatorKey.currentState != null) {
//             NavigatorService.navigatorKey.currentState?.push(MaterialPageRoute(
//               settings: const RouteSettings(name: '/call'),
//               builder: (context) => CallScreen(
//                 callId: callId,
//                 contactId: userId,
//                 contactName: callerName,
//                 contactAvatar: avatar,
//                 isIncoming: true,
//                 isVideoCall: hasVideo,
//                 token: '',
//               ),
//             ));
//           }
//         });
//       }
//     }
//
//     // Start navigation attempts
//     attemptNavigation();
//   }
//
//   /// Start an outgoing call with proper type safety
//   Future<Map<String, dynamic>> startOutgoingCall({
//     required String userId,
//     required String calleeName,
//     required String avatar,
//     required bool hasVideo,
//   }) async {
//     try {
//       // Make sure service is initialized
//       if (!_isInitialized || _callApiService == null) {
//         debugPrint('CallKitService not initialized for outgoing call');
//         return {
//           'callId': 'error',
//           'success': false,
//           'message': 'CallKitService not initialized',
//         };
//       }
//
//       // Update status to busy via API
//       await _safeUpdateCallStatus('busy');
//
//       // Call the API to initiate the call
//       Map<String, dynamic> response;
//       try {
//         final rawResponse = await _callApiService!.initiateCall(
//           userId: userId,
//           hasVideo: hasVideo,
//         );
//
//         // Convert response to ensure it's Map<String, dynamic>
//         response = {};
//         if (rawResponse is Map) {
//           rawResponse.forEach((key, value) {
//             if (key is String) {
//               response[key] = value;
//             }
//           });
//         } else {
//           // Fallback if conversion fails
//           response = {
//             'callId': 'error',
//             'success': false,
//             'message': 'Invalid response format',
//           };
//         }
//       } catch (e) {
//         debugPrint('Error initiating call API: $e');
//         return {
//           'callId': 'error',
//           'success': false,
//           'message': 'Error calling API: $e',
//         };
//       }
//
//       // Extract callId with proper null checking
//       final callId = response['callId']?.toString() ??
//           DateTime.now().millisecondsSinceEpoch.toString();
//
//       // Update response with string callId
//       response['callId'] = callId;
//
//       // Save call info for potential resuming
//       await _saveCallInfo(callId, userId, calleeName, avatar, hasVideo);
//
//       // Show the outgoing call UI with CallKit
//       final params = CallKitParams(
//         id: callId,
//         nameCaller: calleeName,
//         handle: userId,
//         type: hasVideo ? 1 : 0,
//         extra: {
//           'userId': userId,
//           'has_video': hasVideo,
//           'callerName': calleeName,
//           'avatar': avatar,
//         },
//         ios: const IOSParams(
//           handleType: 'generic',
//           supportsVideo: true,
//         ),
//         android: const AndroidParams(
//           isCustomNotification: false,
//           isShowLogo: true,
//           ringtonePath: 'system_ringtone_default',
//         ),
//       );
//
//       try {
//         await FlutterCallkitIncoming.startCall(params);
//       } catch (e) {
//         debugPrint('Error showing CallKit UI: $e');
//         // Continue even if UI fails, as the call might still be working
//       }
//
//       // Ensure success flag is set
//       response['success'] = response['success'] ?? true;
//       return response;
//     } catch (e) {
//       // Update status to available if call fails (safely)
//       await _safeUpdateCallStatus('available');
//       debugPrint('Error starting outgoing call: $e');
//       // Return a default response to prevent crashes
//       return {
//         'callId': 'error',
//         'success': false,
//         'message': 'Error starting call: $e',
//       };
//     }
//   }
//
//   /// Check if there are any active calls
//   Future<bool> hasActiveCalls() async {
//     final result = await FlutterCallkitIncoming.activeCalls();
//     final calls = result as List?;
//     return calls != null && calls.isNotEmpty;
//   }
//
//   /// Get all active calls with proper type conversion
//   Future<List<Map<String, dynamic>>> getActiveCalls() async {
//     final result = await FlutterCallkitIncoming.activeCalls();
//     final List<dynamic> rawCalls = result as List? ?? [];
//
//     // Convert each call to Map<String, dynamic> with proper type safety
//     return rawCalls.map((call) {
//       final Map<String, dynamic> safeCall = {};
//
//       if (call is Map<Object?, Object?>) {
//         call.forEach((key, value) {
//           if (key != null) {
//             final String keyStr = key.toString();
//
//             // Handle 'extra' field specially as it's another map
//             if (keyStr == 'extra' && value is Map) {
//               final Map<String, dynamic> extraMap = {};
//               (value as Map<Object?, Object?>).forEach((extraKey, extraValue) {
//                 if (extraKey != null) {
//                   extraMap[extraKey.toString()] = extraValue;
//                 }
//               });
//               safeCall[keyStr] = extraMap;
//             } else {
//               safeCall[keyStr] = value;
//             }
//           }
//         });
//       }
//
//       return safeCall;
//     }).toList();
//   }
//
//   /// End all active calls
//   Future<void> endAllCalls() async {
//     // Update status to available via API (safely)
//     await _safeUpdateCallStatus('available');
//
//     await FlutterCallkitIncoming.endAllCalls();
//     await _clearCallInfo();
//
//     // Clear all end call locks
//     _callEndProcessed.clear();
//   }
//
//   /// Save call info to SharedPreferences for potential resuming
//   Future<void> _saveCallInfo(
//       String callId,
//       String userId,
//       String name,
//       String avatar,
//       bool hasVideo
//       ) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('active_call_id', callId);
//     await prefs.setString('active_call_user_id', userId);
//     await prefs.setString('active_call_name', name);
//     await prefs.setString('active_call_avatar', avatar);
//     await prefs.setBool('active_call_has_video', hasVideo);
//
//     // Save timestamp to check for stale calls
//     await prefs.setInt('active_call_timestamp', DateTime.now().millisecondsSinceEpoch);
//
//     // Save the base URL for potential service initialization after app restart
//     if (_isInitialized && _callApiService != null) {
//       await prefs.setString('api_base_url', _callApiService!.baseUrl);
//     }
//   }
//
//   /// IMPROVED: Clear saved call info with more thorough cleanup
//   Future<void> _clearCallInfo() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('active_call_id');
//       await prefs.remove('active_call_user_id');
//       await prefs.remove('active_call_name');
//       await prefs.remove('active_call_avatar');
//       await prefs.remove('active_call_has_video');
//       await prefs.remove('active_call_timestamp');
//       await prefs.remove('pending_call_id');
//       await prefs.remove('pending_call_timestamp');
//       // Don't remove api_base_url as it might be needed for future calls
//
//       debugPrint('Call information cleared from preferences');
//     } catch (e) {
//       debugPrint('Error clearing call info: $e');
//     }
//   }
//
//   /// NEW: Check if a call is still active with the server
//   Future<bool> checkCallIsActive(String callId) async {
//     if (!_isInitialized || _callApiService == null) return false;
//
//     try {
//       // await _callApiService!.checkCallStatus();
//       return true;
//     } catch (e) {
//       debugPrint('Call appears inactive: $e');
//       return false;
//     }
//   }
//   Future<void> updateCallState({
//     required String callId,
//     required String callerName,
//     required String callerId,
//     required String avatar,
//     required bool hasVideo,
//   }) async {
//     try {
//       // Check if this call is active in CallKit
//       final activeCalls = await getActiveCalls();
//       final isActive = activeCalls.any((call) => call['id'] == callId);
//
//       if (!isActive) {
//         debugPrint('Call not found in CallKit, displaying as new call: $callId');
//         // If not active, display it as a new call
//         await displayIncomingCall(
//           uuid: callId,
//           callerName: callerName,
//           callerId: callerId,
//           avatar: avatar,
//           hasVideo: hasVideo,
//         );
//         return;
//       }
//
//       // The call already exists in CallKit, just update any CallKit parameters if needed
//       // Note: On iOS, we can use CXCallUpdate to update the call display
//       // On Android, we need to check if we need to update the notification
//
//       if (Platform.isIOS) {
//         // iOS: Update the call display with new information
//         final params = CallKitParams(
//           id: callId,
//           nameCaller: callerName,
//           handle: callerId,
//           type: hasVideo ? 1 : 0,
//           extra: {
//             'userId': callerId,
//             'has_video': hasVideo,
//             'callerName': callerName,
//             'avatar': avatar,
//           },
//         );
//
//         try {
//           // Update call if available in iOS CallKit
//           await FlutterCallkitIncoming.showCallkitIncoming(params);
//           debugPrint('Updated call display in iOS CallKit: $callId');
//         } catch (e) {
//           debugPrint('Error updating call display: $e');
//         }
//       } else if (Platform.isAndroid) {
//         // Android: Currently the plugin doesn't support updating an existing call notification directly
//         // If we need to update the Android notification, we would need to extend the plugin
//         // For now, we'll rely on the existing notification
//         debugPrint('Call already active in Android CallKit, no update needed: $callId');
//       }
//
//       // Make sure the call screen is shown
//       await resumeCallScreenIfNeeded();
//     } catch (e) {
//       debugPrint('Error updating call state: $e');
//     }
//   }
//   /// IMPROVED: Resume call screen if app launched from callkit event with better validation
//   Future<void> resumeCallScreenIfNeeded() async {
//     try {
//       // Check if we have any active calls in CallKit
//       final calls = await getActiveCalls();
//
//       if (calls.isNotEmpty) {
//         final call = calls.first;
//         final callId = call['id']?.toString() ?? '';
//
//         // Additional verification - check if the call is recent
//         final prefs = await SharedPreferences.getInstance();
//         final timestamp = prefs.getInt('active_call_timestamp') ?? 0;
//         final now = DateTime.now().millisecondsSinceEpoch;
//
//         // Only resume if call is recent (within 60 seconds)
//         if (now - timestamp > 60000) { // 60 seconds
//           debugPrint('Found call in CallKit but it appears stale: $callId');
//
//           // Clean up the stale call
//           await endCall(callId);
//           return;
//         }
//
//         // Verify that the call is still active by checking with the API
//         if (_isInitialized && _callApiService != null) {
//           try {
//             // Call API to verify call is still active
//             // If the API throws an error, the call is likely not active
//             // await _callApiService!.checkCallStatus();
//           } catch (e) {
//             debugPrint('Call appears to be inactive according to API: $e');
//             await endCall(callId);
//             return;
//           }
//         }
//
//         final callerName = call['nameCaller']?.toString() ?? 'Unknown';
//
//         // Extract extra fields safely
//         final extra = call['extra'] is Map ? Map<String, dynamic>.from(call['extra'] as Map) : <String, dynamic>{};
//         final avatar = extra['avatar']?.toString() ?? '';
//         final userId = extra['userId']?.toString() ?? '';
//         final hasVideo = extra['has_video'] == true || extra['has_video'] == 'true';
//
//         debugPrint('Found active call in CallKit, resuming: $callId');
//
//         // Add a delay to ensure app is ready
//         await Future.delayed(const Duration(milliseconds: 1500));
//
//         // Use the more reliable navigation method
//         _navigateToCallScreen(
//             callId: callId,
//             userId: userId,
//             callerName: callerName,
//             avatar: avatar,
//             hasVideo: hasVideo
//         );
//       } else {
//         debugPrint('No active calls found in CallKit');
//
//         // We'll be more conservative about using saved call info
//         final prefs = await SharedPreferences.getInstance();
//         final savedCallId = prefs.getString('active_call_id');
//         final savedTimestamp = prefs.getInt('active_call_timestamp') ?? 0;
//         final now = DateTime.now().millisecondsSinceEpoch;
//
//         // Only use saved call info if it's less than 30 seconds old (reduced from 60)
//         if (savedCallId != null && (now - savedTimestamp < 30000)) {
//           // Try to verify with the API if possible
//           if (_isInitialized && _callApiService != null) {
//             try {
//               // Call API to verify call is still active
//               // await _callApiService!.checkCallStatus();
//             } catch (e) {
//               debugPrint('Call appears to be inactive according to API: $e');
//               await _clearCallInfo();
//               return;
//             }
//           }
//
//           final userId = prefs.getString('active_call_user_id') ?? '';
//           final name = prefs.getString('active_call_name') ?? 'Unknown';
//           final avatar = prefs.getString('active_call_avatar') ?? '';
//           final hasVideo = prefs.getBool('active_call_has_video') ?? false;
//
//           debugPrint('Found saved call info that appears active: $savedCallId');
//
//           // Navigate to call screen
//           _navigateToCallScreen(
//               callId: savedCallId,
//               userId: userId,
//               callerName: name,
//               avatar: avatar,
//               hasVideo: hasVideo
//           );
//         } else if (savedCallId != null) {
//           // Clean up old call data
//           debugPrint('Found stale call data, cleaning up');
//           await _clearCallInfo();
//         }
//       }
//     } catch (e) {
//       debugPrint('Error in resumeCallScreenIfNeeded: $e');
//     }
//   }
//
//   // Make sure to clean up when the service is disposed
//   void dispose() {
//     _callKitEventSubscription?.cancel();
//     _lastHandledCallEvent = null;
//     _lastEventTime = null;
//     _lastEventsByType.clear();
//     _callEndProcessed.clear();
//     _lastActionForCall.clear();
//   }
// }
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';

import 'call_api_service.dart';

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  // Add CallApiService with proper initialization protection
  CallApiService? _callApiService;
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Flag to determine if this service should update status or defer to CallService
  bool _shouldUpdateStatus = true;

  // Add event tracking to prevent duplicate events
  String? _lastHandledCallEvent;
  DateTime? _lastEventTime;
  Map<String, DateTime> _lastEventsByType = {};

  // Add these properties for better debouncing
  final Map<String, bool> _callEndProcessed = {};
  final Map<String, DateTime> _lastActionForCall = {};

  // Add initialization retry mechanism
  int _initRetryCount = 0;
  Timer? _initRetryTimer;
  Completer<bool>? _initializationCompleter;

  // To store active subscription
  StreamSubscription? _callKitEventSubscription;

  // Getter for base URL (for re-initialization if needed)
  String? get baseUrl => _callApiService?.baseUrl;

  // Check if initialization is complete
  bool get isInitialized => _isInitialized;

  // New method to get or initialize the CallApiService
  Future<CallApiService> _getOrCreateApiService() async {
    // If already initialized, return the existing service
    if (_isInitialized && _callApiService != null) {
      return _callApiService!;
    }

    // If initialization is in progress, wait for it to complete
    if (_isInitializing && _initializationCompleter != null) {
      await _initializationCompleter!.future;
      if (_callApiService != null) {
        return _callApiService!;
      }
    }

    // Otherwise, create a new service with default URL
    return CallApiService(baseUrl: AppData.remoteUrl3);
  }

  // Initialize method to set up the API service with retry mechanism
  Future<bool> initialize({
    required String baseUrl,
    String? authToken,
    bool shouldUpdateStatus = true, // New parameter to control status updates
  }) async {
    // If already initializing, return the existing completer's future
    if (_isInitializing && _initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    // If already initialized with the same base URL, just update the flag
    if (_isInitialized && _callApiService != null && _callApiService!.baseUrl == baseUrl) {
      debugPrint('CallKitService already initialized with the same baseUrl');
      // Update the status flag to ensure consistent behavior
      _shouldUpdateStatus = shouldUpdateStatus;
      return true;
    }

    // Cancel any existing retry timer
    _initRetryTimer?.cancel();

    // Create a new completer for this initialization attempt
    _initializationCompleter = Completer<bool>();
    _isInitializing = true;

    try {
      _callApiService = CallApiService(baseUrl: baseUrl);
      _isInitialized = true;
      _shouldUpdateStatus = shouldUpdateStatus;

      // Setup call event listeners
      listenToCallEvents();

      debugPrint('CallKitService initialized successfully with baseUrl: $baseUrl');
      debugPrint('Status updates will be ${_shouldUpdateStatus ? 'handled by CallKitService' : 'deferred to CallService'}');

      // Reset retry count on successful initialization
      _initRetryCount = 0;

      // Complete the initialization
      _initializationCompleter?.complete(true);
      _isInitializing = false;

      return true;
    } catch (e) {
      debugPrint('Error initializing CallKitService: $e');

      // Retry initialization with backoff if needed
      if (_initRetryCount < 3) {
        _retryInitialization(baseUrl, shouldUpdateStatus);
        return _initializationCompleter!.future;
      } else {
        _isInitialized = false;
        _isInitializing = false;
        _initializationCompleter?.complete(false);
        return false;
      }
    }
  }

  // Retry initialization with backoff
  void _retryInitialization(String baseUrl, bool shouldUpdateStatus) {
    _initRetryCount++;
    final delay = Duration(milliseconds: 500 * _initRetryCount);

    debugPrint('Will retry CallKitService initialization in ${delay.inMilliseconds}ms (attempt $_initRetryCount)');

    _initRetryTimer = Timer(delay, () {
      initialize(baseUrl: baseUrl, shouldUpdateStatus: shouldUpdateStatus)
          .then((success) {
        if (!success && _initRetryCount < 3) {
          _retryInitialization(baseUrl, shouldUpdateStatus);
        }
      });
    });
  }

  // Safe method to update call status, with null check and control flag
  Future<void> _safeUpdateCallStatus(String status) async {
    // Skip status updates if flag is false (CallService will handle them)
    if (!_shouldUpdateStatus) {
      debugPrint('CallKitService: Status updates deferred to CallService');
      return;
    }

    try {

      final apiService = await _getOrCreateApiService();
      // apiService.sendBusySignal(callId: callId, callerId: callerId)
      // Call your update status API method here if available
      debugPrint('CallKit updated status to: $status');
    } catch (e) {
      debugPrint('Error updating call status to $status: $e');
    }
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

    // First update the call status to "busy" via API (safely)
    await _safeUpdateCallStatus('busy');
    initPusherCall();
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

  // Improved debouncing method to prevent duplicate events
  bool _shouldProcessAction(String callId, String action) {
    final now = DateTime.now();
    final key = "$callId-$action";

    if (_lastActionForCall.containsKey(key)) {
      final lastActionTime = _lastActionForCall[key]!;

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

      if (now.difference(lastActionTime) < debouncePeriod) {
        print('Debouncing $action for call $callId');
        return false;
      }
    }

    // Record this action
    _lastActionForCall[key] = now;
    return true;
  }

  /// Listen to CallKit events with proper debouncing and type safety
  void listenToCallEvents() {
    // Cancel any existing subscription to prevent duplicates
    _callKitEventSubscription?.cancel();
    _callKitEventSubscription = null;

    // Only start listening if service is initialized
    if (!_isInitialized) {
      debugPrint('Cannot listen to call events: service not initialized');
      return;
    }

    _callKitEventSubscription = FlutterCallkitIncoming.onEvent.listen(
      (event) async {
        // Safety check: don't process events if service is disposed
        if (!_isInitialized) {
          debugPrint('Ignoring CallKit event: service not initialized');
          return;
        }

        try {
          final eventType = event?.event;

          // Safely extract data - fix for the type error by explicit type conversion
          final Map<String, dynamic> data = {};

      // Extract call data safely by converting types
      if (event?.body != null) {
        // Convert Object? keys and values to String and dynamic explicitly
        (event!.body as Map<Object?, Object?>).forEach((key, value) {
          if (key != null) {
            data[key.toString()] = value;
          }
        });
      }

      final extra = data['extra'] is Map
          ? Map<String, dynamic>.from(data['extra'] as Map)
          : <String, dynamic>{};
      final callId = data['id']?.toString() ?? '';

      // Skip if we shouldn't process this action
      if (!_shouldProcessAction(callId, eventType.toString())) {
        return;
      }

      // Extract call data with proper type safety
      final callerName = extra['callerName']?.toString() ?? 'Unknown';
      final avatar = extra['avatar']?.toString() ?? '';
      final userId = extra['userId']?.toString() ?? '';
      final hasVideo = extra['has_video'] == true || extra['has_video'] == 'true';

      debugPrint('CallKit event: $eventType for call: $callId');

      switch (eventType) {
        case Event.actionCallAccept:
          try {
            // Update status to busy via API (safely) - only if needed
            await _safeUpdateCallStatus('busy');

            // Get the API service - with proper initialization handling
            try {
              final apiService = await _getOrCreateApiService();

              // Call accept API with proper type safety and retry mechanism
              bool apiCallSuccess = false;
              int retryCount = 0;

              while (!apiCallSuccess && retryCount < 3) {
                try {
                  await apiService.acceptCall(
                    callId: callId,
                    callerId: userId,
                  );
                  apiCallSuccess = true;
                  debugPrint('Successfully called accept API for call: $callId');
                } catch (e) {
                  retryCount++;
                  debugPrint('Error calling accept API (attempt $retryCount): $e');
                  await Future.delayed(Duration(milliseconds: 300 * retryCount));
                }
              }
            } catch (e) {
              debugPrint('Error getting API service: $e');
            }

            // Save call info for potential resuming
            await _saveCallInfo(callId, userId, callerName, avatar, hasVideo);

            // Use a longer delay to ensure the app is fully launched
            await Future.delayed(const Duration(milliseconds: 1500));

            // Navigate to call screen with proper data
            _navigateToCallScreen(
                callId: callId,
                userId: userId,
                callerName: callerName,
                avatar: avatar,
                hasVideo: hasVideo
            );
          } catch (e) {
            debugPrint('Error handling call acceptance: $e');
          }
          break;

        case Event.actionCallDecline:
          try {
            // Update status to available via API (safely)
            await _safeUpdateCallStatus('available');

            // Get the API service - with proper initialization handling
            try {
              final apiService = await _getOrCreateApiService();

              // Call reject API
              await apiService.rejectCall(
                callId: callId,
                callerId: userId,
              );
            } catch (e) {
              debugPrint('Error calling reject API: $e');
            }

            // Clear notification and saved info
            await FlutterCallkitIncoming.endCall(callId);
            await _clearCallInfo();
          } catch (e) {
            debugPrint('Error rejecting call: $e');
          }
          break;

        case Event.actionCallTimeout:
          try {
            // Only process if not already handling an end call for this callId
            if (_callEndProcessed[callId] != true) {
              // Update status to available via API (safely)
              await _safeUpdateCallStatus('available');

              // Get the API service - with proper initialization handling
              try {
                final apiService = await _getOrCreateApiService();

                // Call missed API
                await apiService.missCall(
                  callId: callId,
                  callerId: userId,
                );
              } catch (e) {
                debugPrint('Error calling miss call API: $e');
              }

              // Clear notification and saved info
              await FlutterCallkitIncoming.endCall(callId);
              await _clearCallInfo();
            }
          } catch (e) {
            debugPrint('Error marking call missed: $e');
          }
          break;

        case Event.actionCallEnded:
        // Use our improved endCall method
          await endCall(callId);
          break;

        default:
          break;
      }
        } catch (e) {
          debugPrint('Error processing CallKit event: $e');
        }
      },
      onError: (error) {
        debugPrint('CallKit event stream error: $error');
      },
      onDone: () {
        debugPrint('CallKit event stream closed');
        _callKitEventSubscription = null;
      },
    );
  }

  // Improved end call method
  Future<void> endCall(String uuid) async {
    // Check if this call end has already been processed
    if (_callEndProcessed[uuid] == true) {
      print('Call end already processed for: $uuid');
      return;
    }

    // Check action debouncing
    if (!_shouldProcessAction(uuid, 'end')) {
      return;
    }

    // Mark as processed immediately
    _callEndProcessed[uuid] = true;

    try {
      // First handle UI (CallKit) for immediate feedback
      try {
        print('end call');
        await FlutterCallkitIncoming.endCall(uuid);
      } catch (e) {
        print('Error ending CallKit UI: $e');
      }

      // Update status to available via API (safely)
      await _safeUpdateCallStatus('available');

      // Get the API service - with proper initialization handling
      try {
        final apiService = await _getOrCreateApiService();

        // Call end call API
        await apiService.endCall(callId: uuid);
      } catch (e) {
        print('Error in API call to end call: $e');
      }

      // Clear saved call info
      await _clearCallInfo();

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
  PusherChannelsFlutter get pusher => AppData.pusher;

  initPusherCall() async {
     // Subscribe to Pusher channel for call status updates
     try {
      var  channelName = "user.${AppData.logInUserId}";

       // Bind to the channel events
       await pusher.subscribe(
         channelName: channelName,
         onEvent: (event) {
           String eventName = event.eventName;
           Map<String, dynamic> eventDataMap = {};
           if( eventName=="pusher:subscription_succeeded"){
             return;
           }
           try {
             eventDataMap = jsonDecode(event.data);
           } catch (e) {
             print('Error parsing event data: $e ${event}');
           }
           print('Received call event: $eventName with data: $eventDataMap');

           // Extract call status from event data or use event name
           String callStatus;
           // print('Received call event with status: $callStatus');
            if(eventName=='call.ended') {
             // If call was ended from the other side before we connected
             // Close call screen after a delay
               endCall(eventDataMap['endData']['callId']);
           }
         },
       );

       // Set a timeout for ringing status

     } catch (e) {
       print('Error subscribing to Pusher channel: $e');
       // Continue with call flow even if Pusher fails - CallKit will still work
     }
   }
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
              'token': '',
            },
          );
        }
      } else if (retryCount < 5) {
        // Retry with exponential backoff up to 5 times
        final delay = Duration(milliseconds: 500 * (retryCount + 1));
        debugPrint('Navigator not available, retrying in ${delay.inMilliseconds}ms...');
        Future.delayed(delay, () => attemptNavigation(retryCount + 1));
      } else {
        debugPrint('Failed to navigate to call screen after multiple attempts');
        // Last resort: try the old method with MaterialPageRoute
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (NavigatorService.navigatorKey.currentState != null) {
            NavigatorService.navigatorKey.currentState?.push(MaterialPageRoute(
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
            ));
          }
        });
      }
    }

    // Start navigation attempts
    attemptNavigation();
  }

  /// Start an outgoing call with proper type safety
  Future<Map<String, dynamic>> startOutgoingCall({
    required String userId,
    required String calleeName,
    required String avatar,
    required bool hasVideo,
  }) async {
    try {
      // Get the API service - with proper initialization handling
      final apiService = await _getOrCreateApiService();

      // Update status to busy via API
      await _safeUpdateCallStatus('busy');

      // Call the API to initiate the call
      Map<String, dynamic> response;
      try {
        final rawResponse = await apiService.initiateCall(
          userId: userId,
          hasVideo: hasVideo,
        );

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

      // Extract callId with proper null checking
      final callId = response['callId']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Update response with string callId
      response['callId'] = callId;

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

      try {
        await FlutterCallkitIncoming.startCall(params);
      } catch (e) {
        debugPrint('Error showing CallKit UI: $e');
        // Continue even if UI fails, as the call might still be working
      }

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

  /// Check if there are any active calls
  Future<bool> hasActiveCalls() async {
    final result = await FlutterCallkitIncoming.activeCalls();
    final calls = result as List?;
    return calls != null && calls.isNotEmpty;
  }

  /// Get all active calls with proper type conversion
  Future<List<Map<String, dynamic>>> getActiveCalls() async {
    final result = await FlutterCallkitIncoming.activeCalls();
    final List<dynamic> rawCalls = result as List? ?? [];

    // Convert each call to Map<String, dynamic> with proper type safety
    return rawCalls.map((call) {
      final Map<String, dynamic> safeCall = {};

      if (call is Map<Object?, Object?>) {
        call.forEach((key, value) {
          if (key != null) {
            final String keyStr = key.toString();

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

      return safeCall;
    }).toList();
  }

  /// End all active calls
  Future<void> endAllCalls() async {
    // Update status to available via API (safely)
    await _safeUpdateCallStatus('available');

    await FlutterCallkitIncoming.endAllCalls();
    await _clearCallInfo();

    // Clear all end call locks
    _callEndProcessed.clear();
    _lastActionForCall.clear();
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

    // Save timestamp to check for stale calls
    await prefs.setInt('active_call_timestamp', DateTime.now().millisecondsSinceEpoch);

    // Save the base URL for potential service initialization after app restart
    if (_isInitialized && _callApiService != null) {
      await prefs.setString('api_base_url', _callApiService!.baseUrl);
    }
  }

  /// IMPROVED: Clear saved call info with more thorough cleanup
  Future<void> _clearCallInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_call_id');
      await prefs.remove('active_call_user_id');
      await prefs.remove('active_call_name');
      await prefs.remove('active_call_avatar');
      await prefs.remove('active_call_has_video');
      await prefs.remove('active_call_timestamp');
      await prefs.remove('pending_call_id');
      await prefs.remove('pending_call_timestamp');
      await prefs.remove('pending_caller_id');
      await prefs.remove('pending_caller_name');
      await prefs.remove('pending_caller_avatar');
      await prefs.remove('pending_call_has_video');
      // Don't remove api_base_url as it might be needed for future calls

      debugPrint('Call information cleared from preferences');
    } catch (e) {
      debugPrint('Error clearing call info: $e');
    }
  }

  /// NEW: Check if a call is still active with the server
  Future<bool> checkCallIsActive(String callId) async {
    try {
      // Get the API service - with proper initialization handling
      final apiService = await _getOrCreateApiService();

      // Call your check call status API method if available
      // For now, we'll return true if the service is initialized
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

      if (!isActive) {
        debugPrint('Call not found in CallKit, displaying as new call: $callId');
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

      // The call already exists in CallKit, just update any CallKit parameters if needed
      // Note: On iOS, we can use CXCallUpdate to update the call display
      // On Android, we need to check if we need to update the notification

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
        debugPrint('Call already active in Android CallKit, no update needed: $callId');
      }

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

      if (calls.isNotEmpty) {
        final call = calls.first;
        final callId = call['id']?.toString() ?? '';

        // Additional verification - check if the call is recent
        final prefs = await SharedPreferences.getInstance();
        final timestamp = prefs.getInt('active_call_timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Only resume if call is recent (within 60 seconds)
        if (now - timestamp > 60000) { // 60 seconds
          debugPrint('Found call in CallKit but it appears stale: $callId');

          // Clean up the stale call
          await endCall(callId);
          return;
        }

        // Verify that the call is still active by checking with the API
        bool isActive = await checkCallIsActive(callId);
        if (!isActive) {
          debugPrint('Call appears to be inactive according to API: $callId');
          await endCall(callId);
          return;
        }

        final callerName = call['nameCaller']?.toString() ?? 'Unknown';

        // Extract extra fields safely
        final extra = call['extra'] is Map ? Map<String, dynamic>.from(call['extra'] as Map) : <String, dynamic>{};
        final avatar = extra['avatar']?.toString() ?? '';
        final userId = extra['userId']?.toString() ?? '';
        final hasVideo = extra['has_video'] == true || extra['has_video'] == 'true';

        debugPrint('Found active call in CallKit, resuming: $callId');

        // Add a delay to ensure app is ready
        await Future.delayed(const Duration(milliseconds: 1500));

        // Use the more reliable navigation method
        _navigateToCallScreen(
            callId: callId,
            userId: userId,
            callerName: callerName,
            avatar: avatar,
            hasVideo: hasVideo
        );
      } else {
        debugPrint('No active calls found in CallKit');

        // We'll be more conservative about using saved call info
        final prefs = await SharedPreferences.getInstance();
        final savedCallId = prefs.getString('active_call_id');
        final savedTimestamp = prefs.getInt('active_call_timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Only use saved call info if it's less than 30 seconds old (reduced from 60)
        if (savedCallId != null && (now - savedTimestamp < 30000)) {
          // Try to verify with the API if possible
          bool isActive = await checkCallIsActive(savedCallId);
          if (!isActive) {
            debugPrint('Call appears to be inactive according to API: $savedCallId');
            await _clearCallInfo();
            return;
          }

          final userId = prefs.getString('active_call_user_id') ?? '';
          final name = prefs.getString('active_call_name') ?? 'Unknown';
          final avatar = prefs.getString('active_call_avatar') ?? '';
          final hasVideo = prefs.getBool('active_call_has_video') ?? false;

          debugPrint('Found saved call info that appears active: $savedCallId');

          // Navigate to call screen
          _navigateToCallScreen(
              callId: savedCallId,
              userId: userId,
              callerName: name,
              avatar: avatar,
              hasVideo: hasVideo
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

  // Make sure to clean up when the service is disposed
  void dispose() {
    // Cancel event subscription
    _callKitEventSubscription?.cancel();
    _callKitEventSubscription = null;
    
    // Cancel initialization retry timer
    _initRetryTimer?.cancel();
    _initRetryTimer = null;
    
    // Complete any pending initialization
    if (_initializationCompleter != null && !_initializationCompleter!.isCompleted) {
      _initializationCompleter!.complete(false);
    }
    _initializationCompleter = null;
    
    // Clear all tracking data
    _lastHandledCallEvent = null;
    _lastEventTime = null;
    _lastEventsByType.clear();
    _callEndProcessed.clear();
    _lastActionForCall.clear();
    
    // Reset initialization state
    _isInitialized = false;
    _isInitializing = false;
    _initRetryCount = 0;
    
    debugPrint('CallKitService disposed and cleaned up');
  }
}