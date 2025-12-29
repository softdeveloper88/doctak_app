#!/bin/bash
# Script to set up iOS Screen Sharing Extension for DocTak app
# This script automates the creation of the Broadcast Upload Extension

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IOS_DIR="$SCRIPT_DIR"
PROJECT_DIR="$IOS_DIR/Runner.xcodeproj"
EXTENSION_DIR="$IOS_DIR/BroadcastUploadExtension"

echo "🚀 Setting up iOS Screen Sharing Extension..."

# Check if extension files exist
if [ ! -f "$EXTENSION_DIR/SampleHandler.swift" ]; then
    echo "❌ Extension files not found in $EXTENSION_DIR"
    echo "   Please ensure BroadcastUploadExtension folder exists with SampleHandler.swift"
    exit 1
fi

echo "✅ Extension files found"

# Update Podfile to include the extension target
PODFILE="$IOS_DIR/Podfile"
if ! grep -q "target 'BroadcastUploadExtension'" "$PODFILE"; then
    echo "📝 Adding BroadcastUploadExtension to Podfile..."
    
    # Add the extension target before the post_install block
    sed -i '' '/^post_install do |installer|/i\
\
target '\''BroadcastUploadExtension'\'' do\
  use_frameworks!\
  pod '\''AgoraRtcEngine_iOS/ReplayKit'\'', '\''~> 4.5.2'\''\
end\
' "$PODFILE"
    
    echo "✅ Podfile updated"
else
    echo "ℹ️  Podfile already contains BroadcastUploadExtension target"
fi

echo ""
echo "⚠️  IMPORTANT: Manual steps required in Xcode:"
echo ""
echo "1. Open Runner.xcworkspace in Xcode"
echo "2. File > New > Target... > Broadcast Upload Extension"
echo "3. Name it: BroadcastUploadExtension"
echo "4. Bundle ID: com.doctak.ios.BroadcastUploadExtension"
echo "5. Replace auto-generated files with files from ios/BroadcastUploadExtension/"
echo "6. Add App Groups capability: group.com.doctak.ios.screenshare"
echo "7. Run 'pod install' in the ios folder"
echo ""
echo "📖 See IOS_SCREEN_SHARING_SETUP.md for detailed instructions"
echo ""
echo "🔧 Running pod install..."
cd "$IOS_DIR"
pod install --repo-update || echo "⚠️  Pod install failed, please run manually"

echo ""
echo "✅ Setup script completed!"
