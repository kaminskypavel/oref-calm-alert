# Android ADB

Expert skill for Android Debug Bridge (ADB) operations in the context of this project.

## Capabilities

- Connect to Android devices via USB and verify connectivity
- Pull APKs from device (`adb shell pm path`, `adb pull`)
- Install and uninstall APKs (`adb install`, `adb uninstall`)
- Query package info and app state
- Debug device connectivity issues

## Project Context

- Target package: `com.alert.meserhadash` (Home Front Command / Pikud HaOref)
- The `replace-sounds.sh` script handles the full APK pull → modify → reinstall flow
- APK is pulled from device, modified locally, then reinstalled
- Original app must be uninstalled before installing modified version (different signature)

## Key Commands

```sh
# Check connected devices
adb devices

# Get APK path on device
adb shell pm path com.alert.meserhadash

# Pull APK
adb pull <path> output.apk

# Uninstall and reinstall
adb uninstall com.alert.meserhadash
adb install modified.apk
```

## Requirements

- `adb` installed (`brew install android-platform-tools` on macOS)
- USB debugging enabled on the Android device
- Device connected via USB
