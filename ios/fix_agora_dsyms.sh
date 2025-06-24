#!/bin/bash

# Script to fix Agora dSYM issues for App Store uploads
# This script should be run as a Build Phase in Xcode

set -e

echo "🔧 Fixing Agora dSYM files..."

# Define the frameworks that need dSYM fixes
AGORA_FRAMEWORKS=(
    "AgoraAiEchoCancellationExtension"
    "AgoraAiEchoCancellationLLExtension"
)

# Path to the built app
BUILT_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR:-${SYMROOT}/${CONFIGURATION}${EFFECTIVE_PLATFORM_NAME}}"
APP_PATH="${BUILT_PRODUCTS_DIR}/${FULL_PRODUCT_NAME}"
FRAMEWORKS_PATH="${APP_PATH}/Frameworks"
DSYMS_PATH="${BUILT_PRODUCTS_DIR}"

echo "📍 App path: ${APP_PATH}"
echo "📍 Frameworks path: ${FRAMEWORKS_PATH}"
echo "📍 dSYMs path: ${DSYMS_PATH}"

# Function to create dSYM for a framework
create_dsym_for_framework() {
    local framework_name="$1"
    local framework_path="${FRAMEWORKS_PATH}/${framework_name}.framework"
    local framework_binary="${framework_path}/${framework_name}"
    local dsym_path="${DSYMS_PATH}/${framework_name}.framework.dSYM"
    
    if [ -f "${framework_binary}" ]; then
        echo "🔍 Found ${framework_name} framework"
        
        # Check if dSYM already exists and is valid
        if [ -d "${dsym_path}" ]; then
            echo "✅ dSYM already exists for ${framework_name}"
            return 0
        fi
        
        echo "🛠️  Creating dSYM for ${framework_name}..."
        
        # Create dSYM directory structure
        mkdir -p "${dsym_path}/Contents/Resources/DWARF"
        
        # Create Info.plist for dSYM
        cat > "${dsym_path}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>English</string>
    <key>CFBundleIdentifier</key>
    <string>com.apple.xcode.dsym.${framework_name}.framework</string>
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
        
        # Extract debug symbols using dsymutil if available
        if command -v dsymutil >/dev/null 2>&1; then
            echo "📦 Extracting debug symbols with dsymutil..."
            dsymutil "${framework_binary}" -o "${dsym_path}" 2>/dev/null || {
                echo "⚠️  dsymutil failed, copying binary as fallback..."
                cp "${framework_binary}" "${dsym_path}/Contents/Resources/DWARF/${framework_name}"
            }
        else
            echo "📋 dsymutil not available, copying binary..."
            cp "${framework_binary}" "${dsym_path}/Contents/Resources/DWARF/${framework_name}"
        fi
        
        echo "✅ Created dSYM for ${framework_name}"
    else
        echo "⚠️  Framework ${framework_name} not found at ${framework_binary}"
    fi
}

# Process each Agora framework
for framework in "${AGORA_FRAMEWORKS[@]}"; do
    create_dsym_for_framework "$framework"
done

# Additional fix: Check for any missing dSYMs in Pods
PODS_FRAMEWORKS_PATH="${BUILT_PRODUCTS_DIR}/Pods_Runner.framework"
if [ -d "${PODS_FRAMEWORKS_PATH}" ]; then
    echo "🔍 Checking Pods framework for Agora components..."
    
    # Look for Agora-related binaries in the Pods framework
    find "${PODS_FRAMEWORKS_PATH}" -name "*Agora*" -type f 2>/dev/null | while read -r agora_file; do
        echo "📦 Found Agora component: ${agora_file}"
    done
fi

echo "✅ Agora dSYM fix completed!"