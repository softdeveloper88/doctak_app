# iOS Screen Sharing - Setup Status

## ✅ Automated Setup Completed

The iOS screen sharing extension has been **automatically configured** in the Xcode project and **builds successfully**.

### What Was Set Up Automatically

#### 1. Extension Files Created
- `ios/BroadcastUploadExtension/SampleHandler.swift` - Extension code (placeholder)
- `ios/BroadcastUploadExtension/Info.plist` - Extension configuration  
- `ios/BroadcastUploadExtension/BroadcastUploadExtension.entitlements` - App Groups

#### 2. Xcode Project Configured
- ✅ BroadcastUploadExtension target added
- ✅ Extension embedded in Runner app
- ✅ Target dependency configured
- ✅ Debug/Release/Profile build configs set up
- ✅ Development Team: WXF27GH385
- ✅ Framework search paths configured

#### 3. Entitlements
- ✅ App Group `group.com.doctak.ios.ScreenShare` added

#### 4. Build Status
- ✅ `flutter build ios --no-codesign` **SUCCESSFUL**
- ✅ Extension compiles without errors

---

## ⚠️ Current Limitation

The extension is currently a **placeholder** that validates the app group connection but doesn't actually capture/stream the screen. This is because:

1. **Framework Conflict**: Having both the main app and extension use Agora SDK causes build conflicts
2. **Solution Options**:
   - Use in-app screen capture (doesn't require extension, simpler)
   - Manually link Agora framework to extension in Xcode

---

## In-App Screen Sharing (Recommended for Flutter)

The simpler approach is to use **in-app screen capture** which doesn't require the extension:

```dart
// In video_call_screen.dart - this is already available
await _engine?.startScreenCapture(
  const ScreenCaptureParameters2(
    captureVideo: true,
    captureAudio: true,
    videoParams: ScreenVideoParameters(
      dimensions: VideoDimensions(width: 1280, height: 720),
      frameRate: 15,
      bitrate: 2000,
    ),
  ),
);

// Then update media options to publish screen
await _engine?.updateChannelMediaOptions(
  const ChannelMediaOptions(
    publishScreenCaptureVideo: true,
    publishScreenCaptureAudio: true,
    publishCameraTrack: false,
  ),
);
```

**Note**: In-app screen capture works when the app is in foreground. The extension is needed for background/system-wide screen sharing.

---

## Remaining Manual Steps (For Full Extension Support)

### 1. Apple Developer Portal Setup

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Create App Group: `group.com.doctak.ios.ScreenShare`
3. Add App Group to both App IDs:
   - `com.doctak.ios` (main app)
   - `com.doctak.ios.BroadcastUploadExtension` (extension)
4. Regenerate provisioning profiles

### 2. Link Agora Framework (For Extension Screen Capture)

If you need the extension to actually capture and stream:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **BroadcastUploadExtension** target
3. Go to **General > Frameworks, Libraries, and Embedded Content**
4. Add `AgoraRtcKit.xcframework` from Pods
5. Update SampleHandler.swift to import and use AgoraRtcKit

---

## Bundle Identifiers

| Target | Bundle ID |
|--------|-----------|
| Main App | `com.doctak.ios` |
| Extension | `com.doctak.ios.BroadcastUploadExtension` |
| App Group | `group.com.doctak.ios.ScreenShare` |
