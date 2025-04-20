import 'package:doctak_app/core/call_service/callkit_service.dart';
import 'package:doctak_app/core/notification_service.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/presentation/call_module/call_api_service.dart';
import 'package:doctak_app/presentation/call_module/call_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class to initialize all call-related services
class CallInitializer {
  // Singleton pattern
  static final CallInitializer _instance = CallInitializer._internal();
  factory CallInitializer() => _instance;
  CallInitializer._internal();

  // Flag to prevent multiple initializations
  bool _isInitialized = false;

  // API configuration
  String? _baseUrl;
  String? _authToken;

  /// Initialize call services
  Future<void> initialize({
    required String baseUrl,
    String? authToken,
  }) async {
    if (_isInitialized) return;

    _baseUrl = baseUrl;
    _authToken = authToken;

    // Initialize services that don't need context
    await _initializeCallKit();

    _isInitialized = true;
  }

  /// Initialize CallKit service
  Future<void> _initializeCallKit() async {
    try {
      // Get CallKit service instance
      final callKitService = CallKitService();

      // Set up event listeners
      callKitService.listenToCallEvents();

      // Check for active calls and resume if needed
      await callKitService.resumeCallScreenIfNeeded();

      debugPrint('CallKit service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CallKit service: $e');
    }
  }

  /// Initialize services that need context
  Future<void> initializeWithContext(BuildContext context) async {
    if (_baseUrl == null) {
      debugPrint('Call services not initialized. Call initialize() first.');
      return;
    }

    try {
      // Get the current auth token (implement your own auth token retrieval logic)
      final authToken = await _getAuthToken() ?? _authToken;

      // Get CallService from provider
      final callService = Provider.of<CallService>(context, listen: false);

      // Initialize CallService with API configuration
      await callService.initialize(
        baseUrl: _baseUrl!,
        authToken: authToken,
      );

      // Create API service for device token registration
      final callApiService = CallApiService(
        baseUrl: _baseUrl!,
        authToken: authToken,
      );

      // Register device token for push notifications
      await NotificationService.registerDeviceToken(callApiService);

      debugPrint('Call services initialized with context successfully');
    } catch (e) {
      debugPrint('Error initializing call services with context: $e');
    }
  }

  /// Get the auth token from shared preferences or another source
  Future<String?> _getAuthToken() async {
    try {
      // Get from shared preferences (implement your own storage logic)
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

  /// Handle incoming call from notification
  Future<void> handleIncomingCallNotification({
    required String callId,
    required String callerId,
    required String callerName,
    required String callerAvatar,
    required bool isVideoCall,
  }) async {
    try {
      // Display incoming call UI using CallKit
      await CallKitService().displayIncomingCall(
        uuid: callId,
        callerName: callerName,
        callerId: callerId,
        avatar: callerAvatar,
        hasVideo: isVideoCall,
      );
    } catch (e) {
      debugPrint('Error handling incoming call notification: $e');
    }
  }

  /// Make an outgoing call programmatically
  Future<void> makeCall({
    required BuildContext context,
    required String userId,
    required String userName,
    required String userAvatar,
    required bool isVideoCall,
  }) async {
    try {
      // Get call service from provider
      final callService = Provider.of<CallService>(context, listen: false);

      // Make the call
      await callService.makeCall(
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        isVideoCall: isVideoCall,
      );
    } catch (e) {
      debugPrint('Error making call: $e');
    }
  }

  /// End the current active call
  Future<void> endCurrentCall(BuildContext context) async {
    try {
      // Get call service from provider
      final callService = Provider.of<CallService>(context, listen: false);

      // End the call
      await callService.endCall();
    } catch (e) {
      debugPrint('Error ending call: $e');
    }
  }
}