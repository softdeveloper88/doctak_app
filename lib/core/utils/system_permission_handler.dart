import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive system-level permission handler
/// Handles special permissions like SYSTEM_ALERT_WINDOW (Draw Over Other Apps)
class SystemPermissionHandler {
  static final SystemPermissionHandler _instance = SystemPermissionHandler._internal();

  factory SystemPermissionHandler() => _instance;

  SystemPermissionHandler._internal();

  /// Check if "Draw Over Other Apps" permission is granted
  /// This is required for PiP (Picture-in-Picture) mode on Android
  Future<bool> hasOverlayPermission() async {
    if (!Platform.isAndroid) return true; // iOS doesn't need this

    try {
      final status = await Permission.systemAlertWindow.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return false;
    }
  }

  /// Request "Draw Over Other Apps" permission with user-friendly dialog
  /// Returns true if permission is granted
  Future<bool> requestOverlayPermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    try {
      // Check if already granted
      if (await hasOverlayPermission()) {
        return true;
      }

      // Show explanation dialog first
      if (context.mounted) {
        final shouldProceed = await _showOverlayPermissionDialog(context);
        if (!shouldProceed) {
          return false;
        }
      }

      // Request permission - this will open Android Settings
      final status = await Permission.systemAlertWindow.request();

      if (status.isGranted) {
        return true;
      }

      // If denied, show how to enable manually
      if (context.mounted && status.isDenied) {
        await _showOverlayPermissionDeniedDialog(context);
      }

      return false;
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
      return false;
    }
  }

  /// Show dialog explaining why overlay permission is needed
  Future<bool> _showOverlayPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.layers_rounded, color: Colors.blue[600], size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Display Over Other Apps',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DocTak needs permission to display over other apps for:',
                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Colors.grey[700], height: 1.5),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.picture_in_picture_alt_rounded, 'Picture-in-Picture mode during video calls'),
                const SizedBox(height: 10),
                _buildFeatureItem(Icons.call_rounded, 'Incoming call notifications'),
                const SizedBox(height: 10),
                _buildFeatureItem(Icons.stay_current_portrait_rounded, 'Keep calls active while using other apps'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You\'ll be redirected to Settings to enable this permission.',
                          style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Colors.amber.shade900, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                child: Text(
                  'Not Now',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Show dialog when overlay permission is denied
  Future<void> _showOverlayPermissionDeniedDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.settings_rounded, color: Colors.orange[600], size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Permission Required',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To enable Picture-in-Picture mode and call features:',
              style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Colors.grey[700], height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildStep(1, 'Open Settings'),
            const SizedBox(height: 8),
            _buildStep(2, 'Find "DocTak" in the app list'),
            const SizedBox(height: 8),
            _buildStep(3, 'Enable "Display over other apps"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
            child: Text(
              'Maybe Later',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(int step, String text) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  /// Quick check and request for overlay permission
  /// Returns true if granted
  Future<bool> ensureOverlayPermission(BuildContext context) async {
    if (await hasOverlayPermission()) {
      return true;
    }

    return await requestOverlayPermission(context);
  }
}

/// Global instance for easy access
final systemPermissionHandler = SystemPermissionHandler();
