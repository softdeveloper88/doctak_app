import 'package:doctak_app/core/app_export.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/presentation/home_screen/SVDashboardScreen.dart';
import 'package:doctak_app/presentation/login_screen/login_screen.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_bloc.dart';
import 'package:doctak_app/presentation/splash_screen/bloc/splash_event.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

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

  Future<void> init() async {
    setStatusBarColor(Colors.transparent);
    await 3.seconds.delay;
    finish(context);
    BlocProvider.of<SplashBloc>(context).add(LoadDropdownData('', '','',''),);
    BlocProvider.of<SplashBloc>(context).add(LoadDropdownData1('', ''),);

    initializeAsync();
  }
  void initializeAsync() async{
    SharedPreferences prefs = await   SharedPreferences.getInstance();

    bool rememberMe = prefs.getBool('rememberMe') ?? false;

    String? userToken = prefs.getString('token');
    String? userId = prefs.getString('userId');

    String? name = prefs.getString('name');
    String? profile_pic = prefs.getString('profile_pic');
    String? background = prefs.getString('background');
    String? email = prefs.getString('email');
    String? specialty = prefs.getString('specialty');
    String? userType = prefs.getString('user_type')??'';
    String? university = prefs.getString('university') ?? '';
    String? countryName = prefs.getString('country') ?? '';
    String? currency = prefs.getString('currency') ?? '';

    if (userToken != null) {

      AppData.userToken = userToken;
      AppData.logInUserId = userId;
      AppData.name = name??'';
      AppData.profile_pic = profile_pic??'';
      // AppData.background= background!;
      AppData.background = background??'';
      AppData.email = email??'';
      AppData.specialty = specialty??'';
      AppData.university= university;
      AppData.userType= userType;
      AppData.countryName = countryName;
      AppData.currency = currency;

    }
    if (userToken != null) {
      Future.delayed(const Duration(seconds: 2), () {
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) =>  HomeScreen()), // Navigate to OnboardingScreen
        // );
        SVDashboardScreen().launch(context,isNewTask: true);

      });
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        LoginScreen().launch(context,isNewTask: true);

        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const SignInScreen()), // Navigate to OnboardingScreen
        // );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'images/socialv/svSplashImage.jpg',
            height: context.height(),
            width: context.width(),
            fit: BoxFit.fill,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo/logo.png', height: 50, width: 52, fit: BoxFit.cover,),
              8.width,
              Text("Doctak.net", style: primaryTextStyle(color: Colors.white, size: 40, weight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
