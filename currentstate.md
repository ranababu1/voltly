# Current State

**Last updated:** 2026-10-20
**Milestone:** Phase 1 — Native Battery Telemetry (implemented; physical-device validation pending)
**Project version:** `0.2.0+2` (versionCode 2)

## Implemented and verified

| Area | State | Verification |
| --- | --- | --- |
| Android Flutter app shell | Launchable, label `Voltly`, app ID `com.voltly` | Debug APK installed and launched on Pixel 10a AVD (Android 17); `Status: ok` |
| Minimum platform | API 26 pinned in Gradle | APK `sdkVersion:'26'` |
| Design tokens | AMOLED palette, spacing, radius, typography | `flutter analyze`; widget test asserts theme |
| Dashboard shell | Branding, live-adapter status and diagnostics entry | Widget test + emulator UI hierarchy |
| Launch experience | Black window in light and dark system modes | Android resource review; emulator cold launch |
| Large-text layout | Scrollable, no overflow at 320×640 and 2× text; diagnostics covered | Widget tests passed |
| Static checks | Format, analyze clean | `dart format`, `flutter analyze` |
| Native telemetry adapter | 8 metrics, per-metric availability, no polling | Kotlin tests; debug APK build |
| Native unit conversions | mV→V, tenths °C→°C, µA→A, µAh→mAh, sentinel handling | 13 Kotlin tests |
| Dart telemetry contract | Strict parsing, zero-vs-unavailable, schema rejection | 16 Dart tests |
| Calculated power | Battery-side watts with 2 s input skew rule | 7 Dart tests |
| Channel client | MethodChannel snapshot, EventChannel stream, cancel handling | 6 Dart tests |
| Riverpod state | ProviderScope, service provider, auto-dispose stream, retry disabled | 7 diagnostics UI tests |
| Diagnostics UI | Live values, availability/reason, provenance, timestamps, stale/error/loading states | Widget tests + emulator UI hierarchy |
| End-to-end telemetry | Level, status, voltage, temperature, charge counter, calculated power | Emulator values matched `dumpsys battery` |
| Automated tests | 39 Dart + 13 Kotlin | `flutter test` 39/39; Gradle 13/13 |
| Android builds | Debug and release APKs build; release is debug-signed | `flutter build apk --debug`, `--release` succeeded |

**Deliberately absent:** user-facing dashboard telemetry cards, charging
sessions, charts, alerts and health/capacity estimates. The home screen shows no
battery value rather than a fabricated one; real readings live only in the
developer diagnostics view.

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
TelemetryDiagnosticsScreen (loading/live/stale/error states)
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
- `lib/features/dashboard/telemetry_diagnostics_screen.dart` subscribes while
  open, shows every metric independently, and releases the native receiver when
  closed. It also marks readings stale after five minutes and shows calculated
  power separately.
- `lib/features/dashboard/dashboard_screen.dart` remains presentation-only and
  is not yet the Phase 2 dashboard.
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

Last known results: format clean, analyze clean, 39/39 Dart tests passed,
13/13 Kotlin tests passed, debug and release builds succeeded. End-to-end
diagnostics on the Pixel 10a AVD (Android 17) matched `dumpsys battery`: 100%,
"Not charging", 5.00 V, 25.0 °C, 10.0 mAh and 4.50 W calculated. `--split-per-abi`
has not been run and is required for the arm64 release artifact.

## Known issues and limitations

- Physical-device telemetry validation is still pending. Emulator values prove
  the channel, parsing and UI pipeline, not hardware-specific sign, units or
  capability behavior.
- The emulator reports 0.900 A while unplugged and "Not charging"; Voltly shows
  that device-reported value faithfully. The emulator's battery model is not a
  reference for hardware current semantics.
- The user-facing dashboard is still Phase 2 work. The home screen intentionally
  shows no readings; the diagnostics screen is developer-only.
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
- The Phase 1 diagnostics increment is committed with this documentation
  update on `main`. Verify the current tip with `git status -sb` and
  `git ls-remote --heads origin main`.
- `plan.md` and `instructions.md` are preserved at the root unchanged.


## Next task

**Phase 2 (increment 1) — telemetry-driven dashboard core.**

Acceptance criteria:

1. Replace the foundation notice with dashboard content bound to
   `telemetrySnapshotProvider`. Every displayed value must come from the real
   service; no hard-coded or demo readings.
2. Give battery level, charging state and power source primary hierarchy, and
   show voltage, temperature, current and calculated battery-side power when
   available. Label calculated/approximate values distinctly.
3. Preserve explicit loading, unsupported, unavailable, invalid, stale and
   error states. Never render an unavailable metric as zero.
4. Show observation time and stale status; keep the manual Retry path.
5. Keep diagnostics reachable for development and remove any duplicate
   telemetry acquisition path.
6. Add widget tests with the fake service covering full, partial, low-capability,
   stale, loading and error states at normal and 2× text sizes.
7. Verify on the emulator, then run format, analyze, Dart and Kotlin tests, and
   the debug build; update all three documents and push.

Physical-device telemetry validation for Phase 1 remains outstanding and must
be completed before hardware accuracy can be claimed.
