#!/bin/bash

# Complete Clean and Rebuild Script for Release Mode Fix
# This script thoroughly cleans all caches and rebuilds

set -e

echo "========================================"
echo "DocTak Release Mode - Complete Clean & Rebuild"
echo "========================================"
echo ""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Step 1: Clean Flutter
print_step "1/8 Cleaning Flutter project..."
flutter clean

# Step 2: Clean Gradle
print_step "2/8 Cleaning Gradle cache and build..."
cd android
./gradlew clean
./gradlew cleanBuildCache
cd ..

# Step 3: Delete build folders manually
print_step "3/8 Deleting all build folders..."
rm -rf build/
rm -rf android/.gradle/
rm -rf android/app/build/
rm -rf android/.idea/
rm -rf .dart_tool/

print_info "All build artifacts deleted"

# Step 4: Clean pub cache for this project
print_step "4/8 Cleaning pub cache..."
flutter pub cache clean
flutter pub get

print_info "Dependencies refreshed"

# Step 5: Verify ProGuard rules
print_step "5/8 Verifying ProGuard rules..."
if [ -f "android/app/proguard-rules.pro" ]; then
    rules_count=$(wc -l < android/app/proguard-rules.pro)
    print_info "✓ ProGuard rules file exists with $rules_count lines"
else
    print_warning "✗ ProGuard rules file NOT found!"
    exit 1
fi

# Step 6: Verify build.gradle configuration
print_step "6/8 Checking build.gradle configuration..."
if grep -q "proguardFiles" android/app/build.gradle; then
    print_info "✓ ProGuard files configured in build.gradle"
else
    print_warning "✗ ProGuard files NOT configured in build.gradle!"
fi

if grep -q "debuggable true" android/app/build.gradle; then
    print_info "✓ Release build is debuggable (for testing)"
else
    print_warning "✗ Release build is NOT debuggable"
fi

# Step 7: Build release APK
print_step "7/8 Building release APK..."
echo ""
print_info "Building with verbose output to see R8 behavior..."
echo ""

flutter build apk --release --verbose 2>&1 | tee build_output.log

# Check if build succeeded
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    print_step "✓ Build completed successfully!"
    echo ""

    # Show APK info
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
    if [ -f "$APK_PATH" ]; then
        print_info "APK Location: $APK_PATH"
        print_info "APK Size: $(du -h "$APK_PATH" | cut -f1)"
    fi

    # Check for R8 warnings in build log
    echo ""
    print_step "Checking build log for R8 warnings..."
    if grep -i "r8.*warning" build_output.log > /dev/null 2>&1; then
        print_warning "R8 warnings detected - check build_output.log"
        grep -i "r8.*warning" build_output.log | head -5
    else
        print_info "✓ No R8 warnings detected"
    fi

else
    print_warning "✗ Build failed! Check build_output.log for details"
    exit 1
fi

# Step 8: Install and test
echo ""
print_step "8/8 Installing release APK..."

read -p "Install release APK now? [Y/n]: " install_choice
if [ "$install_choice" != "n" ] && [ "$install_choice" != "N" ]; then

    # Check if device is connected
    if ! adb devices | grep -q "device$"; then
        print_warning "No device connected! Please connect a device and run:"
        echo "  flutter install --release"
        exit 0
    fi

    print_info "Installing release APK..."
    flutter install --release

    echo ""
    print_step "Testing release mode..."
    echo ""
    print_info "Manual tests to perform:"
    echo "  1. Open the app"
    echo "  2. Try Google Sign-In"
    echo "  3. Check if images load"
    echo "  4. Test other features"
    echo ""

    read -p "Monitor logcat? [Y/n]: " logcat_choice
    if [ "$logcat_choice" != "n" ] && [ "$logcat_choice" != "N" ]; then
        print_info "Starting logcat monitoring (Ctrl+C to stop)..."
        echo ""
        adb logcat -c  # Clear logcat first
        adb logcat | grep -E "flutter|GoogleSignIn|CachedImage|doctak" --color=always
    fi
fi

echo ""
echo "========================================"
echo "Troubleshooting Tips"
echo "========================================"
echo ""
echo "If Google Sign-In still fails:"
echo "  1. Check logcat for specific errors"
echo "  2. Verify Firebase SHA-1 certificates"
echo "  3. Try: adb logcat | grep GoogleSignIn"
echo ""
echo "If images still don't load:"
echo "  1. Check logcat for network errors"
echo "  2. Try: adb logcat | grep CachedImage"
echo "  3. Test with one specific image URL"
echo ""
echo "Build log saved to: build_output.log"
echo "========================================"
