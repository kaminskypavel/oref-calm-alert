# Oref Calm Alerts

Replace the scary siren sounds in Israel's Home Front Command app (פיקוד העורף) with calmer alternatives.

The official app only offers two hardcoded alert sounds — Siren and Tzeva Adom — both designed to be as alarming as possible. This tool swaps them with gentler tones while keeping the app fully functional.

## Demo

[![Demo](assets/cover.png)](https://github.com/kaminskypavel/oref-calm-alert/blob/main/assets/demo.mp4)

## Supported platforms

- **[Android](android/)** — working, uses APK sound replacement via ADB

## Quick start

1. Connect your Android phone via USB with USB debugging enabled
2. Place your custom MP3 files in `sounds/` or use the included ones
3. Run:

```sh
cd android
./replace-sounds.sh ../sounds/Sound1_calm.mp3 ../sounds/Sound2_calm.mp3
```

4. Reconfigure the app (location, notification preferences)

## Requirements

- `adb` — Android Debug Bridge
- `ffmpeg` — for re-encoding audio
- Android SDK build-tools (`zipalign`, `apksigner`)

### macOS

```sh
brew install android-platform-tools ffmpeg
```

## How it works

The script pulls the APK from your device, swaps the bundled siren MP3s with your custom sounds, re-signs the APK, and installs it back. No root required.

See [android/README.md](android/README.md) for full technical details on the app internals.

## Important

- This is a **safety-critical app**. After modification, always test that alerts are received and audible.
- The modified app won't auto-update from Play Store. Re-run the script after updates.
- Cell Broadcast (system-level extreme threat alerts) are not affected by this tool.
