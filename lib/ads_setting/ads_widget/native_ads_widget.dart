import 'package:doctak_app/ads_setting/ad_setting.dart';
import 'package:doctak_app/core/app_export.dart';
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
    flutterNativeAdsShow();
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

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isAdLoaded
        ?  Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 350,
        child: AdWidget(ad: _ad),
      ),
    )
        : const SizedBox(height: 0,);
  }
}
