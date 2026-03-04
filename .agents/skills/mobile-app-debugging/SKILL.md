# Mobile App Debugging

Expert skill for debugging the modified Home Front Command app.

## Common Issues

### App not receiving alerts
- Verify all permissions are granted (location, notifications, overlay)
- Check that background service is running (app auto-starts on boot)
- Ensure location is configured in app settings
- Cell Broadcast alerts are separate from the app — not affected by this mod

### Sound not playing
- Sounds must be stored uncompressed (STORED method) in the APK
- Encoding must match original format exactly:
  - Sound1: 192 kbps, 48 kHz, stereo
  - Sound2: 128 kbps, 44.1 kHz, mono
- Test via Settings → Sounds and Indicators → ringtone picker preview

### Installation failures
- Must uninstall original app first (signature mismatch)
- Check `adb devices` shows connected device
- Verify USB debugging is enabled
- Check `zipalign` and `apksigner` are available in Android SDK build-tools

### After Play Store update
- Play Store may reinstall original app (different signature)
- Re-run `replace-sounds.sh` to re-apply modifications
- App settings will be lost — reconfigure location and notification preferences

## Debugging Commands

```sh
# Check if app is installed
adb shell pm list packages | grep meserhadash

# Check app permissions
adb shell dumpsys package com.alert.meserhadash | grep permission

# View app logs
adb logcat -s com.alert.meserhadash

# Force stop app
adb shell am force-stop com.alert.meserhadash  # CAUTION: safety-critical app

# Verify APK contents
unzip -l modified.apk | grep Sound
```

## Safety Warning

This is a safety-critical app. After any modification, always verify:
1. App launches and runs correctly
2. Location is set properly
3. Test alert sounds play from Settings
4. Background service is active
