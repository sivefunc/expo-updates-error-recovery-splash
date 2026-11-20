#!/bin/sh
# Builds a release APK (signed with the debug key) with one variant of the expo-updates relaunch files (scripts/use-fix.sh).
# Output: build-logs/app-<variant>.apk
set -eu
cd "$(dirname "$0")/.."
sh scripts/use-fix.sh "$1"
[ -d android ] || npx expo prebuild --platform android --no-install
(cd android && ./gradlew assembleRelease)
mkdir -p build-logs
cp android/app/build/outputs/apk/release/app-release.apk "build-logs/app-$1.apk"
echo "build-logs/app-$1.apk"
