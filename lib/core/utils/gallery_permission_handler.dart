import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Result of a permission request
enum GalleryPermissionResult {
  /// Permission granted (full or limited access)
  granted,

  /// Permission denied but can be requested again
  denied,

  /// Permission permanently denied - user needs to go to settings
  permanentlyDenied,

  /// Permission restricted (e.g., parental controls on iOS)
  restricted,

  /// An error occurred
  error,
}

/// Comprehensive gallery permission handler for iOS and Android
/// Handles:
/// - iOS 14+ Photo Library with limited access support
/// - Android 13+ granular media permissions (READ_MEDIA_IMAGES)
/// - Android 14+ visual user selected permission
/// - Older Android versions with storage permission
class GalleryPermissionHandler {
  static final GalleryPermissionHandler _instance = GalleryPermissionHandler._internal();

  factory GalleryPermissionHandler() => _instance;

  GalleryPermissionHandler._internal();

  /// Cached Android SDK version
  int? _androidSdkVersion;

  /// Get Android SDK version (cached)
  Future<int> _getAndroidSdkVersion() async {
    if (_androidSdkVersion != null) return _androidSdkVersion!;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    _androidSdkVersion = androidInfo.version.sdkInt;
    return _androidSdkVersion!;
  }

  /// Check if gallery permission is granted without requesting
  Future<bool> isGranted() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.status;
        return status.isGranted || status.isLimited;
      } else if (Platform.isAndroid) {
        final sdkVersion = await _getAndroidSdkVersion();

        if (sdkVersion >= 33) {
          // Android 13+ uses granular media permissions
          final status = await Permission.photos.status;
          return status.isGranted || status.isLimited;
        } else {
          // Older Android uses storage permission
          final status = await Permission.storage.status;
          return status.isGranted;
        }
      }
      return false;
    } catch (e) {
      debugPrint('GalleryPermissionHandler.isGranted error: $e');
      return false;
    }
  }

  /// Request gallery permission and return detailed result
  Future<GalleryPermissionResult> requestPermission() async {
    try {
      if (Platform.isIOS) {
        return await _requestIOSPermission();
      } else if (Platform.isAndroid) {
        return await _requestAndroidPermission();
      }
      return GalleryPermissionResult.error;
    } catch (e) {
      debugPrint('GalleryPermissionHandler.requestPermission error: $e');
      return GalleryPermissionResult.error;
    }
  }

  /// Request permission for iOS
  Future<GalleryPermissionResult> _requestIOSPermission() async {
    // First check current status
    PermissionStatus status = await Permission.photos.status;
    debugPrint('iOS Photo Permission initial status: $status');

    // Already granted or limited - both are acceptable for photo library access
    if (status.isGranted || status.isLimited) {
      return GalleryPermissionResult.granted;
    }

    // Permanently denied - user needs to go to settings
    if (status.isPermanentlyDenied) {
      return GalleryPermissionResult.permanentlyDenied;
    }

    // Restricted by system (parental controls, etc.)
    if (status.isRestricted) {
      return GalleryPermissionResult.restricted;
    }

    // Request permission
    status = await Permission.photos.request();
    debugPrint('iOS Photo Permission after request: $status');

    // Check result
    if (status.isGranted || status.isLimited) {
      return GalleryPermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return GalleryPermissionResult.permanentlyDenied;
    }

    if (status.isRestricted) {
      return GalleryPermissionResult.restricted;
    }

    return GalleryPermissionResult.denied;
  }

  /// Request permission for Android based on SDK version
  Future<GalleryPermissionResult> _requestAndroidPermission() async {
    final sdkVersion = await _getAndroidSdkVersion();
    debugPrint('Android SDK version: $sdkVersion');

    if (sdkVersion >= 34) {
      // Android 14+ - Use READ_MEDIA_VISUAL_USER_SELECTED or photos permission
      return await _requestAndroid14Permission();
    } else if (sdkVersion >= 33) {
      // Android 13 - Use granular media permissions (READ_MEDIA_IMAGES)
      return await _requestAndroid13Permission();
    } else {
      // Android 12 and below - Use storage permission
      return await _requestLegacyAndroidPermission();
    }
  }

  /// Request permission for Android 14+
  Future<GalleryPermissionResult> _requestAndroid14Permission() async {
    // First try photos permission (maps to READ_MEDIA_IMAGES)
    PermissionStatus status = await Permission.photos.status;
    debugPrint('Android 14+ Photo Permission initial status: $status');

    if (status.isGranted || status.isLimited) {
      return GalleryPermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return GalleryPermissionResult.permanentlyDenied;
    }

    // Request permission
    status = await Permission.photos.request();
    debugPrint('Android 14+ Photo Permission after request: $status');

    if (status.isGranted || status.isLimited) {
      return GalleryPermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return GalleryPermissionResult.permanentlyDenied;
    }

    return GalleryPermissionResult.denied;
  }

  /// Request permission for Android 13
  Future<GalleryPermissionResult> _requestAndroid13Permission() async {
    PermissionStatus status = await Permission.photos.status;
    debugPrint('Android 13 Photo Permission initial status: $status');

    if (status.isGranted || status.isLimited) {
      return GalleryPermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return GalleryPermissionResult.permanentlyDenied;
    }

    // Request permission
    status = await Permission.photos.request();
    debugPrint('Android 13 Photo Permission after request: $status');

    if (status.isGranted || status.isLimited) {
      return GalleryPermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return GalleryPermissionResult.permanentlyDenied;
    }

    return GalleryPermissionResult.denied;
  }

  /// Request permission for Android 12 and below
  Future<GalleryPermissionResult> _requestLegacyAndroidPermission() async {
    PermissionStatus status = await Permission.storage.status;
    debugPrint('Android Legacy Storage Permission initial status: $status');

    if (status.isGranted) {
      return GalleryPermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return GalleryPermissionResult.permanentlyDenied;
    }

    // Request permission
    status = await Permission.storage.request();
    debugPrint('Android Legacy Storage Permission after request: $status');

    if (status.isGranted) {
      return GalleryPermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return GalleryPermissionResult.permanentlyDenied;
    }

    return GalleryPermissionResult.denied;
  }

  /// Show a professional permission dialog explaining why permission is needed
  /// Returns true if user wants to open settings, false otherwise
  Future<bool> showPermissionDeniedDialog(BuildContext context, {String? title, String? message, String? cancelText, String? settingsText}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.photo_library_rounded, color: Colors.blue[600], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title ?? 'Photo Access Required',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
          content: Text(
            message ?? 'To share photos and images, please allow access to your photo library in Settings.',
            style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Colors.grey[700], height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                cancelText ?? 'Not Now',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                settingsText ?? 'Open Settings',
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await openAppSettings();
    }

    return result ?? false;
  }

  /// Show a rationale dialog before requesting permission
  /// Returns true if user wants to proceed, false otherwise
  Future<bool> showPermissionRationaleDialog(BuildContext context, {String? title, String? message, String? cancelText, String? proceedText}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.photo_library_rounded, color: Colors.blue[600], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title ?? 'Access Your Photos',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message ?? 'DocTak needs access to your photos to share images in posts and messages.',
                style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Colors.grey[700], height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildFeatureRow(Icons.post_add_rounded, 'Share images in posts'),
              const SizedBox(height: 8),
              _buildFeatureRow(Icons.medical_services_outlined, 'Upload medical images for AI analysis'),
              const SizedBox(height: 8),
              _buildFeatureRow(Icons.chat_rounded, 'Send images in messages'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                cancelText ?? 'Cancel',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                proceedText ?? 'Allow Access',
                style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  /// Request gallery permission with full UI handling
  /// Returns true if permission is granted and user can proceed
  Future<bool> requestWithUI(BuildContext context, {bool showRationale = true, String? rationaleTitle, String? rationaleMessage, String? deniedTitle, String? deniedMessage}) async {
    // Check if already granted
    if (await isGranted()) {
      return true;
    }

    // Show rationale dialog first (optional but recommended for better UX)
    if (showRationale) {
      final shouldProceed = await showPermissionRationaleDialog(context, title: rationaleTitle, message: rationaleMessage);

      if (!shouldProceed) {
        return false;
      }
    }

    // Request permission
    final result = await requestPermission();

    switch (result) {
      case GalleryPermissionResult.granted:
        return true;

      case GalleryPermissionResult.denied:
        // Permission denied but can try again
        // Show a toast or snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Photo access denied. Please allow access to continue.', style: TextStyle(fontFamily: 'Poppins')),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () async {
                  await requestPermission();
                },
              ),
            ),
          );
        }
        return false;

      case GalleryPermissionResult.permanentlyDenied:
        // Show dialog to open settings
        if (context.mounted) {
          await showPermissionDeniedDialog(context, title: deniedTitle, message: deniedMessage);
        }
        return false;

      case GalleryPermissionResult.restricted:
        // Permission is restricted by system
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Photo access is restricted on this device.', style: TextStyle(fontFamily: 'Poppins')),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return false;

      case GalleryPermissionResult.error:
        // An error occurred
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('An error occurred while requesting permission.', style: TextStyle(fontFamily: 'Poppins')),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return false;
    }
  }

  /// Quick permission check and request without showing rationale dialog
  /// Best for cases where user explicitly tapped a gallery button
  Future<bool> requestQuick(BuildContext context) async {
    // Check if already granted
    if (await isGranted()) {
      return true;
    }

    // Request permission directly
    final result = await requestPermission();

    switch (result) {
      case GalleryPermissionResult.granted:
        return true;

      case GalleryPermissionResult.denied:
        // Permission denied - show simple feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Photo access denied. Please allow to continue.', style: TextStyle(fontFamily: 'Poppins')),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return false;

      case GalleryPermissionResult.permanentlyDenied:
        // Show dialog to open settings
        if (context.mounted) {
          await showPermissionDeniedDialog(context);
        }
        return false;

      case GalleryPermissionResult.restricted:
      case GalleryPermissionResult.error:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to access photos. Please check your settings.', style: TextStyle(fontFamily: 'Poppins')),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        return false;
    }
  }
}

/// Global instance for easy access
final galleryPermissionHandler = GalleryPermissionHandler();
