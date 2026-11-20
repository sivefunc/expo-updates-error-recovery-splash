#!/bin/sh
# Copies one version of three expo-updates files into node_modules:
# EnabledUpdatesController.kt, procedures/RelaunchProcedure.kt, procedures/RestartReactAppExtensions.kt.
#   58.0.22   the published files
#   proposed  the fix: after error recovery relaunches the app, recreate the activity
set -eu
cd "$(dirname "$0")/.."
DEST=node_modules/expo-updates/android/src/main/java/expo/modules/updates
for f in EnabledUpdatesController.kt procedures/RelaunchProcedure.kt procedures/RestartReactAppExtensions.kt; do
  cp "fix-variants/$1/$f" "$DEST/$f"
done
echo "expo-updates relaunch files: $1"
