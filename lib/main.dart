import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/utils/force_updrage_page.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import 'core/network/my_https_override.dart';
import 'core/notification_service.dart';
import 'core/utils/get_shared_value.dart';
import 'core/utils/navigator_service.dart';
import 'core/utils/pref_utils.dart';
import 'firebase_options.dart';
import 'localization/app_localization.dart';
import 'presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';

AppStore appStore = AppStore();
var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();
// Toggle this to cause an async error to be thrown during initialization
// and to test that runZonedGuarded() catches the error
const _kShouldTestAsyncErrorOnInit = false;

// Toggle this for testing Crashlytics in your app locally.
const _kTestingCrashlytics = true;
/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey(debugLabel: 'Main Navigator');

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
  initializeAsync();
  // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  //   systemNavigationBarColor: Colors.white, // navigation bar color
  //   statusBarColor: Colors.white, // status bar color
  // ));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // if (Platform.isAndroid) {
  //   await Firebase.initializeApp(
  //     options: const FirebaseOptions(
  //       apiKey: 'AIzaSyDERo2-Nyit1b3UTqWWKNUutkALGBauxuc',
  //       appId: "1:975716064608:android:c1a4889c2863e014749205",
  //       messagingSenderId: "975716064608",
  //       projectId: "doctak-322cc",
  //     ),
  //   );
  // } else {
  //   await Firebase.initializeApp();
  //   // await Firebase.initializeApp();
  // }
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
  checkNotificationPermission();
  NotificationService.initialize();
  RemoteMessage? initialRoute =
      await NotificationService.getInitialNotificationRoute();
  print(initialRoute?.data.toString());
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title // description
    importance: Importance.max,
  );
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();
  // const AndroidInitializationSettings initializationSettingsAndroid =
  //     AndroidInitializationSettings('ic_stat_name');
  // const InitializationSettings initializationSettings =
  //     InitializationSettings(android: initializationSettingsAndroid);
  // await flutterLocalNotificationsPlugin.initialize(initializationSettings,
  //     onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  // // flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // FirebaseMessaging.onBackgroundMessage(_throwGetMessage);
  //   //App is in the foreground
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  //     debugPrint('Got a message, app is in the foreground!');
  //     debugPrint('Message data: $message');
  //     await showNotificationWithCustomIcon(message.notification,message.notification?.title??'', message.notification!.body.toString(),message.data['image'],message.data['banner']);
  //     // showNotification(message.data);
  //     // final ByteArrayAndroidBitmap largeIcon = await _getImageFromUrl('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTQzCFZPz1Er-39Wvzvn5QBEMy9JSP6vGl2Xg&s');
  //     // RemoteNotification? notification = message.notification;
  //     // AndroidNotification? android = message.notification?.android;
  //     // if (notification != null && android != null) {
  //     //   flutterLocalNotificationsPlugin.show(
  //     //       notification.hashCode,
  //     //       notification.title,
  //     //       notification.body,
  //     //       NotificationDetails(
  //     //         android: AndroidNotificationDetails(
  //     //           channel.id,
  //     //           channel.name,
  //     //           largeIcon: largeIcon,
  //     //           styleInformation: BigPictureStyleInformation(
  //     //             largeIcon,
  //     //             contentTitle: notification.title,
  //     //             summaryText: notification.body,
  //     //           ),
  //     //           icon: 'ic_stat_name',
  //     //         ),
  //     //       ));
  //     // }
  //     if (message.notification != null) {
  //       if (kDebugMode) {
  //         print(
  //             'Message also contained a notification: ${message.notification}');
  //       }
  //     }
  //   });
  //
  //   await flutterLocalNotificationsPlugin
  //       .resolvePlatformSpecificImplementation<
  //           AndroidFlutterLocalNotificationsPlugin>()
  //       ?.createNotificationChannel(channel);
  //   await FirebaseMessaging.instance
  //       .setForegroundNotificationPresentationOptions(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   )
  //       .then((value) {
  //     debugPrint('value:print');
  //   });
  // }
  // Get the notification payload if the app was terminated
  // Initialize the notification service
  // Get the initial notification data if the app was launched from a terminated state by tapping a notification

  // Use the notification data (payload or route) to navigate to a specific screen

  appStore.toggleDarkMode(value: false);

  Future.wait([
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]),
    PrefUtils().init()
  ]).then((value) {
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
  MyApp({Key? key,this.message, this.initialRoute, this.id}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Locale? _locale;

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
        NotificationService.clearBadgeCount(); // Clears badge when app resumes

    });
  }

  // final _navigatorKey = GlobalKey<NavigatorState>();
  void setFCMSetting() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('User granted provisional permission');
      }
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    )
        .then((value) {
      if (kDebugMode) {
        print('value:print');
      }
    });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) => {setLocale(locale)});

    super.didChangeDependencies();
  }

  // Future<bool> sendFcmMessage(
  //     String title, String message, String token) async {
  //   try {
  //     var url = 'https://fcm.googleapis.com/fcm/send';
  //     var header = {
  //       'Content-Type': 'application/json',
  //       'Authorization':
  //           'Bearer AAAA4y01nWA:APA91bEcfbKn4ZZ-1WPyK4FFepBC4_PWOthWPwz5yoK7b2rcftt2O9_xy5tOaeoeceVaPR5eY7Y6cX_YtIBq7WL11NN8dB3mtpQ8Tq-cNYf8x_FfyG_Hpps6wsMeY1btHcdUqaWEByTd',
  //     };
  //     var request = {
  //       'registration_ids': [token],
  //       'priority': 'high',
  //       'important': 'max',
  //       'notification': {'body': message, 'title': title}
  //     };
  //     var response = await http.post(Uri.parse(url),
  //         headers: header, body: json.encode(request));
  //     if (kDebugMode) {
  //       print(response.body);
  //     }
  //     return true;
  //   } catch (e) {
  //     print(e);
  //     return false;
  //   }
  // }
  // setToken() async {
  //   await FirebaseMessaging.instance.getToken().then((token) async {
  //     log('token ${token}');
  //   });
  //   var tp = await FirebaseMessaging.instance.getAPNSToken();
  //   print(tp);
  // }
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
  @override
  void initState() {
    NotificationService.clearBadgeCount(); // Clears badge when app resumes
    setFCMSetting();
    // setToken();
    _initializeFlutterFireFuture = _initializeFlutterFire();
    super.initState();
  }

  //   setToken();
  //   FirebaseMessaging.instance
  //       .getInitialMessage()
  //       .then((RemoteMessage? message) {
  //       print('message test $message');
  //     if (message != null) {
  //       FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
  //         NavigatorService.navigatorKey.currentState?.push(
  //           MaterialPageRoute(builder: (context) => ComingSoonScreen()),
  //         );
  //         await showNotificationWithCustomIcon(
  //             message.notification,
  //             message.notification?.title ?? '',
  //             message.notification!.body.toString(),
  //             message.data['image']??'',
  //             message.data['banner']??'');
  //         // final ByteArrayAndroidBitmap largeIcon = await _getImageFromUrl('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTQzCFZPz1Er-39Wvzvn5QBEMy9JSP6vGl2Xg&s');
  //         //
  //         // RemoteNotification? notification = message.notification;
  //         // AndroidNotification? android = message.notification?.android;
  //         // if (notification != null && android != null) {
  //         //   flutterLocalNotificationsPlugin.show(
  //         //       notification.hashCode,
  //         //       notification.title,
  //         //       notification.body,
  //         //       NotificationDetails(
  //         //
  //         //         android: AndroidNotificationDetails(
  //         //           color: Colors.transparent,
  //         //           largeIcon: largeIcon,
  //         //           styleInformation: BigPictureStyleInformation(
  //         //             largeIcon,
  //         //             contentTitle: notification.title,
  //         //             summaryText: notification.body,
  //         //           ),
  //         //           channel.id,
  //         //           channel.name,
  //         //
  //         //           icon: 'ic_stat_name',
  //         //         ),
  //         //       ));
  //         // }
  //         // if(user_type.$=="customer") {
  //         //   await navigatorKey.currentState!.push(
  //         //       MaterialPageRoute(builder: (_) =>
  //         //           NotificationsScreen(isWorkshop:false
  //         //           ))
  //         //   );
  //         // }else{
  //         //   await navigatorKey.currentState!.push(
  //         //       MaterialPageRoute(builder: (_) =>
  //         //           NotificationsScreen(isWorkshop: true
  //         //           ))
  //         //   );
  //         // }
  //       });
  //     }
  //   });
  //   // 2. This method only call when App in forground it mean app must be opened
  //   FirebaseMessaging.onMessage.listen(
  //     (message) async {
  //       if (kDebugMode) {
  //         print('FirebaseMessaging.onMessage.listen');
  //       }
  //       if (message.notification != null) {
  //         if (kDebugMode) {
  //           print(message.notification!.title);
  //         }
  //         if (kDebugMode) {
  //           print(message.notification!.body);
  //         }
  //         if (kDebugMode) {
  //           print('message.data11 ${message.data}');
  //         }
  //         // showNotification(message.data);
  //         // final ByteArrayAndroidBitmap largeIcon = await _getImageFromUrl('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTQzCFZPz1Er-39Wvzvn5QBEMy9JSP6vGl2Xg&s');
  //
  //         RemoteNotification? notification = message.notification;
  //         AndroidNotification? android = message.notification?.android;
  //         // print(message.data);
  //         NavigatorService.navigatorKey.currentState?.push(
  //           MaterialPageRoute(builder: (context) => ComingSoonScreen()),
  //         );
  //         await showNotificationWithCustomIcon(
  //             message.notification,
  //             message.notification?.title ?? '',
  //             message.notification!.body.toString(),
  //             message.data['image']??'',
  //             message.data['banner']??'');
  //
  //         // if (notification != null && android != null) {
  //         //   flutterLocalNotificationsPlugin.show(
  //         //       notification.hashCode,
  //         //       notification.title,
  //         //       notification.body,
  //         //       NotificationDetails(
  //         //         android: AndroidNotificationDetails(
  //         //           channel.id,
  //         //           channel.name,
  //         //           largeIcon: largeIcon,
  //         //           styleInformation: BigPictureStyleInformation(
  //         //             largeIcon,
  //         //             contentTitle: notification.title,
  //         //             summaryText: notification.body,
  //         //           ),
  //         //           icon: 'ic_stat_name',
  //         //         ),
  //         //       ));
  //         // }
  //         // if(user_type.$=="customer") {
  //         //   await navigatorKey.currentState!.push(
  //         //       MaterialPageRoute(builder: (_) =>
  //         //           NotificationsScreen(isWorkshop:false
  //         //           ))
  //         //   );
  //         // }else{
  //         //   await navigatorKey.currentState!.push(
  //         //       MaterialPageRoute(builder: (_) =>
  //         //           NotificationsScreen(isWorkshop: true
  //         //           ))
  //         //   );
  //         // }
  //       }
  //     },
  //   );
  //   // 3. This method only call when App in background and not terminated(not closed)
  //   FirebaseMessaging.onMessageOpenedApp.listen(
  //     (message) async {
  //       print('FirebaseMessaging.onMessageOpenedApp.listen');
  //       if (message.notification != null) {
  //         RemoteNotification? notification = message.notification;
  //         AndroidNotification? android = message.notification?.android;
  //         await showNotificationWithCustomIcon(
  //             message.notification,
  //             message.notification?.title ?? '',
  //             message.notification!.body.toString(),
  //             message.data['image']??'',
  //             message.data['banner']??'');
  //         // final ByteArrayAndroidBitmap largeIcon = await _getImageFromUrl('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTQzCFZPz1Er-39Wvzvn5QBEMy9JSP6vGl2Xg&s');
  //         //
  //         // if (notification != null && android != null) {
  //         //   flutterLocalNotificationsPlugin.show(
  //         //       notification.hashCode,
  //         //       notification.title,
  //         //       notification.body,
  //         //
  //         //       NotificationDetails(
  //         //         android: AndroidNotificationDetails(
  //         //           channel.id,
  //         //           channel.name,
  //         //           icon: 'ic_stat_name',
  //         //           largeIcon: largeIcon,
  //         //           styleInformation: BigPictureStyleInformation(
  //         //             largeIcon,
  //         //             contentTitle: notification.title,
  //         //             summaryText: notification.body,
  //         //           ),
  //         //         ),
  //         //       ));
  //         //   // await navigatorKey.currentState!.push(
  //         //   //     MaterialPageRoute(builder: (_) =>  NotificationsScreen(
  //         //   //     ))
  //         //   // );
  //         // }
  //
  //         // showNotification(message.data);
  //         print(message.notification!.title);
  //         print(message.notification!.body);
  //         print("message.data22 ${message}");
  //       }
  //     },
  //   );
  //   super.initState();
  // }
  Map<String, dynamic> userMap={};

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MultiBlocProvider(
          providers: [
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
                        // theme: theme,
                        title: 'doctak_app',
                        navigatorKey: NavigatorService.navigatorKey,
                        initialRoute: '/${widget.initialRoute}',
                        routes: {
                          // follow_request
                          // friend_request
                          // message_received
                          // comments_on_posts
                          // new_like
                          // new_tag
                          // new_mention
                          // event_invitation
                          // new_content
                          // group_update
                          // account_activity
                          // system_update
                          // reminder
                          // recommendation
                          // feedback_request
                          // new_job_posted
                          // conference_invitation
                          // comment_tag
                          // job_update
                          // new_discuss_case
                          // discuss_case_comment
                          // discuss_case_like
                          // discuss_case_comment_like
                          // like_comment_on_post
                          // likes_on_posts
                          // like_comments
                          '/': (context) => ForceUpgradePage(),
                          '/follow_request': (context) => SVProfileFragment(
                                userId: widget.id ?? '',
                              ),
                          '/follower_notification': (context) => SVProfileFragment(
                                userId: widget.id ?? '',
                              ),
                          '/un_follower_notification': (context) => SVProfileFragment(
                                userId: widget.id ?? '',
                              ),
                          '/friend_request': (context) => SVProfileFragment(
                                userId: widget.id ?? '',
                              ),
                          '/message_received': (context) => ChatRoomScreen(
                                id:  widget.id.toString(),
                                roomId: '',
                               username: widget.message?.notification?.title??"",
                               profilePic:widget.message?.data['image']??''.replaceAll('https://doctak-file.s3.ap-south-1.amazonaws.com/', '') ,

                              ),
                          '/comments_on_posts': (context) => PostDetailsScreen(
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
                        theme: AppTheme.lightTheme,
                        darkTheme: AppTheme.darkTheme,
                        themeMode: appStore.isDarkMode
                            ? ThemeMode.dark
                            : ThemeMode.light,
                        //     localizationsDelegates: const [
                        //
                        //   // AppLocalizationDelegate(),
                        //   GlobalMaterialLocalizations.delegate,
                        //   GlobalWidgetsLocalizations.delegate,
                        //   GlobalCupertinoLocalizations.delegate,
                        // ],
                        // supportedLocales: const [
                        //   Locale(
                        //     'en',
                        //     '',
                        //   ),
                        //   Locale(
                        //     'ar',
                        //     '',
                        //   ),
                        // ],
                        localizationsDelegates:
                            AppLocalizations.localizationsDelegates,
                        supportedLocales: AppLocalizations.supportedLocales,
                        locale: _locale,
                        // home: ForceUpgradePage(widget.initialRoute??""),
                        // initialRoute: AppRoutes.splashScreen,
                      ));
            },
          ),
        );
      },
    );
  }
}
