import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

import '../core/network/custom_cache_manager.dart';

/// A wrapper around CachedNetworkImage with OneUI 8.5 theming and custom cache manager
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
    'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
  };

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final safeUrl = imageUrl.trim();

    // Avoid throwing/stream errors for empty or obviously invalid URLs.
    if (safeUrl.isEmpty || safeUrl.toLowerCase() == 'null') {
      return (errorWidget ??
          (ctx, url, err) => _defaultErrorWidget(ctx, url, err, theme))(
        context,
        safeUrl,
        'Empty/invalid image url',
      );
    }

    return CachedNetworkImage(
      imageUrl: safeUrl,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      cacheManager: CustomCacheManager(),
      httpHeaders: httpHeaders ?? defaultHeaders,
      placeholder:
          placeholder ?? (ctx, url) => _defaultPlaceholder(ctx, url, theme),
      errorWidget:
          errorWidget ??
          (ctx, url, err) => _defaultErrorWidget(ctx, url, err, theme),
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
  }

  Widget _defaultPlaceholder(
    BuildContext context,
    String url,
    OneUITheme theme,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        ),
      ),
    );
  }

  Widget _defaultErrorWidget(
    BuildContext context,
    String url,
    dynamic error,
    OneUITheme theme,
  ) {
    debugPrint('\ud83d\udea8 AppCachedNetworkImage error for URL: $url');
    debugPrint('\ud83d\udea8 Error: $error');

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: theme.textTertiary,
          size: 32,
        ),
      ),
    );
  }
}

/// Extension to easily use CachedNetworkImageProvider with our custom cache manager
class AppCachedNetworkImageProvider extends CachedNetworkImageProvider {
  AppCachedNetworkImageProvider(
    String url, {
    Map<String, String>? headers,
    int? maxWidth,
    int? maxHeight,
  }) : super(
         url.trim(),
         headers: headers ?? AppCachedNetworkImage.defaultHeaders,
         cacheManager: CustomCacheManager(),
         maxWidth: maxWidth,
         maxHeight: maxHeight,
       );
}
