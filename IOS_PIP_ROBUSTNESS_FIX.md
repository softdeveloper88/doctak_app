# iOS PiP "Failed to Start" & Visibility Fix

## Problem
Users reported:
1.  Errors in logs: `failed:Failed to start picture in picture`.
2.  Conflicting behavior where manual timers clashed with system Auto-PiP.
3.  "Flutter widgets not showing" (user expectation vs iOS limitation).

## Root Cause
1.  **Race Condition:** The `VideoCallScreen` was manually triggering PiP on `AppLifecycleState.inactive` (with a delay), which effectively tried to start PiP *twice* (once by system Auto-PiP, once by Flutter). This caused the system to reject the second attempt or fail the first.
2.  **View Visibility:** The `pipView` setup (positioned mostly offscreen with `alpha=0.01`) was too aggressive. iOS 15+ `AVPictureInPictureController` is strict about the player layer being visible in the view hierarchy. If it detects the view is effectively invisible, it fails to start PiP.

## Solution

### 1. Flutter Side (`VideoCallScreen.dart`)
-   **Removed Manual Trigger:** Deleted the `Timer` logic in `didChangeAppLifecycleState` (case `inactive`).
-   **Rely on Auto-PiP:** Now solely relies on the `enableAutoPiP` configuration which sets `canStartPictureInPictureAutomaticallyFromInline = true` on the native side. This is the correct way to handle "home button" or "swipe up" transitions on iOS.

### 2. iOS Native Side (`AppDelegate.swift`)
-   **Robust View Placement:** detailed below.
    -   Changed `pipView` frame to `window.bounds` (Full Screen).
    -   Changed alpha to `1.0` (Fully Opaque).
    -   **Critical:** Instead of `addSubview` (on top), used `insertSubview(pipView, at: 0)`.
    -   **Result:** The PiP player view is now "behind" the Flutter rendering view. It satisfies all system visibility requirements (it's opaque, on screen, in hierarchy) but is naturally covered by the active Flutter UI. When the app minimizes, the system picks up this valid player layer and transitions it to PiP.

## Verification
-   Run the app on a real iOS device.
-   Join a video call.
-   Swipe up to go home.
-   PiP should start smoothly without error logs.
-   Note: The PiP window displays a generated "In Call" animation (pulsing circles), not the Flutter UI widgets, as iOS PiP is video-only.

