/// Utility class for detecting media types from URLs
class MediaTypeDetector {
  static const List<String> imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg', '.ico', '.tiff', '.tif'];

  static const List<String> videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v', '.3gp', '.ogv'];

  /// Detects if a URL is an image
  static bool isImage(String url) {
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.endsWith(ext));
  }

  /// Detects if a URL is a video
  static bool isVideo(String url) {
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext));
  }

  /// Gets the media type as a string
  static String getMediaType(String url) {
    if (isVideo(url)) return 'video';
    if (isImage(url)) return 'image';

    // If we can't determine from extension, assume image for safety
    // unless it explicitly contains video indicators
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('video') || lowerUrl.contains('stream')) {
      return 'video';
    }

    return 'image'; // Default fallback
  }

  /// Validates if the media type matches the URL
  static bool validateMediaType(String url, String declaredType) {
    final detectedType = getMediaType(url);

    if (detectedType != declaredType) {
      print('⚠️ Media type mismatch for URL: $url');
      print('🔍 Declared type: $declaredType');
      print('🔍 Detected type: $detectedType');
      return false;
    }

    return true;
  }

  /// Gets a human-readable file extension
  static String getFileExtension(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'unknown';

    final path = uri.path.toLowerCase();
    final lastDot = path.lastIndexOf('.');

    if (lastDot == -1) return 'unknown';

    return path.substring(lastDot);
  }
}
