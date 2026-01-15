import 'package:doctak_app/ads_setting/ad_setting.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  _BannerAdWidgetState createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  bool _isLoaded = false;
  late BannerAd _bannerAd;

  @override
  void initState() {
    String adsId = AdmobSetting.bannerUnit;
    super.initState();
    _bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: adsId,
      listener: BannerAdListener(
        onAdClosed: (Ad ad) {
          debugPrint("Ad Closed");
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          setState(() {
            _isLoaded = false;
          });
        },
        onAdLoaded: (Ad ad) {
          setState(() {
            _isLoaded = true;
          });
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

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoaded
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: _bannerAd.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
          )
        : const SizedBox.shrink();
  }
}
