import 'package:doctak_app/core/utils/app/AppData.dart';
import 'package:doctak_app/widgets/app_cached_network_image.dart';

/// @deprecated Use [AppCachedNetworkImage] — all media is served via the R2 `/r2-media` proxy.
typedef S3ImageLoader = AppCachedNetworkImage;

/// @deprecated Legacy S3 URL validation is no longer needed.
class S3ImageValidator {
  static Future<bool> validateS3Url(String url) async => AppData.isValidHttpImageUrl(url);
}
