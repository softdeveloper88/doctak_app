# Google Sign-In and Cached Images Fix - Release Mode

## Problem

In **release mode** (not debug):
- ✗ Google Sign-In fails or shows "Sign-in cancelled"
- ✗ Cached images don't load (CachedNetworkImage)
- ✓ Other APIs and packages work fine

## Root Cause

You're using **Android Gradle Plugin (AGP) 8.11.1**. In AGP 8.0+:

> **R8 ALWAYS RUNS, even with `minifyEnabled false`**

R8 optimization in AGP 8+ can:
1. Strip away Pigeon-generated code (used by Google Sign-In plugin)
2. Optimize away HTTP client configurations (breaks CachedNetworkImage)
3. Remove classes that appear "unused" but are needed via reflection

## What Was Fixed

### 1. Updated `proguard-rules.pro`

Added comprehensive rules for:
- ✅ **Google Sign-In**: All GMS classes, Pigeon channels, auth APIs
- ✅ **CachedNetworkImage**: Flutter Cache Manager, HTTP client, path provider
- ✅ **R8 Optimization**: Disabled aggressive optimizations with `-dontoptimize`

### 2. Updated `build.gradle`

```gradle
release {
    minifyEnabled false
    shrinkResources false

    // CRITICAL: ProGuard rules now REQUIRED for AGP 8.0+
    proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
}
```

### 3. Updated `gradle.properties`

```properties
# Disable R8 full mode for better compatibility
android.enableR8.fullMode=false
```

---

## Testing Steps

### Step 1: Clean Build

```bash
# Clean everything
flutter clean
cd android && ./gradlew clean && cd ..

# Get fresh dependencies
flutter pub get
```

### Step 2: Build Release APK

```bash
# Build release
flutter build apk --release --verbose
```

Watch the build output for:
- ✓ "R8" task running (this is expected)
- ✓ "Applying ProGuard rules" (confirms rules are loaded)
- ✗ No warnings about "can't find referenced class"

### Step 3: Install and Test

```bash
# Install release APK
flutter install --release

# In a separate terminal, monitor logs
adb logcat | grep -E "flutter|GoogleSignIn|CachedImage|R8"
```

### Step 4: Test Google Sign-In

1. Open the app
2. Tap "Sign in with Google"
3. **Expected behavior**:
   - Google account picker appears
   - Sign-in completes successfully
   - User profile loaded

**If it fails**, check logcat for:
```
PlatformException(sign_in_failed, ...)
```

This usually means:
- SHA-1 certificate issue (but yours are configured correctly)
- Pigeon channel issue (should be fixed by ProGuard rules)

### Step 5: Test Cached Images

1. Navigate to any screen with user avatars or post images
2. **Expected behavior**:
   - Images load and display
   - Smooth scrolling
   - Images cached (scroll up/down, images appear instantly)

**If it fails**, check logcat for:
```
CachedNetworkImageProvider - Unable to load image
SocketException: Connection refused
```

This usually means:
- HTTP client not initialized (should be fixed)
- Network security config issue (already configured correctly)

---

## Quick Test Script

Use the automated test script:

```bash
./test_release_build.sh
```

Choose option 1 (Profile mode) first to test with debugging enabled.

---

## If Issues Persist

### For Google Sign-In Issues

1. **Verify SHA-1 in Firebase Console**

   Go to [Firebase Console](https://console.firebase.google.com/) → Your Project → Project Settings → Your Android App

   Verify these SHA-1 certificates are listed:
   ```
   93:6E:26:CF:43:3B:54:B9:23:7B:7A:CB:66:10:D3:A9:D3:95:2A:40 (Debug)
   50:1D:B4:67:A1:D3:2D:8A:ED:E2:39:06:E7:DD:6A:49:61:41:AB:17 (Release)
   ```

2. **Check if Published on Play Store**

   If your app is on Google Play Store, you MUST add the Play Store's SHA-1:

   - Go to [Google Play Console](https://play.google.com/console/)
   - Select app → Release → Setup → App Signing
   - Copy SHA-1 from "App signing key certificate"
   - Add to Firebase Console

3. **Download Fresh google-services.json**

   After adding certificates:
   - Firebase Console → Project Settings → Your apps
   - Click "Download google-services.json"
   - Replace `android/app/google-services.json`

4. **Check OAuth Client IDs**

   ```bash
   # Verify OAuth clients in google-services.json
   grep -A 3 "oauth_client" android/app/google-services.json
   ```

   Should show multiple client entries with your certificate hashes.

### For Cached Images Issues

1. **Test Network Connectivity**

   Add debug logging to check if images are loading:

   ```dart
   // In your CustomCacheManager or where images fail
   debugPrint('🔍 Loading image: $url');
   debugPrint('🔍 Using CustomCacheManager');
   ```

2. **Check Image URLs**

   Ensure image URLs are valid:
   - Use HTTPS (not HTTP)
   - URLs are reachable (test in browser)
   - No certificate issues

3. **Test with Standard CachedNetworkImage**

   Temporarily remove CustomCacheManager to isolate the issue:

   ```dart
   // Test with default cache manager
   CachedNetworkImage(
     imageUrl: url,
     // cacheManager: CustomCacheManager(), // Comment out
   )
   ```

4. **Clear App Data**

   ```bash
   adb shell pm clear com.kt.doctak
   ```

   Then reinstall and test fresh.

### For Other Package Issues

If you discover other packages are failing:

1. **Identify the package**: Check logcat for errors
2. **Add ProGuard rules**: Open `proguard-rules.pro`
3. **Add keep rule** for that package:
   ```proguard
   -keep class com.package.name.** { *; }
   ```

---

## Detailed Error Messages to Watch For

### Google Sign-In Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `PlatformException(sign_in_failed)` | SHA-1 or OAuth issue | Verify Firebase SHA-1s |
| `PlatformException(network_error)` | Network config | Check network_security_config.xml |
| `sign_in_canceled` | User cancelled OR Pigeon channel issue | Check ProGuard rules applied |
| `ApiException: 10` | Developer console config | Check OAuth 2.0 Client IDs |

### Cached Image Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `SocketException: Connection refused` | HTTP client not initialized | Check CustomCacheManager |
| `HandshakeException` | Certificate validation | Already handled in CustomHttpClient |
| `404 Not Found` | Invalid image URL | Check image URLs |
| `Unable to load image` | Cache manager stripped | Verify ProGuard rules |

---

## Build Configuration Summary

**Before (Not Working)**:
```gradle
release {
    minifyEnabled false
    // ProGuard rules commented out
    // R8 still running without rules = breaks things
}
```

**After (Should Work)**:
```gradle
release {
    minifyEnabled false
    // ProGuard rules INCLUDED (critical for AGP 8+)
    proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
}
```

---

## Key Files Changed

1. **`android/app/proguard-rules.pro`** - Comprehensive keep rules
2. **`android/app/build.gradle`** - Added proguardFiles reference
3. **`android/gradle.properties`** - Disabled R8 full mode

---

## Verification Checklist

Before declaring victory, verify:

- [ ] Release APK builds successfully
- [ ] No R8 warnings in build output
- [ ] Google Sign-In works in release mode
- [ ] User profile data loads after sign-in
- [ ] Images load on home screen
- [ ] Images load on profile screens
- [ ] Images cache properly (scroll test)
- [ ] App doesn't crash on startup
- [ ] No native library errors in logcat

---

## Next Steps

1. **Build release APK**: `flutter build apk --release`
2. **Test thoroughly**: Use the test script or manual testing
3. **Monitor logs**: Keep `adb logcat` running during tests
4. **Report specific errors**: If still failing, share exact error messages

---

## Additional Notes

### Why R8 Still Runs

AGP 8+ changed the behavior:
- **AGP 7.x and earlier**: `minifyEnabled false` = No R8 at all
- **AGP 8.x**: `minifyEnabled false` = R8 runs, but no shrinking/obfuscation
- **Solution**: ProGuard rules are now required to prevent R8 optimizations

### Why Google Sign-In Fails

The Google Sign-In Flutter plugin uses **Pigeon** to generate platform channel code. R8 sees this generated code as "unused" and optimizes it away. The ProGuard rules with `-keep class io.flutter.plugins.googlesignin.**` prevent this.

### Why CachedNetworkImage Fails

Your `CustomCacheManager` creates an `HttpClient` with custom settings (certificate bypass). R8 can optimize away the configuration, making the HTTP client fail. The ProGuard rules keep all HTTP-related classes intact.

---

## Success Indicators

You'll know it's working when:

1. **Google Sign-In**:
   - Account picker appears immediately
   - Sign-in flow is smooth
   - No delays or errors
   - Profile data loads

2. **Cached Images**:
   - Images appear on first load
   - Images cache (instant on second view)
   - No broken image icons
   - Smooth scrolling with images

3. **Build Output**:
   - No R8 warnings
   - Build completes without errors
   - APK size reasonable (not bloated)

---

## Still Having Issues?

If problems persist after following this guide:

1. **Share Build Output**: Copy the full output from `flutter build apk --release --verbose`
2. **Share Logcat**: Copy relevant errors from `adb logcat`
3. **Specify Which Package**: Exactly which feature is failing (sign-in step, specific screen for images)
4. **Test in Profile Mode**: Try `flutter build apk --profile` to get more debug info

---

**Last Updated**: After implementing AGP 8.11.1 compatibility fixes
