// import 'dart:async';
// import 'dart:io';

// import 'package:doctak_app/core/utils/app/AppData.dart';
// import 'package:doctak_app/presentation/case_discussion/screens/discussion_list_screen.dart';
// import 'package:doctak_app/presentation/NoInternetScreen.dart';
// import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
// import 'package:doctak_app/presentation/calling_module/services/agora_service.dart';
// import 'package:doctak_app/presentation/calling_module/services/call_service.dart';

// // import 'presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
// import 'package:doctak_app/presentation/calling_module/services/callkit_service.dart';
// import 'package:doctak_app/presentation/case_discussion/bloc/create_discussion_bloc.dart';
// import 'package:doctak_app/presentation/case_discussion/bloc/discussion_detail_bloc.dart';
// import 'package:doctak_app/presentation/case_discussion/bloc/discussion_list_bloc.dart';
// import 'package:doctak_app/presentation/case_discussion/repository/case_discussion_repository.dart';
// import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
// import 'package:doctak_app/presentation/coming_soon_screen/coming_soon_screen.dart';
// import 'package:doctak_app/presentation/doctak_ai_module/blocs/ai_chat/ai_chat_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
// import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
// import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/bloc/conference_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
// import 'package:doctak_app/presentation/home_screen/home/screens/news_screen/bloc/news_bloc.dart';
// import 'package:doctak_app/presentation/home_screen/store/AppStore.dart';
// import 'package:doctak_app/presentation/home_screen/utils/AppTheme.dart';
// import 'package:doctak_app/presentation/login_screen/bloc/login_bloc.dart';
// import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
// import 'package:doctak_app/presentation/splash_screen/unified_splash_upgrade_screen.dart';
// import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
// import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:doctak_app/l10n/app_localizations.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_mobx/flutter_mobx.dart';
// import 'package:hive_flutter/hive_flutter.dart'; // Import hive_flutter package
// import 'package:nb_utils/nb_utils.dart';
// import 'package:provider/provider.dart';
// import 'package:sizer/sizer.dart';

// import 'ads_setting/ad_setting.dart';
// import 'core/app_export.dart';
// import 'core/network/my_https_override.dart';
// import 'core/notification_service.dart';
// import 'core/utils/common_navigator.dart';
// import 'core/utils/get_shared_value.dart';
// import 'core/utils/pusher_service.dart';
// import 'core/utils/text_scale_helper.dart';
// import 'core/utils/simple_fixed_media_query.dart';
// import 'core/utils/fixed_sizer.dart';
// import 'core/utils/edge_to_edge_helper.dart';
// import 'firebase_options.dart';
// import 'widgets/fixed_scale_material_app.dart';
// import 'package:overlay_support/overlay_support.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:path_provider/path_provider.dart' as path_provider;

// /// Waits for native plugin channels to be ready.
// /// In release mode, there can be a race condition where Dart code starts
// /// executing before native plugin channels are fully established.
// ///
// /// Uses timeout to prevent hanging if channels never respond.
// Future<void> _waitForPluginChannels() async {
//   debugPrint('Waiting for plugin channels...');

//   // Simple approach: just wait a fixed time and continue
//   // This avoids the hang issue where path_provider never responds
//   await Future.delayed(const Duration(milliseconds: 500));
//   debugPrint('Plugin channel wait complete');
// }

// // Global service instances that persist throughout app lifecycle
// final CallService globalCallService = CallService();
// final CallKitService callKitService = CallKitService();

// // Store instance
// AppStore appStore = AppStore();
// var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

// // Flag to indicate if we're handling a call at app startup
// bool isHandlingCallAtStartup = false;

// // Toggle for Crashlytics
// const _kShouldTestAsyncErrorOnInit = false;
// bool isCurrentlyOnNoInternet = false;
// const _kTestingCrashlytics = true;

// /// Create a [AndroidNotificationChannel] for heads up notifications
// late AndroidNotificationChannel channel;

// /// Initialize the [FlutterLocalNotificationsPlugin] package.
// late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey(
//   debugLabel: 'Main Navigator',
// );
// var calllRoute;

// @pragma('vm:entry-point')
// void onDidReceiveNotificationResponse(
//   NotificationResponse notificationResponse,
// ) async {
//   final String? payload = notificationResponse.payload;
//   if (notificationResponse.payload != null) {
//     debugPrint('notification payload: $payload');
//   }
//   NavigatorService.navigatorKey.currentState?.push(
//     MaterialPageRoute(builder: (context) => const ComingSoonScreen()),
//   );
// }

// void checkNotificationPermission() async {
//   var status = await Permission.notification.status;

//   if (status.isDenied) {
//     // Request permission if it's denied
//     await Permission.notification.request();
//   }
// }

// // Shorebird update check function (commented out due to import issues)
// // Future<void> _checkForShorebirdUpdates() async {
// //   try {
// //     debugPrint('Checking for Shorebird updates...');
// //
// //     // Initialize Shorebird
// //     final shorebirdCodePush = ShorebirdCodePush();
// //
// //     // Check if updates are available
// //     final isUpdateAvailable = await shorebirdCodePush
// //         .isNewPatchAvailableForDownload();
// //
// //     if (isUpdateAvailable) {
// //       debugPrint('Shorebird update available, downloading...');
// //
// //       // Download the update
// //       await shorebirdCodePush.downloadUpdateIfAvailable();
// //       debugPrint('Shorebird update downloaded successfully');
// //
// //       // Check if the update is ready to install
// //       final isUpdateReadyToInstall = await shorebirdCodePush
// //           .isNewPatchReadyToInstall();
// //
// //       if (isUpdateReadyToInstall) {
// //         debugPrint('Shorebird update ready to install on next restart');
// //       }
// //     } else {
// //       debugPrint('No Shorebird updates available');
// //     }
// //   } catch (e) {
// //     debugPrint('Error checking for Shorebird updates: $e');
// //   }
// // }

// // Helper function to get base URL from preferences
// Future<String> _getBaseUrlFromPrefs() async {
//   try {
//     final prefs = await getSharedPreferencesWithRetry();
//     return await prefs.getString('api_base_url') ?? AppData.remoteUrl3;
//   } catch (e) {
//     debugPrint('Error getting base URL from prefs: $e');
//     return AppData.remoteUrl3;
//   }
// }

// Future<String> getToken() async {
//   try {
//     final prefs = await getSharedPreferencesWithRetry();
//     return await prefs.getString('token') ?? '';
//   } catch (e) {
//     debugPrint('Error getting token from prefs: $e');
//     return AppData.userToken ?? "";
//   }
// }

// // Clean up any stale call data
// Future<void> _cleanupStaleCallData() async {
//   try {
//     final prefs = await getSharedPreferencesWithRetry();
//     final now = DateTime.now().millisecondsSinceEpoch;

//     // Check if there's call data that might be stale
//     final savedCallId = await prefs.getString('active_call_id');
//     final pendingCallId = await prefs.getString('pending_call_id');

//     // Clean up active call data if it's too old
//     if (savedCallId != null) {
//       final savedTimestamp = await prefs.getInt('active_call_timestamp') ?? 0;
//       if (now - savedTimestamp > 60000) {
//         // 60 seconds
//         debugPrint('Found stale active call data, cleaning up');
//         await prefs.remove('active_call_id');
//         await prefs.remove('active_call_user_id');
//         await prefs.remove('active_call_name');
//         await prefs.remove('active_call_avatar');
//         await prefs.remove('active_call_has_video');
//         await prefs.remove('active_call_timestamp');
//       }
//     }

//     // Clean up pending call data if it's too old
//     if (pendingCallId != null) {
//       final pendingTimestamp =
//           await prefs.getInt('pending_call_timestamp') ?? 0;
//       if (now - pendingTimestamp > 30000) {
//         // 30 seconds
//         debugPrint('Found stale pending call data, cleaning up');
//         await prefs.remove('pending_call_id');
//         await prefs.remove('pending_call_timestamp');
//         await prefs.remove('pending_caller_id');
//         await prefs.remove('pending_caller_name');
//         await prefs.remove('pending_caller_avatar');
//         await prefs.remove('pending_call_has_video');
//       }
//     }
//   } catch (e) {
//     debugPrint('Error cleaning up stale call data: $e');
//   }
// }

// // Check if there's an active call that should be prioritized
// Future<bool> _isActiveCallPending() async {
//   debugPrint('Checking for active calls...');
//   try {
//     // First check for active calls in CallKit
//     final activeCalls = await callKitService.getActiveCalls();
//     if (activeCalls.isNotEmpty) {
//       final call = activeCalls.first;
//       final callId = call['id']?.toString() ?? '';

//       // Verify call is recent
//       final prefs = await getSharedPreferencesWithRetry();
//       final timestamp = await prefs.getInt('active_call_timestamp') ?? 0;
//       final now = DateTime.now().millisecondsSinceEpoch;

//       // Only consider calls within the last 30 seconds
//       if (now - timestamp < 30000) {
//         debugPrint('Found active recent call in CallKit: $callId');
//         return true;
//       }

//       debugPrint(
//         'Found call in CallKit but it appears stale, clearing: $callId',
//       );
//       await callKitService.endCall(callId);
//     }

//     // Check for pending call info from preferences
//     final prefs = await getSharedPreferencesWithRetry();

//     // First check for pending calls from notifications
//     final pendingCallId = await prefs.getString('pending_call_id');
//     if (pendingCallId != null) {
//       final pendingTimestamp =
//           await prefs.getInt('pending_call_timestamp') ?? 0;
//       final now = DateTime.now().millisecondsSinceEpoch;

//       // Only consider pending calls within the last 15 seconds
//       if (now - pendingTimestamp < 15000) {
//         debugPrint('Found pending call from notification: $pendingCallId');
//         return true;
//       }
//     }

//     // Then check for active calls from saved state
//     final savedCallId = await prefs.getString('active_call_id');
//     if (savedCallId != null) {
//       final savedTimestamp = await prefs.getInt('active_call_timestamp') ?? 0;
//       final now = DateTime.now().millisecondsSinceEpoch;

//       // Only consider saved calls within the last 30 seconds
//       if (now - savedTimestamp < 30000) {
//         debugPrint('Found recent saved call info: $savedCallId');
//         return true;
//       }
//     }

//     return false;
//   } catch (e) {
//     debugPrint('Error checking for active call: $e');
//     return false;
//   }
// }

// Future<void> main() async {
//   // Ensure Flutter is initialized
//   WidgetsFlutterBinding.ensureInitialized();
//   debugPrint('=== DOCTAK APP STARTING ===');

//   // Variables to track initialization state
//   bool firebaseInitialized = false;
//   RemoteMessage? initialRoute;
//   bool isHandlingCallAtStartup = false;
//   String baseUrl = AppData.remoteUrl3;

//   // Wrap ALL initialization in try-catch to ensure runApp is always called
//   try {
//     debugPrint('Step 1: Waiting for plugin channels...');
//     // CRITICAL: In release mode, native plugin channels may not be ready immediately
//     // after WidgetsFlutterBinding.ensureInitialized(). We need to wait for them.
//     // This is especially important for Pigeon-based plugins like path_provider.
//     await _waitForPluginChannels();
//     debugPrint('Step 1: Plugin channels ready');

//     debugPrint('Step 2: Initializing Hive...');
//     // Initialize Hive with retry mechanism for release mode timing issues
//     bool hiveInitialized = false;
//     for (int attempt = 1; attempt <= 3 && !hiveInitialized; attempt++) {
//       try {
//         await Hive.initFlutter();
//         debugPrint('Hive initialized successfully');
//         hiveInitialized = true;
//       } catch (e) {
//         debugPrint('Hive initialization attempt $attempt failed: $e');
//         if (attempt < 3) {
//           await Future.delayed(Duration(milliseconds: 300 * attempt));
//         } else {
//           // Final fallback - try without path_provider
//           try {
//             Hive.init('.');
//             debugPrint('Hive initialized with fallback method');
//             hiveInitialized = true;
//           } catch (e2) {
//             debugPrint('Hive fallback initialization failed: $e2');
//             // Continue anyway - Hive may not be critical for app start
//           }
//         }
//       }
//     }

//     // Override HTTP client
//     HttpOverrides.global = MyHttpsOverrides();

//     debugPrint('Starting app initialization...');

//     // Initialize Shorebird for over-the-air updates (commented out due to import issues)
//     // try {
//     //   // Check for updates in the background
//     //   _checkForShorebirdUpdates();
//     // } catch (e) {
//     //   debugPrint('Shorebird initialization failed: $e');
//     // }

//     // Initialize Firebase FIRST, before any Firebase-dependent services
//     try {
//       await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform,
//       );
//       firebaseInitialized = true;
//       debugPrint('Firebase initialized successfully');
//     } catch (e) {
//       debugPrint('Firebase initialization error: $e');
//       // Try to continue - some features may not work but app should still launch
//     }

//     // Initialize other services
//     try {
//       await initializeAsync();
//       debugPrint('initializeAsync completed');
//     } catch (e) {
//       debugPrint('Error in initializeAsync: $e');
//       // Continue even if this fails
//     }

//     // Initialize image cache manager
//     try {
//       // PostImageCacheManager.initMemoryPressureListener();
//       // Pre-create cache instance
//       // PostImageCacheManager.instance;
//       debugPrint('PostImageCacheManager initialized');
//     } catch (e) {
//       debugPrint('Error initializing PostImageCacheManager: $e');
//     }

//     baseUrl = await _getBaseUrlFromPrefs();
//     try {
//       // Step 1: Initialize CallKit service FIRST - highest priority
//       debugPrint('Initializing CallKitService...');
//       await callKitService.initialize(
//         baseUrl: baseUrl,
//         shouldUpdateStatus: false, // Let CallService handle status updates
//       );
//       debugPrint('CallKitService initialized successfully');
//     } catch (e) {
//       debugPrint('Error initializing CallKitService, continuing: $e');
//       // Continue even if this fails as CallService will retry
//     }

//     // Set up Crashlytics ONLY if Firebase initialized successfully
//     if (firebaseInitialized) {
//       try {
//         const fatalError = true;
//         FlutterError.onError = (errorDetails) {
//           try {
//             if (fatalError) {
//               FirebaseCrashlytics.instance.recordFlutterFatalError(
//                 errorDetails,
//               );
//             } else {
//               FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
//             }
//           } catch (e) {
//             debugPrint('Error recording Flutter error: $e');
//           }
//         };

//         PlatformDispatcher.instance.onError = (error, stack) {
//           try {
//             if (fatalError) {
//               FirebaseCrashlytics.instance.recordError(
//                 error,
//                 stack,
//                 fatal: true,
//               );
//             } else {
//               FirebaseCrashlytics.instance.recordError(error, stack);
//             }
//           } catch (e) {
//             debugPrint('Error recording platform error: $e');
//           }
//           return true;
//         };
//         debugPrint('Firebase Crashlytics configured');
//       } catch (e) {
//         debugPrint('Firebase Crashlytics setup error: $e');
//         // Continue without crashlytics
//       }
//     } else {
//       debugPrint('Skipping Crashlytics setup - Firebase not initialized');
//     }

//     // IMPORTANT: Clean up any stale call data BEFORE checking for active calls
//     await _cleanupStaleCallData();
//     debugPrint('Stale call data cleaned up');

//     // Load the base URL from preferences or use default
//     debugPrint('Using API base URL: $baseUrl');

//     // Create CallKitService instance first - no async await here
//     // This is crucial to avoid the LateInitializationError
//     try {
//       // Step 1: Initialize CallKit service FIRST - highest priority
//       debugPrint('Initializing CallKitService...');
//       await callKitService.initialize(
//         baseUrl: baseUrl,
//         shouldUpdateStatus: false, // Let CallService handle status updates
//       );
//       debugPrint('CallKitService initialized successfully');
//     } catch (e) {
//       debugPrint('Error initializing CallKitService, continuing: $e');
//       // Continue even if this fails as CallService will retry
//     }

//     // Initialize notification service AFTER Firebase and CallKit are initialized
//     try {
//       await NotificationService.initialize();
//       debugPrint('Notification service initialized');
//     } catch (e) {
//       debugPrint('Error initializing NotificationService, continuing: $e');
//       // Continue even if this fails as it's not critical for call handling
//     }

//     // Get initial notification if app was opened from a notification
//     try {
//       initialRoute = await NotificationService.getInitialNotificationRoute();
//       debugPrint('Initial route: ${initialRoute?.data}');
//     } catch (e) {
//       debugPrint('Error getting initial notification route: $e');
//       // Continue without initial route
//     }

//     // Check if app was launched from a call notification
//     bool isFromCallNotification = false;
//     if (initialRoute != null && initialRoute.data['type'] == 'call') {
//       isFromCallNotification = true;
//       isHandlingCallAtStartup = true;
//       debugPrint('App launched from call notification: ${initialRoute.data}');
//     } else {
//       // Check if there's an active call that should be prioritized
//       try {
//         isHandlingCallAtStartup = await _isActiveCallPending();
//       } catch (e) {
//         debugPrint('Error checking for active calls: $e');
//         isHandlingCallAtStartup = false;
//       }
//     }

//     // Step 2: Initialize CallService with the same baseUrl
//     try {
//       debugPrint('Initializing CallService...');
//       await globalCallService.initialize(
//         baseUrl: baseUrl,
//         isFromCallNotification: isFromCallNotification,
//       );
//       debugPrint('CallService initialized successfully');
//     } catch (e) {
//       debugPrint('Error initializing CallService, continuing: $e');
//       // Continue even if this fails as we already have notification service
//     }

//     // Set up notification channel for Android
//     channel = const AndroidNotificationChannel(
//       'high_importance_channel',
//       'High Importance Notifications',
//       importance: Importance.max,
//     );

//     // Step 3: Handle incoming call if launched from notification with a small delay
//     if (isFromCallNotification && initialRoute != null) {
//       // Use a small delay to ensure services are fully initialized
//       await Future.delayed(const Duration(milliseconds: 500));

//       // Extract call information
//       final callId = initialRoute.data['call_id'] ?? '';
//       final callerName = initialRoute.data['caller_name'] ?? 'Unknown Caller';
//       final callerId = initialRoute.data['caller_id'] ?? '';
//       final hasVideo = initialRoute.data['is_video_call'] == 'true';
//       final avatar = initialRoute.data['caller_avatar'] ?? '';

//       debugPrint(
//         'Handling incoming call from notification: $callId from $callerName',
//       );

//       try {
//         await globalCallService.handleIncomingCall(
//           callId: callId,
//           callerName: callerName,
//           callerId: callerId,
//           callerAvatar: avatar,
//           isVideoCall: hasVideo,
//         );
//       } catch (e) {
//         debugPrint('Error handling incoming call at startup: $e');

//         // Try again after a longer delay if initial handling fails
//         Future.delayed(const Duration(seconds: 1), () {
//           try {
//             globalCallService.handleIncomingCall(
//               callId: callId,
//               callerName: callerName,
//               callerId: callerId,
//               callerAvatar: avatar,
//               isVideoCall: hasVideo,
//             );
//           } catch (e) {
//             debugPrint('Second attempt also failed: $e');
//           }
//         });
//       }
//     } else if (isHandlingCallAtStartup) {
//       // There's an active call to restore
//       debugPrint('Resuming active call from startup...');

//       // Use a small delay to ensure services are fully initialized
//       await Future.delayed(const Duration(milliseconds: 500));

//       try {
//         await callKitService.resumeCallScreenIfNeeded();
//       } catch (e) {
//         debugPrint('Error resuming call screen: $e');

//         // Try again with a longer delay
//         Future.delayed(const Duration(seconds: 1), () {
//           try {
//             callKitService.resumeCallScreenIfNeeded();
//           } catch (e) {
//             debugPrint('Second attempt to resume call screen failed: $e');
//           }
//         });
//       }
//     }

//     // Initialize AdMob
//     try {
//       AdmobSetting.initialization();
//     } catch (e) {
//       debugPrint('Error initializing AdMob: $e');
//     }

//     // Set app theme
//     appStore.toggleDarkMode(value: false);

//     // Initialize system settings and start the app
//     try {
//       await SystemChrome.setPreferredOrientations([
//         DeviceOrientation.portraitUp,
//       ]);
//       debugPrint('System orientation set');
//     } catch (e) {
//       debugPrint('Error setting orientation: $e');
//     }

//     // Try to initialize PrefUtils separately
//     try {
//       await PrefUtils().init();
//       debugPrint('PrefUtils initialized');
//     } catch (e) {
//       debugPrint('PrefUtils initialization error: $e');
//       // Continue without PrefUtils - app should still work
//     }

//     // Configure edge-to-edge display
//     try {
//       EdgeToEdgeHelper.configureEdgeToEdge();
//       debugPrint('Edge-to-edge configured');
//     } catch (e) {
//       debugPrint('Error configuring edge-to-edge: $e');
//     }
//   } catch (e, stackTrace) {
//     // Catch ANY unhandled error during initialization
//     debugPrint('CRITICAL: Unhandled error during app initialization: $e');
//     debugPrint('Stack trace: $stackTrace');
//     // Continue to runApp anyway
//   }

//   // ALWAYS run the app, even if initialization failed
//   debugPrint('Launching app UI...');
//   runApp(
//     MyApp(
//       message: initialRoute,
//       initialRoute: isHandlingCallAtStartup
//           ? 'call'
//           : initialRoute?.data['type'] ?? '',
//       id: initialRoute?.data['id'] ?? '',
//     ),
//   );
// }

// class MyApp extends StatefulWidget {
//   final String? initialRoute;
//   String? id;
//   RemoteMessage? message;

//   MyApp({Key? key, this.message, this.initialRoute, this.id}) : super(key: key);

//   @override
//   State<MyApp> createState() => _MyAppState();

//   static void setLocale(BuildContext context, Locale newLocale) {
//     _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
//     state?.setLocale(newLocale);
//   }
// }

// List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
// final Connectivity _connectivity = Connectivity();
// late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
//   FirebaseMessaging? firebaseMessaging;
//   FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   Locale? _locale;

//   setLocale(Locale locale) {
//     setState(() {
//       _locale = locale;
//     });
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _connectivitySubscription.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     debugPrint('App lifecycle state changed to: $state');

//     // Flag to identify if navigating back to a call
//     bool isReturningToCall = false;

//     if (state == AppLifecycleState.resumed) {
//       // Check for active calls when app comes to foreground
//       if (globalCallService.hasActiveCall) {
//         isReturningToCall = true;

//         // Verify call is still active
//         _verifyAndShowCallScreen();
//       } else {
//         // Only clear badges if not returning to a call
//         NotificationService.clearBadgeCount();
//       }
//     }

//     // Use the global instance to handle lifecycle changes
//     globalCallService.handleAppLifecycleState(state);
//   }

//   /// Verify if we have an active call and show the call screen
//   Future<void> _verifyAndShowCallScreen() async {
//     try {
//       // Check if we have active calls
//       final activeCalls = await callKitService.getActiveCalls();

//       if (activeCalls.isNotEmpty) {
//         final call = activeCalls.first;
//         final callId = call['id']?.toString() ?? '';

//         // Quick timeout check
//         final prefs = await getSharedPreferencesWithRetry();
//         final timestamp = await prefs.getInt('active_call_timestamp') ?? 0;
//         final now = DateTime.now().millisecondsSinceEpoch;

//         if (now - timestamp > 60000) {
//           // 60 seconds
//           // Call is too old, end it
//           debugPrint('Call too old, ending: $callId');
//           await callKitService.endCall(callId);
//           return;
//         }

//         debugPrint(
//           'Found active call, ensuring call screen is displayed: $callId',
//         );
//         await callKitService.resumeCallScreenIfNeeded();
//       }
//     } catch (e) {
//       debugPrint('Error verifying and showing call screen: $e');
//     }
//   }

//   bool _isRequestingPermission = false;

//   Future<void> setFCMSetting() async {
//     if (_isRequestingPermission) return;
//     _isRequestingPermission = true;

//     try {
//       // Check if Firebase is initialized before trying to use Firebase Messaging
//       if (Firebase.apps.isEmpty) {
//         debugPrint('Firebase not initialized, skipping FCM setup');
//         return;
//       }

//       NotificationSettings settings = await FirebaseMessaging.instance
//           .requestPermission(
//             alert: true,
//             badge: true,
//             sound: true,
//             criticalAlert: true, // Important for call notifications
//           );
//       print('User granted permission: ${settings.authorizationStatus}');
//     } catch (e) {
//       print('Error requesting FCM permission: $e');
//       // Continue without FCM - app should still work
//     } finally {
//       _isRequestingPermission = false;
//     }
//   }

//   @override
//   void didChangeDependencies() {
//     getLocale().then((locale) => {setLocale(locale)});
//     NotificationService.clearBadgeCount(); // Clears badge when app resumes
//     super.didChangeDependencies();
//   }

//   late Future<void> _initializeFlutterFireFuture;

//   // Define an async function to initialize FlutterFire
//   Future<void> _initializeFlutterFire() async {
//     try {
//       // Check if Firebase is initialized before trying to use Crashlytics
//       if (Firebase.apps.isEmpty) {
//         debugPrint('Firebase not initialized, skipping Crashlytics setup');
//         return;
//       }

//       if (_kTestingCrashlytics) {
//         // Force enable crashlytics collection enabled if we're testing it.
//         await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
//           true,
//         );
//       } else {
//         // Else only enable it in non-debug builds.
//         // You could additionally extend this to allow users to opt-in.
//         await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
//           !kDebugMode,
//         );
//       }
//       debugPrint('Crashlytics collection settings configured');
//     } catch (e) {
//       debugPrint('Error initializing FlutterFire crashlytics: $e');
//       // Continue without crashlytics
//     }
//   }

//   // Platform messages are asynchronous, so we initialize in an async method.
//   Future<void> initConnectivity() async {
//     late List<ConnectivityResult> result;
//     // Platform messages may fail, so we use a try/catch PlatformException.
//     try {
//       result = await _connectivity.checkConnectivity();
//     } on PlatformException catch (e) {
//       // developer.log('Couldn\'t check connectivity status', error: e);
//       return;
//     }

//     // If the widget was removed from the tree while the asynchronous platform
//     // message was in flight, we want to discard the reply rather than calling
//     // setState to update our non-existent appearance.
//     if (!mounted) {
//       return Future.value(null);
//     }

//     return _updateConnectionStatus(result);
//   }

//   Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
//     setState(() {
//       _connectionStatus = result;
//     });

//     if (_connectionStatus.first == ConnectivityResult.none) {
//       isCurrentlyOnNoInternet = true;
//       launchScreen(
//         NavigatorService.navigatorKey.currentState!.overlay!.context,
//         NoInternetScreen(),
//       );
//     } else {
//       if (isCurrentlyOnNoInternet) {
//         Navigator.pop(
//           NavigatorService.navigatorKey.currentState!.overlay!.context,
//         );
//         isCurrentlyOnNoInternet = false;
//       }
//     }

//     print('Connectivity changed: $_connectionStatus');
//   }

//   @override
//   void initState() {
//     WidgetsBinding.instance.addObserver(this);

//     // Try to initialize Firebase Messaging only if Firebase is initialized
//     try {
//       if (Firebase.apps.isNotEmpty) {
//         firebaseMessaging = FirebaseMessaging.instance;
//         debugPrint('Firebase Messaging initialized');
//       } else {
//         debugPrint('Firebase not initialized, skipping Firebase Messaging');
//       }
//     } catch (e) {
//       debugPrint('Error initializing FirebaseMessaging: $e');
//       // Continue without firebase messaging
//     }

//     initConnectivity();
//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
//       _updateConnectionStatus,
//     );
//     NotificationService.clearBadgeCount(); // Clears badge when app resumes
//     setFCMSetting();
//     // setToken();
//     _initializeFlutterFireFuture = _initializeFlutterFire();

//     // Check if we're handling a call at startup and setup appropriate callbacks
//     if (isHandlingCallAtStartup) {
//       print('App started with active call, setting up call screen priority');
//       // Delay app main flow if we're handling a call
//       Future.delayed(const Duration(milliseconds: 500), () {
//         // Check if any calls are active at this point
//         callKitService.getActiveCalls().then((activeCalls) {
//           if (activeCalls.isNotEmpty) {
//             print('Ensuring call screen remains visible');
//             callKitService.resumeCallScreenIfNeeded();
//           }
//         });
//       });
//     }

//     super.initState();
//   }

//   Map<String, dynamic> userMap = {};

//   @override
//   Widget build(BuildContext context) {
//     return FixedSizer(
//       child: MultiBlocProvider(
//         providers: [
//           // ChangeNotifierProvider(create: (_) => ConnectivityService()),
//           BlocProvider(create: (context) => LoginBloc()),
//           Provider<AgoraService>(
//             create: (_) => AgoraService(),
//             dispose: (_, service) => service.release(),
//           ),

//           // ChangeNotifierProvider(create: (_) => PusherProvider()),
//           ///
//           ///
//           BlocProvider<AiChatBloc>(create: (context) => AiChatBloc()),
//           // BlocProvider(create: (context) => DropdownBloc()),
//           BlocProvider(
//             create: (context) => DiscussionDetailBloc(
//               repository: CaseDiscussionRepository(
//                 baseUrl: AppData.base2,
//                 getAuthToken: () {
//                   return AppData.userToken ?? "";
//                 },
//               ),
//             ),
//           ),
//           BlocProvider(
//             create: (context) => CreateDiscussionBloc(
//               repository: CaseDiscussionRepository(
//                 baseUrl: AppData.base2,
//                 getAuthToken: () {
//                   return AppData.userToken ?? "";
//                 },
//               ),
//             ),
//           ),
//           BlocProvider(create: (context) => HomeBloc()),
//           BlocProvider(create: (context) => DrugsBloc()),
//           BlocProvider(create: (context) => SplashBloc()),
//           BlocProvider(create: (context) => JobsBloc()),
//           BlocProvider(create: (context) => SearchPeopleBloc()),
//           BlocProvider(create: (context) => ChatGPTBloc()),
//           BlocProvider(create: (context) => ConferenceBloc()),
//           BlocProvider(create: (context) => GuidelinesBloc()),
//           BlocProvider(create: (context) => AddPostBloc()),
//           BlocProvider(create: (context) => ProfileBloc()),
//           BlocProvider(create: (context) => ChatBloc()),

//           // We're using a global instance, so this is just for UI components that need it
//           // It won't be used for app lifecycle events
//           ChangeNotifierProvider<CallService>.value(value: globalCallService),
//           BlocProvider(
//             create: (context) =>
//                 ThemeBloc(ThemeState(themeType: PrefUtils().getThemeData())),
//           ),
//         ],
//         child: BlocBuilder<ThemeBloc, ThemeState>(
//           builder: (context, state) {
//             return Observer(
//               builder: (_) => OverlaySupport.global(
//                 child: SimpleFixedMediaQuery.wrap(
//                   context: context,
//                   child: MaterialApp(
//                     scaffoldMessengerKey: globalMessengerKey,
//                     navigatorKey: NavigatorService.navigatorKey,
//                     // If handling a call, use '/call' as our home route, otherwise use the regular route
//                     initialRoute: isHandlingCallAtStartup
//                         ? '/call'
//                         : '/${widget.initialRoute}',

//                     // Add onGenerateRoute to better handle deep linking for calls
//                     onGenerateRoute: (settings) {
//                       print('Generating route for: ${settings.name}');

//                       // Handle call routes with special care
//                       if (settings.name == '/call') {
//                         // When no arguments are provided, get active call info from CallKit
//                         if (settings.arguments == null) {
//                           // Return a "loading" route that will be replaced with call info
//                           return MaterialPageRoute(
//                             settings: const RouteSettings(name: '/call'),
//                             builder: (context) {
//                               // Use a FutureBuilder to get call info and show appropriate screen
//                               return FutureBuilder<List<Map<String, dynamic>>>(
//                                 future: callKitService.getActiveCalls(),
//                                 builder: (context, snapshot) {
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     // Show a loading indicator while getting call info
//                                     return const Scaffold(
//                                       body: Center(
//                                         child: CircularProgressIndicator(),
//                                       ),
//                                     );
//                                   }

//                                   if (snapshot.hasData &&
//                                       snapshot.data!.isNotEmpty) {
//                                     // We have active call data, but verify it's still active
//                                     final call = snapshot.data!.first;
//                                     final callId = call['id']?.toString() ?? '';

//                                     // Extract call data carefully - handling type issues
//                                     Map<String, dynamic> extra = {};
//                                     if (call['extra'] is Map) {
//                                       final rawExtra = call['extra'] as Map;
//                                       rawExtra.forEach((key, value) {
//                                         if (key is String) {
//                                           extra[key] = value;
//                                         }
//                                       });
//                                     }

//                                     final userId =
//                                         extra['userId']?.toString() ?? '';
//                                     final name =
//                                         call['nameCaller']?.toString() ??
//                                         'Unknown';
//                                     final avatar =
//                                         extra['avatar']?.toString() ?? '';
//                                     final hasVideo =
//                                         extra['has_video'] == true ||
//                                         extra['has_video'] == 'true';

//                                     // Navigate to call screen - handle null safety properly
//                                     WidgetsBinding.instance
//                                         .addPostFrameCallback((_) {
//                                           Navigator.of(context).pushReplacement(
//                                             MaterialPageRoute(
//                                               settings: const RouteSettings(
//                                                 name: '/call',
//                                               ),
//                                               builder: (context) => CallScreen(
//                                                 callId: callId,
//                                                 contactId: userId,
//                                                 contactName: name,
//                                                 contactAvatar: avatar,
//                                                 isIncoming: true,
//                                                 isVideoCall: hasVideo,
//                                                 token: '',
//                                               ),
//                                             ),
//                                           );
//                                         });

//                                     // Return a temporary screen while we check
//                                     return const Scaffold(
//                                       body: Center(
//                                         child: Column(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             CircularProgressIndicator(),
//                                             SizedBox(height: 16),
//                                             Text('Preparing call...'),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   }

//                                   // No active call found, check for pending calls
//                                   WidgetsBinding.instance.addPostFrameCallback((
//                                     _,
//                                   ) async {
//                                     final prefs =
//                                         await getSharedPreferencesWithRetry();
//                                     final pendingCallId = await prefs.getString(
//                                       'pending_call_id',
//                                     );

//                                     if (pendingCallId != null) {
//                                       // Check if the pending call is recent
//                                       final pendingTimestamp =
//                                           await prefs.getInt(
//                                             'pending_call_timestamp',
//                                           ) ??
//                                           0;
//                                       final now =
//                                           DateTime.now().millisecondsSinceEpoch;

//                                       if (now - pendingTimestamp < 15000) {
//                                         // Within 15 seconds
//                                         // Extract pending call information
//                                         final callerId =
//                                             await prefs.getString(
//                                               'pending_caller_id',
//                                             ) ??
//                                             '';
//                                         final callerName =
//                                             await prefs.getString(
//                                               'pending_caller_name',
//                                             ) ??
//                                             'Unknown';
//                                         final avatar =
//                                             await prefs.getString(
//                                               'pending_caller_avatar',
//                                             ) ??
//                                             '';
//                                         final hasVideo =
//                                             await prefs.getBool(
//                                               'pending_call_has_video',
//                                             ) ??
//                                             false;

//                                         // Handle the pending call
//                                         Navigator.pushReplacement(
//                                           context,
//                                           MaterialPageRoute(
//                                             settings: const RouteSettings(
//                                               name: '/call',
//                                             ),
//                                             builder: (context) => CallScreen(
//                                               callId: pendingCallId,
//                                               contactId: callerId,
//                                               contactName: callerName,
//                                               contactAvatar: avatar,
//                                               isIncoming: true,
//                                               isVideoCall: hasVideo,
//                                               token: '',
//                                             ),
//                                           ),
//                                         );
//                                         return;
//                                       }
//                                     }

//                                     // If we get here, no call is active, redirect to home
//                                     Navigator.of(
//                                       context,
//                                     ).pushReplacementNamed('/');
//                                   });

//                                   return const Scaffold(
//                                     body: Center(
//                                       child: CircularProgressIndicator(),
//                                     ),
//                                   );
//                                 },
//                               );
//                             },
//                           );
//                         }

//                         // Handle call with provided arguments
//                         final args = _extractCallArguments(settings.arguments);

//                         return MaterialPageRoute(
//                           settings: RouteSettings(
//                             name: '/call',
//                           ), // Important for route recognition
//                           builder: (context) => CallScreen(
//                             callId: args['callId'] ?? '',
//                             contactId: args['contactId'] ?? '',
//                             contactName: args['contactName'] ?? 'Unknown',
//                             contactAvatar: args['contactAvatar'] ?? '',
//                             isIncoming: args['isIncoming'] ?? true,
//                             isVideoCall: args['isVideoCall'] ?? false,
//                             token: args['token'] ?? '',
//                           ),
//                         );
//                       }

//                       // Handle message routes
//                       if (settings.name == '/message_received') {
//                         return MaterialPageRoute(
//                           settings: settings,
//                           builder: (context) => ChatRoomScreen(
//                             id: widget.id.toString(),
//                             roomId: '',
//                             username: widget.message?.notification?.title ?? "",
//                             profilePic:
//                                 widget.message?.data['image'] ??
//                                 ''.replaceAll(AppData.imageUrl, ''),
//                           ),
//                         );
//                       }

//                       // Let other routes be handled by the routes map
//                       return null;
//                     },

//                     routes: {
//                       '/': (context) => UnifiedSplashUpgradeScreen(),

//                       // Keep all your existing routes
//                       '/follow_request': (context) =>
//                           SVProfileFragment(userId: widget.id ?? ''),
//                       '/follower_notification': (context) =>
//                           SVProfileFragment(userId: widget.id ?? ''),
//                       '/un_follower_notification': (context) =>
//                           SVProfileFragment(userId: widget.id ?? ''),
//                       '/friend_request': (context) =>
//                           SVProfileFragment(userId: widget.id ?? ''),
//                       '/message_received': (context) => ChatRoomScreen(
//                         id: widget.id.toString(),
//                         roomId: '',
//                         username: widget.message?.notification?.title ?? "",
//                         profilePic:
//                             widget.message?.data['image'] ??
//                             ''.replaceAll(AppData.imageUrl, ''),
//                       ),
//                       '/comments_on_posts': (context) => PostDetailsScreen(
//                         commentId: int.parse(widget.id ?? '0'),
//                       ),
//                       '/reply_to_comment': (context) => PostDetailsScreen(
//                         commentId: int.parse(widget.id ?? '0'),
//                       ),
//                       '/like_comment_on_post': (context) => PostDetailsScreen(
//                         commentId: int.parse(widget.id ?? '0'),
//                       ),
//                       '/like_comments': (context) => PostDetailsScreen(
//                         commentId: int.parse(widget.id ?? '0'),
//                       ),
//                       '/new_like': (context) => PostDetailsScreen(
//                         postId: int.parse(widget.id ?? '0'),
//                       ),
//                       '/like_on_posts': (context) => PostDetailsScreen(
//                         postId: int.parse(widget.id ?? '0'),
//                       ),
//                       '/new_job_posted': (context) =>
//                           JobsDetailsScreen(jobId: widget.id ?? '0'),
//                       '/job_update': (context) =>
//                           JobsDetailsScreen(jobId: widget.id ?? '0'),
//                       '/conference_invitation': (context) =>
//                           ConferencesScreen(),
//                       '/new_discuss_case': (context) =>
//                           const DiscussionListScreen(),
//                       '/discuss_case_comment': (context) =>
//                           const DiscussionListScreen(),
//                       '/job_post_notification': (context) =>
//                           JobsDetailsScreen(jobId: widget.id ?? '0'),
//                     },

//                     debugShowCheckedModeBanner: false,
//                     scrollBehavior: SBehavior(),
//                     themeAnimationDuration: const Duration(microseconds: 500),
//                     theme: AppTheme.lightTheme,
//                     darkTheme: AppTheme.darkTheme,
//                     themeMode: appStore.isDarkMode
//                         ? ThemeMode.dark
//                         : ThemeMode.light,
//                     builder: (context, child) {
//                       return SimpleFixedMediaQuery.wrap(
//                         context: context,
//                         child: child!,
//                       );
//                     },
//                     localizationsDelegates:
//                         AppLocalizations.localizationsDelegates,
//                     supportedLocales: AppLocalizations.supportedLocales,
//                     locale: _locale,
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }

//   // Helper method to safely extract call arguments
//   Map<String, dynamic> _extractCallArguments(dynamic arguments) {
//     try {
//       if (arguments is Map<String, dynamic>) {
//         return arguments;
//       } else if (arguments is Map) {
//         final Map<String, dynamic> args = {};
//         arguments.forEach((key, value) {
//           if (key is String) {
//             args[key] = value;
//           }
//         });
//         return args;
//       } else if (arguments is String) {
//         return {'callId': arguments};
//       } else {
//         return {'callId': arguments?.toString() ?? ''};
//       }
//     } catch (e) {
//       debugPrint('Error extracting call arguments: $e');
//       return {'callId': ''};
//     }
//   }
// }
import 'dart:async';
import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/case_discussion/screens/discussion_list_screen.dart';
import 'package:doctak_app/presentation/NoInternetScreen.dart';
import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
import 'package:doctak_app/presentation/calling_module/services/agora_service.dart';
import 'package:doctak_app/presentation/calling_module/services/call_service.dart';

// import 'presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/calling_module/services/callkit_service.dart';
import 'package:doctak_app/presentation/case_discussion/bloc/create_discussion_bloc.dart';
import 'package:doctak_app/presentation/case_discussion/bloc/discussion_detail_bloc.dart';
import 'package:doctak_app/presentation/case_discussion/bloc/discussion_list_bloc.dart';
import 'package:doctak_app/presentation/case_discussion/repository/case_discussion_repository.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
import 'package:doctak_app/presentation/coming_soon_screen/coming_soon_screen.dart';
import 'package:doctak_app/presentation/doctak_ai_module/blocs/ai_chat/ai_chat_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/bloc/conference_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/news_screen/bloc/news_bloc.dart';
import 'package:doctak_app/presentation/home_screen/store/AppStore.dart';
import 'package:doctak_app/presentation/home_screen/utils/AppTheme.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/unified_splash_upgrade_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctak_app/l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import hive_flutter package
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'ads_setting/ad_setting.dart';
import 'core/app_export.dart';
import 'core/network/my_https_override.dart';
import 'core/notification_service.dart';
import 'core/utils/common_navigator.dart';
import 'core/utils/deep_link_service.dart';
import 'core/utils/get_shared_value.dart';
import 'core/utils/pusher_service.dart';
import 'core/utils/text_scale_helper.dart';
import 'core/utils/simple_fixed_media_query.dart';
import 'core/utils/fixed_sizer.dart';
import 'core/utils/edge_to_edge_helper.dart';
import 'firebase_options.dart';
import 'widgets/fixed_scale_material_app.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Removed path_provider import - using direct paths to avoid Pigeon channel issues in release mode

/// Waits for native plugin channels to be ready.
/// In release mode, there can be a race condition where Dart code starts
/// executing before native plugin channels are fully established.
Future<void> _waitForPluginChannels() async {
  debugPrint('Waiting for plugin channels...');
  // Give a longer delay in release mode for plugins to initialize
  // This is a workaround for Pigeon-based plugins like path_provider
  if (kReleaseMode) {
    await Future.delayed(const Duration(milliseconds: 500));
  } else {
    await Future.delayed(const Duration(milliseconds: 100));
  }
  debugPrint('Plugin channel wait complete');
}

// Global service instances that persist throughout app lifecycle
final CallService globalCallService = CallService();
final CallKitService callKitService = CallKitService();

// Store instance
AppStore appStore = AppStore();
var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Flag to indicate if we're handling a call at app startup
bool isHandlingCallAtStartup = false;

// Toggle for Crashlytics
const _kShouldTestAsyncErrorOnInit = false;
bool isCurrentlyOnNoInternet = false;
const _kTestingCrashlytics = true;

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey(
  debugLabel: 'Main Navigator',
);
var calllRoute;

@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(
  NotificationResponse notificationResponse,
) async {
  final String? payload = notificationResponse.payload;
  if (notificationResponse.payload != null) {
    debugPrint('notification payload: $payload');
  }
  NavigatorService.navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (context) => const ComingSoonScreen()),
  );
}

void checkNotificationPermission() async {
  var status = await Permission.notification.status;

  if (status.isDenied) {
    // Request permission if it's denied
    await Permission.notification.request();
  }
}

// Shorebird update check function (commented out due to import issues)
// Future<void> _checkForShorebirdUpdates() async {
//   try {
//     debugPrint('Checking for Shorebird updates...');
//
//     // Initialize Shorebird
//     final shorebirdCodePush = ShorebirdCodePush();
//
//     // Check if updates are available
//     final isUpdateAvailable = await shorebirdCodePush
//         .isNewPatchAvailableForDownload();
//
//     if (isUpdateAvailable) {
//       debugPrint('Shorebird update available, downloading...');
//
//       // Download the update
//       await shorebirdCodePush.downloadUpdateIfAvailable();
//       debugPrint('Shorebird update downloaded successfully');
//
//       // Check if the update is ready to install
//       final isUpdateReadyToInstall = await shorebirdCodePush
//           .isNewPatchReadyToInstall();
//
//       if (isUpdateReadyToInstall) {
//         debugPrint('Shorebird update ready to install on next restart');
//       }
//     } else {
//       debugPrint('No Shorebird updates available');
//     }
//   } catch (e) {
//     debugPrint('Error checking for Shorebird updates: $e');
//   }
// }

// Helper function to get base URL from preferences
Future<String> _getBaseUrlFromPrefs() async {
  try {
    final prefs = await getSharedPreferencesWithRetry();
    return await prefs.getString('api_base_url') ?? AppData.remoteUrl3;
  } catch (e) {
    debugPrint('Error getting base URL from prefs: $e');
    return AppData.remoteUrl3;
  }
}

Future<String> getToken() async {
  try {
    final prefs = await getSharedPreferencesWithRetry();
    return await prefs.getString('token') ?? '';
  } catch (e) {
    debugPrint('Error getting token from prefs: $e');
    return AppData.userToken ?? "";
  }
}

// Clean up any stale call data
Future<void> _cleanupStaleCallData() async {
  try {
    final prefs = await getSharedPreferencesWithRetry();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if there's call data that might be stale
    final savedCallId = await prefs.getString('active_call_id');
    final pendingCallId = await prefs.getString('pending_call_id');

    // Clean up active call data if it's too old
    if (savedCallId != null) {
      final savedTimestamp = await prefs.getInt('active_call_timestamp') ?? 0;
      if (now - savedTimestamp > 60000) {
        // 60 seconds
        debugPrint('Found stale active call data, cleaning up');
        await prefs.remove('active_call_id');
        await prefs.remove('active_call_user_id');
        await prefs.remove('active_call_name');
        await prefs.remove('active_call_avatar');
        await prefs.remove('active_call_has_video');
        await prefs.remove('active_call_timestamp');
      }
    }

    // Clean up pending call data if it's too old
    if (pendingCallId != null) {
      final pendingTimestamp =
          await prefs.getInt('pending_call_timestamp') ?? 0;
      if (now - pendingTimestamp > 30000) {
        // 30 seconds
        debugPrint('Found stale pending call data, cleaning up');
        await prefs.remove('pending_call_id');
        await prefs.remove('pending_call_timestamp');
        await prefs.remove('pending_caller_id');
        await prefs.remove('pending_caller_name');
        await prefs.remove('pending_caller_avatar');
        await prefs.remove('pending_call_has_video');
      }
    }
  } catch (e) {
    debugPrint('Error cleaning up stale call data: $e');
  }
}

// Check if there's an active call that should be prioritized
Future<bool> _isActiveCallPending() async {
  debugPrint('Checking for active calls...');
  try {
    // First check for active calls in CallKit
    final activeCalls = await callKitService.getActiveCalls();
    if (activeCalls.isNotEmpty) {
      final call = activeCalls.first;
      final callId = call['id']?.toString() ?? '';

      // Verify call is recent
      final prefs = await getSharedPreferencesWithRetry();
      final timestamp = await prefs.getInt('active_call_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Only consider calls within the last 30 seconds
      if (now - timestamp < 30000) {
        debugPrint('Found active recent call in CallKit: $callId');
        return true;
      }

      debugPrint(
        'Found call in CallKit but it appears stale, clearing: $callId',
      );
      await callKitService.endCall(callId);
    }

    // Check for pending call info from preferences
    final prefs = await getSharedPreferencesWithRetry();

    // First check for pending calls from notifications
    final pendingCallId = await prefs.getString('pending_call_id');
    if (pendingCallId != null) {
      final pendingTimestamp =
          await prefs.getInt('pending_call_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Only consider pending calls within the last 15 seconds
      if (now - pendingTimestamp < 15000) {
        debugPrint('Found pending call from notification: $pendingCallId');
        return true;
      }
    }

    // Then check for active calls from saved state
    final savedCallId = await prefs.getString('active_call_id');
    if (savedCallId != null) {
      final savedTimestamp = await prefs.getInt('active_call_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Only consider saved calls within the last 30 seconds
      if (now - savedTimestamp < 30000) {
        debugPrint('Found recent saved call info: $savedCallId');
        return true;
      }
    }

    return false;
  } catch (e) {
    debugPrint('Error checking for active call: $e');
    return false;
  }
}

/// Entry point for Picture-in-Picture mode
/// This is called when PiP creates a new engine for the floating window
@pragma('vm:entry-point')
void pipMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PiPCallWidget());
}

/// Widget displayed in Picture-in-Picture mode during calls
/// This creates a compact floating window UI that shows during active calls
class PiPCallWidget extends StatelessWidget {
  const PiPCallWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF2D2D44), const Color(0xFF1E1E2E)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated call indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: Colors.green,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                // Call status text
                const Text(
                  'Call in Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // Tap to return hint
                Text(
                  'Tap to return',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('=== DOCTAK APP STARTING ===');

  // Variables to track initialization state
  bool firebaseInitialized = false;
  RemoteMessage? initialRoute;
  bool isHandlingCallAtStartup = false;
  String baseUrl = AppData.remoteUrl3;

  // Wrap ALL initialization in try-catch to ensure runApp is always called
  try {
    debugPrint('Step 1: Waiting for plugin channels...');
    // CRITICAL: In release mode, native plugin channels may not be ready immediately
    // after WidgetsFlutterBinding.ensureInitialized(). We need to wait for them.
    // This is especially important for Pigeon-based plugins like path_provider.
    await _waitForPluginChannels();
    debugPrint('Step 1: Plugin channels ready');

    debugPrint('Step 2: Initializing Hive...');
    // WORKAROUND: path_provider has a known race condition in release mode
    // where the Pigeon channel isn't ready. We use platform-specific paths directly.
    // Since Hive is only used for basic caching and not critical data,
    // we can skip initialization if it fails.
    bool hiveInitialized = false;

    try {
      String hivePath;
      if (Platform.isAndroid) {
        // Android: Use the known data directory path directly
        // This bypasses the path_provider plugin entirely
        // The package name is com.kt.doctak from AndroidManifest.xml
        hivePath = '/data/data/com.kt.doctak/app_flutter';
        debugPrint('Using hardcoded Android path: $hivePath');

        // Ensure directory exists
        try {
          final dir = Directory(hivePath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
        } catch (e) {
          debugPrint('Could not create Hive directory: $e');
        }
      } else if (Platform.isIOS) {
        // iOS: Use NSDocumentDirectory path pattern
        // This is typically ~/Documents for the app sandbox
        final home = Platform.environment['HOME'] ?? '';
        hivePath = '$home/Documents';
        debugPrint('Using iOS path: $hivePath');
      } else {
        // Other platforms - use a relative path as fallback
        hivePath = '.';
      }

      Hive.init(hivePath);
      debugPrint('Hive initialized successfully with path: $hivePath');
      hiveInitialized = true;
    } catch (e) {
      debugPrint('Hive initialization failed: $e');
      // App can still run without Hive for basic functionality
      // Hive is not critical for the app to function
    }

    // Mark hiveInitialized as used to suppress warning
    debugPrint('Hive initialized: $hiveInitialized');

    // Override HTTP client
    HttpOverrides.global = MyHttpsOverrides();

    debugPrint('Starting app initialization...');

    // Initialize Shorebird for over-the-air updates (commented out due to import issues)
    // try {
    //   // Check for updates in the background
    //   _checkForShorebirdUpdates();
    // } catch (e) {
    //   debugPrint('Shorebird initialization failed: $e');
    // }

    // Initialize Firebase FIRST, before any Firebase-dependent services
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseInitialized = true;
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      // Try to continue - some features may not work but app should still launch
    }

    // Initialize other services
    try {
      await initializeAsync();
      debugPrint('initializeAsync completed');
    } catch (e) {
      debugPrint('Error in initializeAsync: $e');
      // Continue even if this fails
    }

    // Initialize image cache manager
    try {
      // PostImageCacheManager.initMemoryPressureListener();
      // Pre-create cache instance
      // PostImageCacheManager.instance;
      debugPrint('PostImageCacheManager initialized');
    } catch (e) {
      debugPrint('Error initializing PostImageCacheManager: $e');
    }

    baseUrl = await _getBaseUrlFromPrefs();
    try {
      // Step 1: Initialize CallKit service FIRST - highest priority
      debugPrint('Initializing CallKitService...');
      await callKitService.initialize(
        baseUrl: baseUrl,
        shouldUpdateStatus: false, // Let CallService handle status updates
      );
      debugPrint('CallKitService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CallKitService, continuing: $e');
      // Continue even if this fails as CallService will retry
    }

    // Set up Crashlytics ONLY if Firebase initialized successfully
    if (firebaseInitialized) {
      try {
        const fatalError = true;
        FlutterError.onError = (errorDetails) {
          try {
            if (fatalError) {
              FirebaseCrashlytics.instance.recordFlutterFatalError(
                errorDetails,
              );
            } else {
              FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
            }
          } catch (e) {
            debugPrint('Error recording Flutter error: $e');
          }
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          try {
            if (fatalError) {
              FirebaseCrashlytics.instance.recordError(
                error,
                stack,
                fatal: true,
              );
            } else {
              FirebaseCrashlytics.instance.recordError(error, stack);
            }
          } catch (e) {
            debugPrint('Error recording platform error: $e');
          }
          return true;
        };
        debugPrint('Firebase Crashlytics configured');
      } catch (e) {
        debugPrint('Firebase Crashlytics setup error: $e');
        // Continue without crashlytics
      }
    } else {
      debugPrint('Skipping Crashlytics setup - Firebase not initialized');
    }

    // IMPORTANT: Clean up any stale call data BEFORE checking for active calls
    await _cleanupStaleCallData();
    debugPrint('Stale call data cleaned up');

    // Load the base URL from preferences or use default
    debugPrint('Using API base URL: $baseUrl');

    // Create CallKitService instance first - no async await here
    // This is crucial to avoid the LateInitializationError
    try {
      // Step 1: Initialize CallKit service FIRST - highest priority
      debugPrint('Initializing CallKitService...');
      await callKitService.initialize(
        baseUrl: baseUrl,
        shouldUpdateStatus: false, // Let CallService handle status updates
      );
      debugPrint('CallKitService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CallKitService, continuing: $e');
      // Continue even if this fails as CallService will retry
    }

    // Initialize notification service AFTER Firebase and CallKit are initialized
    try {
      await NotificationService.initialize();
      debugPrint('Notification service initialized');
    } catch (e) {
      debugPrint('Error initializing NotificationService, continuing: $e');
      // Continue even if this fails as it's not critical for call handling
    }

    // Get initial notification if app was opened from a notification
    try {
      initialRoute = await NotificationService.getInitialNotificationRoute();
      debugPrint('Initial route: ${initialRoute?.data}');
    } catch (e) {
      debugPrint('Error getting initial notification route: $e');
      // Continue without initial route
    }

    // Check if app was launched from a call notification
    bool isFromCallNotification = false;
    if (initialRoute != null && initialRoute.data['type'] == 'call') {
      isFromCallNotification = true;
      isHandlingCallAtStartup = true;
      debugPrint('App launched from call notification: ${initialRoute.data}');
    } else {
      // Check if there's an active call that should be prioritized
      try {
        isHandlingCallAtStartup = await _isActiveCallPending();
      } catch (e) {
        debugPrint('Error checking for active calls: $e');
        isHandlingCallAtStartup = false;
      }
    }

    // Step 2: Initialize CallService with the same baseUrl
    try {
      debugPrint('Initializing CallService...');
      await globalCallService.initialize(
        baseUrl: baseUrl,
        isFromCallNotification: isFromCallNotification,
      );
      debugPrint('CallService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing CallService, continuing: $e');
      // Continue even if this fails as we already have notification service
    }

    // Set up notification channel for Android
    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );

    // Step 3: Handle incoming call if launched from notification with a small delay
    if (isFromCallNotification && initialRoute != null) {
      // Use a small delay to ensure services are fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      // Extract call information
      final callId = initialRoute.data['call_id'] ?? '';
      final callerName = initialRoute.data['caller_name'] ?? 'Unknown Caller';
      final callerId = initialRoute.data['caller_id'] ?? '';
      final hasVideo = initialRoute.data['is_video_call'] == 'true';
      final avatar = initialRoute.data['caller_avatar'] ?? '';

      debugPrint(
        'Handling incoming call from notification: $callId from $callerName',
      );

      try {
        await globalCallService.handleIncomingCall(
          callId: callId,
          callerName: callerName,
          callerId: callerId,
          callerAvatar: avatar,
          isVideoCall: hasVideo,
        );
      } catch (e) {
        debugPrint('Error handling incoming call at startup: $e');

        // Try again after a longer delay if initial handling fails
        Future.delayed(const Duration(seconds: 1), () {
          try {
            globalCallService.handleIncomingCall(
              callId: callId,
              callerName: callerName,
              callerId: callerId,
              callerAvatar: avatar,
              isVideoCall: hasVideo,
            );
          } catch (e) {
            debugPrint('Second attempt also failed: $e');
          }
        });
      }
    } else if (isHandlingCallAtStartup) {
      // There's an active call to restore
      debugPrint('Resuming active call from startup...');

      // Use a small delay to ensure services are fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      try {
        await callKitService.resumeCallScreenIfNeeded();
      } catch (e) {
        debugPrint('Error resuming call screen: $e');

        // Try again with a longer delay
        Future.delayed(const Duration(seconds: 1), () {
          try {
            callKitService.resumeCallScreenIfNeeded();
          } catch (e) {
            debugPrint('Second attempt to resume call screen failed: $e');
          }
        });
      }
    }

    // Initialize AdMob
    try {
      AdmobSetting.initialization();
    } catch (e) {
      debugPrint('Error initializing AdMob: $e');
    }

    // Load saved theme preference (dark/light mode)
    try {
      await appStore.initialize();
      debugPrint('AppStore initialized with saved theme');
    } catch (e) {
      debugPrint('Error initializing AppStore: $e');
      // Default to light mode if loading fails
      appStore.toggleDarkMode(value: false, save: false);
    }

    // Initialize system settings and start the app
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      debugPrint('System orientation set');
    } catch (e) {
      debugPrint('Error setting orientation: $e');
    }

    // Try to initialize PrefUtils separately
    try {
      await PrefUtils().init();
      debugPrint('PrefUtils initialized');
    } catch (e) {
      debugPrint('PrefUtils initialization error: $e');
      // Continue without PrefUtils - app should still work
    }

    // Configure edge-to-edge display
    try {
      EdgeToEdgeHelper.configureEdgeToEdge();
      debugPrint('Edge-to-edge configured');
    } catch (e) {
      debugPrint('Error configuring edge-to-edge: $e');
    }
    
    // Initialize Deep Link Service
    try {
      await deepLinkService.initialize();
      debugPrint('DeepLinkService initialized');
    } catch (e) {
      debugPrint('Error initializing DeepLinkService: $e');
    }
  } catch (e, stackTrace) {
    // Catch ANY unhandled error during initialization
    debugPrint('CRITICAL: Unhandled error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue to runApp anyway
  }

  // ALWAYS run the app, even if initialization failed
  debugPrint('Launching app UI...');
  runApp(
    MyApp(
      message: initialRoute,
      initialRoute: isHandlingCallAtStartup
          ? 'call'
          : initialRoute?.data['type'] ?? '',
      id: initialRoute?.data['id'] ?? '',
    ),
  );
}

class MyApp extends StatefulWidget {
  final String? initialRoute;
  String? id;
  RemoteMessage? message;

  MyApp({Key? key, this.message, this.initialRoute, this.id}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

List<ConnectivityResult> _connectionStatus = [ConnectivityResult.none];
final Connectivity _connectivity = Connectivity();
late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  FirebaseMessaging? firebaseMessaging;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Locale? _locale;

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Listen for system theme changes and update app theme if following system
    debugPrint('System brightness changed');
    appStore.updateFromSystemTheme();
    super.didChangePlatformBrightness();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state changed to: $state');

    // Flag to identify if navigating back to a call
    bool isReturningToCall = false;

    if (state == AppLifecycleState.resumed) {
      // Check for active calls when app comes to foreground
      if (globalCallService.hasActiveCall) {
        isReturningToCall = true;

        // Verify call is still active
        _verifyAndShowCallScreen();
      } else {
        // Only clear badges if not returning to a call
        NotificationService.clearBadgeCount();
      }
    }

    // Use the global instance to handle lifecycle changes
    globalCallService.handleAppLifecycleState(state);
  }

  /// Verify if we have an active call and show the call screen
  Future<void> _verifyAndShowCallScreen() async {
    try {
      // Check if we have active calls
      final activeCalls = await callKitService.getActiveCalls();

      if (activeCalls.isNotEmpty) {
        final call = activeCalls.first;
        final callId = call['id']?.toString() ?? '';

        // Quick timeout check
        final prefs = await getSharedPreferencesWithRetry();
        final timestamp = await prefs.getInt('active_call_timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (now - timestamp > 60000) {
          // 60 seconds
          // Call is too old, end it
          debugPrint('Call too old, ending: $callId');
          await callKitService.endCall(callId);
          return;
        }

        debugPrint(
          'Found active call, ensuring call screen is displayed: $callId',
        );
        await callKitService.resumeCallScreenIfNeeded();
      }
    } catch (e) {
      debugPrint('Error verifying and showing call screen: $e');
    }
  }

  bool _isRequestingPermission = false;

  Future<void> setFCMSetting() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;

    try {
      // Check if Firebase is initialized before trying to use Firebase Messaging
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase not initialized, skipping FCM setup');
        return;
      }

      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            criticalAlert:
                false, // Use normal notifications that respect device mute
          );
      print('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting FCM permission: $e');
      // Continue without FCM - app should still work
    } finally {
      _isRequestingPermission = false;
    }
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) => {setLocale(locale)});
    NotificationService.clearBadgeCount(); // Clears badge when app resumes
    super.didChangeDependencies();
  }

  late Future<void> _initializeFlutterFireFuture;

  // Define an async function to initialize FlutterFire
  Future<void> _initializeFlutterFire() async {
    try {
      // Check if Firebase is initialized before trying to use Crashlytics
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase not initialized, skipping Crashlytics setup');
        return;
      }

      if (_kTestingCrashlytics) {
        // Force enable crashlytics collection enabled if we're testing it.
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          true,
        );
      } else {
        // Else only enable it in non-debug builds.
        // You could additionally extend this to allow users to opt-in.
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
          !kDebugMode,
        );
      }
      debugPrint('Crashlytics collection settings configured');
    } catch (e) {
      debugPrint('Error initializing FlutterFire crashlytics: $e');
      // Continue without crashlytics
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      // developer.log('Couldn\'t check connectivity status', error: e);
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    setState(() {
      _connectionStatus = result;
    });

    if (_connectionStatus.first == ConnectivityResult.none) {
      isCurrentlyOnNoInternet = true;
      launchScreen(
        NavigatorService.navigatorKey.currentState!.overlay!.context,
        NoInternetScreen(),
      );
    } else {
      if (isCurrentlyOnNoInternet) {
        Navigator.pop(
          NavigatorService.navigatorKey.currentState!.overlay!.context,
        );
        isCurrentlyOnNoInternet = false;
      }
    }

    print('Connectivity changed: $_connectionStatus');
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    // Try to initialize Firebase Messaging only if Firebase is initialized
    try {
      if (Firebase.apps.isNotEmpty) {
        firebaseMessaging = FirebaseMessaging.instance;
        debugPrint('Firebase Messaging initialized');
      } else {
        debugPrint('Firebase not initialized, skipping Firebase Messaging');
      }
    } catch (e) {
      debugPrint('Error initializing FirebaseMessaging: $e');
      // Continue without firebase messaging
    }

    initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
    NotificationService.clearBadgeCount(); // Clears badge when app resumes
    setFCMSetting();
    // setToken();
    _initializeFlutterFireFuture = _initializeFlutterFire();

    // Check if we're handling a call at startup and setup appropriate callbacks
    if (isHandlingCallAtStartup) {
      print('App started with active call, setting up call screen priority');
      // Delay app main flow if we're handling a call
      Future.delayed(const Duration(milliseconds: 500), () {
        // Check if any calls are active at this point
        callKitService.getActiveCalls().then((activeCalls) {
          if (activeCalls.isNotEmpty) {
            print('Ensuring call screen remains visible');
            callKitService.resumeCallScreenIfNeeded();
          }
        });
      });
    }
    
    // Initialize deep link listener for when app is running
    _initDeepLinkListener();

    super.initState();
  }
  
  /// Initialize listener for deep links when app is running
  void _initDeepLinkListener() {
    deepLinkService.listenForLinks((uri) {
      debugPrint('🔗 MyApp: Deep link received: $uri');
      final context = NavigatorService.navigatorKey.currentState?.context;
      if (context != null) {
        final deepLinkData = deepLinkService.parseDeepLink(uri);
        deepLinkService.handleDeepLink(context, deepLinkData);
      }
    });
  }

  Map<String, dynamic> userMap = {};

  @override
  Widget build(BuildContext context) {
    return FixedSizer(
      child: MultiBlocProvider(
        providers: [
          // ChangeNotifierProvider(create: (_) => ConnectivityService()),
          BlocProvider(create: (context) => LoginBloc()),
          Provider<AgoraService>(
            create: (_) => AgoraService(),
            dispose: (_, service) => service.release(),
          ),

          // ChangeNotifierProvider(create: (_) => PusherProvider()),
          ///
          ///
          BlocProvider<AiChatBloc>(create: (context) => AiChatBloc()),
          // BlocProvider(create: (context) => DropdownBloc()),
          BlocProvider(
            create: (context) => DiscussionDetailBloc(
              repository: CaseDiscussionRepository(
                baseUrl: AppData.base2,
                getAuthToken: () {
                  return AppData.userToken ?? "";
                },
              ),
            ),
          ),
          BlocProvider(
            create: (context) => CreateDiscussionBloc(
              repository: CaseDiscussionRepository(
                baseUrl: AppData.base2,
                getAuthToken: () {
                  return AppData.userToken ?? "";
                },
              ),
            ),
          ),
          BlocProvider(create: (context) => HomeBloc()),
          BlocProvider(create: (context) => DrugsBloc()),
          BlocProvider(create: (context) => SplashBloc()),
          BlocProvider(create: (context) => JobsBloc()),
          BlocProvider(create: (context) => SearchPeopleBloc()),
          BlocProvider(create: (context) => ChatGPTBloc()),
          BlocProvider(create: (context) => ConferenceBloc()),
          BlocProvider(create: (context) => GuidelinesBloc()),
          BlocProvider(create: (context) => AddPostBloc()),
          BlocProvider(create: (context) => ProfileBloc()),
          BlocProvider(create: (context) => ChatBloc()),

          // We're using a global instance, so this is just for UI components that need it
          // It won't be used for app lifecycle events
          ChangeNotifierProvider<CallService>.value(value: globalCallService),
          BlocProvider(
            create: (context) =>
                ThemeBloc(ThemeState(themeType: PrefUtils().getThemeData())),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            return Observer(
              builder: (_) => OverlaySupport.global(
                child: SimpleFixedMediaQuery.wrap(
                  context: context,
                  child: MaterialApp(
                    scaffoldMessengerKey: globalMessengerKey,
                    navigatorKey: NavigatorService.navigatorKey,
                    // If handling a call, use '/call' as our home route, otherwise use the regular route
                    initialRoute: isHandlingCallAtStartup
                        ? '/call'
                        : (widget.initialRoute != null
                              ? '/${widget.initialRoute}'
                              : '/'),

                    // Add onGenerateRoute to better handle deep linking for calls
                    onGenerateRoute: (settings) {
                      print('Generating route for: ${settings.name}');

                      // Handle call routes with special care
                      if (settings.name == '/call') {
                        // When no arguments are provided, get active call info from CallKit
                        if (settings.arguments == null) {
                          // Return a "loading" route that will be replaced with call info
                          return MaterialPageRoute(
                            settings: const RouteSettings(name: '/call'),
                            builder: (context) {
                              // Use a FutureBuilder to get call info and show appropriate screen
                              return FutureBuilder<List<Map<String, dynamic>>>(
                                future: callKitService.getActiveCalls(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    // Show a loading indicator while getting call info
                                    return const Scaffold(
                                      body: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasData &&
                                      snapshot.data!.isNotEmpty) {
                                    // We have active call data, but verify it's still active
                                    final call = snapshot.data!.first;
                                    final callId = call['id']?.toString() ?? '';

                                    // Extract call data carefully - handling type issues
                                    Map<String, dynamic> extra = {};
                                    if (call['extra'] is Map) {
                                      final rawExtra = call['extra'] as Map;
                                      rawExtra.forEach((key, value) {
                                        if (key is String) {
                                          extra[key] = value;
                                        }
                                      });
                                    }

                                    final userId =
                                        extra['userId']?.toString() ?? '';
                                    final name =
                                        call['nameCaller']?.toString() ??
                                        'Unknown';
                                    final avatar =
                                        extra['avatar']?.toString() ?? '';
                                    final hasVideo =
                                        extra['has_video'] == true ||
                                        extra['has_video'] == 'true';

                                    // Navigate to call screen - handle null safety properly
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(
                                              settings: const RouteSettings(
                                                name: '/call',
                                              ),
                                              builder: (context) => CallScreen(
                                                callId: callId,
                                                contactId: userId,
                                                contactName: name,
                                                contactAvatar: avatar,
                                                isIncoming: true,
                                                isVideoCall: hasVideo,
                                                token: '',
                                              ),
                                            ),
                                          );
                                        });

                                    // Return a temporary screen while we check
                                    return const Scaffold(
                                      body: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 16),
                                            Text('Preparing call...'),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  // No active call found, check for pending calls
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) async {
                                    final prefs =
                                        await getSharedPreferencesWithRetry();
                                    final pendingCallId = await prefs.getString(
                                      'pending_call_id',
                                    );

                                    if (pendingCallId != null) {
                                      // Check if the pending call is recent
                                      final pendingTimestamp =
                                          await prefs.getInt(
                                            'pending_call_timestamp',
                                          ) ??
                                          0;
                                      final now =
                                          DateTime.now().millisecondsSinceEpoch;

                                      if (now - pendingTimestamp < 15000) {
                                        // Within 15 seconds
                                        // Extract pending call information
                                        final callerId =
                                            await prefs.getString(
                                              'pending_caller_id',
                                            ) ??
                                            '';
                                        final callerName =
                                            await prefs.getString(
                                              'pending_caller_name',
                                            ) ??
                                            'Unknown';
                                        final avatar =
                                            await prefs.getString(
                                              'pending_caller_avatar',
                                            ) ??
                                            '';
                                        final hasVideo =
                                            await prefs.getBool(
                                              'pending_call_has_video',
                                            ) ??
                                            false;

                                        // Handle the pending call
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            settings: const RouteSettings(
                                              name: '/call',
                                            ),
                                            builder: (context) => CallScreen(
                                              callId: pendingCallId,
                                              contactId: callerId,
                                              contactName: callerName,
                                              contactAvatar: avatar,
                                              isIncoming: true,
                                              isVideoCall: hasVideo,
                                              token: '',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    // If we get here, no call is active, redirect to home
                                    Navigator.of(
                                      context,
                                    ).pushReplacementNamed('/');
                                  });

                                  return const Scaffold(
                                    body: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        }

                        // Handle call with provided arguments
                        final args = _extractCallArguments(settings.arguments);

                        return MaterialPageRoute(
                          settings: RouteSettings(
                            name: '/call',
                          ), // Important for route recognition
                          builder: (context) => CallScreen(
                            callId: args['callId'] ?? '',
                            contactId: args['contactId'] ?? '',
                            contactName: args['contactName'] ?? 'Unknown',
                            contactAvatar: args['contactAvatar'] ?? '',
                            isIncoming: args['isIncoming'] ?? true,
                            isVideoCall: args['isVideoCall'] ?? false,
                            token: args['token'] ?? '',
                          ),
                        );
                      }

                      // Handle message routes
                      if (settings.name == '/message_received') {
                        return MaterialPageRoute(
                          settings: settings,
                          builder: (context) => ChatRoomScreen(
                            id: widget.id.toString(),
                            roomId: '',
                            username: widget.message?.notification?.title ?? "",
                            profilePic:
                                widget.message?.data['image'] ??
                                ''.replaceAll(AppData.imageUrl, ''),
                          ),
                        );
                      }

                      // Let other routes be handled by the routes map
                      return null;
                    },

                    routes: {
                      '/': (context) => UnifiedSplashUpgradeScreen(),

                      // Keep all your existing routes
                      '/follow_request': (context) =>
                          SVProfileFragment(userId: widget.id ?? ''),
                      '/follower_notification': (context) =>
                          SVProfileFragment(userId: widget.id ?? ''),
                      '/un_follower_notification': (context) =>
                          SVProfileFragment(userId: widget.id ?? ''),
                      '/friend_request': (context) =>
                          SVProfileFragment(userId: widget.id ?? ''),
                      '/message_received': (context) => ChatRoomScreen(
                        id: widget.id.toString(),
                        roomId: '',
                        username: widget.message?.notification?.title ?? "",
                        profilePic:
                            widget.message?.data['image'] ??
                            ''.replaceAll(AppData.imageUrl, ''),
                      ),
                      '/comments_on_posts': (context) => PostDetailsScreen(
                        commentId: int.parse(widget.id ?? '0'),
                      ),
                      '/reply_to_comment': (context) => PostDetailsScreen(
                        commentId: int.parse(widget.id ?? '0'),
                      ),
                      '/like_comment_on_post': (context) => PostDetailsScreen(
                        commentId: int.parse(widget.id ?? '0'),
                      ),
                      '/like_comments': (context) => PostDetailsScreen(
                        commentId: int.parse(widget.id ?? '0'),
                      ),
                      '/new_like': (context) => PostDetailsScreen(
                        postId: int.parse(widget.id ?? '0'),
                      ),
                      '/like_on_posts': (context) => PostDetailsScreen(
                        postId: int.parse(widget.id ?? '0'),
                      ),
                      '/new_job_posted': (context) =>
                          JobsDetailsScreen(jobId: widget.id ?? '0'),
                      '/job_update': (context) =>
                          JobsDetailsScreen(jobId: widget.id ?? '0'),
                      '/conference_invitation': (context) =>
                          ConferencesScreen(),
                      '/new_discuss_case': (context) =>
                          const DiscussionListScreen(),
                      '/discuss_case_comment': (context) =>
                          const DiscussionListScreen(),
                      '/job_post_notification': (context) =>
                          JobsDetailsScreen(jobId: widget.id ?? '0'),
                    },

                    debugShowCheckedModeBanner: false,
                    scrollBehavior: SBehavior(),
                    themeAnimationDuration: const Duration(microseconds: 500),
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: appStore.isDarkMode
                        ? ThemeMode.dark
                        : ThemeMode.light,
                    builder: (context, child) {
                      return SimpleFixedMediaQuery.wrap(
                        context: context,
                        child: child!,
                      );
                    },
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    locale: _locale,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method to safely extract call arguments
  Map<String, dynamic> _extractCallArguments(dynamic arguments) {
    try {
      if (arguments is Map<String, dynamic>) {
        return arguments;
      } else if (arguments is Map) {
        final Map<String, dynamic> args = {};
        arguments.forEach((key, value) {
          if (key is String) {
            args[key] = value;
          }
        });
        return args;
      } else if (arguments is String) {
        return {'callId': arguments};
      } else {
        return {'callId': arguments?.toString() ?? ''};
      }
    } catch (e) {
      debugPrint('Error extracting call arguments: $e');
      return {'callId': ''};
    }
  }
}
