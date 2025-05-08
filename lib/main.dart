import 'dart:async';
import 'dart:io';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/force_updrage_page.dart';
import 'package:doctak_app/presentation/NoInternetScreen.dart';
import 'package:doctak_app/presentation/call_module/call_service.dart';
import 'package:doctak_app/presentation/calling_module/providers/pusher_provider.dart';
import 'package:doctak_app/presentation/calling_module/screens/call_screen.dart';
import 'package:doctak_app/presentation/calling_module/services/agora_service.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
import 'package:doctak_app/presentation/coming_soon_screen/coming_soon_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/home_main_screen/post_details_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/SVProfileFragment.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/case_discussion/case_discussion_screen.dart';
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
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/chat_ui_sceen/chat_room_screen.dart';
import 'package:doctak_app/theme/bloc/theme_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'ads_setting/ad_setting.dart';
import 'core/app_export.dart';
import 'core/network/my_https_override.dart';
import 'core/notification_service.dart';
import 'core/utils/common_navigator.dart';
import 'core/utils/get_shared_value.dart';
import 'core/utils/navigator_service.dart';
import 'core/utils/pref_utils.dart';
import 'core/utils/pusher_service.dart';
import 'firebase_options.dart';
import 'localization/app_localization.dart';
import 'presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';
import 'package:doctak_app/core/call_service/callkit_service.dart';

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
final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: 'Main Navigator');
var calllRoute;

@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
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

// Helper function to get base URL from preferences
Future<String> _getBaseUrlFromPrefs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('api_base_url') ??'https://doctak.net/api/v3';
  } catch (e) {
    debugPrint('Error getting base URL from prefs: $e');
    return AppData.remoteUrl3;
  }
}
Future<String> getToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ??'';
  } catch (e) {
    debugPrint('Error getting base URL from prefs: $e');
    return AppData.userToken??"";
  }
}

// Clean up any stale call data
Future<void> _cleanupStaleCallData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if there's call data that might be stale
    final savedCallId = prefs.getString('active_call_id');
    final pendingCallId = prefs.getString('pending_call_id');

    // Clean up active call data if it's too old
    if (savedCallId != null) {
      final savedTimestamp = prefs.getInt('active_call_timestamp') ?? 0;
      if (now - savedTimestamp > 60000) { // 60 seconds
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
      final pendingTimestamp = prefs.getInt('pending_call_timestamp') ?? 0;
      if (now - pendingTimestamp > 30000) { // 30 seconds
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
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('active_call_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Only consider calls within the last 30 seconds
      if (now - timestamp < 30000) {
        debugPrint('Found active recent call in CallKit: $callId');
        return true;
      }

      debugPrint('Found call in CallKit but it appears stale, clearing: $callId');
      await callKitService.endCall(callId);
    }

    // Check for pending call info from preferences
    final prefs = await SharedPreferences.getInstance();

    // First check for pending calls from notifications
    final pendingCallId = prefs.getString('pending_call_id');
    if (pendingCallId != null) {
      final pendingTimestamp = prefs.getInt('pending_call_timestamp') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Only consider pending calls within the last 15 seconds
      if (now - pendingTimestamp < 15000) {
        debugPrint('Found pending call from notification: $pendingCallId');
        return true;
      }
    }

    // Then check for active calls from saved state
    final savedCallId = prefs.getString('active_call_id');
    if (savedCallId != null) {
      final savedTimestamp = prefs.getInt('active_call_timestamp') ?? 0;
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

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Override HTTP client
  HttpOverrides.global = MyHttpsOverrides();

  debugPrint('Starting app initialization...');

  // Initialize Firebase FIRST, before any Firebase-dependent services
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Firebase initialized');

  // Initialize needed services
  try {
    await initializeAsync();
    AppData.initializePusher();
    await PusherService().initialize();
  } catch (e) {
    debugPrint('Error in initializeAsync: $e');
    // Continue even if this fails, as it shouldn't block call handling
  }


  final baseUrl = await _getBaseUrlFromPrefs();
  try {
    // Step 1: Initialize CallKit service FIRST - highest priority
    debugPrint('Initializing CallKitService...');
    await callKitService.initialize(
        baseUrl: baseUrl,
        shouldUpdateStatus: false // Let CallService handle status updates
    );
    debugPrint('CallKitService initialized successfully');
  } catch (e) {
    debugPrint('Error initializing CallKitService, continuing: $e');
    // Continue even if this fails as CallService will retry
  }
  // Set up Crashlytics before any potential crashes
  const fatalError = true;
  FlutterError.onError = (errorDetails) {
    if (fatalError) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    } else {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (fatalError) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } else {
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
    return true;
  };

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
        shouldUpdateStatus: false // Let CallService handle status updates
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
  RemoteMessage? initialRoute;
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
        isFromCallNotification: isFromCallNotification
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

    debugPrint('Handling incoming call from notification: $callId from $callerName');

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

  // Set app theme
  appStore.toggleDarkMode(value: false);

  // Initialize system settings and start the app
  try {
    await Future.wait([
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]),
      PrefUtils().init()
    ]);
  } catch (e) {
    debugPrint('Error setting system preferences: $e');
    // Initialize PrefUtils separately if Future.wait fails
    await PrefUtils().init();
  }

  // Finally run the app
  runApp(MyApp(
      message: initialRoute,
      initialRoute: isHandlingCallAtStartup ? 'call' : initialRoute?.data['type'] ?? '',
      id: initialRoute?.data['id'] ?? ''
  ));
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
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
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
        final prefs = await SharedPreferences.getInstance();
        final timestamp = prefs.getInt('active_call_timestamp') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        if (now - timestamp > 60000) { // 60 seconds
          // Call is too old, end it
          debugPrint('Call too old, ending: $callId');
          await callKitService.endCall(callId);
          return;
        }

        debugPrint('Found active call, ensuring call screen is displayed: $callId');
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
      NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true, // Important for call notifications
      );
      print('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting permission: $e');
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
    if (_kTestingCrashlytics) {
      // Force enable crashlytics collection enabled if we're testing it.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    } else {
      // Else only enable it in non-debug builds.
      // You could additionally extend this to allow users to opt-in.
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
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
      launchScreen(NavigatorService.navigatorKey.currentState!.overlay!.context,
          NoInternetScreen());
    } else {
      if (isCurrentlyOnNoInternet) {
        Navigator.pop(
            NavigatorService.navigatorKey.currentState!.overlay!.context);
        isCurrentlyOnNoInternet = false;
      }
    }

    print('Connectivity changed: $_connectionStatus');
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
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

    super.initState();
  }

  Map<String, dynamic> userMap = {};

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MultiBlocProvider(
          providers: [
            // ChangeNotifierProvider(create: (_) => ConnectivityService()),
            BlocProvider(create: (context) => LoginBloc()),
            Provider<AgoraService>(
              create: (_) => AgoraService(),
              dispose: (_, service) => service.release(),
            ),
            // ChangeNotifierProvider(create: (_) => PusherProvider()),
            ///
            // BlocProvider(create: (context) => DropdownBloc()),
            BlocProvider(create: (context) => HomeBloc()),
            BlocProvider(create: (context) => DrugsBloc()),
            BlocProvider(create: (context) => SplashBloc()),
            BlocProvider(create: (context) => JobsBloc()),
            BlocProvider(create: (context) => SearchPeopleBloc()),
            BlocProvider(create: (context) => ChatGPTBloc()),
            BlocProvider(create: (context) => ConferenceBloc()),
            BlocProvider(create: (context) => NewsBloc()),
            BlocProvider(create: (context) => GuidelinesBloc()),
            BlocProvider(create: (context) => AddPostBloc()),
            BlocProvider(create: (context) => ProfileBloc()),
            BlocProvider(create: (context) => ChatBloc()),

            // We're using a global instance, so this is just for UI components that need it
            // It won't be used for app lifecycle events
            ChangeNotifierProvider<CallService>.value(value: globalCallService),
            BlocProvider(
                create: (context) => ThemeBloc(
                  ThemeState(
                    themeType: PrefUtils().getThemeData(),
                  ),
                )),
          ],
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return Observer(
                  builder: (_) => MaterialApp(
                    scaffoldMessengerKey: globalMessengerKey,
                    navigatorKey: NavigatorService.navigatorKey,
                    // If handling a call, use '/call' as our home route, otherwise use the regular route
                    initialRoute: isHandlingCallAtStartup ? '/call' : '/${widget.initialRoute}',

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
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    // Show a loading indicator while getting call info
                                    return const Scaffold(
                                      body: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
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

                                    final userId = extra['userId']?.toString() ?? '';
                                    final name = call['nameCaller']?.toString() ?? 'Unknown';
                                    final avatar = extra['avatar']?.toString() ?? '';
                                    final hasVideo = extra['has_video'] == true ||
                                        extra['has_video'] == 'true';

                                    // Navigate to call screen - handle null safety properly
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          settings: const RouteSettings(name: '/call'),
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
                                          mainAxisAlignment: MainAxisAlignment.center,
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
                                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                                    final prefs = await SharedPreferences.getInstance();
                                    final pendingCallId = prefs.getString('pending_call_id');

                                    if (pendingCallId != null) {
                                      // Check if the pending call is recent
                                      final pendingTimestamp = prefs.getInt('pending_call_timestamp') ?? 0;
                                      final now = DateTime.now().millisecondsSinceEpoch;

                                      if (now - pendingTimestamp < 15000) { // Within 15 seconds
                                        // Extract pending call information
                                        final callerId = prefs.getString('pending_caller_id') ?? '';
                                        final callerName = prefs.getString('pending_caller_name') ?? 'Unknown';
                                        final avatar = prefs.getString('pending_caller_avatar') ?? '';
                                        final hasVideo = prefs.getBool('pending_call_has_video') ?? false;

                                        // Handle the pending call
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            settings: const RouteSettings(name: '/call'),
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
                                    Navigator.of(context).pushReplacementNamed('/');
                                  });

                                  return const Scaffold(
                                    body: Center(child: CircularProgressIndicator()),
                                  );
                                },
                              );
                            },
                          );
                        }

                        // Handle call with provided arguments
                        final args = _extractCallArguments(settings.arguments);

                        return MaterialPageRoute(
                          settings: RouteSettings(name: '/call'), // Important for route recognition
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
                            profilePic: widget.message?.data['image'] ?? ''
                                .replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', ''),
                          ),
                        );
                      }

                      // Let other routes be handled by the routes map
                      return null;
                    },

                    routes: {
                      '/': (context) => ForceUpgradePage(),

                      // Keep all your existing routes
                      '/follow_request': (context) => SVProfileFragment(
                        userId: widget.id ?? '',
                      ),
                      '/follower_notification': (context) =>
                          SVProfileFragment(
                            userId: widget.id ?? '',
                          ),
                      '/un_follower_notification': (context) =>
                          SVProfileFragment(
                            userId: widget.id ?? '',
                          ),
                      '/friend_request': (context) => SVProfileFragment(
                        userId: widget.id ?? '',
                      ),
                      '/message_received': (context) => ChatRoomScreen(
                        id: widget.id.toString(),
                        roomId: '',
                        username:
                        widget.message?.notification?.title ?? "",
                        profilePic: widget.message?.data['image'] ??
                            ''.replaceAll(
                                'https://doctak-file.s3.ap-south-1.amazonaws.com/',
                                ''),
                      ),
                      '/comments_on_posts': (context) => PostDetailsScreen(
                        commentId: int.parse(widget.id ?? '0'),
                      ),
                      '/reply_to_comment': (context) => PostDetailsScreen(
                        commentId: int.parse(widget.id ?? '0'),
                      ),
                      '/like_comment_on_post': (context) =>
                          PostDetailsScreen(
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
                      '/new_job_posted': (context) => JobsDetailsScreen(
                        jobId: widget.id ?? '0',
                      ),
                      '/job_update': (context) => JobsDetailsScreen(
                        jobId: widget.id ?? '0',
                      ),
                      '/conference_invitation': (context) =>
                          ConferencesScreen(),
                      '/new_discuss_case': (context) =>
                      const CaseDiscussionScreen(),
                      '/discuss_case_comment': (context) =>
                      const CaseDiscussionScreen(),
                      '/job_post_notification': (context) =>
                          JobsDetailsScreen(
                            jobId: widget.id ?? '0',
                          ),
                    },

                    debugShowCheckedModeBanner: false,
                    scrollBehavior: SBehavior(),
                    themeAnimationDuration: const Duration(microseconds: 500),
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: appStore.isDarkMode
                        ? ThemeMode.dark
                        : ThemeMode.light,
                    localizationsDelegates:
                    AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    locale: _locale,
                  ));
            },
          ),
        );
      },
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