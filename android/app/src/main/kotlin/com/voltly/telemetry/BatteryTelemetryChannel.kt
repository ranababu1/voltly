package com.voltly.telemetry

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts Voltly's telemetry platform channels.
 *
 * While Dart is listening, `watch` emits on every ACTION_BATTERY_CHANGED
 * broadcast and additionally re-reads the live BatteryManager properties
 * (current now/average, charge counter) once per [POLL_INTERVAL_MILLIS].
 * Android only broadcasts when level, status, temperature or voltage change,
 * so without this the instantaneous current would appear frozen for minutes.
 *
 * Polling runs only for the lifetime of the Dart subscription, which the app
 * cancels whenever it leaves the foreground. The receiver and the poll are
 * both released on cancel or disposal.
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
    private var lastBatteryIntent: Intent? = null
    private val handler = Handler(Looper.getMainLooper())
    private val pollRunnable = object : Runnable {
        override fun run() {
            val sink = eventSink ?: return
            emit(sink, lastBatteryIntent)
            handler.postDelayed(this, POLL_INTERVAL_MILLIS)
        }
    }

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
                lastBatteryIntent = intent
                emit(events, intent)
                // Restart the poll so a broadcast and a poll tick never land
                // back to back.
                handler.removeCallbacks(pollRunnable)
                handler.postDelayed(pollRunnable, POLL_INTERVAL_MILLIS)
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
            handler.postDelayed(pollRunnable, POLL_INTERVAL_MILLIS)
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

    private fun emit(sink: EventChannel.EventSink, intent: Intent?) {
        try {
            // Before the first broadcast arrives, fall back to the sticky
            // battery intent so intent-derived metrics are never blank.
            sink.success(if (intent != null) reader.read(intent) else reader.read())
        } catch (_: RuntimeException) {
            sink.error(
                "telemetry_read_failed",
                "Could not read battery telemetry.",
                null,
            )
        }
    }

    private fun stopListening() {
        handler.removeCallbacks(pollRunnable)
        lastBatteryIntent = null
        val activeReceiver = receiver ?: return
        receiver = null
        eventSink = null
        try {
            context.unregisterReceiver(activeReceiver)
        } catch (_: IllegalArgumentException) {
            // The platform already unregistered it; nothing to clean up.
        }
    }

    private companion object {
        const val POLL_INTERVAL_MILLIS = 1_000L
    }
}
