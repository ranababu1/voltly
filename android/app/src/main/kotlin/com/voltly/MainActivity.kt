package com.voltly

import com.voltly.telemetry.BatteryTelemetryChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var telemetryChannel: BatteryTelemetryChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        telemetryChannel = BatteryTelemetryChannel(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        telemetryChannel?.dispose()
        telemetryChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
