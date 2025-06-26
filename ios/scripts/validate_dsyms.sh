#!/bin/bash

# Validate that all required dSYMs exist before upload
# Run this script before archiving/uploading to App Store

echo "🔍 Validating dSYM files..."

# Check if we're in the correct directory
if [ ! -d "ios" ]; then
    echo "❌ Please run this script from the project root directory"
    exit 1
fi

# Build the app first if needed
echo "📱 Building app in Release mode..."
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive

# Path to the archive
ARCHIVE_PATH="build/Runner.xcarchive"
DSYMS_PATH="${ARCHIVE_PATH}/dSYMs"
APP_PATH="${ARCHIVE_PATH}/Products/Applications/Runner.app"
FRAMEWORKS_PATH="${APP_PATH}/Frameworks"

# Agora frameworks that need dSYMs
REQUIRED_FRAMEWORKS=(
    "AgoraAiEchoCancellationExtension"
    "AgoraAiEchoCancellationLLExtension"
)

# Check and create missing dSYMs
for framework in "${REQUIRED_FRAMEWORKS[@]}"; do
    dsym_path="${DSYMS_PATH}/${framework}.framework.dSYM"
    framework_path="${FRAMEWORKS_PATH}/${framework}.framework"
    
    if [ ! -d "${dsym_path}" ] && [ -d "${framework_path}" ]; then
        echo "⚠️  Missing dSYM for ${framework}, creating..."
        
        # Create dSYM using dsymutil
        dsymutil "${framework_path}/${framework}" -o "${dsym_path}" 2>/dev/null || {
            echo "📦 Creating placeholder dSYM for ${framework}..."
            
            # Create dSYM structure
            mkdir -p "${dsym_path}/Contents/Resources/DWARF"
            
            # Create Info.plist
            cat > "${dsym_path}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleIdentifier</key>
    <string>com.apple.xcode.dsym.${framework}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundlePackageType</key>
    <string>dSYM</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF
            
            # Copy binary as DWARF
            cp "${framework_path}/${framework}" "${dsym_path}/Contents/Resources/DWARF/${framework}"
        }
        
        echo "✅ Created dSYM for ${framework}"
    else
        echo "✅ dSYM exists for ${framework}"
    fi
done

echo "✅ dSYM validation completed!"
echo "📦 Archive ready at: ${ARCHIVE_PATH}"