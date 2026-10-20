# Current State

**Last updated:** 2026-10-20
**Milestone:** Phase 3 — Charging Sessions (in progress; domain and persistence foundations complete, live integration/UI pending)
**Project version:** `0.6.0+6` (versionCode 6)

## Release

- Tag: `v0.6.0` (pre-release)
- Release: https://github.com/ranababu1/voltly/releases/tag/v0.6.0
- Assets: `Voltly-v0.6.0-universal.apk` (48.9 MB) and
  `Voltly-v0.6.0-arm64-v8a.apk` (17.0 MB)
- Signing certificate SHA-256:
  `54:3D:C7:A8:C3:D4:E3:3D:63:E8:18:0F:09:1F:2A:BD:07:9D:10:2D:3E:32:E8:71:50:38:8F:04:FE:34:D6:41`
- Marked pre-release because session history UI and physical-device validation
  are still pending.
- Both uploaded assets were downloaded again and their SHA-256 hashes matched
  the local signed builds.
- A tag-triggered release workflow (`.github/workflows/release.yml`) is added for
  future `v*` tags; `v0.6.0` was published manually before that workflow existed.

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
| Local persistence | Drift schema v1, indexes, foreign keys, nullable values, availability/provenance metadata | 13 persistence tests; schema inspection |
| Transactional repository | Atomic session/sample writes, duplicate handling, restart recovery, duplicate-active reconciliation, delete-all | Repository tests |
| Retention | 100 ended sessions, 180 days, 720 samples/session; active sessions retained; pruning flagged honestly | Retention/cap tests |
| Release signing | Dedicated Voltly key outside repo; four GitHub Actions secrets; release build verified with `apksigner` | Certificate SHA-256 and package/version/ABI checks |
| GitHub release | `v0.6.0` pre-release with universal + arm64 APKs | Uploaded asset download and hash verification |
| Static checks | Format, analyze clean | `dart format`, `flutter analyze` |
| Native telemetry adapter | 8 metrics, per-metric availability, no polling | Kotlin tests; debug APK build |
| Native unit conversions | mV→V, tenths °C→°C, µA→A, µAh→mAh, sentinel handling | 13 Kotlin tests |
| Dart telemetry contract | Strict parsing, zero-vs-unavailable, schema rejection | 16 Dart tests |
| Calculated power | Battery-side watts with 2 s input skew rule | 7 Dart tests |
| Channel client | MethodChannel snapshot, EventChannel stream, cancel handling | 6 Dart tests |
| Riverpod state | `TelemetryController` owns one subscription; auto-dispose; explicit retry | 8 dashboard + 6 diagnostics + 2 lifecycle tests |
| Diagnostics UI | Live values, availability/reason, provenance, timestamps, stale/error/loading states | Widget tests + emulator UI hierarchy |
| End-to-end telemetry | Dashboard matched `dumpsys`; live simulated update to 42%/Charging/AC; resume retained data | Pixel 10a AVD, Android 17 |
| Automated tests | 78 Dart + 13 Kotlin | `flutter test` 78/78; Gradle 13/13 |
| Android builds | Debug and release APKs build at version 0.6.0; release is production-signed and bundles SQLite for three ABIs | Debug/release builds; `apksigner`; APK metadata checked |

**Deliberately absent:** live session wiring, session history/detail UI, charts,
alerts, health/capacity estimates and a light theme. The dashboard still shows
only real device telemetry, explicit unavailable states and calculated power
labeled as approximate. The session tracker and database repository are tested
foundations but are not started by the running app yet.

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

Session path (implemented, not yet wired):
TelemetrySnapshot → ChargingSessionTracker → SessionRepository → Drift/SQLite
History UI is the next increment.
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
- `lib/core/persistence/` contains Drift schema v1, table/index definitions,
  the transactional repository, retention policy and stored-row mapper. The
  repository writes session + sample atomically, recovers the active session,
  reconciles duplicate active rows and enforces bounded retention.
- `openVoltlyDatabase()` resolves `voltly.sqlite` in the application support
  directory through `path_provider`; the running app does not call it yet, so no
  production database file exists.
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
- `docs/persistence.md` documents schema v1, transactions, recovery, retention
  and deletion behavior.

## Toolchain

Flutter 3.47.7 · Dart 3.13.5 · flutter_riverpod 3.4.3 · Drift 2.35.2 ·
SQLite 3.5.2 (native assets) · path_provider 2.1.6 · JDK 21.0.12 (Corretto) ·
Gradle 9.3.1 · AGP 9.1.0 · Kotlin 2.4.0 · compile/target SDK 36 · minSdk 26 ·
Android SDK installed 37.0.0 / platform android-37.1 · JUnit 4.13.2
(test-only) · drift_dev 2.35.1 / build_runner 2.16.2 (development only).

## Build and test commands

```powershell
flutter pub get
dart run build_runner build
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

Last known results: format clean, analyze clean, 78/78 Dart tests passed,
13/13 Kotlin tests passed, debug and release builds succeeded at version 0.6.0.
The persistence slice added 13 tests; Kotlin was unchanged. Release APK is
48.9 MB, bundles SQLite for arm64-v8a/armeabi-v7a/x86_64 and has no `INTERNET`
permission. The dashboard on the Pixel 10a AVD (Android 17) matched
`dumpsys battery`:
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
- Charging-session domain and Drift/SQLite persistence are implemented and
  tested, but the tracker and repository are not wired to the live controller or
  UI. The running app does not create a production database file yet.
- Session history/detail UI, charts, alerts and estimates are not implemented
  yet (Phase 3+). No v2 migration exists; the newer-schema guard is tested.
- `currentAverage` and `chargeCounter` are unsupported on many devices; the
  contract reports this explicitly and no fallback estimate is invented.
- Riverpod automatic retry is disabled for telemetry. A failed native channel
  shows an explicit error and requires manual Retry.
- Release signing is configured with a dedicated Voltly key outside source
  control and the four GitHub Actions secrets. The key and credentials must be
  backed up; losing them prevents updating an installed release.
- `v0.6.0` is published as a pre-release. Session history UI and physical-device
  telemetry/TalkBack validation remain pending, so it is not a stable release.
- No AAB is configured or built. GitHub Releases currently use the two signed
  APKs required by `instructions.md` §17.1.
- The arm64 APK was signature/ABI-checked but could not be installed on the
  x86_64 emulator used for the universal APK smoke test.
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
- Phase 3 persistence commit `a19b636` was pushed on 2026-10-20; the remote
  `refs/heads/main` resolved to the same commit, and the working tree was clean
  before this documentation update.
- Verify the current tip with `git status -sb` and
  `git ls-remote --heads origin main`.
- `plan.md` and `instructions.md` are preserved at the root unchanged.

## Next task

**Phase 3 (increment 2) — wire live session persistence and expose history.**

Prerequisite complete: session tracker, schema v1, transactional repository,
recovery and retention (29 tests across domain and persistence).

Acceptance criteria:

1. Create one app-scoped lazy database/repository and close it deterministically
   when the app scope is disposed. No second database instance may be created by
   screens.
2. Feed each real telemetry snapshot through a single session coordinator using
   `ChargingSessionTracker`; persist `started`, `sample` and `ended` updates
   transactionally with the active session id.
3. Restore the active session on startup through `recoverActiveSession()` and
   `ChargingSessionTracker.restoreActiveSession()`. Record the restart gap
   instead of starting a duplicate session.
4. Keep sampling foreground-only: lifecycle pause stops acquisition without
   ending the session; resume records the gap. Database failures must not crash
   the dashboard and must surface explicitly rather than silently dropping data.
5. Add a session history list reachable from the dashboard with loading, empty,
   error, active, completed, interrupted and pruned/partial labels. Do not imply
   continuous history when gaps or retention pruning exist; validate semantics
   and 320×640 at 2× text.
6. Add coordinator/provider and history-UI tests, including restart recovery,
   duplicate snapshots, persistence failure and partial-history copy.
7. Run build_runner, format, analyze, Dart/Kotlin tests, debug/release builds;
   update documentation and push.

Physical-device telemetry and manual screen-reader validation remain
outstanding. Session detail and trend charts are the following increment.
