#!/bin/bash

# Wrapper script to build and run release mode
# Fixes: APK location issue and ensures clean build

set -e

echo "========================================"
echo "Building Release Mode (Fixed)"
echo "========================================"
echo ""

# Clean previous build artifacts
echo "[1/4] Cleaning previous build..."
flutter clean > /dev/null 2>&1
rm -rf build/ android/.gradle/ android/app/build/ > /dev/null 2>&1

# Get dependencies
echo "[2/4] Getting dependencies..."
flutter pub get > /dev/null 2>&1

# Build the release APK
echo "[3/4] Building release APK..."
flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Build completed successfully!"
    echo ""

    # Copy APK to where Flutter expects it
    mkdir -p build/app/outputs/flutter-apk/
    cp build/app/outputs/apk/release/app-release.apk build/app/outputs/flutter-apk/app-release.apk

    APK_SIZE=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "APK Size: $APK_SIZE"
    echo ""

    # Install on device
    echo "[4/4] Installing on device..."
    flutter install --release

    if [ $? -eq 0 ]; then
        echo ""
        echo "========================================"
        echo "✓ SUCCESS - App Running in Release Mode"
        echo "========================================"
        echo ""
        echo "Test these features:"
        echo "  1. Launch app (should not crash)"
        echo "  2. Google Sign-In"
        echo "  3. Images load properly"
        echo "  4. Navigation and other features"
        echo ""
        echo "To monitor logs:"
        echo "  adb logcat -c"
        echo "  adb logcat | grep -E 'flutter|FATAL|GoogleSignIn|CachedImage'"
        echo ""
    else
        echo "✗ Installation failed"
        exit 1
    fi
else
    echo "✗ Build failed"
    exit 1
fi
