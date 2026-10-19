# Voltly

**Know your battery.** Battery intelligence, beautifully simple.

Voltly is an Android-first battery-monitoring and charging-analytics app. It
presents device-reported telemetry honestly, keeps history on the device, and
never substitutes guessed or demo values for real readings.

> **Status: Phase 1 — Native battery telemetry (implemented).**
> The Kotlin adapter, typed Dart contract and real-service diagnostics screen
> are implemented. Live readings and calculated power were validated end-to-end
> on an Android emulator; physical-device hardware validation remains pending.

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

Last recorded results (2026-10-20, Phase 1):

- `flutter analyze` — no issues.
- `flutter test` — 39/39 passed (16 contract parsing, 7 power, 6 channel,
  7 diagnostics UI, 3 foundation widget).
- `.\gradlew.bat :app:testDebugUnitTest` — 13/13 Kotlin tests passed.
- `flutter build apk --debug` — succeeded.
- `flutter build apk --release` — succeeded (43.3 MB, signed with the debug
  certificate; not distributable).
- Debug APK installed and cold-launched on a Pixel 10a AVD (Android 17).
  Diagnostics matched `adb shell dumpsys battery`: level 100%, status
  "Not charging", 5.00 V, 25.0 °C and a 10.0 mAh charge counter. Calculated
  battery-side power showed 4.50 W and was labeled Calculated/approximate.
  No Android runtime errors were logged.
- Physical-device validation is still pending.

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
      dashboard_screen.dart         Foundation app shell
      telemetry_diagnostics_screen.dart  Real-service diagnostics UI
test/
  core/telemetry/                   Contract, power and channel tests
  features/dashboard/               Diagnostics UI and navigation tests
  support/                          Payload fixtures and fake service
  widget_test.dart                  Branding, theme and large-text tests
android/app/src/main/kotlin/com/voltly/
  MainActivity.kt                   Registers the telemetry channels
  telemetry/                        Reader, conversions and channel host
docs/
  telemetry-contract.md             Versioned Android-to-Dart contract
```

Feature directories are added only when a milestone needs them.

## Architecture decisions

- **State management:** Riverpod (`flutter_riverpod` 3.4.3) with one service
  provider and one auto-dispose stream provider. Automatic provider retry is
  disabled so native failures surface immediately; the diagnostics screen
  offers an explicit Retry. No competing pattern is used.
- **Telemetry boundary:** implemented. A single Kotlin reader acquires readings
  from `ACTION_BATTERY_CHANGED` and `BatteryManager`, converts units once and
  publishes a versioned contract through MethodChannel/EventChannel. The Dart
  service is the only client. See `docs/telemetry-contract.md`.
- **Diagnostics:** the real-service diagnostics screen labels each metric's
  availability, provenance and observation time, marks readings older than five
  minutes stale, and displays calculated battery-side power separately.
- **Sampling:** the native receiver exists only while Dart is subscribed, so
  there is no polling and no background service. Riverpod auto-disposes the
  subscription when the diagnostics screen closes.
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
pre-1.0 during development (`0.2.0+2` now). Build numbers increment for each
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
- Average current, charge counter and other metrics are unsupported on some
  devices. The contract reports availability per metric; this is not a bug.
- The dashboard still shows no telemetry; only the developer diagnostics screen
  does. Phase 2 is the user-facing dashboard milestone.
- Release builds are currently signed with the Android debug certificate.
  Approved release signing credentials must be configured outside source
  control before any distribution.
- No release or GitHub Release has been created; the required universal and
  arm64 release APKs belong to a future approved release milestone.
