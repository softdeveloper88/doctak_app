import 'dart:io';

import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:clear_all_notifications/clear_all_notifications.dart';
import 'package:doctak_app/core/call_service/callkit_service.dart';
import 'package:doctak_app/core/utils/force_updrage_page.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/presentation/call_module/call_api_service.dart';
import 'package:doctak_app/presentation/call_module/call_service.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/case_discussion_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static const String _payloadKey = 'type';
  static const String _payloadId = 'id';

  // Add CallKitService instance
  static final CallKitService _callKitService = CallKitService();

  @pragma('vm:entry-point')
  static Future<dynamic> _throwGetMessage(RemoteMessage message) async {
    await Firebase.initializeApp();
    debugPrint('PUSH RECEIVED ${message.data}');

    await NotificationService.incrementBadgeCount();

    // Check if it's a call notification
    if (message.data['type'] == 'call') {
      final callId = message.data['call_id'] ?? '';
      final callerName = message.data['caller_name'] ?? 'Unknown Caller';
      final callerId = message.data['caller_id'] ?? '';
      final hasVideo = message.data['is_video_call'] == 'true';
      final avatar = message.data['caller_avatar'] ?? '';

      // Use CallKitService to display incoming call UI
      await _callKitService.displayIncomingCall(
        uuid: callId,
        callerName: callerName,
        callerId: callerId,
        avatar: avatar,
        hasVideo: hasVideo,
      );
    } else {
      // Handle regular notifications
      await showNotificationWithCustomIcon(
          message.notification,
          message.data,
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          message.data['image'] ?? '',
          message.data['banner'] ?? ''
      );
    }
  }

  // Initialize the notification services (both local and FCM)
  static Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_stat_name');
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      defaultPresentSound: true,
      defaultPresentAlert: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentBadge: true,
    );
    const InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        print('notification ${notificationResponse.payload}');
        if (notificationResponse.payload != null) {
          // Handle notification tap
        }
      },
    );

    // Initialize FCM and handle background/terminated state
    await _firebaseMessaging.requestPermission();

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_throwGetMessage);

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await NotificationService.incrementBadgeCount();
      _showLocalNotification(message);
    });

    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationService.clearBadgeCount();

      // Handle notification tap based on type
      if (message.data['type'] == 'call') {
        // Call notifications are handled by CallKit
      } else {
        _handleNotificationTap(
          message.notification?.title ?? '',
          message.data['image'] ?? '',
          message.data['type'] ?? '',
          message.data['id'] ?? '',
        );
      }
    });

    // Create notification channel for Android
    await _createCallNotificationChannel();
  }

  // Create call notification channel for Android
  static Future<void> _createCallNotificationChannel() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      _localNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'call_channel',
            'Call Notifications',
            description: 'Channel for call notifications',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }
    }
  }

  static Future<RemoteMessage?> getInitialNotificationRoute() async {
    // For Firebase Messaging
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    print('initialMessage $initialMessage');
    if (initialMessage != null) {
      print('type ${initialMessage.data['type']}');
      // Extract the route or screen from the notification data
      return initialMessage; // Assuming 'screen' is the key in your payload
    }
    // For local notifications
    return null;
  }

  // Show local notification when FCM is received
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (message.data['type'] == 'call') {
      final callId = message.data['call_id'] ?? '';
      final callerName = message.data['caller_name'] ?? 'Unknown Caller';
      final callerId = message.data['caller_id'] ?? '';
      final hasVideo = message.data['is_video_call'] == 'true';
      final avatar = message.data['caller_avatar'] ?? '';

      // Use CallKitService to display incoming call UI
      await _callKitService.displayIncomingCall(
        uuid: callId,
        callerName: callerName,
        callerId: callerId,
        avatar: avatar,
        hasVideo: hasVideo,
      );
    } else {
      await showNotificationWithCustomIcon(
          message.notification,
          message.data,
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          message.data['image'] ?? '',
          message.data['banner'] ?? '');
    }
  }

  static Future<ByteArrayAndroidBitmap> _getImageFromUrl(
      String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/user_image.png';
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    final Uint8List imageBytes = await file.readAsBytes();
    return ByteArrayAndroidBitmap(imageBytes);
  }

  static Future<void> showNotificationWithCustomIcon(notification, data,
      String title, String body, String imageUrl, String bannerImage) async {
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
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    //
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_stat_name');
    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      defaultPresentSound: true,
      defaultPresentAlert: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentBadge: true,
    );
    const InitializationSettings initializationSettings =
    InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS);
    //
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
          print('notificationResponse $notificationResponse');
          if (notificationResponse.payload != null) {
            _handleNotificationTap(
              title,
              imageUrl,
              notificationResponse.payload!,
              data['id'] ?? '',
            );
          }
        });
    var channel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title // description
        importance: Importance.max,
        showBadge: true);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    AndroidNotificationDetails(
      channelShowBadge: true,
      icon: initializationSettingsAndroid.defaultIcon,
      'high_importance_channel',
      // Channel ID
      'High Importance Notifications',
      // Channel name
      channelDescription: 'your_channel_description',
      // Channel description
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    _localNotificationsPlugin.show(
        notification.hashCode,
        title,
        body,
        payload: data['type'],
        NotificationDetails(
          iOS: const DarwinNotificationDetails(
            badgeNumber: 1,
            presentBadge: true,
            presentSound: true,
            presentAlert: true,
          ),
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelShowBadge: true,
            icon: initializationSettingsAndroid.defaultIcon,
            channelDescription: channel.name,
            // Channel description
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            // importance: Importance.max,
            // priority: Priority.high,
            ongoing: false,          // Prevent dismissal by swiping
            autoCancel: false,       // Don't auto-remove on tap
            timeoutAfter: 0,         // No automatic timeout
            fullScreenIntent: true,  // Show even when device locked
            category: AndroidNotificationCategory.event,
            visibility: NotificationVisibility.public,
            color: Colors.transparent,
            largeIcon: largeIcon,
            styleInformation: bannerImage != ''
                ? BigPictureStyleInformation(
              banner,
              contentTitle: notification.title,
              summaryText: notification.body,
            )
                : null,
            // icon: 'ic_stat_name',
          ),
        ));
  }

  // Handle notification tap (local or FCM)
  static Future<void> _handleNotificationTap(
      String title, String profilePic, String payload, String id) async {
    // Save the payload to shared preferences for later retrieval
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_payloadKey, payload);
    await prefs.setString(_payloadId, id);

    // Use Navigator to go to the specific screen
    _navigateToScreen(title, profilePic, payload, id);
  }

  // Get the notification payload when the app is terminated
  static Future<String?> getNotificationPayload() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_payloadKey);
  }

  // Clear the stored notification payload once handled
  static Future<void> clearNotificationPayload() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_payloadKey);
  }

  // Navigate to the specific screen based on the payload
  static void _navigateToScreen(
      String username, String profilePic, String payload, String id) {
    print('payload $payload');
    print('username $username');
    print('id $id');

    if (NavigatorService.navigatorKey.currentState != null) {
      NavigatorService.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) {
          if (payload == 'message_received') {
            return ChatRoomScreen(
                id: id,
                roomId: '',
                username: username,
                profilePic: profilePic.replaceAll(
                    'https://doctak-file.s3.ap-south-1.amazonaws.com/', ''));
          } else if (payload == 'follow_request' ||
              payload == 'follower_notification' ||
              payload == 'un_follower_notification' ||
              payload == 'friend_request') {
            return SVProfileFragment(
              userId: id,
            );
          } else if (payload == 'comments_on_posts' || payload == 'reply_to_comment' ||
              payload == 'like_comment_on_post' ||
              payload == 'like_comments') {
            return PostDetailsScreen(
              commentId: int.parse(id),
            );
          } else if (payload == 'new_like' || payload == 'like_on_posts') {
            return PostDetailsScreen(
              postId: int.parse(id),
            );
          } else if (payload == 'new_job_posted' ||
              payload == 'job_update' ||
              payload == 'job_post_notification') {
            return JobsDetailsScreen(
              jobId: id,
            );
          } else if (payload == 'conference_invitation') {
            return ConferencesScreen();
          } else if (payload == 'new_discuss_case' ||
              payload == 'discuss_case_comment') {
            return const CaseDiscussionScreen();
          }
          return ForceUpgradePage(); // Default route if payload does not match
        }),
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
    await ClearAllNotifications.clear();
  }

  // Register device token with the API service for notifications
  static Future<void> registerDeviceToken(CallApiService apiService) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await apiService.registerDeviceToken(
          token: token,
          deviceType: Platform.isIOS ? 'ios' : 'android',
        );

        print('Device token registered: $token');

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          try {
            await apiService.registerDeviceToken(
              token: newToken,
              deviceType: Platform.isIOS ? 'ios' : 'android',
            );
            print('Device token refreshed and registered: $newToken');
          } catch (e) {
            print('Error registering refreshed device token: $e');
          }
        });
      }
    } catch (e) {
      print('Error registering device token: $e');
    }
  }
}