import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Centralized helper for media/gallery (photos) permission handling.
/// Returns true if the app can proceed to show the gallery picker.
/// Handles iOS limited access as allowed and consolidates Android SDK nuances.
class PermissionUtils {
  static Future<bool> ensurePhotoPermission({
    bool requestIfDenied = true,
  }) async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.status;
        if (status.isGranted || status.isLimited) return true; // OK already

        if ((status.isDenied || status.isRestricted) && requestIfDenied) {
          final result = await Permission.photos.request();
          if (result.isGranted || result.isLimited) return true;
        }

        // Only treat permanentlyDenied as a hard false requiring settings.
        if (status.isPermanentlyDenied) return false;

        // Re-check final state (covers undetermined edge cases)
        final finalStatus = await Permission.photos.status;
        return finalStatus.isGranted || finalStatus.isLimited;
      } else {
        // ANDROID
        final deviceInfo = DeviceInfoPlugin();
        final android = await deviceInfo.androidInfo;
        final sdk = android.version.sdkInt;

        if (sdk >= 34) {
          // Android 14+: photos (read media visual user selected subset)
          final status = await Permission.photos.status;
          if (status.isGranted || status.isLimited) return true;
          if (status.isDenied && requestIfDenied) {
            final result = await Permission.photos.request();
            return result.isGranted || result.isLimited;
          }
          return false;
        } else if (sdk >= 33) {
          // Android 13 granular media permissions – using photos
          final status = await Permission.photos.status;
          if (status.isGranted || status.isLimited) return true;
          if (status.isDenied && requestIfDenied) {
            final result = await Permission.photos.request();
            return result.isGranted || result.isLimited;
          }
          return false;
        } else if (sdk >= 30) {
          final status = await Permission.storage.status;
          if (status.isGranted) return true;
          if (status.isDenied && requestIfDenied) {
            final result = await Permission.storage.request();
            return result.isGranted;
          }
          return false;
        } else {
          final status = await Permission.storage.status;
          if (status.isGranted) return true;
          if (status.isDenied && requestIfDenied) {
            final result = await Permission.storage.request();
            return result.isGranted;
          }
          return false;
        }
      }
    } catch (e) {
      // On any unexpected error, fail safe by returning false (caller may show rationale)
      // ignore: avoid_print
      print('ensurePhotoPermission error: $e');
      return false;
    }
  }
}
