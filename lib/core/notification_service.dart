import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:clear_all_notifications/clear_all_notifications.dart';
import 'package:doctak_app/core/notification_counter_service.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/app/app_environment.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/core/notification_navigation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:doctak_app/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:doctak_app/core/utils/auth_token_service.dart';
import 'package:doctak_app/core/utils/secure_storage_service.dart';

import '../presentation/calling_module_v2/services/call_push_v2.dart';

@pragma('vm:entry-point')
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static const String _payloadKey = 'type';
  static const String _payloadId = 'id';

  // CallKitService instance removed (unused)

  // Separate tracking for different types of notification events
  static final Map<String, int> _lastHandledPushNotifications = {};
  static final Map<String, int> _lastHandledForegroundNotifications = {};
  static final Map<String, int> _lastHandledBackgroundNotifications = {};
  static final Map<String, int> _lastHandledScreenOpenedNotifications = {};
  static final Map<String, int> _lastHandledInitialNotifications = {};

  // Lock to prevent multiple simultaneous notification handling
  static bool _isHandlingNotification = false;

  static String _titleFromMessage(RemoteMessage message) {
    final fromNotification = message.notification?.title?.trim();
    if (fromNotification != null && fromNotification.isNotEmpty) {
      return fromNotification;
    }
    final fromData = message.data['title']?.toString().trim();
    return (fromData != null && fromData.isNotEmpty) ? fromData : 'Doctak';
  }

  static String _bodyFromMessage(RemoteMessage message) {
    final fromNotification = message.notification?.body?.trim();
    if (fromNotification != null && fromNotification.isNotEmpty) {
      return fromNotification;
    }
    return message.data['body']?.toString().trim() ?? '';
  }

  /// Whether a message carries a real title/body worth showing. Silent data
  /// messages (sync triggers, counter pings) have neither and must NOT be
  /// rendered — otherwise they show up as an empty "Doctak" notification.
  static bool _hasDisplayableContent(RemoteMessage message) {
    final title = (message.notification?.title ?? message.data['title'] ?? '').toString().trim();
    final body = (message.notification?.body ?? message.data['body'] ?? '').toString().trim();
    return title.isNotEmpty || body.isNotEmpty;
  }

  static String _loggedInUserId() => AppData.logInUserId?.toString() ?? '';

  /// Conversation the user is actively viewing — suppress message pushes for it.
  static int? activeChatConversationId;

  /// Returns true when this push should not be shown (own action or active chat).
  static bool shouldSuppressPush(RemoteMessage message) {
    final myId = _loggedInUserId();
    if (myId.isEmpty) return false;

    final data = message.data;
    final actorId = (data['actorUserId'] ?? data['senderId'] ?? data['sender_id'] ?? '')
        .toString();
    if (actorId.isNotEmpty && actorId == myId) {
      return true;
    }

    final type = (data['type'] ?? '').toString();
    if (type.contains('message')) {
      final convId = data['conversationId'] ?? data['entityId'] ?? data['id'];
      if (convId != null &&
          activeChatConversationId != null &&
          convId.toString() == activeChatConversationId.toString()) {
        return true;
      }
    }

    return false;
  }

  /// Remove this device's FCM registration for the current user (call on logout).
  static Future<void> deregisterDeviceToken() async {
    try {
      final storedToken = AppData.deviceToken.trim();
      final token = storedToken.isNotEmpty ? storedToken : await getFcmTokenSafely();
      final auth = AppData.userToken?.trim() ?? '';

      String deviceId = '';
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        deviceId = (await deviceInfo.androidInfo).id;
      } else if (Platform.isIOS) {
        deviceId = (await deviceInfo.iosInfo).identifierForVendor ?? '';
      }

      if (auth.isNotEmpty) {
        final base = AppEnvironment.nodeApiUrl.endsWith('/')
            ? AppEnvironment.nodeApiUrl.substring(0, AppEnvironment.nodeApiUrl.length - 1)
            : AppEnvironment.nodeApiUrl;

        if (token.isNotEmpty) {
          final uri = Uri.parse('$base/api/notifications/devices').replace(
            queryParameters: {'token': token},
          );
          await http.delete(
            uri,
            headers: {
              'Authorization': 'Bearer $auth',
              'Accept': 'application/json',
            },
          );
        } else if (deviceId.isNotEmpty) {
          final uri = Uri.parse('$base/api/notifications/devices').replace(
            queryParameters: {'deviceId': deviceId},
          );
          await http.delete(
            uri,
            headers: {
              'Authorization': 'Bearer $auth',
              'Accept': 'application/json',
            },
          );
        }
      }

      try {
        await _firebaseMessaging.unsubscribeFromTopic(broadcastTopic);
      } catch (_) {}

      debugPrint('FCM deregisterDeviceToken completed');
    } catch (e) {
      debugPrint('FCM deregisterDeviceToken failed: $e');
    }
  }

  static Future<void> _ensureAndroidNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return;
      final result = await Permission.notification.request();
      debugPrint('Android notification permission: $result');
    } catch (e) {
      debugPrint('Android notification permission request failed: $e');
    }
  }

  static Future<Map<String, dynamic>> _registerTokenWithServer(String token) async {
    await AuthTokenService.instance.ensureTokenLoaded();
    var auth = await AuthTokenService.instance.getToken();
    if (token.isEmpty || auth == null) {
      debugPrint('FCM server registration skipped: missing token or auth');
      return {'ok': false, 'error': 'missing token or auth'};
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      String deviceType = '';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceType = 'android';
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceType = 'ios';
        deviceId = iosInfo.identifierForVendor ?? '';
      }

      final base = AppEnvironment.nodeApiUrl.endsWith('/')
          ? AppEnvironment.nodeApiUrl.substring(0, AppEnvironment.nodeApiUrl.length - 1)
          : AppEnvironment.nodeApiUrl;

      Future<http.Response> post(String bearer) {
        return http.post(
          Uri.parse('$base/api/notifications/devices'),
          headers: {
            'Authorization': 'Bearer $bearer',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'token': token,
            'deviceType': deviceType,
            'deviceId': deviceId,
          }),
        );
      }

      var response = await post(auth);
      if (response.statusCode == 401) {
        final refreshed = await AuthTokenService.instance.refreshToken();
        if (refreshed) {
          auth = await AuthTokenService.instance.getToken();
          if (auth != null) {
            response = await post(auth);
          }
        }
      }

      debugPrint(
        'FCM server registration: ${response.statusCode} ${response.body.length > 120 ? response.body.substring(0, 120) : response.body}',
      );
      return {
        'ok': response.statusCode >= 200 && response.statusCode < 300,
        'statusCode': response.statusCode,
        'body': response.body,
        'deviceId': deviceId,
        'deviceType': deviceType,
      };
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
      return {'ok': false, 'error': e.toString()};
    }
  }

  /// Debug helper: gathers the current push-registration state for an on-screen
  /// diagnostics view (FCM token, iOS APNS token, device identifiers, target
  /// node URL and whether the user is authenticated).
  static Future<Map<String, dynamic>> debugFcmStatus() async {
    final result = <String, dynamic>{};
    try {
      result['fcmToken'] = await getFcmTokenSafely();
      if (Platform.isIOS) {
        result['apnsToken'] = await _firebaseMessaging.getAPNSToken() ?? '';
      }
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await deviceInfo.androidInfo;
        result['deviceType'] = 'android';
        result['deviceId'] = a.id;
      } else if (Platform.isIOS) {
        final i = await deviceInfo.iosInfo;
        result['deviceType'] = 'ios';
        result['deviceId'] = i.identifierForVendor ?? '';
      }
      result['userId'] = _loggedInUserId();
      result['nodeApiUrl'] = AppEnvironment.nodeApiUrl;
      result['authPresent'] = (AppData.userToken ?? '').isNotEmpty;
    } catch (e) {
      result['error'] = e.toString();
    }
    return result;
  }

  /// Debug helper: re-fetches the FCM token and re-registers it with the
  /// doctak-node server, returning the server response (status + body, which
  /// now echoes the saved device row).
  static Future<Map<String, dynamic>> debugRegisterCurrentToken() async {
    final token = await getFcmTokenSafely();
    if (token.isEmpty) {
      return {'ok': false, 'error': 'FCM token unavailable (APNS not set on iOS?)'};
    }
    AppData.deviceToken = token;
    final result = await _registerTokenWithServer(token);
    await _subscribeToBroadcastTopic();
    return {...result, 'fcmToken': token};
  }

  static const String broadcastTopic = 'doctak-all';

  /// Prints the full FCM token in debug builds so you can copy it for server tests.
  static void logFcmTokenForTesting(String token, {String source = 'app'}) {
    if (token.isEmpty) {
      debugPrint('[FCM] ($source) No device token available');
      return;
    }
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('══════════ FCM DEVICE TOKEN — copy the next line ══════════');
    debugPrint('source: $source');
    final userId = _loggedInUserId();
    debugPrint('userId: ${userId.isNotEmpty ? userId : "(not set yet)"}');
    debugPrint(token);
    debugPrint('═══════════════════════════════════════════════════════════');
    debugPrint('');
    // Some terminals surface `print` more reliably than `debugPrint`.
    print('FCM_DEVICE_TOKEN=$token');
  }

  static Future<void> _subscribeToBroadcastTopic() async {
    try {
      await _firebaseMessaging.subscribeToTopic(broadcastTopic);
      debugPrint('FCM subscribed to topic: $broadcastTopic');
    } catch (e) {
      debugPrint('FCM topic subscribe failed: $e');
    }
  }

  /// Returns the FCM device token, ensuring on iOS that the APNS token has been
  /// set first. On iOS `getToken()` throws (`apns-token-not-set`) or returns
  /// null until the OS has delivered the APNS token, which previously left iOS
  /// devices unregistered — so the server had no token and pushes never arrived.
  /// Waits briefly for the APNS token, then retries `getToken()`.
  static Future<String> getFcmTokenSafely() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        for (int i = 0; i < 5 && (apnsToken == null || apnsToken.isEmpty); i++) {
          await Future.delayed(const Duration(seconds: 1));
          apnsToken = await _firebaseMessaging.getAPNSToken();
        }
        if (apnsToken == null || apnsToken.isEmpty) {
          debugPrint('FCM: APNS token still unavailable — getToken may fail on iOS');
        }
      }

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final token = await _firebaseMessaging.getToken();
          if (token != null && token.isNotEmpty) return token;
        } catch (e) {
          debugPrint('FCM getToken attempt $attempt failed: $e');
          if (e.toString().contains('FIS_AUTH_ERROR')) {
            try {
              await _firebaseMessaging.deleteToken();
              await Future.delayed(const Duration(milliseconds: 500));
            } catch (_) {}
          }
        }
        if (attempt < 3) await Future.delayed(const Duration(seconds: 2));
      }
    } catch (e) {
      debugPrint('FCM getFcmTokenSafely error: $e');
    }
    return '';
  }

  static Future<void> syncDeviceToken() async {
    try {
      await _ensureAndroidNotificationPermission();
      final token = await getFcmTokenSafely();
      if (token.isEmpty) {
        debugPrint('FCM syncDeviceToken: token unavailable');
        return;
      }

      AppData.deviceToken = token;
      try {
        final prefs = SecureStorageService.instance;
        await prefs.initialize();
        await prefs.setString('device_token', token);
      } catch (e) {
        debugPrint('FCM: failed to persist device_token: $e');
      }

      final userId = _loggedInUserId();
      logFcmTokenForTesting(token, source: userId.isNotEmpty ? 'login' : 'syncDeviceToken');
      await _registerTokenWithServer(token);
      await _subscribeToBroadcastTopic();
    } catch (e, stackTrace) {
      debugPrint('FCM syncDeviceToken failed: $e');
      debugPrint('$stackTrace');
    }
  }


  @pragma('vm:entry-point')
  static Future<dynamic> _throwGetMessage(RemoteMessage message) async {
    // Ensure Flutter bindings and plugins are registered before using platform channels
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('PUSH RECEIVED (bg): hasNotification=${message.notification != null} '
        'title="${message.notification?.title ?? message.data['title']}" data=${message.data}');

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

    // Calling module v2: data-only call pushes (incoming_call /
    // call_cancelled with signalVersion=2) show/dismiss the native call UI
    // from this background isolate and are fully handled here.
    if (await CallPushV2.maybeHandleBackground(message)) {
      return;
    }

    if (shouldSuppressPush(message)) {
      debugPrint('Skipping background push (own message or active chat)');
      return;
    }

    await NotificationService.incrementBadgeCount();

    // Calls are handled entirely by CallPushV2 above; any legacy `type == 'call'`
    // push that isn't a v2 call is ignored (legacy calling_module disconnected).
    if (message.data['type'] == 'call') {
      return;
    }

    if (message.notification == null) {
      // Data-only message: the OS shows nothing automatically, so we post it
      // ourselves — but only if it actually has content. Silent data messages
      // (no title/body) must not appear as an empty "Doctak" notification.
      if (!_hasDisplayableContent(message)) {
        debugPrint('Skipping silent data message (no title/body): ${message.data}');
        return;
      }
      await showNotificationWithCustomIcon(
        message.notification,
        message.data,
        _titleFromMessage(message),
        _bodyFromMessage(message),
        message.data['image'] ?? '',
        message.data['banner'] ?? '',
      );
    } else {
      // Message has a `notification` payload: while backgrounded the OS
      // displays it automatically (iOS). Android server payloads are data-only.
      debugPrint('Background notification has a notification payload — letting the OS display it (no duplicate)');
    }
  }

  // More specific methods to check and mark different notification types

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

    final String type = message.data['type'] ?? '';
    final String messageId = message.data['messageId'] ?? '';
    if (messageId.isNotEmpty && type.contains('message')) {
      return 'message:$messageId';
    }

    final String notificationId = message.data['notificationId'] ?? '';
    if (notificationId.isNotEmpty) {
      return 'notif:$notificationId';
    }

    // For other notifications, generate an ID based on content
    final String id = message.data['id'] ?? message.data['entityId'] ?? '';
    final String title = message.notification?.title ?? message.data['title'] ?? '';

    return '$type:$id:${title.hashCode}';
  }

  // Clean up notification entries older than 10 minutes
  static void _cleanupOldEntries(Map<String, int> map) {
    final now = DateTime.now().millisecondsSinceEpoch;
    map.removeWhere((key, timestamp) => (now - timestamp > 600000));
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
        final payload = notificationResponse.payload;
        if (payload == null || payload.isEmpty) return;
        await _handleNotificationPayload(payload);
      },
    );

    await _ensureAndroidNotificationPermission();

    // Skip the permission dialog when already granted (saves ~200–800ms on warm start).
    NotificationSettings settings;
    final currentSettings = await _firebaseMessaging.getNotificationSettings();
    if (currentSettings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } else {
      settings = currentSettings;
    }

    debugPrint('📱 FCM Permission status: ${settings.authorizationStatus}');
    debugPrint('📱 Alert permission: ${settings.alert}');
    debugPrint('📱 Badge permission: ${settings.badge}');
    debugPrint('📱 Sound permission: ${settings.sound}');

    // iOS: badge only in foreground — we show one tray notification ourselves.
    // Showing both the system FCM banner and a local notification duplicated chat alerts.
    if (Platform.isIOS) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_throwGetMessage);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint(
        '📩 FCM foreground: id=${message.messageId} title=${message.notification?.title ?? message.data['title']} type=${message.data['type']}',
      );
      // Generate a notification ID for checking duplicates
      final String notificationId = _getNotificationId(message);

      // Check if this foreground notification was already handled
      if (_shouldSkipForegroundNotification(notificationId)) {
        debugPrint('Skipping duplicate foreground notification: $notificationId');
        return;
      }

      // Mark as handled in foreground map
      _markForegroundNotificationHandled(notificationId);

      // Calling module v2: route call pushes to the call controller
      // (rings via CallKit + in-app screen) instead of the notification tray.
      if (await CallPushV2.maybeHandle(message)) {
        return;
      }

      if (shouldSuppressPush(message)) {
        debugPrint('Skipping foreground push (own message or active chat)');
        return;
      }

      // v2 calls already handled above. Show one local notification in foreground.
      // iOS system banner is disabled above (alert: false) to avoid duplicates.
      if (_hasDisplayableContent(message)) {
        try {
          await _showLocalNotification(message);
        } catch (e, st) {
          debugPrint('Failed to show foreground notification: $e');
          debugPrint('$st');
        }
      } else {
        debugPrint('Skipping silent foreground data message (no title/body): ${message.data}');
      }

      // Badge + in-app counter are best-effort; failures here are non-fatal.
      try {
        await NotificationService.incrementBadgeCount();
        NotificationCounterService().onFCMForegroundPush();
      } catch (e) {
        debugPrint('Badge/counter update failed: $e');
      }
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

      // Calls open via CallKit / calling_module_v2, not the notification tray.
      if (message.data['type'] == 'call') return;

      _handleNotificationPayload(jsonEncode(message.data));
    });

    // Create notification channels for Android
    await _createCallNotificationChannel();

    _firebaseMessaging.onTokenRefresh.listen((token) async {
      AppData.deviceToken = token;
      await _registerTokenWithServer(token);
      await _subscribeToBroadcastTopic();
    });

    // Token fetch + server registration are network-heavy — defer past first frame.
    scheduleMicrotask(() => unawaited(syncDeviceToken()));
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

        // FCM system notifications use this channel id from the server payload.
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'doctak_default',
            'Doctak Notifications',
            description: 'Default channel for push notifications from Doctak',
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

      // Calls are delivered via CallPushV2 + CallKit and resumed by
      // calling_module_v2 on cold start — never route them through here.
      if (initialMessage.data['type'] == 'call') {
        return null;
      }

      NotificationNavigation.setPendingTap(
        Map<String, dynamic>.from(initialMessage.data),
      );

      return initialMessage;
    }

    // Terminated app opened from a tray notification we showed locally (foreground FCM).
    final launchDetails = await _localNotificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map) {
            NotificationNavigation.setPendingTap(Map<String, dynamic>.from(decoded));
          } else {
            NotificationNavigation.setPendingTap({'type': payload});
          }
        } catch (_) {
          NotificationNavigation.setPendingTap({'type': payload});
        }
      }
    }

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

    // Calls render via CallKit / calling_module_v2, never as a tray notification.
    if (message.data['type'] == 'call') return;

    await showNotificationWithCustomIcon(
      message.notification,
      message.data,
      _titleFromMessage(message),
      _bodyFromMessage(message),
      message.data['image'] ?? '',
      message.data['banner'] ?? '',
    );
  }

  @pragma('vm:entry-point')
  static Future<ByteArrayAndroidBitmap?> _getImageFromUrl(String imageUrl) async {
    try {
      final uri = Uri.tryParse(imageUrl);
      if (uri == null || !uri.hasScheme) {
        return null;
      }
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/user_image.png';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      final Uint8List imageBytes = await file.readAsBytes();
      return ByteArrayAndroidBitmap(imageBytes);
    } catch (e) {
      debugPrint('Failed to load notification image: $e');
      return null;
    }
  }

  @pragma('vm:entry-point')
  static int _stableNotificationId(Map<String, dynamic> data) {
    final messageId = (data['messageId'] ?? data['notificationId'] ?? '').toString();
    if (messageId.isNotEmpty) {
      return messageId.hashCode & 0x7fffffff;
    }

    final type = (data['type'] ?? '').toString();
    final entityId = (data['entityId'] ?? data['id'] ?? '').toString();
    final title = (data['title'] ?? '').toString();
    return '$type:$entityId:$title'.hashCode & 0x7fffffff;
  }

  @pragma('vm:entry-point')
  static String? _androidNotificationTag(Map<String, dynamic> data) {
    final messageId = (data['messageId'] ?? '').toString();
    if (messageId.isNotEmpty) return 'msg:$messageId';

    final notificationId = (data['notificationId'] ?? '').toString();
    if (notificationId.isNotEmpty) return 'notif:$notificationId';

    return null;
  }

  @pragma('vm:entry-point')
  static Future<void> showNotificationWithCustomIcon(notification, data, String title, String body, String imageUrl, String bannerImage) async {
    final payloadMap = Map<String, dynamic>.from(data);
    final androidTag = _androidNotificationTag(payloadMap);
    final notificationId = _stableNotificationId(payloadMap);
    final ByteArrayAndroidBitmap? largeIcon = imageUrl != '' ? await _getImageFromUrl(imageUrl) : null;
    final ByteArrayAndroidBitmap? banner = bannerImage != '' ? await _getImageFromUrl(bannerImage) : null;

    const androidIcon = AndroidInitializationSettings('ic_stat_name');
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      showBadge: true,
    );

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      channelShowBadge: true,
      icon: androidIcon.defaultIcon,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ongoing: false,
      autoCancel: true,
      timeoutAfter: 0,
      fullScreenIntent: false,
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      color: Colors.transparent,
      tag: androidTag,
      largeIcon: largeIcon,
      styleInformation: banner != null
          ? BigPictureStyleInformation(banner, contentTitle: title, summaryText: body)
          : null,
    );

    payloadMap.putIfAbsent('title', () => title);
    payloadMap.putIfAbsent('body', () => body);
    if (imageUrl.isNotEmpty) payloadMap.putIfAbsent('image', () => imageUrl);

    try {
      await _localNotificationsPlugin.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          iOS: const DarwinNotificationDetails(
            badgeNumber: 1,
            presentBadge: true,
            presentSound: true,
            presentAlert: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
          android: androidPlatformChannelSpecifics,
        ),
        payload: jsonEncode(payloadMap),
      );
      debugPrint('🔔 Local notification shown: id=$notificationId title="$title"');
    } catch (e, st) {
      debugPrint('❌ _localNotificationsPlugin.show failed: $e');
      debugPrint('$st');
    }
  }

  static Future<void> _handleNotificationPayload(String payload) async {
    if (_isHandlingNotification) {
      debugPrint('Already handling a notification tap, skipping');
      return;
    }

    _isHandlingNotification = true;
    try {
      Map<String, dynamic> data;
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        } else {
          data = {'type': payload};
        }
      } catch (_) {
        data = {'type': payload};
      }

      final prefs = SecureStorageService.instance;
      await prefs.initialize();
      await prefs.setString(_payloadKey, data['type']?.toString() ?? '');
      await prefs.setString(
        _payloadId,
        data['id']?.toString() ?? data['entityId']?.toString() ?? '',
      );

      try {
        if (Platform.isAndroid) {
          await ClearAllNotifications.clear();
        }
      } catch (_) {}

      await NotificationNavigation.openWhenReady(data);
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

  static int notificationCount = 0;

  static Future<void> incrementBadgeCount() async {
    notificationCount++;
    try {
      await AppBadgePlus.updateBadge(notificationCount);
    } catch (e) {
      // Some launchers/devices don't support app badges — never let this throw.
      debugPrint('AppBadgePlus.updateBadge failed: $e');
    }
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
