package com.voltly.charging

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Restores the opt-in charging monitor after a reboot or app update. Does
 * nothing unless the user turned the charging screen on.
 */
class ChargingBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        if (!ChargingScreenPrefs.isEnabled(context)) return
        try {
            ChargingMonitorService.start(context)
        } catch (_: RuntimeException) {
            // The platform refused a background start; the dashboard restarts
            // the service the next time Voltly opens.
        }
    }
}
