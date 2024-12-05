import 'dart:io';

import 'package:doctak_app/ads_setting/ad_setting.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  @override
  _NativeAdWidgetState createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  late NativeAd _ad;
  bool _isAdLoaded = false;

  @override
  void initState() {
    loadAd();
    super.initState();
  }

  flutterNativeAdsShow() {
    // TODO: Create a NativeAd instance
    // _ad = NativeAd(
    //   adUnitId: AdmobSetting.nativeAdUnitId,
    //   factoryId: "NativeAdsShow",
    //   request: const AdRequest(),
    //   listener: NativeAdListener(
    //     onAdLoaded: (_) {
    //       setState(() {
    //         _isAdLoaded = true;
    //       });
    //     },
    //     onAdFailedToLoad: (ad, error) {
    //       // Releases an ad resource when it fails to load
    //       ad.dispose();
    //       debugPrint(
    //           'Ad load failed (code=${error.code} message=${error.message})');
    //     },
    //   ),
    // );
    // _ad.load();
    _ad = NativeAd(
      adUnitId: AdmobSetting.nativeAdUnitId,
      factoryId: 'NativeAdsShow',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          // ignore: avoid_print
          print('$NativeAd loaded.');
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          // ignore: avoid_print
          print('$NativeAd failedToLoad: $error');
          ad.dispose();
        },
        onAdClicked: (ad) {},
        onAdImpression: (ad) {},
        onAdClosed: (ad) {},
        onAdOpened: (ad) {},
        onAdWillDismissScreen: (ad) {},
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {},
      ),
      request: const AdRequest(),
    )..load();
  }

  NativeAd? nativeAd;
  bool _nativeAdIsLoaded = false;

  // TODO: replace this test ad unit with your own ad unit.
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-3940256099942544/3986624511';

  /// Loads a native ad.
  void loadAd() {
    _ad = NativeAd(
        adUnitId: _adUnitId,
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint('$NativeAd loaded.');
            setState(() {
              _nativeAdIsLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            // Dispose the ad here to free resources.
            debugPrint('$NativeAd failed to load: $error');
            ad.dispose();
          },
        ),
        request: const AdRequest(),
        // Styling
        nativeTemplateStyle: NativeTemplateStyle(
            // Required: Choose a template.
            templateType: TemplateType.medium,
            // Optional: Customize the ad's style.
            // mainBackgroundColor: Colors.purple,
            cornerRadius: 10.0,
            callToActionTextStyle: NativeTemplateTextStyle(
                textColor: Colors.black,
                backgroundColor: Colors.yellow,
                style: NativeTemplateFontStyle.monospace,
                size: 16.0),
            primaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.black,
                // backgroundColor: Colors.cyan,
                style: NativeTemplateFontStyle.italic,
                size: 16.0),
            secondaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.green,
                backgroundColor: Colors.black,
                style: NativeTemplateFontStyle.bold,
                size: 16.0),
            tertiaryTextStyle: NativeTemplateTextStyle(
                textColor: Colors.brown,
                // backgroundColor: Colors.amber,
                style: NativeTemplateFontStyle.normal,
                size: 16.0)))
      ..load();
  }

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _nativeAdIsLoaded
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 350,
              child: AdWidget(ad: _ad),
            ),
          )
        : const SizedBox(
            height: 0,
          );
  }
}
