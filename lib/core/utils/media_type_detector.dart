/// Utility class for detecting media types from URLs
class MediaTypeDetector {
  // Comprehensive list of image extensions
  static const List<String> imageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico', 
    '.tiff', '.tif', '.heic', '.heif', '.avif', '.raw', '.psd', '.ai',
    '.eps', '.pdf', '.jfif', '.pjpeg', '.pjp', '.apng', '.jxl'
  ];

  // Comprehensive list of video extensions
  static const List<String> videoExtensions = [
    '.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v', 
    '.3gp', '.ogv', '.mpeg', '.mpg', '.ts', '.mts', '.m2ts', '.vob',
    '.asf', '.rm', '.rmvb', '.divx', '.f4v', '.swf', '.3g2', '.mxf',
    '.dv', '.gxf', '.m2v', '.qt'
  ];

  /// Detects if a URL is an image
  static bool isImage(String url) {
    final lowerUrl = _cleanUrl(url);
    return imageExtensions.any((ext) => lowerUrl.endsWith(ext));
  }

  /// Detects if a URL is a video
  static bool isVideo(String url) {
    final lowerUrl = _cleanUrl(url);
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext));
  }

  /// Clean URL by removing query parameters for extension detection
  static String _cleanUrl(String url) {
    final lowerUrl = url.toLowerCase();
    // Remove query parameters for accurate extension detection
    final queryIndex = lowerUrl.indexOf('?');
    if (queryIndex != -1) {
      return lowerUrl.substring(0, queryIndex);
    }
    return lowerUrl;
  }

  /// Gets the media type as a string
  static String getMediaType(String url) {
    if (isVideo(url)) return 'video';
    if (isImage(url)) return 'image';

    // Check URL patterns for media type hints
    final lowerUrl = url.toLowerCase();
    
    // Video indicators in URL
    if (lowerUrl.contains('/video/') || 
        lowerUrl.contains('video_') || 
        lowerUrl.contains('_video') ||
        lowerUrl.contains('/stream/') ||
        lowerUrl.contains('stream_')) {
      return 'video';
    }
    
    // Image indicators in URL
    if (lowerUrl.contains('/image/') || 
        lowerUrl.contains('/photo/') ||
        lowerUrl.contains('/picture/') ||
        lowerUrl.contains('image_') ||
        lowerUrl.contains('_image') ||
        lowerUrl.contains('photo_') ||
        lowerUrl.contains('_photo')) {
      return 'image';
    }

    return 'image'; // Default fallback
  }

  /// Validates if the media type matches the URL
  static bool validateMediaType(String url, String declaredType) {
    final detectedType = getMediaType(url);
    return detectedType == declaredType;
  }

  /// Gets a human-readable file extension
  static String getFileExtension(String url) {
    final cleanedUrl = _cleanUrl(url);
    final uri = Uri.tryParse(cleanedUrl);
    if (uri == null) return 'unknown';

    final path = uri.path.toLowerCase();
    final lastDot = path.lastIndexOf('.');

    if (lastDot == -1) return 'unknown';

    return path.substring(lastDot);
  }
  
  /// Check if the format is supported for display
  static bool isSupportedFormat(String url) {
    return isImage(url) || isVideo(url);
  }
}
