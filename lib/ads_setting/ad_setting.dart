import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdmobSetting {
  /// Maximum duration allowed between loading and showing the ad.
  final Duration maxCacheDuration = const Duration(hours: 4);

  /// Keep track of load time so we don't show an expired ad.
  DateTime? _appOpenLoadTime;

  String adOpenUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/3419835294'
      : 'not set for ios';

  static String get bannerUnit {
    print("banner adsId ${AppData.androidBannerAdsId}");
    if (Platform.isAndroid) {
      // return 'ca-app-pub-3940256099942544/6300978111';
      return AppData.androidBannerAdsId??'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return AppData.iosBannerAdsId ?? 'ca-app-pub-3940256099942544/2934735716';
      // return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError("Unsupported platform");
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      print('native ads constant ${AppData.androidNativeAdsId}');
      return AppData.androidNativeAdsId ?? 'ca-app-pub-3940256099942544/2247696110';
    } else if (Platform.isIOS) {
      return AppData.iosNativeAdsId ?? 'ca-app-pub-3940256099942544/3986624511';
    }
    throw UnsupportedError("Unsupported platform");
  }

  static String get interstitialsUnit {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    throw UnsupportedError("Unsupported platform");
  }

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  /// Load an [AppOpenAd].
  void loadAd() {
    // We will implement this below.
    AppOpenAd.load(
      adUnitId: adOpenUnitId,
      // orientation: AppOpenAd.orientationPortrait,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded');
          _appOpenLoadTime = DateTime.now();
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  /// Whether an ad is available to be shown.
  bool get isAdAvailable {
    return _appOpenAd != null;
  }

  // static String get bannerUnit => 'ca-app-pub-3940256099942544/6300978111';
  // static String get interstitialsUnit =>
  //     'ca-app-pub-3940256099942544/1033173712';
  InterstitialAd? _interstitialAd;
  int num_of_attempt_load = 0;

  static initialization() {
    if (MobileAds.instance == null) {
      MobileAds.instance.initialize();
    }
  }

  static BannerAd getBannerAds() {
    BannerAd bAd = BannerAd(
        size: AdSize.fullBanner,
        adUnitId: bannerUnit,
        listener: BannerAdListener(onAdClosed: (Ad ad) {
          debugPrint("Ad Closed");
        }, onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        }, onAdLoaded: (Ad ad) {
          debugPrint('Ad Loaded');
        }, onAdOpened: (Ad ad) {
          debugPrint('Ad opened');
        }),
        request: const AdRequest());
    return bAd;
  }

  // method for creating  interstitial ads
  void createInterstitialAds() {
    debugPrint("createInterstitialAds");
    InterstitialAd.load(
      adUnitId: interstitialsUnit,
      request: const AdRequest(),
      adLoadCallback:
          InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
        debugPrint("onAdLoaded");
        _interstitialAd = ad;
        num_of_attempt_load = 0;
      }, onAdFailedToLoad: (LoadAdError error) {
        debugPrint("onAdFailedToLoad");
        num_of_attempt_load += 1;
        if (num_of_attempt_load <= 3) {
          createInterstitialAds();
        } else {
          // add is not coming from google any reason
        }
      }),
    );
  }

  void createInterstitialAdsButton(
      int screen, BuildContext context, SharedPreferences prefs) {
    debugPrint("createInterstitialAds");
    if (_interstitialAd == null) {
      // showInterstitialAds(screen, context);
      // navigateScreenRequired(screen, context, prefs);
    } else {
      InterstitialAd.load(
        adUnitId: interstitialsUnit,
        request: const AdRequest(),
        adLoadCallback:
            InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
          debugPrint("onAdLoaded");
          _interstitialAd = ad;
          showInterstitialAds(screen, context, prefs);
          num_of_attempt_load = 0;
        }, onAdFailedToLoad: (LoadAdError error) {
          debugPrint("error:::::${error.code}");
          num_of_attempt_load += 1;
          if (num_of_attempt_load <= 3) {
            createInterstitialAdsButton(screen, context, prefs);
          } else {
            // navigateScreenRequired(screen, context, prefs);
            // add is not coming from google any reason
          }
        }),
      );
    }
  }

// show interstitial ads to Navigation time
  void showInterstitialAds(
      int screen, BuildContext context, SharedPreferences prefs) {
    if (_interstitialAd == null) {
      // navigateScreenRequired(screen, context, prefs);
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      debugPrint("ad onAdshowedFullscreen");
    }, onAdDismissedFullScreenContent: (InterstitialAd ad) {
      debugPrint("ad Disposed");
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);

      // navigateScreenRequired(screen, context, prefs);
      ad.dispose();
    }, onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError aderror) {
      debugPrint('$ad OnAdFailed $aderror');
      ad.dispose();
      createInterstitialAds();
    });
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void showAdIfAvailable() {
    if (!isAdAvailable) {
      print('Tried to show ad before available.');
      loadAd();
      return;
    }
    if (_isShowingAd) {
      print('Tried to show ad while already showing an ad.');
      return;
    }
    if (DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
      print('Maximum cache duration exceeded. Loading another ad.');
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAd();
      return;
    }
    // Set the fullScreenContentCallback and show the ad.
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        print('$ad onAdShowedFullScreenContent');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        print('$ad onAdDismissedFullScreenContent');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );
    _appOpenAd!.show();
  }

// void navigateScreenRequired(
//     int screen, BuildContext context, SharedPreferences? prefs) {
//
//     switch (screen) {
//       case 1:
//         {
//           ColorsCode.primaryColor = const Color(0xffF9963D);
//           ResourcesPath.headerImagePath = 'assets/icons/orange_circle.svg';
//           ResourcesPath.phoneImagePath =
//           'assets/icons/orange_mobile_icon.svg';
//           ResourcesPath.loaderAnimationPath =
//           'assets/animations/orangeloading.json';
//
//           pageRoutPushReplacement(
//               context,
//               PhoneTrackLocationScreen(
//                 email: prefs?.getString("user_email")??"",
//                 displayName: prefs?.getString("user_name")??"",
//                 password: prefs?.getString("user_password")??"",
//               ));
//         }
//         break;
//       case 2:
//         {
//           ColorsCode.primaryColor = const Color(0xff007EFD);
//           ResourcesPath.headerImagePath = 'assets/icons/blue_circle.svg';
//           ResourcesPath.phoneImagePath = 'assets/icons/blue_mobile_icon.svg';
//           ResourcesPath.loaderAnimationPath =
//           'assets/animations/blueloading.json';
//
//           pageRoutPushReplacement(
//               context,
//               PhoneRingToneScreen(
//                   email: prefs?.getString("user_email")??"",
//                   displayName: prefs?.getString("user_name")??"",
//                   password: prefs?.getString("user_password")??""));
//         }
//         break;
//       case 3:
//         {
//           ColorsCode.primaryColor = const Color(0xffF3514F);
//           ResourcesPath.headerImagePath = 'assets/icons/red_circle.svg';
//           ResourcesPath.phoneImagePath = 'assets/icons/red_mobile_icon.svg';
//           ResourcesPath.loaderAnimationPath =
//           'assets/animations/redloading.json';
//           pageRoutPushReplacement(
//               context,
//               PhoneVibrateScreen(
//                   email: prefs?.getString("user_email")??"",
//                   displayName: prefs?.getString("user_name")??"",
//                   password: prefs?.getString("user_password")??""));
//         }
//         break;
//       case 4:
//         {
//           ColorsCode.primaryColor = const Color(0xff5954F8);
//           ResourcesPath.headerImagePath = 'assets/icons/blue_circle.svg';
//           ResourcesPath.phoneImagePath =
//           'assets/icons/purple_mobile_icon.svg';
//           ResourcesPath.loaderAnimationPath =
//           'assets/animations/purpleloading.json';
//
//              pageRoutPushReplacement(
//                  context,
//                  PhoneLastTryScreen(
//                      email: prefs?.getString("user_email") ?? "",
//                      displayName: prefs?.getString("user_name") ?? "",
//                      password: prefs?.getString("user_password") ?? ""));
//
//         }
//         break;
//       case 5:
//         {
//           ColorsCode.primaryColor = const Color(0xffF9963D);
//           ResourcesPath.headerImagePath = 'assets/icons/orange_circle.svg';
//           ResourcesPath.phoneImagePath =
//           'assets/icons/orange_mobile_icon.svg';
//           ResourcesPath.loaderAnimationPath =
//           'assets/animations/orangeloading.json';
//
//           pageRoutPushReplacement(
//               context,
//               PhoneLockScreen(
//                   email: prefs?.getString("user_email")??"",
//                   displayName: prefs?.getString("user_name")??"",
//                   password: prefs?.getString("user_password")??""));
//         }
//         break;
//       case 6:
//         {
//           ColorsCode.primaryColor = const Color(0xff007EFD);
//           ResourcesPath.headerImagePath = 'assets/icons/blue_circle.svg';
//           ResourcesPath.phoneImagePath = 'assets/icons/blue_mobile_icon.svg';
//           ResourcesPath.loaderAnimationPath =
//           'assets/animations/blueloading.json';
//
//           pageRoutPushReplacement(
//               context,
//               PhoneEraseDataScreen(
//                   email: prefs?.getString("user_email")??"",
//                   displayName: prefs?.getString("user_name")??"",
//                   password: prefs?.getString("user_password")??""));
//         }
//         break;
//       case 7:
//         {
//           ColorsCode.primaryColor = const Color(0xffF3514F);
//           ResourcesPath.headerImagePath = 'assets/icons/red_circle.svg';
//           ResourcesPath.phoneImagePath = 'assets/icons/red_mobile_icon.svg';
//           ResourcesPath.loaderAnimationPath =
//           'assets/animations/redoading.json';
//
//           pageRoutPushReplacement(context, const BatteryScreen());
//         }
//         break;
//       case 8:
//         {
//           ColorsCode.primaryColor = const Color(0xff5954F8);
//           ResourcesPath.headerImagePath = 'assets/icons/blue_circle.svg';
//           ResourcesPath.phoneImagePath =
//           'assets/icons/purple_mobile_icon.svg';
//           ResourcesPath.loaderAnimationPath =
//           'assets/animations/purpleloading.json';
//
//           pageRoutPushReplacement(context, const UnTouchPhoneScreen());
//         }
//         break;
//       case 9:
//         {
//           ColorsCode.primaryColor = const Color(0xffF9963D);
//           ResourcesPath.headerImagePath = 'assets/icons/orange_circle.svg';
//           ResourcesPath.phoneImagePath =
//           'assets/icons/orange_mobile_icon.svg';
//           ResourcesPath.loaderAnimationPath =
//           'assets/animations/orangeloading.json';
//
//           pageRoutPushReplacement(
//               context,
//               PhoneFlashLightScreen(
//                   email: prefs?.getString("user_email")??"",
//                   displayName: prefs?.getString("user_name")??"",
//                   password: prefs?.getString("user_password")??""));
//         }
//         break;
//       default:
//         debugPrint("no screen found");
//     }
//     // if (screen == "Location") {
//     //   pageRout(context, new FindLocationScreen(
//     //                 email: _auth.currentUser!.email!,
//     //                 displayName: _auth.currentUser!.displayName!,
//     //                 photoURL: _auth.currentUser!.photoURL!,
//     //                 uid: _auth.currentUser!.uid));
//     // } else if (screen == "Ring") {
//     //   pageRout(context, new RingToneScreen(
//     //       email: _auth.currentUser!.email!,
//     //       displayName: _auth.currentUser!.displayName!,
//     //       photoURL: _auth.currentUser!.photoURL!,
//     //       uid: _auth.currentUser!.uid));
//     //
//     // } else if (screen == "Vibrate") {
//     //   pageRout(context, new VibrateScreen(
//     //       email: _auth.currentUser!.email!,
//     //       displayName: _auth.currentUser!.displayName!,
//     //       photoURL: _auth.currentUser!.photoURL!,
//     //       uid: _auth.currentUser!.uid));
//     //
//     // } else if (screen == "LastTry") {
//     //   pageRout(context, new LastTryScreen(
//     //       email: _auth.currentUser!.email!,
//     //       displayName: _auth.currentUser!.displayName!,
//     //       photoURL: _auth.currentUser!.photoURL!,
//     //       uid: _auth.currentUser!.uid));
//     //
//     //   // pageRout(context, new DontTouchScreen(
//     //   // ));
//     //
//     // }else if (screen == "lockScreen") {
//     //   pageRout(context, new LockScreen(
//     //       email: _auth.currentUser!.email!,
//     //       displayName: _auth.currentUser!.displayName!,
//     //       photoURL: _auth.currentUser!.photoURL!,
//     //       uid: _auth.currentUser!.uid));
//     //
//     //   // pageRout(context, new DontTouchScreen(
//     //   // ));
//     //
//     // }else if (screen == "EraseData") {
//     //   pageRout(context, new EraseDataScreen(
//     //       email: _auth.currentUser!.email!,
//     //       displayName: _auth.currentUser!.displayName!,
//     //       photoURL: _auth.currentUser!.photoURL!,
//     //       uid: _auth.currentUser!.uid));
//     //
//     //   // pageRout(context, new DontTouchScreen(
//     //   // ));
//     //
//     // }else if (screen == "Unplug") {
//     //   pageRout(context, new BatteryScreen());
//     //
//     //   // pageRout(context, new DontTouchScreen(
//     //   // ));
//     //
//     // }else if (screen == "Touch") {
//     //   pageRout(context, new DontTouchScreen());
//
//     // pageRout(context, new DontTouchScreen(
//     // ));
//
//     // }
//   }
}
