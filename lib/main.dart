import 'dart:io';

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
import 'package:doctak_app/presentation/splash_screen/splash_screen.dart';
import 'package:doctak_app/presentation/user_chat_screen/bloc/chat_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:upgrader/upgrader.dart';

import 'ads_setting/ad_setting.dart';
import 'core/app_export.dart';
import 'core/network/my_https_override.dart';
import 'presentation/home_screen/fragments/home_main_screen/bloc/home_bloc.dart';

AppStore appStore = AppStore();
var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpsOverrides();
  appStore.toggleDarkMode(value: false);
  WidgetsFlutterBinding.ensureInitialized();
  await Upgrader.clearSavedSettings(); //live update

  AdmobSetting appOpenAdManager = AdmobSetting()..loadAd();
  // WidgetsBinding.instance!.addObserver(AppLifecycle(appOpenAdManager: appOpenAdManager));
  AdmobSetting.initialization();
  MobileAds.instance.initialize();
  if (Platform.isAndroid) {
    AdmobSetting.initialization();
  }
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
  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) => {setLocale(locale)});
    super.didChangeDependencies();
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
                        home:  UpgradeAlert(child:  const SplashScreen()),
                        // initialRoute: AppRoutes.splashScreen,
                        // routes: AppRoutes.routes,
                      ));
            },
          ),
        );
      },
    );
  }
}
