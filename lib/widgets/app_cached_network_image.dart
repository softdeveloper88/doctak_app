import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

import '../core/network/custom_cache_manager.dart';

/// A wrapper around CachedNetworkImage with OneUI 8.5 theming and custom cache manager.
///
/// Applies bitmap downsampling via [memCacheWidth]/[memCacheHeight] whenever
/// layout size is known (Play Console: decode at display size, not full resolution).
class AppCachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Color? color;
  final BlendMode? colorBlendMode;
  final Map<String, String>? httpHeaders;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final ImageWidgetBuilder? imageBuilder;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;
  final Alignment alignment;
  final ImageRepeat repeat;
  final bool matchTextDirection;
  final FilterQuality filterQuality;
  final BorderRadius? borderRadius;

  /// Cap decode dimensions so a full-bleed image still downsamples on large phones.
  static const int maxDecodePx = 2048;

  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.color,
    this.colorBlendMode,
    this.httpHeaders,
    this.memCacheWidth,
    this.memCacheHeight,
    this.imageBuilder,
    this.progressIndicatorBuilder,
    this.fadeInDuration,
    this.fadeOutDuration,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.filterQuality = FilterQuality.low,
    this.borderRadius,
  });

  static const Map<String, String> defaultHeaders = {
    'User-Agent': 'DocTak-Mobile-App/1.0 (Flutter; iOS/Android)',
    'Accept': 'image/webp,image/apng,image/jpeg,image/png,image/*,*/*;q=0.8',
  };

  static int? decodePx(double? logical, double devicePixelRatio) {
    if (logical == null || !logical.isFinite || logical <= 0) return null;
    return (logical * devicePixelRatio).round().clamp(1, maxDecodePx);
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final safeUrl = AppData.fullImageUrl(imageUrl);
    final onError = errorWidget ??
        (BuildContext ctx, String url, dynamic err) =>
            _defaultErrorWidget(ctx, url, err, theme);

    if (!AppData.isValidHttpImageUrl(safeUrl)) {
      return onError(context, safeUrl, 'Empty/invalid image url');
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final explicitW = memCacheWidth ?? decodePx(width, dpr);
    final explicitH = memCacheHeight ?? decodePx(height, dpr);

    // When width/height aren't fixed, resolve from parent constraints so we
    // still downsample (avoids full-res decode into ImageCache).
    if (explicitW == null && explicitH == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cacheW = decodePx(
            constraints.maxWidth.isFinite ? constraints.maxWidth : null,
            dpr,
          );
          final cacheH = decodePx(
            constraints.maxHeight.isFinite ? constraints.maxHeight : null,
            dpr,
          );
          return _buildImage(
            context,
            theme: theme,
            safeUrl: safeUrl,
            onError: onError,
            memCacheWidth: cacheW,
            memCacheHeight: cacheH,
          );
        },
      );
    }

    return _buildImage(
      context,
      theme: theme,
      safeUrl: safeUrl,
      onError: onError,
      memCacheWidth: explicitW,
      memCacheHeight: explicitH,
    );
  }

  Widget _buildImage(
    BuildContext context, {
    required OneUITheme theme,
    required String safeUrl,
    required Widget Function(BuildContext, String, dynamic) onError,
    required int? memCacheWidth,
    required int? memCacheHeight,
  }) {
    final image = CachedNetworkImage(
      imageUrl: safeUrl,
      cacheKey: safeUrl,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      cacheManager: CustomCacheManager(),
      // Bearer token is attached for DocTak hosts only (private media such
      // as chat attachments requires an authenticated request).
      httpHeaders: AppData.mediaHeadersFor(safeUrl, baseHeaders: httpHeaders ?? defaultHeaders),
      placeholder: placeholder ?? (ctx, url) => _defaultPlaceholder(ctx, url, theme),
      errorWidget: onError,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      imageBuilder: imageBuilder,
      progressIndicatorBuilder: progressIndicatorBuilder,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
      fadeOutDuration: fadeOutDuration ?? const Duration(milliseconds: 300),
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      filterQuality: filterQuality,
    );

    return image;
  }

  Widget _defaultPlaceholder(BuildContext context, String url, OneUITheme theme) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: theme.surfaceVariant, borderRadius: borderRadius ?? BorderRadius.circular(8)),
      child: Center(
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.primary))),
      ),
    );
  }

  Widget _defaultErrorWidget(BuildContext context, String url, dynamic error, OneUITheme theme) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: theme.surfaceVariant, borderRadius: borderRadius ?? BorderRadius.circular(8)),
      child: Center(child: Icon(Icons.broken_image_rounded, color: theme.textTertiary, size: 32)),
    );
  }
}

/// Extension to easily use CachedNetworkImageProvider with our custom cache manager
class AppCachedNetworkImageProvider extends CachedNetworkImageProvider {
  AppCachedNetworkImageProvider(String url, {Map<String, String>? headers, int? maxWidth, int? maxHeight})
    : super(
        AppData.fullImageUrl(url),
        headers: AppData.mediaHeadersFor(
          AppData.fullImageUrl(url),
          baseHeaders: headers ?? AppCachedNetworkImage.defaultHeaders,
        ),
        cacheManager: CustomCacheManager(),
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
}
