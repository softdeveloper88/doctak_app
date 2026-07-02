import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Global pre-loader configuration. Defaults to the splash screen Lottie asset.
/// Override at startup: `DoctakAppLoaderConfig.lottieAsset = 'assets/...'`.
class DoctakAppLoaderConfig {
  DoctakAppLoaderConfig._();

  static const String defaultLottieAsset = 'assets/animations/doctak_logo.json';
  static String lottieAsset = defaultLottieAsset;

  static const double dialogSize = 100;
  static const double inlineSize = 28;
  static const double pageSize = 120;

  /// Dim scrim behind full-screen loaders (matches legacy progress overlay).
  static const Color overlayBarrierColor = Color(0x8A000000);
}

/// Branded Lottie loader — same animation as [SplashLogoLottie] / splash screen.
class DoctakAppLoader extends StatelessWidget {
  final double size;
  final bool repeat;
  final String? asset;

  const DoctakAppLoader({
    super.key,
    this.size = DoctakAppLoaderConfig.dialogSize,
    this.repeat = true,
    this.asset,
  });

  const DoctakAppLoader.compact({super.key, this.repeat = true, this.asset})
      : size = DoctakAppLoaderConfig.inlineSize;

  const DoctakAppLoader.page({super.key, this.repeat = true, this.asset})
      : size = DoctakAppLoaderConfig.pageSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        asset ?? DoctakAppLoaderConfig.lottieAsset,
        fit: BoxFit.contain,
        repeat: repeat,
        frameRate: FrameRate.max,
      ),
    );
  }
}

/// Full-page / section centered loader with optional caption.
class DoctakCenterLoader extends StatelessWidget {
  final String? message;

  const DoctakCenterLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DoctakAppLoader.page(),
          if (message != null && message!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Poppins',
                color: theme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Transparent full-screen overlay content — logo only, no card background.
/// Pair with [showDialog] and [DoctakAppLoaderConfig.overlayBarrierColor].
class DoctakAppLoaderOverlay extends StatelessWidget {
  final String? title;
  final String? message;
  final double loaderSize;
  final bool canPop;

  const DoctakAppLoaderOverlay({
    super.key,
    this.title,
    this.message,
    this.loaderSize = DoctakAppLoaderConfig.pageSize,
    this.canPop = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox.expand(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DoctakAppLoader(size: loaderSize),
                if (title != null && title!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      title!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (message != null && message!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Card-style loader (optional — use [DoctakAppLoaderOverlay] for full-screen overlays).
class DoctakAppLoaderDialogBody extends StatelessWidget {
  final String? title;
  final String? message;

  const DoctakAppLoaderDialogBody({
    super.key,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const DoctakAppLoader(),
        if (title != null && title!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
              color: theme.textPrimary,
            ),
          ),
        ],
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: theme.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
