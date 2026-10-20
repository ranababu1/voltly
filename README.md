# Voltly

**Know your battery.** Battery intelligence, beautifully simple.

Voltly is an Android-first battery-monitoring and charging-analytics app. It
presents device-reported telemetry honestly, keeps history on the device, and
never substitutes guessed or demo values for real readings.

> **Status: Phase 3 (in progress) — session persistence foundation.**
> The dashboard renders live device telemetry with accessible semantics,
> explicit availability/provenance/stale/error states, calculated battery-side
> power, a reduce-motion-aware charging pulse, and background pause/resume of
> acquisition. A pure charging-session state machine classifies real telemetry,
> and a transactional Drift/SQLite layer now persists sessions and samples with
> schema v1, recovery and bounded retention. Live wiring and session history UI
> are the next increment. Physical-device and manual screen-reader validation
> remain pending.
>
> **First signed preview:** `v0.6.0` is published with universal and
> `arm64-v8a` APKs. It is marked as a pre-release because session history UI and
> physical-device validation are still pending.

## Scope

- Android 8.0+ (API 26), phone-first. No iOS target.
- Local-first and offline. No accounts, backend, ads or analytics SDKs.
- Dark-only, AMOLED-friendly surfaces with restrained mint accents.
- Live telemetry and local charging-session persistence are implemented. Session
  history UI, charts, estimates and alerts are planned in later milestones. See
  `plan.md` for the authoritative scope.

## Toolchain

Versions the current build was verified with:

| Component | Version |
| --- | --- |
| Flutter | 3.47.7 (stable) |
| Dart | 3.13.5 |
| flutter_riverpod | 3.4.3 |
| drift | 2.35.2 |
| sqlite3 | 3.5.2 (bundled native assets) |
| path_provider | 2.1.6 |
| drift_dev / build_runner | 2.35.1 / 2.16.2 (development only) |
| JDK | Amazon Corretto 21.0.12 |
| Gradle wrapper | 9.3.1 |
| Android Gradle Plugin | 9.1.0 |
| Kotlin | 2.4.0 |
| JUnit (native tests) | 4.13.2 |
| Android SDK (installed) | 37.0.0, platform android-37.1 |
| compileSdk / targetSdk | 36 / 36 |
| minSdk | 26 (pinned in `android/app/build.gradle.kts`) |
| Application ID | `com.voltly` |

## Getting started

Prerequisites: Flutter 3.47.x, JDK 21, Android SDK with platform 36, and an
Android device or emulator running API 26+.

```powershell
flutter pub get
flutter run
```

## Releases

- **v0.6.0 (pre-release):** `Voltly-v0.6.0-universal.apk` and
  `Voltly-v0.6.0-arm64-v8a.apk`.
  [GitHub Release](https://github.com/ranababu1/voltly/releases/tag/v0.6.0)

Release assets are signed with the Voltly production key. See
`docs/release.md` for signing, verification and publication rules.

## Verification

```powershell
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
cd android
.\gradlew.bat :app:testDebugUnitTest
cd ..
flutter build apk --debug
```

Last recorded results (2026-10-20, Phase 3 persistence slice):

- `flutter analyze` — no issues.
- `flutter test` — 78/78 passed (16 contract parsing, 7 power, 6 channel,
  6 diagnostics, 9 dashboard, 2 lifecycle provider, 1 motion, 2 app/lifecycle,
  14 session tracker, 2 session sample, 13 persistence).
- `.\gradlew.bat :app:testDebugUnitTest` — 13/13 Kotlin tests passed with `--rerun-tasks` (native code
  unchanged in this slice).
- `flutter build apk --debug` — succeeded at version `0.6.0+6`.
- `flutter build apk --release` — succeeded (48.9 MB, signed with the debug
  certificate; not distributable). Includes `libsqlite3.so` for arm64-v8a,
  armeabi-v7a and x86_64, and no `INTERNET` permission.
- Persistence tests cover schema/index creation, transaction rollback,
  unavailable-value mapping, duplicate samples, duplicate active recovery,
  file-backed restart, retention bounds, sample pruning, delete-all and
  newer-schema rejection.
- Release APKs are signed with `CN=Voltly Release, O=Voltly, C=US`; SHA-256
  `54:3D:C7:A8:C3:D4:E3:3D:63:E8:18:0F:09:1F:2A:BD:07:9D:10:2D:3E:32:E8:71:50:38:8F:04:FE:34:D6:41`.
  Universal is 48.9 MB; arm64 is 17.0 MB.
- The universal signed APK was installed on the Pixel 10a AVD, cold-launched as
  version `0.6.0`, and showed live dashboard values. The arm64 APK was built,
  signature-checked and ABI-checked, but cannot be installed on the x86_64
  emulator.
- The Phase 2 emulator validation remains the last on-device UI validation.
  Debug APK was installed and cold-launched on a Pixel 10a AVD (Android 17).
  Dashboard values matched `adb shell dumpsys battery`: 100%, "Not charging",
  5.00 V, 25.0 °C, 10.0 mAh and 4.50 W calculated.
- Live update test: simulated `level 42`, `status 2` and `ac 1` via
  `dumpsys battery`; the running dashboard updated to 42%, "Charging" and
  "Power source: AC" without a restart.
- Background test: pressing Home then returning produced a HOT resume with
  fresh values and no Android runtime errors.
- `uiautomator dump` confirmed concise semantics labels such as
  "Battery level 42 percent" and "Voltage, 5.00 volts, Available, Device".
- Physical-device and manual screen-reader validation remain pending.

## Project structure

```text
lib/
  main.dart                         App entry point and system UI style
  app/
    app.dart                        MaterialApp root
    theme/
      app_colors.dart               Color tokens
      app_tokens.dart               Spacing and radius tokens
      app_typography.dart           Type scale
      app_theme.dart                Material 3 dark theme
  core/
    errors/
      telemetry_exception.dart      Payload-level contract errors
    telemetry/
      telemetry_models.dart         Typed snapshot and availability model
      battery_telemetry_service.dart Platform-channel client
      telemetry_providers.dart      Riverpod service and autoDispose stream
      battery_power.dart            Calculated battery-side power
    sessions/
      charging_session.dart         Session lifecycle and coverage metadata
      charging_session_tracker.dart Pure telemetry-to-session state machine
      telemetry_sample.dart         Snapshot captured within a session
    persistence/
      app_database.dart             Drift schema v1, migrations and file opener
      tables.dart                   Session/sample columns and indexes
      session_repository.dart       Transactional writes, recovery and retention
      session_retention_policy.dart Bounded-history defaults
      sample_metadata.dart          Availability/provenance JSON encoding
      sample_mapper.dart            Stored row to domain sample
  features/
    dashboard/
      dashboard_screen.dart         Telemetry-driven dashboard
      telemetry_diagnostics_screen.dart  Real-service diagnostics UI
      telemetry_presentation.dart   Shared formatting, badges and freshness
test/
  core/telemetry/                   Contract, power, channel and lifecycle tests
  core/sessions/                    Session tracker and sample mapping tests
  core/persistence/                 Schema, repository, recovery and retention tests
  features/dashboard/               Dashboard, diagnostics, motion and semantics
  support/                          Fixtures, fake service and app pump helper
  widget_test.dart                  App root, theme and lifecycle smoke tests
android/app/src/main/kotlin/com/voltly/
  MainActivity.kt                   Registers the telemetry channels
  telemetry/                        Reader, conversions and channel host
docs/
  telemetry-contract.md             Versioned Android-to-Dart contract
  persistence.md                    Schema v1, recovery and retention policy
```

Feature directories are added only when a milestone needs them.

## Architecture decisions

- **State management:** Riverpod (`flutter_riverpod` 3.4.3). One
  `TelemetryController` notifier owns the single service subscription and is
  shared by the dashboard and diagnostics. It is auto-disposed when the last
  screen closes, cancels acquisition when the app leaves the foreground,
  retains the last snapshot, and resubscribes on resume. Automatic provider
  retry is disabled; both screens offer an explicit Retry. No competing state
  pattern is used.
- **Telemetry boundary:** implemented. A single Kotlin reader acquires readings
  from `ACTION_BATTERY_CHANGED` and `BatteryManager`, converts units once and
  publishes a versioned contract through MethodChannel/EventChannel. The Dart
  service is the only client. See `docs/telemetry-contract.md`.
- **Dashboard:** renders live battery level, charging state, power source,
  voltage, temperature, current, average current, charge counter and calculated
  battery-side power. Availability, provenance, observation time and stale
  state are visible; loading and error states replace the content without
  inventing values.
- **Diagnostics:** the developer screen exposes the full contract, per-metric
  timestamps and reasons for validation.
- **Lifecycle and sampling:** the app root observes Android lifecycle changes.
  Inactive/paused states cancel the subscription so the native receiver
  unregisters; resume re-subscribes immediately. The retained observation keeps
  its original timestamp, so staleness remains honest. There is no polling or
  background service.
- **Session domain:** a pure `ChargingSessionTracker` consumes real snapshots and
  emits started/sample/ended updates. Charging starts a session; full or
  discharging completes it; a persistent `not_charging` state becomes an
  interrupted session after a two-minute grace period; inter-sample gaps over
  five minutes mark the session partial. Duplicate/out-of-order timestamps are
  ignored, unavailable levels stay null, and an unavailable charging state does
  not fabricate an end. Restoration from persistence records the restart gap.
- **Motion:** a small charging pulse runs only for the reported charging state
  and is disabled when the platform requests reduced motion. The adjacent text
  carries the meaning; motion is decorative.
- **Accessibility:** battery level, charging state/source, each metric card and
  calculated power expose concise screen-reader labels. Layout is validated at
  320×640 with 2× text; status is never communicated by color alone.
- **Presentation:** dashboard and diagnostics share one formatting, badge and
  freshness layer so status language cannot drift between screens.
- **Persistence:** Drift/SQLite schema v1 and a transactional repository are
  implemented. Session summaries and samples are written atomically, stored
  availability/provenance is preserved, active sessions are recovered after
  restart, and bounded retention plus delete-all are implemented. It is not yet
  wired to live acquisition or UI. See `docs/persistence.md`.
- **Charts and estimates:** deferred until real captured data exists. Estimates
  will be labeled and withheld when evidence is insufficient.

## Privacy and permissions

- No application code performs network requests, and no third-party analytics,
  ads or tracking SDKs are included.
- Battery telemetry uses `ACTION_BATTERY_CHANGED` and `BatteryManager`, which
  require no runtime permission. Readings are processed on-device. The local
  session database layer stores only Voltly session data when integrated and is
  never transmitted.
- The release manifest requests **no** runtime permissions and no `INTERNET`
  permission. Debug and profile builds include Flutter's development-only
  `INTERNET` permission for hot reload and debugging.
- No database file is committed; `.gitignore` excludes databases, WAL/journal
  files, exports, signing material, environment files and logs. Telemetry export
  is not implemented.
- A privacy policy is not yet written; it must reflect implemented behavior
  before any store submission.

## Versioning

`pubspec.yaml` uses semantic-style `MAJOR.MINOR.PATCH+BUILD`. The project is
pre-1.0 during development (`0.6.0+6` now). Build numbers increment for each
distributed release candidate. The first signed preview tag is `v0.6.0`.
Tag and release conventions are defined in `instructions.md` §17.

## Documentation

- `plan.md` — authoritative product and engineering blueprint (immutable).
- `instructions.md` — engineering, testing, Git and release rules.
- `docs/telemetry-contract.md` — versioned native/Dart telemetry contract.
- `docs/persistence.md` — schema v1, transactions, recovery and retention policy.
- `docs/release.md` — signing, APK naming, verification and release safety.
- `changelog.md` — chronological record of meaningful changes.
- `currentstate.md` — factual snapshot, blockers and the next task.

## Known limitations

- Native telemetry is validated on an Android emulator only. Physical-device
  behavior, vendor metric availability, current sign and unit semantics remain
  unverified on hardware.
- The emulator reports 0.900 A while unplugged and "Not charging"; Voltly shows
  that device-reported value faithfully. This validates the pipeline, not the
  hardware sign convention.
- The dashboard core, lifecycle pause/resume, charging pulse and semantics
  labels are implemented. Manual TalkBack/screen-reader validation and
  physical-device testing remain pending.
- The app is dark-only by design; no light theme is included.
- Charging-session classification and persistence exist and are tested, but the
  tracker/repository are not yet wired to live acquisition or shown in the UI.
  No production database file is created by the running app yet.
- Session history UI, charts, alerts and health/capacity estimates remain
  pending (Phase 3+).
- Average current, charge counter and other metrics are unsupported on some
  devices. The contract reports availability per metric; this is not a bug.
- Release signing is configured with a dedicated Voltly key stored outside
  source control. The four signing values are also repository Actions secrets.
  Loss of the key/credentials would prevent updates over an installed release.
- `v0.6.0` is a signed pre-release because session history UI and
  physical-device validation are still pending. A stable release requires the
  remaining release checks.
