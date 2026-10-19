# Current State

**Last updated:** 2026-10-19
**Milestone:** Phase 1 — Native Battery Telemetry (adapter complete; diagnostics UI pending)
**Project version:** `0.1.0+1` (versionCode 1)

## Implemented and verified

| Area | State | Verification |
| --- | --- | --- |
| Android Flutter app shell | Launchable, label `Voltly`, app ID `com.voltly` | Debug APK installed and launched on Pixel 10a AVD (Android 17); `Status: ok` |
| Minimum platform | API 26 pinned in Gradle | APK `sdkVersion:'26'` |
| Design tokens | AMOLED palette, spacing, radius, typography | `flutter analyze`; widget test asserts theme |
| Dashboard shell | Branding, tagline, explicit no-telemetry notice | Widget test + emulator UI hierarchy |
| Launch experience | Black window in light and dark system modes | Android resource review; emulator cold launch |
| Large-text layout | Scrollable, no overflow at 320×640 and 2× text | Widget test passed |
| Static checks | Format, analyze clean | `dart format`, `flutter analyze` |
| Native telemetry adapter | 8 metrics, per-metric availability, no polling | Kotlin tests; debug APK build |
| Native unit conversions | mV→V, tenths °C→°C, µA→A, µAh→mAh, sentinel handling | 13 Kotlin tests |
| Dart telemetry contract | Strict parsing, zero-vs-unavailable, schema rejection | 16 Dart tests |
| Calculated power | Battery-side watts with 2 s input skew rule | 7 Dart tests |
| Channel client | MethodChannel snapshot, EventChannel stream, cancel handling | 6 Dart tests |
| Automated tests | 32 Dart + 13 Kotlin | `flutter test` 32/32; Gradle 13/13 |
| Android builds | Debug APK builds with telemetry channels | `flutter build apk --debug` succeeded |

**Deliberately absent:** any on-screen telemetry display, charging sessions,
charts, alerts and health/capacity estimates. The current screen still shows no
battery value rather than a fabricated one.

## Architecture and data flow

```text
ACTION_BATTERY_CHANGED + BatteryManager
        ↓
BatteryTelemetryReader (single native acquisition source)
        ↓
BatteryTelemetryChannel (MethodChannel + EventChannel)
        ↓
PlatformBatteryTelemetryService (typed Dart client)
        ↓
TelemetrySnapshot (immutable, per-metric availability/provenance)
        ↓
[next increment] Riverpod diagnostics → presentation
```

- `lib/main.dart` sets the system UI overlay and runs `VoltlyApp`.
- `lib/app/app.dart` owns the `MaterialApp`; dark-only `AppTheme`.
- `lib/app/theme/` contains color, spacing/radius, typography and theme tokens.
- `lib/core/telemetry/telemetry_models.dart` strictly parses the versioned
  payload and models missing/invalid/stale values explicitly.
- `lib/core/telemetry/battery_telemetry_service.dart` is the only Dart channel
  client. Widgets must not access platform channels or Android APIs.
- `lib/core/telemetry/battery_power.dart` derives approximate battery-side
  watts only from available, contemporaneous voltage/current.
- `lib/features/dashboard/dashboard_screen.dart` remains presentation-only and
  is not yet wired to telemetry.
- Riverpod remains the selected single state approach and is not added yet.
- `docs/telemetry-contract.md` is the authoritative channel/payload contract.
- Planned persistence: Drift/SQLite with explicit migrations (Phase 3+).

## Toolchain

Flutter 3.47.7 · Dart 3.13.5 · JDK 21.0.12 (Corretto) · Gradle 9.3.1 ·
AGP 9.1.0 · Kotlin 2.4.0 · compile/target SDK 36 · minSdk 26 ·
Android SDK installed 37.0.0 / platform android-37.1 · JUnit 4.13.2
(test-only).

## Build and test commands

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
cd android
.\gradlew.bat :app:testDebugUnitTest
cd ..
flutter build apk --debug
flutter build apk --release
flutter build apk --release --split-per-abi
```

Last known results: format clean, analyze clean, 32/32 Dart tests passed,
13/13 Kotlin tests passed, debug build succeeded. The release build and
`--split-per-abi` have **not** been re-run since telemetry was added; both are
required before any release candidate.

## Known issues and limitations

- Native telemetry is implemented but not displayed in the app yet. The
  diagnostics UI is the next increment; end-to-end channel behavior has not
  been exercised through the UI.
- Emulator-only validation so far. Hardware behavior, vendor battery APIs,
  current sign and metric availability remain unverified on physical devices.
- `currentAverage` and `chargeCounter` are unsupported on many devices; the
  contract reports this explicitly and no fallback estimate is invented.
- Release signing is not configured; release APKs use the Android debug
  certificate. Distribution is blocked until production signing is set up
  outside source control.
- No AAB is configured or built.
- No release or GitHub Release has been published. `instructions.md` §17.1
  requires signed universal and arm64 APKs for an approved release; that
  workflow has not been executed.
- The Gradle build emits an SDK XML version warning (installed tooling is newer
  than a component expects). It did not affect the build; resolve during a
  deliberate toolchain update, not opportunistically.

## Git

- Branch: `main`, tracking `origin/main`.
- Remote: `origin` → `https://github.com/ranababu1/voltly.git`
- Initial Phase 0 commit `efdce6b` was pushed on 2026-10-19. The remote
  `refs/heads/main` resolved to the same commit, and `git status -sb` reported
  `## main...origin/main` with a clean tree.
- `plan.md` and `instructions.md` are preserved at the root unchanged.
- Later documentation updates are committed separately. Verify the current tip
  with `git status -sb` and `git ls-remote --heads origin main`.


## Next task

**Phase 1 (increment 2) — Riverpod-backed telemetry diagnostics on the real
service.**

Acceptance criteria:

1. Add `flutter_riverpod` and wrap the app in `ProviderScope`; expose one
   service provider and an `autoDispose` stream provider. No competing state
   approach.
2. Add a diagnostics screen reachable from the dashboard. It subscribes only
   while open, so closing it cancels the native receiver.
3. Show each metric independently with value and unit, or availability plus
   reason. Include observation time, staleness, provenance, and calculated
   battery-side power clearly labeled as calculated/approximate.
4. Cover loading, available, unavailable, error, stale and large-text states in
   widget tests using a fake service supplied through a provider override.
5. Validate the native channel end-to-end on the Android emulator and compare
   level, status, voltage and temperature with `adb shell dumpsys battery`.
6. Run format, analyze, Dart and Kotlin tests, and the debug build; update
   `changelog.md`, `currentstate.md` and `README.md`; commit and push.

After that, Phase 1 closeout still requires physical-device telemetry
validation, which remains pending until hardware is available.
