import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/conferences_screen/conferences_screen.dart';
import 'package:doctak_app/presentation/home_screen/home/screens/jobs_screen/jobs_details_screen.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:doctak_app/presentation/terms_and_condition_screen/terms_and_condition_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:sizer/sizer.dart';

import '../../core/utils/pusher_service.dart';
import '../home_screen/SVDashboardScreen.dart';
import '../home_screen/home/screens/jobs_screen/jobs_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    init();
    super.initState();
  }

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void dispose() {
    _linkSubscription?.cancel();

    super.dispose();
  }

  Future<void> initDeepLinks(context) async {
    try {
      print('before');
      _appLinks = AppLinks();
      // Handle links
      final initialLink = await _appLinks.getLatestLink();
      if (initialLink != null) {
        print(initialLink);
        if (initialLink.path.contains('job')) {
          String id = initialLink.pathSegments.last;
          JobsDetailsScreen(isFromSplash: true, jobId: id)
              .launch(context, isNewTask: false);
        } else if (initialLink.path.contains('post')) {
          SVDashboardScreen().launch(context, isNewTask: true);
        } else {
          ConferencesScreen(isFromSplash: true)
              .launch(context, isNewTask: false);
        }
      } else {
        const SVDashboardScreen().launch(context, isNewTask: true);
      }
      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
        debugPrint('onAppLink: $uri');
        // openAppLink(uri);
      });
    } catch (e) {
      print('error $e');
    }
  }

  Future<void> init() async {
    setStatusBarColor(Colors.transparent);
    await 1.seconds.delay;
    finish(context);
    BlocProvider.of<SplashBloc>(context).add(
      LoadDropdownData('', '', '', ''),
    );
    BlocProvider.of<SplashBloc>(context).add(
      LoadDropdownData1('', ''),
    );

    initializeAsync();
  }

  void initializeAsync() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool rememberMe = prefs.getBool('rememberMe') ?? false;
    bool acceptTerms = prefs.getBool('acceptTerms') ?? false;

    String? userToken = prefs.getString('token');
    String? userId = prefs.getString('userId');

    String? name = prefs.getString('name');
    String? profile_pic = prefs.getString('profile_pic');
    String? background = prefs.getString('background');
    String? email = prefs.getString('email');
    String? specialty = prefs.getString('specialty');
    String? userType = prefs.getString('user_type') ?? '';
    String? university = prefs.getString('university') ?? '';
    String? countryName = prefs.getString('country') ?? '';
    String? currency = prefs.getString('currency') ?? '';

    if (userToken != null) {
      AppData.userToken = userToken;
      AppData.logInUserId = userId;
      AppData.name = name ?? '';
      AppData.profile_pic = profile_pic ?? '';
      // AppData.background= background!;
      AppData.background = background ?? '';
      AppData.email = email ?? '';
      AppData.specialty = specialty ?? '';
      AppData.university = university;
      AppData.userType = userType;
      AppData.countryName = countryName;
      AppData.currency = currency;
    }
    if (rememberMe) {
      if (userToken != null) {
        //Future.delayed(const Duration(seconds: 1), () {
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) =>  HomeScreen()), // Navigate to OnboardingScreen
        // );

        initDeepLinks(context);
        // const SVDashboardScreen().launch(context,isNewTask: true);
        // });

      } else {
        // Future.delayed(const Duration(seconds: 1), () {
        LoginScreen().launch(context, isNewTask: true);

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const SignInScreen()), // Navigate to OnboardingScreen
        // );
        // });
      }

    } else {

      LoginScreen().launch(context, isNewTask: true);

      // TermsAndConditionScreen().launch(context, isNewTask: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/splash.png',
            height: context.height(),
            width: context.width(),
            fit: BoxFit.fill,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                  child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Image.asset(
                        'assets/logo/logo.png',
                        // height: 80,
                        width: 80.w,
                        fit: BoxFit.contain,
                      ))),
              8.width,
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Text("Doctak.net",
              //       style: primaryTextStyle(
              //           color: Colors.white,
              //           size: 24,
              //           weight: FontWeight.w500)),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
