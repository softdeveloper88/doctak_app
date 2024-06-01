import 'dart:io';

import 'package:doctak_app/core/utils/doctak_firebase_remoteConfig.dart';
import 'package:doctak_app/presentation/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpgradePage extends StatefulWidget {
  const ForceUpgradePage({Key? key}) : super(key: key);

  @override
  State<ForceUpgradePage> createState() => _ForceUpgradeState();
}

class _ForceUpgradeState extends State<ForceUpgradePage> {
  PackageInfo? packageInfo;
  final featureFlagRepository = DoctakFirebaseRemoteConfig();

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

  void _checkAppVersion() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (packageInfo != null) {
        final appVersion = _getExtendedVersionNumber(packageInfo!.version);
        final requiredMinVersion =
        _getExtendedVersionNumber(featureFlagRepository.getRequiredMinimumVersion());
        final recommendedMinVersion =
        _getExtendedVersionNumber(featureFlagRepository.getRecommendedMinimumVersion());

        if (appVersion < requiredMinVersion) {
          isSkippible=false;
          isUpdateAvailable=true;
        } else if (appVersion < recommendedMinVersion) {
          isSkippible=true;
          isUpdateAvailable=true;
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            ),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SplashScreen(),
          ),
        );
        // Handle the case where packageInfo is null
        // You can display a loading indicator or handle it in some other way
      }
    });
  }

  int _getExtendedVersionNumber(String version) {
    List versionCells = version.split('.');
    versionCells = versionCells.map((i) => int.parse(i)).toList();
    return versionCells[0] - 100000 + versionCells[1] - 1000 + versionCells[2];
  }

  void _launchAppOrPlayStore() {
    final appId = Platform.isAndroid ? packageInfo!.packageName : '6448684340';
    final url = Uri.parse(
      Platform.isAndroid ? "market://details?id=$appId" : "https://apps.apple.com/app/id$appId",
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
      body: isUpdateAvailable??false?Padding(
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
              onPressed:_launchAppOrPlayStore,
              child: const Text('Update Now'),
            ),
           if(isSkippible??false) ElevatedButton(
              onPressed:(){
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
      ):Stack(
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
