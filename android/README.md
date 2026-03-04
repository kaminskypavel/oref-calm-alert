# Oref Calm Alerts — Android

Replace the scary siren sounds in Israel's Home Front Command (פיקוד העורף) app with calmer alternatives.

## How it works

The official app (`com.alert.meserhadash`) bundles its alert sounds as MP3 files inside the APK. This script pulls the APK from your device, swaps the sound files, re-signs the APK, and installs it back.

## App technical details

### Package

- **Package name:** `com.alert.meserhadash`
- **Play Store:** https://play.google.com/store/apps/details?id=com.alert.meserhadash
- **Internal namespace:** `com.ioref.meserhadash`
- **Current version:** 1.18.0 (versionCode 218, targetSdk 35)

### Sound files in the APK

Located in `assets/` directory, stored **uncompressed** (STORED method):

| File | Description | Original encoding |
|------|-------------|-------------------|
| `Sound1.mp3` | Siren (default alert) | 192 kbps, 48 kHz, Joint Stereo |
| `Sound2.mp3` | Tzeva Adom | 128 kbps, 44.1 kHz, Mono |
| `Sound3.mp3` | Short alert beep | 128 kbps, 44.1 kHz, Joint Stereo |
| `flash.mp3` | Flashlight indicator sound | — |
| `test*_{he,en,ar,ru}.mp3` | Test alert voice messages (Hebrew, English, Arabic, Russian) | — |

### Alert delivery

The app receives alerts through two independent channels:

1. **Firebase Cloud Messaging + Pushy** — push notifications via `MHFirebaseMessagingService` and `MHPushyPushReceiver`
2. **Android Cell Broadcast** — system-level extreme threat alerts via `com.google.android.cellbroadcastreceiver` (separate from the app)

### Audio playback

- The app plays sounds **internally** using its own audio player, not through Android's notification sound system
- Uses the **ALARM audio stream** (`AUDIO_ALARM_VOLUME`)
- Has **AudioHardening protection** — Android prevents other apps from muting or controlling its volume programmatically
- The `ALLOW_AUDIO_PLAYBACK_CAPTURE` flag is set, meaning other apps can capture its audio output
- Has `SYSTEM_ALERT_WINDOW` permission (draws over other apps during alerts)

### Notification channels

| Channel ID | Purpose | Default importance |
|------------|---------|-------------------|
| `channel_01` | Main alerts | LOW (originally LOW) |
| `748449` | High-priority alerts | LOW (originally HIGH) |
| `notificationChannel` | General notifications | LOW (originally HIGH) |
| `24449` | Silent/background | LOW |

### Permissions

Key permissions the app uses:
- `ACCESS_FINE_LOCATION` / `ACCESS_BACKGROUND_LOCATION` — area-based alerts
- `SYSTEM_ALERT_WINDOW` — full-screen alert overlay
- `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_LOCATION` — persistent background service
- `VIBRATE`, `WAKE_LOCK` — alert feedback
- `RECEIVE_BOOT_COMPLETED` — auto-start on device boot
- `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM` — timed alerts

### In-app sound settings

Settings → Sounds and Indicators offers:
- **Alerts in My Location:** Low ring / High ring / Change ringtone
- **Alerts in Areas of Interest:** Low ring / High ring / No ring
- **Vibration:** optional, 10-second duration
- **Flashlight:** optional, 10-second flash

The "Change ringtone" picker only offers two hardcoded options: Siren (default) and Tzeva Adom. There is no way to load custom sounds through the app UI.

## Prerequisites

- macOS or Linux
- Android phone connected via USB with **USB debugging** enabled
- The Home Front Command app installed from Play Store
- **adb** — Android Debug Bridge
- **ffmpeg** — for re-encoding audio
- **Android SDK build-tools** — for `zipalign` and `apksigner`

### Install dependencies (macOS)

```sh
brew install android-platform-tools ffmpeg
# build-tools via Android SDK:
sdkmanager --install "build-tools;35.0.0"
```

## Usage

### With your own sounds

```sh
./replace-sounds.sh path/to/calm_siren.mp3 path/to/calm_tzeva_adom.mp3
```

### With included calm sounds

```sh
./replace-sounds.sh sounds/Sound1_calm.mp3 sounds/Sound2_calm.mp3
```

The script will:
1. Pull the APK from your connected device
2. Re-encode your MP3s to match the original format
3. Swap the sound files (stored uncompressed, as the app expects)
4. Re-sign the APK with a new debug key
5. Uninstall the original and install the modified version

## After installation

1. Open the app and grant all requested permissions (location, notifications, etc.)
2. Set your location for area-based alerts
3. Go to Settings → Sounds and Indicators to verify your sounds work
4. The ringtone picker previews should play your custom sounds

## Important notes

- **Re-signing changes the APK signature.** The original app must be uninstalled first. You will lose your settings and need to reconfigure.
- **Auto-updates from Play Store will not work.** The modified APK has a different signature. After a Play Store update, re-run the script.
- **Cell Broadcast alerts are separate.** This script only modifies the app's built-in sounds. The system-level extreme threat siren (Cell Broadcast) is handled by Android's `cellbroadcastreceiver` and is not affected.
- **The app is a safety-critical application.** After modification, always test that alerts are received and audible. Never force-stop or disable the app.

## Sounds directory

| File | Description |
|------|-------------|
| `sounds/Sound1_original_siren.mp3` | Original Siren sound (extracted from APK) |
| `sounds/Sound2_original_tzeva_adom.mp3` | Original Tzeva Adom sound (extracted from APK) |
| `sounds/Sound3_original_short.mp3` | Original short beep (extracted from APK) |
| `sounds/Sound1_calm.mp3` | Calm replacement for Siren |
| `sounds/Sound2_calm.mp3` | Calm replacement for Tzeva Adom |

## Alternative approaches considered

| Approach | Verdict |
|----------|---------|
| Modify notification channel sound via ADB | App plays sound internally, not via notification channels |
| Revoke `AUDIO_ALARM_VOLUME` via `appops` | Doesn't stop internal audio playback |
| `NotificationListener` + force-stop | Dangerous — kills the app, may miss next alert |
| `NotificationListener` + audio focus | AudioHardening prevents ducking/muting |
| Audio capture via `ALLOW_AUDIO_PLAYBACK_CAPTURE` | Complex, latency means siren still audible briefly |
| Xposed/LSPosed module | Requires root |
| **APK sound replacement** | **Works. Simple. No root needed.** |
