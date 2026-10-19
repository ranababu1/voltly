# Changelog

Newest-first record of meaningful implementation changes.

## 2026-10-19 — Phase 0: Foundation

**Milestone:** Phase 0 — Foundation

**Summary**

- Created the Android-only Flutter application (`voltly`, application ID
  `com.voltly`) with `minSdk` pinned to 26 and the launcher label `Voltly`.
- Added the AMOLED-first design-token system: true-black backgrounds, dark
  green-black surfaces, mint accent, status colors, spacing/radius scales and
  a Material 3 dark type scale.
- Added a launchable foundation app shell that presents Voltly branding and an
  explicit "No readings yet" state. No battery value, percentage or demo
  reading is rendered; native telemetry starts in Phase 1.
- Made the Android launch window black in both system light and dark modes to
  avoid a white flash before the first Flutter frame.
- Removed the unused `cupertino_icons` dependency and set the development
  version to `0.1.0+1`.
- Added widget tests for branding/no-fabricated-telemetry, the AMOLED/mint
  theme, and overflow-free rendering at 320×640 with 2× system text scaling.
- Added `README.md`, this changelog and `currentstate.md`; extended `.gitignore`
  for environment files, signing material, local databases, telemetry exports,
  crash dumps and local editor configuration.

**Key files**

- `lib/main.dart`, `lib/app/app.dart`
- `lib/app/theme/app_colors.dart`, `app_tokens.dart`, `app_typography.dart`,
  `app_theme.dart`
- `lib/features/dashboard/dashboard_screen.dart`
- `test/widget_test.dart`
- `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`,
  `android/app/src/main/res/**`
- `pubspec.yaml`, `.gitignore`, `README.md`

**Verification**

- `dart format lib test` — completed.
- `flutter analyze` — no issues found.
- `flutter test` — 3/3 tests passed.
- `flutter build apk --debug` — succeeded; APK at
  `build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build apk --release` — succeeded; APK at
  `build/app/outputs/flutter-apk/app-release.apk`.
- Debug APK installed and launched on a Pixel 10a AVD running Android 17
  (API 37 emulator image); `am start -W` reported `Status: ok` and
  `LaunchState: COLD`, with no `AndroidRuntime` errors.
- UI hierarchy dump confirmed the expected copy, including
  "No readings yet" and the absence of any battery percentage.
- APK metadata: versionName `0.1.0`, versionCode `1`, minSdk `26`,
  targetSdk/compileSdk `36`; release manifest has no `INTERNET` permission.

**Known limitations**

- No native telemetry, sessions, charts, alerts or estimates are implemented.
- No physical-device validation has been performed; emulator only.
- Release signing is not configured. `app-release.apk` is signed with the
  Android debug certificate and must not be distributed.
- No GitHub Release exists. The two required release APK variants belong to a
  future approved release milestone (`instructions.md` §17.1).
