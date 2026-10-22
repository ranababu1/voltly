# Changelog

Newest-first record of meaningful implementation changes.

## 2026-10-22 — Phase 4 increment 1: evidence-based time estimates

**Milestone:** Phase 4 — Estimates (increment 1 complete)

**Summary**

- Added a pure `BatteryTimeEstimator` that projects time to full/empty from the
  most recent 30 minutes of retained samples. It requires at least three
  samples, 10 minutes of coverage, a latest sample no older than five minutes,
  no gap over five minutes, available levels and charging states throughout the
  window, and a level change in the expected direction.
- Added explicit unavailable results for insufficient samples/coverage, stale
  data, gaps, changed or unavailable state, unavailable levels, pruning that
  leaves too few samples, completed/inactive sessions, full/not-charging states,
  contradictory direction, and projections over 24 hours. No branch substitutes
  zero, charger power, capacity or battery health.
- Added an active-session estimate provider and dashboard card. The card shows
  "Time to full" or "Time to empty", an "Estimated" badge, a five-minute-rounded
  approximate duration, sample/window coverage, steady-rate assumption, pruning
  or earlier-gap notes, and a statement that this is not charger input power,
  capacity or battery health. When evidence is inadequate it shows the reason
  instead of a number. A one-shot invalidation withholds an already-visible
  estimate as soon as its latest sample crosses the five-minute freshness limit.
- Added 16 estimator tests, 6 estimate-card tests and 2 provider tests covering
  valid charging/discharging, target reached, short windows, gaps, unavailable
  levels/states, stale samples, inactive sessions, noisy/contradictory levels,
  pruning, the 24-hour cap, semantics and 2× text.
- Added `docs/estimates.md` documenting the evidence rules, formula, unavailable
  reasons, pruning/gap semantics and limits.
- Bumped the development version to `0.9.0+9`.

**Key files**

- `lib/core/sessions/battery_time_estimate.dart`
- `lib/core/sessions/estimate_presentation.dart`
- `lib/core/sessions/session_providers.dart`
- `lib/features/sessions/session_estimate_card.dart`
- `lib/features/dashboard/dashboard_screen.dart`
- `test/core/sessions/battery_time_estimate_test.dart`
- `test/features/sessions/session_estimate_card_test.dart`
- `docs/estimates.md`

**Verification**

- `dart format lib test` — clean.
- `flutter analyze` — no issues.
- `flutter test` — 135/135 passed.
- `.\gradlew.bat :app:testDebugUnitTest --rerun-tasks` — 13/13 Kotlin tests
  passed; native code unchanged.
- `flutter build apk --debug` — succeeded at `0.9.0+9`.
- `flutter build apk --release` — succeeded; universal 51.5 MB,
  production-signed.
- `flutter build apk --release --split-per-abi --target-platform android-arm64`
  — succeeded; arm64 17.8 MB, production-signed.
- Universal `0.9.0` installed on the Pixel 10a AVD. The active session showed the
  estimate card withheld with "at least 3 stored samples are needed; 2
  available" and semantics "Battery time estimate unavailable." A calculated
  estimate requires 10 minutes of observations and is covered by automated
  tests; the smoke test did not wait for that window.
- Both release APKs verified with the Voltly production certificate; no
  `INTERNET` permission.

**Known limitations**

- Physical-device telemetry and manual TalkBack validation remain pending.
- Estimates are one-point recent projections, not guarantees, charger ratings,
  capacity measurements or battery-health claims. Completed sessions do not show
  an estimate.
- Alerts, settings and health/capacity estimates are not implemented.
- The published GitHub Release `v0.6.0` predates sessions, history, charts and
  estimates; `0.9.0+9` is not published. No AAB is built.

## 2026-10-22 — Phase 3 complete: session detail and stored trend charts

**Milestone:** Phase 3 — Charging Sessions (implementation complete)

**Summary**

- Added a session-detail route from each history card, with loading, not-found,
  empty-sample and storage-error states.
- Added `sessionDetailProvider` to load one stored session and its retained
  samples through the repository.
- Added stored summary fields (state, dates, start/end levels, change, duration,
  sample count) without fabricating unavailable values.
- Added level, current, temperature and calculated battery-side power charts
  drawn from retained samples only.
- Added pure gap segmentation: missing values and intervals over five minutes
  break the line; values are never interpolated. Pruned history is labelled and
  charts cover only retained samples.
- Added chart summaries and screen-reader labels describing sample count, latest
  value, range, breaks and unavailable samples.
- Added 6 chart-data tests, 7 detail-screen tests, a history-to-detail navigation
  test and a detail-provider test, bringing Dart coverage to 111 tests.
- Bumped the development version to `0.8.0+8`.

**Key files**

- `lib/core/sessions/session_detail.dart`
- `lib/core/sessions/session_chart_data.dart`
- `lib/core/sessions/session_providers.dart`
- `lib/features/sessions/session_detail_screen.dart`
- `lib/features/sessions/session_trend_chart.dart`
- `test/core/sessions/session_chart_data_test.dart`
- `test/features/sessions/session_detail_screen_test.dart`

**Verification**

- `dart format lib test` — clean.
- `flutter analyze` — no issues.
- `flutter test` — 111/111 passed.
- `.\gradlew.bat :app:testDebugUnitTest --rerun-tasks` — 13/13 Kotlin tests
  passed; native code unchanged.
- `flutter build apk --debug` and `--release` — succeeded at `0.8.0+8`;
  universal release 51.5 MB, production-signed.
- `flutter build apk --release --split-per-abi --target-platform android-arm64`
  — succeeded; arm64 release 17.8 MB, production-signed.
- Universal `0.8.0` installed on the Pixel 10a AVD. The stored active session
  opened in Session detail and exposed a gap-aware battery trend summary
  (3 samples, 2 sampling breaks). arm64 was signature/ABI-checked but cannot
  install on the x86_64 emulator.

**Known limitations**

- Physical-device telemetry and manual TalkBack validation remain pending.
- Alerts, settings, health/capacity estimates and time-to-full/empty estimates
  are not implemented.
- The published GitHub Release `v0.6.0` predates session history and charts;
  `0.8.0+8` is not published.
- No AAB is built.

## 2026-10-22 — Phase 3 (in progress): live session persistence and history

**Milestone:** Phase 3 — Charging Sessions

**Summary**

- Made telemetry app-scoped and started an app-scoped Drift/SQLite database and
  repository at the root. The database opens lazily and closes with the provider
  scope; screens cannot create their own database.
- Added `SessionCoordinator`, which serializes real snapshots through
  `ChargingSessionTracker`, persists started/sample/ended updates with the active
  session id, restores the active session at launch, and keeps it open across
  foreground pauses so the next observation records the gap.
- Added session tracking providers. Storage failures pause tracking, invalidate
  history, and surface a dashboard Retry banner instead of crashing or silently
  dropping data. Retry reloads the last committed active session.
- Added a Charging sessions screen linked from the dashboard. It lists active,
  completed and interrupted sessions with start/end levels, duration, sample
  count, telemetry-gap, partial-session and retention-pruned labels. It never
  presents background time as continuous coverage.
- Added a shared session presentation layer for honest labels, durations,
  level changes and screen-reader summaries. History is overflow-tested at
  320×640 with 2× text.
- Added 18 tests (6 coordinator, 4 session providers, 6 history UI, 2 dashboard
  integration), bringing Dart coverage to 96 tests.
- Bumped the development version to `0.7.0+7`.

**Key files**

- `lib/core/persistence/session_store.dart`
- `lib/core/persistence/persistence_providers.dart`
- `lib/core/sessions/session_coordinator.dart`
- `lib/core/sessions/session_providers.dart`
- `lib/core/sessions/session_presentation.dart`
- `lib/features/sessions/session_history_screen.dart`
- `lib/features/sessions/session_widgets.dart`
- `test/core/sessions/session_coordinator_test.dart`
- `test/core/sessions/session_providers_test.dart`
- `test/features/sessions/session_history_screen_test.dart`

**Verification**

- `dart format lib test` — clean.
- `flutter analyze` — no issues.
- `flutter test` — 96/96 passed.
- `.\gradlew.bat :app:testDebugUnitTest --rerun-tasks` — 13/13 Kotlin tests
  passed; native code unchanged.
- `flutter build apk --debug` and `flutter build apk --release` — succeeded at
  `0.7.0+7`; universal release 51.2 MB, production-signed.
- `flutter build apk --release --split-per-abi --target-platform android-arm64`
  — succeeded; arm64 release 17.8 MB, production-signed.
- Universal `0.7.0` installed on the Pixel 10a AVD. With simulated
  `level 42`, `status 2`, `ac 1`, the dashboard showed live values and Charging
  sessions showed a real active session (`Recording`, start 42%, one sample).
- arm64 was signature/ABI-checked but cannot install on the x86_64 emulator.

**Known limitations**

- Session detail screens and trend charts are not implemented.
- The last published GitHub Release `v0.6.0` predates live session history;
  `0.7.0+7` is not published.
- Physical-device telemetry and manual TalkBack validation remain pending.
- No AAB is built.

## 2026-10-20 — v0.6.0 signed preview release

**Milestone:** Phase 3 — Charging Sessions (preview release)

**Summary**

- Configured production release signing from `android/key.properties` with the
  keystore and passwords kept outside version control. Added the corresponding
  four GitHub Actions secrets.
- Built signed **universal** and **arm64-v8a** release APKs from version
  `0.6.0+6`.
- Published GitHub Release `v0.6.0` as a **pre-release** because session history
  UI and physical-device validation are still pending.
- Release assets:
  - `Voltly-v0.6.0-universal.apk` — 48.9 MB, versionCode 6
  - `Voltly-v0.6.0-arm64-v8a.apk` — 17.0 MB, versionCode 2006
- Signing certificate: `CN=Voltly Release, O=Voltly, C=US`, SHA-256
  `54:3D:C7:A8:C3:D4:E3:3D:63:E8:18:0F:09:1F:2A:BD:07:9D:10:2D:3E:32:E8:71:50:38:8F:04:FE:34:D6:41`.
- Asset SHA-256:
  - Universal: `C24C0B647504F42695E2376A64FBCBBC3F115BDE21DAFF1085EBF84F4BB2FC97`
  - arm64: `AD2DACF4A90773E9DAEC564A5806AFF465D746D5FB110F73246150BE644627E6`
- Added `docs/release.md` documenting signing, naming, verification and safety.
- Added a tag-triggered GitHub Actions workflow for future releases. It builds,
  tests, signs, verifies and publishes both APKs; `v0.6.0` itself was published
  manually.

**Verification**

- `flutter analyze` — no issues; `flutter test` — 78/78 passed.
- `.\gradlew.bat :app:testDebugUnitTest --rerun-tasks` — 13/13 passed.
- `apksigner verify --print-certs` confirmed the production certificate on both
  APKs; universal reports package `com.voltly`, versionName `0.6.0`,
  versionCode `6`, ABIs arm64-v8a/armeabi-v7a/x86_64; arm64 reports only
  arm64-v8a.
- Universal APK installed and cold-launched on the Pixel 10a AVD (Android 17);
  dashboard showed live values. arm64 could not be installed on the x86_64
  emulator.
- GitHub Release upload verified; assets downloaded again and hashes checked.

**Known limitations**

- Pre-release only: session history/detail UI and charts are not implemented.
- Physical-device telemetry and manual TalkBack validation remain pending.
- The signing keystore and credentials must be backed up outside the repository.
- No AAB is built.

## 2026-10-20 — Phase 3 (in progress): Drift schema v1 and session repository

**Milestone:** Phase 3 — Charging Sessions

**Summary**

- Added Drift 2.35.2 with SQLite 3.5.2 native assets. Removed the obsolete
  `sqlite3_flutter_libs` package; SQLite is now bundled through Dart hooks.
- Added schema v1 with `charging_sessions` and `telemetry_samples`. Session rows
  preserve lifecycle state, nullable levels, last observation, sample count,
  gap metadata and a distinct `samples_pruned` flag. Sample rows preserve every
  stored metric, plug source, calculated power, contract version and JSON
  availability/provenance metadata.
- Added four indexes: recent/retention ordering, active lookup, ordered sample
  retrieval plus duplicate protection (unique), and sample-time maintenance.
  Foreign keys are enabled per connection and session deletion cascades to
  samples. Level range and non-negative-count checks are enforced in SQLite.
- Added a transactional repository that inserts a session with its first sample,
  updates summaries with subsequent samples, ignores duplicate sample timestamps,
  rolls back missing-session writes, recovers the active session after restart,
  reconciles duplicate active rows, enforces retention and supports delete-all.
- Retention defaults: 100 ended sessions, 180 days, 720 samples per session.
  Active sessions are exempt from age/count bounds but their sample rows are
  capped. Pruning marks `samples_pruned` without pretending a telemetry gap
  occurred.
- Added a stored-row mapper that rebuilds typed samples and renders missing or
  malformed metadata as invalid readings rather than inventing values.
- Added 13 persistence tests covering schema/index/foreign-key creation,
  round-trip sample mapping, transactions and rollback, unavailable metrics,
  duplicate samples, duplicate active recovery, file-backed restart, retention
  by count and age, sample pruning, delete-all and newer-schema rejection.
- Documented the schema and retention policy in `docs/persistence.md`.
- Bumped the version to `0.6.0+6`.

**Key files**

- `lib/core/persistence/app_database.dart` and generated `app_database.g.dart`
- `lib/core/persistence/tables.dart`
- `lib/core/persistence/session_repository.dart`
- `lib/core/persistence/session_retention_policy.dart`
- `lib/core/persistence/sample_metadata.dart`
- `lib/core/persistence/sample_mapper.dart`
- `test/core/persistence/session_repository_test.dart`
- `docs/persistence.md`

**Verification**

- `dart format lib test` — clean.
- `flutter analyze` — no issues.
- `flutter test` — 78/78 passed (65 existing + 13 persistence).
- `.\gradlew.bat :app:testDebugUnitTest --rerun-tasks` — 13/13 Kotlin tests
  passed; native code was unchanged.
- `flutter build apk --debug` — succeeded at `0.6.0+6`.
- `flutter build apk --release` — succeeded (48.9 MB, debug certificate; not
  distributable). APK contains `libsqlite3.so` for arm64-v8a, armeabi-v7a and
  x86_64, and no `INTERNET` permission.
- File-backed persistence was closed and reopened in tests; stored sessions and
  samples survived, and a database with `user_version = 2` was rejected.

**Known limitations**

- The tracker and repository are not yet wired to live acquisition or UI. The
  running app does not create a production database file yet.
- Session list/detail views and charts are not implemented.
- No v2 migration exists yet; the newer-schema guard is tested, but future
  upgrades must add explicit migrations.
- The planned `app_settings` table is deferred until settings exist.
- Physical-device telemetry and manual TalkBack validation remain pending.
- Release signing, AAB generation, split-ABI artifacts and GitHub Releases
  remain outstanding.

## 2026-10-20 — Phase 3 (in progress): charging-session domain and tracker

**Milestone:** Phase 3 — Charging Sessions

**Summary**

- Added normalized `ChargingSession` and `TelemetrySample` domain models.
  Sessions carry start/end/last-observed timestamps, nullable levels, lifecycle
  state, sample count and explicit sampling-gap metadata. Samples retain the
  original snapshot, so availability, provenance and timestamps are preserved.
- Added a pure `ChargingSessionTracker` state machine that consumes real
  telemetry snapshots and emits `started`, `sample` and `ended` updates without
  performing I/O.
- Session rules: charging starts a session; full or discharging completes it; a
  persistent `not_charging` state ends it as interrupted after a two-minute
  grace period; inter-sample gaps over five minutes mark the session partial.
  A brief charging pause resumes the same session, and the restore path
  continues an active session after restart while recording the gap.
- Duplicate and out-of-order observation timestamps are ignored. Unavailable
  levels remain null, unavailable charging state does not force an end, and no
  zero or placeholder reading is fabricated.
- Added 14 tracker tests and 2 sample-mapping tests covering start/continue,
  full/discharging completion, short and persistent `not_charging`, duplicates,
  sampling gaps, unavailable state and level, restart recovery and invalid
  restore.
- Bumped the version to `0.5.0+5`.

**Key files**

- `lib/core/sessions/charging_session.dart`
- `lib/core/sessions/charging_session_tracker.dart`
- `lib/core/sessions/telemetry_sample.dart`
- `test/core/sessions/charging_session_tracker_test.dart`
- `test/core/sessions/telemetry_sample_test.dart`
- `test/support/session_fixtures.dart`

**Verification**

- `dart format lib test` — clean.
- `flutter analyze` — no issues.
- `flutter test` — 65/65 passed (49 existing + 16 new).
- `.\gradlew.bat :app:testDebugUnitTest` — 13/13 Kotlin tests passed from the
  last native change; no Kotlin code changed in this slice.
- `flutter build apk --debug` — succeeded at `0.5.0+5`.
- `flutter build apk --release` — succeeded (43.5 MB, debug certificate; not
  distributable).

**Known limitations**

- Sessions are produced in memory only. Drift/SQLite persistence, retention and
  history UI are not implemented yet.
- The tracker is not yet wired to `TelemetryController` or any screen.
- Physical-device telemetry and manual TalkBack validation remain pending.
- Release signing, AAB generation, split-ABI artifacts and GitHub Releases
  remain outstanding.

## 2026-10-20 — Phase 2 complete: lifecycle, motion and accessibility

**Milestone:** Phase 2 — Dashboard and Visual System

**Summary**

- Replaced the stream-provider wiring with a single `TelemetryController`
  notifier that owns one service subscription, cancels it explicitly when the
  app leaves the foreground, retains the last snapshot and resubscribes on
  resume. Automatic retry remains disabled; Retry is explicit.
- Added app lifecycle observation at the root (`ConsumerStatefulWidget` +
  `WidgetsBindingObserver`). Inactive/paused/hidden states stop acquisition;
  `resumed` restarts it without polling or losing the last observation.
- Added `ChargingPulse`, a restrained charging-state icon animation that runs
  only while the reported state is charging and stops when Android requests
  reduced motion.
- Added concise semantics labels for battery level, charging state and power
  source, each metric card and calculated power. The decorative progress bar is
  excluded from semantics; status never relies on color alone.
- Reworked the test fake into explicit per-listener stream controllers so
  subscription and cancellation behavior is deterministic.
- Added lifecycle provider tests, app lifecycle integration coverage, motion
  tests and a screen-reader semantics test.
- Bumped the version to `0.4.0+4`.

**Verification**

- `dart format --output=none --set-exit-if-changed lib test` — exit 0.
- `flutter analyze` — no issues.
- `flutter test` — 49/49 passed (16 contract, 7 power, 6 channel,
  6 diagnostics, 9 dashboard, 2 lifecycle provider, 1 motion,
  2 app/lifecycle).
- `.\gradlew.bat :app:testDebugUnitTest` — 13/13 Kotlin tests passed.
- `flutter build apk --debug` — succeeded.
- `flutter build apk --release` — succeeded (43.5 MB, debug certificate; not
  distributable).
- APKs report versionName `0.4.0`, versionCode `4`, minSdk `26`, compile/target
  SDK `36`. Release manifest has no `INTERNET` permission.
- Pixel 10a AVD (Android 17): dashboard values matched `dumpsys battery`;
  simulated `level 42`, `status 2` and `ac 1` updated the live screen to 42%,
  "Charging" and "AC" without restart. Home then resume produced a HOT return
  with fresh values. No `AndroidRuntime` errors.
- `uiautomator dump` confirmed labels such as "Battery level 42 percent" and
  "Voltage, 5.00 volts, Available, Device".

**Known limitations**

- Physical-device telemetry and manual TalkBack/screen-reader validation are
  still pending.
- The emulator reports 0.900 A while unplugged; it is shown faithfully and does
  not validate hardware current semantics.
- The dashboard is dark-only; no light theme is included.
- Charging sessions, history, charts, alerts and estimates remain Phase 3+.
- Release signing, AAB generation and GitHub Release APK artifacts remain
  outstanding for an approved release.

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
