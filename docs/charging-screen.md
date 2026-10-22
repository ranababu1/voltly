# Charging screen

An opt-in, minimal full-screen view shown over the lock screen when a charger
is connected: clock, date, an animated tick ring for the battery level, and
four metrics — temperature, current, time estimate and approximate
battery-side power.

Approved by the project owner on 2026-10-23 as an addition outside the
original `plan.md` scope, including the persistent notification and the new
permissions below.

## Trigger

Android (API 26+) does not deliver `ACTION_POWER_CONNECTED` to manifest
receivers, so the feature needs a running component:

1. The dashboard **Charging screen** switch requests `POST_NOTIFICATIONS`
   (Android 13+) and, if granted, stores the opt-in in the
   `voltly_charging_screen` SharedPreferences file and starts
   `ChargingMonitorService`.
2. `ChargingMonitorService` is a `specialUse` foreground service with a
   minimum-importance ongoing notification. It registers a dynamic receiver
   for power connect/disconnect only. It does no sampling, polling or wake
   locks.
3. On connect, `ChargingScreenPolicy.shouldLaunch` decides: enabled, the device
   is locked or its screen is off, and no launch in the last 5 s (connector
   bounce). An unlocked device in use is never interrupted.
4. The service posts a silent high-importance notification with a
   full-screen intent to `MainActivity` (`com.voltly.extra.CHARGING_SCREEN`).
   The activity sets `showWhenLocked`/`turnScreenOn`, cancels the
   notification and asks Flutter to open the screen.
5. `ChargingBootReceiver` restarts the service after `BOOT_COMPLETED` and
   `MY_PACKAGE_REPLACED`, only when the opt-in is on. Opening Voltly also
   restarts it if Android stopped it.

Turning the switch off stops the service and removes the notification.

## Permissions

| Permission | Why |
| --- | --- |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE` | Keep the connect receiver alive |
| `POST_NOTIFICATIONS` | Service notification and the full-screen launch notification |
| `USE_FULL_SCREEN_INTENT` | Open over the lock screen. Android 14+ can revoke it; the dashboard card warns and links to the special-access page. Without it the trigger arrives as a normal notification. |
| `RECEIVE_BOOT_COMPLETED` | Restore the opt-in after reboot |

Play Store note: `specialUse` foreground services and full-screen intents both
require declarations at submission time; full-screen intent is restricted to
calling/alarm apps by default on Android 14+ for Play installs.

## Channel `com.voltly/charging_screen`

| Method | Result |
| --- | --- |
| `getStatus`, `setEnabled({enabled})`, `requestNotificationPermission` | `{enabled, notificationsAllowed, fullScreenAllowed}` |
| `openFullScreenSettings` | Opens the full-screen-intent special-access page |
| `consumeLaunchRequest` | `bool`: launched by the trigger; cleared after read |
| `releaseLockScreen` | Clears `showWhenLocked`; moves the task back if locked |
| `unlock` | `bool`: keyguard dismissed |
| Native → Dart `showChargingScreen` | Trigger arrived while Flutter was running |

A missing plugin (tests, non-Android) is reported as unsupported and the
dashboard card is hidden.

## Screen behaviour

- Values come from the single `TelemetryController` and the stored-sample
  estimate. Unavailable values show `—` with an explicit semantics label;
  nothing becomes zero.
- Level is a whole percent (Android reports integer levels; no invented
  decimals). Status is the device charging state; Voltly does not claim
  "fast charging" because it has no reliable source for that.
- Current is device-reported `currentNow` in mA (positive = charging).
- The estimate is the dashboard estimator's result, rounded to 5 minutes. It
  needs 10 minutes of stored samples, so it is usually `—` right after
  plugging in.
- Power is calculated battery-side watts, labelled `≈` and "battery-side",
  never charger input.
- Motion: a slow glow sweep across the filled ticks and the existing bolt
  pulse, only while charging and fresh, and none at all with reduced motion.
- The clock updates on minute boundaries (one timer, no per-second ticker).
- The screen closes when the charger is unplugged (after a plugged reading
  was seen), from the close button, or via back. Closing from the lock screen
  returns to it. The open button requests keyguard dismissal and stays put if
  the user cancels.

## Limitations

- Metrics refresh on `ACTION_BATTERY_CHANGED` broadcasts only, so current and
  power can lag by tens of seconds on some devices. A faster refresh would
  need bounded polling and changes to session sample throttling.
- Verified on the Pixel 10a AVD (Android 17) with the screen lock set to None.
  Return-to-keyguard with a secure lock, OEM lock-screen behaviour and
  battery-optimisation killing need physical-device checks.
