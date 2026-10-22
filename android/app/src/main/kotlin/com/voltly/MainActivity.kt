package com.voltly

import android.content.Intent
import android.os.Bundle
import com.voltly.charging.ChargingScreenChannel
import com.voltly.telemetry.BatteryTelemetryChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var telemetryChannel: BatteryTelemetryChannel? = null
    private var chargingScreenChannel: ChargingScreenChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        telemetryChannel = BatteryTelemetryChannel(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )
        chargingScreenChannel = ChargingScreenChannel(
            this,
            flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // The engine is configured during super.onCreate, but Dart has not
        // asked for launch state yet, so the request is queued.
        chargingScreenChannel?.handleIntent(intent, flutterRunning = false)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        chargingScreenChannel?.handleIntent(intent, flutterRunning = true)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        chargingScreenChannel?.onRequestPermissionsResult(requestCode)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        telemetryChannel?.dispose()
        telemetryChannel = null
        chargingScreenChannel?.dispose()
        chargingScreenChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
