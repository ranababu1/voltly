# Local Persistence

**Status:** schema v1, repository, live session tracking, history, detail and
gap-aware stored trend charts are implemented.

Voltly uses Drift on top of SQLite (`package:sqlite3` native assets). The
database is local-only and is never committed to source control. The production
file lives in the application support directory as `voltly.sqlite`; tests use
in-memory or temporary files.

## Schema v1

### `charging_sessions`

| Column | Type | Notes |
| --- | --- | --- |
| `id` | INTEGER PK | Auto-increment |
| `started_at` | DATETIME | Observation timestamp, UTC |
| `ended_at` | DATETIME NULL | Null while active |
| `last_observed_at` | DATETIME NULL | Used to detect restart gaps |
| `start_level_percent` | REAL NULL | Never defaulted to 0 |
| `end_level_percent` | REAL NULL | Null when unavailable at the end |
| `session_state` | TEXT | `active`, `completed`, `interrupted` |
| `sample_count` | INTEGER | Accepted samples, including rows later pruned |
| `max_sampling_gap_ms` | INTEGER NULL | Longest inter-sample gap |
| `has_sampling_gaps` | BOOLEAN | Telemetry coverage was interrupted |
| `samples_pruned` | BOOLEAN | Retention removed older sample rows |
| `created_at` / `updated_at` | DATETIME | Repository clock |

### `telemetry_samples`

Stores each accepted observation: battery level, charging state, plug source,
voltage, current now, average current, temperature, charge counter, calculated
battery-side watts, contract schema version, plus availability and provenance
metadata. Values are nullable when Android did not provide a usable reading.

`availability_metadata` is a JSON map per metric containing availability,
observation time, unit and reason. `source_metadata` records the source
(`device`, `calculated`, `estimated`) and the power method. JSON is metadata
only; scalar columns remain queryable.

A unique index on `(session_id, observed_at)` makes duplicate sample inserts
idempotent. Deleting a session cascades to its samples.

### Indexes

- `idx_charging_sessions_started_at` — recent history and retention ordering.
- `idx_charging_sessions_state_started_at` — active-session lookup.
- `idx_telemetry_samples_session_observed_at` — ordered sample retrieval and
  duplicate protection (unique).
- `idx_telemetry_samples_observed_at` — time-based maintenance and future charts.

## Migration policy

- `schemaVersion` is `1`; fresh databases run `createAll()`.
- Opening a database whose stored version is newer than the app's supported
  version throws `UnsupportedError`. Voltly never silently downgrades or mutates
  newer data.
- Future upgrades must be explicit and tested. There is no destructive fallback.
- Foreign keys are enabled on every open.
- Generated Drift code (`app_database.g.dart`) is committed so builds do not
  require code generation. Regenerate with:
  `dart run build_runner build`.

## Transactions and recovery

- Starting a session inserts the summary and first sample in one transaction.
- Appending or ending a session updates the summary and inserts its sample in one
  transaction; a missing session rolls the whole operation back.
- `recoverActiveSession()` returns the newest active row. If corruption or an
  external edit left multiple active rows, older rows are marked interrupted at
  the newest session's start and flagged as gap-affected.
- A process restart leaves the active session open. The next integration step
  must restore it through the tracker so the restart gap is recorded.

## Retention

Default `SessionRetentionPolicy`:

- Keep at most **100 ended sessions**.
- Remove ended sessions whose end time is more than **180 days** old.
- Keep at most **720 sample rows per session** (~12 hours at one sample/minute).
- Active sessions are exempt from the age/count bounds but their samples are
  still capped.

When a per-session cap removes the oldest samples, `samples_pruned` becomes true.
`sample_count` still reflects accepted observations, so a history screen can say
that the stored sample list is incomplete without confusing pruning with a
telemetry gap. All retention work runs inside the same repository transaction as
the write that triggered it.

`deleteAllSessions()` removes all sessions and samples in one transaction and
returns the number of sessions deleted.

## Live integration

- `databaseProvider` owns the single database for the app lifetime; it opens
  lazily and closes when the provider scope is disposed.
- `SessionCoordinator` serializes foreground snapshots through the tracker and
  repository. It restores the active session on launch and leaves it open while
  the app is backgrounded so the next observation records a gap.
- A storage failure pauses live tracking, keeps the dashboard usable and shows a
  Retry banner. Retry reloads the last committed active session.
- The history screen reads recent sessions from the same repository. It labels
  active, completed and interrupted sessions, sampling gaps, partial sessions
  and retention-pruned sample lists.

## Chart rules

Session detail charts are built only from retained database samples:

- A missing or unavailable metric breaks the line.
- A gap longer than five minutes breaks the line.
- No value is interpolated between samples.
- Retention-pruned history is labelled; a chart covers only the retained range.
- Charts expose a text summary and screen-reader label instead of relying on
  visual shape alone.

## Privacy

- No network access is used by the database or repository.
- No database file, WAL/SHM file or export is committed; `.gitignore` excludes
  them.
- The app settings table from the product plan is deferred until settings are
  implemented. No secrets belong in this database.
