# Current State

**Last updated:** 2026-10-19
**Milestone:** Phase 0 — Foundation (complete pending physical-device review)
**Project version:** `0.1.0+1` (versionCode 1)

## Implemented and verified

| Area | State | Verification |
| --- | --- | --- |
| Android Flutter app shell | Launchable, label `Voltly`, app ID `com.voltly` | Debug APK installed and launched on Pixel 10a AVD (Android 17); `Status: ok` |
| Minimum platform | API 26 pinned in Gradle | APK `sdkVersion:'26'` |
| Design tokens | AMOLED palette, spacing, radius, typography | `flutter analyze`; widget test asserts theme |
| Dashboard shell | Branding, tagline, explicit no-telemetry notice | Widget test + emulator UI hierarchy |
| Launch experience | Black window in light and dark system modes | Android resource review; emulator cold launch |
| Large-text layout | Scrollable, no overflow at 320×640 and 2× text | Widget test passed |
| Static checks | Format, analyze clean | `dart format`, `flutter analyze` |
| Automated tests | 3 widget tests | `flutter test` — 3/3 passed |
| Android builds | Debug and release APKs build | `flutter build apk --debug`, `--release` |

**Deliberately absent:** battery percentages, voltage, current, temperature,
power, session history, charts, alerts, health/capacity estimates. The app
shows no value rather than a fabricated one.

## Architecture and data flow

- `lib/main.dart` sets the system UI overlay and runs `VoltlyApp`.
- `lib/app/app.dart` owns the `MaterialApp`; dark-only `AppTheme`.
- `lib/app/theme/` contains color, spacing/radius, typography and theme tokens.
- `lib/features/dashboard/dashboard_screen.dart` is presentation-only and has
  no platform-channel or storage access.
- No telemetry source, repository, database or state container exists yet.
- Selected for the next milestone, not yet added: Riverpod (single state
  approach) and a native telemetry service behind a platform channel.
- Planned persistence: Drift/SQLite with explicit migrations (Phase 3+).

## Toolchain

Flutter 3.47.7 · Dart 3.13.5 · JDK 21.0.12 (Corretto) · Gradle 9.3.1 ·
AGP 9.1.0 · Kotlin 2.4.0 · compile/target SDK 36 · minSdk 26 ·
Android SDK installed 37.0.0 / platform android-37.1.

## Build and test commands

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter build apk --release --split-per-abi
```

Last known results: format clean, analyze clean, 3/3 tests passed, debug and
release builds succeeded. `--split-per-abi` has **not** been run yet; it will be
required for the arm64 release artifact at release time.

## Known issues and limitations

- No native telemetry or real-device readings exist yet.
- Emulator-only validation. Hardware behavior, vendor battery APIs and
  permission behavior remain unverified on physical devices.
- Release signing is not configured; both APKs use the Android debug
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

- Branch: `main`
- Remote: `origin` → `https://github.com/ranababu1/voltly.git`
- The repository was initialized during Phase 0. `plan.md` and
  `instructions.md` are preserved at the root unchanged.
- Push status must be verified with `git status -sb` and `git ls-remote origin`
  before it is reported as published.

## Next task

**Phase 1 — Native battery telemetry adapter (single source of truth).**

Acceptance criteria:

1. A single Dart `BatteryTelemetryService` obtains readings through one
   documented Kotlin platform channel; no widget queries Android directly.
2. Payload documents units, nullability, timestamp, charging/discharging sign
   convention and provenance (device-reported vs calculated).
3. Unsupported or missing fields remain explicitly unavailable — never `0` or
   a guessed value; malformed payloads are handled without crashing.
4. A runtime capability report identifies which metrics the device exposes.
5. Kotlin/Dart unit tests cover parsing, unit conversion and missing-field
   behavior.
6. Dashboard displays only real readings with timestamp/stale indication,
   or an explicit unavailable state.
7. `flutter analyze`, `flutter test`, Android build and a physical-device
   telemetry check are completed and recorded.
