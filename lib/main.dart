import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/core/utils/force_updrage_page.dart';
import 'package:doctak_app/presentation/chat_gpt_screen/bloc/chat_gpt_bloc.dart';
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
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import 'ads_setting/ad_setting.dart';
import 'core/network/my_https_override.dart';
import 'core/utils/navigator_service.dart';
import 'core/utils/pref_utils.dart';
import 'localization/app_localization.dart';
import 'presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';

AppStore appStore = AppStore();
var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<dynamic> _throwGetMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('PUSH RECEIVED');
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

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey(debugLabel: 'Main Navigator');

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
  if (!kIsWeb) {
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title // description
      importance: Importance.max,
    );
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    FirebaseMessaging.onBackgroundMessage(_throwGetMessage);
    //App is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message, app is in the foreground!');
      debugPrint('Message data: $message');
      // showNotification(message.data);
      if (message.notification != null) {
        if (kDebugMode) {
          print(
              'Message also contained a notification: ${message.notification}');
        }
      }
    });

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    )
        .then((value) {
      debugPrint('value:print');
    });
  }
  appStore.toggleDarkMode(value: false);
  WidgetsFlutterBinding.ensureInitialized();
  // await Upgrader.clearSavedSettings(); //live update
  // await DoctakFirebaseRemoteConfig.initialize();
  // AdmobSetting appOpenAdManager = AdmobSetting()..loadAd();
  // WidgetsBinding.instance!.addObserver(AppLifecycle(appOpenAdManager: appOpenAdManager));
  // AdmobSetting.initialization();
  // MobileAds.instance.initialize();
  // if (Platform.isAndroid) {
  //   AdmobSetting.initialization();
  // }
  Future.wait([
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]),
    PrefUtils().init()
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;

  MyApp({this.navigatorKey});

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

  Future<bool> sendFcmMessage(
      String title, String message, String token) async {
    try {
      var url = 'https://fcm.googleapis.com/fcm/send';
      var header = {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer AAAA4y01nWA:APA91bEcfbKn4ZZ-1WPyK4FFepBC4_PWOthWPwz5yoK7b2rcftt2O9_xy5tOaeoeceVaPR5eY7Y6cX_YtIBq7WL11NN8dB3mtpQ8Tq-cNYf8x_FfyG_Hpps6wsMeY1btHcdUqaWEByTd',
      };
      var request = {
        'registration_ids': [token],
        'priority': 'high',
        'important': 'max',
        'notification': {'body': message, 'title': title}
      };
      var response = await http.post(Uri.parse(url),
          headers: header, body: json.encode(request));
      if (kDebugMode) {
        print(response.body);
      }
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  setToken() async {
    await FirebaseMessaging.instance.getToken().then((token) async {
      sendFcmMessage('dfd', 'df', token.toString());
      if (kDebugMode) {
        print(token);
      }
    });
  }

  @override
  void initState() {
    // NotificationManger.init(context: context);
    // setFCMSetting();
    // setToken();
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          RemoteNotification? notification = message.notification;
          AndroidNotification? android = message.notification?.android;
          if (notification != null && android != null) {
            flutterLocalNotificationsPlugin.show(
                notification.hashCode,
                notification.title,
                notification.body,
                NotificationDetails(
                  android: AndroidNotificationDetails(
                    channel.id,
                    channel.name,
                    icon: '@mipmap/icon_launcher',
                  ),
                ));
          }
          // if(user_type.$=="customer") {
          //   await navigatorKey.currentState!.push(
          //       MaterialPageRoute(builder: (_) =>
          //           NotificationsScreen(isWorkshop:false
          //           ))
          //   );
          // }else{
          //   await navigatorKey.currentState!.push(
          //       MaterialPageRoute(builder: (_) =>
          //           NotificationsScreen(isWorkshop: true
          //           ))
          //   );
          // }
        });
      }
    });
    // 2. This method only call when App in forground it mean app must be opened
    FirebaseMessaging.onMessage.listen(
      (message) async {
        if (kDebugMode) {
          print('FirebaseMessaging.onMessage.listen');
        }
        if (message.notification != null) {
          if (kDebugMode) {
            print(message.notification!.title);
          }
          if (kDebugMode) {
            print(message.notification!.body);
          }
          if (kDebugMode) {
            print('message.data11 ${message.data}');
          }
          // showNotification(message.data);
          RemoteNotification? notification = message.notification;
          AndroidNotification? android = message.notification?.android;
          if (notification != null && android != null) {
            flutterLocalNotificationsPlugin.show(
                notification.hashCode,
                notification.title,
                notification.body,
                NotificationDetails(
                  android: AndroidNotificationDetails(
                    channel.id,
                    channel.name,
                    icon: '@mipmap/ic_launcher',
                  ),
                ));
          }
          // if(user_type.$=="customer") {
          //   await navigatorKey.currentState!.push(
          //       MaterialPageRoute(builder: (_) =>
          //           NotificationsScreen(isWorkshop:false
          //           ))
          //   );
          // }else{
          //   await navigatorKey.currentState!.push(
          //       MaterialPageRoute(builder: (_) =>
          //           NotificationsScreen(isWorkshop: true
          //           ))
          //   );
          // }
        }
      },
    );
    // 3. This method only call when App in background and not terminated(not closed)
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) async {
        print('FirebaseMessaging.onMessageOpenedApp.listen');
        if (message.notification != null) {
          RemoteNotification? notification = message.notification;
          AndroidNotification? android = message.notification?.android;
          if (notification != null && android != null) {
            flutterLocalNotificationsPlugin.show(
                notification.hashCode,
                notification.title,
                notification.body,
                NotificationDetails(
                  android: AndroidNotificationDetails(
                    channel.id,
                    channel.name,
                    icon: '@mipmap/ic_launcher',
                  ),
                ));
            // await navigatorKey.currentState!.push(
            //     MaterialPageRoute(builder: (_) =>  NotificationsScreen(
            //     ))
            // );
          }

          // showNotification(message.data);
          print(message.notification!.title);
          print(message.notification!.body);
          print("message.data22 ${message.data['_id']}");
        }
      },
    );
    super.initState();
  }

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
                        home: const ForceUpgradePage(),
                        // initialRoute: AppRoutes.splashScreen,
                      ));
            },
          ),
        );
      },
    );
  }
}
