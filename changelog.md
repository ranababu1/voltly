# Changelog

Newest-first record of meaningful implementation changes.

## 2026-10-20 — Phase 2 (in progress): telemetry-driven dashboard core

**Milestone:** Phase 2 — Dashboard and Visual System

**Summary**

- Replaced the foundation notice with a dashboard bound to
  `telemetrySnapshotProvider`. All displayed values come from the real
  telemetry service.
- Battery level, charging state and power source form the primary hierarchy,
  with a level progress indicator, explicit Live/Stale state and a stale
  warning.
- Added secondary cards for voltage, temperature, current now, average current
  and charge counter, plus a dedicated calculated battery-side power card.
- Unsupported, temporarily unavailable, invalid and stale values are shown
  explicitly with reasons. No unavailable metric is rendered as zero.
- Added loading and error cards with a Retry action; telemetry errors still do
  not auto-retry.
- Extracted shared telemetry presentation (formatting, availability/provenance
  badges and freshness timer) used by both the dashboard and diagnostics.
  Added a `displayLarge` typography token for the primary battery percentage.
- Added eight dashboard widget tests and a shared app-pump test helper;
  refactored diagnostics tests to reuse the shared fixtures.
- Bumped the version to `0.3.0+3`.

**Verification**

- `dart format --output=none --set-exit-if-changed lib test` — exit 0.
- `flutter analyze` — no issues.
- `flutter test` — 44/44 passed (16 contract, 7 power, 6 channel, 6
  diagnostics, 8 dashboard, 1 app/theme).
- `.\gradlew.bat :app:testDebugUnitTest` — 13/13 Kotlin tests passed.
- `flutter build apk --debug` — succeeded.
- `flutter build apk --release` — succeeded (43.3 MB, debug certificate; not
  distributable).
- APKs report versionName `0.3.0`, versionCode `3`, minSdk `26`, compile/target
  SDK `36`. The release manifest has no `INTERNET` permission.
- Installed and cold-launched the debug APK on a Pixel 10a AVD (Android 17).
  Dashboard values matched `dumpsys battery`: 100%, "Not charging",
  "Not plugged in", 5.00 V, 25.0 °C and 10.0 mAh. Calculated power showed
  4.50 W and was labeled Calculated/approximate. No `AndroidRuntime` errors.
- Dashboard and diagnostics text were captured through `uiautomator dump`;
  no fabricated or zero-filled unavailable values were observed.

**Known limitations**

- Physical-device telemetry validation remains pending. Emulator values prove
  the pipeline and UI, not hardware-specific sign, units or capability.
- The emulator reports 0.900 A while unplugged and "Not charging"; Voltly shows
  that device-reported value faithfully.
- Restrained charging animation, pausing updates while backgrounded and a full
  screen-reader/accessibility review remain Phase 2 follow-ups.
- The dashboard is dark-only; no light theme is included.
- Release signing, AAB generation and GitHub Release APK artifacts remain
  outstanding for an approved release.

## 2026-10-20 — Phase 1 complete: real-service telemetry diagnostics

**Milestone:** Phase 1 — Native Battery Telemetry

**Summary**

- Added `flutter_riverpod` 3.4.3, wrapped the app in `ProviderScope`, and added
  one telemetry service provider plus an auto-dispose `StreamProvider`.
  Automatic provider retry is disabled so native failures surface immediately.
- Added a developer diagnostics screen reachable from the dashboard. It renders
  every metric independently with value/unit or availability plus reason,
  per-metric observation time, provenance badges, live/stale state, and
  calculated battery-side power. Loading, error, unavailable, stale and
  retry states are covered.
- The auto-disposed provider releases the native `ACTION_BATTERY_CHANGED`
  receiver when the screen closes, preserving the no-polling design.
- Updated the dashboard foundation copy and capability rows to reflect the live
  adapter; the dashboard still shows no telemetry values.
- Added a replaying fake telemetry service and seven diagnostics widget tests,
  including navigation, error, unavailable and 2× text scaling coverage.
- Bumped the project version to `0.2.0+2`.

**Verification**

- `flutter analyze` — no issues.
- `flutter test` — 39/39 passed (16 contract, 7 power, 6 channel, 7 diagnostics,
  3 foundation widget tests).
- `.\gradlew.bat :app:testDebugUnitTest` — 13/13 Kotlin tests passed.
- `flutter build apk --debug` — succeeded.
- `flutter build apk --release` — succeeded (43.3 MB, debug certificate; not
  distributable).
- Debug APK installed and cold-launched on a Pixel 10a AVD (Android 17).
  On-device diagnostics matched `dumpsys battery`: level 100%, status
  "Not charging", 5.00 V, 25.0 °C, charge counter 10.0 mAh. Calculated power
  showed 4.50 W and was labeled Calculated/approximate. No `AndroidRuntime`
  errors.
- The diagnostics UI text was captured through `uiautomator dump`; no
  fabricated or zero-filled unavailable values were observed.

**Known limitations**

- Physical-device telemetry validation is still pending. Emulator values prove
  the pipeline, not hardware-specific sign or unit behavior.
- The emulator reports 0.900 A while unplugged and "Not charging"; this is shown
  faithfully as device-reported data.
- The user-facing dashboard remains Phase 2 work.
- Release signing, AAB generation and the universal + arm64 GitHub Release
  artifacts remain outstanding for an approved release.

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
