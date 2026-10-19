# Voltly: Product and Engineering Plan

> **Document status:** Authoritative project blueprint  
> **Change policy:** Treat this file as immutable during implementation. Do not silently rewrite scope or decisions. If a material change is needed, propose it to the project owner and obtain explicit approval before changing this file. Record approved changes in `changelog.md`.

## 1. Project Overview

**Product name:** Voltly  
**Tagline:** Know your battery.  
**Product promise:** Battery intelligence, beautifully simple.

Voltly is an Android-first battery-monitoring and charging-analytics application. It helps users understand battery state, electrical telemetry, charging behavior, temperature, and long-term battery trends through a polished, trustworthy interface.

Voltly is inspired by the general category of battery-monitoring products such as AmpereFlow. It must have its own brand, user experience, source code, architecture, copy, and visual assets. Do not copy another product's proprietary implementation, branding, screenshots, or assets.

### 1.1 Problem Statement

Android users often cannot easily see useful battery telemetry or understand how their phone behaves while charging and discharging. Available metrics vary by device, and many displayed health or capacity figures are estimates rather than direct measurements.

Voltly should make available information understandable without overstating accuracy, while remaining lightweight, local-first, privacy-conscious, and battery-efficient.

### 1.2 Product Goals

1. Present available battery readings clearly and update them reliably while the app is in use.
2. Distinguish device-reported measurements from calculated values and estimates.
3. Record charging sessions and provide useful local history and comparisons.
4. Offer honest capacity and health estimates only when the data supports them.
5. Provide useful, configurable alerts without promising unrestricted background execution.
6. Deliver a premium, accessible interface with an AMOLED-friendly dark theme and restrained mint-green accents.
7. Keep core functionality offline, with no account or backend required for the initial release.
8. Maintain a modular, testable, continuously buildable codebase.

### 1.3 Non-Goals for the Initial Release

- iOS support or feature parity.
- Cloud synchronization, user accounts, or a hosted backend.
- Social features or community functionality.
- Claims that Voltly makes a phone charge faster, improves battery chemistry, or directly prevents degradation.
- Guaranteed access to every metric on every Android device.
- Guaranteed continuous sampling when the app is closed or the operating system restricts background work.
- Advertising or third-party analytics SDKs in the initial release.
- Root access or privileged APIs.
- Automatic device repair or battery optimization actions outside normal Android APIs.

## 2. Target Users and Primary Use Cases

### 2.1 Target Users

- People curious about their phone's battery and charging behavior.
- Users comparing charging sessions, cables, adapters, or charging conditions.
- Users who want battery temperature and threshold notifications.
- Technically curious users who want access to available device telemetry without unnecessary complexity.

### 2.2 Primary User Journeys

1. **Open and understand:** The user opens Voltly and sees battery percentage, charging state, and currently available metrics.
2. **Observe charging:** While charging, the dashboard shows live readings and clearly indicates unavailable or stale values.
3. **Review a session:** After a charging session, the user can inspect duration, percentage change, observed trends, and data coverage.
4. **Understand limitations:** The user can see which values are directly reported, calculated, or estimated and why some metrics may be unavailable.
5. **Configure alerts:** The user configures supported battery percentage or temperature thresholds and grants notification permission when required.
6. **Review history:** The user views saved sessions and trends without needing an account or internet connection.
7. **Control data:** The user can review storage use and delete local history.

## 3. Platform and Technology Decisions

These are the initial project defaults. Verify compatibility when creating the project and pin compatible dependency versions.

| Area | Initial choice | Responsibility |
|---|---|---|
| Target platform | Android only | Initial product and release target |
| UI and application layer | Flutter / Dart | Screens, navigation, presentation, app logic |
| Native integration | Kotlin | Android battery APIs, system broadcasts and platform-specific behavior |
| Dart/native bridge | Flutter platform channels or Pigeon if justified | Typed communication across the boundary |
| Local database | SQLite using Drift | Telemetry samples, charging sessions, settings where appropriate |
| State management | Select one maintained approach and document it before broad implementation | Predictable UI state and dependency boundaries |
| Charts | A maintained Flutter chart library | Trends and session comparisons |
| Background work | Android WorkManager for appropriate deferrable work; foreground execution only when justified | Avoid promises of unrestricted background sampling |
| Notifications | Android notification APIs through a maintained Flutter plugin or native Kotlin integration | User-configured alerts |
| Tests | Dart unit/widget tests, integration tests, Kotlin tests and physical-device validation | Correctness and release confidence |
| Distribution | Signed Android App Bundle (AAB) | Google Play release |

### 3.1 Minimum Android Version

Initial target: **Android 8.0 (API 26)**, subject to validation against the selected Flutter version, plugins, APIs, and target-device needs. Confirm and document the final minimum SDK before implementation is considered complete. Do not raise or lower it silently.

### 3.2 Offline-First Policy

The initial release must not require internet connectivity for core features. Do not add a backend, account system, remote telemetry, crash-reporting SDK, advertising SDK, or analytics service unless the project owner explicitly approves the change and its privacy implications.

## 4. Product Scope and Phases

Features are introduced incrementally. A phase is not complete merely because its UI exists; its behavior must be implemented, tested, documented, and verified against the relevant acceptance criteria.

### Phase 0: Foundation

**Deliverables**
- Flutter project and Android/Kotlin integration scaffold.
- Repository and feature-module boundaries.
- Theme foundations and design tokens.
- Documentation files: `plan.md`, `instructions.md`, `changelog.md`, and `currentstate.md`.
- Git workflow, ignore rules, dependency baseline, and build/test commands.
- A minimal app that launches on an Android device or emulator.

**Acceptance criteria**
- A clean checkout can be configured and built using documented steps.
- The app launches without a crash.
- Flutter and Android toolchain versions and build commands are documented.
- No secrets, local databases, generated build artifacts, or machine-specific configuration are committed.

### Phase 1: Native Battery Telemetry

**Deliverables**
- Kotlin telemetry adapter around supported Android battery APIs and system broadcasts.
- A stable telemetry contract shared with Dart.
- Explicit handling for unsupported, unavailable, invalid, stale, or permission-restricted data.
- Unit conversion and sign conventions documented and tested.
- Device capability reporting.
- A small diagnostic view or developer-only diagnostics to validate values during development.

**Initial metrics**
- Battery level and charging state.
- Battery voltage.
- Battery temperature.
- Current and average current where available.
- Charge counter or capacity-related readings where available.
- Charging source/type where available.
- Plugged/connected state.
- Timestamp and reading availability/freshness.

**Acceptance criteria**
- The app never substitutes fabricated readings for unavailable hardware values.
- Raw Android values are converted consistently and tested.
- Telemetry timestamps and availability states are explicit.
- Values are checked against Android/device diagnostics on physical devices.
- The native adapter is the single source of truth for telemetry acquisition.
- Missing metrics do not crash the app or break the dashboard.

### Phase 2: Dashboard and Visual System

**Deliverables**
- Dashboard for battery percentage, charging state, and supported telemetry.
- Clear visual hierarchy and metric cards.
- Live updates while the app is active.
- Restrained battery/charging animation that does not imply unsupported precision.
- Dark AMOLED-friendly theme and mint-green accent.
- Light theme if included without delaying core telemetry reliability.
- Loading, unavailable, stale-data, error, empty and low-capability-device states.
- Accessibility support for text scaling, contrast, screen readers and touch targets.

**Acceptance criteria**
- Dashboard values come from the real telemetry service, not hard-coded demo values.
- UI remains stable when metrics appear/disappear or are unavailable.
- Sampling and rendering do not cause avoidable battery or CPU use.
- Layout is validated on more than one screen size and at increased text scaling.
- Direct measurements, calculated values and estimates are visually distinguishable.

### Phase 3: Charging Session Engine and Local History

**Deliverables**
- Session start/end lifecycle based on available charging-state transitions.
- Session sampling policy and retention strategy.
- Local SQLite schema and Drift data access layer.
- Session list and session detail views.
- Charging/discharging trend charts and session summaries.
- Recovery behavior after app process termination, reboot, or interrupted sampling.

**Acceptance criteria**
- Sessions survive app restarts and database migrations.
- Duplicate or noisy state transitions do not create uncontrolled duplicate sessions.
- Partial sessions and gaps are represented honestly.
- The UI does not imply a continuous history when sampling was interrupted.
- Database writes are bounded and retention behavior is documented.
- Repository and session-engine logic are unit tested.

### Phase 4: Estimates, Battery Insights and Alerts

**Deliverables**
- Estimated time to full or empty only when sufficient recent data exists.
- Capacity/health estimates only when a defensible method and sufficient data are available.
- Estimate confidence/quality and explanatory copy.
- Configurable supported thresholds for battery percentage and temperature.
- Notifications that respect Android permission and background execution rules.
- Settings for sampling, alerts, history retention and data deletion.

**Acceptance criteria**
- Every estimate is labelled as an estimate and has documented assumptions.
- Voltly does not invent a battery-health percentage when evidence is insufficient.
- Estimates handle changing load, charging interruptions, missing samples and implausible values.
- Notification permission is requested contextually and only when needed.
- Background limitations and expected alert reliability are explained.
- User settings persist and have tests.

### Phase 5: Everyday Utility and Release Candidate

**Deliverables**
- Optional home-screen widget after feasibility and lifecycle validation.
- Export of session history, if included in the release scope.
- Localization-ready strings and accessibility review.
- Performance, battery-use, storage and stability checks.
- Privacy policy and Play Console disclosures appropriate to actual behavior.
- App icon, screenshots, store listing and signed AAB.
- Release checklist and rollback/support notes.

**Acceptance criteria**
- Release build is reproducible from documented steps.
- All release-blocking tests pass.
- No known critical data integrity, privacy, crash, or telemetry correctness defects remain.
- Store disclosures accurately describe data collection and permissions.
- Signing secrets remain outside version control.
- Final release limitations and supported-device test matrix are documented.

## 5. Functional Requirements

### 5.1 Dashboard and Telemetry

- Display battery percentage and charging/discharging/idle state.
- Display voltage, current, approximate battery-side power, and temperature when available.
- Display charging source/type only when Android provides a meaningful value.
- Show the time of the latest reading or otherwise indicate stale data.
- Represent unavailable values as unavailable, not as zero.
- Indicate whether a value is device-reported, calculated, or estimated.
- Allow live refresh while the app is active without uncontrolled polling.
- Handle device/API variation gracefully.

### 5.2 Charging Sessions

- Detect session transitions using available Android state.
- Persist session start/end time and samples or summary statistics needed for history.
- Show session duration, start/end battery percentage, percentage change, and data coverage.
- Show charts only where adequate samples exist.
- Mark interrupted or incomplete sessions.
- Support history deletion and retention limits.

### 5.3 Battery Health and Capacity

- Treat battery health and capacity as optional, evidence-dependent features.
- Prefer directly exposed device values where available and meaningful.
- If an estimate is implemented, document the calculation, required data, limitations, and confidence criteria.
- Do not present an estimate as a manufacturer diagnostic or precise battery-aging measurement.
- If the device does not expose enough information, explain that a reliable estimate is unavailable.

### 5.4 Alerts

- Support user-configured thresholds only for metrics that can be observed with reasonable reliability.
- Respect notification permission and Android version behavior.
- Avoid repeated notifications by implementing cooldowns, state-change detection, or hysteresis where appropriate.
- Clearly explain that background restrictions can delay or prevent some alerts.
- Do not run an unnecessary permanent service merely to simulate reliability.

### 5.5 Settings and Privacy

- Allow supported appearance and alert preferences to be configured.
- Explain telemetry and estimate limitations in plain language.
- Provide a way to clear locally stored history.
- Request only permissions justified by a user-visible feature.
- Keep core data local by default.
- Document what is stored, why it is stored, and how it is removed.

## 6. Telemetry Data Contract

The Kotlin adapter should expose a stable, versioned contract to Dart. Prefer typed models or a clearly documented map/schema with strict parsing. Do not let UI widgets call Android APIs directly.

Each reading should represent, as applicable:

- `metric`: stable metric identifier.
- `value`: numeric value or null when unavailable.
- `unit`: canonical unit.
- `timestamp`: observation time.
- `availability`: available, unsupported, temporarily unavailable, invalid, or stale.
- `source`: Android/device reported, calculated, or estimated.
- `quality` or confidence metadata when applicable.
- `reason`: optional human-readable/debuggable reason for unavailability.

Suggested canonical units:
- Battery level: percent.
- Voltage: volts in the Dart/domain model.
- Current: amperes in the Dart/domain model, with a documented positive/negative convention.
- Temperature: degrees Celsius.
- Power: watts, calculated only when input values are valid and contemporaneous.
- Capacity/charge counter: mAh where the source and conversion support that unit.

Android APIs commonly expose current in microamps, voltage in millivolts, and temperature in tenths of a degree Celsius. Verify the exact API semantics and units used by each field. Keep raw/native units at the adapter boundary if needed for diagnostics, but convert once and test the conversion.

### 6.1 Current and Power Semantics

- Document the sign convention for charging and discharging and normalize it consistently.
- Do not assume every device uses the same availability or interpretation for every metric without validating the API contract.
- Approximate battery-side power may be calculated from battery voltage and current when both readings are valid and sufficiently close in time.
- Label this as **estimated/calculated battery-side power**, not wall-charger input power or adapter output.
- Do not infer charger wattage from battery-side current/power.
- Do not show misleading negative values without an understandable explanation.

### 6.2 Missing and Stale Data

- Null/unavailable is distinct from numeric zero.
- UI must handle unsupported metrics gracefully.
- Stale readings must not be presented as live.
- Invalid readings should be rejected or marked invalid, not silently coerced.
- Sampling gaps must be represented in charts and session summaries.

## 7. Architecture and Module Boundaries

Use feature-oriented architecture with clear separation between presentation, domain logic, data access, and native integration.

Suggested target structure (create files incrementally, not all at once):

```text
voltly/
├── android/
│   └── app/src/main/kotlin/.../   # Native telemetry and Android integrations
├── lib/
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── theme/
│   ├── core/
│   │   ├── telemetry/
│   │   ├── formatting/
│   │   ├── errors/
│   │   └── storage/
│   ├── data/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── sources/
│   └── features/
│       ├── dashboard/
│       ├── battery_details/
│       ├── charging_sessions/
│       ├── history/
│       ├── battery_health/
│       ├── alerts/
│       └── settings/
├── test/
├── integration_test/
├── plan.md
├── instructions.md
├── changelog.md
├── currentstate.md
└── README.md
```

### 7.1 Architectural Rules

- One telemetry acquisition service is the source of truth.
- Widgets must not directly query platform channels or Android APIs.
- Domain calculations must be testable without a physical device.
- Repositories isolate persistence from UI and business logic.
- Native Android code owns Android-specific APIs and broadcasts.
- Dart models validate native payloads and handle missing/unknown fields safely.
- Keep platform-channel contracts small, typed, documented and versioned when they evolve.
- Avoid speculative abstractions and premature backend layers.
- Avoid a monolithic screen or service that owns unrelated features.
- Add modules when a real requirement needs them, not simply because they appear in the target tree.

## 8. Data Model and Local Database

Use SQLite through Drift unless a documented technical constraint justifies an approved alternative.

### 8.1 Proposed Tables

**`telemetry_samples`**
- `id`: primary key.
- `recorded_at`: timestamp.
- `session_id`: nullable relation to a charging session.
- `battery_level_percent`: nullable numeric value.
- `charging_state`: normalized state.
- `voltage_volts`: nullable numeric value.
- `current_amps`: nullable numeric value.
- `temperature_celsius`: nullable numeric value.
- `power_watts`: nullable calculated value.
- `charge_counter_mah`: nullable value when supported.
- `availability_metadata`: structured metadata or normalized fields for supported/unavailable readings.
- `source_metadata`: measurement/calculation/estimate provenance where needed.

**`charging_sessions`**
- `id`: primary key.
- `started_at`: timestamp.
- `ended_at`: nullable timestamp for an active or interrupted session.
- `start_level_percent`: nullable.
- `end_level_percent`: nullable.
- `session_state`: active, completed, interrupted, or equivalent normalized states.
- `sample_count`: summary/cache field only if maintained consistently.
- `created_at` and `updated_at` where useful.

**`app_settings`**
- Key/value or typed settings storage for sampling preferences, theme, alert thresholds, retention policy, and notification choices.
- Do not store secrets. Avoid storing settings in multiple competing sources of truth.

This is a proposed logical schema, not permission to introduce every column immediately. Confirm field types, indexes, migration strategy and retention needs during the relevant milestone. Store raw samples only to the extent needed for useful history and reasonable storage usage.

### 8.2 Persistence Rules

- Use migrations for schema changes after the initial database is shipped or treated as persistent.
- Test migrations and recovery from incomplete sessions.
- Use transactions for operations that must succeed or fail together.
- Define indexes based on real query patterns.
- Avoid unbounded writes or unlimited sample retention.
- Provide a documented retention policy and a way for the user to clear history.
- Never commit real user telemetry or database files to source control.

## 9. Non-Functional Requirements

### Reliability
- Unavailable device metrics must not crash the app.
- Handle process death, app restarts, device reboot, charging-state noise and database errors.
- Never claim a sample was collected when it was not.

### Performance and Battery Efficiency
- Choose sampling intervals based on user-visible value and device constraints.
- Do not use tight polling loops.
- Stop or reduce foreground sampling when the dashboard is no longer active unless a separately justified feature requires otherwise.
- Use deferred background work only for tasks compatible with Android's scheduling model.
- Measure CPU, memory, database growth and battery impact on physical devices.

### Privacy and Security
- Local-first data storage.
- No unnecessary permissions.
- No secrets in source control or logs.
- Avoid collecting or transmitting data that is not required.
- If any network, analytics, crash-reporting or account feature is proposed later, obtain explicit approval and document data flows, consent, retention and store disclosures first.

### Accessibility and Usability
- Support system text scaling.
- Use meaningful semantic labels for metrics and charts.
- Do not rely on color alone to communicate charging state or warnings.
- Maintain readable contrast and touch targets.
- Provide understandable empty, loading, error and unsupported states.

### Maintainability
- Use consistent formatting, analysis and naming.
- Keep domain logic isolated and unit tested.
- Document platform-specific behavior and non-obvious calculations.
- Keep dependencies maintained and minimize unnecessary packages.

## 10. Testing Strategy

### Unit Tests
- Unit conversions and sign normalization.
- Power calculation and invalid-input handling.
- Estimate calculations, confidence thresholds and insufficient-data behavior.
- Charging-session transitions and duplicate event handling.
- Session summaries and sampling-gap handling.
- Repository logic and retention policy.

### Widget Tests
- Dashboard for available and unavailable metrics.
- Stale-data and error states.
- Theme and text-scaling behavior.
- Settings, alert configuration and empty history.
- Chart behavior with empty, sparse and irregular samples.

### Native and Integration Tests
- Kotlin adapter parsing and conversion.
- Platform-channel payload validation.
- Database writes, reads, migrations and recovery.
- End-to-end charging-session flow.
- Notification permission and threshold behavior where testable.

### Physical-Device Validation
Test on multiple Android devices where possible, ideally across manufacturers and Android versions. Validate:
- Battery level and charging state.
- Voltage and temperature availability/units.
- Current/charge counter availability and sign behavior.
- Plug type/source availability.
- Sampling behavior during screen-off, app backgrounding and process termination.
- Notifications under realistic battery optimization settings.
- Storage growth and app battery impact.

Emulators are useful for UI and logic, but do not substitute for physical-device telemetry validation.

## 11. Milestone Gates

A milestone is complete only when all applicable items below are true:

1. Scope and implementation are documented.
2. Relevant automated tests pass.
3. Static analysis and formatting pass.
4. The application compiles and builds for the intended target.
5. Relevant manual or physical-device validation is recorded.
6. `changelog.md` is updated.
7. `currentstate.md` reflects the actual repository state and next task.
8. Git diff is reviewed and contains only intended changes.
9. No known release-blocking regression is introduced.

A push must never leave the repository non-building. If a change cannot reasonably be built yet, split it into smaller buildable steps or keep it unpushed until the build is restored.

## 12. Release Checklist

Before a public release:

- [ ] Confirm product name, store name and trademark/app-store conflicts have been reviewed.
- [ ] Confirm minimum Android SDK and supported-device expectations.
- [ ] Run formatter, static analysis and all applicable tests.
- [ ] Build and install a release candidate on physical devices.
- [ ] Validate real telemetry, unavailable states, charging sessions and estimates.
- [ ] Review crash behavior, performance, storage growth and battery use.
- [ ] Verify permissions and notification behavior.
- [ ] Verify local history deletion and retention behavior.
- [ ] Confirm no unnecessary network access or third-party tracking is present.
- [ ] Prepare privacy policy and store disclosures that accurately reflect actual behavior.
- [ ] Generate a signed AAB using protected signing credentials.
- [ ] Ensure signing credentials and secrets are not committed.
- [ ] Prepare store icon, screenshots, description and support contact.
- [ ] Update `changelog.md`, `currentstate.md` and release notes.
- [ ] Record version, build number, tested devices and known limitations.

## 13. Risks and Known Limitations

- **Hardware variation:** Android devices expose different metrics and readings. Feature availability must be runtime-driven.
- **Estimate quality:** Battery capacity and health are difficult to infer without adequate observations or manufacturer-specific data.
- **Background restrictions:** Android may delay or stop background work. Continuous sampling and instant alerts cannot be guaranteed in all conditions.
- **Charging power semantics:** Battery-side electrical power is not equivalent to wall input or charger rating.
- **Session gaps:** App suspension and missed events can make a session incomplete.
- **Naming:** Voltly is a working name until app-store and trademark checks are completed.
- **iOS differences:** iOS is outside the initial scope and requires a separate feasibility assessment.

## 14. Decisions Requiring Explicit Approval

Do not silently change these project-level decisions:
- Product name and branding after the initial name check.
- Android-only initial scope or minimum Android version.
- Addition of a backend, account system, cloud sync, analytics, ads or data transmission.
- Addition of sensitive or unnecessary permissions.
- Changes to the local-first privacy model.
- A material change to the agreed technology stack.
- Any scope change that materially alters delivery, maintenance, privacy or cost.

## 15. Definition of Done

Voltly is ready for its initial public release when the agreed release scope is implemented with real device telemetry, the application is stable and tested across the documented device matrix, estimates and limitations are communicated honestly, local data is handled safely, the release build is reproducible, store/privacy requirements are complete, and the documentation accurately describes the delivered product.

**North-star engineering principle:** Establish correct real-device telemetry first. Every dashboard, chart, session and insight must build on trustworthy readings and explicit uncertainty handling.
