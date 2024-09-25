import 'dart:convert';
import 'dart:io';

import 'package:doctak_app/presentation/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_transitions.dart';

class ForceUpgradePage extends StatefulWidget {
  const ForceUpgradePage({Key? key}) : super(key: key);

  @override
  State<ForceUpgradePage> createState() => _ForceUpgradeState();
}

class _ForceUpgradeState extends State<ForceUpgradePage> {
  PackageInfo? packageInfo;

  // final featureFlagRepository = DoctakFirebaseRemoteConfig();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializePackageInfo();
    _checkAppVersion();
  }

  Future<void> _initializePackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  Future<Map<String, dynamic>> fetchLatestVersion() async {
    try {
      var response;
      if (Platform.isAndroid) {
        response = await http
            .get(Uri.parse('https://doctak.net/api/v1/version/Android'));
      } else {
        response =
        await http.get(Uri.parse('https://doctak.net/api/v1/version/iOS'));
      }
      print(response.body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return <String, dynamic>{};
      }
    }catch(e){
      return <String, dynamic>{};
    }
  }

  Future<void> _checkAppVersion() async {
    if (packageInfo != null) {
      SharedPreferences prefs =
      await SharedPreferences.getInstance();
      final latestVersionInfo = await fetchLatestVersion();
      var latestVersion;
      var latestVersionLocal;
     var mandatory;
      if(latestVersionInfo.isNotEmpty) {
         latestVersion = latestVersionInfo['data']['version'];
            await prefs.setString('latest_version', latestVersion);
           latestVersionLocal=prefs.getString('latest_version');
          mandatory = latestVersionInfo['data']['mandatory'];
      }else{
        latestVersionLocal=prefs.getString('latest_version');
      }
      print(latestVersionLocal);
      Version version1 = Version.parse(packageInfo!.version);
      Version version2 = Version.parse(latestVersionLocal);

      // final url = latestVersionInfo['url'];
      print(latestVersionInfo);
      print(latestVersion);
      print(version1);
      print(version2);

      if (version1 < version2 && mandatory == 1) {
        setState(() {
          isSkippible = false;
          isUpdateAvailable = true;
        });
      } else if (version1 < version2 && mandatory == 0) {
        setState(() {
          isSkippible = true;
          isUpdateAvailable = true;
        });
      } else {
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            page: const SplashScreen(),
            transitionType: PageTransitionType.fade, // or any other type
          ),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        CustomPageRoute(
          page: const SplashScreen(),
          transitionType: PageTransitionType.fade, // or any other type
        ),
      );
      // Handle the case where packageInfo is null
      // You can display a loading indicator or handle it in some other way
    }
  }

  void _launchAppOrPlayStore() {
    final appId = Platform.isAndroid ? packageInfo!.packageName : '6448684340';
    final url = Uri.parse(
      Platform.isAndroid
          ? "market://details?id=$appId"
          : "https://apps.apple.com/app/id$appId",
    );
    launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  bool? isSkippible;
  bool? isUpdateAvailable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isUpdateAvailable ?? false
          ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'New version available',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Please update to the latest version of the app to continue using it.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _launchAppOrPlayStore,
                    child: const Text('Update Now'),
                  ),
                  if (isSkippible ?? false)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const SplashScreen(),
                          ),
                        );
                      },
                      child: const Text('Skip'),
                    ),
                ],
              ),
            )
          : Stack(
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

                  ],
                ),
              ],
            ),
    );
  }
}
