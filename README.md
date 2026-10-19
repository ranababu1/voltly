# Voltly

**Know your battery.** Battery intelligence, beautifully simple.

Voltly is an Android-first battery-monitoring and charging-analytics app. It
presents device-reported telemetry honestly, keeps history on the device, and
never substitutes guessed or demo values for real readings.

> **Status: Phase 2 — Dashboard (implemented).**
> The dashboard renders live device telemetry with accessible semantics,
> explicit availability/provenance/stale/error states, calculated battery-side
> power, a reduce-motion-aware charging pulse, and background pause/resume of
> acquisition. Physical-device and manual screen-reader validation remain
> pending.

## Scope

- Android 8.0+ (API 26), phone-first. No iOS target.
- Local-first and offline. No accounts, backend, ads or analytics SDKs.
- Dark-only, AMOLED-friendly surfaces with restrained mint accents.
- Live telemetry, charging sessions, charts, estimates and alerts are planned
  in later milestones. See `plan.md` for the authoritative scope.

## Toolchain

Versions the current build was verified with:

| Component | Version |
| --- | --- |
| Flutter | 3.47.7 (stable) |
| Dart | 3.13.5 |
| flutter_riverpod | 3.4.3 |
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

## Verification

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
cd android
.\gradlew.bat :app:testDebugUnitTest
cd ..
flutter build apk --debug
```

Last recorded results (2026-10-20, Phase 2 complete):

- `flutter analyze` — no issues.
- `flutter test` — 49/49 passed (16 contract parsing, 7 power, 6 channel,
  6 diagnostics, 9 dashboard, 2 lifecycle provider, 1 motion, 2 app/lifecycle).
- `.\gradlew.bat :app:testDebugUnitTest` — 13/13 Kotlin tests passed.
- `flutter build apk --debug` — succeeded.
- `flutter build apk --release` — succeeded (43.5 MB, signed with the debug
  certificate; not distributable).
- Debug APK installed and cold-launched on a Pixel 10a AVD (Android 17).
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
  features/
    dashboard/
      dashboard_screen.dart         Telemetry-driven dashboard
      telemetry_diagnostics_screen.dart  Real-service diagnostics UI
      telemetry_presentation.dart   Shared formatting, badges and freshness
test/
  core/telemetry/                   Contract, power, channel and lifecycle tests
  features/dashboard/               Dashboard, diagnostics, motion and semantics
  support/                          Fixtures, fake service and app pump helper
  widget_test.dart                  App root, theme and lifecycle smoke tests
android/app/src/main/kotlin/com/voltly/
  MainActivity.kt                   Registers the telemetry channels
  telemetry/                        Reader, conversions and channel host
docs/
  telemetry-contract.md             Versioned Android-to-Dart contract
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
- **Motion:** a small charging pulse runs only for the reported charging state
  and is disabled when the platform requests reduced motion. The adjacent text
  carries the meaning; motion is decorative.
- **Accessibility:** battery level, charging state/source, each metric card and
  calculated power expose concise screen-reader labels. Layout is validated at
  320×640 with 2× text; status is never communicated by color alone.
- **Presentation:** dashboard and diagnostics share one formatting, badge and
  freshness layer so status language cannot drift between screens.
- **Persistence:** Drift/SQLite is planned for session history, with explicit,
  tested schema migrations. No database exists yet.
- **Charts and estimates:** deferred until real captured data exists. Estimates
  will be labeled and withheld when evidence is insufficient.

## Privacy and permissions

- No application code performs network requests, and no third-party analytics,
  ads or tracking SDKs are included.
- Battery telemetry uses `ACTION_BATTERY_CHANGED` and `BatteryManager`, which
  require no runtime permission. Readings are in-memory only and are not
  persisted or transmitted.
- The release manifest requests **no** runtime permissions and no `INTERNET`
  permission. Debug and profile builds include Flutter's development-only
  `INTERNET` permission for hot reload and debugging.
- No local database or telemetry export exists yet. `.gitignore` excludes
  databases, exports, signing material, environment files and logs.
- A privacy policy is not yet written; it must reflect implemented behavior
  before any store submission.

## Versioning

`pubspec.yaml` uses semantic-style `MAJOR.MINOR.PATCH+BUILD`. The project is
pre-1.0 during development (`0.4.0+4` now). Build numbers increment for each
distributed release candidate. Tag and release conventions are defined in
`instructions.md` §17.

## Documentation

- `plan.md` — authoritative product and engineering blueprint (immutable).
- `instructions.md` — engineering, testing, Git and release rules.
- `docs/telemetry-contract.md` — versioned native/Dart telemetry contract.
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
- Charging sessions, history, charts, alerts and health/capacity estimates are
  not implemented yet (Phase 3+).
- Average current, charge counter and other metrics are unsupported on some
  devices. The contract reports availability per metric; this is not a bug.
- Release builds are currently signed with the Android debug certificate.
  Approved release signing credentials must be configured outside source
  control before any distribution.
- No release or GitHub Release has been created; the required universal and
  arm64 release APKs belong to a future approved release milestone.
