# Android Permissions Audit & Cleanup

## Date: December 30, 2025

## Summary of Changes

### ✅ Permissions Kept (Essential)

1. **Internet & Network**
   - `INTERNET` - Core app functionality
   - `ACCESS_NETWORK_STATE` - Network connectivity checks
   - `ACCESS_WIFI_STATE` - Wi-Fi connectivity detection

2. **Media Access (Android 13+)**
   - `READ_MEDIA_IMAGES` - Gallery photo selection
   - `READ_MEDIA_VIDEO` - Gallery video selection
   - `READ_MEDIA_VISUAL_USER_SELECTED` - Partial media access (Android 14+)

3. **Legacy Storage (Android 12 and below)**
   - `READ_EXTERNAL_STORAGE` (maxSdkVersion="32") - Limited to old Android versions
   - `WRITE_EXTERNAL_STORAGE` (maxSdkVersion="32") - Limited to old Android versions

4. **Camera & Audio**
   - `CAMERA` - Video calls, photo capture
   - `RECORD_AUDIO` - Voice calls, voice messages

5. **Call Features**
   - `FOREGROUND_SERVICE` - Background call processing
   - `FOREGROUND_SERVICE_PHONE_CALL` - Call notifications
   - `FOREGROUND_SERVICE_MEDIA_PROJECTION` - Screen sharing
   - `MANAGE_OWN_CALLS` - Call management
   - `USE_FULL_SCREEN_INTENT` - Incoming call full-screen notifications

6. **Screen Sharing**
   - `MEDIA_PROJECTION` - Screen sharing during meetings

7. **Overlay & PiP**
   - `SYSTEM_ALERT_WINDOW` - Picture-in-Picture mode, overlay windows
   - **Note**: Must be manually enabled by user through Settings

8. **Notifications**
   - `POST_NOTIFICATIONS` - Push notifications (Android 13+)
   - `RECEIVE_BOOT_COMPLETED` - Restart notification services on boot

9. **System**
   - `VIBRATE` - Call/notification vibration

### ❌ Permissions Removed (Unused)

1. **READ_PHONE_STATE** - Not used anywhere in the app
2. **BLUETOOTH** - Not actively used for Bluetooth features
3. **Hardware Feature: android.hardware.telephony** - Not required
4. **All Launcher Badge Permissions** (Samsung, HTC, Sony, Apex, Solid, Huawei)
   - These are deprecated and not needed on modern devices
   - App badge functionality works without these permissions

### 🔧 New Features Added

#### 1. System Permission Handler
Created `lib/core/utils/system_permission_handler.dart` to properly request `SYSTEM_ALERT_WINDOW` permission with user-friendly dialogs.

**Features:**
- Explains why permission is needed
- Shows features that require it (PiP, call overlays)
- Guides user to Settings if permission is denied
- Professional UI with step-by-step instructions

**Usage:**
```dart
// Import
import 'package:doctak_app/core/utils/system_permission_handler.dart';

// Check permission
bool hasPermission = await systemPermissionHandler.hasOverlayPermission();

// Request permission with UI
bool granted = await systemPermissionHandler.requestOverlayPermission(context);

// Quick check and request
bool ensured = await systemPermissionHandler.ensureOverlayPermission(context);
```

#### 2. Updated PiP Service
Enhanced `lib/presentation/calling_module/services/pip_service.dart` to:
- Check overlay permission before enabling PiP
- Request permission with user-friendly dialog if not granted
- Handle permission denial gracefully

**Updated Methods:**
```dart
// Now accepts optional context for permission dialogs
await pipService.enablePiP(
  contactName: 'John Doe',
  isVideoCall: true,
  context: context, // Optional but recommended
);

await pipService.enableAutoPiP(
  isVideoCall: true,
  context: context, // Optional but recommended
);
```

## User Experience Improvements

### Before
- SYSTEM_ALERT_WINDOW permission requested silently
- User confused about why PiP doesn't work
- No guidance on enabling permission
- Unnecessary permissions cluttering Play Store listing

### After
- Professional dialog explaining overlay permission
- Clear reasons why permission is needed
- Step-by-step guide if permission is denied
- Clean permission list on Play Store
- Proper scoping of storage permissions by Android version

## Testing Checklist

### Permissions Testing
- [ ] Camera permission works for video calls
- [ ] Microphone permission works for audio calls
- [ ] Gallery permission works for photo selection
- [ ] Notification permission works (Android 13+)
- [ ] Overlay permission dialog shows correctly
- [ ] PiP mode enables after granting overlay permission
- [ ] Storage permissions work on Android 12 and below
- [ ] Media permissions work on Android 13+

### Negative Testing
- [ ] App handles denied permissions gracefully
- [ ] Settings dialogs open correctly
- [ ] Permission rationale dialogs are clear
- [ ] App doesn't crash if permissions are denied
- [ ] User can retry permission requests

## Google Play Store Impact

### Before Changes
```
Permissions Detected (14+):
- Phone (read phone status and identity)
- Photos/Media/Files
- Storage
- Camera
- Microphone
- Wi-Fi connection information
- Device ID & call information
- Many launcher badge permissions
- Draw over other apps (not explained)
```

### After Changes
```
Permissions Detected (Reduced):
- Photos/Media/Files (properly scoped by Android version)
- Camera
- Microphone
- Wi-Fi connection information
- Draw over other apps (with proper explanation)
- Notifications
```

**Removed from listing:**
- Phone (READ_PHONE_STATE)
- Bluetooth
- Device ID
- Launcher badge permissions
- Redundant storage permissions

## Code Examples

### Request Overlay Permission Before PiP

```dart
// In your call screen
Future<void> enablePictureInPicture() async {
  final pipService = PiPService();
  
  // This now automatically checks and requests overlay permission
  final enabled = await pipService.enablePiP(
    contactName: widget.contactName,
    isVideoCall: widget.isVideoCall,
    context: context, // Provides context for permission dialog
  );
  
  if (enabled) {
    print('PiP enabled successfully');
  } else {
    print('PiP failed - permission may be denied');
  }
}
```

### Manual Overlay Permission Request

```dart
// Request overlay permission independently
import 'package:doctak_app/core/utils/system_permission_handler.dart';

Future<void> checkOverlayPermission() async {
  if (!await systemPermissionHandler.hasOverlayPermission()) {
    // Show dialog and request
    final granted = await systemPermissionHandler.requestOverlayPermission(context);
    
    if (granted) {
      // Proceed with PiP or overlay features
      enablePiP();
    } else {
      // Handle permission denial
      showSnackbar('Overlay permission is required for PiP mode');
    }
  }
}
```

## Migration Guide

### For Developers

1. **Update PiP calls to pass context:**
```dart
// Old
await pipService.enablePiP(
  contactName: name,
  isVideoCall: true,
);

// New (recommended)
await pipService.enablePiP(
  contactName: name,
  isVideoCall: true,
  context: context, // Add this
);
```

2. **Test permission flows:**
   - Test on Android 12 and below (storage permissions)
   - Test on Android 13+ (media permissions)
   - Test overlay permission on all versions
   - Verify permission dialogs appear correctly

3. **Update any custom permission handling:**
   - Remove references to READ_PHONE_STATE
   - Remove references to BLUETOOTH permission
   - Use new SystemPermissionHandler for overlay permission

## Additional Notes

### Why Storage Permissions Have maxSdkVersion

Android 13+ (API 33+) introduced granular media permissions (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`). The old storage permissions are only needed for Android 12 and below. By setting `maxSdkVersion="32"`, we:

1. Don't request unnecessary permissions on newer devices
2. Improve Play Store listing (fewer permissions shown)
3. Follow Android best practices
4. Maintain compatibility with older devices

### Why SYSTEM_ALERT_WINDOW Needs Manual Request

The SYSTEM_ALERT_WINDOW permission:
- Cannot be granted through normal permission request on Android 6+
- Requires user to manually enable in Settings
- Needs proper explanation (hence the new SystemPermissionHandler)
- Is critical for PiP functionality

## Files Modified

1. `android/app/src/main/AndroidManifest.xml` - Cleaned up permissions
2. `lib/core/utils/system_permission_handler.dart` - New file
3. `lib/presentation/calling_module/services/pip_service.dart` - Updated
4. `PERMISSIONS_AUDIT.md` - This documentation

## References

- [Android Permissions Best Practices](https://developer.android.com/training/permissions/requesting)
- [SYSTEM_ALERT_WINDOW Documentation](https://developer.android.com/reference/android/Manifest.permission#SYSTEM_ALERT_WINDOW)
- [Scoped Storage](https://developer.android.com/about/versions/11/privacy/storage)
- [Granular Media Permissions](https://developer.android.com/about/versions/13/behavior-changes-13#granular-media-permissions)
