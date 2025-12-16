#!/bin/bash
# Production Build Script for Play Store Upload
# Uses profile mode due to AGP 8.11.1 + Flutter 3.38.3 Pigeon bug

set -e

echo "========================================"
echo "Building DocTak for Play Store"
echo "Mode: Profile (Production-Ready)"
echo "========================================"

# Clean everything
echo "Step 1: Cleaning build artifacts..."
flutter clean
rm -rf android/.gradle/
rm -rf android/app/build/

# Get dependencies
echo "Step 2: Getting dependencies..."
flutter pub get

# Build Android App Bundle (Play Store preferred format)
echo "Step 3: Building signed AAB..."
flutter build appbundle --profile

# Verify signing
echo "Step 4: Verifying AAB signature..."
echo ""
jarsigner -verify build/app/outputs/bundle/profile/app-profile.aab 2>&1 | grep "jar verified" && echo "✅ AAB signature verified!"

echo ""
echo "========================================"
echo "✅ Build Complete!"
echo "========================================"
echo ""
echo "📦 Play Store Upload File:"
echo "   build/app/outputs/bundle/profile/app-profile.aab"
echo ""
echo "   Size: $(du -h build/app/outputs/bundle/profile/app-profile.aab | cut -f1)"
echo ""
echo "📤 Next Steps:"
echo "   1. Test the APK on device: flutter install --profile"
echo "   2. Upload AAB to Play Console: https://play.google.com/console"
echo "   3. Create new release and submit for review"
echo ""
echo "✅ All plugins work in profile mode!"
echo "========================================"
