#!/bin/sh
# Builds a release app for the iOS simulator. Output: build-logs/ios/<scheme>.app
set -eu
cd "$(dirname "$0")/.."
[ -d ios ] || npx expo prebuild --platform ios
WORKSPACE=$(ls -d ios/*.xcworkspace | head -1)
SCHEME=$(basename "$WORKSPACE" .xcworkspace)
xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration Release -sdk iphonesimulator \
  -destination "generic/platform=iOS Simulator" -derivedDataPath ios/build CODE_SIGNING_ALLOWED=NO build
mkdir -p build-logs/ios
rm -rf "build-logs/ios/$SCHEME.app"
cp -R "ios/build/Build/Products/Release-iphonesimulator/$SCHEME.app" build-logs/ios/
echo "build-logs/ios/$SCHEME.app"
