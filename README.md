# expo-updates: the app stays on the splash screen after error recovery (Android)

An update throws a fatal JS error during launch. expo-updates error recovery falls back to the
embedded update and relaunches the app. On Android, the relaunched app loads the bundle, but nothing
renders: the native splash screen (orange here) stays until the app is closed.

- Blank `create-expo-app` project (SDK 58): `expo` 58.0.26, `expo-updates` 58.0.22, React Native
  0.88.1, New Architecture.
- No EAS Update. `scripts/serve-update.js` is a minimal update server (protocol 1) on port 3000.
  The app reaches it through `adb reverse`, at `http://127.0.0.1:3000/api/manifest`
  (`expo-build-properties` allows cleartext traffic for that).
- `App.js` throws at module scope when `EXPO_PUBLIC_CRASH_ON_LAUNCH=1`. The embedded update does not
  throw. `scripts/publish-update.sh` exports the update that throws.

## Steps

Needs Node, the Android SDK, and a running Android emulator or device.

```sh
npm install
sh scripts/build-release.sh 58.0.22      # expo prebuild + gradlew assembleRelease (debug key)
node scripts/serve-update.js             # in another terminal
sh scripts/publish-update.sh             # after the build: an update older than the embedded one is not used
sh scripts/run-scenario.sh build-logs/app-58.0.22.apk out
```

`scripts/run-scenario.sh` installs the APK, clears its data, and launches the app 3 times, with
`am force-stop` before each launch. Then it taps "Reload" (`Updates.reloadAsync()`). It saves a
screenshot after each step, a video, and the logcat in `out/`.

1. First launch: the embedded update renders. The update that throws downloads in the background.
2. Second launch: the update that throws runs, and error recovery falls back to the embedded update.
3. Third launch.

**Expected:** the second launch renders the embedded update.

**Actual:** the second launch stays on the splash screen. The third launch renders the embedded
update, and "Reload" works.

### iOS

```sh
sh scripts/build-release-ios.sh          # expo prebuild + xcodebuild Release for the simulator
node scripts/serve-update.js             # in another terminal
sh scripts/publish-update.sh
SIMULATOR_UDID=<udid> sh scripts/run-scenario-ios.sh build-logs/ios/expoupdateserrorrecoverysplash.app out
```

The same 3 launches, without the "Reload" step. The second launch also stays on the splash screen,
through other code than on Android: the app renders, but `expo-splash-screen` no longer has the
observer that hides the splash screen. `scripts/use-splash-fix.sh <58.0.14|proposed>` copies the
published files or the proposed fix of `expo-splash-screen` into `node_modules` (run it before
`scripts/build-release-ios.sh`).

## Variants

`scripts/use-fix.sh <variant>` copies three files of `expo-updates` from `fix-variants/` into
`node_modules` (`scripts/build-release.sh` calls it):

- `58.0.22`: the published files.
- `proposed`: the proposed fix. After error recovery relaunches the app, it waits for the reload,
  then recreates the activity, so the activity creates and starts its surface again.

## Results (2026-11-20, Android 16 emulator, API 36, macOS 26.7.3)

| Variant | Second launch | Runs |
|---|---|---|
| `58.0.22` | splash screen | 4 of 4 |
| `58.0.22` with expo/expo#53498, #53499, and #53500 | splash screen | 3 of 3 |
| A check of `lifecycleState == BEFORE_CREATE` in `ReactHost.restart` | splash screen | 3 of 10 |
| `proposed` | the embedded update renders | 10 of 10 |

In every run, the third launch rendered the embedded update and "Reload" reloaded the JS.

iOS (iPhone 18 Pro simulator, iOS 27.2, `58.0.22`): the second launch stayed on the splash screen
3 of 3 times, and still after 60 seconds in a fourth run. With the proposed `expo-splash-screen`
fix, it rendered the embedded update 10 of 10 times, and "Reload" still worked.
