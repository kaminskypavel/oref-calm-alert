#!/usr/bin/env bash
set -euo pipefail

# Replace alert sounds in the Home Front Command (Pikud HaOref) app
# Usage: ./replace-sounds.sh <siren.mp3> <tzeva_adom.mp3>

PACKAGE="com.alert.meserhadash"
WORK_DIR="$(mktemp -d)"
BUILD_TOOLS_DIR="${ANDROID_HOME:-$HOME/Library/Android/sdk}/build-tools"
LATEST_BUILD_TOOLS="$(ls "$BUILD_TOOLS_DIR" 2>/dev/null | sort -V | tail -1)"
ZIPALIGN="$BUILD_TOOLS_DIR/$LATEST_BUILD_TOOLS/zipalign"
APKSIGNER="$BUILD_TOOLS_DIR/$LATEST_BUILD_TOOLS/apksigner"
KEYSTORE="$WORK_DIR/debug.keystore"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# --- Validate inputs ---
if [ $# -lt 2 ]; then
    echo "Usage: $0 <siren_replacement.mp3> <tzeva_adom_replacement.mp3>"
    echo ""
    echo "  Arg 1 = replaces Siren (default alert, assets/Sound1.mp3)"
    echo "  Arg 2 = replaces Tzeva Adom (assets/Sound2.mp3)"
    echo ""
    echo "Requirements: adb, ffmpeg, Android SDK build-tools (zipalign, apksigner)"
    exit 1
fi

SOUND1="$1"
SOUND2="$2"

for f in "$SOUND1" "$SOUND2"; do
    if [ ! -f "$f" ]; then
        echo "Error: File not found: $f"
        exit 1
    fi
done

# --- Check tools ---
for tool in adb ffmpeg; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: $tool not found in PATH"
        exit 1
    fi
done

for tool in "$ZIPALIGN" "$APKSIGNER"; do
    if [ ! -x "$tool" ]; then
        echo "Error: $tool not found."
        echo "Install Android SDK build-tools: sdkmanager --install 'build-tools;35.0.0'"
        exit 1
    fi
done

# --- Check device ---
echo "==> Checking for connected device..."
DEVICE_COUNT=$(adb devices | grep -c 'device$' || true)
if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo "Error: No Android device connected. Connect via USB and enable USB debugging."
    exit 1
fi
echo "    Device found."

# --- Pull APK ---
echo "==> Pulling APK from device..."
APK_PATH=$(adb shell pm path "$PACKAGE" | sed 's/package://' | tr -d '\r')
if [ -z "$APK_PATH" ]; then
    echo "Error: $PACKAGE not installed on device."
    echo "Install it from: https://play.google.com/store/apps/details?id=com.alert.meserhadash"
    exit 1
fi
adb pull "$APK_PATH" "$WORK_DIR/original.apk" > /dev/null
echo "    APK pulled."

# --- Re-encode sounds to match original format ---
echo "==> Re-encoding sound files..."
mkdir -p "$WORK_DIR/assets"
# Sound1 (Siren): 192kbps, 48kHz, stereo — matches original encoding
ffmpeg -y -i "$SOUND1" -ar 48000 -ab 192k -ac 2 "$WORK_DIR/assets/Sound1.mp3" 2>/dev/null
# Sound2 (Tzeva Adom): 128kbps, 44.1kHz, mono — matches original encoding
ffmpeg -y -i "$SOUND2" -ar 44100 -ab 128k -ac 1 "$WORK_DIR/assets/Sound2.mp3" 2>/dev/null
echo "    Re-encoded."

# --- Replace sounds in APK ---
echo "==> Patching APK..."
cp "$WORK_DIR/original.apk" "$WORK_DIR/modified.apk"
cd "$WORK_DIR"
# Remove old sounds and signature
zip -d modified.apk assets/Sound1.mp3 assets/Sound2.mp3 > /dev/null 2>&1 || true
zip -d modified.apk "META-INF/*" > /dev/null 2>&1 || true
# Add new sounds with STORED method (no compression) — critical for Android asset playback
zip -0 -r modified.apk assets/Sound1.mp3 assets/Sound2.mp3 > /dev/null
echo "    Patched."

# --- Align ---
echo "==> Aligning APK..."
"$ZIPALIGN" -f 4 modified.apk aligned.apk
echo "    Aligned."

# --- Sign ---
echo "==> Signing APK..."
keytool -genkeypair -v \
    -keystore "$KEYSTORE" \
    -alias oref-calm \
    -keyalg RSA -keysize 2048 \
    -validity 10000 \
    -storepass orefcalm \
    -keypass orefcalm \
    -dname "CN=OrefCalmAlerts" \
    > /dev/null 2>&1

"$APKSIGNER" sign \
    --ks "$KEYSTORE" \
    --ks-key-alias oref-calm \
    --ks-pass pass:orefcalm \
    --key-pass pass:orefcalm \
    aligned.apk
echo "    Signed."

# --- Install ---
echo ""
echo "==> Ready to install."
echo "    WARNING: This will uninstall the original app first."
echo "    You will lose app settings (location, notification preferences)."
echo "    You will need to reconfigure the app after installation."
echo ""
read -p "    Proceed? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "==> Uninstalling original..."
    adb uninstall "$PACKAGE" || true
    echo "==> Installing modified APK..."
    adb install aligned.apk
    echo ""
    echo "==> Done! Open the app and reconfigure your location settings."
    echo "    The alert sounds have been replaced with your custom sounds."
else
    OUTPATH="${OLDPWD:-$(pwd)}/modified-oref.apk"
    cp aligned.apk "$OUTPATH"
    echo "    Modified APK saved to: $OUTPATH"
    echo "    Install manually with:"
    echo "      adb uninstall $PACKAGE && adb install \"$OUTPATH\""
fi
