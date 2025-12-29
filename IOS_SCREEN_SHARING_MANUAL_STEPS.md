# iOS Screen Sharing - Manual Configuration Steps

This guide provides detailed step-by-step instructions for configuring iOS screen sharing in the Apple Developer Portal and Xcode.

---

## Part 1: Apple Developer Portal Configuration

### Step 1: Login to Apple Developer Portal

1. Open your browser and go to: **https://developer.apple.com/account**
2. Sign in with your Apple Developer account credentials
3. Click on **"Certificates, Identifiers & Profiles"** in the left sidebar

---

### Step 2: Create the App Group

1. In the left sidebar, click **"Identifiers"**
2. At the top right, click the **"+"** button (Register a new identifier)
3. Select **"App Groups"** from the list
4. Click **"Continue"**

5. Fill in the details:
   - **Description**: `DocTak Screen Share Group`
   - **Identifier**: `group.com.doctak.screenshare`
   
   > ⚠️ **Important**: The identifier MUST start with `group.` prefix

6. Click **"Continue"**
7. Review the information and click **"Register"**

✅ You should now see your new App Group in the list.

---

### Step 3: Add App Group to Main App ID (com.doctak.ios)

1. In the left sidebar, click **"Identifiers"**
2. Make sure **"App IDs"** is selected in the dropdown filter (top right)
3. Find and click on **`com.doctak.ios`** (your main app)
4. Scroll down to the **"Capabilities"** section
5. Find **"App Groups"** in the list and check the checkbox to enable it
6. Click **"Configure"** button next to App Groups
7. In the popup:
   - Check the box next to **`group.com.doctak.screenshare`**
   - Click **"Continue"**
8. Click **"Save"** at the top right
9. A warning will appear saying the provisioning profiles will be invalidated - click **"Confirm"**

---

### Step 4: Create Extension App ID (com.doctak.ios.BroadcastUploadExtension)

1. In the left sidebar, click **"Identifiers"**
2. Click the **"+"** button (Register a new identifier)
3. Select **"App IDs"**
4. Click **"Continue"**
5. Select **"App"** as the type
6. Click **"Continue"**

7. Fill in the details:
   - **Description**: `DocTak Broadcast Extension`
   - **Bundle ID**: Select **"Explicit"**
   - Enter: `com.doctak.ios.BroadcastUploadExtension`

8. Scroll down to **"Capabilities"** section
9. Find and enable **"App Groups"** (check the checkbox)
10. Click **"Configure"** next to App Groups
11. Check the box next to **`group.com.doctak.screenshare`**
12. Click **"Continue"**
13. Click **"Continue"** again
14. Review and click **"Register"**

---

### Step 5: Regenerate Provisioning Profiles

After modifying App IDs, you need to regenerate provisioning profiles:

#### For Main App (com.doctak.ios):

1. In the left sidebar, click **"Profiles"**
2. Find your existing profile for `com.doctak.ios` (Development or Distribution)
3. Click on it
4. Click **"Edit"**
5. Make sure the correct App ID and certificates are selected
6. Click **"Generate"**
7. Download the new profile

#### For Extension (com.doctak.ios.BroadcastUploadExtension):

1. Click **"+"** to create a new profile
2. Select the profile type:
   - For development: **"iOS App Development"**
   - For App Store: **"App Store Connect"**
3. Click **"Continue"**
4. Select **`com.doctak.ios.BroadcastUploadExtension`** from the App ID dropdown
5. Click **"Continue"**
6. Select the appropriate certificate
7. Click **"Continue"**
8. Select the devices (for development profiles)
9. Click **"Continue"**
10. Enter a name: `DocTak Broadcast Extension Development` (or Distribution)
11. Click **"Generate"**
12. Download the profile

---

### Step 6: Install Profiles in Xcode

1. Double-click each downloaded `.mobileprovision` file to install it
2. Or drag them into Xcode

Alternatively, in Xcode:
1. Go to **Xcode > Settings > Accounts**
2. Select your Apple ID
3. Click **"Download Manual Profiles"**

---

## Part 2: Link Agora Framework to Extension (Optional - For Full Screen Sharing)

This step is needed if you want the extension to actually capture and stream the screen via Agora.

### Step 1: Open Project in Xcode

1. Open Terminal and run:
   ```bash
   open /Users/hassan/Documents/MyProjects/doctak_app/ios/Runner.xcworkspace
   ```

2. Wait for Xcode to fully load the project and index files

---

### Step 2: Locate Agora Framework

1. In the left sidebar (Project Navigator), expand **"Pods"**
2. Expand **"Pods"** > **"AgoraRtcEngine_iOS"**
3. You should see the Agora frameworks here

The frameworks are located at:
```
ios/Pods/AgoraRtcEngine_iOS/AgoraRtcKit.xcframework
ios/Pods/AgoraRtcEngine_iOS/AgoraReplayKitExtension.xcframework (if available)
```

---

### Step 3: Add Framework to Extension Target

1. In the Project Navigator (left sidebar), click on the **"Runner"** project (blue icon at the top)
2. In the middle panel, you'll see a list of **TARGETS**
3. Select **"BroadcastUploadExtension"**
4. Click on the **"General"** tab
5. Scroll down to **"Frameworks, Libraries, and Embedded Content"**
6. Click the **"+"** button

7. In the popup:
   - Click **"Add Other..."** at the bottom
   - Select **"Add Files..."**
   
8. Navigate to:
   ```
   ios/Pods/AgoraRtcEngine_iOS/
   ```

9. Select **`AgoraRtcKit.xcframework`**
10. Click **"Open"**

11. Make sure the framework shows with **"Do Not Embed"** selected
    (Extensions should not embed frameworks - they use the main app's copy)

---

### Step 4: Add Framework Search Paths

1. With **"BroadcastUploadExtension"** still selected
2. Click on the **"Build Settings"** tab
3. Make sure **"All"** and **"Combined"** are selected at the top
4. In the search bar, type: `framework search`
5. Find **"Framework Search Paths"**
6. Double-click on the value column
7. Click **"+"** and add:
   ```
   $(PODS_ROOT)/AgoraRtcEngine_iOS
   $(PODS_CONFIGURATION_BUILD_DIR)/AgoraRtcEngine_iOS
   ```

---

### Step 5: Update SampleHandler.swift

After linking the framework, update the SampleHandler.swift file:

1. In Project Navigator, expand **"BroadcastUploadExtension"**
2. Open **"SampleHandler.swift"**
3. Replace the contents with the full Agora implementation:

```swift
import ReplayKit
import AgoraRtcKit

class SampleHandler: RPBroadcastSampleHandler, AgoraRtcEngineDelegate {
    
    private var agoraEngine: AgoraRtcEngineKit?
    private let appId = "f2cf99f1193a40e69546157883b2159f"
    private let appGroupIdentifier = "group.com.doctak.screenshare"
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        config.channelProfile = .liveBroadcasting
        
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraEngine?.setClientRole(.broadcaster)
        
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            finishBroadcastWithError(NSError(domain: "SampleHandler",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Cannot access app group"]))
            return
        }
        
        let channelName = defaults.string(forKey: "AGORA_CHANNEL_NAME") ?? ""
        let token = defaults.string(forKey: "AGORA_TOKEN")
        let uid = defaults.integer(forKey: "AGORA_UID")
        
        if channelName.isEmpty {
            finishBroadcastWithError(NSError(domain: "SampleHandler",
                                            code: -2,
                                            userInfo: [NSLocalizedDescriptionKey: "No channel configured"]))
            return
        }
        
        let videoConfig = AgoraVideoEncoderConfiguration(
            size: CGSize(width: 1280, height: 720),
            frameRate: .fps15,
            bitrate: 2000,
            orientationMode: .adaptative,
            mirrorMode: .auto
        )
        agoraEngine?.setVideoEncoderConfiguration(videoConfig)
        agoraEngine?.enableVideo()
        
        let option = AgoraRtcChannelMediaOptions()
        option.publishCameraTrack = false
        option.publishMicrophoneTrack = false
        option.publishScreenCaptureVideo = true
        option.publishScreenCaptureAudio = true
        option.clientRoleType = .broadcaster
        
        agoraEngine?.joinChannel(
            byToken: token,
            channelId: channelName,
            uid: UInt(uid),
            mediaOptions: option
        )
    }
    
    override func broadcastPaused() {
        // Pause streaming
    }
    
    override func broadcastResumed() {
        // Resume streaming
    }
    
    override func broadcastFinished() {
        agoraEngine?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
        agoraEngine = nil
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            agoraEngine?.pushExternalVideoFrame(sampleBuffer)
        case .audioApp:
            // Handle app audio if needed
            break
        case .audioMic:
            // Handle mic audio if needed
            break
        @unknown default:
            break
        }
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("Agora error: \(errorCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("Joined channel: \(channel)")
    }
}
```

---

### Step 6: Build and Test

1. Select **"BroadcastUploadExtension"** scheme (if available) or **"Runner"**
2. Select a real iOS device (not simulator)
3. Press **Cmd+B** to build
4. If there are errors about missing modules, check:
   - Framework Search Paths are correct
   - The framework is properly linked

---

## Part 3: Flutter Side - Save Channel Info for Extension

Add this code to your `video_call_screen.dart` to pass channel info to the extension:

### In AppDelegate.swift (iOS native):

```swift
// Add this method channel handler in AppDelegate.swift

let screenShareChannel = FlutterMethodChannel(
    name: "com.doctak.ios/screenshare",
    binaryMessenger: controller.binaryMessenger
)

screenShareChannel.setMethodCallHandler { call, result in
    if call.method == "saveScreenShareInfo" {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
            return
        }
        
        let defaults = UserDefaults(suiteName: "group.com.doctak.screenshare")
        defaults?.set(args["channelName"], forKey: "AGORA_CHANNEL_NAME")
        defaults?.set(args["token"], forKey: "AGORA_TOKEN")
        defaults?.set(args["uid"], forKey: "AGORA_UID")
        defaults?.synchronize()
        
        result(true)
    } else {
        result(FlutterMethodNotImplemented)
    }
}
```

### In video_call_screen.dart (Flutter):

```dart
// Add this method to save channel info before screen sharing
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
      debugPrint('Error saving screen share info: $e');
    }
  }
}

// Call this before showing the screen share picker
```

---

## Troubleshooting

### "App Group not found" error
- Verify the App Group identifier matches exactly in:
  - Apple Developer Portal
  - Runner.entitlements
  - BroadcastUploadExtension.entitlements
  - SampleHandler.swift code

### "Module 'AgoraRtcKit' not found"
- Check Framework Search Paths in Build Settings
- Make sure the framework is linked in General > Frameworks
- Try cleaning build folder: **Product > Clean Build Folder**

### Extension doesn't appear in broadcast picker
- The extension must be signed with a valid provisioning profile
- Bundle ID must match exactly: `com.doctak.ios.BroadcastUploadExtension`
- Check that the extension is included in the build scheme

### Build fails with code signing errors
- Regenerate provisioning profiles in Developer Portal
- In Xcode, go to **Signing & Capabilities** for both targets
- Try disabling and re-enabling automatic signing

---

## Quick Checklist

- [ ] Created App Group `group.com.doctak.screenshare` in Developer Portal
- [ ] Added App Group to main app ID `com.doctak.ios`
- [ ] Created extension app ID `com.doctak.ios.BroadcastUploadExtension`
- [ ] Added App Group to extension app ID
- [ ] Regenerated provisioning profiles for both
- [ ] (Optional) Linked AgoraRtcKit.xcframework to extension
- [ ] (Optional) Added Framework Search Paths
- [ ] (Optional) Updated SampleHandler.swift with Agora code
- [ ] (Optional) Added method channel for passing channel info
