// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
// import 'package:doctak_app/core/utils/app/AppData.dart';
//
// /// A callback type for handling Pusher events
// typedef PusherEventCallback = void Function(String eventName, Map<String, dynamic> data);
//
// /// Service to manage Pusher channel subscriptions and event listeners
// class PusherService {
//   // Singleton instance
//   static final PusherService _instance = PusherService._internal();
//
//   // Factory constructor
//   factory PusherService() => _instance;
//
//   // Private constructor
//   PusherService._internal();
//
//   // The Pusher client instance
//   PusherChannelsFlutter? _pusher;
//
//   // Map of subscribed channels and their listeners
//   final Map<String, List<_EventListener>> _channelListeners = {};
//
//   // Flag to track initialization
//   bool _isInitialized = false;
//   bool get isInitialized => _isInitialized;
//
//   /// Initialize the Pusher service
//   Future<void> initialize() async {
//     if (_isInitialized) {
//       debugPrint('PusherService is already initialized');
//       return;
//     }
//
//     try {
//       // Get Pusher from AppData
//       _pusher = AppData.pusher;
//
//       // Mark as initialized
//       _isInitialized = true;
//       debugPrint('PusherService initialized successfully');
//
//       // Auto-subscribe to user channel if user is logged in
//       if (AppData.logInUserId != null && AppData.logInUserId.isNotEmpty) {
//         await subscribeToUserChannel();
//       }
//     } catch (e) {
//       _isInitialized = false;
//       debugPrint('Error initializing PusherService: $e');
//       rethrow;
//     }
//   }
//
//   /// Subscribe to the user's personal channel
//   Future<void> subscribeToUserChannel() async {
//     if (AppData.logInUserId == null || AppData.logInUserId.isEmpty) {
//       debugPrint('Cannot subscribe to user channel: User ID is empty');
//       return;
//     }
//
//     final channelName = "user.${AppData.logInUserId}";
//     await subscribeToChannel(channelName);
//   }
//
//   /// Subscribe to a channel and set up event handling
//   Future<void> subscribeToChannel(String channelName) async {
//     if (!_isInitialized) {
//       await initialize();
//     }
//
//     if (_pusher == null) {
//       throw Exception('Pusher not available');
//     }
//
//     try {
//       // Check if we're already subscribed to this channel
//       try {
//         final state = await _pusher!.getChannelState(channelName: channelName);
//         if (state == "SUBSCRIBED") {
//           debugPrint('Already subscribed to channel: $channelName');
//           return;
//         }
//       } catch (e) {
//         // If getChannelState fails, attempt to subscribe anyway
//         debugPrint('Could not get channel state: $e');
//       }
//
//       // Subscribe to the channel with an event handler
//       await _pusher!.subscribe(
//         channelName: channelName,
//         onEvent: (PusherEvent event) {
//           _handlePusherEvent(channelName, event);
//         },
//       );
//
//       debugPrint('Subscribed to channel: $channelName');
//     } catch (e) {
//       debugPrint('Error subscribing to channel $channelName: $e');
//       rethrow;
//     }
//   }
//
//   /// Handle a Pusher event by dispatching to registered listeners
//   void _handlePusherEvent(String channelName, PusherEvent event) {
//     final eventName = event.eventName;
//
//     // Skip internal Pusher events
//     if (eventName.startsWith('pusher:')) {
//       debugPrint('Received Pusher internal event: $eventName');
//       return;
//     }
//
//     // Parse event data
//     Map<String, dynamic> eventData = {};
//     try {
//       if (event.data.isNotEmpty) {
//         eventData = jsonDecode(event.data);
//       }
//     } catch (e) {
//       debugPrint('Error parsing event data: $e');
//       eventData = {'raw_data': event.data};
//     }
//
//     debugPrint('Received event: $eventName on channel: $channelName with data: $eventData');
//
//     // Find all listeners for this channel
//     final listeners = _channelListeners[channelName] ?? [];
//
//     // Notify all listeners that match this event name or wildcard
//     for (var listener in listeners) {
//       if (listener.eventName == '*' || listener.eventName == eventName) {
//         try {
//           listener.callback(eventName, eventData);
//         } catch (e) {
//           debugPrint('Error in event listener callback: $e');
//         }
//       }
//     }
//   }
//
//   /// Register an event listener for a specific channel and event
//   /// Returns a function to unregister this listener
//   Future<Function> listenToEvent({
//     required String channelName,
//     required String eventName,
//     required PusherEventCallback callback,
//   }) async {
//     if (!_isInitialized) {
//       await initialize();
//     }
//
//     // Make sure we're subscribed to the channel
//     await subscribeToChannel(channelName);
//
//     // Create a unique listener object
//     final listener = _EventListener(
//       eventName: eventName,
//       callback: callback,
//     );
//
//     // Add to listeners map
//     _channelListeners[channelName] ??= [];
//     _channelListeners[channelName]!.add(listener);
//
//     // Return a function to remove this specific listener
//     return () {
//       _channelListeners[channelName]?.remove(listener);
//       debugPrint('Removed listener for $eventName on channel $channelName');
//     };
//   }
//
//   /// Unsubscribe from a channel
//   Future<void> unsubscribeFromChannel(String channelName) async {
//     if (!_isInitialized || _pusher == null) {
//       return;
//     }
//
//     try {
//       await _pusher!.unsubscribe(channelName: channelName);
//       _channelListeners.remove(channelName);
//       debugPrint('Unsubscribed from channel: $channelName');
//     } catch (e) {
//       debugPrint('Error unsubscribing from channel $channelName: $e');
//     }
//   }
//
//   /// Disconnect from Pusher completely
//   Future<void> disconnect() async {
//     if (!_isInitialized || _pusher == null) {
//       return;
//     }
//
//     try {
//       await _pusher!.disconnect();
//       _channelListeners.clear();
//       debugPrint('Disconnected from Pusher');
//     } catch (e) {
//       debugPrint('Error disconnecting from Pusher: $e');
//     }
//   }
// }
//
// /// Helper class to store event listener information
// class _EventListener {
//   final String eventName;
//   final PusherEventCallback callback;
//
//   _EventListener({
//     required this.eventName,
//     required this.callback,
//   });
// }