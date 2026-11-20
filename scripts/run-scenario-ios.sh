#!/bin/sh
# The scenario of scripts/run-scenario.sh on an iOS simulator, without the "Reload" step.
# Needs scripts/serve-update.js running and updates/current published.
# Usage: SIMULATOR_UDID=<udid> scripts/run-scenario-ios.sh <app> <output dir>
set -eu
cd "$(dirname "$0")/.."
APP=$1
OUT=$2
SIM=$SIMULATOR_UDID
BUNDLE=com.example.errorrecoverysplash
mkdir -p "$OUT"
xcrun simctl bootstatus "$SIM" -b >/dev/null
xcrun simctl uninstall "$SIM" "$BUNDLE" 2>/dev/null || true
xcrun simctl install "$SIM" "$APP"
START=$(date -u +"%Y-%m-%d %H:%M:%S")
xcrun simctl io "$SIM" recordVideo --codec h264 --force "$OUT/scenario.mov" 2>/dev/null &
REC=$!
sleep 2
launch() {
  xcrun simctl terminate "$SIM" "$BUNDLE" 2>/dev/null || true
  sleep 1
  xcrun simctl launch "$SIM" "$BUNDLE" >/dev/null
  sleep "$2"
  xcrun simctl io "$SIM" screenshot "$OUT/$1.png" >/dev/null 2>&1
  echo "$1: $OUT/$1.png"
}
launch 1-first-launch 10
launch 2-second-launch 15
launch 3-third-launch 10
kill -INT $REC 2>/dev/null || true
wait $REC 2>/dev/null || true
xcrun simctl spawn "$SIM" log show --style compact --start "$START" \
  --predicate 'subsystem BEGINSWITH "dev.expo" OR process == "expoupdateserrorrecoverysplash"' > "$OUT/log.txt" 2>/dev/null || true
echo "log: $OUT/log.txt"
