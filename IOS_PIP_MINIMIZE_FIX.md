# iOS PiP Minimize Fix Summary

## Problem
iOS Picture-in-Picture window was not opening automatically when the app was minimized, unlike Android.

## Root Cause
1.  The iOS implementation was relying on manually calling `startPictureInPicture()` via an app lifecycle observer (`didEnterBackgroundNotification`).
2.  Method `AVPictureInPictureController.canStartPictureInPictureAutomaticallyFromInline` was being set to `false` (hardcoded) in `setup()`.
3.  Even though `setAutoEnabled` existed in Swift, it had a race condition where the deferred `setup()` call (0.3s delay) would overwrite the value set by `setAutoEnabled`.
4.  The Dart side `IOSAgoraPiPService` did not expose the `setAutoEnabled` method.
5.  `PiPService` was not calling `setAutoEnabled(true)` for iOS.

## Solution

### 1. iOS Native Code (`ios/Runner/AppDelegate.swift`)
-   Added `private var isAutoPiPEnabled = false` to track the desired state.
-   Updated `setAutoEnabled(_:)` to update this state variable.
-   Updated `setup()` to initialize `pipController?.canStartPictureInPictureAutomaticallyFromInline` with `self.isAutoPiPEnabled` instead of hardcoded `false`. This fixes the race condition.

### 2. Dart Service (`lib/presentation/calling_module/services/ios_agora_pip_service.dart`)
-   Added `setAutoEnabled(bool enabled)` method to invoke the native channel method.

### 3. PiP Logic (`lib/presentation/calling_module/services/pip_service.dart`)
-   Updated `enableAutoPiP()` to call `_iosAgoraPiPService.setAutoEnabled(true)`.
-   Updated `disablePiP()` to call `_iosAgoraPiPService.setAutoEnabled(false)`.
-   Updated `onAppResumed()` to temporarily disable auto-PiP and then re-enable it, ensuring smooth transitions and preventing unwanted PiP when returning to the app.

## Result
Now, when `enableAutoPiP()` is called (which happens when joining a call), `canStartPictureInPictureAutomaticallyFromInline` is set to `true` on iOS. The system handles the transition to PiP automatically when the app is minimized (swiped up), ensuring reliable activation.
