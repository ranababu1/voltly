# Voltly: Engineering and Agent Instructions

> **Purpose:** These rules govern all development work in this repository. They complement `plan.md`, which is the authoritative product blueprint.
>
> **Priority:** Follow platform/security requirements first, then explicit project-owner instructions, then `plan.md`, then this file. If two project documents conflict, stop and ask for clarification rather than silently choosing a new product direction.

## 1. Required Project Documents

Maintain these four documents at the repository root:

- `plan.md`: authoritative scope, architecture, requirements, milestones and acceptance criteria. **Do not modify it during implementation unless the project owner explicitly approves a change.**
- `instructions.md`: these engineering, safety, Git, testing and release rules.
- `changelog.md`: chronological record of meaningful implementation changes.
- `currentstate.md`: concise, factual snapshot of what exists, what works, known issues and the next task.

Create `changelog.md` and `currentstate.md` during project foundation if they do not exist. Keep them useful and current. Do not claim work was completed unless it was actually implemented and verified.

## 2. Work Planning and Scope

1. Read `plan.md`, `instructions.md`, `currentstate.md`, and the relevant recent entries in `changelog.md` before starting a task.
2. Inspect the repository, current branch, working tree, toolchain and existing implementation before editing anything.
3. Identify the current milestone and its acceptance criteria.
4. Implement one coherent, small, buildable increment at a time.
5. Do not generate the entire application in one step.
6. Avoid unrelated refactors, speculative features and opportunistic dependency upgrades.
7. Preserve existing behavior unless the task explicitly requires changing it.
8. If requirements are ambiguous, the change would alter a project-level decision, or the requested implementation conflicts with the plan, explain the issue and ask before proceeding.
9. Do not silently change the product name, supported platform, privacy model, architecture, minimum SDK or monetization direction.
10. Before declaring a task complete, state what changed, what verification ran, what did not run, and any remaining limitation.

## 3. Repository and Git Safety

### 3.1 Preserve Existing Work

- Work on the existing intended branch unless the project owner authorizes a branch change.
- Inspect `git status` before making changes.
- Preserve all uncommitted user changes, including changes unrelated to the task.
- Never overwrite, discard, stage, revert or reformat unrelated user work.
- Do not assume a dirty working tree is disposable.
- If the existing state makes safe work uncertain, stop and ask.

### 3.2 Prohibited Destructive Operations

Never run any of the following without explicit permission from the project owner:

- `git reset --hard`
- `git clean -fd` or other destructive clean variants
- Force pushes
- History rewriting
- Branch deletion
- Broad checkout/restore commands that discard work
- Commands or scripts that delete project data or user changes

Do not use a destructive command merely to make the working tree clean.

### 3.3 Commit and Push Rules

- Push after every file change that leaves the solution buildable, **or at minimum when approximately 50 lines of production code have changed since the previous push, whichever comes first**.
- If a change temporarily breaks compilation, fix the build, verify it, and then push again.
- Periodically when bigger milestones gets completed and passes the tests, create checkpoints in git for better maintainability.
- Prefer small, focused commits with clear, factual messages.
- Review `git diff` and `git diff --cached` before committing.
- Stage only files relevant to the current task. Never use indiscriminate staging when unrelated user changes may be present.
- Update `changelog.md` and `currentstate.md` before committing when feasible.
- Push only to the configured remote and intended branch.
- Verify that the push succeeded; do not claim it succeeded based only on issuing the command.
- Do not add an AI co-author trailer.
- If no remote is configured, credentials are unavailable, network access is unavailable, or pushing is not authorized by the environment, do not pretend the push happened. Report the blocker and leave the verified local changes intact.
- Never bypass repository protections or rewrite history to force a push through.

## 4. Buildable-State Rule

A push must never leave the repository non-building.

- Prefer small changes that preserve compilation at each step.
- After any change that could affect compilation, run the narrowest useful validation and then a full relevant build before pushing.
- Run formatting and static analysis as appropriate for the files changed.
- If the required SDK, dependency, device or tool is unavailable, report that fact and do not claim the check passed.
- Do not hide failures, weaken tests, disable analyzers, or remove functionality simply to obtain a green build.
- If the baseline already fails, document the pre-existing failure, isolate your changes, and do not claim the repository is fully healthy.
- A test/build failure must be investigated. Do not push while a newly introduced build failure remains.

## 5. Flutter and Dart Standards

- Use sound null safety and the project's configured Dart/Flutter SDK constraints.
- Follow `dart format` and the configured lints.
- Run `flutter analyze` and relevant `flutter test` suites.
- Keep widgets focused on presentation and interaction. Put business rules and calculations in testable domain/service code.
- Do not access Android APIs directly from UI widgets.
- Use a single, documented state-management approach. Do not introduce multiple competing approaches without approval.
- Handle loading, empty, error, stale, unsupported and partially available data states.
- Avoid unnecessary rebuilds, tight polling, expensive work on the UI thread and unbounded lists.
- Use semantic labels and accessible controls. Support text scaling and avoid color-only status indicators.
- Keep user-facing text clear, respectful and explicit about estimates and uncertainty.
- Avoid hard-coded demo values in production paths. Any demo fixture must be clearly isolated from live telemetry and must never be presented as a real device reading.
- Use dependency injection or explicit interfaces where they make native integration and tests practical, without overengineering.

## 6. Kotlin and Android Standards

- Follow Kotlin conventions and the project's configured Android lint/static-analysis rules.
- Keep Android-specific telemetry and system event handling in the native adapter layer.
- Verify Android API semantics, units, nullability and version behavior before relying on a field.
- Do not assume every device reports every metric.
- Convert raw units at a clearly defined boundary and test the conversion.
- Document the current/charging sign convention.
- Use lifecycle-aware, battery-conscious sampling and avoid unnecessary permanent background services.
- Respect Android notification permissions, background execution limits, battery optimization behavior and target SDK requirements.
- Avoid blocking the main thread.
- Handle exceptions and malformed native data safely. Do not catch and silently discard errors that matter.
- Keep platform-channel method names, payload schemas and error behavior documented.
- If a native payload or contract changes, update the Dart side and tests in the same buildable increment.
- Validate telemetry on physical devices. Emulator results alone are insufficient evidence of hardware support.

## 7. Telemetry Correctness Rules

These rules are mandatory because telemetry correctness is the foundation of Voltly.

1. **One source of truth:** use a single telemetry service to acquire readings. Screens must not query Android independently.
2. **No fabricated values:** unavailable, unsupported, invalid and stale values must be represented explicitly. Never replace them with `0`, a guessed value, or a plausible-looking demo number.
3. **Canonical units:** document the units at the Kotlin/Dart boundary. Convert exactly once and test it.
4. **Timestamp every observation:** do not label stale data as live.
5. **Provenance:** distinguish device-reported values from calculated values and estimates.
6. **Current semantics:** define and consistently apply the charging/discharging sign convention.
7. **Power semantics:** if calculated from voltage and current, label it as approximate battery-side power. Never imply it is wall input power or charger wattage.
8. **Estimate honesty:** capacity, health and time-to-full/empty require adequate data and defensible calculations. Show unavailable when the evidence is insufficient.
9. **Sampling gaps:** charts and session summaries must not imply uninterrupted sampling when data is missing.
10. **Device variation:** capability detection must be runtime-based, not assumed from one test phone.
11. **Defensive parsing:** unknown fields, nulls, invalid numbers and payload-version changes must not crash the app.
12. **No misleading precision:** round and label values appropriately for the quality and resolution of the source data.

## 8. Architecture Boundaries

- Follow the feature-oriented architecture and boundaries in `plan.md`.
- Keep presentation, domain logic, repositories/persistence, and native Android integration separate.
- Widgets must not own database queries, platform-channel calls, or complex calculations.
- Repositories isolate storage from feature logic.
- Keep calculations pure where practical and cover them with unit tests.
- Avoid circular dependencies between features.
- Do not introduce a backend, authentication, cloud sync, analytics, advertising or remote telemetry without explicit approval.
- Do not add a package for a trivial task when the platform or existing stack already provides a sound solution.
- Before adding or upgrading a dependency, assess maintenance, compatibility, license, transitive dependencies, permissions, size and privacy impact. Pin or constrain versions appropriately and commit the relevant lockfile.
- Do not perform broad dependency upgrades as part of an unrelated feature.
- Add new architecture abstractions only when they solve a demonstrated need.

## 9. Database and Data Handling

- Use Drift/SQLite as agreed unless an approved change is documented.
- Keep schema and migrations explicit and tested.
- Use transactions for related writes that must be atomic.
- Test session persistence, interrupted sessions and migrations.
- Add indexes based on query patterns rather than speculation.
- Bound telemetry sampling, database growth and retention.
- Provide a clear way to delete locally stored history.
- Never commit device telemetry, user databases, exported personal data or production data.
- Do not log sensitive or unnecessary user/device data.
- Treat data corruption and database errors as real states; do not silently erase data to recover.
- Document any data migration that can alter or remove user history.

## 10. Security, Privacy and Permissions

- Keep the core product local-first and offline-capable.
- Request the minimum permissions needed for an implemented, user-visible feature.
- Explain permission requests in context. Do not request notification permission until a feature actually needs it.
- Never add hidden collection, undisclosed network requests, tracking SDKs or telemetry uploads.
- Never commit API keys, keystores, passwords, tokens, signing credentials or other secrets.
- Use local configuration and environment-specific secret handling where necessary; commit only safe examples such as `.env.example` without real values.
- Ensure `.gitignore` covers Flutter/Dart outputs, Android/Gradle outputs, IDE files, local configuration, signing files, databases, logs and secrets.
- Do not place secrets in source code, screenshots, changelogs or logs.
- If a future feature adds network transmission, accounts, analytics, ads or cloud storage, stop for approval and document data flows, consent, retention, security controls and Play Store disclosure implications before implementation.
- Do not claim a privacy policy or compliance requirement is satisfied until the relevant implementation and disclosure have been reviewed.

## 11. Testing and Verification

Choose tests based on the change, and record what actually ran.

### Dart / Flutter
- Format changed Dart files.
- Run `flutter analyze`.
- Run relevant unit and widget tests with `flutter test`.
- Run integration tests when the change crosses feature, persistence or native boundaries.
- Build the Android target after relevant changes.

### Kotlin / Android
- Run relevant Kotlin/JVM tests and Android lint or configured checks when available.
- Validate platform-channel payloads and conversion behavior.
- Build the Android app after native integration changes.
- Test on physical devices for hardware-dependent behavior.

### Data and Lifecycle
- Test charging state transitions, duplicate/noisy events, missing samples, app restarts and interrupted sessions.
- Test schema migrations and retention behavior.
- Test notification behavior and permissions on supported Android versions where feasible.

### Reporting
- Report exact commands and outcomes.
- Distinguish passed, failed, skipped and not-run checks.
- Never say “tested” when only code review was performed.
- Do not remove or weaken tests to make a change pass without explicit approval and a documented reason.

## 12. Sampling, Background Work and Battery Efficiency

- Use an explicit, configurable sampling policy rather than tight polling.
- Use a reasonable foreground interval based on user value, measured device behavior and performance testing.
- Reduce or stop live sampling when it is not needed.
- Use WorkManager only for deferrable tasks compatible with its scheduling guarantees.
- Do not promise exact background sampling intervals or instant alerts when Android does not guarantee them.
- Avoid wake locks and persistent foreground services unless a user-visible, approved requirement justifies them.
- Measure the impact of sampling frequency on battery, CPU, memory and storage.
- Explain sampling gaps and background limitations in the product where relevant.

## 13. UI and Design Rules

- Follow the Voltly visual direction: premium, restrained, AMOLED-friendly dark surfaces and mint-green accents.
- Prioritize legibility and information hierarchy over decorative effects.
- Use animation sparingly and ensure it communicates state rather than false precision.
- Do not copy AmpereFlow's exact layouts, branding, icons, assets, text or proprietary implementation.
- Use a consistent design-token system for color, spacing, typography, radius and elevation.
- Provide visual states for available, unavailable, stale, loading, error and insufficient-data conditions.
- Do not imply a metric is measured if it is estimated.
- Keep essential information accessible at large text sizes and to screen readers.
- Verify the interface on more than one screen size and with system text scaling enabled.

## 14. Documentation Maintenance

### `changelog.md`
- Keep a chronological, newest-first record of meaningful changes.
- Include date, milestone/area, summary, key files or behavior affected, and verification.
- Mention known limitations or failed checks relevant to the change.
- Do not record speculative or unimplemented work as completed.
- Keep entries concise but specific enough to understand the project's evolution.

### `currentstate.md`
Maintain a factual snapshot containing:
- Current milestone and project version/build status.
- Implemented features and their verification status.
- Current architecture and important data flows.
- Build/test commands and last known results.
- Known issues, platform/device limitations and blockers.
- Current Git branch and working-tree/push status when known.
- The single recommended next task and its acceptance criteria.

Update both documents when a meaningful implementation change is completed and before committing when feasible. Do not rewrite history to make prior state look better.

## 15. File Editing and Code Generation

- When editing an existing file, inspect the entire relevant file and preserve unrelated behavior.
- Make focused edits and review the complete diff.
- Do not replace a full file with a shortened version that omits existing functionality.
- Do not leave placeholder methods, TODO-only implementations, fake telemetry, or hard-coded production readings unless the task explicitly calls for a clearly isolated scaffold.
- Do not create large numbers of empty or speculative files.
- Keep generated code understandable and consistent with surrounding conventions.
- Avoid unrelated formatting churn.
- If a task requires a multi-file contract change, update all affected code and tests together while preserving a buildable result.
- If the requested change cannot be made safely within the current task, explain why and propose the smallest safe next step.

## 16. Git Ignore and Repository Hygiene

Verify that `.gitignore` excludes applicable generated and private files, including:
- `.dart_tool/`, `build/`, `.flutter-plugins`, `.flutter-plugins-dependencies`
- Android/Gradle build outputs and local machine configuration
- `.idea/`, `.vscode/` where project policy treats them as local, and OS-generated files
- `*.jks`, `*.keystore`, signing properties and local secret files
- `.env` and other real environment files
- SQLite database files, telemetry exports, logs, crash dumps and temporary files
- IDE caches and generated artifacts

Do not blindly overwrite the existing `.gitignore`; inspect it and add only missing, appropriate rules. Keep intentionally shared editor settings if the repository uses them as team configuration.

## 17. Release and Versioning

- Use a documented, consistent version/build-number strategy.
- Keep release builds reproducible.
- Run the relevant automated suite and verify a release build before declaring release readiness.
- Test the release candidate on physical Android devices.
- Confirm permission behavior, data deletion, retention, estimate messaging and offline functionality.
- Prepare privacy disclosures based on actual app behavior, not assumptions.
- Protect signing keys and credentials outside source control.
- Update changelog, current state and release notes before release.
- Document tested devices, Android versions, build identifiers and known limitations.
- Do not publish, submit to a store, or change production release configuration without explicit authorization.

### 17.1 GitHub Releases and APK Artifacts

Every approved Voltly release must publish two installable Android APK artifacts to the repository's GitHub Releases section.

#### Required Release Artifacts

1. **Universal APK:** An installable APK intended for broad device compatibility.
2. **ARM64 APK:** An architecture-optimized APK for `arm64-v8a` Android devices.

Both artifacts must be generated from the same release version and source revision. Their filenames must clearly identify the application, version, and APK variant.

Example filenames:

- `Voltly-v1.0.0-universal.apk`
- `Voltly-v1.0.0-arm64-v8a.apk`

These are the required release artifact types. Do not substitute debug APKs for production release APKs.

#### Release Workflow

1. Confirm that the release scope is complete and update `changelog.md` and `currentstate.md`.
2. Run formatting, static analysis, automated tests, and the required Android build checks.
3. Build both APK variants using the documented, reproducible release process.
4. Sign both APKs with the approved release signing configuration. Never commit keystores, passwords, signing credentials, or other secrets.
5. Verify that both APK files exist, are non-empty, and are valid installable packages.
6. Verify the package/application ID, version name, version code, signing identity, and target architecture for each artifact.
7. Install and smoke-test both APK variants on compatible Android devices or emulators. Record any device-specific validation limitations.
8. Create a Git tag matching the release version, following the repository's established versioning convention.
9. Create a GitHub Release for that tag and attach both APK files as downloadable release assets.
10. Include concise release notes describing the changes, important fixes, known limitations, and any relevant installation instructions.
11. Verify that the GitHub Release exists and that both APK assets are accessible for download. Do not report a successful publication until this verification is complete.
12. Update the release documentation and `currentstate.md` with the version, tag, build status, artifact names, release URL, and verification result.

#### Release Safety Rules

- Never publish an APK from a failed, unverified, or non-building source revision.
- Never overwrite or delete an existing release or tag without explicit project-owner approval.
- Never force-push or rewrite Git history to correct a release.
- Never expose signing credentials or secrets in logs, release notes, workflow files, or artifacts.
- Do not upload debug builds as production releases.
- Do not claim that a release was published when only the APKs were built locally.
- If either APK fails to build, sign, install, or upload, report the blocker and do not mark the release complete.
- Use GitHub Actions for automated release generation when practical, with protected signing secrets and a tag-triggered workflow. Manual release publication is acceptable when automation has not yet been implemented.
- Keep the signed Android App Bundle (AAB) as a separate Google Play distribution artifact when required. The AAB does not replace the two APK assets required in GitHub Releases.

#### Release Completion Criteria

A Voltly release is complete only when both required APKs have been built from the same tagged source revision, signed and validated, published as assets on the corresponding GitHub Release, and verified as downloadable. The release documentation must accurately record the outcome.

## 18. Dependency and Toolchain Changes

- Record the Flutter, Dart, JDK, Gradle, Android Gradle Plugin, Kotlin and SDK versions needed to build the project.
- Verify compatibility before upgrading any part of the toolchain.
- Avoid changing several interdependent toolchain versions at once unless necessary.
- Do not upgrade dependencies simply because newer versions exist.
- After a toolchain change, run clean, documented build and test checks as appropriate. Do not delete user data or caches destructively as a first troubleshooting step.
- Explain any environment-specific limitation rather than silently changing the supported build configuration.

## 19. Completion Report Template

At the end of each meaningful task, report:

1. **Implemented:** concrete behavior and files changed.
2. **Verification:** exact commands/checks and actual results.
3. **Device validation:** devices/Android versions tested, or state that physical-device validation remains pending.
4. **Documentation:** changes made to `changelog.md` and `currentstate.md`.
5. **Git:** branch, commit and push status, including blockers. Never claim a commit or push that did not occur.
6. **Known limitations:** unresolved issues and assumptions.
7. **Next task:** one specific next step aligned with the current milestone.

## 20. Final Non-Negotiable Rules

- Accuracy before visual polish.
- No fabricated telemetry or dishonest estimates.
- One telemetry acquisition source of truth.
- Privacy-first, local-first defaults.
- Preserve uncommitted user work.
- No destructive Git operations without explicit permission.
- Review diffs before committing.
- Keep the application buildable.
- Never push a non-building solution.
- Follow the required push cadence when the solution is buildable.
- Keep `plan.md` immutable unless the project owner explicitly approves a change.
- Maintain `changelog.md` and `currentstate.md`.
- Never claim unperformed tests, builds, commits or pushes succeeded.
