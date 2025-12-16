# Testing Guide - Pigeon Platform Channel Fix

## Changes Made (Latest)

### 1. ProGuard Configuration Updated
- Changed from `proguard-android-optimize.txt` to `proguard-android.txt` (less aggressive)
- Added comprehensive keep rules for:
  - All Flutter embedding classes
  - All Flutter plugin communication classes (MethodChannel, BinaryMessenger, etc.)
  - Specific Google Sign-In plugin classes by name
  - Specific SharedPreferences plugin classes by name
  - All Pigeon-generated API classes

### 2. Build Configuration
- Added `profile` build type for testing with same minification as release
- Kept R8 full mode disabled (`android.enableR8.fullMode=false`)

### 3. Files Modified
- `android/app/build.gradle` - Changed ProGuard file and added profile build type
- `android/app/proguard-rules.pro` - Added Flutter channel communication rules
- `android/app/r8-rules.pro` - Added specific plugin class keep rules

## Testing Steps

### Step 1: Test Release APK Locally (CRITICAL)

Before uploading to Play Store, test the release APK on a physical device:

```bash
# Install the release APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Monitor logs for errors
adb logcat | grep -E "flutter|channel-error|PlatformException"
```

**Test these features:**
1. ✅ Open app - should reach login screen without crashes
2. ✅ Click "Sign in with Google" - should show Google account picker
3. ✅ Complete Google Sign-In - should login successfully
4. ✅ Logout and try manual login with email/password
5. ✅ Enable "Remember Me" checkbox
6. ✅ Close app completely (force stop)
7. ✅ Reopen app - should auto-login (tests SharedPreferences)
8. ✅ Check logcat - should see NO "channel-error" messages

**Expected Results:**
- ✅ NO "PlatformException(channel-error, Unable to establish connection...)"
- ✅ Google Sign-In works smoothly
- ✅ SharedPreferences persists login state
- ✅ Manual login works

**If Errors Still Occur:**
See "Emergency Fix" section below.

### Step 2: Upload to Play Store Internal Testing

```bash
# Upload the AAB file
# Location: build/app/outputs/bundle/release/app-release.aab (200.4MB)
```

1. Go to Google Play Console
2. Select "Internal Testing" track
3. Create new release
4. Upload `app-release.aab`
5. Complete release notes
6. Submit for review

### Step 3: Test Play Store Build

After Play Store processes the build (usually 30-60 minutes):

1. Download app from Internal Testing link
2. Repeat all tests from Step 1
3. Monitor Firebase Crashlytics for any crashes
4. Check for "channel-error" in Crashlytics logs

### Step 4: Monitor Production

After promoting to production:
- Monitor Firebase Crashlytics for first 24-48 hours
- Check for spike in "channel-error" crashes
- Monitor Google Sign-In success rate
- Check user reviews for login issues

## Verification Commands

### Check if ProGuard is working correctly
```bash
# After building, check the mapping file
cat build/app/outputs/mapping/release/mapping.txt | grep -A 5 "io.flutter.plugins.googlesignin"
cat build/app/outputs/mapping/release/mapping.txt | grep -A 5 "io.flutter.plugins.sharedpreferences"
```

**What to look for:**
- If classes are NOT obfuscated, you'll see original names
- If classes ARE obfuscated, you'll see mappings like `a.b.c -> io.flutter.plugins.googlesignin.Messages`
- We want NO obfuscation for these plugin classes

### Check APK contents
```bash
# Extract and check if plugin classes exist
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "googlesignin"
unzip -l build/app/outputs/flutter-apk/app-release.apk | grep "sharedpreferences"
```

## Emergency Fix - If Issues Persist

If you still see channel errors after testing the APK locally, we need to completely disable minification:

### Option A: Disable Minification (Temporary)

Edit `android/app/build.gradle`:

```groovy
buildTypes {
    release {
        minifyEnabled false  // ← Change from true to false
        shrinkResources false  // ← Change from true to false
        multiDexEnabled true
        
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro', 'r8-rules.pro'
        
        debuggable false
        signingConfig = signingConfigs.release
        
        firebaseCrashlytics {
            mappingFileUploadEnabled false  // ← Change from true to false
        }
    }
}
```

Then rebuild:
```bash
flutter clean
flutter build appbundle --release
```

**Note:** This will increase APK size significantly but guarantees no obfuscation issues.

### Option B: Nuclear ProGuard Rules

If Option A works but you want to keep minification, add this to `r8-rules.pro`:

```proguard
# NUCLEAR OPTION - Keep ALL Flutter classes
-keep class io.flutter.** { *; }
-keep interface io.flutter.** { *; }
-keepclassmembers class io.flutter.** { *; }
-keepnames class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep ALL plugin classes without ANY modification
-keep class * implements io.flutter.embedding.engine.plugins.FlutterPlugin { *; }
-keep class * implements io.flutter.plugin.common.MethodCallHandler { *; }
```

## Comparison: Profile Mode vs Release Build

| Feature | Profile Mode (VS Code) | Release Build (Play Store) |
|---------|----------------------|---------------------------|
| Minification | NO | YES |
| Obfuscation | NO | YES |
| Code Shrinking | NO | YES |
| Optimization | MINIMAL | AGGRESSIVE |
| Why it works | Original class names preserved | ProGuard must preserve plugin classes |

## Key ProGuard Rules Applied

```proguard
# Google Sign-In - Absolute Protection
-keep class io.flutter.plugins.googlesignin.** { *; }
-keep interface io.flutter.plugins.googlesignin.** { *; }
-keep class io.flutter.plugins.googlesignin.Messages { *; }
-keep class io.flutter.plugins.googlesignin.Messages$** { *; }
-keep class io.flutter.plugins.googlesignin.GoogleSignInPlugin { *; }

# SharedPreferences - Absolute Protection  
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep interface io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.sharedpreferences.Messages { *; }
-keep class io.flutter.plugins.sharedpreferences.Messages$** { *; }

# Flutter Communication Channels
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.BinaryMessenger { *; }
-keep class io.flutter.plugin.common.BasicMessageChannel { *; }
-keep class io.flutter.embedding.** { *; }
```

## Success Indicators

✅ **APK Testing Success:**
- App launches without crashes
- Google Sign-In works
- Manual login works
- "Remember Me" persists after app restart
- No "channel-error" in logcat

✅ **Play Store Success:**
- No spike in crashes after release
- Google Sign-In success rate normal
- No negative reviews about login issues
- Firebase Crashlytics shows no "channel-error" exceptions

## Troubleshooting

### "Still getting channel-error in release APK"
→ Try Emergency Fix Option A (disable minification)

### "Google Sign-In works but SharedPreferences doesn't"
→ Check AndroidManifest.xml for missing permissions
→ Verify device has storage permissions

### "Works in Internal Testing but fails in Production"
→ Verify SHA-1 certificate fingerprint matches production keystore
→ Check Firebase Console for correct package name and signing certificate

### "APK is too large after disabling minification"
→ Use app bundle (.aab) instead of APK
→ Enable app bundle size optimization in Play Console
→ Consider using split APKs for different architectures

## Build Artifacts

- **App Bundle (for Play Store):** `build/app/outputs/bundle/release/app-release.aab` (200.4MB)
- **APK (for testing):** `build/app/outputs/flutter-apk/app-release.apk` (335.6MB)
- **Mapping File:** `build/app/outputs/mapping/release/mapping.txt`

## Next Steps

1. ✅ Test release APK locally (Step 1)
2. ⏳ If successful, upload to Internal Testing
3. ⏳ Test Play Store build
4. ⏳ Monitor for 24-48 hours
5. ⏳ Promote to production if stable
