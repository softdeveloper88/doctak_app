import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'custom_cache_manager.dart';
import 'package:doctak_app/core/utils/video_url_utils.dart';

/// Disk cache for remote videos — used as an iOS fallback when streaming fails.
class VideoCacheManager extends CacheManager {
  static const key = 'doctakVideoCache';

  static VideoCacheManager? _instance;

  factory VideoCacheManager() {
    _instance ??= VideoCacheManager._();
    return _instance!;
  }

  VideoCacheManager._()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 14),
            maxNrOfCacheObjects: 40,
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(httpClient: CustomHttpClient()),
          ),
        );

  Future<File> getVideoFile(String url) async {
    final resolved = VideoUrlUtils.resolveUrl(url);
    return getSingleFile(
      resolved,
      headers: VideoUrlUtils.defaultHeaders,
    );
  }
}
