#!/bin/sh
# Installs an APK on a device or emulator and runs the scenario:
#   1. first launch: the embedded update renders, and the broken update downloads in the background;
#   2. second launch: the broken update throws, and error recovery falls back to the embedded update;
#   3. third launch;
#   4. a tap on "Reload" (Updates.reloadAsync), which must still reload the JS as before.
# Needs scripts/serve-update.js running and updates/current published.
# Usage: scripts/run-scenario.sh <apk> <output dir>   (ANDROID_SERIAL selects the device)
set -eu
cd "$(dirname "$0")/.."
APK=$1
OUT=$2
PKG=com.example.errorrecoverysplash
mkdir -p "$OUT"
adb install -r "$APK" >/dev/null
adb shell pm clear "$PKG" >/dev/null
adb reverse tcp:3000 tcp:3000 >/dev/null
adb logcat -c
adb shell screenrecord --time-limit 90 /sdcard/scenario.mp4 &
REC=$!
sleep 1
launch() {
  adb shell am force-stop "$PKG"
  sleep 1
  adb shell am start -W -n "$PKG/.MainActivity" >/dev/null
  sleep "$2"
  adb exec-out screencap -p > "$OUT/$1.png"
  echo "$1: $OUT/$1.png"
}
launch 1-first-launch 10
launch 2-second-launch 15
launch 3-third-launch 10
# 4. Tap "Reload".
adb shell uiautomator dump /sdcard/ui.xml >/dev/null
BOUNDS=$(adb shell cat /sdcard/ui.xml | grep -o -i 'text="reload"[^>]*bounds="[^"]*"' | grep -o 'bounds="[^"]*"' | head -1)
X=$(echo "$BOUNDS" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\1 \3/' | awk '{print int(($1+$2)/2)}')
Y=$(echo "$BOUNDS" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\2 \4/' | awk '{print int(($1+$2)/2)}')
adb shell input tap "$X" "$Y"
sleep 6
adb exec-out screencap -p > "$OUT/4-after-reload.png"
echo "4-after-reload: $OUT/4-after-reload.png (tap at $X,$Y)"
# Stop the recording on the device and wait until screenrecord closes the file.
adb shell pkill -INT screenrecord || true
wait $REC 2>/dev/null || true
while adb shell pidof screenrecord >/dev/null; do sleep 1; done
adb pull /sdcard/scenario.mp4 "$OUT/scenario.mp4" >/dev/null
adb shell rm /sdcard/scenario.mp4
adb logcat -d > "$OUT/logcat.txt"
grep -E "ReactNativeJS|dev.expo.updates|ExpoModulesCore|ReactHost|AndroidRuntime" "$OUT/logcat.txt" > "$OUT/logcat-filtered.txt" || true
echo "logs: $OUT/logcat-filtered.txt"
