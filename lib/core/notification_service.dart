import 'dart:io';

import 'package:doctak_app/core/utils/force_updrage_page.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/coming_soon_screen/coming_soon_screen.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static const String _payloadKey = 'type';

  // Initialize the notification services (both local and FCM)
  static Future<void> initialize() async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_name');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        if (notificationResponse.payload != null) {
          _handleNotificationTap(notificationResponse.payload!);
        }
      },
    );

    // Initialize FCM and handle background/terminated state
    await _firebaseMessaging.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data['type']);
    });

    // For terminated state handling
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data['type']);
    }
  }

  static Future<String?> getInitialNotificationRoute() async {
    // For Firebase Messaging
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    print('initialMessage $initialMessage');
    if (initialMessage != null) {
      print(initialMessage.data['type']);
      // Extract the route or screen from the notification data
      return initialMessage
          .data['type']; // Assuming 'screen' is the key in your payload
    }
    // For local notifications
    final NotificationAppLaunchDetails? details =
        await _localNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details!.notificationResponse?.payload ??
          ''; // Assuming payload contains route
    }

    return null;
  }

  // Show local notification when FCM is received
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // Channel ID
      'your_channel_name', // Channel name
      channelDescription: 'your_channel_description', // Channel description
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await showNotificationWithCustomIcon(
        message.notification,
        message.data,
        message.notification?.title ??'',
        message.notification?.body ??'',
        message.data['image'] ?? '',
        message.data['banner'] ?? '');
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
    final ByteArrayAndroidBitmap largeIcon = await _getImageFromUrl(imageUrl);
    ByteArrayAndroidBitmap banner;
    if (bannerImage != '') {
      banner = await _getImageFromUrl(bannerImage);
    } else {
      banner = ByteArrayAndroidBitmap(Uint8List(0));
    }
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    //
    // const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_name');
    //
    // const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    //
    // await flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
    var channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title // description
      importance: Importance.max,
    );
    const AndroidNotificationDetails(
      'high_importance_channel', // Channel ID
      'High Importance Notifications', // Channel name
      channelDescription: 'your_channel_description', // Channel description
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    // await _localNotificationsPlugin.show(
    //   message.hashCode,
    //   message.notification?.title ?? 'New Notification', // Notification title
    //   message.notification?.body ?? 'You have received a new notification', // Notification body
    //   platformChannelSpecifics,
    //   payload: message.data['type'], // Pass payload from FCM data
    // );

    _localNotificationsPlugin.show(
        notification.hashCode,
        title,
        body,
        payload: data['type'],
        NotificationDetails(
          android: AndroidNotificationDetails(
            color: Colors.transparent,
            channel.id,
            channel.name,
            largeIcon: largeIcon,
            styleInformation: bannerImage != ''
                ? BigPictureStyleInformation(
                    banner,
                    contentTitle: notification.title,
                    summaryText: notification.body,
                  )
                : null,
            icon: 'ic_stat_name',
          ),
        ));
  }

  // Handle notification tap (local or FCM)
  static Future<void> _handleNotificationTap(String payload) async {
    // Save the payload to shared preferences for later retrieval
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_payloadKey, payload);

    // Use Navigator to go to the specific screen
    _navigateToScreen(payload);
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
  static void _navigateToScreen(String payload) {
    if (NavigatorService.navigatorKey.currentState != null) {
      NavigatorService.navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) {
          print(payload);
          if (payload == 'follow_request') {
            return const ComingSoonScreen();
          }
          return const ForceUpgradePage(); // Default route if payload does not match
        }),
      );
    }
  }
}
