# Release Mode Package Issues - Fix Guide

## Overview
This guide addresses issues where packages like `nb_utils`, `google_sign_in`, `file_picker`, etc. work in **debug mode** but fail in **release mode**.

## Certificate Analysis

### Debug Keystore SHA-1
```
93:6E:26:CF:43:3B:54:B9:23:7B:7A:CB:66:10:D3:A9:D3:95:2A:40
```

### Release Keystore SHA-1
```
50:1D:B4:67:A1:D3:2D:8A:ED:E2:39:06:E7:DD:6A:49:61:41:AB:17
```

✅ **Status**: Both SHA-1 certificates are registered in Firebase `google-services.json`

---

## Common Issues & Solutions

### 1. Google Sign-In Issues

#### Problem
Google Sign-In works in debug but fails silently or shows "Sign-in cancelled" in release.

#### Root Causes
- Missing release SHA-1 in Firebase Console (✅ Already fixed in your project)
- Incorrect OAuth client configuration
- Google Play Console additional SHA-1 requirements

#### Solution Steps

**A. Verify Firebase Console Configuration**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `doctak-322cc`
3. Go to **Project Settings** → **General**
4. Scroll to **Your apps** section
5. Click on your Android app
6. Verify these SHA-1 certificates are listed:
   ```
   93:6E:26:CF:43:3B:54:B9:23:7B:7A:CB:66:10:D3:A9:D3:95:2A:40  (Debug)
   50:1D:B4:67:A1:D3:2D:8A:ED:E2:39:06:E7:DD:6A:49:61:41:AB:17  (Release)
   ```

**B. Add Google Play App Signing Certificate (if published to Play Store)**

If your app is on Google Play Console, you need to add the Play Store's signing certificate:

1. Go to [Google Play Console](https://play.google.com/console/)
2. Select your app
3. Go to **Release** → **Setup** → **App Signing**
4. Copy the **SHA-1 certificate fingerprint** from "App signing key certificate"
5. Add this SHA-1 to your Firebase project (same place as above)

**C. Download Updated google-services.json**

After adding certificates to Firebase:
1. In Firebase Console → Project Settings → Your apps
2. Click **Download google-services.json**
3. Replace `android/app/google-services.json` with the new file

**D. Verify OAuth Client ID in Code**

Check your Flutter code for Google Sign-In configuration:

```dart
// Make sure you're not hardcoding a specific client ID
// Let the plugin auto-configure from google-services.json

GoogleSignIn _googleSignIn = GoogleSignIn(
  // scopes: <String>['email'],
  // Don't specify clientId here for Android
);
```

---

### 2. nb_utils Package Issues

#### Problem
`nb_utils` utilities (toast, navigation, etc.) may fail in release mode.

#### Root Causes
- ProGuard/R8 stripping utility classes
- Context issues in release builds
- Initialization timing issues

#### Solutions

**A. ProGuard Rules** (Already Added)
```proguard
-keep class nb_utils.** { *; }
-dontwarn nb_utils.**
```

**B. Verify nb_utils Initialization**

Ensure nb_utils is initialized in your `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize other services...

  runApp(MyApp());
}

// In MyApp build, ensure you have navigatorKey
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigatorService.navigatorKey, // Important for nb_utils
      // ... other config
    );
  }
}
```

---

### 3. File Picker / File Path Issues

#### Problem
File picker works in debug but fails or crashes in release mode on Android 11+.

#### Root Causes
- Scoped storage enforcement
- Missing permissions
- FileProvider configuration issues

#### Solutions

**A. Update AndroidManifest.xml**

Ensure these permissions are present (✅ Already in your manifest):
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />

<!-- Add requestLegacyExternalStorage for Android 10 -->
<application
    android:requestLegacyExternalStorage="true"
    ...>
```

**B. Request Permissions at Runtime**

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  if (Platform.isAndroid) {
    final androidVersion = await DeviceInfoPlugin().androidInfo;

    if (androidVersion.version.sdkInt >= 33) {
      // Android 13+
      await [
        Permission.photos,
        Permission.videos,
      ].request();
    } else if (androidVersion.version.sdkInt >= 30) {
      // Android 11-12
      await Permission.manageExternalStorage.request();
    } else {
      // Android 10 and below
      await Permission.storage.request();
    }
  }
}
```

**C. Use Scoped Storage Approach**

For Android 11+, use scoped storage paths:

```dart
// Don't use hardcoded paths in release
// BAD:
// File file = File('/storage/emulated/0/...');

// GOOD: Use path_provider
import 'package:path_provider/path_provider.dart';

Future<String> getAppDirectory() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}
```

---

### 4. Network & API Issues (nb_utils, dio, http)

#### Problem
API calls fail in release mode but work in debug.

#### Root Causes
- Certificate pinning issues
- Network security config
- ProGuard stripping networking classes

#### Solutions

**A. Network Security Config** (✅ Already configured)

Your `network_security_config.xml` is correctly set up:
```xml
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

**B. For Production, Use HTTPS Only**

Consider changing to HTTPS-only for production:
```xml
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" /> <!-- For debugging with proxy -->
        </trust-anchors>
    </base-config>

    <!-- Allow cleartext only for specific domains if needed -->
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">your-dev-server.com</domain>
    </domain-config>
</network-security-config>
```

**C. ProGuard Rules for Networking** (Already Added)
```proguard
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-dontwarn okhttp3.**
-dontwarn retrofit2.**
```

---

### 5. Firebase & Crashlytics

#### Problem
Firebase services not initialized properly in release.

#### Solution

Ensure Firebase is initialized in `main()`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Enable Crashlytics in release mode
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass uncaught errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(MyApp());
}
```

---

## Build Configuration

### Current Configuration (build.gradle)

```gradle
buildTypes {
    release {
        minifyEnabled false        // Code shrinking DISABLED
        shrinkResources false      // Resource shrinking DISABLED
        multiDexEnabled true
        debuggable false
        signingConfig signingConfigs.release
    }
}
```

### Optional: Enable Code Shrinking (For Smaller APK)

If you want to enable code shrinking for smaller APK size:

```gradle
buildTypes {
    release {
        minifyEnabled true         // Enable code shrinking
        shrinkResources true       // Enable resource shrinking
        multiDexEnabled true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        signingConfig signingConfigs.release
    }
}
```

**Note**: We've created comprehensive ProGuard rules in `proguard-rules.pro` that should prevent any issues.

---

## Testing Checklist

### Before Testing Release Build

- [ ] Clean project: `flutter clean`
- [ ] Get dependencies: `flutter pub get`
- [ ] Clean Gradle cache: `cd android && ./gradlew clean`

### Build Release APK

```bash
# Build release APK
flutter build apk --release

# Or build app bundle for Play Store
flutter build appbundle --release
```

### Test Each Package

**1. Google Sign-In**
- [ ] Try signing in with Google account
- [ ] Verify profile data is retrieved
- [ ] Test sign out and re-sign in

**2. nb_utils Functions**
- [ ] Test toast messages: `toast("Test")`
- [ ] Test navigation helpers
- [ ] Test utility functions (validation, formatting, etc.)

**3. File Picker**
- [ ] Select image from gallery
- [ ] Select document/file
- [ ] Verify file path is accessible
- [ ] Test file upload

**4. Network/API Calls**
- [ ] Test API endpoints
- [ ] Verify data loading
- [ ] Test error handling

**5. Firebase Services**
- [ ] Test push notifications
- [ ] Verify analytics events
- [ ] Check Crashlytics (force a test crash)

---

## Debugging Release Mode Issues

### 1. Enable Logging in Release

Add this to your `main()` to see logs in release:

```dart
void main() {
  // Enable logging even in release mode (for debugging)
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      // Print to console even in release
      print(message);
    };
  }

  runApp(MyApp());
}
```

### 2. Build Profile Mode

Profile mode is like release but allows debugging:

```bash
flutter build apk --profile
flutter install --profile
```

### 3. Check Logcat

Connect your device and monitor logs:

```bash
adb logcat | grep -i "flutter\|doctak"
```

### 4. Firebase Crashlytics

Check Firebase Crashlytics console for crash reports:
- Go to Firebase Console → Crashlytics
- Look for crashes in release builds

---

## Common Error Messages & Solutions

### "PlatformException(sign_in_failed, ...)"
- **Cause**: SHA-1 not registered or incorrect OAuth configuration
- **Solution**: Verify SHA-1 certificates in Firebase Console

### "java.io.FileNotFoundException" or "Permission denied"
- **Cause**: Storage permissions not granted or scoped storage violation
- **Solution**: Request runtime permissions, use path_provider

### "Unable to resolve host" or "Network error"
- **Cause**: Network security config blocking requests
- **Solution**: Check network_security_config.xml, ensure HTTPS

### App crashes immediately on launch
- **Cause**: ProGuard stripped required classes
- **Solution**: Check proguard-rules.pro, add keep rules for your models

### "NoSuchMethodError" or "ClassNotFoundException"
- **Cause**: ProGuard obfuscated method/class names
- **Solution**: Add `-keep` rules in proguard-rules.pro

---

## Quick Fix Commands

```bash
# 1. Clean everything
flutter clean
cd android && ./gradlew clean && cd ..

# 2. Get dependencies
flutter pub get

# 3. Build release (with verbose output)
flutter build apk --release --verbose

# 4. Install and test
flutter install --release

# 5. Monitor logs while testing
adb logcat | grep -E "flutter|doctak|GoogleSignIn|FilePicker"
```

---

## Additional Resources

- [Flutter Release Mode Documentation](https://docs.flutter.dev/deployment/android)
- [ProGuard Rules Guide](https://developer.android.com/studio/build/shrink-code)
- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Google Sign-In Troubleshooting](https://pub.dev/packages/google_sign_in#troubleshooting)
- [Android Scoped Storage](https://developer.android.com/training/data-storage)

---

## Summary

Your configuration is mostly correct. The main potential issues are:

1. ✅ **SHA-1 Certificates**: Both debug and release are registered
2. ✅ **ProGuard Rules**: Comprehensive rules added
3. ✅ **Network Security**: Properly configured
4. ⚠️ **Play Store SHA-1**: May need to add if publishing to Play Store
5. ⚠️ **Runtime Permissions**: Ensure proper permission requests
6. ⚠️ **Scoped Storage**: Use path_provider for file operations

**Next Steps**:
1. If published on Play Store, add Play Store SHA-1 to Firebase
2. Test with profile mode first: `flutter build apk --profile`
3. Check logs during testing: `adb logcat`
4. Report specific error messages if issues persist
