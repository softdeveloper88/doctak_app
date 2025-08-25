# DocTak Calling Module - Runtime Permission Fix

## Issue Fixed
**Android Runtime Exception**: `SecurityException: Starting FGS with type phoneCall requires permissions`

This error occurred because the app targets Android 14+ (SDK 35) which requires specific permissions for phone call foreground services.

## ✅ Applied Fixes

### 1. **Android Manifest Permissions**
Added required permissions for Android 14+ CallKit functionality:

```xml
<!-- Added to AndroidManifest.xml -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL"/>
<uses-permission android:name="android.permission.MANAGE_OWN_CALLS"/>
```

### 2. **Foreground Service Configuration**
Updated CallKit services with correct service types:

```xml
<!-- Updated service configurations -->
<service
    android:name="com.hiennv.flutter_callkit_incoming.CallkitIncomingService"
    android:exported="true"
    android:foregroundServiceType="phoneCall|microphone|camera" />

<service
    android:name="com.hiennv.flutter_callkit_incoming.OngoingNotificationService"
    android:exported="false"
    android:foregroundServiceType="phoneCall" />
```

### 3. **CallKit Activity Integration**
Added missing CallKit activity for proper call interface:

```xml
<activity
    android:name="com.hiennv.flutter_callkit_incoming.CallkitIncomingActivity"
    android:exported="false"
    android:excludeFromRecents="true"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"
    android:launchMode="singleTop"
    android:screenOrientation="portrait" />
```

### 4. **Token Authentication Fix**
Fixed hardcoded empty token in AgoraService:

```dart
// Before (security issue)
await _engine!.joinChannel(token: '', ...)

// After (secure)
await _engine!.joinChannel(token: token ?? '', ...)
```

## 📱 Android 14+ Requirements

The error was caused by Android's enhanced security model in SDK 35 which requires:

1. **Explicit Phone Call Permissions**: `FOREGROUND_SERVICE_PHONE_CALL`
2. **Call Management Permission**: `MANAGE_OWN_CALLS` 
3. **Proper Service Type Declaration**: `phoneCall` foreground service type

## 🚀 Next Steps

1. **Clean Build**: Run `flutter clean` then `flutter build apk`
2. **Test Call Functionality**: The calling should now work without runtime crashes
3. **Verify Permissions**: Ensure users grant phone call permissions when prompted

## ✅ Status
- **Android Manifest**: ✅ Updated with required permissions
- **Service Configuration**: ✅ Fixed foreground service types
- **Token Security**: ✅ Enabled proper Agora token usage
- **CallKit Integration**: ✅ Complete activity and service setup

The calling module should now work smoothly on Android 14+ devices without the SecurityException crash.