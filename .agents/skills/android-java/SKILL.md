# Android Java

Expert skill for understanding the Android app internals relevant to this project.

## App Details

- **Package:** `com.alert.meserhadash`
- **Internal namespace:** `com.ioref.meserhadash`
- **Version:** 1.18.0 (versionCode 218, targetSdk 35)

## Sound System

- App plays sounds **internally** using its own audio player, not Android notification sounds
- Uses **ALARM audio stream** (`AUDIO_ALARM_VOLUME`)
- Has **AudioHardening** — prevents other apps from muting/controlling volume
- Sound files are in `assets/` directory, stored uncompressed (STORED method)

### Sound Files

| File | Encoding |
|------|----------|
| `Sound1.mp3` (Siren) | 192 kbps, 48 kHz, Joint Stereo |
| `Sound2.mp3` (Tzeva Adom) | 128 kbps, 44.1 kHz, Mono |
| `Sound3.mp3` (Short beep) | 128 kbps, 44.1 kHz, Joint Stereo |

## Alert Delivery

1. **Firebase Cloud Messaging + Pushy** — via `MHFirebaseMessagingService` and `MHPushyPushReceiver`
2. **Android Cell Broadcast** — system-level, separate from app

## Key Permissions

- `ACCESS_FINE_LOCATION` / `ACCESS_BACKGROUND_LOCATION`
- `SYSTEM_ALERT_WINDOW` (full-screen overlay)
- `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_LOCATION`
- `RECEIVE_BOOT_COMPLETED` (auto-start)
- `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM`

## APK Modification

- Sound replacement requires: unzip → swap MP3s → re-sign → reinstall
- Assets must be stored with STORED method (no compression) for Android playback
- Re-signing invalidates Play Store updates
- Build tools needed: `zipalign`, `apksigner`
