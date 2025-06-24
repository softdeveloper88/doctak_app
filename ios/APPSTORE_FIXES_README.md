# iOS App Store Connect Fixes

This document explains the fixes for the iOS App Store Connect warnings.

## Issues Fixed

### 1. Missing NSUserActivityTypes Info.plist Value

**Warning:** "Apps with the com.apple.developer.usernotifications.communication entitlement must specify either "INSendMessageIntent" or "INStartCallIntent" in the value of the NSUserActivityTypes Info.plist key."

**Fix Applied:** Added NSUserActivityTypes array to Info.plist with required intent types.

### 2. Missing dSYM Files for Agora Frameworks

**Warning:** "The archive did not include a dSYM for the AgoraAiEchoCancellationExtension.framework and AgoraAiEchoCancellationLLExtension.framework"

**Fixes Applied:**
- Updated Podfile with specific build settings for Agora frameworks
- Created automated scripts to generate missing dSYM files
- Added build configuration to ensure proper debug symbol generation

## How to Apply These Fixes

### Automatic Fixes (Already Applied)

1. **Info.plist Update** ✅
   - NSUserActivityTypes array added with INSendMessageIntent and INStartCallIntent

2. **Podfile Update** ✅
   - Added specific build settings for Agora frameworks in post_install hook
   - Enabled debug symbol generation for Agora targets

### Manual Steps Required

#### Step 1: Add Build Phase Script (Recommended)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the "Runner" target
3. Go to "Build Phases" tab
4. Click "+" and add "New Run Script Phase"
5. Move this new script phase to be AFTER "Embed Pods Frameworks"
6. Name it "Fix Agora dSYMs"
7. Add this script content:

```bash
# Fix Agora dSYM files for App Store submission
if [ "${CONFIGURATION}" = "Release" ]; then
    echo "🔧 Running Agora dSYM fix..."
    "${SRCROOT}/scripts/post_build_dsym_fix.sh"
fi
```

8. Add Input Files:
   - `$(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME).app`

9. Add Output Files:
   - `$(BUILT_PRODUCTS_DIR)/*.dSYM`

#### Step 2: Clean and Rebuild

1. Clean build folder: `Product > Clean Build Folder` (Cmd+Shift+K)
2. Delete `ios/Pods` folder
3. Run `flutter clean`
4. Run `flutter pub get`
5. Run `cd ios && pod install --repo-update`
6. Build for release: `flutter build ios --release`

#### Step 3: Create Archive for App Store

1. Open project in Xcode
2. Select "Any iOS Device" as destination
3. Product > Archive
4. Wait for archive to complete
5. In Organizer, select your archive and click "Distribute App"
6. Choose "App Store Connect"
7. Follow the upload process

### Alternative Manual Fix (If Scripts Don't Work)

If the automated scripts don't resolve the issue, you can manually create the dSYM files:

```bash
# Navigate to your build directory
cd ios/build/Release-iphoneos

# For each missing framework, create dSYM manually
for framework in "AgoraAiEchoCancellationExtension" "AgoraAiEchoCancellationLLExtension"; do
    if [ -f "Runner.app/Frameworks/${framework}.framework/${framework}" ]; then
        dsymutil "Runner.app/Frameworks/${framework}.framework/${framework}" -o "${framework}.framework.dSYM"
    fi
done
```

## Verification

### Check Info.plist Fix
Run this command to verify NSUserActivityTypes is present:
```bash
/usr/libexec/PlistBuddy -c "Print NSUserActivityTypes" ios/Runner/Info.plist
```

Expected output:
```
Array {
    INSendMessageIntent
    INStartCallIntent
}
```

### Check dSYM Generation
After building, verify dSYM files exist:
```bash
ls -la ios/build/Release-iphoneos/*.dSYM
```

You should see dSYM files for all frameworks including:
- `AgoraAiEchoCancellationExtension.framework.dSYM`
- `AgoraAiEchoCancellationLLExtension.framework.dSYM`

## Troubleshooting

### If You Still Get dSYM Warnings

1. **Check Build Settings:**
   - Ensure `DEBUG_INFORMATION_FORMAT` is set to `dwarf-with-dsym` for Release
   - Verify `STRIP_INSTALLED_PRODUCT` is set to `NO`

2. **Manual dSYM Creation:**
   - Use the alternative manual fix above
   - Or contact Agora support for pre-built dSYM files

3. **Update Agora SDK:**
   - Consider updating to the latest version of agora_rtc_engine
   - Newer versions may include proper dSYM files

### If Communication Features Don't Work

1. **Verify Entitlements:**
   - Check that `com.apple.developer.usernotifications.communication` is in your entitlements
   - Ensure your Apple Developer account supports communication notifications

2. **Test Intents:**
   - Verify that your app properly handles INSendMessageIntent and INStartCallIntent
   - Update intent handling code if necessary

## Files Created/Modified

- ✅ `ios/Runner/Info.plist` - Added NSUserActivityTypes
- ✅ `ios/Podfile` - Added Agora build settings
- ✅ `ios/fix_agora_dsyms.sh` - Manual dSYM fix script
- ✅ `ios/scripts/post_build_dsym_fix.sh` - Automated build phase script
- ✅ `ios/Runner/AgoraDebugSettings.xcconfig` - Build configuration
- ✅ `ios/APPSTORE_FIXES_README.md` - This documentation

## Next Steps

1. Follow the manual steps above to add the build script
2. Test the build process with a release build
3. Create an archive and upload to App Store Connect
4. Verify that the warnings are resolved

If you continue to experience issues, please refer to the troubleshooting section or reach out for additional support.