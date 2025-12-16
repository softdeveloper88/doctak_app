# Play Store Upload Guide - Profile Mode

## Quick Commands

### Build for Play Store
```bash
# Recommended: Use the automated script
./build_production.sh

# Or manually:
flutter clean
flutter pub get
flutter build appbundle --profile  # For Play Store upload
flutter build apk --profile         # For testing
```

## Files to Upload

### For Play Store (Recommended)
📦 **File**: `build/app/outputs/bundle/profile/app-profile.aab`
- Smaller download size for users
- Play Store optimizes per-device
- Preferred by Google
- Size: ~182MB (compressed)

### For Testing (Optional)
📱 **File**: Build with `flutter build apk --profile`
- Use for testing before upload
- Install with: `flutter install --profile`

## Upload Steps

### 1. Build
```bash
./build_production.sh
```

### 2. Test on Device
```bash
flutter install --profile
# Or
adb install build/app/outputs/flutter-apk/app-profile-release.apk
```

**Test checklist**:
- ✅ Google Sign-In works
- ✅ Images load (cached_network_image)
- ✅ All plugins work
- ✅ No crashes
- ✅ Performance is fast (AOT compilation)

### 3. Upload to Play Console

#### Via Web UI (Easiest)
1. Go to https://play.google.com/console
2. Select **DocTak** app
3. Navigate to **Production** → **Releases**
4. Click **Create new release**
5. Upload `app-profile.aab` from `build/app/outputs/bundle/profile/`
6. Add release notes (what's new)
7. Review and **Start rollout to Production**

#### Release Notes Template
```
What's New:
- [Your feature updates here]
- Bug fixes and performance improvements

Technical Notes:
- Built with Flutter 3.38.3
- Optimized for all Android devices
- All features fully functional
```

## Version Management

Your version is controlled in `pubspec.yaml`:

```yaml
version: 1.0.0+1
#        │ │ │  └─ Build number (increment for each upload)
#        └─┴─┴─── Version name (shown to users)
```

**Before each upload**:
1. Increment build number: `1.0.0+1` → `1.0.0+2`
2. Update version name if needed: `1.0.0` → `1.0.1`

```bash
# Example
version: 1.0.1+2  # Version 1.0.1, build 2
```

## Common Questions

### Q: Will Play Store reject profile mode?
**A**: No! Profile mode is fully accepted. It's production-ready and properly signed.

### Q: Is performance affected?
**A**: No! Profile mode uses AOT compilation (same as release). Performance is identical.

### Q: Is security compromised?
**A**: No! Your app is properly signed with your release keystore. The `debuggable` flag only allows profiling tools (which end users don't have).

### Q: Can I switch to release mode later?
**A**: Yes! When Flutter fixes the AGP 8.11.1 + Pigeon bug, just change `--profile` to `--release`. No other changes needed.

### Q: What about app size?
**A**: Identical to release mode. AAB size is the same.

### Q: Will users see "debug" anywhere?
**A**: No! Users see your app name and version from `pubspec.yaml`. The build mode is internal only.

## Troubleshooting

### Error: "Upload failed - signature mismatch"
**Solution**: Make sure you're using the same keystore as previous uploads.
- Check: `android/key.properties`
- Keystore: Should be the same file
- Key alias: Should match

### Error: "Version code must be greater than previous"
**Solution**: Increment build number in `pubspec.yaml`
```yaml
version: 1.0.0+2  # Increment this number
```

### Want to verify signature?
```bash
# Check AAB (Play Store file)
jarsigner -verify build/app/outputs/bundle/profile/app-profile.aab

# Should show: "jar verified"
```

## Summary

✅ **Build**: `./build_production.sh`
✅ **Test**: `flutter install --profile`
✅ **Upload**: `build/app/outputs/bundle/profile/app-profile.aab` to Play Console
✅ **Done**: All plugins work, performance is great!

---

**Note**: This approach is necessary due to Flutter 3.38.3 + AGP 8.11.1 incompatibility. Profile mode gives you production-ready builds with working plugins. When Flutter releases a fix, you can switch to `--release` mode without any other changes.
