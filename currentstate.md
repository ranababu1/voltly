# Current State

**Last updated:** 2026-10-20
**Milestone:** Phase 3 — Charging Sessions (in progress; session domain complete, persistence pending)
**Project version:** `0.5.0+5` (versionCode 5)

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
| Lifecycle control | Controller cancels acquisition when inactive, retains last snapshot, resubscribes on resume | 2 provider tests + app lifecycle widget test |
| Charging motion | Pulse only for reported charging; stops for reduced motion; decorative | Dashboard wiring test + motion test |
| Accessibility | Concise semantics labels; decorative progress excluded; 2× text; no color-only status | Semantics test + `uiautomator dump` |
| Shared telemetry UI | Formatting, badges, freshness timer used by dashboard and diagnostics | Both UI test suites |
| Launch experience | Black window in light and dark system modes | Android resource review; emulator cold launch |
| Large-text layout | Scrollable, no overflow at 320×640 and 2× text; dashboard and diagnostics covered | Widget tests passed |
| Charging-session domain | Normalized session/sample models with nullable levels, provenance, sample count and gap/coverage metadata | 2 sample-mapping tests; `flutter analyze` |
| Session state machine | Charging starts, full/discharging completes, `not_charging` grace, interrupted/partial states, duplicate and restart handling | 14 tracker tests |
| Static checks | Format, analyze clean | `dart format`, `flutter analyze` |
| Native telemetry adapter | 8 metrics, per-metric availability, no polling | Kotlin tests; debug APK build |
| Native unit conversions | mV→V, tenths °C→°C, µA→A, µAh→mAh, sentinel handling | 13 Kotlin tests |
| Dart telemetry contract | Strict parsing, zero-vs-unavailable, schema rejection | 16 Dart tests |
| Calculated power | Battery-side watts with 2 s input skew rule | 7 Dart tests |
| Channel client | MethodChannel snapshot, EventChannel stream, cancel handling | 6 Dart tests |
| Riverpod state | `TelemetryController` owns one subscription; auto-dispose; explicit retry | 8 dashboard + 6 diagnostics + 2 lifecycle tests |
| Diagnostics UI | Live values, availability/reason, provenance, timestamps, stale/error/loading states | Widget tests + emulator UI hierarchy |
| End-to-end telemetry | Dashboard matched `dumpsys`; live simulated update to 42%/Charging/AC; resume retained data | Pixel 10a AVD, Android 17 |
| Automated tests | 65 Dart + 13 Kotlin | `flutter test` 65/65; Gradle 13/13 |
| Android builds | Debug and release APKs build at version 0.5.0; release is debug-signed | `flutter build apk --debug`, `--release` succeeded; APK metadata checked |

**Deliberately absent:** session persistence and history UI, charts, alerts,
health/capacity estimates and a light theme. The dashboard shows only real device
telemetry, explicit unavailable states and calculated power labeled as
approximate. Session classification exists as a pure domain layer only.

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
TelemetryController (single subscription; pauses when inactive,
retains last snapshot; explicit retry)
        ↓
TelemetrySnapshot → DashboardScreen + TelemetryDiagnosticsScreen

Planned session path:
TelemetrySnapshot → ChargingSessionTracker → SessionRepository → Drift/SQLite
```

- `lib/main.dart` sets the system UI overlay and runs `VoltlyApp` in a
  `ProviderScope`.
- `lib/app/app.dart` owns the `MaterialApp` and observes app lifecycle changes.
- `lib/app/theme/` contains color, spacing/radius, typography and theme tokens.
- `lib/core/telemetry/telemetry_models.dart` strictly parses the versioned
  payload and models missing/invalid/stale values explicitly.
- `lib/core/telemetry/battery_telemetry_service.dart` is the only Dart channel
  client. Widgets must not access platform channels or Android APIs.
- `lib/core/telemetry/battery_power.dart` derives approximate battery-side
  watts only from available, contemporaneous voltage/current.
- `lib/core/sessions/` contains the pure session domain. `ChargingSession`
  records lifecycle and sampling-gap metadata, `TelemetrySample` retains the
  original snapshot with provenance, and `ChargingSessionTracker` turns real
  snapshots into started/sample/ended updates. It has no database, UI or
  lifecycle dependencies.
- Planned persistence: `ChargingSessionTracker` → transactional Drift/SQLite
  repository → retained session history (next increment). No database exists
  yet.
- `lib/core/telemetry/telemetry_providers.dart` contains the app-active flag and
  `TelemetryController`, which owns the single service subscription and cancels
  it when the app is not resumed. The last snapshot is retained; retry is
  explicit.
- `lib/features/dashboard/dashboard_screen.dart` consumes the controller and
  renders the live primary/secondary metrics. It does not query channels or
  Android APIs.
- `lib/features/dashboard/telemetry_presentation.dart` holds shared formatting,
  availability/provenance badges, the one-shot freshness timer and the
  reduce-motion-aware charging pulse.
- `lib/features/dashboard/telemetry_diagnostics_screen.dart` uses the same
  controller and presentation layer for contract-level diagnostics.
- The native receiver is released when the app leaves the foreground or the last
  consuming screen closes.
- `docs/telemetry-contract.md` is the authoritative channel/payload contract.

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

Last known results: format clean, analyze clean, 65/65 Dart tests passed,
13/13 Kotlin tests passed, debug and release builds succeeded at version 0.5.0.
The session slice added 16 tests; Kotlin was unchanged. The dashboard on the
Pixel 10a AVD (Android 17) matched `dumpsys battery`:
100%, "Not charging", 5.00 V, 25.0 °C, 10.0 mAh and 4.50 W calculated.
Simulated `level 42`, `status 2` and `ac 1` updated the running dashboard to
42%, "Charging" and "AC" without restart. Home then resume produced a HOT
return with fresh values. `--split-per-abi` has not been run and is required
for the arm64 release artifact.

## Known issues and limitations

- Physical-device telemetry validation is still pending. Emulator values prove
  the channel, parsing and UI pipeline, not hardware-specific sign, units or
  capability behavior.
- The emulator reports 0.900 A while unplugged and "Not charging"; Voltly shows
  that device-reported value faithfully. The emulator's battery model is not a
  reference for hardware current semantics.
- Lifecycle pause/resume, the reduce-motion-aware charging pulse and semantics
  labels are implemented and automated-tested. Manual TalkBack validation on a
  physical device remains pending.
- The dashboard is dark-only by design; no light theme is included.
- The charging-session domain is implemented but not yet persisted, wired to the
  live controller, or displayed. Drift/SQLite persistence, retention and history
  UI remain pending.
- Session history, charts, alerts and estimates are not implemented yet
  (Phase 3+).
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
- Phase 2 dashboard commit `188aed0` was pushed on 2026-10-20; the remote
  `refs/heads/main` resolved to the same commit, and the working tree was clean
  before this documentation update.
- Phase 2 completion commit `de38dc3` was pushed on 2026-10-20; the remote
  `refs/heads/main` resolved to the same commit, and the working tree was clean
  before this documentation update.
- Phase 3 session-domain commit `73c8bda` was pushed on 2026-10-20; the remote
  `refs/heads/main` resolved to the same commit, and the working tree was clean
  before this documentation update.
- Verify the current tip with `git status -sb` and
  `git ls-remote --heads origin main`.
- `plan.md` and `instructions.md` are preserved at the root unchanged.

## Next task

**Phase 3 (increment 1b) — Drift/SQLite persistence and session repository.**

Prerequisite complete: normalized `ChargingSession`/`TelemetrySample` models and
the pure `ChargingSessionTracker` (16 tests).

Acceptance criteria:

1. Add Drift/SQLite and path resolution dependencies with Android-compatible
   native libraries; no database file may be committed.
2. Define schema v1 for `charging_sessions` and `telemetry_samples`, preserving
   nullable levels, availability/provenance metadata, lifecycle state, sample
   count and gap/coverage fields. Add explicit indexes for intended queries.
3. Provide explicit schema creation/migration and migration tests, including
   opening an existing v1 database and rejecting a newer unsupported schema
   rather than silently mutating it.
4. Implement a repository that writes a session and its sample in one
   transaction, updates active sessions atomically and restores the active
   session after restart. Define a bounded retention policy and a
   user-controlled delete-all operation.
5. Add tests for inserts/updates, duplicate samples, active-session recovery,
   retention bounds and deletion. Keep sampling foreground-only; gaps caused by
   backgrounding must remain visible.
6. Run format, analyze, Dart and Kotlin tests, debug/release builds; update all
   documents; commit and push.

Physical-device telemetry and manual screen-reader validation remain
outstanding. Session history must not imply continuous sampling when the app was
backgrounded or telemetry was unavailable.
