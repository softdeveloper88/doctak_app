# Gallery Permission Update - Professional Implementation

## Overview

A comprehensive, professional gallery permission handling system has been implemented for the DocTak app, supporting both **iOS and Android latest devices** with proper permission dialogs and edge case handling.

## What Was Updated

### 1. New Professional Permission Handler (`lib/core/utils/gallery_permission_handler.dart`)

A new `GalleryPermissionHandler` class that provides:

#### Features:
- ✅ **iOS 14+ Support**: Handles both full and limited photo library access
- ✅ **Android 13+ Support**: Uses granular media permissions (READ_MEDIA_IMAGES)
- ✅ **Android 14+ Support**: Handles visual user selected permission (READ_MEDIA_VISUAL_USER_SELECTED)
- ✅ **Legacy Android Support**: Falls back to storage permission for Android 12 and below
- ✅ **Professional UI**: Beautiful, native-looking permission dialogs
- ✅ **Smart Handling**: Distinguishes between denied, permanently denied, and restricted states
- ✅ **User-Friendly**: Clear messaging explaining why permissions are needed

#### API:
```dart
// Quick permission check
final hasPermission = await galleryPermissionHandler.isGranted();

// Request permission with full UI handling
final granted = await galleryPermissionHandler.requestWithUI(context);

// Quick request (when user taps gallery button)
final granted = await galleryPermissionHandler.requestQuick(context);

// Show permission denied dialog
await galleryPermissionHandler.showPermissionDeniedDialog(context);
```

### 2. Updated `PermissionUtils` (`lib/utils/permission_utils.dart`)

Enhanced utility class that wraps the professional handler for backward compatibility:

```dart
// Gallery permissions
await PermissionUtils.requestGalleryPermissionWithUI(context);
await PermissionUtils.isGalleryPermissionGranted();
await PermissionUtils.showGalleryPermissionDeniedDialog(context);

// Camera permissions
await PermissionUtils.requestCameraPermissionWithUI(context);
await PermissionUtils.ensureCameraPermission();

// Microphone permissions
await PermissionUtils.ensureMicrophonePermission();

// Video recording (camera + microphone)
await PermissionUtils.ensureVideoRecordingPermissions();
```

### 3. Updated Screens

#### Add Post Screen (`SVPostOptionsComponent`)
- ✅ Gallery button uses professional permission handler
- ✅ Camera button with proper permission dialogs
- ✅ Video recording with camera + microphone permissions
- ✅ Clear error messages for users

#### AI Chat Screen (`ChatGptWithImageScreen`)
- ✅ Upload button with professional permission handling
- ✅ Attachment button with proper permission dialogs
- ✅ Simplified permission dialog method

#### Multiple Image Upload Widget
- ✅ Gallery picker with professional permission handling
- ✅ Camera with proper permission dialogs
- ✅ Video recording with camera + microphone permissions
- ✅ Clean error handling with user-friendly messages

## Platform-Specific Implementation

### iOS Configuration

Already configured in `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is needed to share medical images, case studies, and other visual content during professional discussions and meetings.</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs permission to save images to your photo library.</string>

<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calls, meetings, and sharing visual content with other medical professionals.</string>

<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for voice calls, video meetings, and recording voice messages.</string>
```

The implementation handles:
- ✅ Full photo library access (when user grants full access)
- ✅ Limited photo library access (iOS 14+ when user selects specific photos)
- ✅ Permanently denied state (directs user to Settings)
- ✅ Restricted state (parental controls, etc.)

### Android Configuration

Already configured in `android/app/src/main/AndroidManifest.xml`:
```xml
<!-- Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

<!-- Android 14+ (API 34+) -->
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />

<!-- Legacy Android (API 32 and below) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Camera -->
<uses-permission android:name="android.permission.CAMERA" />
```

The implementation automatically detects Android SDK version and uses:
- **Android 14+ (API 34+)**: `READ_MEDIA_IMAGES` + `READ_MEDIA_VISUAL_USER_SELECTED`
- **Android 13 (API 33)**: `READ_MEDIA_IMAGES`
- **Android 12 and below**: `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`

## User Experience

### Permission Flow

1. **User taps Gallery/Upload button**
2. **System checks if permission is already granted**
   - If yes: Opens gallery immediately
   - If no: Continues to step 3

3. **System requests permission**
   - Shows native permission dialog
   - User can grant full access, limited access (iOS), or deny

4. **System handles the result**
   - **Granted/Limited**: Opens gallery
   - **Denied**: Shows friendly snackbar with retry option
   - **Permanently Denied**: Shows dialog with "Open Settings" button

### Permission Dialogs

#### Rationale Dialog (Optional)
Shows before requesting permission, explaining why it's needed:
- Beautiful UI with icon
- Clear explanation
- Feature list showing what the permission enables
- "Allow Access" and "Cancel" buttons

#### Denied Dialog
Shows when permission is permanently denied:
- Professional UI matching app design
- Clear message about needing to enable in Settings
- "Open Settings" button (opens device settings)
- "Not Now" button

#### Error Messages
User-friendly snackbars for various scenarios:
- Permission denied (orange with retry action)
- Permission restricted (red)
- Gallery picker errors (red)

## Testing Checklist

### iOS Testing
- [ ] Test on iOS 14+ with full photo library access
- [ ] Test on iOS 14+ with limited photo library access
- [ ] Test permission denied scenario
- [ ] Test permanently denied → Settings → re-enable → works
- [ ] Test in Add Post screen
- [ ] Test in AI Chat screen

### Android Testing
- [ ] Test on Android 14+ (API 34+)
- [ ] Test on Android 13 (API 33)
- [ ] Test on Android 11-12 (API 30-32)
- [ ] Test permission denied scenario
- [ ] Test permanently denied → Settings → re-enable → works
- [ ] Test in Add Post screen
- [ ] Test in AI Chat screen

## Code Examples

### Using in a New Screen

```dart
import 'package:doctak_app/utils/permission_utils.dart';

// Simple usage - just request and open gallery
Future<void> openGallery() async {
  final hasPermission = await PermissionUtils.requestGalleryPermissionWithUI(
    context,
    showRationale: false, // Set true to show rationale dialog first
  );

  if (hasPermission) {
    // Open gallery picker
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // Handle selected image
  }
}

// Advanced usage - with custom messages
Future<void> openGalleryAdvanced() async {
  final handler = GalleryPermissionHandler();

  final granted = await handler.requestWithUI(
    context,
    showRationale: true,
    rationaleTitle: 'Access Your Photos',
    rationaleMessage: 'We need access to upload medical images.',
    deniedTitle: 'Photo Access Required',
    deniedMessage: 'Please enable photo access in Settings.',
  );

  if (granted) {
    // Open gallery
  }
}
```

### Camera Permission Example

```dart
Future<void> openCamera() async {
  final hasPermission = await PermissionUtils.requestCameraPermissionWithUI(context);

  if (hasPermission) {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    // Handle captured photo
  }
}
```

## Benefits

1. **Professional UX**: Beautiful, native-looking permission dialogs that match iOS and Android design guidelines
2. **Latest OS Support**: Properly handles permissions on iOS 14+ and Android 13/14+
3. **Clear Messaging**: Users understand why permissions are needed
4. **Smart Handling**: Distinguishes between different denial states and handles each appropriately
5. **Consistent**: Same permission flow across all screens
6. **Maintainable**: Centralized permission logic makes updates easy
7. **Well-Documented**: Clear API and usage examples

## Files Modified

1. ✅ `lib/core/utils/gallery_permission_handler.dart` (NEW)
2. ✅ `lib/utils/permission_utils.dart` (UPDATED)
3. ✅ `lib/presentation/home_screen/fragments/add_post/components/SVPostOptionsComponent.dart`
4. ✅ `lib/presentation/chat_gpt_screen/chat_gpt_with_image_screen.dart`
5. ✅ `lib/widgets/image_upload_widget/multiple_image_upload_widget.dart`

## Dependencies

No new dependencies required! The implementation uses:
- `permission_handler: ^12.0.1` (already in pubspec.yaml)
- `device_info_plus: ^10.1.2` (already in pubspec.yaml)
- `image_picker: ^1.1.2` (already in pubspec.yaml)

## Notes

- All existing functionality is preserved
- The implementation is backward compatible
- Debug logging uses `debugPrint()` instead of `print()` for production-ready code
- Permission checks are cached for performance
- All edge cases are handled (restricted, limited access, etc.)
- The code follows Flutter best practices and Material Design guidelines

## Next Steps

1. Test on real iOS devices (iOS 14+)
2. Test on real Android devices (Android 13+, 14+)
3. Verify permission dialogs show correctly
4. Test denial scenarios and Settings navigation
5. Monitor analytics for permission denial rates

---

**Implementation Date**: December 8, 2025
**Status**: ✅ Complete and Ready for Testing
