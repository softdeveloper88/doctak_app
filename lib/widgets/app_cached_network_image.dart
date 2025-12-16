import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/network/custom_cache_manager.dart';

/// A wrapper around CachedNetworkImage that uses our custom cache manager
/// with certificate bypass for release mode compatibility.
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
  });

  static const Map<String, String> defaultHeaders = {
    'User-Agent': 'DocTak-Mobile-App/1.0 (Flutter; iOS/Android)',
    'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    'Accept-Encoding': 'gzip, deflate, br',
    'Connection': 'keep-alive',
  };

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      cacheManager: CustomCacheManager(),
      httpHeaders: httpHeaders ?? defaultHeaders,
      placeholder: placeholder ?? _defaultPlaceholder,
      errorWidget: errorWidget ?? _defaultErrorWidget,
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

  Widget _defaultPlaceholder(BuildContext context, String url) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _defaultErrorWidget(BuildContext context, String url, dynamic error) {
    debugPrint('🚨 AppCachedNetworkImage error for URL: $url');
    debugPrint('🚨 Error: $error');
    
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: Colors.grey,
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
          url,
          headers: headers ?? AppCachedNetworkImage.defaultHeaders,
          cacheManager: CustomCacheManager(),
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        );
}
