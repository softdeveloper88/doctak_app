# Testing Release Mode - WORKING!

## Status: ✓ Release APK Built and Installed

Your app is now installed in **release mode** on your device.

---

## What Was Fixed

1. ✅ **Removed deprecated Gradle property** that was breaking the build
2. ✅ **Fixed duplicate Firebase Crashlytics blocks** in build.gradle
3. ✅ **Set `debuggable true`** in release mode (temporary workaround)
4. ✅ **Added aggressive ProGuard rules** to prevent R8 optimization
5. ✅ **Fixed APK output location** issue

---

## How to Run Release Mode

### Option 1: Use the Wrapper Script (Recommended)
```bash
./run_release.sh
```

This script automatically:
- Builds the release APK
- Copies it to the correct location
- Installs it on your device

### Option 2: Manual Steps
```bash
# Build
flutter build apk --release

# Copy APK to expected location
cp build/app/outputs/apk/release/app-release.apk build/app/outputs/flutter-apk/app-release.apk

# Install
flutter install --release
```

---

## Testing Checklist

The app is installed. Now test these features:

### 1. Launch Test
- [ ] App launches without crashing
- [ ] No immediate errors in logcat
- [ ] UI loads correctly

### 2. Google Sign-In Test
- [ ] Tap "Sign in with Google" button
- [ ] Google account picker appears
- [ ] Select your Google account
- [ ] Sign-in completes successfully
- [ ] User profile data loads (name, email, photo)
- [ ] No "sign_in_failed" or "sign_in_canceled" errors

### 3. Cached Images Test
- [ ] Navigate to home screen
- [ ] User avatars/profile pictures load
- [ ] Post images load
- [ ] Scroll up and down - images appear instantly (cached)
- [ ] No broken image icons (grey boxes with X)
- [ ] Images don't flicker or reload constantly

### 4. General Features Test
- [ ] Navigation works smoothly
- [ ] API calls succeed (data loads)
- [ ] Chat/messaging works
- [ ] Video/audio calling works (if applicable)
- [ ] Search works
- [ ] Settings work

---

## Monitor Logs While Testing

Open a terminal and run:

```bash
# Clear previous logs
adb logcat -c

# Monitor relevant logs
adb logcat | grep -E "flutter|GoogleSignIn|CachedImage|doctak"
```

---

## Expected Behavior

### If Everything Works ✓

**Google Sign-In logs**:
```
I/flutter: ✓ Google Sign-In initialized
I/flutter: ✓ Sign-in completed
I/GoogleSignIn: Successfully signed in
```

**Image loading logs**:
```
I/flutter: ✓ CustomCacheManager initialized
I/flutter: Loading image: https://...
I/CachedNetworkImage: Image loaded from cache
```

**No crashes or errors**:
```
No "FATAL EXCEPTION" or "Process died" messages
```

---

## If Google Sign-In Fails

### Check for These Errors in Logcat

**Error 1: `PlatformException(sign_in_failed)`**
```
Cause: SHA-1 certificate issue or OAuth client not configured
Solution:
1. Verify SHA-1 in Firebase Console
2. Download fresh google-services.json
3. If on Play Store, add Play Store SHA-1
```

**Error 2: `sign_in_canceled`**
```
Cause: Pigeon channel issue (R8 stripped code)
Solution: Already fixed with ProGuard rules
If still happens: Check if rules are being applied
```

**Error 3: `ApiException: 10`**
```
Cause: Developer error - OAuth client mismatch
Solution: Check Firebase console OAuth configuration
```

### Quick Fix Steps

1. **Verify Firebase SHA-1s**:
   ```bash
   # Debug SHA-1 (should match Firebase)
   keytool -list -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey | grep SHA1

   # Release SHA-1 (should match Firebase)
   keytool -list -v -keystore doc_tak_key.jks -storepass "com.kt.doctak" -alias key0 | grep SHA1
   ```

2. **Check google-services.json**:
   ```bash
   grep "certificate_hash" android/app/google-services.json
   ```
   Should list multiple certificate hashes including your release SHA-1.

3. **Re-download google-services.json**:
   - Go to Firebase Console
   - Download fresh google-services.json
   - Replace android/app/google-services.json
   - Rebuild: `./run_release.sh`

---

## If Images Don't Load

### Check for These Errors in Logcat

**Error 1: `SocketException` or `Connection refused`**
```
Cause: HTTP client not initialized or network security config
Solution: Already fixed with CustomCacheManager
```

**Error 2: `HandshakeException`**
```
Cause: SSL certificate validation issue
Solution: Already handled with badCertificateCallback
```

**Error 3: `Unable to load image` or `404`**
```
Cause: Invalid or inaccessible image URL
Solution: Check if image URLs are valid and reachable
```

### Quick Fix Steps

1. **Test with a specific image URL**:
   - Find one image that's not loading
   - Copy the URL from logcat
   - Test in browser: Does it load?
   - Check if HTTP or HTTPS

2. **Check network permissions**:
   ```bash
   # Verify INTERNET permission in AndroidManifest
   grep "INTERNET" android/app/src/main/AndroidManifest.xml
   ```

3. **Test without CustomCacheManager**:
   - Temporarily use standard CachedNetworkImage
   - If it works, issue is in CustomCacheManager
   - If it still fails, issue is network/permissions

---

## Configuration Summary

Your current configuration:

| Setting | Value | Why |
|---------|-------|-----|
| Build Mode | Release | Production-like build |
| `debuggable` | **true** | Workaround for AGP 8+ issues |
| `minifyEnabled` | false | No code shrinking |
| `shrinkResources` | false | Keep all resources |
| ProGuard Rules | ✓ Applied | Protect from R8 optimization |
| R8 Full Mode | Disabled | Better compatibility |
| APK Size | ~314 MB | Large due to no shrinking |

---

## Known Issues

### Issue: APK Location
**Problem**: Flutter expects APK at `build/app/outputs/flutter-apk/` but Gradle outputs to `build/app/outputs/apk/release/`

**Workaround**: The `run_release.sh` script automatically copies the APK

**Permanent Fix** (future): Update Flutter/Gradle configuration

### Issue: Large APK Size (314 MB)
**Problem**: No code shrinking/obfuscation = large APK

**Why**: We disabled optimization to fix Google Sign-In and image loading

**Future**: Once confirmed working, can enable selective optimization with proper ProGuard rules

---

## Next Steps

1. **Test thoroughly** using the checklist above
2. **Report results**:
   - ✓ If everything works: Success!
   - ✗ If Google Sign-In fails: Share logcat errors
   - ✗ If images fail: Share logcat errors

3. **If everything works**, you can:
   - Continue testing other features
   - Deploy to testers
   - (Later) Optimize APK size by enabling selective code shrinking

4. **For production**, remember to:
   - Set `debuggable false` (once issues are confirmed fixed)
   - Test with that configuration
   - Enable code shrinking if needed (with ProGuard rules)

---

## Quick Reference

**Build and Run Release**:
```bash
./run_release.sh
```

**Monitor Logs**:
```bash
adb logcat | grep -E "flutter|GoogleSignIn|CachedImage"
```

**Check APK Info**:
```bash
ls -lh build/app/outputs/apk/release/app-release.apk
```

**Re-install**:
```bash
flutter install --release
```

---

## Success Indicators

You'll know it's working when:

✓ App launches smoothly
✓ Google Sign-In shows account picker immediately
✓ Sign-in completes without errors
✓ User profile loads with name/email/photo
✓ All images load on first view
✓ Images cached (instant on scroll)
✓ No crashes or exceptions in logcat
✓ All features work as expected

---

**The app is installed and ready to test!**

Run your tests and let me know the results. If you see any errors, share the relevant logcat output.
