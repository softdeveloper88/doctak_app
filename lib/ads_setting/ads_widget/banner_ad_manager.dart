import 'package:doctak_app/ads_setting/ad_setting.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdManager {
  late BannerAd _bannerAd;
  bool _isLoaded = false;

  BannerAdManager() {
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: AdmobSetting.bannerUnit,
      listener: BannerAdListener(
        onAdClosed: (Ad ad) {
          debugPrint("Ad Closed");
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          _isLoaded = false;
        },
        onAdLoaded: (Ad ad) {
          _isLoaded = true;
          debugPrint('Ad Loaded');
        },
        onAdOpened: (Ad ad) {
          debugPrint('Ad opened');
        },
      ),
      request: const AdRequest(),
    );

    _bannerAd.load();
  }

  Widget getBannerAdWidget() {
    if (_isLoaded) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          height: _bannerAd.size.height.toDouble(),
          child: AdWidget(
            ad: _bannerAd,
          ),
        ),
      );
    } else {
      return const SizedBox(height: 8);
    }
  }
  void dispose() {
    _bannerAd.dispose();
  }
}