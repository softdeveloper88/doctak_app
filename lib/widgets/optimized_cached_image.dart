import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctak_app/core/network/enhanced_image_cache_manager.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

/// Optimized cached image widget for posts
/// Features:
/// - Uses PostImageCacheManager for 14-day caching
/// - Memory-efficient with configurable cache dimensions
/// - Smooth loading animations
/// - Error handling with retry capability
class OptimizedPostImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool useMemoryCache;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final VoidCallback? onTap;
  final bool showLoadingIndicator;
  
  const OptimizedPostImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.useMemoryCache = true,
    this.memCacheWidth,
    this.memCacheHeight,
    this.onTap,
    this.showLoadingIndicator = true,
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

    // Handle invalid URLs
    if (safeUrl.isEmpty || safeUrl.toLowerCase() == 'null') {
      return _buildErrorWidget(theme);
    }

    Widget image = CachedNetworkImage(
      imageUrl: safeUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: PostImageCacheManager(),
      httpHeaders: defaultHeaders,
      // Memory cache optimization
      memCacheWidth: useMemoryCache ? memCacheWidth : null,
      memCacheHeight: useMemoryCache ? memCacheHeight : null,
      // Smooth fade animation
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      // Placeholder
      placeholder: showLoadingIndicator
          ? (context, url) => _buildPlaceholder(theme)
          : null,
      // Error widget
      errorWidget: (context, url, error) => _buildErrorWidget(theme),
      // Image builder for optional border radius
      imageBuilder: borderRadius != null
          ? (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: fit,
                  ),
                ),
              )
          : null,
    );

    if (onTap != null) {
      image = GestureDetector(
        onTap: onTap,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder(OneUITheme theme) {
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

  Widget _buildErrorWidget(OneUITheme theme) {
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

/// Optimized cached image widget for profile pictures
/// Features:
/// - Uses ProfileImageCacheManager for 60-day caching
/// - Circular avatar support
/// - Placeholder initials
class OptimizedProfileImage extends StatelessWidget {
  final String imageUrl;
  final double size;
  final String? initials;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  
  const OptimizedProfileImage({
    super.key,
    required this.imageUrl,
    this.size = 40,
    this.initials,
    this.backgroundColor,
    this.onTap,
  });

  static const Map<String, String> defaultHeaders = {
    'User-Agent': 'DocTak-Mobile-App/1.0 (Flutter; iOS/Android)',
    'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
  };

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    final safeUrl = imageUrl.trim();

    // Handle invalid URLs
    if (safeUrl.isEmpty || safeUrl.toLowerCase() == 'null') {
      return _buildFallbackAvatar(theme);
    }

    Widget avatar = CachedNetworkImage(
      imageUrl: safeUrl,
      width: size,
      height: size,
      cacheManager: ProfileImageCacheManager(),
      httpHeaders: defaultHeaders,
      // Smaller memory cache for profiles
      memCacheWidth: (size * 2).toInt(),
      memCacheHeight: (size * 2).toInt(),
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: const Duration(milliseconds: 150),
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: size / 2,
        backgroundImage: imageProvider,
        backgroundColor: backgroundColor ?? theme.surfaceVariant,
      ),
      placeholder: (context, url) => _buildFallbackAvatar(theme),
      errorWidget: (context, url, error) => _buildFallbackAvatar(theme),
    );

    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildFallbackAvatar(OneUITheme theme) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? theme.surfaceVariant,
      child: initials != null
          ? Text(
              initials!.toUpperCase(),
              style: TextStyle(
                color: theme.primary,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
              ),
            )
          : Icon(
              Icons.person,
              color: theme.textTertiary,
              size: size * 0.5,
            ),
    );
  }
}

/// Widget to preload images for smooth scrolling
/// Use in ListView.builder or similar for prefetching
class ImagePreloader extends StatefulWidget {
  final List<String> imageUrls;
  final Widget child;
  
  const ImagePreloader({
    super.key,
    required this.imageUrls,
    required this.child,
  });

  @override
  State<ImagePreloader> createState() => _ImagePreloaderState();
}

class _ImagePreloaderState extends State<ImagePreloader> {
  @override
  void initState() {
    super.initState();
    _preloadImages();
  }

  Future<void> _preloadImages() async {
    await ImageCacheUtils.preloadImages(widget.imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
