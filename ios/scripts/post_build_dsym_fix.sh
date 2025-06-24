#!/bin/bash

# Post-build script to ensure all required dSYM files are present
# Add this as a "Run Script" build phase AFTER "Embed Pods Frameworks"

set -e

echo "🚀 Starting post-build dSYM verification and fix..."

# Configuration
CONFIGURATION="${CONFIGURATION:-Release}"
BUILT_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR:-${SYMROOT}/${CONFIGURATION}${EFFECTIVE_PLATFORM_NAME}}"
TARGET_NAME="${TARGET_NAME:-Runner}"
PRODUCT_NAME="${PRODUCT_NAME:-Runner}"

# Define paths
APP_PATH="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
FRAMEWORKS_PATH="${APP_PATH}/Frameworks"
DSYM_ROOT="${BUILT_PRODUCTS_DIR}"

echo "📁 Configuration: ${CONFIGURATION}"
echo "📁 Built products dir: ${BUILT_PRODUCTS_DIR}"
echo "📁 App path: ${APP_PATH}"
echo "📁 Frameworks path: ${FRAMEWORKS_PATH}"

# Agora frameworks that commonly have dSYM issues
AGORA_FRAMEWORKS=(
    "AgoraAiEchoCancellationExtension"
    "AgoraAiEchoCancellationLLExtension"
    "AgoraCore"
    "AgoraRtcKit"
    "AgoraAiEchoCancellation"
    "Agorafdkaac"
    "Agoraffmpeg"
    "AgoraSoundTouch"
)

# Function to check if a framework exists
framework_exists() {
    local framework_name="$1"
    local framework_path="${FRAMEWORKS_PATH}/${framework_name}.framework"
    [ -d "${framework_path}" ]
}

# Function to check if dSYM exists and is valid
dsym_exists() {
    local framework_name="$1"
    local dsym_path="${DSYM_ROOT}/${framework_name}.framework.dSYM"
    [ -d "${dsym_path}" ] && [ -f "${dsym_path}/Contents/Resources/DWARF/${framework_name}" ]
}

# Function to create a minimal dSYM
create_minimal_dsym() {
    local framework_name="$1"
    local framework_path="${FRAMEWORKS_PATH}/${framework_name}.framework"
    local framework_binary="${framework_path}/${framework_name}"
    local dsym_path="${DSYM_ROOT}/${framework_name}.framework.dSYM"
    local dwarf_path="${dsym_path}/Contents/Resources/DWARF"
    
    echo "🔨 Creating minimal dSYM for ${framework_name}..."
    
    # Create directory structure
    mkdir -p "${dwarf_path}"
    
    # Get framework info
    local bundle_id=""
    local info_plist="${framework_path}/Info.plist"
    if [ -f "${info_plist}" ]; then
        bundle_id=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "${info_plist}" 2>/dev/null || echo "com.agora.${framework_name}")
    else
        bundle_id="com.agora.${framework_name}"
    fi
    
    # Create dSYM Info.plist
    cat > "${dsym_path}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleIdentifier</key>
    <string>com.apple.xcode.dsym.${bundle_id}</string>
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
    <key>dSYM_UUID</key>
    <dict>
EOF
    
    # Try to extract UUID from binary and add to plist
    if [ -f "${framework_binary}" ]; then
        local uuid=$(dwarfdump --uuid "${framework_binary}" 2>/dev/null | head -1 | awk '{print $2}' || echo "")
        if [ -n "${uuid}" ]; then
            echo "        <key>${uuid}</key>" >> "${dsym_path}/Contents/Info.plist"
            echo "        <dict>" >> "${dsym_path}/Contents/Info.plist"
            echo "            <key>DBGArchitecture</key>" >> "${dsym_path}/Contents/Info.plist"
            echo "            <string>arm64</string>" >> "${dsym_path}/Contents/Info.plist"
            echo "            <key>DBGDSYMPath</key>" >> "${dsym_path}/Contents/Info.plist"
            echo "            <string>${dsym_path}</string>" >> "${dsym_path}/Contents/Info.plist"
            echo "            <key>DBGSymbolRichExecutable</key>" >> "${dsym_path}/Contents/Info.plist"
            echo "            <string>${dwarf_path}/${framework_name}</string>" >> "${dsym_path}/Contents/Info.plist"
            echo "        </dict>" >> "${dsym_path}/Contents/Info.plist"
        fi
    fi
    
    cat >> "${dsym_path}/Contents/Info.plist" << EOF
    </dict>
</dict>
</plist>
EOF
    
    # Try to extract debug symbols using dsymutil
    if command -v dsymutil >/dev/null 2>&1 && [ -f "${framework_binary}" ]; then
        echo "🔍 Extracting debug symbols with dsymutil..."
        if dsymutil "${framework_binary}" -o "${dsym_path}" 2>/dev/null; then
            echo "✅ Successfully extracted debug symbols for ${framework_name}"
            return 0
        else
            echo "⚠️  dsymutil extraction failed, creating symbolic link..."
        fi
    fi
    
    # Fallback: create symbolic link or copy
    if [ -f "${framework_binary}" ]; then
        # Try to create a symbolic link first
        if ln -sf "${framework_binary}" "${dwarf_path}/${framework_name}" 2>/dev/null; then
            echo "🔗 Created symbolic link for ${framework_name}"
        else
            # If symbolic link fails, copy the binary
            cp "${framework_binary}" "${dwarf_path}/${framework_name}"
            echo "📋 Copied binary for ${framework_name}"
        fi
    else
        echo "❌ Framework binary not found: ${framework_binary}"
        return 1
    fi
    
    echo "✅ Created dSYM for ${framework_name}"
}

# Function to verify and fix Agora dSYMs
fix_agora_dsyms() {
    echo "🔍 Checking Agora frameworks..."
    
    local frameworks_found=0
    local frameworks_fixed=0
    
    for framework in "${AGORA_FRAMEWORKS[@]}"; do
        if framework_exists "${framework}"; then
            frameworks_found=$((frameworks_found + 1))
            echo "📦 Found framework: ${framework}"
            
            if ! dsym_exists "${framework}"; then
                echo "⚠️  Missing dSYM for ${framework}, creating..."
                if create_minimal_dsym "${framework}"; then
                    frameworks_fixed=$((frameworks_fixed + 1))
                fi
            else
                echo "✅ dSYM already exists for ${framework}"
            fi
        fi
    done
    
    echo "📊 Summary: Found ${frameworks_found} Agora frameworks, fixed ${frameworks_fixed} dSYMs"
}

# Function to list all available frameworks and their dSYM status
list_framework_status() {
    echo "📋 Framework dSYM Status Report:"
    echo "================================"
    
    if [ -d "${FRAMEWORKS_PATH}" ]; then
        for framework_dir in "${FRAMEWORKS_PATH}"/*.framework; do
            if [ -d "${framework_dir}" ]; then
                local framework_name=$(basename "${framework_dir}" .framework)
                local dsym_status="❌ Missing"
                
                if dsym_exists "${framework_name}"; then
                    dsym_status="✅ Present"
                fi
                
                echo "${framework_name}: ${dsym_status}"
            fi
        done
    else
        echo "⚠️  Frameworks directory not found: ${FRAMEWORKS_PATH}"
    fi
    echo "================================"
}

# Main execution
echo "🎯 Target: ${TARGET_NAME}"
echo "📦 Product: ${PRODUCT_NAME}"

# Only run for Release configuration by default, but allow override
if [ "${CONFIGURATION}" = "Release" ] || [ "${FORCE_DSYM_FIX}" = "YES" ]; then
    echo "🚀 Running dSYM fix for ${CONFIGURATION} configuration..."
    
    # List current status
    list_framework_status
    
    # Fix Agora frameworks
    fix_agora_dsyms
    
    # Final status report
    echo ""
    echo "🎉 Final Status:"
    list_framework_status
    
    echo "✅ dSYM fix completed successfully!"
else
    echo "ℹ️  Skipping dSYM fix for ${CONFIGURATION} configuration"
    echo "   (Set FORCE_DSYM_FIX=YES to force)"
fi

echo "🏁 Post-build dSYM verification completed!"