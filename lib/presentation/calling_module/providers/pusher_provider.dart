// import 'dart:async';
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
//
// import '../../../core/utils/app/AppData.dart';
// import '../services/pusher_service.dart';
//
// /// ChangeNotifier that wraps PusherService for use with Provider pattern
// class PusherProvider extends ChangeNotifier {
//   final PusherService _pusherService = PusherService();
//
//   // Maintain notification count and user online status in the provider
//   int _notificationCount = 0;
//   Map<String, bool> _userOnlineStatus = {};
//
//   // Getters
//   int get notificationCount => _notificationCount;
//   Map<String, bool> get userOnlineStatus => _userOnlineStatus;
//   bool get isConnected => _pusherService.isConnected;
//
//   // Stream controllers for global events
//   final _onlineStatusController = StreamController<Map<String, dynamic>>.broadcast();
//   final _notificationCountController = StreamController<Map<String, dynamic>>.broadcast();
//
//   // Stream getters for global events
//   Stream<Map<String, dynamic>> get onlineStatusStream => _onlineStatusController.stream;
//   Stream<Map<String, dynamic>> get notificationCountStream => _notificationCountController.stream;
//
//   PusherProvider() {
//     // Initialize and set up default listeners
//     _initialize();
//   }
//
//   Future<void> _initialize() async {
//     try {
//       // Initialize the Pusher service if not already initialized
//       await _pusherService.initialize();
//
//       // Set up listeners for common global events
//       _setupGlobalListeners();
//
//       notifyListeners();
//     } catch (e) {
//       debugPrint('Error initializing PusherProvider: $e');
//     }
//   }
//
//   Future<void> _setupGlobalListeners() async {
//     final pusherService = PusherService();
//
//     // Register listeners for notification count events
//     pusherService.registerEventListener(
//       channelName: "user.${AppData.logInUserId}",
//       eventName: "NotificationEvent",
//       callback: (data) {
//         print(data);
//         // _notificationCount = data['count'] ?? 0;
//         // _notificationCountController.add(data);
//         notifyListeners();
//       },
//     );
//
//     // Register listeners for online status events
//     await pusherService.registerEventListener(
//       channelName: "user.${AppData.logInUserId}",
//       eventName: "user.online_status",
//       callback: (data) {
//         final userId = data['user_id']?.toString();
//         final isOnline = data['is_online'] == true;
//
//         if (userId != null) {
//           _userOnlineStatus[userId] = isOnline;
//           _onlineStatusController.add(data);
//           notifyListeners();
//         }
//       },
//     );
//   }
//
//   /// Register a listener for a specific event
//   /// Returns a function to unregister the listener
//     listenForEvent({
//     required String channelName,
//     required String eventName,
//     required Function(Map<String, dynamic>) callback,
//   }) {
//     return _pusherService.registerEventListener(
//       channelName: channelName,
//       eventName: eventName,
//       callback: callback,
//     );
//   }
//
//   /// Subscribe to a specific channel if not already subscribed
//   Future<void> subscribeToChannel(String channelName) async {
//     await _pusherService.subscribeToChannel(channelName);
//   }
//
//   /// Check if a specific user is online
//   bool isUserOnline(String userId) {
//     return _userOnlineStatus[userId] ?? false;
//   }
//
//   /// Get all online users
//   List<String> getOnlineUsers() {
//     return _userOnlineStatus.entries
//         .where((entry) => entry.value)
//         .map((entry) => entry.key)
//         .toList();
//   }
//
//   /// Reset notification count (e.g., after viewing notifications)
//   void resetNotificationCount() {
//     if (_notificationCount > 0) {
//       _notificationCount = 0;
//       notifyListeners();
//     }
//   }
//
//   @override
//   void dispose() {
//     _pusherService.dispose();
//     super.dispose();
//   }
// }
//
// /// Example of how to use this provider in a main.dart file:
// ///
// /// ```dart
// /// void main() async {
// ///   WidgetsFlutterBinding.ensureInitialized();
// ///
// ///   // Initialize AppData and configure Pusher first
// ///   await AppData.initialize();
// ///
// ///   runApp(
// ///     MultiProvider(
// ///       providers: [
// ///         ChangeNotifierProvider(create: (_) => PusherProvider()),
// ///         // Other providers...
// ///       ],
// ///       child: MyApp(),
// ///     ),
// ///   );
// /// }
// /// ```
// ///
// /// And in a widget:
// ///
// /// ```dart
// /// class MyWidget extends StatelessWidget {
// ///   @override
// ///   Widget build(BuildContext context) {
// ///     final pusherProvider = Provider.of<PusherProvider>(context);
// ///
// ///     return Text('Notifications: ${pusherProvider.notificationCount}');
// ///   }
// /// }
// /// ```