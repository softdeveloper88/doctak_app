import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:clear_all_notifications/clear_all_notifications.dart';
import 'package:doctak_app/presentation/calling_module/services/callkit_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/splash_screen/unified_splash_upgrade_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:doctak_app/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';

import '../presentation/calling_module/services/call_api_service.dart';
import '../presentation/calling_module/services/call_service.dart';
import '../presentation/case_discussion/screens/discussion_list_screen.dart';

@pragma('vm:entry-point')
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static const String _payloadKey = 'type';
  static const String _payloadId = 'id';

  // Add CallKitService instance
  static final CallKitService _callKitService = CallKitService();

  // Separate tracking for different types of notification events
  static final Map<String, int> _lastHandledPushNotifications = {};
  static final Map<String, int> _lastHandledForegroundNotifications = {};
  static final Map<String, int> _lastHandledBackgroundNotifications = {};
  static final Map<String, int> _lastHandledScreenOpenedNotifications = {};
  static final Map<String, int> _lastHandledInitialNotifications = {};

  // Lock to prevent multiple simultaneous notification handling
  static bool _isHandlingNotification = false;

  // Helper method to check for active calls and send busy signal if needed
  static Future<bool> _shouldSendBusySignal(String callId, String callerId) async {
    try {
      // Get active calls from CallKit
      final result = await FlutterCallkitIncoming.activeCalls();
      final activeCalls = result as List? ?? [];

      // Check if there's an active call different from this one
      for (var call in activeCalls) {
        final activeCallId = call['id']?.toString() ?? '';
        if (activeCallId != callId && activeCallId.isNotEmpty) {
          debugPrint('User has another active call, sending busy signal for: $callId');

          try {
            // Create API service instance
            final apiService = CallApiService(baseUrl: AppData.remoteUrl3);

            // Send busy signal
            await apiService.sendBusySignal(callId: callId, callerId: callerId);

            debugPrint('Busy signal sent successfully for call: $callId');
            return true; // Busy signal sent, don't show call UI
          } catch (e) {
            debugPrint('Error sending busy signal: $e');
            return false; // Continue with normal call handling
          }
        }
      }
      return false; // No other active calls, proceed normally
    } catch (e) {
      debugPrint('Error checking active calls: $e');
      return false; // Proceed with normal call handling
    }
  }

  @pragma('vm:entry-point')
  static Future<dynamic> _throwGetMessage(RemoteMessage message) async {
    // Ensure Flutter bindings and plugins are registered before using platform channels
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('PUSH RECEIVED ${message.data}');

    // Generate a unique notification ID
    final String notificationId = _getNotificationId(message);

    // Check if this notification was already handled recently (within 1 second)
    // Only check the background notifications map for background message handler
    if (_shouldSkipBackgroundNotification(notificationId)) {
      debugPrint('Skipping duplicate background notification: $notificationId');
      return;
    }

    // Mark this notification as handled in background map
    _markBackgroundNotificationHandled(notificationId);

    await NotificationService.incrementBadgeCount();

    // Check if it's a call notification
    if (message.data['type'] == 'call') {
      final callId = message.data['call_id'] ?? '';
      final callerId = message.data['caller_id'] ?? '';

      // Check if user is already on a call - if so, send busy signal
      if (await _shouldSendBusySignal(callId, callerId)) {
        // Busy signal was sent, don't proceed with showing the call UI
        return;
      }

      await _handleCallNotification(message);
    } else {
      // Handle regular notifications
      await showNotificationWithCustomIcon(
        message.notification,
        message.data,
        message.notification?.title ?? '',
        message.notification?.body ?? '',
        message.data['image'] ?? '',
        message.data['banner'] ?? '',
      );
    }
  }

  // More specific methods to check and mark different notification types
  static bool _shouldSkipPushNotification(String notificationId) {
    return _shouldSkipWithinDuration(notificationId, _lastHandledPushNotifications, 500);
  }

  static bool _shouldSkipForegroundNotification(String notificationId) {
    return _shouldSkipWithinDuration(notificationId, _lastHandledForegroundNotifications, 500);
  }

  static bool _shouldSkipBackgroundNotification(String notificationId) {
    return _shouldSkipWithinDuration(notificationId, _lastHandledBackgroundNotifications, 1000);
  }

  static bool _shouldSkipScreenOpenedNotification(String notificationId) {
    return _shouldSkipWithinDuration(notificationId, _lastHandledScreenOpenedNotifications, 1000);
  }

  static bool _shouldSkipInitialNotification(String notificationId) {
    return _shouldSkipWithinDuration(notificationId, _lastHandledInitialNotifications, 1000);
  }

  // Helper method to check if a notification was handled recently
  static bool _shouldSkipWithinDuration(String notificationId, Map<String, int> map, int durationMs) {
    final lastTimestamp = map[notificationId];
    if (lastTimestamp == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastTimestamp < durationMs);
  }

  // Mark notifications as handled in the specific maps
  static void _markPushNotificationHandled(String notificationId) {
    _lastHandledPushNotifications[notificationId] = DateTime.now().millisecondsSinceEpoch;
    _cleanupOldEntries(_lastHandledPushNotifications);
  }

  static void _markForegroundNotificationHandled(String notificationId) {
    _lastHandledForegroundNotifications[notificationId] = DateTime.now().millisecondsSinceEpoch;
    _cleanupOldEntries(_lastHandledForegroundNotifications);
  }

  static void _markBackgroundNotificationHandled(String notificationId) {
    _lastHandledBackgroundNotifications[notificationId] = DateTime.now().millisecondsSinceEpoch;
    _cleanupOldEntries(_lastHandledBackgroundNotifications);
  }

  static void _markScreenOpenedNotificationHandled(String notificationId) {
    _lastHandledScreenOpenedNotifications[notificationId] = DateTime.now().millisecondsSinceEpoch;
    _cleanupOldEntries(_lastHandledScreenOpenedNotifications);
  }

  static void _markInitialNotificationHandled(String notificationId) {
    _lastHandledInitialNotifications[notificationId] = DateTime.now().millisecondsSinceEpoch;
    _cleanupOldEntries(_lastHandledInitialNotifications);
  }

  // Generate a unique ID for the notification for deduplication
  static String _getNotificationId(RemoteMessage message) {
    // For call notifications, use callId
    if (message.data['type'] == 'call' && message.data['call_id'] != null) {
      return 'call_${message.data['call_id']}';
    }

    // For other notifications, generate an ID based on content
    final String type = message.data['type'] ?? '';
    final String id = message.data['id'] ?? '';
    final String title = message.notification?.title ?? '';

    // Include a timestamp in the ID to make it unique for recurring notifications
    // but don't make it too granular to allow for some deduplication
    final int timestamp = (DateTime.now().millisecondsSinceEpoch / 10000).floor();

    return '$type:$id:${title.hashCode}:$timestamp';
  }

  // Clean up notification entries older than 10 minutes
  static void _cleanupOldEntries(Map<String, int> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    map.removeWhere((key, timestamp) => (now - timestamp > 600000));
  }

  // Handle call notifications with better deduplication and busy signal check
  static Future<void> _handleCallNotification(RemoteMessage message) async {
    // Use a lock to prevent multiple simultaneous processing
    if (_isHandlingNotification) {
      debugPrint('Already handling a notification, skipping');
      return;
    }

    _isHandlingNotification = true;

    try {
      final callId = message.data['call_id'] ?? '';
      final callerName = message.data['caller_name'] ?? 'Unknown Caller';
      final callerId = message.data['caller_id'] ?? '';
      final hasVideo = message.data['is_video_call'] == 'true';
      final avatar = message.data['caller_avatar'] ?? '';

      // Check for active calls in CallKit before processing this new call
      if (await _shouldSendBusySignal(callId, callerId)) {
        // Busy signal was sent, don't proceed with showing the call UI
        return;
      }

      // Save the call data to preferences for later recovery if needed
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      await prefs.setString('pending_call_id', callId);
      await prefs.setInt('pending_call_timestamp', DateTime.now().millisecondsSinceEpoch);
      await prefs.setString('pending_caller_id', callerId);
      await prefs.setString('pending_caller_name', callerName);
      await prefs.setString('pending_caller_avatar', avatar);
      await prefs.setBool('pending_call_has_video', hasVideo);

      // Check if the call service is already initialized
      final callService = CallService();

      // Try to initialize the call service if not already done
      if (!callService.isInitialized) {
        await callService.initialize(baseUrl: AppData.remoteUrl3);
      }

      // Handle the incoming call
      await callService.handleIncomingCall(callId: callId, callerId: callerId, callerName: callerName, callerAvatar: avatar, isVideoCall: hasVideo);
    } finally {
      _isHandlingNotification = false;
    }
  }

  // Initialize the notification services (both local and FCM)
  static Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_name');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      defaultPresentSound: true,
      defaultPresentAlert: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentBadge: true,
      requestCriticalPermission: true, // For critical alerts on iOS
    );
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        print('notification ${notificationResponse.payload}');
        if (notificationResponse.payload != null) {
          // Handle notification tap
          _handleNotificationTap(
            '', // Title will be populated later if needed
            '', // Profile pic will be populated later if needed
            notificationResponse.payload!,
            '', // ID will be populated later if needed
          );
        }
      },
    );

    // Initialize FCM and handle background/terminated state with proper iOS permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false, // Use normal notifications that respect device mute settings
      provisional: false,
      sound: true,
    );

    debugPrint('📱 FCM Permission status: ${settings.authorizationStatus}');
    debugPrint('📱 Alert permission: ${settings.alert}');
    debugPrint('📱 Badge permission: ${settings.badge}');
    debugPrint('📱 Sound permission: ${settings.sound}');

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_throwGetMessage);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Generate a notification ID for checking duplicates
      final String notificationId = _getNotificationId(message);

      // Check if this foreground notification was already handled
      if (_shouldSkipForegroundNotification(notificationId)) {
        debugPrint('Skipping duplicate foreground notification: $notificationId');
        return;
      }

      // Mark as handled in foreground map
      _markForegroundNotificationHandled(notificationId);

      await NotificationService.incrementBadgeCount();
      _showLocalNotification(message);
    });

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      NotificationService.clearBadgeCount();

      // Generate a notification ID for checking duplicates
      final String notificationId = _getNotificationId(message);

      // Check if this opened notification was already handled
      if (_shouldSkipScreenOpenedNotification(notificationId)) {
        debugPrint('Skipping duplicate opened notification: $notificationId');
        return;
      }

      // Mark as handled in opened map
      _markScreenOpenedNotificationHandled(notificationId);

      // Handle notification tap based on type
      if (message.data['type'] == 'call') {
        // Call notifications are handled by CallKit/CallService
        // Just make sure if there's an active call, we navigate to it
        final callId = message.data['call_id'] ?? '';
        final callerId = message.data['caller_id'] ?? '';

        // Check if user is already on a call - if so, send busy signal
        if (await _shouldSendBusySignal(callId, callerId)) {
          // Busy signal was sent, don't proceed with showing the call UI
          return;
        }

        // Try to initialize the call service if needed
        final callService = CallService();
        if (!callService.isInitialized) {
          await callService.initialize(baseUrl: AppData.remoteUrl3);
        }

        // Try to handle it as a new call
        final callerName = message.data['caller_name'] ?? 'Unknown Caller';
        final hasVideo = message.data['is_video_call'] == 'true';
        final avatar = message.data['caller_avatar'] ?? '';

        await callService.handleIncomingCall(callId: callId, callerId: callerId, callerName: callerName, callerAvatar: avatar, isVideoCall: hasVideo);
      } else {
        _handleNotificationTap(message.notification?.title ?? '', message.data['image'] ?? '', message.data['type'] ?? '', message.data['id'] ?? '');
      }
    });

    // Create notification channel for Android
    await _createCallNotificationChannel();
  }

  // Create call notification channel for Android
  @pragma('vm:entry-point')
  static Future<void> _createCallNotificationChannel() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _localNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Create high priority channel for all notifications
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_importance_channel',
            'High Priority Notifications',
            description: 'Channel for high priority notifications including calls and messages',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
            enableLights: true,
          ),
        );

        // Create separate call channel with full screen intent
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'call_channel',
            'Call Notifications',
            description: 'Channel for incoming call notifications',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
            enableLights: true,
          ),
        );
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<RemoteMessage?> getInitialNotificationRoute() async {
    // For Firebase Messaging
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    print('initialMessage $initialMessage');
    if (initialMessage != null) {
      print('type ${initialMessage.data['type']}');

      // Generate a notification ID for checking duplicates
      final String notificationId = _getNotificationId(initialMessage);

      // Check if this initial notification was already handled
      if (_shouldSkipInitialNotification(notificationId)) {
        debugPrint('Skipping duplicate initial notification: $notificationId');
        return null;
      }

      // Mark as handled in initial map
      _markInitialNotificationHandled(notificationId);

      // Special handling for call notifications when app is opened from terminated state
      if (initialMessage.data['type'] == 'call') {
        final callId = initialMessage.data['call_id'] ?? '';
        final callerId = initialMessage.data['caller_id'] ?? '';

        // Check if user is already on a call - if so, send busy signal
        if (await _shouldSendBusySignal(callId, callerId)) {
          // Busy signal was sent, don't proceed with showing the call UI
          return null;
        }

        final callerName = initialMessage.data['caller_name'] ?? 'Unknown Caller';
        final hasVideo = initialMessage.data['is_video_call'] == 'true';
        final avatar = initialMessage.data['caller_avatar'] ?? '';

        // Save the call data to preferences
        final prefs = SecureStorageService.instance;
        await prefs.initialize();
        await prefs.setString('pending_call_id', callId);
        await prefs.setInt('pending_call_timestamp', DateTime.now().millisecondsSinceEpoch);
        await prefs.setString('pending_caller_id', callerId);
        await prefs.setString('pending_caller_name', callerName);
        await prefs.setString('pending_caller_avatar', avatar);
        await prefs.setBool('pending_call_has_video', hasVideo);

        // Try to initialize and handle the call
        try {
          final callService = CallService();
          await callService.initialize(baseUrl: AppData.remoteUrl3, isFromCallNotification: true);

          // Handle as a new incoming call
          await callService.handleIncomingCall(callId: callId, callerId: callerId, callerName: callerName, callerAvatar: avatar, isVideoCall: hasVideo);
        } catch (e) {
          // The main app initialization will try again if this fails
          debugPrint('Error handling initial call notification: $e');
        }
      }

      // Extract the route or screen from the notification data
      return initialMessage;
    }
    // For local notifications
    return null;
  }

  // Show local notification when FCM is received
  @pragma('vm:entry-point')
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    // Generate a notification ID
    final String notificationId = _getNotificationId(message);

    // We use a different check method since this is already inside the onMessage handler
    final lastTimestamp = _lastHandledPushNotifications[notificationId];
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lastTimestamp != null && (now - lastTimestamp < 500)) {
      debugPrint('Skipping duplicate local notification: $notificationId');
      return;
    }

    // Mark as handled for local processing
    _lastHandledPushNotifications[notificationId] = now;

    if (message.data['type'] == 'call') {
      final callId = message.data['call_id'] ?? '';
      final callerId = message.data['caller_id'] ?? '';

      // Check if user is already on a call - if so, send busy signal
      if (await _shouldSendBusySignal(callId, callerId)) {
        // Busy signal was sent, don't proceed with showing the call UI
        return;
      }

      await _handleCallNotification(message);
    } else {
      await showNotificationWithCustomIcon(
        message.notification,
        message.data,
        message.notification?.title ?? '',
        message.notification?.body ?? '',
        message.data['image'] ?? '',
        message.data['banner'] ?? '',
      );
    }
  }

  @pragma('vm:entry-point')
  static Future<ByteArrayAndroidBitmap> _getImageFromUrl(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/user_image.png';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    final Uint8List imageBytes = await file.readAsBytes();
    return ByteArrayAndroidBitmap(imageBytes);
  }

  @pragma('vm:entry-point')
  static Future<void> showNotificationWithCustomIcon(notification, data, String title, String body, String imageUrl, String bannerImage) async {
    ByteArrayAndroidBitmap largeIcon = ByteArrayAndroidBitmap(Uint8List(0));
    if (imageUrl != '') {
      largeIcon = await _getImageFromUrl(imageUrl);
    }
    ByteArrayAndroidBitmap banner;
    if (bannerImage != '') {
      banner = await _getImageFromUrl(bannerImage);
    } else {
      banner = ByteArrayAndroidBitmap(Uint8List(0));
    }
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    //
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_name');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      defaultPresentSound: true,
      defaultPresentAlert: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentBadge: true,
      requestCriticalPermission: true, // For critical alerts
    );
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    //
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        print('notificationResponse $notificationResponse');
        if (notificationResponse.payload != null) {
          _handleNotificationTap(title, imageUrl, notificationResponse.payload!, data['id'] ?? '');
        }
      },
    );
    var channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title // description
      importance: Importance.max,
      showBadge: true,
    );

    await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      channelShowBadge: true,
      icon: initializationSettingsAndroid.defaultIcon,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ongoing: false,
      autoCancel: false,
      timeoutAfter: 0,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.event,
      visibility: NotificationVisibility.public,
      color: Colors.transparent,
      largeIcon: largeIcon,
      styleInformation: bannerImage != '' ? BigPictureStyleInformation(banner, contentTitle: title, summaryText: body) : null,
    );

    // Generate a semi-unique ID for the notification to avoid overwriting previous ones
    final int notificationId = notification.hashCode + DateTime.now().millisecondsSinceEpoch.toInt() % 10000;

    _localNotificationsPlugin.show(
      notificationId,
      title,
      body,
      payload: data['type'],
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          badgeNumber: 1,
          presentBadge: true,
          presentSound: true,
          presentAlert: true,
          sound: 'default', // Specify default sound
          interruptionLevel: InterruptionLevel.timeSensitive, // Important for iOS 15+
        ),
        android: androidPlatformChannelSpecifics,
      ),
    );
  }

  // Handle notification tap (local or FCM)
  @pragma('vm:entry-point')
  static Future<void> _handleNotificationTap(String title, String profilePic, String payload, String id) async {
    // Check if we're already handling a notification tap
    if (_isHandlingNotification) {
      debugPrint('Already handling a notification tap, skipping');
      return;
    }

    _isHandlingNotification = true;

    try {
      // Save the payload to secure storage for later retrieval
      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      await prefs.setString(_payloadKey, payload);
      await prefs.setString(_payloadId, id);

      // Clear all notifications to prevent duplicates
      try {
        if (Platform.isAndroid) {
          await ClearAllNotifications.clear();
        }
      } catch (e) {
        // Ignore errors
      }

      // Use Navigator to go to the specific screen
      _navigateToScreen(title, profilePic, payload, id);
    } finally {
      _isHandlingNotification = false;
    }
  }

  // Get the notification payload when the app is terminated
  static Future<String?> getNotificationPayload() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    return prefs.getString(_payloadKey);
  }

  // Clear the stored notification payload once handled
  static Future<void> clearNotificationPayload() async {
    final prefs = SecureStorageService.instance;
    await prefs.initialize();
    await prefs.remove(_payloadKey);
  }

  // Navigate to the specific screen based on the payload
  static void _navigateToScreen(String username, String profilePic, String payload, String id) {
    print('payload $payload');
    print('username $username');
    print('id $id');

    if (NavigatorService.navigatorKey.currentState != null) {
      NavigatorService.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) {
            if (payload == 'message_received') {
              return ChatRoomScreen(id: id, roomId: '', username: username, profilePic: profilePic.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', ''));
            } else if (payload == 'follow_request' || payload == 'follower_notification' || payload == 'un_follower_notification' || payload == 'friend_request') {
              return SVProfileFragment(userId: id);
            } else if (payload == 'comments_on_posts' || payload == 'reply_to_comment' || payload == 'like_comment_on_post' || payload == 'like_comments') {
              return PostDetailsScreen(commentId: int.parse(id));
            } else if (payload == 'new_like' || payload == 'like_on_posts') {
              return PostDetailsScreen(postId: int.parse(id));
            } else if (payload == 'new_job_posted' || payload == 'job_update' || payload == 'job_post_notification') {
              return JobsDetailsScreen(jobId: id);
            } else if (payload == 'conference_invitation') {
              return ConferencesScreen();
            } else if (payload == 'new_discuss_case' || payload == 'discuss_case_comment') {
              return const DiscussionListScreen();
            }
            return UnifiedSplashUpgradeScreen(); // Default route if payload does not match
          },
        ),
      );
    }
  }

  static int notificationCount = 0;

  static Future<void> incrementBadgeCount() async {
    notificationCount++;
    await AppBadgePlus.updateBadge(notificationCount);
  }

  static Future<void> clearBadgeCount() async {
    print('notification ');
    notificationCount = 0;
    await AppBadgePlus.updateBadge(notificationCount);

    // Clear all notifications
    try {
      await ClearAllNotifications.clear();
    } catch (e) {
      // Ignore errors
    }
  }
}
