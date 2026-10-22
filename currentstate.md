# Current State

**Last updated:** 2026-10-22
**Milestone:** Phase 4 — Estimates (increment 1 complete; physical-device validation pending)
**Project version:** `0.9.0+9` (versionCode 9)

## Release

- Tag: `v0.9.0-preview` (pre-release), commit `8eacc32`
- Release: https://github.com/ranababu1/voltly/releases/tag/v0.9.0-preview
- Assets:
  - `Voltly-v0.9.0-preview-universal.apk` — 53,968,846 bytes (51.5 MB),
    versionCode 9, SHA-256
    `A0A7DD579C690A5CB5C09A361E1C73EDDD0640586E9E536C48121520B59C59D9`
  - `Voltly-v0.9.0-preview-arm64-v8a.apk` — 18,716,326 bytes (17.8 MB),
    versionCode 2009, SHA-256
    `47C3AB6B44C66A81794BA874307FF066BCC45588897C4FC6CC7ACFE279DB0096`
  - `Voltly-v0.9.0-preview.aab` — 53,558,550 bytes (51.1 MB), SHA-256
    `1D137BE4FB509E48B7344899824B6308769D57D83A129DB0CD3445CC6328E958`
    (Google Play artifact; not directly installable)
- Signing certificate SHA-256:
  `54:3D:C7:A8:C3:D4:E3:3D:63:E8:18:0F:09:1F:2A:BD:07:9D:10:2D:3E:32:E8:71:50:38:8F:04:FE:34:D6:41`
- Marked pre-release because physical-device telemetry validation and human
  TalkBack validation remain pending. It is not a stable release.
- All three assets were downloaded again from GitHub, signature-checked, and
  their SHA-256/size values recorded above. The universal APK installed and
  cold-launched on the Pixel 10a AVD; the arm64 APK is ABI-compatible only with
  arm64 hardware and the AAB is not installable.
- APKs have no `INTERNET` permission. Both APKs verify with the production
  certificate; the AAB verifies with `jarsigner`.
- The tag-triggered workflow (`.github/workflows/release.yml`) now builds and
  publishes both APKs and the AAB. A first run exposed a missing tracked Gradle
  wrapper; commit `8eacc32` fixed that and the retagged preview published
  successfully (workflow run `39814224399`, conclusion success).
- Previous release: `v0.6.0` (pre-release), which predates live session tracking,
  history, charts and estimates.

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
| Live session coordinator | App-scoped DB/repository; serialized snapshots; persisted start/sample/end; restart recovery; failure pause/retry | 6 coordinator + 7 provider tests |
| Session history UI | Dashboard entry; active/completed/interrupted, gap, partial and pruned labels; 2× text; semantics | 7 history UI tests; emulator active session |
| Session detail | Stored summary by id, loading/not-found/error, navigation from history | 7 detail tests; emulator detail screen |
| Stored trend charts | Level/current/temperature/power from retained samples; gap/unavailable breaks; no interpolation; chart semantics | 6 chart-data tests; 2× text; emulator semantics |
| Time-to-full/empty estimator | Pure 10–30-minute retained window; fresh/consecutive samples required; consistent state and direction; 24-hour cap; one-shot stale invalidation; no capacity/health/charger substitution | 16 estimator tests; 2 estimate provider cases |
| Estimate UI | Active-session card; approximate label, coverage, assumptions, pruning/gap notes; explicit unavailable reason; semantics; 2× text | 6 estimate-card tests; emulator withheld state |
| Local persistence | Drift schema v1, indexes, foreign keys, nullable values, availability/provenance metadata | 13 persistence tests; schema inspection |
| Transactional repository | Atomic session/sample writes, duplicate handling, restart recovery, duplicate-active reconciliation, delete-all | Repository tests |
| Retention | 100 ended sessions, 180 days, 720 samples/session; active sessions retained; pruning flagged honestly | Retention/cap tests |
| Release signing | Dedicated Voltly key outside repo; four GitHub Actions secrets; release build verified with `apksigner` | Certificate SHA-256 and package/version/ABI checks |
| GitHub release | `v0.9.0-preview` pre-release with universal APK, arm64 APK and AAB; `v0.6.0` retained | Uploaded asset download, signature, size and hash verification |
| Static checks | Format, analyze clean | `dart format`, `flutter analyze` |
| Native telemetry adapter | 8 metrics, per-metric availability, no polling | Kotlin tests; debug APK build |
| Native unit conversions | mV→V, tenths °C→°C, µA→A, µAh→mAh, sentinel handling | 13 Kotlin tests |
| Dart telemetry contract | Strict parsing, zero-vs-unavailable, schema rejection | 16 Dart tests |
| Calculated power | Battery-side watts with 2 s input skew rule | 7 Dart tests |
| Channel client | MethodChannel snapshot, EventChannel stream, cancel handling | 6 Dart tests |
| Riverpod state | `TelemetryController` owns one app-scoped subscription; explicit retry | Dashboard, diagnostics, lifecycle and history tests |
| Diagnostics UI | Live values, availability/reason, provenance, timestamps, stale/error/loading states | Widget tests + emulator UI hierarchy |
| End-to-end telemetry | Dashboard matched `dumpsys`; live simulated update to 42%/Charging/AC; session persisted and shown in history | Pixel 10a AVD, Android 17 |
| Automated tests | 135 Dart + 13 Kotlin | `flutter test` 135/135; Gradle 13/13 |
| Android builds | Debug/release at 0.9.0; universal 51.5 MB, arm64 17.8 MB; production-signed SQLite bundles | Builds; `apksigner`; APK metadata; emulator |
| AAB | Production-signed 51.1 MB Google Play bundle, published with the preview release; not uploaded to a store | `flutter build appbundle --release`; `jarsigner`; SHA-256 |

**Deliberately absent:** alerts, settings, health/capacity estimates and a light
theme. Phase 4 time estimates are implemented; capacity/health, alerts and
settings remain. The dashboard and session screens show only real telemetry and
stored samples, explicit unavailable states, and calculated/estimated values
labeled as such.

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
        ↓
active session + retained samples → BatteryTimeEstimator → estimate card
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
- `lib/core/sessions/battery_time_estimate.dart` is the pure estimator. It uses
  the latest 30-minute retained window, requires at least three samples, 10
  minutes of coverage, a latest sample no older than five minutes, no gap over
  five minutes, available levels/states and a consistent direction, and withholds
  projections over 24 hours. `estimate_presentation.dart` formats the approximate
  result, coverage notes and semantics.
- `lib/features/sessions/session_estimate_card.dart` shows the active-session
  estimate or its explicit unavailable reason. The dashboard hosts the card; no
  completed session shows a time estimate.
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
- `docs/estimates.md` documents the estimate evidence rules, formula, unavailable
  reasons, pruning/gap semantics and limits.
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
flutter build appbundle --release
```

Last known results: format clean, analyze clean, 135/135 Dart tests passed,
13/13 Kotlin tests passed, signed debug/release builds succeeded at version
0.9.0. Universal release is 51.5 MB; arm64 is 17.8 MB; the AAB is 51.1 MB; all
are production-signed and the APKs have no `INTERNET` permission. The
`v0.9.0-preview` pre-release published all three assets, and each was downloaded
again and signature/hash verified. On the Pixel 10a AVD (Android 17), simulated
charging produced live dashboard values, a stored active session and a
session-detail screen with gap-aware battery trend semantics (3 stored samples,
2 sampling breaks). The active session also showed the time estimate card
withheld with its explicit reason and semantics ("Battery time estimate
unavailable."); a calculated estimate requires 10 minutes of observations and is
covered by automated tests. TalkBack was enabled on the AVD; TTS synthesis
requests and the expected semantics labels were observed, but human audio review
is still pending. The dashboard also matched `dumpsys battery` earlier at 100%,
"Not charging", 5.00 V, 25.0 °C, 10.0 mAh and 4.50 W calculated. The arm64 APK
cannot install on this x86_64 emulator.

## Known issues and limitations

- Physical-device telemetry validation is still pending. Emulator values prove
  the channel, parsing and UI pipeline, not hardware-specific sign, units or
  capability behavior.
- The emulator reports 0.900 A while unplugged and "Not charging"; Voltly shows
  that device-reported value faithfully. The emulator's battery model is not a
  reference for hardware current semantics.
- Lifecycle pause/resume, the reduce-motion-aware charging pulse and semantics
  labels are implemented and automated-tested. TalkBack was enabled on the API
  37 emulator with TTS synthesis and the expected semantics labels observed;
  human audio review and physical-device TalkBack validation remain pending.
- The dashboard is dark-only by design; no light theme is included.
- Live session tracking, history, detail, stored trend charts and active-session
  time estimates are implemented and automated-tested. Alerts, settings,
  health/capacity estimates and other Phase 4 features are not implemented. No
  v2 migration exists; the newer-schema guard is tested.
- Time estimates require a fresh, contiguous recent window and are explicitly
  withheld otherwise. They are one-point projections, not guarantees, charger
  ratings, capacity measurements or battery-health claims. Completed sessions do
  not show an estimate.
- The last published build is `v0.9.0-preview`, a pre-release with live session
  tracking, history, charts, estimates and a signed AAB. Physical-device
  telemetry and human TalkBack validation remain pending, so it is not stable.
- `currentAverage` and `chargeCounter` are unsupported on many devices; the
  contract reports this explicitly and no fallback estimate is invented.
- Riverpod automatic retry is disabled for telemetry. A failed native channel
  shows an explicit error and requires manual Retry.
- Release signing is configured with a dedicated Voltly key outside source
  control and the four GitHub Actions secrets. The key and credentials must be
  backed up; losing them prevents updating an installed release.
- `v0.9.0-preview` is published as a pre-release. Physical-device telemetry and
  human TalkBack validation remain pending, so it is not a stable release.
- The signed AAB (`Voltly-v0.9.0-preview.aab`, 51.1 MB) is published with the
  preview for a future Google Play submission, but it has not been uploaded to a
  store. GitHub Releases still require the two signed APKs from
  `instructions.md` §17.1.
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
- GitHub Release `v0.9.0-preview` was published from tag commit `8eacc32` with
  universal APK, arm64 APK and AAB assets. All three were downloaded again and
  signature/hash verified.
- Live-session/history commit `3dc56db` was pushed on 2026-10-22; the remote
  `refs/heads/main` resolved to the same commit, and the working tree was clean
  before this documentation update.
- Session-detail/chart commit `bb2e7bc` was pushed on 2026-10-22; the remote
  `refs/heads/main` resolved to the same commit, and the working tree was clean
  before this documentation update.
- Phase 4 estimate-feature commit `b54f0fd` was pushed on 2026-10-22; the remote
  `refs/heads/main` resolved to the same commit before this documentation
  update. It includes the estimator, provider, dashboard card, tests, version
  bump and `docs/estimates.md`.
- Phase 4 estimate-docs commit `4a11d09` was pushed after it; the remote
  `refs/heads/main` resolved to the same commit.
- Phase 4 stale-estimate fix `7ea7f50` was pushed on 2026-10-22; it adds one-shot
  invalidation at the five-minute freshness boundary and updates the build
  hashes in the documentation. The remote tip matched the local tip before this
  documentation update.
- Preview-release workflow commit `b186a8a` added `-preview` tag support, AAB
  build/signing verification and AAB publication. The first tag run failed before
  publication because `android/gradlew` was ignored by Git.
- Build commit `8eacc32` tracked the Gradle wrapper scripts/JAR. Annotated tag
  `v0.9.0-preview` points at `8eacc32`; the rerun published the GitHub
  pre-release with universal APK, arm64 APK and AAB assets. All three were
  downloaded again and verified.
- Verify the current tip with `git status -sb` and
  `git ls-remote --heads origin main`.
- `plan.md` and `instructions.md` are preserved at the root unchanged.

## Next task

**Phase 4 (increment 1) — evidence-based time-to-full/empty estimates: complete.**

Delivered: pure estimator with a documented 10–30-minute retained window, strict
freshness/gap/state/level/direction rules, explicit unavailable reasons, a
dashboard card with approximate/calculated copy, coverage and assumptions, and
screen-reader/2× text coverage. See `docs/estimates.md`. Automated verification:
135 Dart tests + 13 Kotlin tests; APKs and AAB published in the
`v0.9.0-preview` pre-release.

Phase 4 increment 2 has not started. The plan order places battery
health/capacity evidence before alerts and settings; any next increment must keep
the same rule that missing evidence is explained, never invented. The remaining
release gates are physical-device telemetry validation and human TalkBack
validation; both require hardware/human review rather than emulator automation.
