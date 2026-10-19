package com.voltly.telemetry

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts Voltly's telemetry platform channels.
 *
 * `watch` updates arrive from ACTION_BATTERY_CHANGED while Dart is listening;
 * there is no polling. The receiver is registered only for the lifetime of
 * the Dart subscription and unregistered on cancel or disposal.
 */
internal class BatteryTelemetryChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val reader = BatteryTelemetryReader(context)
    private val methodChannel = MethodChannel(
        messenger,
        BatteryTelemetryContract.METHOD_CHANNEL,
    ).also { it.setMethodCallHandler(this) }
    private val eventChannel = EventChannel(
        messenger,
        BatteryTelemetryContract.EVENT_CHANNEL,
    ).also { it.setStreamHandler(this) }

    private var receiver: BroadcastReceiver? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            BatteryTelemetryContract.METHOD_GET_SNAPSHOT -> {
                try {
                    result.success(reader.read())
                } catch (_: RuntimeException) {
                    result.error(
                        "telemetry_read_failed",
                        "Could not read battery telemetry.",
                        null,
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events == null) return
        stopListening()
        eventSink = events

        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent == null || eventSink !== events) return
                try {
                    events.success(reader.read(intent))
                } catch (_: RuntimeException) {
                    events.error(
                        "telemetry_read_failed",
                        "Could not read battery telemetry.",
                        null,
                    )
                }
            }
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(
                    batteryReceiver,
                    filter,
                    Context.RECEIVER_NOT_EXPORTED,
                )
            } else {
                @Suppress("DEPRECATION")
                context.registerReceiver(batteryReceiver, filter)
            }
            receiver = batteryReceiver
        } catch (_: RuntimeException) {
            eventSink = null
            events.error(
                "telemetry_receiver_failed",
                "Could not register for Android battery updates.",
                null,
            )
            events.endOfStream()
        }
    }

    override fun onCancel(arguments: Any?) {
        stopListening()
    }

    fun dispose() {
        stopListening()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    private fun stopListening() {
        val activeReceiver = receiver ?: return
        receiver = null
        eventSink = null
        try {
            context.unregisterReceiver(activeReceiver)
        } catch (_: IllegalArgumentException) {
            // The platform already unregistered it; nothing to clean up.
        }
    }
}
