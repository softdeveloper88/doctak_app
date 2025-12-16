#!/bin/bash

# Release Build Testing Script for DocTak
# This script helps test packages in release mode

set -e  # Exit on error

echo "========================================"
echo "DocTak Release Build Test Script"
echo "========================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Clean build
print_step "Cleaning Flutter project..."
flutter clean

print_step "Cleaning Gradle cache..."
cd android && ./gradlew clean && cd ..

# 2. Get dependencies
print_step "Getting Flutter dependencies..."
flutter pub get

# 3. Verify SHA-1 certificates
print_step "Verifying keystore certificates..."
echo ""
echo "Debug SHA-1:"
keytool -list -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey 2>/dev/null | grep "SHA1:" || print_warning "Could not read debug keystore"
echo ""

if [ -f "doc_tak_key.jks" ]; then
    echo "Release SHA-1:"
    keytool -list -v -keystore doc_tak_key.jks -storepass "com.kt.doctak" -alias key0 2>/dev/null | grep "SHA1:" || print_warning "Could not read release keystore"
    echo ""
else
    print_warning "Release keystore not found at: doc_tak_key.jks"
fi

# 4. Check google-services.json
print_step "Checking google-services.json..."
if [ -f "android/app/google-services.json" ]; then
    echo "✓ google-services.json found"
    # Count OAuth clients
    oauth_count=$(grep -o '"client_type": 1' android/app/google-services.json | wc -l)
    echo "✓ Found $oauth_count OAuth clients configured"
else
    print_error "google-services.json not found!"
    exit 1
fi

# 5. Check ProGuard rules
print_step "Checking ProGuard rules..."
if [ -f "android/app/proguard-rules.pro" ]; then
    rules_count=$(grep -c "^-keep" android/app/proguard-rules.pro || echo "0")
    echo "✓ ProGuard rules file found with $rules_count keep rules"
else
    print_warning "ProGuard rules file not found"
fi

# 6. Build options
echo ""
echo "========================================"
echo "Choose build type:"
echo "========================================"
echo "1) Profile mode (recommended for testing - allows debugging)"
echo "2) Release mode (production build)"
echo "3) Both (profile first, then release)"
echo "4) Skip build (just run checks)"
echo ""
read -p "Enter choice [1-4]: " choice

case $choice in
    1)
        print_step "Building in PROFILE mode..."
        flutter build apk --profile --verbose
        BUILD_PATH="build/app/outputs/flutter-apk/app-profile.apk"
        ;;
    2)
        print_step "Building in RELEASE mode..."
        flutter build apk --release --verbose
        BUILD_PATH="build/app/outputs/flutter-apk/app-release.apk"
        ;;
    3)
        print_step "Building in PROFILE mode first..."
        flutter build apk --profile --verbose
        print_step "Building in RELEASE mode..."
        flutter build apk --release --verbose
        BUILD_PATH="build/app/outputs/flutter-apk/app-release.apk"
        ;;
    4)
        print_step "Skipping build as requested"
        exit 0
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

# 7. Check if build succeeded
if [ -f "$BUILD_PATH" ]; then
    print_step "Build successful!"
    echo ""
    echo "APK Location: $BUILD_PATH"
    echo "APK Size: $(du -h "$BUILD_PATH" | cut -f1)"
    echo ""

    # Ask if user wants to install
    read -p "Install APK on connected device? [y/N]: " install_choice
    if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
        print_step "Installing APK..."
        if [[ "$BUILD_PATH" == *"profile"* ]]; then
            flutter install --profile
        else
            flutter install --release
        fi

        print_step "Installation complete!"
        echo ""
        print_step "Starting logcat monitoring..."
        echo "Press Ctrl+C to stop"
        echo ""
        adb logcat | grep -E "flutter|doctak|GoogleSignIn|FilePicker|nb_utils" --color=always
    fi
else
    print_error "Build failed! Check the output above for errors."
    exit 1
fi

echo ""
echo "========================================"
echo "Testing Checklist"
echo "========================================"
echo "After installing, please test:"
echo ""
echo "[ ] Google Sign-In"
echo "    - Tap 'Sign in with Google'"
echo "    - Complete sign-in flow"
echo "    - Verify profile data loaded"
echo ""
echo "[ ] File Picker"
echo "    - Try picking an image"
echo "    - Try picking a document"
echo "    - Verify upload works"
echo ""
echo "[ ] nb_utils Functions"
echo "    - Test toast notifications"
echo "    - Test navigation"
echo "    - Test any dialogs"
echo ""
echo "[ ] Network/API Calls"
echo "    - Test data loading"
echo "    - Test API endpoints"
echo "    - Verify error handling"
echo ""
echo "[ ] Firebase Services"
echo "    - Send test notification"
echo "    - Check analytics"
echo "    - Verify crashlytics"
echo ""
echo "========================================"
