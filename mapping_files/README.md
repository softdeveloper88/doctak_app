# DocTak Mapping Files

This directory contains R8/ProGuard mapping files generated during release builds.

## What are mapping files?

When you build a release version of your app with obfuscation enabled (minifyEnabled true), R8 renames classes, methods, and fields to shorter names to reduce app size. The mapping file contains the original → obfuscated name mappings.

## Why are they important?

- **Crash Analysis**: Without mapping files, crash reports show obfuscated names that are hard to debug
- **Google Play Console**: Upload these files to make crash reports readable
- **Firebase Crashlytics**: Automatically uses these files for better crash reporting

## Files in this directory

Each mapping file is named with the format:
`doctak_mapping_{versionCode}_{timestamp}.txt`

Example: `doctak_mapping_101_20250110_143052.txt`

## How to use

### For Google Play Console:
1. Go to Play Console → Your App → App bundle explorer
2. Select the release version
3. Click "Upload deobfuscation file"
4. Upload the corresponding mapping file

### For Firebase Crashlytics:
- Automatic upload is configured when `mappingFileUploadEnabled true` is set
- No manual action needed for new releases

## Build Process

Mapping files are automatically generated and copied here when you run:
```bash
flutter build appbundle --release
# or
flutter build apk --release
```

## Important Notes

- Keep these files safe - you cannot regenerate them for old releases
- Each app version needs its specific mapping file
- Store mapping files for all published versions
- These files are needed to debug crashes from production users

## Troubleshooting

If mapping files are not generated:
1. Ensure `minifyEnabled true` in release build type
2. Check that obfuscation is not disabled in proguard-rules.pro
3. Verify the build completed successfully

For more help, run the upload helper script:
```bash
cd android
./upload_mapping.sh
```