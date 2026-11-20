#!/bin/sh
# Exports the broken update (EXPO_PUBLIC_CRASH_ON_LAUNCH=1) to updates/broken and makes it the
# update that scripts/serve-update.js serves.
set -eu
cd "$(dirname "$0")/.."
rm -rf updates/broken
EXPO_PUBLIC_CRASH_ON_LAUNCH=1 npx expo export --platform android --platform ios --output-dir updates/broken
npx expo config --json --type public > updates/broken/expoConfig.json
ln -sfn broken updates/current
echo "updates/current -> updates/broken"
