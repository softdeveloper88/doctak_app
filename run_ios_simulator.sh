#!/bin/bash
# Run iOS app on simulator (works around iOS 26 app extension bug)

set -e

echo "Building iOS app..."
cd "$(dirname "$0")"

# Build the app
flutter build ios --simulator --debug

# Remove the problematic BroadcastUploadExtension (iOS 26 simulator bug)
echo "Removing BroadcastUploadExtension (iOS 26 simulator workaround)..."
rm -rf build/ios/iphonesimulator/Runner.app/PlugIns/BroadcastUploadExtension.appex

# Install on the booted simulator
echo "Installing app on simulator..."
xcrun simctl install booted build/ios/iphonesimulator/Runner.app

# Launch the app
echo "Launching app..."
xcrun simctl launch booted com.doctak.ios

echo "✅ App is running on simulator!"
