import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/core/call_service/callkit_service.dart';
import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';

import '../../user_chat_screen/chat_ui_sceen/call_loading_screen.dart';

// Get the global Pusher instance
// This assumes your app has a globally accessible PusherChannelsFlutter instance
PusherChannelsFlutter get pusher => AppData.pusher;

Future<void> startOutgoingCall(String userId, String username, String profilePic, bool isVideoCall) async {

  // Create a key to access the loading screen state
  final GlobalKey<CallLoadingScreenState> loadingScreenKey = GlobalKey<CallLoadingScreenState>();

  // Reference to the Pusher channel name
  String? channelName;
  String? callId;

  // Function to clean up resources
  void cleanupResources() {
    // Unsubscribe from Pusher channel if needed
    if (channelName != null) {
      try {
        pusher.unsubscribe(channelName: channelName!);

        print('Unsubscribed from Pusher channel: $channelName');
      } catch (e) {
        print('Error unsubscribing from Pusher: $e');
      }
    }

    // End any active calls
    try {
      if (callId != null) {
        CallKitService().endCall(callId);
      } else {
        CallKitService().endAllCalls();
      }
    } catch (e) {
      print('Error ending calls during cleanup: $e');
    }
  }

  // Show calling screen immediately
  NavigatorService.navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (context) => CallLoadingScreen(
        key: loadingScreenKey,
        contactName: username,
        contactAvatar: "${AppData.imageUrl}$profilePic",
        isVideoCall: isVideoCall,
        onCancel: () {
          // Pop the loading screen

          Navigator.of(context).pop();
          // Cancel any pending call setup
          cleanupResources();
        },
      ),
    ),
  );

  try {
    // Initialize call in the background with proper error handling
    Map<String, dynamic> callData;

    try {
      // Update loading screen status to "calling"
      loadingScreenKey.currentState?.updateStatus(CallStatus.calling);

      final response = await CallKitService().startOutgoingCall(
          userId: userId,
          calleeName: username,
          avatar: "${AppData.imageUrl}$profilePic",
          hasVideo: isVideoCall
      );

      // Ensure we have proper Map<String, dynamic>
      if (response is Map<String, dynamic>) {
        callData = response;
      } else {
        // Convert to Map<String, dynamic> if needed
        callData = {};
        if (response is Map) {
          response.forEach((key, value) {
            if (key is String) {
              callData[key] = value;
            }
          });
        } else {
          throw Exception('Invalid response format from CallKitService');
        }
      }
    } catch (e) {
      print('Error calling CallKitService.startOutgoingCall: $e');
      throw e;
    }

    // Handle success - subscribe to Pusher for call status updates
    if (callData['success'] == true && callData['callId'] != null) {
      callId = callData['callId'].toString();

      // Subscribe to Pusher channel for call status updates
      try {
        channelName = "user.${AppData.logInUserId}";

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
           if(eventName=='call.ringing') {
              loadingScreenKey.currentState?.updateStatus(CallStatus.ringing);

           } else if(eventName=='call.status') {

             if(eventDataMap.containsKey('callData')) {
               callStatus = eventDataMap['callData']['status'];
             }else{

               callStatus = eventDataMap['statusData']['status'];

             }
             switch (callStatus) {
               case 'ringing':
                 loadingScreenKey.currentState?.updateStatus(
                     CallStatus.ringing);
                 break;

               case 'accepted':
                 loadingScreenKey.currentState?.updateStatus(
                     CallStatus.accepted);
                 // Navigate to call screen after a brief delay to show "accepted" status
                 Future.delayed(const Duration(milliseconds: 500), () {
                   if (NavigatorService.navigatorKey.currentState != null) {
                     NavigatorService.navigatorKey.currentState!
                         .pushReplacement(
                       MaterialPageRoute(
                         settings: const RouteSettings(name: '/call'),
                         builder: (context) =>
                             CallScreen(
                               callId: callId!,
                               contactId: userId,
                               contactName: username,
                               contactAvatar: "${AppData.imageUrl}$profilePic",
                               isIncoming: false,
                               isVideoCall: isVideoCall,
                               token: callData['token']?.toString() ?? '',
                             ),
                       ),
                     );
                   }
                 });
                 break;

               case 'rejected':
                 loadingScreenKey.currentState?.updateStatus(
                     CallStatus.rejected);

                 // Close call screen after a delay
                 Future.delayed(Duration(seconds: 2), () {
                   if (NavigatorService.navigatorKey.currentState != null) {
                     NavigatorService.navigatorKey.currentState?.pop();
                     cleanupResources();
                   }
                 });
                 break;

               case 'busy':
                 loadingScreenKey.currentState?.updateStatus(CallStatus.busy);
                 // Close call screen after a delay
                 Future.delayed(Duration(seconds: 2), () {
                   if (NavigatorService.navigatorKey.currentState != null) {
                     NavigatorService.navigatorKey.currentState?.pop();
                     cleanupResources();
                   }
                 });
                 break;
               case 'ended':
               // If call was ended from the other side before we connected
                 if (NavigatorService.navigatorKey.currentState != null) {
                   NavigatorService.navigatorKey.currentState?.pop();
                   cleanupResources();
                 }
                 break;
               case 'missed':
               // If call was ended from the other side before we connected
                 if (NavigatorService.navigatorKey.currentState != null) {
                   NavigatorService.navigatorKey.currentState?.pop();
                   cleanupResources();
                 }
                 break;
             }
           }else if(eventName=='call.busy') {
             // If call was ended from the other side before we connected
             loadingScreenKey.currentState?.updateStatus(CallStatus.busy);
             // Close call screen after a delay
             Future.delayed(Duration(seconds: 2), () {
               if (NavigatorService.navigatorKey.currentState != null) {
                 NavigatorService.navigatorKey.currentState?.pop();
                 cleanupResources();
               }
             });
           }else if(eventName=='call.ended') {
             // If call was ended from the other side before we connected
             loadingScreenKey.currentState?.updateStatus(CallStatus.busy);
             // Close call screen after a delay
             Future.delayed(Duration(seconds: 2), () {
               if (NavigatorService.navigatorKey.currentState != null) {
                 NavigatorService.navigatorKey.currentState?.pop();
                 cleanupResources();
               }
             });
           }
          },
        );

        // Set a timeout for ringing status
        Future.delayed(Duration(seconds: 30), () {
          // If still in ringing status after 30 seconds, assume timeout
          if (loadingScreenKey.currentState?.status == CallStatus.ringing ||
              loadingScreenKey.currentState?.status == CallStatus.calling) {
            loadingScreenKey.currentState?.updateStatus(CallStatus.timeout);

            Future.delayed(Duration(seconds: 2), () {
              if (NavigatorService.navigatorKey.currentState != null) {
                NavigatorService.navigatorKey.currentState?.pop();
                cleanupResources();
              }
            });
          }
        });

      } catch (e) {
        print('Error subscribing to Pusher channel: $e');
        // Continue with call flow even if Pusher fails - CallKit will still work
      }
    } else {
      // Handle API error
      NavigatorService.navigatorKey.currentState?.pop(); // Remove loading screen
      _showCallError("Failed to establish call. Please try again.");
      cleanupResources();
    }
  } catch (error) {
    print('Error starting outgoing call: $error');

    NavigatorService.navigatorKey.currentState?.pop(); // Remove loading screen
    _showCallError("Error starting call. Please try again.");

    // Make sure any partial call state is cleaned up
    cleanupResources();
  }
}

// Helper function to show call errors
void _showCallError(String message) {
  final context = NavigatorService.navigatorKey.currentState?.overlay?.context;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}