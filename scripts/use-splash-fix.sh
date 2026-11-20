#!/bin/sh
# Copies one version of expo-splash-screen's SplashScreenManager.swift and SplashScreenModule.swift
# into node_modules.
#   58.0.14   the published files
#   proposed  the fix: remove the observer when the splash screen hides, not in OnDestroy
set -eu
cd "$(dirname "$0")/.."
cp "fix-variants-ios/$1/SplashScreenManager.swift" "fix-variants-ios/$1/SplashScreenModule.swift" node_modules/expo-splash-screen/ios/
echo "expo-splash-screen files: $1"
