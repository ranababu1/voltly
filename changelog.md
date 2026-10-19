# Changelog

Newest-first record of meaningful implementation changes.

## 2026-10-19 — Phase 1 (in progress): Native telemetry adapter

**Milestone:** Phase 1 — Native Battery Telemetry

**Summary**

- Added `BatteryTelemetryConversions`: pure, unit-tested conversions from
  Android's raw units to canonical percent, volts, amperes, Celsius and
  milliampere-hours, plus status/plug mappings and plausibility guards.
- Added `BatteryTelemetryReader`: the single native acquisition source. It reads
  `ACTION_BATTERY_CHANGED` extras and `BatteryManager` properties, reports each
  metric independently with availability/reason metadata, and never coerces
  missing values to zero.
- Added `BatteryTelemetryChannel`: MethodChannel `getSnapshot` plus an
  EventChannel that registers `ACTION_BATTERY_CHANGED` only while Dart listens.
  The receiver is unregistered on cancel/engine cleanup; no polling or
  background service is used.
- Registered the channel host in `MainActivity` and disposed it with the
  Flutter engine.
- Added the typed Dart contract: strict payload parsing, per-metric
  availability/source/timestamp, explicit zero-vs-unavailable handling,
  schema-version rejection and defensive degradation of malformed metrics.
- Added `calculateBatteryPower`: battery-side watts derived only from available,
  contemporaneous voltage and current, labeled calculated/approximate.
- Added `docs/telemetry-contract.md` documenting channels, units, sign
  convention, timestamps, availability, errors and versioning.
- Added 13 Kotlin unit tests and 29 Dart tests (16 contract, 7 power, 6 channel).

**Verification**

- `flutter analyze` — no issues.
- `flutter test` — 32/32 passed (29 new + 3 existing widget tests).
- `.\gradlew.bat :app:testDebugUnitTest` — 13/13 Kotlin tests passed.
- `flutter build apk --debug` — succeeded.

**Known limitations**

- The app does not yet display telemetry; the diagnostics UI and Riverpod
  integration are the next increment. End-to-end channel validation on the
  emulator is therefore pending.
- No physical-device telemetry validation has been performed. Vendor metric
  availability and current sign behavior remain unverified on hardware.
- `currentAverage` and `chargeCounter` are frequently unsupported; this is
  reported explicitly rather than estimated.

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
