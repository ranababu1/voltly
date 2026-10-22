# Current State

**Last updated:** 2026-10-22
**Milestone:** Phase 3 — Charging Sessions (implementation complete; physical-device validation pending)
**Project version:** `0.8.0+8` (versionCode 8)

## Release

- Tag: `v0.6.0` (pre-release)
- Release: https://github.com/ranababu1/voltly/releases/tag/v0.6.0
- Assets: `Voltly-v0.6.0-universal.apk` (48.9 MB) and
  `Voltly-v0.6.0-arm64-v8a.apk` (17.0 MB)
- Signing certificate SHA-256:
  `54:3D:C7:A8:C3:D4:E3:3D:63:E8:18:0F:09:1F:2A:BD:07:9D:10:2D:3E:32:E8:71:50:38:8F:04:FE:34:D6:41`
- Marked pre-release because the session history UI and physical-device
  validation were still pending at publication; `v0.6.0` predates live session
  tracking and history.
- The current development build is `0.8.0+8`; it is not published.
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
| Live session coordinator | App-scoped DB/repository; serialized snapshots; persisted start/sample/end; restart recovery; failure pause/retry | 6 coordinator + 4 provider tests |
| Session history UI | Dashboard entry; active/completed/interrupted, gap, partial and pruned labels; 2× text; semantics | 7 history UI tests; emulator active session |
| Session detail | Stored summary by id, loading/not-found/error, navigation from history | 7 detail tests; emulator detail screen |
| Stored trend charts | Level/current/temperature/power from retained samples; gap/unavailable breaks; no interpolation; chart semantics | 6 chart-data tests; 2× text; emulator semantics |
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
| Riverpod state | `TelemetryController` owns one app-scoped subscription; explicit retry | Dashboard, diagnostics, lifecycle and history tests |
| Diagnostics UI | Live values, availability/reason, provenance, timestamps, stale/error/loading states | Widget tests + emulator UI hierarchy |
| End-to-end telemetry | Dashboard matched `dumpsys`; live simulated update to 42%/Charging/AC; session persisted and shown in history | Pixel 10a AVD, Android 17 |
| Automated tests | 111 Dart + 13 Kotlin | `flutter test` 111/111; Gradle 13/13 |
| Android builds | Debug/release at 0.8.0; universal 51.5 MB, arm64 17.8 MB; production-signed SQLite bundles | Builds; `apksigner`; APK metadata; emulator |

**Deliberately absent:** alerts, health/capacity estimates and a light theme.
Phase 4 estimate/alert work remains. The dashboard and session screens show only
real telemetry and stored samples, explicit unavailable states, and calculated
battery-side power labeled as approximate.

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
TelemetryController (app-scoped single subscription; pauses when inactive,
retains last snapshot; explicit retry)
        ↓
TelemetrySnapshot → DashboardScreen + TelemetryDiagnosticsScreen
        ↓
SessionCoordinator → ChargingSessionTracker → SessionRepository
        ↓
Drift/SQLite → SessionHistoryScreen → SessionDetailScreen + trend charts
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
- `lib/core/sessions/` contains the session domain, coordinator, tracking
  providers and honest formatting. `SessionCoordinator` serializes real
  snapshots through `ChargingSessionTracker` and the persistence boundary,
  restores the active session at launch and pauses on storage failure.
- `lib/core/persistence/` contains Drift schema v1, table/index definitions,
  the transactional repository, retention policy and stored-row mapper. The
  repository writes session + sample atomically, recovers the active session,
  reconciles duplicate active rows and enforces bounded retention.
- `openVoltlyDatabase()` resolves `voltly.sqlite` in the application support
  directory through `path_provider`. The app-scoped `databaseProvider` opens it
  lazily and closes it when the provider scope is disposed.
- `lib/core/telemetry/telemetry_providers.dart` contains the app-active flag and
  `TelemetryController`, which owns the single app-scoped service subscription
  and cancels it when the app is not resumed. The last snapshot is retained;
  retry is explicit.
- `lib/features/sessions/session_history_screen.dart` lists recent sessions and
  labels active/completed/interrupted, gaps, partial sessions and pruned sample
  lists. Tapping a card opens stored session detail. The dashboard links to the
  list and shows a storage-error banner with Retry.
- `lib/features/sessions/session_detail_screen.dart` loads one session and its
  retained samples through `sessionDetailProvider`. It exposes loading,
  not-found and error states plus level/current/temperature/power trend cards.
- `lib/core/sessions/session_chart_data.dart` splits stored points at missing
  values and gaps over five minutes; `session_trend_chart.dart` draws only those
  segments and never interpolates.
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
- `docs/release.md` documents signing, APK naming, verification and release
  safety; `.github/workflows/release.yml` handles future version tags.

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

Last known results: format clean, analyze clean, 111/111 Dart tests passed,
13/13 Kotlin tests passed, signed debug/release builds succeeded at version
0.8.0. Universal release is 51.5 MB; arm64 is 17.8 MB; both are production-signed,
bundle SQLite and have no `INTERNET` permission. On the Pixel 10a AVD
(Android 17), simulated charging produced live dashboard values, a stored active
session and a session-detail screen with gap-aware battery trend semantics
(3 stored samples, 2 sampling breaks). The dashboard also matched
`dumpsys battery` earlier at 100%, "Not charging", 5.00 V, 25.0 °C, 10.0 mAh and
4.50 W calculated. The arm64 APK cannot install on this x86_64 emulator.

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
- Live session tracking, history, detail and stored trend charts are implemented
  and automated-tested. Alerts, health/capacity estimates and other Phase 4
  features are not implemented. No v2 migration exists; the newer-schema guard
  is tested.
- The last published GitHub Release `v0.6.0` predates live session tracking,
  history and charts. The current `0.8.0+8` development build is not published.
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
- Release signing commit `16474bd` and build-ignore commit `6e1d02a` were pushed
  on 2026-10-20. Annotated tag `v0.6.0` points at `6e1d02a`; the tag was pushed.
- Release workflow commit `1fd7156` was pushed after the first release. The
  workflow is active and will handle future `v*` tags.
- GitHub Release `v0.6.0` is a pre-release with both signed APK assets. Both
  assets were downloaded again and their SHA-256 hashes matched.
- Live-session/history commit `3dc56db` was pushed on 2026-10-22; the remote
  `refs/heads/main` resolved to the same commit, and the working tree was clean
  before this documentation update.
- Session-detail/chart commit `bb2e7bc` was pushed on 2026-10-22; the remote
  `refs/heads/main` resolved to the same commit, and the working tree was clean
  before this documentation update.
- Verify the current tip with `git status -sb` and
  `git ls-remote --heads origin main`.
- `plan.md` and `instructions.md` are preserved at the root unchanged.

## Next task

**Phase 4 (increment 1) — evidence-based time-to-full/empty estimates.**

Prerequisite complete: Phase 3 session tracking, history, detail and stored trend
charts (111 Dart tests). Physical-device validation remains outstanding.

Acceptance criteria:

1. Implement a pure estimator using only retained telemetry samples and a
   documented minimum observation window. Require an available charging state,
   sufficient elapsed coverage and a consistent level direction.
2. Return an explicit unavailable reason when samples are insufficient, stale,
   gap-affected, pruned across the estimation window or contradictory. Never
   substitute zero, charger power, capacity or battery health.
3. Show any time-to-full/empty estimate as approximate and calculated, with its
   coverage/assumptions visible; withhold it automatically when evidence is
   inadequate.
4. Add tests for valid charging/discharging cases, too-short windows, gaps,
   unavailable state/level, pruning and noisy levels.
5. Keep the estimate accessible at 320×640 with 2× text and expose a concise
   screen-reader label.
6. Add repository/detail chart tests as needed; run build_runner, format,
   analyze, Dart/Kotlin tests, debug/release builds; update documentation and
   push.

Physical-device telemetry and manual screen-reader validation remain
outstanding. Alerts, settings and battery-health estimates are later increments.
