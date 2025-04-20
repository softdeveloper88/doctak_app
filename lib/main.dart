import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:doctak_app/meeting_module/bloc/chat/chat_bloc.dart'
as chatbloc2;
import 'package:doctak_app/meeting_module/bloc/meeting/meeting_bloc.dart';
import 'package:doctak_app/meeting_module/bloc/participants/participants_bloc.dart';
import 'package:doctak_app/meeting_module/bloc/settings/settings_bloc.dart';
import 'package:doctak_app/meeting_module/services/agora_service.dart';
import 'package:doctak_app/meeting_module/services/api_service.dart';
import 'package:doctak_app/meeting_module/utils/constants.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/core/utils/force_updrage_page.dart';
import 'package:doctak_app/presentation/NoInternetScreen.dart';
import 'package:doctak_app/presentation/call_module/call_service.dart';
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
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'ads_setting/ad_setting.dart';
import 'core/call_service/callkit_service.dart';
import 'core/network/my_https_override.dart';
import 'core/notification_service.dart';
import 'core/utils/common_navigator.dart';
import 'core/utils/get_shared_value.dart';
import 'core/utils/navigator_service.dart';
import 'core/utils/pref_utils.dart';
import 'firebase_options.dart';
import 'localization/app_localization.dart';
import 'presentation/call_module/ui/call_screen.dart';
import 'presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';

AppStore appStore = AppStore();
var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();
// Toggle this to cause an async error to be thrown during initialization
// and to test that runZonedGuarded() catches the error
const _kShouldTestAsyncErrorOnInit = false;
bool isCurrentlyOnNoInternet = false;
// Toggle this for testing Crashlytics in your app locally.
const _kTestingCrashlytics = true;

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey(debugLabel: 'Main Navigator');
var calllRoute;

// Global instance of CallService to handle lifecycle events without Provider
final CallService globalCallService = CallService();

@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse) async {
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpsOverrides();

  // Initialize Firebase FIRST, before any Firebase-dependent services
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  initializeAsync();

  // Initialize CallKit service to listen for events
  final callKitService = CallKitService();
  callKitService.listenToCallEvents();
  await callKitService.resumeCallScreenIfNeeded();

  // Initialize notification service after Firebase is initialized
  await NotificationService.initialize();

  // Initialize call system
  await globalCallService.initialize(
    baseUrl: 'https://doctak.net/api',authToken:AppData.userToken
    // Replace with your actual API URL
  );

  AdmobSetting.initialization();

  const fatalError = true;
  // Non-async exceptions
  FlutterError.onError = (errorDetails) {
    if (fatalError) {
      // If you want to record a "fatal" exception
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      // ignore: dead_code
    } else {
      // If you want to record a "non-fatal" exception
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    }
  };
  // Async exceptions
  PlatformDispatcher.instance.onError = (error, stack) {
    if (fatalError) {
      // If you want to record a "fatal" exception
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      // ignore: dead_code
    } else {
      // If you want to record a "non-fatal" exception
      FirebaseCrashlytics.instance.recordError(error, stack);
    }
    return true;
  };

  // Get initial notification if app was opened from a notification
  RemoteMessage? initialRoute = await NotificationService.getInitialNotificationRoute();
  print(initialRoute?.data.toString());

  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title // description
    importance: Importance.max,
  );

  appStore.toggleDarkMode(value: false);

  Future.wait([
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]),
    PrefUtils().init()
  ]).then((value) async {
    runApp(MyApp(
        message: initialRoute,
        initialRoute: initialRoute?.data['type'] ?? '',
        id: initialRoute?.data['id'] ?? ''));
  });
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
    print('state change');

    // Use the global instance instead of Provider
    globalCallService.handleAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      NotificationService.clearBadgeCount(); // Clears badge when app resumes
    }
  }

  bool _isRequestingPermission = false;

  Future<void> setFCMSetting() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;

    try {
      NotificationSettings settings =
      await FirebaseMessaging.instance.requestPermission();
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

    // ignore: avoid_print
    // if(_connectionStatus.single==ConnectionState.none) {

    print('Connectivity changed: $_connectionStatus');
    // }
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
            // Provider<CallService>.value(value: globalCallService),
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
                    initialRoute: '/${widget.initialRoute}',

                    // Add or modify the onGenerateRoute method to handle call routes
                    onGenerateRoute: (settings) {
                      if (settings.name == '/call' || settings.name == '/incoming-call') {
                        // Get args (either as Map or as simple String for callId)
                        final args = settings.arguments is Map<String, dynamic>
                            ? settings.arguments as Map<String, dynamic>
                            : {'callId': settings.arguments ?? ''};

                        return MaterialPageRoute(
                          builder: (context) => CallScreen(
                            callId: args['callId'] ?? '',
                            contactId: args['contactId'] ?? '',
                            contactName: args['contactName'] ?? 'Unknown',
                            contactAvatar: args['contactAvatar'] ?? '',
                            isIncoming: args['isIncoming'] ?? true,
                            isVideoCall: args['isVideoCall'] ?? false,
                          ),
                        );
                      }
                      // Let other routes be handled normally
                      return null;
                    },

                    routes: {
                      '/': (context) => ForceUpgradePage(),

                      // Update the audio/video call routes
                      '/audio_call': (context) {
                        final callId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
                        return CallScreen(
                          callId: callId,
                          contactId: '',
                          contactName: '',
                          contactAvatar: '',
                          isIncoming: false,
                          isVideoCall: false,
                        );
                      },

                      '/video_call': (context) {
                        final callId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
                        return CallScreen(
                          callId: callId,
                          contactId: '',
                          contactName: '',
                          contactAvatar: '',
                          isIncoming: false,
                          isVideoCall: true,
                        );
                      },

                      // Keep the existing route for call for backward compatibility
                      '/call': (context) => const CallScreen(
                        callId: '123',
                        contactId: '2222',
                        contactName: 'Hassan',
                        contactAvatar: '',
                        isIncoming: true,
                        isVideoCall: true,
                      ),

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
}