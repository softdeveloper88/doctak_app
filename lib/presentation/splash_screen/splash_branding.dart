import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:doctak_app/widgets/doctak_app_loader.dart';

/// Shared splash branding — doctak_logo.json is 90 frames @ 30fps (3.0s).
class SplashBranding {
  SplashBranding._();

  static String get lottieAsset => DoctakAppLoaderConfig.lottieAsset;
  static set lottieAsset(String value) => DoctakAppLoaderConfig.lottieAsset = value;

  static const Duration animationDuration = Duration(milliseconds: 1200);
  static const Duration minDuration = Duration(milliseconds: 1200);
}

class SplashLogoLottie extends StatelessWidget {
  final double? width;
  final bool repeat;

  const SplashLogoLottie({
    super.key,
    this.width,
    this.repeat = true,
  });

  @override
  Widget build(BuildContext context) {
    return DoctakAppLoader(
      size: width ?? 50.w,
      repeat: repeat,
    );
  }
}
