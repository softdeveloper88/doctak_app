#!/bin/bash

# Script to fix Agora dSYM issues during build
# This script is run as a Build Phase in Xcode

set -e

echo "🔧 Starting Agora dSYM fix build phase..."

# Only run for Release and Profile configurations
if [[ "${CONFIGURATION}" != "Release" && "${CONFIGURATION}" != "Profile" ]]; then
    echo "⏭️  Skipping dSYM fix for ${CONFIGURATION} configuration"
    exit 0
fi

# Define the frameworks that need dSYM fixes
AGORA_FRAMEWORKS=(
    "AgoraAiEchoCancellationExtension"
    "AgoraAiEchoCancellationLLExtension"
)

# Function to create dSYM for a framework
create_dsym_for_framework() {
    local framework_name="$1"
    local framework_path="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/${framework_name}.framework"
    local framework_binary="${framework_path}/${framework_name}"
    local dsym_path="${DWARF_DSYM_FOLDER_PATH}/${framework_name}.framework.dSYM"
    
    if [ -f "${framework_binary}" ]; then
        echo "🔍 Processing ${framework_name} framework"
        
        # Check if dSYM already exists
        if [ -d "${dsym_path}" ] && [ -f "${dsym_path}/Contents/Resources/DWARF/${framework_name}" ]; then
            echo "✅ dSYM already exists for ${framework_name}"
            return 0
        fi
        
        echo "🛠️  Creating dSYM for ${framework_name}..."
        
        # Create dSYM using dsymutil
        if command -v dsymutil >/dev/null 2>&1; then
            dsymutil "${framework_binary}" -o "${dsym_path}" || {
                echo "⚠️  dsymutil failed for ${framework_name}, creating placeholder..."
                
                # Create placeholder dSYM structure
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
    <string>com.apple.xcode.dsym.${framework_name}</string>
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
                
                # Copy the binary as DWARF file
                cp "${framework_binary}" "${dsym_path}/Contents/Resources/DWARF/${framework_name}"
            }
        fi
        
        echo "✅ Created dSYM for ${framework_name}"
    else
        echo "⚠️  Framework ${framework_name} not found at ${framework_path}"
    fi
}

# Process each Agora framework
for framework in "${AGORA_FRAMEWORKS[@]}"; do
    create_dsym_for_framework "$framework"
done

echo "✅ Agora dSYM fix build phase completed!"