# Voltly

**Know your battery.** Battery intelligence, beautifully simple.

Voltly is an Android-first battery-monitoring and charging-analytics app. It
presents device-reported telemetry honestly, keeps history on the device, and
never substitutes guessed or demo values for real readings.

> **Status: Phase 0 — Foundation.**
> The Android app shell, design tokens and automated checks exist. Native
> battery telemetry is **not** implemented yet, so the app deliberately shows
> no battery readings.

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
| JDK | Amazon Corretto 21.0.12 |
| Gradle wrapper | 9.3.1 |
| Android Gradle Plugin | 9.1.0 |
| Kotlin | 2.4.0 |
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
flutter build apk --debug
```

Last recorded results (2026-10-19):

- `flutter analyze` — no issues.
- `flutter test` — 3/3 widget tests passed.
- `flutter build apk --debug` — succeeded.
- `flutter build apk --release` — succeeded, but signed with the debug key.
- Debug APK installed and launched on a Pixel 10a emulator (Android 17);
  no Android runtime errors. Physical-device validation is still pending.

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
  features/
    dashboard/
      dashboard_screen.dart         Foundation app shell (no telemetry yet)
test/
  widget_test.dart                  Branding, theme and large-text tests
android/                            Android host, minSdk 26, app ID com.voltly
```

Feature directories are added only when a milestone needs them.

## Architecture decisions

- **State management:** Riverpod is the selected single approach for live
  telemetry state. The dependency is intentionally not added yet because
  Phase 0 has no runtime state to manage. No competing pattern is used.
- **Telemetry boundary:** a single telemetry service will acquire readings
  through a native Android adapter. Widgets must never query Android APIs
  directly. Payload contracts will be documented and tested on both sides.
- **Persistence:** Drift/SQLite is planned for session history, with explicit,
  tested schema migrations. No database exists yet.
- **Charts and estimates:** deferred until real captured data exists. Estimates
  will be labeled and withheld when evidence is insufficient.

## Privacy and permissions

- No application code performs network requests, and no third-party analytics,
  ads or tracking SDKs are included.
- The release manifest requests **no** runtime permissions and no `INTERNET`
  permission. Debug and profile builds include Flutter's development-only
  `INTERNET` permission for hot reload and debugging.
- No local database or telemetry export exists yet. `.gitignore` excludes
  databases, exports, signing material, environment files and logs.
- A privacy policy is not yet written; it must reflect implemented behavior
  before any store submission.

## Versioning

`pubspec.yaml` uses semantic-style `MAJOR.MINOR.PATCH+BUILD`. The project is
pre-1.0 during development (`0.1.0+1` now). Build numbers increment for each
distributed release candidate. Tag and release conventions are defined in
`instructions.md` §17.

## Documentation

- `plan.md` — authoritative product and engineering blueprint (immutable).
- `instructions.md` — engineering, testing, Git and release rules.
- `changelog.md` — chronological record of meaningful changes.
- `currentstate.md` — factual snapshot, blockers and the next task.

## Known limitations

- No native telemetry, sessions, charts, alerts or estimates exist yet.
- Only emulator validation has been performed; hardware-specific behavior is
  unverified until physical-device testing.
- Release builds are currently signed with the Android debug certificate.
  Approved release signing credentials must be configured outside source
  control before any distribution.
- No release or GitHub Release has been created; the required universal and
  arm64 release APKs belong to a future approved release milestone.
