import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';
import 'package:flutter/material.dart';

import '../core/network/custom_cache_manager.dart';

/// Enhanced S3 image loader with retry logic, OneUI 8.5 theming, and better error handling
class S3ImageLoader extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int maxRetries;
  final Duration retryDelay;

  const S3ImageLoader({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  _S3ImageLoaderState createState() => _S3ImageLoaderState();
}

class _S3ImageLoaderState extends State<S3ImageLoader> {
  int _retryCount = 0;
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);

    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheManager: CustomCacheManager(),
      httpHeaders: _getS3Headers(),
      placeholder: (context, url) =>
          widget.placeholder ?? _buildDefaultPlaceholder(theme),
      errorWidget: (context, url, error) =>
          _handleError(context, url, error, theme),
    );
  }

  Map<String, String> _getS3Headers() {
    return {
      'User-Agent': 'DocTak-Mobile-App/1.0 (Flutter; iOS/Android)',
      'Accept': 'image/webp,image/apng,image/jpeg,image/png,image/*,*/*;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Pragma': 'no-cache',
      'Expires': '0',
      'x-amz-acl': 'public-read',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
  }

  Widget _buildDefaultPlaceholder(OneUITheme theme) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
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

  Widget _handleError(
    BuildContext context,
    String url,
    dynamic error,
    OneUITheme theme,
  ) {
    debugPrint('\ud83d\udea8 S3ImageLoader error for URL: $url');
    debugPrint('\ud83d\udea8 Error details: $error');

    if (_retryCount < widget.maxRetries && !_isRetrying) {
      _scheduleRetry();
      return _buildRetryingWidget(theme);
    }

    return widget.errorWidget ?? _buildDefaultErrorWidget(theme);
  }

  void _scheduleRetry() {
    _isRetrying = true;
    Future.delayed(widget.retryDelay, () {
      if (mounted) {
        setState(() {
          _retryCount++;
          _isRetrying = false;
        });
      }
    });
  }

  Widget _buildRetryingWidget(OneUITheme theme) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.warning),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Retrying... ($_retryCount/${widget.maxRetries})',
            style: TextStyle(
              fontSize: 12,
              color: theme.warning,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultErrorWidget(OneUITheme theme) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_rounded, color: theme.error, size: 32),
          const SizedBox(height: 4),
          Text(
            'Image failed to load',
            style: TextStyle(
              color: theme.error,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

/// Dio-based image validator for S3 URLs
class S3ImageValidator {
  static final Dio _dio = Dio();

  static Future<bool> validateS3Url(String url) async {
    try {
      debugPrint('\ud83d\udd0d Validating S3 URL: $url');

      final response = await _dio.head(
        url,
        options: Options(
          headers: {
            'User-Agent': 'DocTak-Mobile-App/1.0 (Flutter; iOS/Android)',
            'Accept': '*/*',
          },
          followRedirects: true,
          validateStatus: (status) => status! < 500,
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      debugPrint('\ud83d\udd0d S3 validation response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('\ud83d\udea8 S3 validation error: $e');
      return false;
    }
  }
}
