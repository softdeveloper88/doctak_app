# Xcode Build Script Setup for dSYM Fix

## Step-by-Step Guide to Add Build Phase Script

### 1. Open Project in Xcode
```bash
open ios/Runner.xcworkspace
```

### 2. Add Build Phase Script

1. **Select Runner Target**:
   - In Xcode, click on "Runner" in the project navigator (blue icon)
   - Make sure "Runner" target is selected (not the project)

2. **Go to Build Phases**:
   - Click on the "Build Phases" tab at the top
   - You should see phases like "Dependencies", "Compile Sources", "Embed Pods Frameworks", etc.

3. **Add New Run Script Phase**:
   - Click the "+" button at the top left of the Build Phases section
   - Select "New Run Script Phase" from the dropdown

4. **Position the Script Correctly**:
   - **IMPORTANT**: Drag the new "Run Script" phase to be **AFTER** "Embed Pods Frameworks"
   - The order should be:
     ```
     [CP] Check Pods Manifest.lock
     Sources
     Frameworks
     Resources
     Embed Pods Frameworks
     Run Script  ← Your new script should be here
     [CP] Embed Pods Frameworks
     ```

5. **Configure the Script**:
   - Name the script: "Fix Agora dSYMs"
   - In the script box, paste this exact code:

   ```bash
   # Fix Agora dSYM files for App Store submission
   if [ "${CONFIGURATION}" = "Release" ]; then
       echo "🔧 Running Agora dSYM fix..."
       "${SRCROOT}/scripts/post_build_dsym_fix.sh"
   fi
   ```

6. **Add Input Files**:
   - Click the dropdown arrow next to "Input Files"
   - Click "+" and add: `$(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME).app`

7. **Add Output Files**:
   - Click the dropdown arrow next to "Output Files"  
   - Click "+" and add: `$(BUILT_PRODUCTS_DIR)/*.dSYM`

### 3. Verify Script Permissions

In Terminal, run:
```bash
chmod +x ios/scripts/post_build_dsym_fix.sh
chmod +x ios/fix_agora_dsyms.sh
```

### 4. Test the Setup

1. **Clean Build Folder**: 
   - In Xcode: Product → Clean Build Folder (Cmd+Shift+K)

2. **Build for Release**:
   - Select "Any iOS Device" as destination
   - Product → Archive

3. **Check Console Output**:
   - During build, you should see the dSYM fix messages in the console
   - Look for "🔧 Running Agora dSYM fix..." messages

### 5. Alternative Manual Method

If the automated script doesn't work, you can manually run:

```bash
# Navigate to project root
cd /Users/skapple/Documents/MyProjects/doctak_app

# Run the dSYM fix script manually
CONFIGURATION=Release FORCE_DSYM_FIX=YES ./ios/scripts/post_build_dsym_fix.sh
```

## Troubleshooting

### Script Not Running?
- Verify script permissions: `ls -la ios/scripts/`
- Check script location: `ls ios/scripts/post_build_dsym_fix.sh`
- Ensure Build Phase is positioned correctly (after Embed Pods Frameworks)

### Still Getting dSYM Errors?
- Try the manual dSYM creation method from APPSTORE_FIXES_README.md
- Contact Agora support for pre-built dSYM files
- Consider updating to newer Agora SDK version

### Build Errors?
- Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Clean project: Product → Clean Build Folder
- Rebuild pods: `cd ios && pod install --repo-update`

## Verification

After successful archive:
1. Check if dSYM files exist in build folder
2. Upload to App Store Connect should not show dSYM warnings
3. Look for "✅ dSYM fix completed successfully!" in build logs