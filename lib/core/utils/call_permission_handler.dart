import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(widget.isVideoCall ? Icons.videocam_rounded : Icons.mic_rounded, color: Colors.blue.shade600, size: 30),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.isVideoCall ? 'Camera & Microphone Access' : 'Microphone Access',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              widget.isVideoCall ? 'Enable the following permissions to join the video call' : 'Enable microphone access to join the call',
              style: TextStyle(fontSize: 13, fontFamily: 'Poppins', color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Permission Switches
            if (_isLoading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CupertinoActivityIndicator())
            else ...[
              // Microphone Permission
              _buildPermissionRow(
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

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Colors.grey[700]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _allRequiredPermissionsGranted ? _onContinue : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue.shade600,
                      disabledBackgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.grey.shade500,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      _allRequiredPermissionsGranted ? 'Continue' : 'Enable All',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow({required IconData icon, required String title, required String subtitle, required bool isEnabled, required bool needsSettings, required VoidCallback onTap}) {
    return InkWell(
      onTap: isEnabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.green.shade50
              : needsSettings
              ? Colors.orange.shade50
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? Colors.green.shade200
                : needsSettings
                ? Colors.orange.shade200
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEnabled
                    ? Colors.green.shade100
                    : needsSettings
                    ? Colors.orange.shade100
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isEnabled
                    ? Colors.green.shade600
                    : needsSettings
                    ? Colors.orange.shade600
                    : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: needsSettings ? Colors.orange.shade600 : Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Switch/Status Indicator
            if (_isRequesting && !isEnabled)
              const SizedBox(width: 24, height: 24, child: CupertinoActivityIndicator())
            else if (needsSettings && !isEnabled)
              Icon(Icons.settings, color: Colors.orange.shade600, size: 24)
            else
              CupertinoSwitch(value: isEnabled, activeTrackColor: Colors.green.shade500, onChanged: isEnabled ? null : (_) => onTap()),
          ],
        ),
      ),
    );
  }
}

/// Global instance for easy access
final callPermissionHandler = CallPermissionHandler();
