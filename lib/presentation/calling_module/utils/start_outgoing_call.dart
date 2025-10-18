import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/navigator_service.dart';
import 'package:doctak_app/core/utils/call_permission_handler.dart';
import 'package:doctak_app/core/utils/pusher_service.dart';
import 'package:doctak_app/presentation/calling_module/services/callkit_service.dart';
import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
import 'package:doctak_app/localization/app_localization.dart';

import '../../user_chat_screen/chat_ui_sceen/call_loading_screen.dart';

// Use PusherService singleton which handles initialization and connection
PusherService get pusherService => PusherService();

Future<void> startOutgoingCall(
  String userId,
  String username,
  String profilePic,
  bool isVideoCall,
) async {
  // Get the current context for permission dialogs
  final context = NavigatorService.navigatorKey.currentState?.context;

  // Check and request permissions before starting the call
  if (context != null) {
    final hasPermissions = await callPermissionHandler.hasCallPermissions(
      isVideoCall: isVideoCall,
    );

    if (!hasPermissions) {
      // Request permissions with professional UI
      final granted = await callPermissionHandler.requestWithUI(
        context,
        isVideoCall: isVideoCall,
        showRationale: true,
      );

      if (!granted) {
        // User denied permissions, don't start the call
        return;
      }
    }
  }

  // Create a key to access the loading screen state
  final GlobalKey<CallLoadingScreenState> loadingScreenKey =
      GlobalKey<CallLoadingScreenState>();

  // Reference to the Pusher channel name
  String? channelName;
  String? callId;

  // Track if call was accepted - don't force end accepted calls
  bool callAccepted = false;
  bool callNavigatedToScreen = false;

  // Function to clean up resources (only for failed/cancelled calls)
  void cleanupResources({bool forceEnd = false}) {
    debugPrint(
      '📞 cleanupResources() called - callAccepted: $callAccepted, forceEnd: $forceEnd',
    );

    // Don't cleanup if call was accepted and navigated to call screen
    if (callAccepted && callNavigatedToScreen && !forceEnd) {
      debugPrint('📞 Skipping cleanup - call was accepted and is active');
      return;
    }

    // Unsubscribe from Pusher channel if needed
    final currentChannel = channelName;
    if (currentChannel != null) {
      try {
        pusherService.unsubscribeFromChannel(currentChannel);
        print('📞 Unsubscribed from Pusher channel: $channelName');
      } catch (e) {
        print('📞 Error unsubscribing from Pusher: $e');
      }
    }

    // Only end calls if they weren't accepted or if forced
    if (!callAccepted || forceEnd) {
      try {
        if (callId != null) {
          CallKitService().forceEndOutgoingCall(callId);
        } else {
          CallKitService().endAllCalls();
        }
      } catch (e) {
        print('📞 Error ending calls during cleanup: $e');
      }
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

      debugPrint('📞 Calling CallKitService().startOutgoingCall...');
      final response = await CallKitService().startOutgoingCall(
        userId: userId,
        calleeName: username,
        avatar: "${AppData.imageUrl}$profilePic",
        hasVideo: isVideoCall,
      );
      debugPrint('📞 CallKitService response: $response');

      // Response is already Map<String, dynamic>
      callData = response;
    } catch (e) {
      print('Error calling CallKitService.startOutgoingCall: $e');
      throw e;
    }

    // Handle success - subscribe to Pusher for call status updates
    debugPrint(
      '📞 Checking callData success: ${callData['success']}, callId: ${callData['callId']}',
    );
    if (callData['success'] == true && callData['callId'] != null) {
      callId = callData['callId'].toString();
      debugPrint('📞 Call initiated successfully with callId: $callId');

      // Subscribe to Pusher channel for call status updates
      try {
        channelName = "user.${AppData.logInUserId}";

        print('📞 Subscribing to Pusher channel: $channelName for call events');

        // Initialize PusherService if not already connected
        if (!pusherService.isConnected) {
          print('📞 Initializing PusherService...');
          await pusherService.initialize();
          await pusherService.connect();
          // Wait a bit for connection to stabilize
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // Subscribe to the channel
        await pusherService.subscribeToChannel(channelName);

        // Wait for subscription to be ready
        await Future.delayed(const Duration(milliseconds: 300));
        print('📞 Pusher subscription ready for channel: $channelName');

        // Register event listeners for call status updates
        void handleCallEvent(dynamic eventData) {
          print('📞 handleCallEvent received data: $eventData');
          print('📞 handleCallEvent data type: ${eventData.runtimeType}');

          Map<String, dynamic> eventDataMap = {};
          if (eventData is Map<String, dynamic>) {
            eventDataMap = eventData;
          } else if (eventData is Map) {
            eventDataMap = Map<String, dynamic>.from(eventData);
          } else if (eventData is String) {
            try {
              eventDataMap = jsonDecode(eventData);
            } catch (e) {
              print('📞 Error parsing event data: $e');
              return;
            }
          }

          print('📞 Parsed eventDataMap: $eventDataMap');

          // Extract call status from different possible locations
          String? callStatus;

          // Try different paths to find the status
          if (eventDataMap.containsKey('callData') &&
              eventDataMap['callData'] is Map) {
            callStatus = eventDataMap['callData']['status']?.toString();
            print('📞 Found status in callData: $callStatus');
          }
          if (callStatus == null &&
              eventDataMap.containsKey('statusData') &&
              eventDataMap['statusData'] is Map) {
            callStatus = eventDataMap['statusData']['status']?.toString();
            print('📞 Found status in statusData: $callStatus');
          }
          if (callStatus == null && eventDataMap.containsKey('status')) {
            callStatus = eventDataMap['status']?.toString();
            print('📞 Found status directly: $callStatus');
          }
          if (callStatus == null && eventDataMap.containsKey('call_status')) {
            callStatus = eventDataMap['call_status']?.toString();
            print('📞 Found status in call_status: $callStatus');
          }
          // Also check for data wrapper
          if (callStatus == null &&
              eventDataMap.containsKey('data') &&
              eventDataMap['data'] is Map) {
            final dataMap = eventDataMap['data'] as Map;
            callStatus =
                dataMap['status']?.toString() ??
                dataMap['call_status']?.toString();
            print('📞 Found status in data wrapper: $callStatus');
          }

          print('📞 Final extracted call status: $callStatus');

          if (callStatus == null) {
            print('📞 No status found in event data');
            return;
          }

          // Normalize status to lowercase
          final normalizedStatus = callStatus.toLowerCase();
          print('📞 Normalized status: $normalizedStatus');

          switch (normalizedStatus) {
            case 'ringing':
              print('📞 Processing RINGING status');
              loadingScreenKey.currentState?.updateStatus(CallStatus.ringing);
              break;

            case 'no_answer':
            case 'noanswer':
            case 'no-answer':
            case 'unanswered':
              print('📞 Processing NO ANSWER status');
              loadingScreenKey.currentState?.updateStatus(CallStatus.timeout);
              // Close the loading screen after showing no answer
              Future.delayed(const Duration(seconds: 2), () {
                if (NavigatorService.navigatorKey.currentState != null &&
                    !callNavigatedToScreen) {
                  NavigatorService.navigatorKey.currentState?.pop();
                  cleanupResources();
                }
              });
              break;

            case 'accepted':
              print('📞 Processing ACCEPTED status - CRITICAL!');
              // Mark call as accepted IMMEDIATELY to prevent cleanup
              callAccepted = true;
              debugPrint('📞 CRITICAL: Call accepted event received!');
              debugPrint('📞 Updating loading screen to accepted status...');
              loadingScreenKey.currentState?.updateStatus(CallStatus.accepted);

              // Navigate to call screen immediately without delay
              if (NavigatorService.navigatorKey.currentState != null &&
                  !callNavigatedToScreen) {
                callNavigatedToScreen = true;
                debugPrint('📞 Navigating to CallScreen with callId: $callId');
                NavigatorService.navigatorKey.currentState!.pushReplacement(
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/call'),
                    builder: (context) => CallScreen(
                      callId: callId!,
                      contactId: userId,
                      contactName: username,
                      contactAvatar: "${AppData.imageUrl}$profilePic",
                      isIncoming: false,
                      isVideoCall: isVideoCall,
                      token: callData['token']?.toString(),
                    ),
                  ),
                );
              }
              break;

            case 'rejected':
              loadingScreenKey.currentState?.updateStatus(CallStatus.rejected);
              Future.delayed(Duration(seconds: 2), () {
                if (NavigatorService.navigatorKey.currentState != null) {
                  NavigatorService.navigatorKey.currentState?.pop();
                  cleanupResources();
                }
              });
              break;

            case 'busy':
              loadingScreenKey.currentState?.updateStatus(CallStatus.busy);
              Future.delayed(Duration(seconds: 2), () {
                if (NavigatorService.navigatorKey.currentState != null) {
                  NavigatorService.navigatorKey.currentState?.pop();
                  cleanupResources();
                }
              });
              break;

            case 'ended':
            case 'missed':
            case 'offline':
              // Only handle if not already navigated to CallScreen
              if (!callNavigatedToScreen &&
                  NavigatorService.navigatorKey.currentState != null) {
                // Show appropriate status
                if (normalizedStatus == 'offline') {
                  loadingScreenKey.currentState?.updateStatus(CallStatus.offline);
                } else {
                  loadingScreenKey.currentState?.updateStatus(CallStatus.timeout);
                }
                // Give time to show the status
                Future.delayed(const Duration(seconds: 2), () {
                  if (!callNavigatedToScreen &&
                      NavigatorService.navigatorKey.currentState != null) {
                    NavigatorService.navigatorKey.currentState?.pop();
                    cleanupResources();
                  }
                });
              }
              break;
          }
        }

        // Register listeners for different call events
        pusherService.registerEventListener('call.ringing', (data) {
          print('📞 Received call.ringing event');
          loadingScreenKey.currentState?.updateStatus(CallStatus.ringing);
        });

        pusherService.registerEventListener('call.status', handleCallEvent);
        pusherService.registerEventListener('Call_Status', handleCallEvent);

        // CRITICAL: Add listener for call.accepted event directly
        pusherService.registerEventListener('call.accepted', (data) {
          print('📞 Received call.accepted event directly!');
          callAccepted = true;
          loadingScreenKey.currentState?.updateStatus(CallStatus.accepted);

          if (NavigatorService.navigatorKey.currentState != null &&
              !callNavigatedToScreen) {
            callNavigatedToScreen = true;
            debugPrint('📞 Navigating to CallScreen from call.accepted event');
            NavigatorService.navigatorKey.currentState!.pushReplacement(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/call'),
                builder: (context) => CallScreen(
                  callId: callId!,
                  contactId: userId,
                  contactName: username,
                  contactAvatar: "${AppData.imageUrl}$profilePic",
                  isIncoming: false,
                  isVideoCall: isVideoCall,
                  token: callData['token']?.toString(),
                ),
              ),
            );
          }
        });

        // Also listen for Call_Accepted (different casing)
        pusherService.registerEventListener('Call_Accepted', (data) {
          print('📞 Received Call_Accepted event!');
          callAccepted = true;
          loadingScreenKey.currentState?.updateStatus(CallStatus.accepted);

          if (NavigatorService.navigatorKey.currentState != null &&
              !callNavigatedToScreen) {
            callNavigatedToScreen = true;
            debugPrint('📞 Navigating to CallScreen from Call_Accepted event');
            NavigatorService.navigatorKey.currentState!.pushReplacement(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/call'),
                builder: (context) => CallScreen(
                  callId: callId!,
                  contactId: userId,
                  contactName: username,
                  contactAvatar: "${AppData.imageUrl}$profilePic",
                  isIncoming: false,
                  isVideoCall: isVideoCall,
                  token: callData['token']?.toString(),
                ),
              ),
            );
          }
        });

        pusherService.registerEventListener('call.busy', (data) {
          print('📞 Received call.busy event');
          loadingScreenKey.currentState?.updateStatus(CallStatus.busy);
          Future.delayed(Duration(seconds: 2), () {
            if (NavigatorService.navigatorKey.currentState != null) {
              NavigatorService.navigatorKey.currentState?.pop();
              cleanupResources();
            }
          });
        });

        pusherService.registerEventListener('call.ended', (data) {
          print(
            '📞 Received call.ended event - callAccepted: $callAccepted, callNavigatedToScreen: $callNavigatedToScreen',
          );
          // Only handle if call wasn't accepted and navigated to CallScreen
          // CallScreen handles its own call.ended events
          if (!callNavigatedToScreen &&
              NavigatorService.navigatorKey.currentState != null) {
            NavigatorService.navigatorKey.currentState?.pop();
            cleanupResources();
          }
        });

        // Also register for CallAccepted with underscore (server might use different naming)
        pusherService.registerEventListener('CallAccepted', (data) {
          print('📞 Received CallAccepted event!');
          handleCallEvent({'status': 'accepted', 'data': data});
        });

        // Register for accepted with dot notation
        pusherService.registerEventListener('accepted', (data) {
          print('📞 Received accepted event!');
          handleCallEvent({'status': 'accepted', 'data': data});
        });

        // Register a generic event handler for unknown event names
        // This will be called when PusherService can't find exact match but data contains status
        pusherService.registerEventListener(
          '__call_status_fallback__',
          handleCallEvent,
        );

        // Set a timeout for ringing status
        Future.delayed(Duration(seconds: 30), () {
          // Skip timeout if call was already accepted
          if (callAccepted) {
            debugPrint('📞 Timeout skipped - call was accepted');
            return;
          }

          // If still in ringing status after 30 seconds, assume timeout/no answer
          if (loadingScreenKey.currentState?.status == CallStatus.ringing ||
              loadingScreenKey.currentState?.status == CallStatus.calling) {
            print('📞 Call timeout after 30 seconds - showing no answer');
            loadingScreenKey.currentState?.updateStatus(CallStatus.timeout);

            Future.delayed(Duration(seconds: 2), () {
              // Double-check call wasn't accepted during the delay
              if (!callAccepted &&
                  !callNavigatedToScreen &&
                  NavigatorService.navigatorKey.currentState != null) {
                print('📞 Closing loading screen after no answer timeout');
                NavigatorService.navigatorKey.currentState?.pop();
                cleanupResources();
              } else {
                print('📞 Skipping close - call was accepted: $callAccepted, navigated: $callNavigatedToScreen');
              }
            });
          }
        });
      } catch (e) {
        print('📞 Error subscribing to Pusher channel: $e');
        // Continue with call flow even if Pusher fails - CallKit will still work
      }
    } else {
      // Handle API error
      NavigatorService.navigatorKey.currentState
          ?.pop(); // Remove loading screen
      _showCallError(
        translation(
          NavigatorService.navigatorKey.currentState!.context,
        ).lbl_failed_to_establish_call,
      );
      cleanupResources();
    }
  } catch (error) {
    print('Error starting outgoing call: $error');

    NavigatorService.navigatorKey.currentState?.pop(); // Remove loading screen
    _showCallError(
      translation(
        NavigatorService.navigatorKey.currentState!.context,
      ).lbl_error_starting_call,
    );

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
