package com.voltly.charging

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import com.voltly.MainActivity
import com.voltly.R

/**
 * Opt-in foreground service that waits for a charger connection.
 *
 * Android does not deliver ACTION_POWER_CONNECTED to manifest receivers on
 * API 26+, so a running component must hold a dynamic receiver. The service
 * does no sampling or polling: it only reacts to connect/disconnect
 * broadcasts. When the device is locked (or the screen is off) it posts a
 * full-screen-intent notification that opens the charging screen over the
 * lock screen.
 */
class ChargingMonitorService : Service() {
    private var receiver: BroadcastReceiver? = null
    private var lastLaunchAtMillis: Long? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        ensureChannels(this)
        startInForeground()
        registerPowerReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!ChargingScreenPrefs.isEnabled(this)) {
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onDestroy() {
        receiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
                // Already unregistered by the platform.
            }
        }
        receiver = null
        cancelLaunchNotification(this)
        super.onDestroy()
    }

    private fun startInForeground() {
        val openApp = PendingIntent.getActivity(
            this,
            REQUEST_OPEN_APP,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = Notification.Builder(this, CHANNEL_MONITOR)
            .setSmallIcon(R.drawable.ic_stat_charging)
            .setContentTitle("Charging screen is on")
            .setContentText("Shows charging details on the lock screen when you plug in.")
            .setContentIntent(openApp)
            .setOngoing(true)
            .setShowWhen(false)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_MONITOR,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_MONITOR, notification)
        }
    }

    private fun registerPowerReceiver() {
        val powerReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_POWER_CONNECTED -> onPowerConnected()
                    Intent.ACTION_POWER_DISCONNECTED ->
                        cancelLaunchNotification(this@ChargingMonitorService)
                }
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_POWER_CONNECTED)
            addAction(Intent.ACTION_POWER_DISCONNECTED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(powerReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(powerReceiver, filter)
        }
        receiver = powerReceiver
    }

    private fun onPowerConnected() {
        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        val power = getSystemService(Context.POWER_SERVICE) as? PowerManager
        val now = System.currentTimeMillis()
        val launch = ChargingScreenPolicy.shouldLaunch(
            enabled = ChargingScreenPrefs.isEnabled(this),
            keyguardLocked = keyguard?.isKeyguardLocked ?: false,
            screenInteractive = power?.isInteractive ?: true,
            lastLaunchAtMillis = lastLaunchAtMillis,
            nowMillis = now,
        )
        if (!launch) return
        lastLaunchAtMillis = now
        postLaunchNotification()
    }

    private fun postLaunchNotification() {
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val fullScreen = PendingIntent.getActivity(
            this,
            REQUEST_CHARGING_SCREEN,
            chargingScreenIntent(this),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notification = Notification.Builder(this, CHANNEL_LAUNCH)
            .setSmallIcon(R.drawable.ic_stat_charging)
            .setContentTitle("Charging")
            .setContentText("Tap to view charging details.")
            .setCategory(Notification.CATEGORY_STATUS)
            .setContentIntent(fullScreen)
            .setFullScreenIntent(fullScreen, true)
            .setAutoCancel(true)
            .setTimeoutAfter(LAUNCH_NOTIFICATION_TIMEOUT_MILLIS)
            .build()
        try {
            manager.notify(NOTIFICATION_LAUNCH, notification)
        } catch (_: SecurityException) {
            // Notification permission was revoked; the dashboard reports it.
        }
    }

    companion object {
        const val EXTRA_CHARGING_SCREEN = "com.voltly.extra.CHARGING_SCREEN"

        private const val CHANNEL_MONITOR = "charging_monitor"
        private const val CHANNEL_LAUNCH = "charging_screen"
        private const val NOTIFICATION_MONITOR = 41
        private const val NOTIFICATION_LAUNCH = 42
        private const val REQUEST_OPEN_APP = 1
        private const val REQUEST_CHARGING_SCREEN = 2
        private const val LAUNCH_NOTIFICATION_TIMEOUT_MILLIS = 60_000L

        fun chargingScreenIntent(context: Context): Intent =
            Intent(context, MainActivity::class.java)
                .putExtra(EXTRA_CHARGING_SCREEN, true)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

        fun start(context: Context) {
            context.startForegroundService(
                Intent(context, ChargingMonitorService::class.java),
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, ChargingMonitorService::class.java))
        }

        fun cancelLaunchNotification(context: Context) {
            context.getSystemService(NotificationManager::class.java)
                ?.cancel(NOTIFICATION_LAUNCH)
        }

        private fun ensureChannels(context: Context) {
            val manager = context.getSystemService(NotificationManager::class.java) ?: return
            val monitor = NotificationChannel(
                CHANNEL_MONITOR,
                "Charging screen service",
                NotificationManager.IMPORTANCE_MIN,
            ).apply {
                description = "Keeps the charging screen ready while it is turned on."
                setShowBadge(false)
            }
            val launch = NotificationChannel(
                CHANNEL_LAUNCH,
                "Charging screen",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Opens the charging screen when a charger is connected."
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            }
            manager.createNotificationChannels(listOf(monitor, launch))
        }
    }
}
