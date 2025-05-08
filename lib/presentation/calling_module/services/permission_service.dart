// lib/presentation/call_module/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

/// Service to handle permission requests
class PermissionService {
  // Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request both permissions
  static Future<Map<Permission, bool>> requestCallPermissions({
    required bool isVideoCall,
  }) async {
    // For audio calls, we only need microphone
    if (!isVideoCall) {
      final micStatus = await Permission.microphone.request();
      return {
        Permission.microphone: micStatus.isGranted,
      };
    }

    // For video calls, we need both
    final Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.camera,
    ].request();

    return {
      Permission.microphone: statuses[Permission.microphone]?.isGranted ?? false,
      Permission.camera: statuses[Permission.camera]?.isGranted ?? false,
    };
  }

  // Check if we have all required permissions
  static Future<bool> hasRequiredPermissions({
    required bool isVideoCall,
  }) async {
    final micStatus = await Permission.microphone.status;

    if (!isVideoCall) {
      return micStatus.isGranted;
    }

    final camStatus = await Permission.camera.status;
    return micStatus.isGranted && camStatus.isGranted;
  }

  // Open app settings
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}