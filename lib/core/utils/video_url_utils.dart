import 'dart:io';

import 'package:doctak_app/core/utils/app/AppData.dart';

/// Normalizes remote video URLs and provides HTTP headers for CDN/R2 playback.
class VideoUrlUtils {
  VideoUrlUtils._();

  static const Map<String, String> defaultHeaders = {
    'User-Agent': 'DocTak-Mobile-App/1.0 (Flutter; iOS/Android)',
    'Accept': 'video/mp4,video/quicktime,video/*,*/*;q=0.8',
    'Connection': 'keep-alive',
  };

  /// Resolves legacy S3 paths and relative keys onto the R2 media base.
  static String resolveUrl(String raw) => AppData.fullImageUrl(raw);

  /// Builds a safe [Uri] for [VideoPlayerController.networkUrl].
  static Uri resolveUri(String raw) {
    final normalized = resolveUrl(raw.trim());
    if (normalized.isEmpty) {
      throw ArgumentError('Empty video URL');
    }

    var uri = Uri.tryParse(normalized);
    if (uri == null) {
      uri = Uri.tryParse(Uri.encodeFull(normalized));
    }
    if (uri == null) {
      throw FormatException('Invalid video URL: $normalized');
    }

    if (uri.path.contains(' ')) {
      final encodedPath =
          '/${uri.pathSegments.map(Uri.encodeComponent).join('/')}';
      uri = uri.replace(path: encodedPath);
    }

    return uri;
  }

  /// iOS AVPlayer cannot play these container formats natively.
  static bool isIosUnsupportedFormat(String url) {
    if (!Platform.isIOS) return false;
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.webm') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.flv') ||
        lower.endsWith('.ogv');
  }
}
