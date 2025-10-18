import 'package:doctak_app/core/utils/gallery_permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized helper for media/gallery (photos) permission handling.
/// Returns true if the app can proceed to show the gallery picker.
/// Handles iOS limited access as allowed and consolidates Android SDK nuances.
class PermissionUtils {
  /// Quick check and request for photo permission
  /// Returns true if permission is granted
  static Future<bool> ensurePhotoPermission({
    bool requestIfDenied = true,
  }) async {
    try {
      final handler = GalleryPermissionHandler();

      // If just checking without requesting
      if (!requestIfDenied) {
        return await handler.isGranted();
      }

      // Check if already granted
      if (await handler.isGranted()) {
        return true;
      }

      // Request permission
      final result = await handler.requestPermission();
      return result == GalleryPermissionResult.granted;
    } catch (e) {
      debugPrint('ensurePhotoPermission error: $e');
      return false;
    }
  }

  /// Request gallery permission with full UI handling
  /// Shows dialogs and handles all edge cases professionally
  static Future<bool> requestGalleryPermissionWithUI(
    BuildContext context, {
    bool showRationale = false,
    String? title,
    String? message,
  }) async {
    final handler = GalleryPermissionHandler();

    if (showRationale) {
      return await handler.requestWithUI(
        context,
        showRationale: true,
        rationaleTitle: title,
        rationaleMessage: message,
      );
    } else {
      return await handler.requestQuick(context);
    }
  }

  /// Check if gallery permission is granted without requesting
  static Future<bool> isGalleryPermissionGranted() async {
    return await GalleryPermissionHandler().isGranted();
  }

  /// Show permission denied dialog with option to open settings
  static Future<void> showGalleryPermissionDeniedDialog(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    await GalleryPermissionHandler().showPermissionDeniedDialog(
      context,
      title: title,
      message: message,
    );
  }

  /// Request camera permission
  static Future<bool> ensureCameraPermission({
    bool requestIfDenied = true,
  }) async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted) return true;

      if (requestIfDenied && status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      }

      return false;
    } catch (e) {
      debugPrint('ensureCameraPermission error: $e');
      return false;
    }
  }

  /// Request camera permission with UI handling
  static Future<bool> requestCameraPermissionWithUI(
    BuildContext context,
  ) async {
    try {
      if (await Permission.camera.isGranted) {
        return true;
      }

      final result = await Permission.camera.request();

      if (result.isGranted) {
        return true;
      }

      if (result.isPermanentlyDenied && context.mounted) {
        await _showCameraPermissionDeniedDialog(context);
      } else if (result.isDenied && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Camera access denied. Please allow to continue.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      return false;
    } catch (e) {
      debugPrint('requestCameraPermissionWithUI error: $e');
      return false;
    }
  }

  static Future<void> _showCameraPermissionDeniedDialog(
    BuildContext context,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.green[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Camera Access Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'To take photos and record videos, please allow camera access in Settings.',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Not Now',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Open Settings',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Request microphone permission
  static Future<bool> ensureMicrophonePermission({
    bool requestIfDenied = true,
  }) async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) return true;

      if (requestIfDenied && status.isDenied) {
        final result = await Permission.microphone.request();
        return result.isGranted;
      }

      return false;
    } catch (e) {
      debugPrint('ensureMicrophonePermission error: $e');
      return false;
    }
  }

  /// Request multiple permissions for video recording (camera + microphone)
  static Future<bool> ensureVideoRecordingPermissions({
    bool requestIfDenied = true,
  }) async {
    final cameraGranted = await ensureCameraPermission(
      requestIfDenied: requestIfDenied,
    );
    final microphoneGranted = await ensureMicrophonePermission(
      requestIfDenied: requestIfDenied,
    );

    return cameraGranted && microphoneGranted;
  }
}
