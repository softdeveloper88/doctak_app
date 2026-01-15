import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:doctak_app/theme/one_ui_theme.dart';

/// Result of a call permission request
enum CallPermissionResult {
  /// All required permissions granted
  granted,

  /// Some permissions denied but can be requested again
  denied,

  /// Some permissions permanently denied - user needs to go to settings
  permanentlyDenied,

  /// Permission restricted (e.g., parental controls on iOS)
  restricted,

  /// An error occurred
  error,
}

/// Detailed permission status for call permissions
class CallPermissionStatus {
  final bool microphoneGranted;
  final bool cameraGranted;
  final bool microphonePermanentlyDenied;
  final bool cameraPermanentlyDenied;

  CallPermissionStatus({required this.microphoneGranted, required this.cameraGranted, required this.microphonePermanentlyDenied, required this.cameraPermanentlyDenied});

  bool get allGranted => microphoneGranted && cameraGranted;
  bool get audioCallGranted => microphoneGranted;
  bool get videoCallGranted => microphoneGranted && cameraGranted;
  bool get anyPermanentlyDenied => microphonePermanentlyDenied || cameraPermanentlyDenied;

  List<String> get deniedPermissions {
    final denied = <String>[];
    if (!microphoneGranted) denied.add('Microphone');
    if (!cameraGranted) denied.add('Camera');
    return denied;
  }

  List<String> get permanentlyDeniedPermissions {
    final denied = <String>[];
    if (microphonePermanentlyDenied) denied.add('Microphone');
    if (cameraPermanentlyDenied) denied.add('Camera');
    return denied;
  }
}

/// Professional call permission handler for iOS and Android
/// Handles microphone and camera permissions with smooth user experience
class CallPermissionHandler {
  static final CallPermissionHandler _instance = CallPermissionHandler._internal();

  factory CallPermissionHandler() => _instance;

  CallPermissionHandler._internal();

  /// Check if all required call permissions are granted
  Future<bool> hasCallPermissions({required bool isVideoCall}) async {
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) return false;

      if (isVideoCall) {
        final camStatus = await Permission.camera.status;
        if (!camStatus.isGranted) return false;
      }

      return true;
    } catch (e) {
      debugPrint('CallPermissionHandler.hasCallPermissions error: $e');
      return false;
    }
  }

  /// Get detailed permission status
  Future<CallPermissionStatus> getPermissionStatus({required bool isVideoCall}) async {
    try {
      final micStatus = await Permission.microphone.status;
      final camStatus = isVideoCall ? await Permission.camera.status : PermissionStatus.granted;

      return CallPermissionStatus(
        microphoneGranted: micStatus.isGranted,
        cameraGranted: isVideoCall ? camStatus.isGranted : true,
        microphonePermanentlyDenied: micStatus.isPermanentlyDenied,
        cameraPermanentlyDenied: isVideoCall ? camStatus.isPermanentlyDenied : false,
      );
    } catch (e) {
      debugPrint('CallPermissionHandler.getPermissionStatus error: $e');
      return CallPermissionStatus(microphoneGranted: false, cameraGranted: false, microphonePermanentlyDenied: false, cameraPermanentlyDenied: false);
    }
  }

  /// Request a single permission
  Future<bool> requestSinglePermission(Permission permission) async {
    try {
      final status = await permission.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('CallPermissionHandler.requestSinglePermission error: $e');
      return false;
    }
  }

  /// Check if a permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  /// Show the permission status dialog with switches
  /// This is the main entry point for permission handling
  Future<CallPermissionResult> showPermissionStatusDialog(BuildContext context, {required bool isVideoCall}) async {
    // First check if already granted
    if (await hasCallPermissions(isVideoCall: isVideoCall)) {
      return CallPermissionResult.granted;
    }

    if (!context.mounted) return CallPermissionResult.error;

    // Show the permission status dialog
    final result = await showDialog<CallPermissionResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _PermissionStatusDialog(isVideoCall: isVideoCall, handler: this),
    );

    return result ?? CallPermissionResult.denied;
  }

  /// Show in-call permission dialog (when already in call/meeting screen)
  Future<CallPermissionResult> showInCallPermissionDialog(BuildContext context, {required bool isVideoCall}) async {
    return showPermissionStatusDialog(context, isVideoCall: isVideoCall);
  }

  /// Request permissions with full UI handling
  Future<bool> requestWithUI(BuildContext context, {required bool isVideoCall, bool showRationale = true}) async {
    // Check if already granted
    if (await hasCallPermissions(isVideoCall: isVideoCall)) {
      return true;
    }

    if (!context.mounted) return false;

    final result = await showPermissionStatusDialog(context, isVideoCall: isVideoCall);

    return result == CallPermissionResult.granted;
  }

  /// Quick permission check and request
  Future<bool> requestQuick(BuildContext context, {required bool isVideoCall}) async {
    return await requestWithUI(context, isVideoCall: isVideoCall, showRationale: false);
  }
}

/// Permission Status Dialog Widget with switches
class _PermissionStatusDialog extends StatefulWidget {
  final bool isVideoCall;
  final CallPermissionHandler handler;

  const _PermissionStatusDialog({required this.isVideoCall, required this.handler});

  @override
  State<_PermissionStatusDialog> createState() => _PermissionStatusDialogState();
}

class _PermissionStatusDialogState extends State<_PermissionStatusDialog> {
  bool _microphoneEnabled = false;
  bool _cameraEnabled = false;
  bool _microphoneCanRequest = true; // Can show native iOS dialog
  bool _cameraCanRequest = true; // Can show native iOS dialog
  bool _isLoading = true;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    setState(() => _isLoading = true);

    final micStatus = await Permission.microphone.status;
    final camStatus = await Permission.camera.status;

    if (mounted) {
      setState(() {
        _microphoneEnabled = micStatus.isGranted;
        _cameraEnabled = camStatus.isGranted;
        // On iOS: isDenied means never asked OR denied once (can still show dialog)
        // isPermanentlyDenied means user selected "Don't Allow" - need Settings
        // On iOS 14+, after first denial, status becomes permanentlyDenied
        _microphoneCanRequest = !micStatus.isPermanentlyDenied && !micStatus.isRestricted;
        _cameraCanRequest = !camStatus.isPermanentlyDenied && !camStatus.isRestricted;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestMicrophonePermission() async {
    if (_isRequesting) return;

    setState(() => _isRequesting = true);

    // Check current status first
    final currentStatus = await Permission.microphone.status;

    // If already granted, just update UI
    if (currentStatus.isGranted) {
      if (mounted) {
        setState(() {
          _microphoneEnabled = true;
          _isRequesting = false;
        });
      }
      return;
    }

    // If permanently denied or restricted, go to settings
    if (currentStatus.isPermanentlyDenied || currentStatus.isRestricted) {
      setState(() => _isRequesting = false);
      await _showSettingsDialog('Microphone');
      await _checkPermissionStatus();
      return;
    }

    // Request permission - this will show native iOS dialog if not yet asked
    final status = await Permission.microphone.request();

    if (mounted) {
      setState(() {
        _microphoneEnabled = status.isGranted;
        _microphoneCanRequest = !status.isPermanentlyDenied && !status.isRestricted;
        _isRequesting = false;
      });

      // If became permanently denied after request (user tapped "Don't Allow")
      // Don't automatically show settings - let user tap again if they want
    }
  }

  Future<void> _requestCameraPermission() async {
    if (_isRequesting) return;

    setState(() => _isRequesting = true);

    // Check current status first
    final currentStatus = await Permission.camera.status;

    // If already granted, just update UI
    if (currentStatus.isGranted) {
      if (mounted) {
        setState(() {
          _cameraEnabled = true;
          _isRequesting = false;
        });
      }
      return;
    }

    // If permanently denied or restricted, go to settings
    if (currentStatus.isPermanentlyDenied || currentStatus.isRestricted) {
      setState(() => _isRequesting = false);
      await _showSettingsDialog('Camera');
      await _checkPermissionStatus();
      return;
    }

    // Request permission - this will show native iOS dialog if not yet asked
    final status = await Permission.camera.request();

    if (mounted) {
      setState(() {
        _cameraEnabled = status.isGranted;
        _cameraCanRequest = !status.isPermanentlyDenied && !status.isRestricted;
        _isRequesting = false;
      });

      // If became permanently denied after request (user tapped "Don't Allow")
      // Don't automatically show settings - let user tap again if they want
    }
  }

  Future<void> _showSettingsDialog(String permissionName) async {
    if (!mounted) return;

    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle),
              child: Icon(Icons.settings, color: Colors.orange.shade600, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$permissionName Blocked',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$permissionName access was previously denied. To enable it:',
              style: TextStyle(fontSize: 14, fontFamily: 'Poppins', color: Colors.grey[700], height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildSettingsStep(1, 'Open Settings'),
            const SizedBox(height: 8),
            _buildSettingsStep(2, 'Find DocTak'),
            const SizedBox(height: 8),
            _buildSettingsStep(3, 'Enable $permissionName'),
            const SizedBox(height: 8),
            _buildSettingsStep(4, 'Return to app'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600]),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Open Settings', style: TextStyle(fontFamily: 'Poppins')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (shouldOpenSettings == true) {
      await openAppSettings();
      // Wait a moment then refresh status
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _checkPermissionStatus();
      }
    }
  }

  Widget _buildSettingsStep(int step, String text) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Colors.grey[700]),
        ),
      ],
    );
  }

  bool get _allRequiredPermissionsGranted {
    if (widget.isVideoCall) {
      return _microphoneEnabled && _cameraEnabled;
    }
    return _microphoneEnabled;
  }

  void _onContinue() {
    if (_allRequiredPermissionsGranted) {
      Navigator.pop(context, CallPermissionResult.granted);
    }
  }

  void _onCancel() {
    Navigator.pop(context, CallPermissionResult.denied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = OneUITheme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: EdgeInsets.zero,
      backgroundColor: theme.cardBackground,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),
            
            // Header Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                widget.isVideoCall ? Icons.videocam_rounded : Icons.mic_rounded,
                color: theme.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.isVideoCall ? 'Camera & Microphone\nAccess' : 'Microphone Access',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                  color: theme.textPrimary,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.isVideoCall
                    ? 'Enable the following permissions to join\nthe video call'
                    : 'Enable microphone access to join the call',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: theme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // Permission Switches
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: CupertinoActivityIndicator(color: theme.primary),
                    )
                  : Column(
                      children: [
                        // Microphone Permission
                        _buildPermissionRow(
                          context: context,
                          theme: theme,
                          icon: Icons.mic_rounded,
                          title: 'Microphone',
                          subtitle: !_microphoneCanRequest && !_microphoneEnabled
                              ? 'Tap to open Settings'
                              : _microphoneEnabled
                              ? 'Enabled'
                              : 'Tap to enable',
                          isEnabled: _microphoneEnabled,
                          needsSettings: !_microphoneCanRequest && !_microphoneEnabled,
                          onTap: _requestMicrophonePermission,
                        ),

                        if (widget.isVideoCall) ...[
                          const SizedBox(height: 12),
                          // Camera Permission
                          _buildPermissionRow(
                            context: context,
                            theme: theme,
                            icon: Icons.videocam_rounded,
                            title: 'Camera',
                            subtitle: !_cameraCanRequest && !_cameraEnabled
                                ? 'Tap to open Settings'
                                : _cameraEnabled
                                ? 'Enabled'
                                : 'Tap to enable',
                            isEnabled: _cameraEnabled,
                            needsSettings: !_cameraCanRequest && !_cameraEnabled,
                            onTap: _requestCameraPermission,
                          ),
                        ],
                      ],
                    ),
            ),

            const SizedBox(height: 28),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.border, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _allRequiredPermissionsGranted ? _onContinue : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.primary,
                        disabledBackgroundColor: theme.surfaceVariant,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: theme.textTertiary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Text(
                        _allRequiredPermissionsGranted ? 'Continue' : 'Enable All',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required BuildContext context,
    required OneUITheme theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required bool needsSettings,
    required VoidCallback onTap,
  }) {
    final Color bgColor = isEnabled
        ? theme.success.withValues(alpha: 0.08)
        : needsSettings
        ? theme.warning.withValues(alpha: 0.08)
        : theme.surfaceVariant;
    
    final Color borderColor = isEnabled
        ? theme.success.withValues(alpha: 0.2)
        : needsSettings
        ? theme.warning.withValues(alpha: 0.2)
        : theme.border;
    
    final Color iconBgColor = isEnabled
        ? theme.success.withValues(alpha: 0.15)
        : needsSettings
        ? theme.warning.withValues(alpha: 0.15)
        : theme.iconButtonBg;
    
    final Color iconColor = isEnabled
        ? theme.success
        : needsSettings
        ? theme.warning
        : theme.iconColor;

    return InkWell(
      onTap: isEnabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      color: needsSettings ? theme.warning : theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Switch/Status Indicator - Fixed to prevent scrolling
            SizedBox(
              width: 51,
              height: 31,
              child: _isRequesting && !isEnabled
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CupertinoActivityIndicator(color: theme.primary),
                      ),
                    )
                  : needsSettings && !isEnabled
                  ? Center(child: Icon(Icons.settings_outlined, color: theme.warning, size: 24))
                  : isEnabled
                  // Fixed switch indicator for enabled state - prevents scroll issue
                  ? Container(
                      width: 51,
                      height: 31,
                      decoration: BoxDecoration(
                        color: theme.success,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          width: 27,
                          height: 27,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  // Interactive switch for disabled state
                  : CupertinoSwitch(
                      value: false,
                      activeColor: theme.success,
                      onChanged: (_) => onTap(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Global instance for easy access
final callPermissionHandler = CallPermissionHandler();
