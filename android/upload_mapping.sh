#!/bin/bash

# Script to help upload mapping files to Google Play Console
# Run this after building a release APK/AAB

echo "🔍 DocTak Mapping File Upload Helper"
echo "======================================"

# Check if mapping file exists
MAPPING_FILE="app/build/outputs/mapping/release/mapping.txt"

if [ -f "$MAPPING_FILE" ]; then
    echo "✅ Mapping file found: $MAPPING_FILE"
    echo "📊 File size: $(du -h $MAPPING_FILE | cut -f1)"
    echo "📅 Last modified: $(stat -f '%Sm' $MAPPING_FILE)"
    echo ""
    echo "📋 To upload this mapping file to Google Play Console:"
    echo "1. Go to Google Play Console → Your App → App bundle explorer"
    echo "2. Select the release/version you want to upload mapping for"
    echo "3. Click 'Upload deobfuscation file'"
    echo "4. Upload the file: $(pwd)/$MAPPING_FILE"
    echo ""
    echo "🔗 Direct link to mapping file:"
    echo "   $(pwd)/$MAPPING_FILE"
    echo ""
    echo "📝 You can also copy the mapping file to your desktop:"
    echo "   cp $MAPPING_FILE ~/Desktop/doctak_mapping_$(date +%Y%m%d_%H%M%S).txt"
else
    echo "❌ Mapping file not found!"
    echo "💡 Make sure you've built a release version with obfuscation enabled:"
    echo "   flutter build appbundle --release"
    echo "   or"
    echo "   flutter build apk --release"
    echo ""
    echo "🔍 Looking for mapping files in build outputs..."
    find app/build/outputs -name "mapping.txt" -o -name "*.txt" | grep -i mapping || echo "   No mapping files found"
fi

echo ""
echo "🔧 Build configuration check:"
if grep -q "minifyEnabled true" app/build.gradle; then
    echo "✅ Obfuscation is enabled in release build"
else
    echo "❌ Obfuscation is not enabled - mapping files won't be generated"
    echo "💡 Enable obfuscation by setting 'minifyEnabled true' in release build type"
fi

if grep -q "mappingFileUploadEnabled true" app/build.gradle; then
    echo "✅ Firebase Crashlytics mapping upload is enabled"
else
    echo "⚠️  Firebase Crashlytics mapping upload not configured"
fi

echo ""
echo "🚀 For future releases, Firebase Crashlytics will automatically upload mapping files."