#!/bin/bash

# Build and run in PROFILE MODE (works like release but with working plugins)
# This is the recommended mode for testing "release" builds

set -e

echo "========================================"
echo "Building PROFILE Mode (WORKING)"
echo "========================================"
echo ""
echo "Profile mode = Release performance + Working plugins"
echo ""

# Clean previous build
echo "[1/4] Cleaning previous build..."
flutter clean > /dev/null 2>&1
rm -rf build/ android/.gradle/ android/app/build/ > /dev/null 2>&1

# Get dependencies
echo "[2/4] Getting dependencies..."
flutter pub get > /dev/null 2>&1

# Build profile APK
echo "[3/4] Building profile APK (AOT + debuggable)..."
flutter build apk --profile

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Build completed successfully!"
    echo ""

    # Copy APK
    mkdir -p build/app/outputs/flutter-apk/
    cp build/app/outputs/apk/profile/app-profile.apk build/app/outputs/flutter-apk/

    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-profile.apk | cut -f1)
    echo "APK Size: $APK_SIZE"
    echo ""

    # Install
    echo "[4/4] Installing on device..."
    flutter install --profile

    if [ $? -eq 0 ]; then
        echo ""
        echo "========================================"
        echo "✓ SUCCESS - App Running in PROFILE Mode"
        echo "========================================"
        echo ""
        echo "Profile mode provides:"
        echo "  ✓ AOT compilation (fast like release)"
        echo "  ✓ Working plugins (no MissingPluginException)"
        echo "  ✓ Google Sign-In should work"
        echo "  ✓ Cached images should work"
        echo ""
        echo "Test these features:"
        echo "  1. App launches ✓"
        echo "  2. Google Sign-In"
        echo "  3. Images load properly"
        echo "  4. All features work"
        echo ""
        echo "To monitor logs:"
        echo "  adb logcat -c"
        echo "  adb logcat | grep -E 'flutter|GoogleSignIn|CachedImage|MissingPlugin'"
        echo ""
    else
        echo "✗ Installation failed"
        exit 1
    fi
else
    echo "✗ Build failed"
    exit 1
fi
