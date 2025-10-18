// lib/presentation/call_module/services/permission_service.dart
import 'dart:io';
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

  // Request notification permission (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    // Only request on Android 13+ (API level 33+)
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    // iOS doesn't need this permission for CallKit
    return true;
  }

  // Check notification permission status
  static Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    // iOS doesn't need this permission for CallKit
    return true;
  }

  // Request all required permissions for calling
  static Future<Map<Permission, bool>> requestCallPermissions({
    required bool isVideoCall,
  }) async {
    List<Permission> permissions = [Permission.microphone];
    
    // Add camera permission for video calls
    if (isVideoCall) {
      permissions.add(Permission.camera);
    }
    
    // Add notification permission for Android 13+
    if (Platform.isAndroid) {
      permissions.add(Permission.notification);
    }

    final Map<Permission, PermissionStatus> statuses = await permissions.request();

    Map<Permission, bool> results = {};
    for (Permission permission in permissions) {
      results[permission] = statuses[permission]?.isGranted ?? false;
    }

    return results;
  }

  // Request all permissions with better error handling
  static Future<bool> requestAllCallPermissions({
    required bool isVideoCall,
  }) async {
    try {
      // Request notification permission first (non-blocking)
      if (Platform.isAndroid) {
        await requestNotificationPermission();
      }

      // Request core permissions
      final results = await requestCallPermissions(isVideoCall: isVideoCall);
      
      // Check if all core permissions are granted
      bool micGranted = results[Permission.microphone] ?? false;
      bool camGranted = isVideoCall ? (results[Permission.camera] ?? false) : true;
      
      return micGranted && camGranted;
    } catch (e) {
      print('Error requesting call permissions: $e');
      return false;
    }
  }

  // Check if we have all required permissions
  static Future<bool> hasRequiredPermissions({
    required bool isVideoCall,
  }) async {
    final micStatus = await Permission.microphone.status;
    
    // For core functionality, notification permission is not strictly required
    // but we should warn if it's missing on Android 13+
    if (Platform.isAndroid) {
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        print('Warning: Notification permission not granted - incoming calls may not display properly');
      }
    }

    if (!isVideoCall) {
      return micStatus.isGranted;
    }

    final camStatus = await Permission.camera.status;
    return micStatus.isGranted && camStatus.isGranted;
  }

  // Check if we have all permissions including notifications
  static Future<bool> hasAllPermissions({
    required bool isVideoCall,
  }) async {
    final micStatus = await Permission.microphone.status;
    final notificationStatus = await hasNotificationPermission();

    if (!isVideoCall) {
      return micStatus.isGranted && notificationStatus;
    }

    final camStatus = await Permission.camera.status;
    return micStatus.isGranted && camStatus.isGranted && notificationStatus;
  }

  // Open app settings
  static Future<bool> openSettings() async {
    return await openAppSettings();
  }

  // Get permission status summary
  static Future<Map<String, bool>> getPermissionSummary({
    required bool isVideoCall,
  }) async {
    return {
      'microphone': await Permission.microphone.status.then((s) => s.isGranted),
      'camera': isVideoCall ? await Permission.camera.status.then((s) => s.isGranted) : true,
      'notification': await hasNotificationPermission(),
    };
  }
}