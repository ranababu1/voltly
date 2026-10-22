package com.voltly.charging

import android.Manifest
import android.app.Activity
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Platform channel for the opt-in lock-screen charging screen.
 *
 * Contract (documented in docs/charging-screen.md):
 * - `getStatus` / `setEnabled(enabled)` / `requestNotificationPermission`
 *   return `{enabled, notificationsAllowed, fullScreenAllowed}`.
 * - `openFullScreenSettings` opens the Android 14+ special-access page.
 * - `consumeLaunchRequest` returns whether this activity was opened by the
 *   charger-connect trigger and clears the flag.
 * - `releaseLockScreen` stops showing over the keyguard and, if the device is
 *   locked, sends the task back so the lock screen returns.
 * - `unlock` asks the system to dismiss the keyguard; returns success.
 * - Native → Dart `showChargingScreen` when a new trigger arrives while the
 *   Flutter UI is already running.
 */
internal class ChargingScreenChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val context: Context = activity.applicationContext
    private val channel = MethodChannel(messenger, CHANNEL).also {
        it.setMethodCallHandler(this)
    }
    private var pendingLaunch = false
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStatus" -> {
                // Self-heal: restart the monitor if Android stopped it.
                if (ChargingScreenPrefs.isEnabled(context)) startMonitorSafely()
                result.success(status())
            }
            "setEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") == true
                ChargingScreenPrefs.setEnabled(context, enabled)
                if (enabled) startMonitorSafely() else ChargingMonitorService.stop(context)
                result.success(status())
            }
            "requestNotificationPermission" -> requestNotificationPermission(result)
            "openFullScreenSettings" -> {
                openFullScreenSettings()
                result.success(null)
            }
            "consumeLaunchRequest" -> {
                val launch = pendingLaunch
                pendingLaunch = false
                result.success(launch)
            }
            "releaseLockScreen" -> {
                setShowOverLockScreen(false)
                val keyguard =
                    context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                if (keyguard?.isKeyguardLocked == true) activity.moveTaskToBack(true)
                result.success(null)
            }
            "unlock" -> unlock(result)
            else -> result.notImplemented()
        }
    }

    /** Called by the activity for every intent it receives. */
    fun handleIntent(intent: Intent?, flutterRunning: Boolean) {
        if (intent?.getBooleanExtra(ChargingMonitorService.EXTRA_CHARGING_SCREEN, false) != true) {
            return
        }
        intent.removeExtra(ChargingMonitorService.EXTRA_CHARGING_SCREEN)
        ChargingMonitorService.cancelLaunchNotification(context)
        setShowOverLockScreen(true)
        if (flutterRunning) {
            channel.invokeMethod("showChargingScreen", null)
        } else {
            pendingLaunch = true
        }
    }

    fun onRequestPermissionsResult(requestCode: Int) {
        if (requestCode != REQUEST_NOTIFICATIONS) return
        pendingPermissionResult?.success(status())
        pendingPermissionResult = null
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pendingPermissionResult?.success(status())
        pendingPermissionResult = null
    }

    private fun status(): Map<String, Any> {
        val manager = context.getSystemService(NotificationManager::class.java)
        val fullScreenAllowed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            manager?.canUseFullScreenIntent() == true
        } else {
            true
        }
        return mapOf(
            "enabled" to ChargingScreenPrefs.isEnabled(context),
            "notificationsAllowed" to (manager?.areNotificationsEnabled() == true),
            "fullScreenAllowed" to fullScreenAllowed,
        )
    }

    private fun startMonitorSafely() {
        try {
            ChargingMonitorService.start(context)
        } catch (_: RuntimeException) {
            // Background-start restrictions; retried on the next status call.
        }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(status())
            return
        }
        pendingPermissionResult?.success(status())
        pendingPermissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_NOTIFICATIONS,
        )
    }

    private fun openFullScreenSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            Intent(
                Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                Uri.parse("package:${context.packageName}"),
            )
        } else {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
        }
        try {
            activity.startActivity(intent)
        } catch (_: RuntimeException) {
            activity.startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:${context.packageName}"),
                ),
            )
        }
    }

    private fun unlock(result: MethodChannel.Result) {
        val keyguard = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        if (keyguard == null || !keyguard.isKeyguardLocked) {
            setShowOverLockScreen(false)
            result.success(true)
            return
        }
        keyguard.requestDismissKeyguard(
            activity,
            object : KeyguardManager.KeyguardDismissCallback() {
                override fun onDismissSucceeded() {
                    setShowOverLockScreen(false)
                    result.success(true)
                }

                override fun onDismissCancelled() {
                    result.success(false)
                }

                override fun onDismissError() {
                    result.success(false)
                }
            },
        )
    }

    private fun setShowOverLockScreen(show: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            activity.setShowWhenLocked(show)
            activity.setTurnScreenOn(show)
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (show) activity.window.addFlags(flags) else activity.window.clearFlags(flags)
        }
    }

    companion object {
        const val CHANNEL = "com.voltly/charging_screen"
        private const val REQUEST_NOTIFICATIONS = 4201
    }
}
