import 'dart:async';
import 'dart:io';

import 'package:doctak_app/core/utils/force_updrage_page.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
import 'package:doctak_app/presentation/coming_soon_screen/coming_soon_screen.dart';
import 'package:doctak_app/presentation/home_screen/fragments/add_post/bloc/add_post_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/profile_screen/bloc/profile_bloc.dart';
import 'package:doctak_app/presentation/home_screen/fragments/search_people/bloc/search_people_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/bloc/conference_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/drugs_list_screen/bloc/drugs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/guidelines_screen/bloc/guideline_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/bloc/jobs_bloc.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/news_screen/bloc/news_bloc.dart';
import 'package:doctak_app/presentation/home_screen/store/AppStore.dart';
import 'package:doctak_app/presentation/home_screen/utils/AppTheme.dart';
import 'package:doctak_app/presentation/login_screen/bloc/login_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:doctak_app/theme/bloc/theme_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'core/utils/navigator_service.dart';
import 'core/utils/pref_utils.dart';
import 'localization/app_localization.dart';
import 'presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';

AppStore appStore = AppStore();
var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();


Future<dynamic> _throwGetMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('PUSH RECEIVED');

  await showNotificationWithCustomIcon(
      message.notification,
      message.notification?.title ??'',
      message.notification?.body ??'',
      message.data['image'] ?? '',
      message.data['banner'] ?? '');
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  // FlutterLocalNotificationsPlugin();
  // const AndroidInitializationSettings initializationSettingsAndroid =
  // AndroidInitializationSettings('ic_stat_name');
  // const InitializationSettings initializationSettings = InitializationSettings(
  //     android: initializationSettingsAndroid);
  // await flutterLocalNotificationsPlugin.initialize(initializationSettings,
  //     onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  // final ByteArrayAndroidBitmap largeIcon = await _getImageFromUrl('https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTQzCFZPz1Er-39Wvzvn5QBEMy9JSP6vGl2Xg&s');
  // RemoteNotification? notification = message.notification;
  // AndroidNotification? android = message.notification?.android;
  // if (notification != null && android != null) {
  //   flutterLocalNotificationsPlugin.show(
  //       notification.hashCode,
  //       notification.title,
  //       notification.body,
  //       NotificationDetails(
  //         android: AndroidNotificationDetails(
  //           channel.id,
  //           channel.name,
  //           largeIcon: largeIcon,
  //           styleInformation: BigPictureStyleInformation(
  //             largeIcon,
  //             contentTitle: notification.title,
  //             summaryText: notification.body,
  //           ),
  //           icon: 'ic_stat_name',
  //         ),
  //       ));
  // }
  // if(user_type.$=="customer") {
  //   await navigatorKey.currentState?.push(
  //       MaterialPageRoute(builder: (context) =>
  //           NotificationsScreen(isWorkshop:false
  //           ))
  //   );
  // }else{
  //   await navigatorKey.currentState?.push(
  //       MaterialPageRoute(builder: (context) =>
  //           NotificationsScreen(isWorkshop: true
  //           ))
  //   );
  // }
  // showNotification(message.data);
}

Future<void> showNotificationWithCustomIcon(notification, String title,
    String body, String imageUrl, String bannerImage) async {
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
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title // description
    importance: Importance.max,
  );
  flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      title,
      body,
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });
  HttpOverrides.global = MyHttpsOverrides();
  // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  //   systemNavigationBarColor: Colors.white, // navigation bar color
  //   statusBarColor: Colors.white, // status bar color
  // ));
  if (Platform.isAndroid) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDERo2-Nyit1b3UTqWWKNUutkALGBauxuc',
        appId: "1:975716064608:android:c1a4889c2863e014749205",
        messagingSenderId: "975716064608",
        projectId: "doctak-322cc",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  // if (!kIsWeb) {
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
  String? payload = await NotificationService.getNotificationPayload();
  // Initialize the notification service


  // Get the initial notification data if the app was launched from a terminated state by tapping a notification
  String? initialRoute = await NotificationService.getInitialNotificationRoute();

  // Use the notification data (payload or route) to navigate to a specific screen

  appStore.toggleDarkMode(value: false);
  WidgetsFlutterBinding.ensureInitialized();
  Future.wait([
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]),
    PrefUtils().init()
  ]).then((value) {

    runApp(MyApp(initialRoute:initialRoute));

  });
}

class MyApp extends StatefulWidget {
  final String? initialRoute;

  const MyApp({Key? key, this.initialRoute}) : super(key: key);

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
  setToken() async {
    await FirebaseMessaging.instance.getToken().then((token) async {
      log('token ${token}');
    });
  }

  @override
  void initState() {
    setFCMSetting();
    setToken();
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
                        initialRoute: widget.initialRoute ?? '/',
                        routes: {
                          '/': (context) => const ForceUpgradePage(),
                          '/follow_request': (context) => const ComingSoonScreen(),
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
                        // home: ForceUpgradePage(),
                        // initialRoute: AppRoutes.splashScreen,
                      ));
            },
          ),
        );
      },
    );
  }
}

Future<ByteArrayAndroidBitmap> _getImageFromUrl(String imageUrl) async {
  final response = await http.get(Uri.parse(imageUrl));
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/user_image.png';
  final file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  final Uint8List imageBytes = await file.readAsBytes();
  return ByteArrayAndroidBitmap(imageBytes);
}
