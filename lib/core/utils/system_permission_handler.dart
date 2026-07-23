import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';

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
    final theme = OneUITheme.of(context);
    
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: theme.cardBackground,
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24),

                  // Header Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.layers_rounded,
                      color: theme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Display Over Other Apps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: theme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'DocTak needs permission to display over other apps for:',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontFamily: 'Poppins',
                        color: theme.textSecondary,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Features List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildFeatureItem(
                          theme,
                          Icons.picture_in_picture_alt_rounded,
                          'Picture-in-Picture mode during video calls',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureItem(
                          theme,
                          Icons.call_rounded,
                          'Incoming call notifications',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureItem(
                          theme,
                          Icons.stay_current_portrait_rounded,
                          'Keep calls active while using other apps',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.warning.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: theme.warning,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You\'ll be redirected to Settings to enable this permission.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontFamily: 'Poppins',
                                color: theme.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              side: BorderSide(color: theme.border, width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.transparent,
                            ),
                            child: Text(
                              'Not Now',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  /// Show dialog when overlay permission is denied
  Future<void> _showOverlayPermissionDeniedDialog(BuildContext context) async {
    final theme = OneUITheme.of(context);
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.cardBackground,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),

              // Header Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.warning.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.warning.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.settings_rounded,
                  color: theme.warning,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Permission Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: theme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'To enable Picture-in-Picture mode and call features:',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontFamily: 'Poppins',
                    color: theme.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Steps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildStep(theme, 1, 'Open Settings'),
                    const SizedBox(height: 10),
                    _buildStep(theme, 2, 'Find "DocTak" in the app list'),
                    const SizedBox(height: 10),
                    _buildStep(theme, 3, 'Enable "Display over other apps"'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: BorderSide(color: theme.border, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        child: Text(
                          'Maybe Later',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          openAppSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Open Settings',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(OneUITheme theme, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: theme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontFamily: 'Poppins',
                color: theme.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(OneUITheme theme, int step, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.warning.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.warning,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontFamily: 'Poppins',
                color: theme.textSecondary,
                height: 1.35,
              ),
            ),
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
