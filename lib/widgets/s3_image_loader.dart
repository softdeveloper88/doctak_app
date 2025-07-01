import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// Enhanced S3 image loader with retry logic and better error handling
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
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      httpHeaders: _getS3Headers(),
      placeholder: (context, url) => widget.placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => _handleError(context, url, error),
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
      // S3 specific headers
      'x-amz-acl': 'public-read',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, HEAD, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    };
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }

  Widget _handleError(BuildContext context, String url, dynamic error) {
    print('🚨 S3ImageLoader error for URL: $url');
    print('🚨 Error details: $error');
    print('🚨 Error type: ${error.runtimeType}');
    print('🚨 Retry count: $_retryCount');

    // If we haven't exceeded max retries and not already retrying
    if (_retryCount < widget.maxRetries && !_isRetrying) {
      _scheduleRetry();
      return _buildRetryingWidget();
    }

    // If we've exceeded retries, show final error
    return widget.errorWidget ?? _buildDefaultErrorWidget();
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

  Widget _buildRetryingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.orange[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Retrying... ($_retryCount/${widget.maxRetries})',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.red[50],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            color: Colors.red,
            size: 32,
          ),
          SizedBox(height: 4),
          Text(
            'Image failed to load',
            style: TextStyle(
              color: Colors.red,
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
      print('🔍 Validating S3 URL: $url');
      
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
      
      print('🔍 S3 validation response: ${response.statusCode}');
      print('🔍 S3 headers: ${response.headers.map}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('🚨 S3 validation error: $e');
      return false;
    }
  }
}