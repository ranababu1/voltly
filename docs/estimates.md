# Time-to-full/empty estimates

This document defines the evidence-based estimates introduced in Phase 4,
increment 1. Estimates are calculated from stored telemetry only. They are
approximate projections, not charger ratings, capacity measurements or battery
health claims.

## Scope

- Only an **active** session is eligible. A completed or interrupted session is
  historical evidence, so the dashboard hides the estimate card.
- The estimator is pure Dart (`BatteryTimeEstimator`) and does not read Android
  APIs, the charger, capacity, health or the current snapshot directly.
- Inputs are the stored `ChargingSession` and its retained `TelemetrySample`
  rows. The repository remains the source of truth.

## Evidence requirements

The most recent **30 minutes** of retained samples form the candidate window.
All of the following must hold:

| Requirement | Rule |
| --- | --- |
| Freshness | The latest sample is no more than **5 minutes** old. |
| Sample count | At least **3** samples in the candidate window. |
| Coverage | The window spans at least **10 minutes**. |
| Continuity | No interval between consecutive samples exceeds **5 minutes**. |
| State | The latest charging state is available and is `charging` or `discharging`. |
| Consistency | Every sample in the window reports the same charging state. |
| Levels | Every sample in the window has an available battery level. |
| Direction | Charging levels rise; discharging levels fall. |
| Projection | The linear projection is at most **24 hours**. |

A missing level or state is never interpolated and never treated as zero. A
sample with an unavailable level makes the window ineligible even if its
neighbours are valid.

## Calculation

1. Sort samples by observation time and discard anything older than 30 minutes
   before the latest sample.
2. Compute the elapsed minutes between the first and last retained samples in
   the window.
3. Compute the average level rate in percent per minute:
   `(latest level - first level) / elapsed minutes`.
4. Project to 100% for charging or 0% for discharging:
   `remaining percent / |rate|`.
5. Round the result to the nearest minute. Presentation rounds to five minutes
   and says "about", "under 5 min", or "Full"/"Empty" rather than implying
   precision.
6. If the latest level has already reached the target, report the reached target
   with no duration. The UI shows "Full" or "Empty", never "0 min".

The rate assumes a steady level change over the observed window. Real batteries
are not linear, so the result is always labelled approximate.

## Unavailable reasons

`BatteryEstimateResult.unavailable` carries a user-facing reason. It is shown in
the dashboard card instead of a number when evidence is inadequate:

- no active session / session is not active;
- no stored samples yet;
- fewer than three samples (with a pruning note when retention removed older
  rows);
- less than ten minutes of observations;
- latest sample older than five minutes;
- charging state unavailable in the latest sample;
- charging state changed or was unavailable during the window;
- battery level unavailable during the window;
- a sampling gap over five minutes;
- battery already full, or device not charging;
- charging level did not rise / discharging level did not fall;
- projected time exceeds 24 hours;
- stored samples could not be read (provider-level error).

No unavailable branch substitutes zero, charger input power, capacity, current,
voltage or battery health.

## Gaps, pruning and retention

- Gap detection is local to the estimation window. A gap earlier in the session
  does not invalidate a complete, recent window, but the card labels that earlier
  session gap.
- Retention removes the oldest sample rows first. A valid recent retained window
  can still be used and is labelled "Older samples were pruned by retention".
  If too few retained samples remain, the unavailable reason explicitly mentions
  pruning.
- Samples outside the recent window are not used to fill holes. No line or value
  is interpolated.

## UI and accessibility

The dashboard shows `SessionEstimateCard` only while a session is active:

- title "Time to full" or "Time to empty";
- an "Estimated" badge and an approximate time;
- sample count and observed window;
- a statement that the estimate assumes a steady rate;
- a statement that it is not charger input power, capacity or battery health;
- pruning/earlier-gap notes when applicable;
- an explicit "Time estimate unavailable" card and reason when withheld.

The card has a concise semantics label containing the estimate, sample count,
window, assumptions and limits. It is tested at 320×640 with 2× text scaling.

## Tests

- `test/core/sessions/battery_time_estimate_test.dart` covers valid charging and
  discharging, minimum sample/window rules, gaps, unavailable levels/states,
  stale samples, completed sessions, noisy/contradictory direction, pruning,
  target reached, and the 24-hour cap.
- `test/features/sessions/session_estimate_card_test.dart` covers the visible
  estimate, unavailable reason, no-active-session state, pruned note, semantics
  and 2× text.
- `test/core/sessions/session_providers_test.dart` covers active-session
  retrieval and a no-active-session result.

## Deliberate limitations

- This is a one-point-in-time projection from recent observations, not a
  prediction of future device use or charging behavior.
- It is not a battery-health, capacity, charge-cycle or charger-power estimate.
- Completed sessions do not show an estimate; historical estimates may be added
  only with a separately specified evidence model.
- Physical-device validation and manual TalkBack validation remain outstanding.
