# Fix for "Multiple Commands Produce" Error

If you get a "Multiple commands produce" or "duplicate output file" error after pulling from GitHub, this is usually caused by stale build cache. Follow these steps:

## Quick Fix (Recommended)

1. **Close Xcode completely**

2. **Clean DerivedData:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/HelloGT-*
   ```

3. **Clean the build folder in Xcode:**
   - Open Xcode
   - Product → Clean Build Folder (Shift+Cmd+K)

4. **Resolve Swift Packages:**
   - File → Packages → Resolve Package Versions

5. **Build again**

## Alternative: Command Line Fix

```bash
# Navigate to project directory
cd /path/to/iosClubG1

# Clean DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/HelloGT-*

# Clean and resolve packages
xcodebuild clean -project HelloGT.xcodeproj -scheme HelloGT
xcodebuild -resolvePackageDependencies -project HelloGT.xcodeproj -scheme HelloGT
```

## Why This Happens

The project uses `PBXFileSystemSynchronizedRootGroup` which automatically includes files in the `HelloGT/` folder. Files in the root directory (like `AuthenticationManager.swift`) are explicitly referenced. This is correct, but Xcode's build cache can sometimes get confused and think files are being compiled twice.

Cleaning DerivedData forces Xcode to rebuild its cache from scratch.
