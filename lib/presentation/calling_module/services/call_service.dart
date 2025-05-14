// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:doctak_app/core/call_service/callkit_service.dart';
// import 'package:doctak_app/core/utils/navigator_service.dart';
// import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
// import 'package:doctak_app/presentation/call_module/call_api_service.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:clear_all_notifications/clear_all_notifications.dart';
//
// /// Global service to handle call functionality throughout the app lifecycle
// /// This service coordinates with CallKitService to manage calls
// class CallService extends ChangeNotifier {
//   // Singleton instance with lazy initialization
//   static CallService? _instance;
//
//   // Use factory constructor for singleton pattern
//   factory CallService() {
//     // Create instance if it doesn't exist
//     _instance ??= CallService._internal();
//     return _instance!;
//   }
//
//   // Private constructor
//   CallService._internal();
//
//   // Use nullable fields with getters for safe access
//   CallKitService? _callKitService;
//   CallApiService? _callApiService;
//
//   // Safe access to CallKitService with lazy initialization
//   CallKitService get callKitService {
//     _callKitService ??= CallKitService();
//     return _callKitService!;
//   }
//
//   // State management
//   bool _isInitialized = false;
//   bool _hasActiveCall = false;
//   bool _isHandlingIncomingCall = false;
//   bool _isInForeground = true;
//   String? _currentCallId;
//   String _appState = 'inactive'; // inactive, foreground, background
//
//   // Flag to track if we're currently ending a call
//   bool _isEndingCall = false;
//
//   // Flag to track if we're in the process of handling a call acceptance
//   bool _isAcceptingCall = false;
//
//   // Timestamp of last handled notification to prevent duplicates
//   Map<String, int> _lastHandledNotification = {};
//
//   // Map to track accepted calls to prevent duplicates
//   final Map<String, DateTime> _acceptedCalls = {};
//
//   // Locks to prevent duplicate API calls
//   final Map<String, bool> _apiCallLocks = {};
//   final Map<String, DateTime> _lastApiCallTimestamps = {};
//
//   // Call information
//   String? _callerId;
//   String? _callerName;
//   String? _callerAvatar;
//   bool _isVideoCall = false;
//
//   // Initialization retry mechanism
//   int _initRetryCount = 0;
//   Timer? _initRetryTimer;
//
//   // Getters
//   bool get isInitialized => _isInitialized;
//   bool get hasActiveCall => _hasActiveCall;
//   String? get currentCallId => _currentCallId;
//   bool get isVideoCall => _isVideoCall;
//   bool get isEndingCall => _isEndingCall;
//   bool get isAcceptingCall => _isAcceptingCall;
//
//   /// Initialize the CallService
//   Future<void> initialize({
//     required String baseUrl,
//     bool isFromCallNotification = false,
//   }) async {
//     // Cancel any existing retry timer
//     _initRetryTimer?.cancel();
//
//     try {
//       // Initialize API service with base URL
//       _callApiService = CallApiService(baseUrl: baseUrl);
//       _isInitialized = true;
//
//       debugPrint('CallService initialized successfully with baseUrl: $baseUrl');
//
//       // Initialize CallKitService if it hasn't been already
//       if (_callKitService == null) {
//         _callKitService = CallKitService();
//         await _callKitService!.initialize(
//           baseUrl: baseUrl,
//           shouldUpdateStatus: false, // Let CallService handle status updates
//         );
//       }
//
//       // Listen to CallKit events
//       _setupCallKitListeners();
//
//       // Load previously accepted calls from SharedPreferences
//       await _loadAcceptedCalls();
//
//       // If launched from notification, we'll handle it in handleIncomingCall
//       if (isFromCallNotification) {
//         debugPrint('App launched from call notification');
//
//         // Check for pending call info
//         await _checkForPendingCalls();
//       } else {
//         // Check for any existing calls (app startup)
//         await _checkForActiveCalls();
//       }
//
//       // Reset retry count on successful initialization
//       _initRetryCount = 0;
//     } catch (e) {
//       debugPrint('Error initializing CallService: $e');
//       _isInitialized = false;
//
//       // Retry initialization with increasing delay if needed
//       _retryInitialization(baseUrl, isFromCallNotification);
//     }
//   }
//
//   // Load accepted calls from SharedPreferences
//   Future<void> _loadAcceptedCalls() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final acceptedCallsJson = prefs.getStringList('accepted_calls') ?? [];
//
//       // Clear existing entries
//       _acceptedCalls.clear();
//
//       // Parse and add entries
//       for (final entry in acceptedCallsJson) {
//         final parts = entry.split('|');
//         if (parts.length == 2) {
//           final callId = parts[0];
//           final timestamp = int.tryParse(parts[1]) ?? 0;
//
//           if (timestamp > 0) {
//             _acceptedCalls[callId] = DateTime.fromMillisecondsSinceEpoch(timestamp);
//           }
//         }
//       }
//
//       debugPrint('Loaded ${_acceptedCalls.length} accepted calls from preferences');
//     } catch (e) {
//       debugPrint('Error loading accepted calls: $e');
//     }
//   }
//
//   // Save accepted calls to SharedPreferences
//   Future<void> _saveAcceptedCalls() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       // Clean up old entries (older than 5 minutes)
//       final now = DateTime.now();
//       _acceptedCalls.removeWhere((_, timestamp) =>
//       now.difference(timestamp).inMinutes > 5);
//
//       // Convert to string list
//       final acceptedCallsJson = _acceptedCalls.entries.map((entry) =>
//       '${entry.key}|${entry.value.millisecondsSinceEpoch}').toList();
//
//       // Save to preferences
//       await prefs.setStringList('accepted_calls', acceptedCallsJson);
//
//       debugPrint('Saved ${_acceptedCalls.length} accepted calls to preferences');
//     } catch (e) {
//       debugPrint('Error saving accepted calls: $e');
//     }
//   }
//
//   // Mark a call as accepted
//   Future<void> _markCallAsAccepted(String callId) async {
//     _acceptedCalls[callId] = DateTime.now();
//     await _saveAcceptedCalls();
//
//     // Also clear any notifications to prevent duplicates
//     try {
//       if (Platform.isAndroid) {
//         await ClearAllNotifications.clear();
//       }
//     } catch (e) {
//       // Ignore errors clearing notifications
//     }
//
//     debugPrint('Marked call as accepted: $callId');
//   }
//
//   // Check if a call has already been accepted
//   bool _isCallAlreadyAccepted(String callId) {
//     final timestamp = _acceptedCalls[callId];
//     if (timestamp == null) return false;
//
//     // Consider a call as accepted if it was accepted in the last 5 minutes
//     final now = DateTime.now();
//     return now.difference(timestamp).inMinutes < 5;
//   }
//
//   // Check if notification was recently handled to prevent duplicates
//   bool _isRecentlyHandledNotification(String callId) {
//     final lastTimestamp = _lastHandledNotification[callId];
//     if (lastTimestamp == null) return false;
//
//     final now = DateTime.now().millisecondsSinceEpoch;
//     // Consider notifications within 3 seconds as duplicates
//     return (now - lastTimestamp < 3000);
//   }
//
//   // Mark notification as handled
//   void _markNotificationHandled(String callId) {
//     _lastHandledNotification[callId] = DateTime.now().millisecondsSinceEpoch;
//   }
//
//   // Check for pending calls
//   Future<void> _checkForPendingCalls() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final pendingCallId = prefs.getString('pending_call_id');
//
//       if (pendingCallId != null) {
//         // Check if this call has already been accepted
//         if (_isCallAlreadyAccepted(pendingCallId) || _isRecentlyHandledNotification(pendingCallId)) {
//           debugPrint('Call already accepted or notification recently handled, ignoring: $pendingCallId');
//           await _clearPendingCallInfo();
//           return;
//         }
//
//         final pendingTimestamp = prefs.getInt('pending_call_timestamp') ?? 0;
//         final now = DateTime.now().millisecondsSinceEpoch;
//
//         // Only consider calls within the last 30 seconds
//         if (now - pendingTimestamp < 30000) {
//           debugPrint('Found pending call from notification: $pendingCallId');
//
//           // Mark as handled immediately to prevent duplicates
//           _markNotificationHandled(pendingCallId);
//
//           // Extract call information
//           final callerId = prefs.getString('pending_caller_id') ?? '';
//           final callerName = prefs.getString('pending_caller_name') ?? 'Unknown';
//           final avatar = prefs.getString('pending_caller_avatar') ?? '';
//           final hasVideo = prefs.getBool('pending_call_has_video') ?? false;
//
//           // Handle the call
//           await handleIncomingCall(
//             callId: pendingCallId,
//             callerId: callerId,
//             callerName: callerName,
//             callerAvatar: avatar,
//             isVideoCall: hasVideo,
//           );
//         } else {
//           // Call info is too old, clean up
//           await _clearPendingCallInfo();
//         }
//       }
//     } catch (e) {
//       debugPrint('Error checking for pending calls: $e');
//     }
//   }
//
//   // Clean up pending call info
//   Future<void> _clearPendingCallInfo() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('pending_call_id');
//       await prefs.remove('pending_call_timestamp');
//       await prefs.remove('pending_caller_id');
//       await prefs.remove('pending_caller_name');
//       await prefs.remove('pending_caller_avatar');
//       await prefs.remove('pending_call_has_video');
//
//       // Also clear any notifications to prevent duplicates
//       try {
//         if (Platform.isAndroid) {
//           await ClearAllNotifications.clear();
//         }
//       } catch (e) {
//         // Ignore errors clearing notifications
//       }
//     } catch (e) {
//       debugPrint('Error clearing pending call info: $e');
//     }
//   }
//
//   // Retry initialization with exponential backoff
//   void _retryInitialization(String baseUrl, bool isFromCallNotification) {
//     if (_initRetryCount >= 3) {
//       debugPrint('Giving up on initialization after $_initRetryCount attempts');
//       return;
//     }
//
//     _initRetryCount++;
//     final delay = Duration(milliseconds: 300 * _initRetryCount);
//
//     debugPrint('Will retry initialization in ${delay.inMilliseconds}ms (attempt $_initRetryCount)');
//
//     _initRetryTimer = Timer(delay, () {
//       initialize(baseUrl: baseUrl, isFromCallNotification: isFromCallNotification);
//     });
//   }
//
//   /// Set up listeners for CallKit events
//   void _setupCallKitListeners() {
//     try {
//       callKitService.listenToCallEvents();
//       debugPrint('CallKit listeners set up successfully');
//     } catch (e) {
//       debugPrint('Error setting up CallKit listeners: $e');
//     }
//   }
//
//   /// Check for any active calls at startup
//   Future<void> _checkForActiveCalls() async {
//     if (!_isInitialized) {
//       debugPrint('CallService not initialized, cannot check for active calls');
//       return;
//     }
//
//     try {
//       // First check for active calls in CallKit
//       List<dynamic> activeCalls = [];
//       try {
//         // Try to use the service method first
//         activeCalls = await callKitService.getActiveCalls();
//       } catch (e) {
//         // If that fails, try direct FlutterCallkitIncoming call
//         try {
//           final result = await FlutterCallkitIncoming.activeCalls();
//           activeCalls = result as List? ?? [];
//         } catch (e2) {
//           debugPrint('Error checking active calls: $e2');
//         }
//       }
//
//       if (activeCalls.isNotEmpty) {
//         final call = activeCalls.first;
//         final callId = call['id']?.toString() ?? '';
//
//         // Check if this call has already been accepted
//         if (_isCallAlreadyAccepted(callId) || _isRecentlyHandledNotification(callId)) {
//           debugPrint('Call already accepted or notification recently handled, ensuring it\'s visible: $callId');
//           await callKitService.resumeCallScreenIfNeeded();
//           return;
//         }
//
//         // Mark as handled immediately to prevent duplicates
//         _markNotificationHandled(callId);
//
//         // Verify the call timestamp is recent
//         final now = DateTime.now().millisecondsSinceEpoch;
//         final prefs = await SharedPreferences.getInstance();
//         final timestamp = prefs.getInt('active_call_timestamp') ?? 0;
//
//         // Only consider recent calls (less than 60 seconds old)
//         if (now - timestamp > 60000) {
//           debugPrint('Found stale call in CallKit, cleaning up: $callId');
//           await callKitService.endCall(callId);
//           await _clearCallInfo();
//           return;
//         }
//
//         // Verify call is active with server if possible
//         bool isActive = await _verifyCallWithServer(callId);
//         if (!isActive) {
//           debugPrint('Call not active according to server: $callId');
//           await callKitService.endCall(callId);
//           await _clearCallInfo();
//           return;
//         }
//
//         // Extract call information from CallKit
//         debugPrint('Found active call in CallKit: $callId');
//
//         // Mark this call as accepted
//         await _markCallAsAccepted(callId);
//
//         // Extract call information
//         final extra = call['extra'] is Map ?
//         Map<String, dynamic>.from(call['extra'] as Map) :
//         <String, dynamic>{};
//
//         _callerId = extra['userId']?.toString() ?? '';
//         _callerName = call['nameCaller']?.toString() ?? 'Unknown';
//         _callerAvatar = extra['avatar']?.toString() ?? '';
//         _isVideoCall = extra['has_video'] == true || extra['has_video'] == 'true';
//         _currentCallId = callId;
//         _hasActiveCall = true;
//
//         // Save call information for recovery
//         await _saveCallInfo(callId, _callerId!, _callerName!, _callerAvatar!, _isVideoCall);
//
//         notifyListeners();
//       } else {
//         // No calls in CallKit, check preferences
//         await _loadCallInfo();
//
//         if (_currentCallId != null) {
//           // Check if this call has already been accepted
//           if (_isCallAlreadyAccepted(_currentCallId!) || _isRecentlyHandledNotification(_currentCallId!)) {
//             debugPrint('Call already accepted or notification recently handled, ensuring it\'s visible: $_currentCallId');
//             await callKitService.resumeCallScreenIfNeeded();
//             return;
//           }
//
//           // Mark as handled immediately to prevent duplicates
//           _markNotificationHandled(_currentCallId!);
//
//           // We have call info, verify it's recent and active
//           final prefs = await SharedPreferences.getInstance();
//           final timestamp = prefs.getInt('active_call_timestamp') ?? 0;
//           final now = DateTime.now().millisecondsSinceEpoch;
//
//           // Only consider recent calls (less than 30 seconds old)
//           if (now - timestamp > 30000) {
//             debugPrint('Call info is too old, clearing');
//             await _clearCallInfo();
//             return;
//           }
//
//           // Verify call is active with server
//           bool isActive = await _verifyCallWithServer(_currentCallId!);
//           if (!isActive) {
//             debugPrint('Call not active according to server: $_currentCallId');
//             await _clearCallInfo();
//             return;
//           }
//
//           // Call appears to be active
//           debugPrint('Found active call in preferences: $_currentCallId');
//
//           // Mark this call as accepted
//           await _markCallAsAccepted(_currentCallId!);
//
//           _hasActiveCall = true;
//           notifyListeners();
//         }
//       }
//     } catch (e) {
//       debugPrint('Error checking for active calls: $e');
//     }
//   }
//
//   /// Verify call is active with the server
//   Future<bool> _verifyCallWithServer(String callId) async {
//     try {
//       if (!_isInitialized || _callApiService == null) return false;
//
//       // Add actual API call to verify call status
//       // This would typically check with your backend if the call is still active
//       // await _callApiService.checkCallStatus(callId);
//
//       // For now, we'll return true if the service is initialized
//       // In a production environment, you should implement proper verification
//       return true;
//     } catch (e) {
//       debugPrint('Error verifying call with server: $e');
//       return false;
//     }
//   }
//
//   /// Load call information from SharedPreferences
//   Future<void> _loadCallInfo() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       _currentCallId = prefs.getString('active_call_id');
//       _callerId = prefs.getString('active_call_user_id');
//       _callerName = prefs.getString('active_call_name');
//       _callerAvatar = prefs.getString('active_call_avatar');
//       _isVideoCall = prefs.getBool('active_call_has_video') ?? false;
//
//       if (_currentCallId != null) {
//         debugPrint('Loaded call info - Call ID: $_currentCallId, Caller: $_callerName');
//       }
//     } catch (e) {
//       debugPrint('Error loading call info: $e');
//     }
//   }
//
//   /// Clear call information from SharedPreferences and reset state
//   Future<void> _clearCallInfo() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       // Clear call-related preferences
//       await prefs.remove('active_call_id');
//       await prefs.remove('active_call_user_id');
//       await prefs.remove('active_call_name');
//       await prefs.remove('active_call_avatar');
//       await prefs.remove('active_call_has_video');
//       await prefs.remove('active_call_timestamp');
//
//       // Reset local state
//       _currentCallId = null;
//       _callerId = null;
//       _callerName = null;
//       _callerAvatar = null;
//       _isVideoCall = false;
//       _hasActiveCall = false;
//
//       notifyListeners();
//       debugPrint('Call information cleared');
//
//       // Also clear any notifications to prevent duplicates
//       try {
//         if (Platform.isAndroid) {
//           await ClearAllNotifications.clear();
//         }
//       } catch (e) {
//         // Ignore errors clearing notifications
//       }
//     } catch (e) {
//       debugPrint('Error clearing call info: $e');
//     }
//   }
//
//   /// Save call information to SharedPreferences for persistence
//   Future<void> _saveCallInfo(
//       String callId,
//       String callerId,
//       String callerName,
//       String callerAvatar,
//       bool isVideoCall
//       ) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       // Save call information
//       await prefs.setString('active_call_id', callId);
//       await prefs.setString('active_call_user_id', callerId);
//       await prefs.setString('active_call_name', callerName);
//       await prefs.setString('active_call_avatar', callerAvatar);
//       await prefs.setBool('active_call_has_video', isVideoCall);
//       await prefs.setInt('active_call_timestamp', DateTime.now().millisecondsSinceEpoch);
//
//       // Update local state
//       _currentCallId = callId;
//       _callerId = callerId;
//       _callerName = callerName;
//       _callerAvatar = callerAvatar;
//       _isVideoCall = isVideoCall;
//
//       debugPrint('Call information saved - Call ID: $callId, Caller: $callerName');
//     } catch (e) {
//       debugPrint('Error saving call info: $e');
//     }
//   }
//
//   /// Handle an incoming call notification
//   Future<void> handleIncomingCall({
//     required String callId,
//     required String callerId,
//     required String callerName,
//     required String callerAvatar,
//     required bool isVideoCall,
//   }) async {
//     // Check if this call has already been accepted or is currently active or recently handled
//     if (_isCallAlreadyAccepted(callId) ||
//         (_currentCallId == callId && _hasActiveCall) ||
//         _isRecentlyHandledNotification(callId) ||
//         _isAcceptingCall) {
//       debugPrint('Call already accepted or notification recently handled, updating UI for: $callId');
//
//       // Just ensure the call screen is visible
//       await callKitService.resumeCallScreenIfNeeded();
//
//       // Clear any pending call info to prevent duplicate processing
//       await _clearPendingCallInfo();
//
//       return;
//     }
//
//     // Mark notification as handled immediately to prevent duplicates
//     _markNotificationHandled(callId);
//
//     // First, save call info to preferences immediately regardless of initialization state
//     await _saveCallInfoToPreferences(
//         callId, callerId, callerName, callerAvatar, isVideoCall);
//
//     // Use a lock to prevent duplicate handling of the same call
//     final lockKey = 'incoming_$callId';
//     if (_apiCallLocks[lockKey] == true) {
//       debugPrint('Already handling incoming call: $callId');
//       return;
//     }
//
//     _apiCallLocks[lockKey] = true;
//     _isHandlingIncomingCall = true;
//
//     try {
//       debugPrint('Handling incoming call: $callId from $callerName (video: $isVideoCall)');
//
//       // Save current app state
//       String previousAppState = _appState;
//
//       // Save call information for persistence
//       await _saveCallInfo(callId, callerId, callerName, callerAvatar, isVideoCall);
//
//       // Update state
//       _hasActiveCall = true;
//       notifyListeners();
//
//       // First, call the ringing API to notify the server
//       if (_isInitialized && _callApiService != null) {
//         try {
//           // Only call if we haven't recently called it
//           if (!_hasRecentlyCalledApi('ringing_$callId')) {
//             await _callApiService!.callRinging(
//               callId: callId,
//               callerId: callerId,
//             );
//             _markApiCallTimestamp('ringing_$callId');
//             debugPrint('Called ringing API for call: $callId');
//           } else {
//             debugPrint('Skipping duplicate ringing API call for: $callId');
//           }
//         } catch (e) {
//           debugPrint('Error calling ringing API: $e');
//           // Continue even if this API fails
//         }
//       }
//
//       // Check if we already have an active call UI before showing a new one
//       List<dynamic> activeCalls = [];
//       try {
//         activeCalls = await callKitService.getActiveCalls();
//       } catch (e) {
//         try {
//           final result = await FlutterCallkitIncoming.activeCalls();
//           activeCalls = result as List? ?? [];
//         } catch (e2) {
//           // Ignore errors
//         }
//       }
//
//       bool callAlreadyActive = activeCalls.any((call) => call['id'] == callId);
//       if (!callAlreadyActive) {
//         // Show incoming call UI via CallKit
//         try {
//           await callKitService.displayIncomingCall(
//             uuid: callId,
//             callerName: callerName,
//             callerId: callerId,
//             avatar: callerAvatar,
//             hasVideo: isVideoCall,
//           );
//           debugPrint('Successfully displayed incoming call UI');
//         } catch (e) {
//           debugPrint('Error displaying incoming call UI: $e');
//           // Try with a delay
//           _retryDisplayIncomingCall(callId, callerName, callerId, callerAvatar, isVideoCall);
//         }
//       } else {
//         debugPrint('Call already active in CallKit, not showing duplicate UI');
//       }
//
//       // If app was in foreground, navigate to call screen directly
//       if (previousAppState == 'foreground') {
//         navigateToCallScreen(
//           callId: callId,
//           userId: callerId,
//           userName: callerName,
//           avatar: callerAvatar,
//           isVideoCall: isVideoCall,
//         );
//       }
//     } catch (e) {
//       debugPrint('Error handling incoming call: $e');
//     } finally {
//       // Release locks
//       _apiCallLocks[lockKey] = false;
//       _isHandlingIncomingCall = false;
//     }
//   }
//
//   // Save call info to SharedPreferences directly (for use when service is not initialized)
//   Future<void> _saveCallInfoToPreferences(
//       String callId,
//       String callerId,
//       String callerName,
//       String callerAvatar,
//       bool isVideoCall
//       ) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       // Save pending call information for later handling
//       await prefs.setString('pending_call_id', callId);
//       await prefs.setInt('pending_call_timestamp', DateTime.now().millisecondsSinceEpoch);
//       await prefs.setString('pending_caller_id', callerId);
//       await prefs.setString('pending_caller_name', callerName);
//       await prefs.setString('pending_caller_avatar', callerAvatar);
//       await prefs.setBool('pending_call_has_video', isVideoCall);
//
//       debugPrint('Saved call info to preferences for later handling: $callId');
//     } catch (e) {
//       debugPrint('Error saving call info to preferences: $e');
//     }
//   }
//
//   // Retry displaying incoming call UI
//   void _retryDisplayIncomingCall(
//       String callId,
//       String callerName,
//       String callerId,
//       String callerAvatar,
//       bool isVideoCall
//       ) {
//     Future.delayed(Duration(milliseconds: 500), () {
//       try {
//         callKitService.displayIncomingCall(
//           uuid: callId,
//           callerName: callerName,
//           callerId: callerId,
//           avatar: callerAvatar,
//           hasVideo: isVideoCall,
//         );
//         debugPrint('Successfully displayed incoming call UI on retry');
//       } catch (e) {
//         debugPrint('Retry also failed to display incoming call UI: $e');
//       }
//     });
//   }
//
//   /// Check if we've recently called an API to prevent duplicates
//   bool _hasRecentlyCalledApi(String apiKey) {
//     final lastTimestamp = _lastApiCallTimestamps[apiKey];
//     if (lastTimestamp == null) return false;
//
//     final now = DateTime.now();
//     final difference = now.difference(lastTimestamp);
//
//     // Consider API calls within 2 seconds as duplicates
//     return difference.inSeconds < 2;
//   }
//
//   /// Mark an API call timestamp to prevent duplicates
//   void _markApiCallTimestamp(String apiKey) {
//     _lastApiCallTimestamps[apiKey] = DateTime.now();
//   }
//
//   /// Handle user accepting a call
//   Future<void> handleCallAccepted(String callId) async {
//     // Prevent duplicate acceptances
//     if (_isAcceptingCall || _isCallAlreadyAccepted(callId)) {
//       debugPrint('Already accepting call or call already accepted: $callId');
//       return;
//     }
//
//     _isAcceptingCall = true;
//
//     try {
//       // Mark this call as accepted to prevent duplicates
//       await _markCallAsAccepted(callId);
//
//       // Clear all notifications to prevent duplicates
//       try {
//         if (Platform.isAndroid) {
//           await ClearAllNotifications.clear();
//         }
//       } catch (e) {
//         // Ignore errors
//       }
//
//       // Clear any pending call info
//       await _clearPendingCallInfo();
//
//       debugPrint('Call accepted: $callId');
//     } finally {
//       _isAcceptingCall = false;
//     }
//   }
//
//   /// Make an outgoing call
//   Future<Map<String, dynamic>> makeCall({
//     required String userId,
//     required String userName,
//     required String userAvatar,
//     required bool isVideoCall,
//   }) async {
//     // Check initialization
//     if (!_isInitialized || _callApiService == null) {
//       debugPrint('CallService not initialized for outgoing call');
//       return {
//         'success': false,
//         'message': 'Call service not initialized',
//       };
//     }
//
//     // Use a lock to prevent duplicate calls
//     final lockKey = 'outgoing_$userId';
//     if (_apiCallLocks[lockKey] == true) {
//       debugPrint('Already making a call to: $userId');
//       return {
//         'success': false,
//         'message': 'Call already in progress',
//       };
//     }
//
//     _apiCallLocks[lockKey] = true;
//
//     try {
//       debugPrint('Making call to $userName ($userId), video: $isVideoCall');
//
//       // Check if there are any active calls first and end them
//       try {
//         List<dynamic> activeCalls = [];
//         try {
//           activeCalls = await callKitService.getActiveCalls();
//         } catch (e) {
//           try {
//             final result = await FlutterCallkitIncoming.activeCalls();
//             activeCalls = result as List? ?? [];
//           } catch (e2) {
//             // Ignore errors
//           }
//         }
//
//         if (activeCalls.isNotEmpty) {
//           debugPrint('Ending active calls before making new call');
//           await callKitService.endAllCalls();
//           await _clearCallInfo();
//
//           // Small delay to ensure cleanup
//           await Future.delayed(Duration(milliseconds: 300));
//         }
//       } catch (e) {
//         // Ignore errors, continue with call
//       }
//
//       // Call the CallKit service to initiate the call
//       final result = await callKitService.startOutgoingCall(
//         userId: userId,
//         calleeName: userName,
//         avatar: userAvatar,
//         hasVideo: isVideoCall,
//       );
//
//       if (result['success'] == true && result['callId'] != null) {
//         final callId = result['callId'].toString();
//
//         // Mark this call as accepted
//         await _markCallAsAccepted(callId);
//
//         // Mark notification as handled
//         _markNotificationHandled(callId);
//
//         // Save call information for recovery
//         await _saveCallInfo(callId, userId, userName, userAvatar, isVideoCall);
//
//         // Update state
//         _hasActiveCall = true;
//         notifyListeners();
//
//         return result;
//       } else {
//         throw Exception(result['message'] ?? 'Failed to start call');
//       }
//     } catch (e) {
//       debugPrint('Error making call: $e');
//       return {
//         'success': false,
//         'message': 'Error: $e',
//       };
//     } finally {
//       // Release the lock after a delay
//       Future.delayed(Duration(seconds: 3), () {
//         _apiCallLocks[lockKey] = false;
//       });
//     }
//   }
//
//   /// End the current call
//   Future<void> endCall() async {
//     if (_currentCallId == null) {
//       debugPrint('No active call to end');
//
//       // Try to end any active calls anyway
//       try {
//         List<dynamic> activeCalls = [];
//         try {
//           activeCalls = await callKitService.getActiveCalls();
//         } catch (e) {
//           try {
//             final result = await FlutterCallkitIncoming.activeCalls();
//             activeCalls = result as List? ?? [];
//           } catch (e2) {
//             // Ignore errors
//           }
//         }
//
//         if (activeCalls.isNotEmpty) {
//           for (var call in activeCalls) {
//             final callId = call['id']?.toString() ?? '';
//             if (callId.isNotEmpty) {
//               await callKitService.endCall(callId);
//             }
//           }
//         }
//       } catch (e) {
//         // Ignore errors
//       }
//
//       return;
//     }
//
//     final callId = _currentCallId!;
//
//     // Use a lock to prevent duplicate end calls
//     final lockKey = 'end_$callId';
//     if (_apiCallLocks[lockKey] == true || _isEndingCall) {
//       debugPrint('Already ending call: $callId');
//       return;
//     }
//
//     _apiCallLocks[lockKey] = true;
//     _isEndingCall = true;
//     notifyListeners(); // Notify about ending state change
//
//     try {
//       debugPrint('Beginning call end process for: $callId');
//
//       // First, let the API know we're ending the call (if initialized)
//       if (_isInitialized && _callApiService != null) {
//         try {
//           await _callApiService!.endCall(callId: callId);
//           debugPrint('API call successful to end call: $callId');
//         } catch (e) {
//           debugPrint('Error with API call to end call: $e, continuing with UI cleanup');
//           // Continue with cleanup even if API call fails
//         }
//       }
//
//       // Next, end the call in CallKit to dismiss UI notifications
//       try {
//         await callKitService.endCall(callId);
//         debugPrint('Successfully ended call in CallKit: $callId');
//       } catch (e) {
//         debugPrint('Error ending call in CallKit: $e, continuing with UI cleanup');
//         // Fallback to direct method if CallKitService fails
//         try {
//           await FlutterCallkitIncoming.endCall(callId);
//         } catch (e2) {
//           debugPrint('Error with direct endCall: $e2');
//         }
//       }
//
//       // Clear all notifications to prevent duplicates
//       try {
//         if (Platform.isAndroid) {
//           await ClearAllNotifications.clear();
//         }
//       } catch (e) {
//         // Ignore errors
//       }
//
//       // Clear call information
//       await _clearCallInfo();
//
//       // Remove from accepted calls to allow future calls with the same ID
//       _acceptedCalls.remove(callId);
//       await _saveAcceptedCalls();
//
//       // Pop the call screen if it's still open
//       try {
//         final navigatorKey = NavigatorService.navigatorKey;
//         if (navigatorKey.currentState != null) {
//           navigatorKey.currentState?.maybePop();
//         }
//       } catch (e) {
//         debugPrint('Error popping call screen: $e');
//       }
//
//       debugPrint('Call end process completed for: $callId');
//     } catch (e) {
//       debugPrint('Error in end call process: $e');
//     } finally {
//       // Release locks
//       _apiCallLocks[lockKey] = false;
//       _isEndingCall = false;
//       notifyListeners(); // Notify listeners about the end of call
//     }
//   }
//
//   /// Handle app lifecycle changes
//   void handleAppLifecycleState(AppLifecycleState state) {
//     debugPrint('App lifecycle state: $state');
//
//     switch (state) {
//       case AppLifecycleState.resumed:
//         _isInForeground = true;
//         _appState = 'foreground';
//
//         // Clear notifications when app comes to foreground
//         try {
//           if (Platform.isAndroid) {
//             ClearAllNotifications.clear();
//           }
//         } catch (e) {
//           // Ignore errors
//         }
//
//         // Check for active calls when resuming
//         if (_hasActiveCall && _currentCallId != null) {
//           _verifyActiveCallOnResume();
//         } else {
//           _checkForMissedCalls();
//         }
//         break;
//
//       case AppLifecycleState.paused:
//         _isInForeground = false;
//         _appState = 'background';
//         break;
//
//       case AppLifecycleState.inactive:
//         _appState = 'inactive';
//         break;
//
//       case AppLifecycleState.detached:
//         _isInForeground = false;
//         _appState = 'detached';
//         break;
//       case AppLifecycleState.hidden:
//         _isInForeground = false;
//         _appState = 'hidden';
//         break;
//     }
//   }
//
//   /// Verify if a call is still active when resuming the app
//   Future<void> _verifyActiveCallOnResume() async {
//     if (_currentCallId == null) return;
//
//     try {
//       debugPrint('Verifying active call on resume: $_currentCallId');
//
//       // Check if the call is still in CallKit
//       List<dynamic> activeCalls = [];
//       try {
//         activeCalls = await callKitService.getActiveCalls();
//       } catch (e) {
//         try {
//           final result = await FlutterCallkitIncoming.activeCalls();
//           activeCalls = result as List? ?? [];
//         } catch (e2) {
//           // Ignore errors
//         }
//       }
//
//       final isInCallKit = activeCalls.any((call) => call['id'] == _currentCallId);
//
//       if (!isInCallKit) {
//         debugPrint('Call not found in CallKit on resume: $_currentCallId');
//         await _clearCallInfo();
//
//         // Remove from accepted calls
//         _acceptedCalls.remove(_currentCallId);
//         await _saveAcceptedCalls();
//
//         return;
//       }
//
//       // Verify with server
//       bool isActive = await _verifyCallWithServer(_currentCallId!);
//
//       if (!isActive) {
//         debugPrint('Call not active according to server on resume: $_currentCallId');
//         await callKitService.endCall(_currentCallId!);
//         await _clearCallInfo();
//
//         // Remove from accepted calls
//         _acceptedCalls.remove(_currentCallId);
//         await _saveAcceptedCalls();
//       } else {
//         // Call is still active, ensure call screen is visible
//         debugPrint('Call still active on resume, ensuring call screen is visible');
//         await callKitService.resumeCallScreenIfNeeded();
//       }
//     } catch (e) {
//       debugPrint('Error verifying call on resume: $e');
//     }
//   }
//
//   /// Check for missed calls when resuming the app
//   Future<void> _checkForMissedCalls() async {
//     try {
//       debugPrint('Checking for missed calls');
//
//       // Check for active calls in CallKit
//       List<dynamic> activeCalls = [];
//       try {
//         activeCalls = await callKitService.getActiveCalls();
//       } catch (e) {
//         try {
//           final result = await FlutterCallkitIncoming.activeCalls();
//           activeCalls = result as List? ?? [];
//         } catch (e2) {
//           // Ignore errors
//         }
//       }
//
//       if (activeCalls.isNotEmpty) {
//         final call = activeCalls.first;
//         final callId = call['id']?.toString() ?? '';
//
//         // Check if this call has already been accepted or recently handled
//         if (_isCallAlreadyAccepted(callId) || _isRecentlyHandledNotification(callId)) {
//           debugPrint('Call already accepted or notification recently handled, ensuring it\'s visible: $callId');
//           await callKitService.resumeCallScreenIfNeeded();
//           return;
//         }
//
//         // Mark as handled immediately to prevent duplicates
//         _markNotificationHandled(callId);
//
//         debugPrint('Found missed call on resume: $callId');
//
//         // Verify call is still active
//         bool isActive = await _verifyCallWithServer(callId);
//
//         if (isActive) {
//           // Mark this call as accepted
//           await _markCallAsAccepted(callId);
//
//           // Update state with call information
//           final extra = call['extra'] is Map ?
//           Map<String, dynamic>.from(call['extra'] as Map) :
//           <String, dynamic>{};
//
//           _callerId = extra['userId']?.toString() ?? '';
//           _callerName = call['nameCaller']?.toString() ?? 'Unknown';
//           _callerAvatar = extra['avatar']?.toString() ?? '';
//           _isVideoCall = extra['has_video'] == true || extra['has_video'] == 'true';
//           _currentCallId = callId;
//           _hasActiveCall = true;
//
//           // Save call information
//           await _saveCallInfo(callId, _callerId!, _callerName!, _callerAvatar!, _isVideoCall);
//
//           notifyListeners();
//
//           // Resume call screen
//           await callKitService.resumeCallScreenIfNeeded();
//         } else {
//           // Call is no longer active
//           debugPrint('Missed call no longer active, cleaning up: $callId');
//           await callKitService.endCall(callId);
//
//           // Remove from accepted calls
//           _acceptedCalls.remove(callId);
//           await _saveAcceptedCalls();
//         }
//       }
//
//       // Also check for pending calls
//       await _checkForPendingCalls();
//     } catch (e) {
//       debugPrint('Error checking for missed calls: $e');
//     }
//   }
//
//   /// Navigate to call screen (when accepting a call)
//   Future<void> navigateToCallScreen({
//     required String callId,
//     required String userId,
//     required String userName,
//     required String avatar,
//     required bool isVideoCall,
//   }) async {
//     // Mark this call as accepted before navigating
//     await _markCallAsAccepted(callId);
//
//     // Navigate to the call screen
//     final navigatorKey = NavigatorService.navigatorKey;
//
//     if (navigatorKey.currentState == null) {
//       debugPrint('Navigator state is null, cannot navigate to call screen');
//       return;
//     }
//
//     debugPrint('Navigating to call screen for: $callId, caller: $userName');
//
//     // Use pushNamed for consistency and to allow for predictable navigation
//     navigatorKey.currentState!.pushNamed(
//       '/call',
//       arguments: {
//         'callId': callId,
//         'contactId': userId,
//         'contactName': userName,
//         'contactAvatar': avatar,
//         'isIncoming': true,
//         'isVideoCall': isVideoCall,
//         'token': '',
//       },
//     );
//   }
//
//   /// Method to update an existing call instead of creating a new one
//   /// This is used when a subsequent notification for the same call arrives
//   Future<void> updateExistingCall({
//     required String callId,
//     required String callerId,
//     required String callerName,
//     required String callerAvatar,
//     required bool isVideoCall,
//   }) async {
//     try {
//       // Check if notification was recently handled
//       if (_isRecentlyHandledNotification(callId)) {
//         debugPrint('Notification recently handled, ignoring duplicate: $callId');
//         return;
//       }
//
//       // Mark as handled immediately to prevent duplicates
//       _markNotificationHandled(callId);
//
//       // Check if this is already our active call
//       if (_currentCallId == callId && _hasActiveCall) {
//         debugPrint('Already handling this call as active call: $callId');
//
//         // If we're in the background, make sure the call screen is visible
//         if (!_isInForeground) {
//           await callKitService.resumeCallScreenIfNeeded();
//         }
//
//         return;
//       }
//
//       // Check if call is in CallKit but not active in our service
//       List<dynamic> activeCalls = [];
//       try {
//         activeCalls = await callKitService.getActiveCalls();
//       } catch (e) {
//         try {
//           final result = await FlutterCallkitIncoming.activeCalls();
//           activeCalls = result as List? ?? [];
//         } catch (e2) {
//           // Ignore errors
//         }
//       }
//
//       final isInCallKit = activeCalls.any((call) => call['id'] == callId);
//
//       if (isInCallKit) {
//         // We have the call in CallKit but not as active - update our state
//         debugPrint('Call found in CallKit but not active in service, updating state: $callId');
//
//         // Update local state
//         _callerId = callerId;
//         _callerName = callerName;
//         _callerAvatar = callerAvatar;
//         _isVideoCall = isVideoCall;
//         _currentCallId = callId;
//         _hasActiveCall = true;
//
//         // Save call information for persistence
//         await _saveCallInfo(callId, callerId, callerName, callerAvatar, isVideoCall);
//
//         // Mark as accepted
//         await _markCallAsAccepted(callId);
//
//         // Update UI if needed
//         notifyListeners();
//
//         // Make sure call UI is visible
//         await callKitService.resumeCallScreenIfNeeded();
//
//         return;
//       }
//
//       // Call is not in CallKit or active, handle as new call but without duplicate UI
//       debugPrint('Call not found in active state, handling as update: $callId');
//
//       // Save call information
//       await _saveCallInfo(callId, callerId, callerName, callerAvatar, isVideoCall);
//
//       // Update state
//       _currentCallId = callId;
//       _callerId = callerId;
//       _callerName = callerName;
//       _callerAvatar = callerAvatar;
//       _isVideoCall = isVideoCall;
//       _hasActiveCall = true;
//
//       // Mark as accepted to prevent duplicate processing
//       await _markCallAsAccepted(callId);
//
//       // Use CallKit to update the call state if needed
//       try {
//         await callKitService.updateCallState(
//             callId: callId,
//             callerName: callerName,
//             callerId: callerId,
//             avatar: callerAvatar,
//             hasVideo: isVideoCall
//         );
//       } catch (e) {
//         debugPrint('Error updating call state: $e');
//         // If updating fails, try to display a new call
//         try {
//           await callKitService.displayIncomingCall(
//             uuid: callId,
//             callerName: callerName,
//             callerId: callerId,
//             avatar: callerAvatar,
//             hasVideo: isVideoCall,
//           );
//         } catch (e2) {
//           debugPrint('Error displaying call: $e2');
//         }
//       }
//
//       // Update UI
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error updating existing call: $e');
//     }
//   }
//
//   // Clean up resources
//   @override
//   void dispose() {
//     _initRetryTimer?.cancel();
//     super.dispose();
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctak_app/presentation/calling_module/services/callkit_service.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:clear_all_notifications/clear_all_notifications.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';

import 'call_api_service.dart';

/// Global service to handle call functionality throughout the app lifecycle
/// This service coordinates with CallKitService to manage calls
class CallService extends ChangeNotifier {
  // Singleton instance with lazy initialization
  static CallService? _instance;

  // Use factory constructor for singleton pattern
  factory CallService() {
    // Create instance if it doesn't exist
    _instance ??= CallService._internal();
    return _instance!;
  }

  // Private constructor
  CallService._internal();

  // Use nullable fields with getters for safe access
  CallKitService? _callKitService;
  CallApiService? _callApiService;

  // Safe access to CallKitService with lazy initialization
  CallKitService get callKitService {
    _callKitService ??= CallKitService();
    return _callKitService!;
  }

  // State management
  bool _isInitialized = false;
  bool _isInitializing = false;
  bool _hasActiveCall = false;
  bool _isHandlingIncomingCall = false;
  bool _isInForeground = true;
  String? _currentCallId;
  String _appState = 'inactive'; // inactive, foreground, background

  // Flag to track if we're currently ending a call
  bool _isEndingCall = false;

  // Flag to track if we're in the process of handling a call acceptance
  bool _isAcceptingCall = false;

  // Timestamp of last handled notification to prevent duplicates
  Map<String, int> _lastHandledNotification = {};

  // Map to track accepted calls to prevent duplicates
  final Map<String, DateTime> _acceptedCalls = {};

  // Locks to prevent duplicate API calls
  final Map<String, bool> _apiCallLocks = {};
  final Map<String, DateTime> _lastApiCallTimestamps = {};

  // Call information
  String? _callerId;
  String? _callerName;
  String? _callerAvatar;
  bool _isVideoCall = false;

  // Initialization retry mechanism
  int _initRetryCount = 0;
  Timer? _initRetryTimer;
  Completer<bool>? _initializationCompleter;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get hasActiveCall => _hasActiveCall;
  String? get currentCallId => _currentCallId;
  bool get isVideoCall => _isVideoCall;
  bool get isEndingCall => _isEndingCall;
  bool get isAcceptingCall => _isAcceptingCall;

  /// Initialize the CallService
  Future<bool> initialize({
    required String baseUrl,
    bool isFromCallNotification = false,
  }) async {
    // If initialization is already in progress, wait for it to complete
    if (_isInitializing && _initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    // If already initialized with the same base URL, just return true
    if (_isInitialized && _callApiService != null && _callApiService!.baseUrl == baseUrl) {
      debugPrint('CallService already initialized with the same baseUrl');
      return true;
    }

    // Cancel any existing retry timer
    _initRetryTimer?.cancel();

    // Create a new completer for this initialization attempt
    _initializationCompleter = Completer<bool>();
    _isInitializing = true;

    try {
      // Initialize API service with base URL
      _callApiService = CallApiService(baseUrl: baseUrl);
      _isInitialized = true;

      debugPrint('CallService initialized successfully with baseUrl: $baseUrl');

      // Initialize CallKitService if it hasn't been already
      if (_callKitService == null) {
        _callKitService = CallKitService();
        await _callKitService!.initialize(
          baseUrl: baseUrl,
          shouldUpdateStatus: false, // Let CallService handle status updates
        );
      }

      // Listen to CallKit events
      _setupCallKitListeners();

      // Load previously accepted calls from SharedPreferences
      await _loadAcceptedCalls();

      // If launched from notification, we'll handle it in handleIncomingCall
      if (isFromCallNotification) {
        debugPrint('App launched from call notification');

        // Check for pending call info
        await _checkForPendingCalls();
      } else {
        // Check for any existing calls (app startup)
        await _checkForActiveCalls();
      }

      // Reset retry count on successful initialization
      _initRetryCount = 0;

      // Complete the initialization
      _initializationCompleter?.complete(true);
      _isInitializing = false;

      return true;
    } catch (e) {
      debugPrint('Error initializing CallService: $e');

      // Try to initialize with alternate URL if main URL fails
      if (baseUrl != AppData.remoteUrl3) {
        try {
          _callApiService = CallApiService(baseUrl: AppData.remoteUrl3);
          _isInitialized = true;
          debugPrint('CallService initialized with fallback URL');

          // Complete the initialization
          _initializationCompleter?.complete(true);
          _isInitializing = false;

          return true;
        } catch (e2) {
          // Both URLs failed, continue with retry logic
          debugPrint('Error initializing with fallback URL: $e2');
        }
      }

      // Retry initialization with increasing delay if needed
      if (_initRetryCount < 3) {
        _retryInitialization(baseUrl, isFromCallNotification);
        return _initializationCompleter!.future;
      } else {
        _isInitialized = false;
        _isInitializing = false;
        _initializationCompleter?.complete(false);
        return false;
      }
    }
  }

  // Load accepted calls from SharedPreferences
  Future<void> _loadAcceptedCalls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final acceptedCallsJson = prefs.getStringList('accepted_calls') ?? [];

      // Clear existing entries
      _acceptedCalls.clear();

      // Parse and add entries
      for (final entry in acceptedCallsJson) {
        final parts = entry.split('|');
        if (parts.length == 2) {
          final callId = parts[0];
          final timestamp = int.tryParse(parts[1]) ?? 0;

          if (timestamp > 0) {
            _acceptedCalls[callId] = DateTime.fromMillisecondsSinceEpoch(timestamp);
          }
        }
      }

      debugPrint('Loaded ${_acceptedCalls.length} accepted calls from preferences');
    } catch (e) {
      debugPrint('Error loading accepted calls: $e');
    }
  }

  // Save accepted calls to SharedPreferences
  Future<void> _saveAcceptedCalls() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clean up old entries (older than 5 minutes)
      final now = DateTime.now();
      _acceptedCalls.removeWhere((_, timestamp) =>
      now.difference(timestamp).inMinutes > 5);

      // Convert to string list
      final acceptedCallsJson = _acceptedCalls.entries.map((entry) =>
      '${entry.key}|${entry.value.millisecondsSinceEpoch}').toList();

      // Save to preferences
      await prefs.setStringList('accepted_calls', acceptedCallsJson);

      debugPrint('Saved ${_acceptedCalls.length} accepted calls to preferences');
    } catch (e) {
      debugPrint('Error saving accepted calls: $e');
    }
  }

  // Mark a call as accepted
  Future<void> _markCallAsAccepted(String callId) async {
    _acceptedCalls[callId] = DateTime.now();
    await _saveAcceptedCalls();

    // Also clear any notifications to prevent duplicates
    try {
      if (Platform.isAndroid) {
        await ClearAllNotifications.clear();
      }
    } catch (e) {
      // Ignore errors clearing notifications
    }

    debugPrint('Marked call as accepted: $callId');
  }

  // Check if a call has already been accepted
  bool _isCallAlreadyAccepted(String callId) {
    final timestamp = _acceptedCalls[callId];
    if (timestamp == null) return false;

    // Consider a call as accepted if it was accepted in the last 5 minutes
    final now = DateTime.now();
    return now.difference(timestamp).inMinutes < 5;
  }

  // Check if notification was recently handled to prevent duplicates
  bool _isRecentlyHandledNotification(String callId) {
    final lastTimestamp = _lastHandledNotification[callId];
    if (lastTimestamp == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    // Consider notifications within 3 seconds as duplicates
    return (now - lastTimestamp < 3000);
  }

  // Mark notification as handled
  void _markNotificationHandled(String callId) {
    _lastHandledNotification[callId] = DateTime.now().millisecondsSinceEpoch;
  }

  // Retry initialization with exponential backoff
  void _retryInitialization(String baseUrl, bool isFromCallNotification) {
    _initRetryCount++;
    final delay = Duration(milliseconds: 300 * _initRetryCount);

    debugPrint('Will retry initialization in ${delay.inMilliseconds}ms (attempt $_initRetryCount)');

    _initRetryTimer = Timer(delay, () {
      initialize(baseUrl: baseUrl, isFromCallNotification: isFromCallNotification)
          .then((success) {
        if (!success && _initRetryCount < 3) {
          _retryInitialization(baseUrl, isFromCallNotification);
        }
      });
    });
  }

  // Get or initialize the CallApiService
  Future<CallApiService> _getOrCreateApiService() async {
    // If already initialized, return the existing service
    if (_isInitialized && _callApiService != null) {
      return _callApiService!;
    }

    // If initialization is in progress, wait for it to complete
    if (_isInitializing && _initializationCompleter != null) {
      final success = await _initializationCompleter!.future;
      if (success && _callApiService != null) {
        return _callApiService!;
      }
    }

    // Otherwise, create a new service with default URL
    return CallApiService(baseUrl: AppData.remoteUrl3);
  }

  // Check for pending calls
  Future<void> _checkForPendingCalls() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingCallId = prefs.getString('pending_call_id');

      if (pendingCallId != null) {
        // Check if this call has already been accepted
        if (_isCallAlreadyAccepted(pendingCallId) || _isRecentlyHandledNotification(pendingCallId)) {
          debugPrint('Call already accepted or notification recently handled, ignoring: $pendingCallId');
          await _clearPendingCallInfo();
          return;
        }

        final pendingTimestamp = prefs.getInt('pending_call_timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Only consider calls within the last 30 seconds
        if (now - pendingTimestamp < 30000) {
          debugPrint('Found pending call from notification: $pendingCallId');

          // Mark as handled immediately to prevent duplicates
          _markNotificationHandled(pendingCallId);

          // Extract call information
          final callerId = prefs.getString('pending_caller_id') ?? '';
          final callerName = prefs.getString('pending_caller_name') ?? 'Unknown';
          final avatar = prefs.getString('pending_caller_avatar') ?? '';
          final hasVideo = prefs.getBool('pending_call_has_video') ?? false;

          // Handle the call
          await handleIncomingCall(
            callId: pendingCallId,
            callerId: callerId,
            callerName: callerName,
            callerAvatar: avatar,
            isVideoCall: hasVideo,
          );
        } else {
          // Call info is too old, clean up
          await _clearPendingCallInfo();
        }
      }
    } catch (e) {
      debugPrint('Error checking for pending calls: $e');
    }
  }

  // Clean up pending call info
  Future<void> _clearPendingCallInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_call_id');
      await prefs.remove('pending_call_timestamp');
      await prefs.remove('pending_caller_id');
      await prefs.remove('pending_caller_name');
      await prefs.remove('pending_caller_avatar');
      await prefs.remove('pending_call_has_video');

      // Also clear any notifications to prevent duplicates
      try {
        if (Platform.isAndroid) {
          await ClearAllNotifications.clear();
        }
      } catch (e) {
        // Ignore errors clearing notifications
      }
    } catch (e) {
      debugPrint('Error clearing pending call info: $e');
    }
  }

  /// Set up listeners for CallKit events
  void _setupCallKitListeners() {
    try {
      callKitService.listenToCallEvents();
      debugPrint('CallKit listeners set up successfully');
    } catch (e) {
      debugPrint('Error setting up CallKit listeners: $e');
    }
  }

  /// Check for any active calls at startup
  Future<void> _checkForActiveCalls() async {
    if (!_isInitialized && !_isInitializing) {
      debugPrint('CallService not initialized, cannot check for active calls');

      // Try to initialize with default URL
      final initialized = await initialize(baseUrl: AppData.remoteUrl3);
      if (!initialized) {
        return;
      }
    }

    try {
      // First check for active calls in CallKit
      List<dynamic> activeCalls = [];
      try {
        // Try to use the service method first
        activeCalls = await callKitService.getActiveCalls();
      } catch (e) {
        // If that fails, try direct FlutterCallkitIncoming call
        try {
          final result = await FlutterCallkitIncoming.activeCalls();
          activeCalls = result as List? ?? [];
        } catch (e2) {
          debugPrint('Error checking active calls: $e2');
        }
      }

      if (activeCalls.isNotEmpty) {
        final call = activeCalls.first;
        final callId = call['id']?.toString() ?? '';

        // Check if this call has already been accepted
        if (_isCallAlreadyAccepted(callId) || _isRecentlyHandledNotification(callId)) {
          debugPrint('Call already accepted or notification recently handled, ensuring it\'s visible: $callId');
          await callKitService.resumeCallScreenIfNeeded();
          return;
        }

        // Mark as handled immediately to prevent duplicates
        _markNotificationHandled(callId);

        // Verify the call timestamp is recent
        final now = DateTime.now().millisecondsSinceEpoch;
        final prefs = await SharedPreferences.getInstance();
        final timestamp = prefs.getInt('active_call_timestamp') ?? 0;

        // Only consider recent calls (less than 60 seconds old)
        if (now - timestamp > 60000) {
          debugPrint('Found stale call in CallKit, cleaning up: $callId');
          await callKitService.endCall(callId);
          await _clearCallInfo();
          return;
        }

        // Verify call is active with server if possible
        bool isActive = await _verifyCallWithServer(callId,);
        if (!isActive) {
          debugPrint('Call not active according to server: $callId');
          await callKitService.endCall(callId);
          await _clearCallInfo();
          return;
        }

        // Extract call information from CallKit
        debugPrint('Found active call in CallKit: $callId');

        // Mark this call as accepted
        await _markCallAsAccepted(callId);

        // Extract call information
        final extra = call['extra'] is Map ?
        Map<String, dynamic>.from(call['extra'] as Map) :
        <String, dynamic>{};

        _callerId = extra['userId']?.toString() ?? '';
        _callerName = call['nameCaller']?.toString() ?? 'Unknown';
        _callerAvatar = extra['avatar']?.toString() ?? '';
        _isVideoCall = extra['has_video'] == true || extra['has_video'] == 'true';
        _currentCallId = callId;
        _hasActiveCall = true;

        // Save call information for recovery
        await _saveCallInfo(callId, _callerId!, _callerName!, _callerAvatar!, _isVideoCall);

        notifyListeners();
      } else {
        // No calls in CallKit, check preferences
        await _loadCallInfo();

        if (_currentCallId != null) {
          // Check if this call has already been accepted
          if (_isCallAlreadyAccepted(_currentCallId!) || _isRecentlyHandledNotification(_currentCallId!)) {
            debugPrint('Call already accepted or notification recently handled, ensuring it\'s visible: $_currentCallId');
            await callKitService.resumeCallScreenIfNeeded();
            return;
          }

          // Mark as handled immediately to prevent duplicates
          _markNotificationHandled(_currentCallId!);

          // We have call info, verify it's recent and active
          final prefs = await SharedPreferences.getInstance();
          final timestamp = prefs.getInt('active_call_timestamp') ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;

          // Only consider recent calls (less than 30 seconds old)
          if (now - timestamp > 30000) {
            debugPrint('Call info is too old, clearing');
            await _clearCallInfo();
            return;
          }

          // Verify call is active with server
          bool isActive = await _verifyCallWithServer(_currentCallId!);
          if (!isActive) {
            debugPrint('Call not active according to server: $_currentCallId');
            await _clearCallInfo();
            return;
          }

          // Call appears to be active
          debugPrint('Found active call in preferences: $_currentCallId');

          // Mark this call as accepted
          await _markCallAsAccepted(_currentCallId!);

          _hasActiveCall = true;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error checking for active calls: $e');
    }
  }

  /// Verify call is active with the server
  Future<bool> _verifyCallWithServer(String callId) async {
    try {
      // Get or create API service
      final apiService = await _getOrCreateApiService();

      // Add actual API call to verify call status
      // For now, we'll return true since the API method isn't implemented
      return true;
    } catch (e) {
      debugPrint('Error verifying call with server: $e');
      return false;
    }
  }

  /// Load call information from SharedPreferences
  Future<void> _loadCallInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _currentCallId = prefs.getString('active_call_id');
      _callerId = prefs.getString('active_call_user_id');
      _callerName = prefs.getString('active_call_name');
      _callerAvatar = prefs.getString('active_call_avatar');
      _isVideoCall = prefs.getBool('active_call_has_video') ?? false;

      if (_currentCallId != null) {
        debugPrint('Loaded call info - Call ID: $_currentCallId, Caller: $_callerName');
      }
    } catch (e) {
      debugPrint('Error loading call info: $e');
    }
  }

  /// Clear call information from SharedPreferences and reset state
  Future<void> _clearCallInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear call-related preferences
      await prefs.remove('active_call_id');
      await prefs.remove('active_call_user_id');
      await prefs.remove('active_call_name');
      await prefs.remove('active_call_avatar');
      await prefs.remove('active_call_has_video');
      await prefs.remove('active_call_timestamp');

      // Reset local state
      _currentCallId = null;
      _callerId = null;
      _callerName = null;
      _callerAvatar = null;
      _isVideoCall = false;
      _hasActiveCall = false;

      notifyListeners();
      debugPrint('Call information cleared');

      // Also clear any notifications to prevent duplicates
      try {
        if (Platform.isAndroid) {
          await ClearAllNotifications.clear();
        }
      } catch (e) {
        // Ignore errors clearing notifications
      }
    } catch (e) {
      debugPrint('Error clearing call info: $e');
    }
  }

  /// Save call information to SharedPreferences for persistence
  Future<void> _saveCallInfo(
      String callId,
      String callerId,
      String callerName,
      String callerAvatar,
      bool isVideoCall
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save call information
      await prefs.setString('active_call_id', callId);
      await prefs.setString('active_call_user_id', callerId);
      await prefs.setString('active_call_name', callerName);
      await prefs.setString('active_call_avatar', callerAvatar);
      await prefs.setBool('active_call_has_video', isVideoCall);
      await prefs.setInt('active_call_timestamp', DateTime.now().millisecondsSinceEpoch);

      // Update local state
      _currentCallId = callId;
      _callerId = callerId;
      _callerName = callerName;
      _callerAvatar = callerAvatar;
      _isVideoCall = isVideoCall;

      debugPrint('Call information saved - Call ID: $callId, Caller: $callerName');
    } catch (e) {
      debugPrint('Error saving call info: $e');
    }
  }

  /// Handle an incoming call notification
  Future<void> handleIncomingCall({
    required String callId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required bool isVideoCall,
  }) async {
    // Check if this call has already been accepted or is currently active or recently handled
    if (_isCallAlreadyAccepted(callId) ||
        (_currentCallId == callId && _hasActiveCall) ||
        _isRecentlyHandledNotification(callId) ||
        _isAcceptingCall) {
      debugPrint('Call already accepted or notification recently handled, updating UI for: $callId');

      // Just ensure the call screen is visible
      await callKitService.resumeCallScreenIfNeeded();

      // Clear any pending call info to prevent duplicate processing
      await _clearPendingCallInfo();

      return;
    }

    // Mark notification as handled immediately to prevent duplicates
    _markNotificationHandled(callId);

    // First, save call info to preferences immediately regardless of initialization state
    await _saveCallInfoToPreferences(
        callId, callerId, callerName, callerAvatar, isVideoCall);

    // Use a lock to prevent duplicate handling of the same call
    final lockKey = 'incoming_$callId';
    if (_apiCallLocks[lockKey] == true) {
      debugPrint('Already handling incoming call: $callId');
      return;
    }

    _apiCallLocks[lockKey] = true;
    _isHandlingIncomingCall = true;

    try {
      debugPrint('Handling incoming call: $callId from $callerName (video: $isVideoCall)');

      // Save current app state
      String previousAppState = _appState;

      // Save call information for persistence
      await _saveCallInfo(callId, callerId, callerName, callerAvatar, isVideoCall);

      // Update state
      _hasActiveCall = true;
      notifyListeners();

      // First, call the ringing API to notify the server
      try {
        final apiService = await _getOrCreateApiService();

        // Only call if we haven't recently called it
        if (!_hasRecentlyCalledApi('ringing_$callId')) {
          await apiService.callRinging(
            callId: callId,
            callerId: callerId,
          );
          _markApiCallTimestamp('ringing_$callId');
          debugPrint('Called ringing API for call: $callId');
        } else {
          debugPrint('Skipping duplicate ringing API call for: $callId');
        }
      } catch (e) {
        debugPrint('Error calling ringing API: $e');
        // Continue even if this API fails
      }

      // Check if we already have an active call UI before showing a new one
      List<dynamic> activeCalls = [];
      try {
        activeCalls = await callKitService.getActiveCalls();
      } catch (e) {
        try {
          final result = await FlutterCallkitIncoming.activeCalls();
          activeCalls = result as List? ?? [];
        } catch (e2) {
          // Ignore errors
        }
      }

      bool callAlreadyActive = activeCalls.any((call) => call['id'] == callId);
      if (!callAlreadyActive) {
        // Show incoming call UI via CallKit
        try {
          await callKitService.displayIncomingCall(
            uuid: callId,
            callerName: callerName,
            callerId: callerId,
            avatar: callerAvatar,
            hasVideo: isVideoCall,
          );
          debugPrint('Successfully displayed incoming call UI');
        } catch (e) {
          debugPrint('Error displaying incoming call UI: $e');
          // Try with a delay
          _retryDisplayIncomingCall(callId, callerName, callerId, callerAvatar, isVideoCall);
        }
      } else {
        debugPrint('Call already active in CallKit, not showing duplicate UI');
      }

      // If app was in foreground, navigate to call screen directly
      if (previousAppState == 'foreground') {
        navigateToCallScreen(
          callId: callId,
          userId: callerId,
          userName: callerName,
          avatar: callerAvatar,
          isVideoCall: isVideoCall,
        );
      }
    } catch (e) {
      debugPrint('Error handling incoming call: $e');
    } finally {
      // Release locks
      _apiCallLocks[lockKey] = false;
      _isHandlingIncomingCall = false;
    }
  }

  // Save call info to SharedPreferences directly (for use when service is not initialized)
  Future<void> _saveCallInfoToPreferences(
      String callId,
      String callerId,
      String callerName,
      String callerAvatar,
      bool isVideoCall
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save pending call information for later handling
      await prefs.setString('pending_call_id', callId);
      await prefs.setInt('pending_call_timestamp', DateTime.now().millisecondsSinceEpoch);
      await prefs.setString('pending_caller_id', callerId);
      await prefs.setString('pending_caller_name', callerName);
      await prefs.setString('pending_caller_avatar', callerAvatar);
      await prefs.setBool('pending_call_has_video', isVideoCall);

      debugPrint('Saved call info to preferences for later handling: $callId');
    } catch (e) {
      debugPrint('Error saving call info to preferences: $e');
    }
  }

  // Retry displaying incoming call UI
  void _retryDisplayIncomingCall(
      String callId,
      String callerName,
      String callerId,
      String callerAvatar,
      bool isVideoCall
      ) {
    Future.delayed(Duration(milliseconds: 500), () {
      try {
        callKitService.displayIncomingCall(
          uuid: callId,
          callerName: callerName,
          callerId: callerId,
          avatar: callerAvatar,
          hasVideo: isVideoCall,
        );
        debugPrint('Successfully displayed incoming call UI on retry');
      } catch (e) {
        debugPrint('Retry also failed to display incoming call UI: $e');
      }
    });
  }

  /// Check if we've recently called an API to prevent duplicates
  bool _hasRecentlyCalledApi(String apiKey) {
    final lastTimestamp = _lastApiCallTimestamps[apiKey];
    if (lastTimestamp == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastTimestamp);

    // Consider API calls within 2 seconds as duplicates
    return difference.inSeconds < 2;
  }

  /// Mark an API call timestamp to prevent duplicates
  void _markApiCallTimestamp(String apiKey) {
    _lastApiCallTimestamps[apiKey] = DateTime.now();
  }

  /// Handle user accepting a call - improved with API call
  Future<void> handleCallAccepted(String callId) async {
    // Prevent duplicate acceptances
    if (_isAcceptingCall || _isCallAlreadyAccepted(callId)) {
      debugPrint('Already accepting call or call already accepted: $callId');
      return;
    }

    _isAcceptingCall = true;

    try {
      // Mark this call as accepted to prevent duplicates
      await _markCallAsAccepted(callId);

      // Get the call data from preferences if not already loaded
      if (_currentCallId != callId) {
        await _loadCallInfo();

        // Check if we loaded the call info successfully
        if (_currentCallId != callId) {
          // If not, try to get it from CallKit or saved preferences
          final prefs = await SharedPreferences.getInstance();
          _callerId = prefs.getString('active_call_user_id') ??
              prefs.getString('pending_caller_id');

          if (_callerId == null) {
            // Try to get active calls from CallKit
            final activeCalls = await callKitService.getActiveCalls();
            if (activeCalls.isNotEmpty && activeCalls.first['id'] == callId) {
              final call = activeCalls.first;
              final extra = call['extra'] is Map ?
              Map<String, dynamic>.from(call['extra'] as Map) :
              <String, dynamic>{};

              _callerId = extra['userId']?.toString();
            }
          }

          // Set the current call ID
          _currentCallId = callId;
        }
      }

      // Make API call to accept if we have the callerId
      if (_callerId != null) {
        try {
          final apiService = await _getOrCreateApiService();

          // Call accept API with error handling
          bool apiCallSuccess = false;
          int retryCount = 0;

          while (!apiCallSuccess && retryCount < 3) {
            try {
              await apiService.acceptCall(
                callId: callId,
                callerId: _callerId!,
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
          debugPrint('Error with accept call API: $e');
        }
      }

      // Clear all notifications to prevent duplicates
      try {
        if (Platform.isAndroid) {
          await ClearAllNotifications.clear();
        }
      } catch (e) {
        // Ignore errors
      }

      // Clear any pending call info
      await _clearPendingCallInfo();

      // Update state
      _hasActiveCall = true;
      notifyListeners();

      debugPrint('Call accepted: $callId');
    } finally {
      _isAcceptingCall = false;
    }
  }

  /// Make an outgoing call
  Future<Map<String, dynamic>> makeCall({
    required String userId,
    required String userName,
    required String userAvatar,
    required bool isVideoCall,
  }) async {
    // Check initialization
    if (!_isInitialized && !_isInitializing) {
      // Try to initialize with default URL
      final initialized = await initialize(baseUrl: AppData.remoteUrl3);
      if (!initialized) {
        return {
          'success': false,
          'message': 'Call service not initialized',
        };
      }
    }

    // Use a lock to prevent duplicate calls
    final lockKey = 'outgoing_$userId';
    if (_apiCallLocks[lockKey] == true) {
      debugPrint('Already making a call to: $userId');
      return {
        'success': false,
        'message': 'Call already in progress',
      };
    }

    _apiCallLocks[lockKey] = true;

    try {
      debugPrint('Making call to $userName ($userId), video: $isVideoCall');

      // Check if there are any active calls first and end them
      try {
        List<dynamic> activeCalls = [];
        try {
          activeCalls = await callKitService.getActiveCalls();
        } catch (e) {
          try {
            final result = await FlutterCallkitIncoming.activeCalls();
            activeCalls = result as List? ?? [];
          } catch (e2) {
            // Ignore errors
          }
        }

        if (activeCalls.isNotEmpty) {
          debugPrint('Ending active calls before making new call');
          await callKitService.endAllCalls();
          await _clearCallInfo();

          // Small delay to ensure cleanup
          await Future.delayed(Duration(milliseconds: 300));
        }
      } catch (e) {
        // Ignore errors, continue with call
      }

      // Call the CallKit service to initiate the call
      final result = await callKitService.startOutgoingCall(
        userId: userId,
        calleeName: userName,
        avatar: userAvatar,
        hasVideo: isVideoCall,
      );

      if (result['success'] == true && result['callId'] != null) {
        final callId = result['callId'].toString();

        // Mark this call as accepted
        await _markCallAsAccepted(callId);

        // Mark notification as handled
        _markNotificationHandled(callId);

        // Save call information for recovery
        await _saveCallInfo(callId, userId, userName, userAvatar, isVideoCall);

        // Update state
        _hasActiveCall = true;
        notifyListeners();

        return result;
      } else {
        throw Exception(result['message'] ?? 'Failed to start call');
      }
    } catch (e) {
      debugPrint('Error making call: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    } finally {
      // Release the lock after a delay
      Future.delayed(Duration(seconds: 3), () {
        _apiCallLocks[lockKey] = false;
      });
    }
  }

  /// End the current call with improved error handling and cleanup
  Future<void> endCall() async {
    // Check if we're already ending a call
    if (_isEndingCall) {
      debugPrint('Already ending call');
      return;
    }

    if (_currentCallId == null) {
      debugPrint('No active call to end');

      // Try to end any active calls anyway
      try {
        List<dynamic> activeCalls = [];
        try {
          activeCalls = await callKitService.getActiveCalls();
        } catch (e) {
          try {
            final result = await FlutterCallkitIncoming.activeCalls();
            activeCalls = result as List? ?? [];
          } catch (e2) {
            // Ignore errors
          }
        }

        if (activeCalls.isNotEmpty) {
          for (var call in activeCalls) {
            final callId = call['id']?.toString() ?? '';
            if (callId.isNotEmpty) {
              await callKitService.endCall(callId);
            }
          }
        }
      } catch (e) {
        // Ignore errors
      }

      return;
    }

    final callId = _currentCallId!;

    // Use a lock to prevent duplicate end calls
    final lockKey = 'end_$callId';
    if (_apiCallLocks[lockKey] == true) {
      debugPrint('Already ending call: $callId');
      return;
    }

    _apiCallLocks[lockKey] = true;
    _isEndingCall = true;
    notifyListeners(); // Notify about ending state change

    try {
      debugPrint('Beginning call end process for: $callId');

      // First, let the API know we're ending the call
      try {
        final apiService = await _getOrCreateApiService();

        // Call end call API with retry mechanism
        bool apiCallSuccess = false;
        int retryCount = 0;

        while (!apiCallSuccess && retryCount < 3) {
          try {
            await apiService.endCall(callId: callId);

            apiCallSuccess = true;
            debugPrint('Successfully called end call API: $callId');

           } catch (e) {

            retryCount++;
            debugPrint('Error calling end API (attempt $retryCount): $e');

            // Only retry if not the last attempt
            if (retryCount < 3) {
              await Future.delayed(Duration(milliseconds: 300 * retryCount));
            }
          }
        }
      } catch (e) {
        debugPrint('Error with end call API: $e, continuing with UI cleanup');
        // Continue with cleanup even if API call fails
      }

      // Next, end the call in CallKit to dismiss UI notifications
      try {
        await callKitService.endCall(callId);
        debugPrint('Successfully ended call in CallKit: $callId');
      } catch (e) {
        debugPrint('Error ending call in CallKit: $e, continuing with UI cleanup');
        // Fallback to direct method if CallKitService fails
        try {
          await FlutterCallkitIncoming.endCall(callId);
        } catch (e2) {
          debugPrint('Error with direct endCall: $e2');
        }
      }

      // Clear all notifications to prevent duplicates
      try {
        if (Platform.isAndroid) {
          await ClearAllNotifications.clear();
        }
      } catch (e) {
        // Ignore errors
      }

      // Clear call information
      await _clearCallInfo();

      // Remove from accepted calls to allow future calls with the same ID
      _acceptedCalls.remove(callId);
      await _saveAcceptedCalls();

      debugPrint('Call end process completed for: $callId');
    } catch (e) {
      debugPrint('Error in end call process: $e');
    } finally {
      // Release locks
      _apiCallLocks[lockKey] = false;
      _isEndingCall = false;
      notifyListeners(); // Notify listeners about the end of call
    }
  }

  /// Handle app lifecycle changes
  void handleAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _isInForeground = true;
        _appState = 'foreground';

        // Clear notifications when app comes to foreground
        try {
          if (Platform.isAndroid) {
            ClearAllNotifications.clear();
          }
        } catch (e) {
          // Ignore errors
        }

        // Check for active calls when resuming
        if (_hasActiveCall && _currentCallId != null) {
          _verifyActiveCallOnResume();
        } else {
          _checkForMissedCalls();
        }
        break;

      case AppLifecycleState.paused:
        _isInForeground = false;
        _appState = 'background';
        break;

      case AppLifecycleState.inactive:
        _appState = 'inactive';
        break;

      case AppLifecycleState.detached:
        _isInForeground = false;
        _appState = 'detached';
        break;

      case AppLifecycleState.hidden:
        _isInForeground = false;
        _appState = 'hidden';
        break;
    }
  }

  /// Verify if a call is still active when resuming the app
  Future<void> _verifyActiveCallOnResume() async {
    if (_currentCallId == null) return;

    try {
      debugPrint('Verifying active call on resume: $_currentCallId');

      // Check if the call is still in CallKit
      List<dynamic> activeCalls = [];
      try {
        activeCalls = await callKitService.getActiveCalls();
      } catch (e) {
        try {
          final result = await FlutterCallkitIncoming.activeCalls();
          activeCalls = result as List? ?? [];
        } catch (e2) {
          // Ignore errors
        }
      }

      final isInCallKit = activeCalls.any((call) => call['id'] == _currentCallId);

      if (!isInCallKit) {
        debugPrint('Call not found in CallKit on resume: $_currentCallId');
        await _clearCallInfo();

        // Remove from accepted calls
        _acceptedCalls.remove(_currentCallId);
        await _saveAcceptedCalls();

        return;
      }

      // Verify with server
      bool isActive = await _verifyCallWithServer(_currentCallId!);

      if (!isActive) {
        debugPrint('Call not active according to server on resume: $_currentCallId');
        await callKitService.endCall(_currentCallId!);
        await _clearCallInfo();

        // Remove from accepted calls
        _acceptedCalls.remove(_currentCallId);
        await _saveAcceptedCalls();
      } else {
        // Call is still active, ensure call screen is visible
        debugPrint('Call still active on resume, ensuring call screen is visible');
        await callKitService.resumeCallScreenIfNeeded();
      }
    } catch (e) {
      debugPrint('Error verifying call on resume: $e');
    }
  }

  /// Check for missed calls when resuming the app
  Future<void> _checkForMissedCalls() async {
    try {
      debugPrint('Checking for missed calls');

      // Check for active calls in CallKit
      List<dynamic> activeCalls = [];
      try {
        activeCalls = await callKitService.getActiveCalls();
      } catch (e) {
        try {
          final result = await FlutterCallkitIncoming.activeCalls();
          activeCalls = result as List? ?? [];
        } catch (e2) {
          // Ignore errors
        }
      }

      if (activeCalls.isNotEmpty) {
        final call = activeCalls.first;
        final callId = call['id']?.toString() ?? '';

        // Check if this call has already been accepted or recently handled
        if (_isCallAlreadyAccepted(callId) || _isRecentlyHandledNotification(callId)) {
          debugPrint('Call already accepted or notification recently handled, ensuring it\'s visible: $callId');
          await callKitService.resumeCallScreenIfNeeded();
          return;
        }

        // Mark as handled immediately to prevent duplicates
        _markNotificationHandled(callId);

        debugPrint('Found missed call on resume: $callId');

        // Verify call is still active
        bool isActive = await _verifyCallWithServer(callId);

        if (isActive) {
          // Mark this call as accepted
          await _markCallAsAccepted(callId);

          // Update state with call information
          final extra = call['extra'] is Map ?
          Map<String, dynamic>.from(call['extra'] as Map) :
          <String, dynamic>{};

          _callerId = extra['userId']?.toString() ?? '';
          _callerName = call['nameCaller']?.toString() ?? 'Unknown';
          _callerAvatar = extra['avatar']?.toString() ?? '';
          _isVideoCall = extra['has_video'] == true || extra['has_video'] == 'true';
          _currentCallId = callId;
          _hasActiveCall = true;

          // Save call information
          await _saveCallInfo(callId, _callerId!, _callerName!, _callerAvatar!, _isVideoCall);

          notifyListeners();

          // Resume call screen
          await callKitService.resumeCallScreenIfNeeded();
        } else {
          // Call is no longer active
          debugPrint('Missed call no longer active, cleaning up: $callId');
          await callKitService.endCall(callId);

          // Remove from accepted calls
          _acceptedCalls.remove(callId);
          await _saveAcceptedCalls();
        }
      }

      // Also check for pending calls
      await _checkForPendingCalls();
    } catch (e) {
      debugPrint('Error checking for missed calls: $e');
    }
  }

  /// Navigate to call screen (when accepting a call)
  Future<void> navigateToCallScreen({
    required String callId,
    required String userId,
    required String userName,
    required String avatar,
    required bool isVideoCall,
  }) async {
    // Mark this call as accepted before navigating
    await _markCallAsAccepted(callId);

    // Navigate to the call screen
    final navigatorKey = NavigatorService.navigatorKey;

    if (navigatorKey.currentState == null) {
      debugPrint('Navigator state is null, cannot navigate to call screen');
      return;
    }

    debugPrint('Navigating to call screen for: $callId, caller: $userName');

    // Use pushNamed for consistency and to allow for predictable navigation
    navigatorKey.currentState!.pushNamed(
      '/call',
      arguments: {
        'callId': callId,
        'contactId': userId,
        'contactName': userName,
        'contactAvatar': avatar,
        'isIncoming': true,
        'isVideoCall': isVideoCall,
        'token': '',
      },
    );
  }

  /// Method to update an existing call instead of creating a new one
  /// This is used when a subsequent notification for the same call arrives
  Future<void> updateExistingCall({
    required String callId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required bool isVideoCall,
  }) async {
    try {
      // Check if notification was recently handled
      if (_isRecentlyHandledNotification(callId)) {
        debugPrint('Notification recently handled, ignoring duplicate: $callId');
        return;
      }

      // Mark as handled immediately to prevent duplicates
      _markNotificationHandled(callId);

      // Check if this is already our active call
      if (_currentCallId == callId && _hasActiveCall) {
        debugPrint('Already handling this call as active call: $callId');

        // If we're in the background, make sure the call screen is visible
        if (!_isInForeground) {
          await callKitService.resumeCallScreenIfNeeded();
        }

        return;
      }

      // Check if call is in CallKit but not active in our service
      List<dynamic> activeCalls = [];
      try {
        activeCalls = await callKitService.getActiveCalls();
      } catch (e) {
        try {
          final result = await FlutterCallkitIncoming.activeCalls();
          activeCalls = result as List? ?? [];
        } catch (e2) {
          // Ignore errors
        }
      }

      final isInCallKit = activeCalls.any((call) => call['id'] == callId);

      if (isInCallKit) {
        // We have the call in CallKit but not as active - update our state
        debugPrint('Call found in CallKit but not active in service, updating state: $callId');

        // Update local state
        _callerId = callerId;
        _callerName = callerName;
        _callerAvatar = callerAvatar;
        _isVideoCall = isVideoCall;
        _currentCallId = callId;
        _hasActiveCall = true;

        // Save call information for persistence
        await _saveCallInfo(callId, callerId, callerName, callerAvatar, isVideoCall);

        // Mark as accepted
        await _markCallAsAccepted(callId);

        // Update UI if needed
        notifyListeners();

        // Make sure call UI is visible
        await callKitService.resumeCallScreenIfNeeded();

        return;
      }

      // Call is not in CallKit or active, handle as new call but without duplicate UI
      debugPrint('Call not found in active state, handling as update: $callId');

      // Save call information
      await _saveCallInfo(callId, callerId, callerName, callerAvatar, isVideoCall);

      // Update state
      _currentCallId = callId;
      _callerId = callerId;
      _callerName = callerName;
      _callerAvatar = callerAvatar;
      _isVideoCall = isVideoCall;
      _hasActiveCall = true;

      // Mark as accepted to prevent duplicate processing
      await _markCallAsAccepted(callId);

      // Use CallKit to update the call state if needed
      try {
        await callKitService.updateCallState(
            callId: callId,
            callerName: callerName,
            callerId: callerId,
            avatar: callerAvatar,
            hasVideo: isVideoCall
        );
      } catch (e) {
        debugPrint('Error updating call state: $e');
        // If updating fails, try to display a new call
        try {
          await callKitService.displayIncomingCall(
            uuid: callId,
            callerName: callerName,
            callerId: callerId,
            avatar: callerAvatar,
            hasVideo: isVideoCall,
          );
        } catch (e2) {
          debugPrint('Error displaying call: $e2');
        }
      }

      // Update UI
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating existing call: $e');
    }
  }

  // Clean up resources
  @override
  void dispose() {
    _initRetryTimer?.cancel();
    super.dispose();
  }
}