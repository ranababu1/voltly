# Current State

**Last updated:** 2026-10-20
**Milestone:** Phase 2 — Dashboard (core implemented; polish, lifecycle and accessibility review pending)
**Project version:** `0.3.0+3` (versionCode 3)

## Implemented and verified

| Area | State | Verification |
| --- | --- | --- |
| Android Flutter app shell | Launchable, label `Voltly`, app ID `com.voltly` | Debug APK installed and launched on Pixel 10a AVD (Android 17); `Status: ok` |
| Minimum platform | API 26 pinned in Gradle | APK `sdkVersion:'26'` |
| Design tokens | AMOLED palette, spacing, radius, typography | `flutter analyze`; widget test asserts theme |
| Dashboard shell | Branding, live dashboard, diagnostics entry | Widget test + emulator UI hierarchy |
| Dashboard primary metrics | Device battery level, charging state, power source, progress and Live/Stale state | 8 dashboard widget tests + emulator |
| Dashboard secondary metrics | Voltage, temperature, current, average current, charge counter and calculated power | 8 dashboard widget tests + emulator |
| Dashboard states | Loading, error/retry, unsupported, unavailable, invalid, stale, level-unavailable | Widget tests; zero fallbacks asserted |
| Shared telemetry UI | Formatting, badges, freshness timer used by dashboard and diagnostics | Both UI test suites |
| Launch experience | Black window in light and dark system modes | Android resource review; emulator cold launch |
| Large-text layout | Scrollable, no overflow at 320×640 and 2× text; dashboard and diagnostics covered | Widget tests passed |
| Static checks | Format, analyze clean | `dart format`, `flutter analyze` |
| Native telemetry adapter | 8 metrics, per-metric availability, no polling | Kotlin tests; debug APK build |
| Native unit conversions | mV→V, tenths °C→°C, µA→A, µAh→mAh, sentinel handling | 13 Kotlin tests |
| Dart telemetry contract | Strict parsing, zero-vs-unavailable, schema rejection | 16 Dart tests |
| Calculated power | Battery-side watts with 2 s input skew rule | 7 Dart tests |
| Channel client | MethodChannel snapshot, EventChannel stream, cancel handling | 6 Dart tests |
| Riverpod state | ProviderScope, service provider, auto-dispose stream, retry disabled | 8 dashboard + 6 diagnostics tests |
| Diagnostics UI | Live values, availability/reason, provenance, timestamps, stale/error/loading states | Widget tests + emulator UI hierarchy |
| End-to-end telemetry | Dashboard matched `dumpsys battery`; calculated power labeled | Pixel 10a AVD, Android 17 |
| Automated tests | 44 Dart + 13 Kotlin | `flutter test` 44/44; Gradle 13/13 |
| Android builds | Debug and release APKs build at version 0.3.0; release is debug-signed | `flutter build apk --debug`, `--release` succeeded; APK metadata checked |

**Deliberately absent:** charging sessions, charts, alerts, health/capacity
estimates, a charging animation and a light theme. The dashboard shows only real
device telemetry, explicit unavailable states and calculated power labeled as
approximate.

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
Riverpod service provider + auto-dispose StreamProvider
        ↓
DashboardScreen (primary/secondary metrics) + TelemetryDiagnosticsScreen
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
- `lib/core/telemetry/telemetry_providers.dart` is the only state wiring:
  one service provider and one auto-dispose stream provider with automatic
  retry disabled so failures surface immediately.
- `lib/features/dashboard/dashboard_screen.dart` consumes that provider and
  renders the live primary/secondary metrics. It does not query channels or
  Android APIs.
- `lib/features/dashboard/telemetry_presentation.dart` holds shared formatting,
  availability/provenance badges and the one-shot freshness timer.
- `lib/features/dashboard/telemetry_diagnostics_screen.dart` uses the same
  provider and presentation layer for contract-level diagnostics.
- The native receiver is released when the last consuming screen closes. Pausing
  the subscription while the app is backgrounded remains a Phase 2 follow-up.
- `docs/telemetry-contract.md` is the authoritative channel/payload contract.
- Planned persistence: Drift/SQLite with explicit migrations (Phase 3+).

## Toolchain

Flutter 3.47.7 · Dart 3.13.5 · flutter_riverpod 3.4.3 · JDK 21.0.12
(Corretto) · Gradle 9.3.1 · AGP 9.1.0 · Kotlin 2.4.0 · compile/target SDK 36 ·
minSdk 26 · Android SDK installed 37.0.0 / platform android-37.1 ·
JUnit 4.13.2 (test-only).

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

Last known results: format clean, analyze clean, 44/44 Dart tests passed,
13/13 Kotlin tests passed, debug and release builds succeeded at version 0.3.0.
The dashboard on the Pixel 10a AVD (Android 17) matched `dumpsys battery`:
100%, "Not charging", "Not plugged in", 5.00 V, 25.0 °C, 10.0 mAh and
4.50 W calculated. `--split-per-abi` has not been run and is required for the
arm64 release artifact.

## Known issues and limitations

- Physical-device telemetry validation is still pending. Emulator values prove
  the channel, parsing and UI pipeline, not hardware-specific sign, units or
  capability behavior.
- The emulator reports 0.900 A while unplugged and "Not charging"; Voltly shows
  that device-reported value faithfully. The emulator's battery model is not a
  reference for hardware current semantics.
- The user-facing dashboard core is implemented. Pausing telemetry while the app
  is backgrounded, a restrained charging animation and a full
  screen-reader/accessibility review remain Phase 2 follow-ups.
- The dashboard is dark-only by design; no light theme is included.
- `currentAverage` and `chargeCounter` are unsupported on many devices; the
  contract reports this explicitly and no fallback estimate is invented.
- Riverpod automatic retry is disabled for telemetry. A failed native channel
  shows an explicit error and requires manual Retry.
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
- Phase 1 adapter commit `e230514` was pushed and verified against
  `origin/main`.
- Phase 1 diagnostics commit `89ee8e5` was pushed on 2026-10-20; the remote
  `refs/heads/main` resolved to the same commit, and the working tree was clean
  before this documentation update.
- The Phase 2 dashboard core is committed with this documentation update on
  `main`. Verify the current tip with `git status -sb` and
  `git ls-remote --heads origin main`.
- `plan.md` and `instructions.md` are preserved at the root unchanged.


## Next task

**Phase 2 (increment 2) — lifecycle-aware updates, restrained charging motion
and accessibility review.**

Acceptance criteria:

1. Pause the telemetry subscription when the app becomes inactive/paused and
   resume it on return, without losing the last snapshot or polling. Readings
   age into stale state based on observation time, not on pause duration.
2. Add a restrained charging animation that reflects only the reported charging
   state, respects the platform reduce-motion setting, and never implies
   unsupported precision.
3. Review semantics, contrast and touch targets. Battery level, state, power
   source, metric cards and calculated power need clear screen-reader labels;
   status must never rely on color alone.
4. Validate the dashboard and diagnostics at 320×640 with 2× text and at a second
   screen size, including low-capability, stale and error states.
5. Add tests for lifecycle pause/resume and motion behavior; run format,
   analyze, Dart and Kotlin tests, and the debug build; verify on the emulator;
   update all documents and push.

Physical-device telemetry validation for Phase 1 remains outstanding and must be
completed before hardware accuracy can be claimed.
