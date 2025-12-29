# iOS Screen Sharing Configuration Guide for DocTak App

This guide explains how to complete the iOS screen sharing setup for the DocTak meeting module using Agora's ReplayKit integration.

## Overview

iOS screen sharing requires a Broadcast Upload Extension that runs in a separate process. The extension has been created at:
- `ios/BroadcastUploadExtension/`

## Steps to Complete Setup in Xcode

### Step 1: Add the Broadcast Upload Extension Target

1. Open the Xcode workspace: `ios/Runner.xcworkspace`
2. In Xcode, go to **File > New > Target...**
3. Select **Broadcast Upload Extension** and click **Next**
4. Configure:
   - **Product Name**: `BroadcastUploadExtension`
   - **Bundle Identifier**: `com.doctak.ios.BroadcastUploadExtension`
   - **Language**: Swift
   - **Include UI Extension**: No (uncheck)
5. Click **Finish**

### Step 2: Replace Generated Files

After Xcode creates the extension, replace its files with the ones already created:
1. Delete the auto-generated `SampleHandler.swift`
2. Drag and drop the following files from `ios/BroadcastUploadExtension/` into the Xcode extension target:
   - `SampleHandler.swift`
   - `Info.plist`
   - `BroadcastUploadExtension.entitlements`

### Step 3: Configure Extension Target Settings

1. Select the **BroadcastUploadExtension** target
2. Go to **Build Settings**:
   - Set **iOS Deployment Target** to `15.0`
   - Set **Swift Language Version** to match the main app
3. Go to **General**:
   - Ensure **Bundle Identifier** is `com.doctak.ios.BroadcastUploadExtension`
   - Set **Version** and **Build** to match the main app
4. Go to **Signing & Capabilities**:
   - Enable automatic signing with your team
   - Add **App Groups** capability with identifier: `group.com.doctak.ios.screenshare`

### Step 4: Configure Main App Target

1. Select the **Runner** target
2. Go to **Signing & Capabilities**
3. Add **App Groups** capability if not present
4. Add the group identifier: `group.com.doctak.ios.screenshare`

### Step 5: Add Agora Framework to Extension

1. Select the **BroadcastUploadExtension** target
2. Go to **General > Frameworks, Libraries, and Embedded Content**
3. Click **+** and add:
   - `AgoraRtcKit.xcframework`
   - Any other required Agora frameworks

Or update the Podfile to include Agora in the extension:

```ruby
target 'BroadcastUploadExtension' do
  use_frameworks!
  pod 'AgoraRtcEngine_iOS', '~> 4.5.2'
end
```

### Step 6: Update Podfile

Add the following to your `Podfile`:

```ruby
target 'BroadcastUploadExtension' do
  use_frameworks!
  pod 'AgoraRtcEngine_iOS/ReplayKit', '~> 4.5.2'
end
```

Then run:
```bash
cd ios && pod install
```

### Step 7: App Group Configuration in Apple Developer Portal

1. Log in to [Apple Developer Portal](https://developer.apple.com)
2. Go to **Certificates, Identifiers & Profiles > Identifiers**
3. Create a new App Group with identifier: `group.com.doctak.ios.screenshare`
4. Update both App IDs (Runner and BroadcastUploadExtension) to include this App Group

## Flutter Side: Passing Screen Share Info

The extension needs channel information from the main app. Update the screen sharing code in `video_call_screen.dart` to save info to App Group UserDefaults before starting screen share:

```dart
// Add this import at the top of video_call_screen.dart
import 'package:flutter/services.dart';

// Add this method to save channel info for iOS screen sharing
Future<void> _saveScreenShareInfoForIOS() async {
  if (Platform.isIOS) {
    try {
      const platform = MethodChannel('com.doctak.ios/screenshare');
      await platform.invokeMethod('saveScreenShareInfo', {
        'channelName': channelName,
        'token': token,
        'uid': int.tryParse(AppData.logInUserId) ?? 0,
      });
    } catch (e) {
      debugPrint('Error saving screen share info for iOS: $e');
    }
  }
}
```

### Add Method Channel Handler in AppDelegate.swift

```swift
import Flutter
import UIKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        let screenShareChannel = FlutterMethodChannel(
            name: "com.doctak.ios/screenshare",
            binaryMessenger: controller.binaryMessenger
        )
        
        screenShareChannel.setMethodCallHandler { [weak self] call, result in
            if call.method == "saveScreenShareInfo" {
                guard let args = call.arguments as? [String: Any] else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                    return
                }
                
                let defaults = UserDefaults(suiteName: "group.com.doctak.ios.screenshare")
                defaults?.set(args["channelName"], forKey: "AGORA_CHANNEL_NAME")
                defaults?.set(args["token"], forKey: "AGORA_TOKEN")
                defaults?.set(args["uid"], forKey: "AGORA_UID")
                defaults?.synchronize()
                
                result(true)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

## Testing Screen Sharing

1. Build and run the app on a real iOS device (screen sharing doesn't work on simulator)
2. Start a meeting
3. Tap the screen share button
4. iOS will show the broadcast picker UI
5. Select "DocTak Screen Share" extension
6. The screen share should start

## Troubleshooting

### Common Issues

1. **Extension not appearing in broadcast picker**
   - Ensure the extension target is included in the build scheme
   - Check that the extension bundle identifier is correct
   - Verify signing is properly configured

2. **Screen share starts but no video**
   - Check that Agora credentials are correct
   - Verify App Group is properly configured in both targets
   - Check console logs for Agora errors

3. **Extension crashes immediately**
   - Check that all required Agora frameworks are linked
   - Verify the deployment target is iOS 15.0 or higher
   - Check for any missing entitlements

### Debug Logging

To see extension logs:
1. Open Xcode
2. Go to **Debug > Attach to Process by PID or Name**
3. Enter "BroadcastUploadExtension"
4. Start screen sharing in the app

## Important Notes

- The extension runs in a separate process with limited memory (50MB max)
- The extension and main app communicate via App Groups
- Screen sharing only works on real devices, not simulators
- Users must have iOS 15.0 or later
