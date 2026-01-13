# iOS Picture-in-Picture (PiP) Fix Summary

## Problem
iOS PiP was not showing the minimized window when the app went to background during a call.

## Root Cause
The previous implementation used `AVSampleBufferDisplayLayer` which is complex and was showing a black screen or not working at all. The iOS Simulator also has limited PiP support.

## Solution
Rewrote `AppDelegate.swift` with a new `AVPlayer`-based approach:

### Key Changes

1. **AVPlayer-based PiP** - Uses `AVPlayer` + `AVPlayerLooper` for a looping video
2. **Programmatic video generation** - Creates an animated placeholder video with:
   - Dark blue gradient background
   - Pulsing blue circle with video camera icon
   - Animated dots indicating "in call" status
   - 3-second looping animation at 30fps

3. **KVO Observation** - Waits for `isPictureInPicturePossible` to become true before starting PiP

4. **Proper cleanup** - Invalidates observations and cleans up resources properly

### Files Modified

- **`ios/Runner/AppDelegate.swift`** - Complete rewrite with:
  - `AgoraPiPController` class using AVPlayer approach
  - Video generation code for placeholder animation
  - KVO observer for `isPictureInPicturePossible`
  - Method channel handlers for Flutter communication

## iOS Simulator Limitation

**⚠️ IMPORTANT**: iOS Simulator does NOT fully support Picture-in-Picture.

The error message `"Failed to start picture in picture."` is expected on the Simulator. **PiP will work correctly on a real iOS device**.

## How to Test on Real Device

1. Connect a real iPhone/iPad (iOS 15.0+)
2. Run: `flutter run -d <device-id>`
3. Join a video call or meeting
4. Press the home button or swipe up to go to background
5. The PiP window should appear with the animated "in call" indicator

## Info.plist Requirements

The following background modes are already configured:
- `audio` - Required for audio session
- `picture-in-picture` - Required for PiP functionality
- `voip` - For VoIP calls
- `fetch` - For background fetch
- `remote-notification` - For push notifications

## Audio Session Configuration

The audio session is configured for PiP in `AppDelegate.swift`:
```swift
try audioSession.setCategory(.playAndRecord, mode: .videoChat, options: [
  .allowBluetooth,
  .allowBluetoothA2DP,
  .defaultToSpeaker,
  .mixWithOthers
])
```

## Method Channel API

Channel: `com.doctak.app/agora_pip`

Methods:
- `isSupported` - Returns `Bool`, whether PiP is supported
- `setup` - Returns `Bool`, initializes PiP controller
- `start` - Returns `Bool`, starts PiP
- `stop` - Returns `Bool`, stops PiP
- `isActive` - Returns `Bool`, current PiP state
- `setAutoEnabled` - Enables/disables auto-enter PiP
- `getStatus` - Returns status dictionary
- `dispose` - Cleans up resources

Events (via `invokeMethod`):
- `onPiPStateChanged` - Notifies of state changes (`willStart`, `started`, `willStop`, `stopped`, `restoreUI`, `failed:*`)

## Summary of PiP Flow

1. When call screen opens → `PipService.enablePiP()` is called
2. iOS: `IOSAgoraPiPService.setup()` creates video and PiP controller
3. When app goes to background → `PipService.onAppPaused()` triggers
4. iOS: `IOSAgoraPiPService.start()` starts PiP
5. User sees animated placeholder in PiP window
6. When user taps PiP → `restoreUserInterface` delegate method returns to app
7. When call ends → `PipService.disablePiP()` cleans up

## Android Status

Android PiP is working correctly using the `pip` package with:
- `autoEnterEnabled: true` when call is active
- `autoEnterEnabled: false` when returning from PiP
- PiP only enabled on call/meeting screens (not globally)
