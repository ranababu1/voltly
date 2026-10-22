import 'package:voltly/core/sessions/battery_time_estimate.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Pure formatting for the charging screen's compact tiles.
///
/// Every function returns null for an unavailable value so the widget shows
/// an explicit placeholder; nothing is ever substituted with zero.

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatChargingClock(DateTime local, {required bool use24HourFormat}) {
  final int hour = use24HourFormat
      ? local.hour
      : (local.hour % 12 == 0 ? 12 : local.hour % 12);
  final String hourText = use24HourFormat
      ? hour.toString().padLeft(2, '0')
      : hour.toString();
  return '$hourText:${local.minute.toString().padLeft(2, '0')}';
}

String formatChargingDate(DateTime local) =>
    '${local.day} ${_months[local.month - 1]} ${local.year}';

String chargingStatusLabel(TelemetryReading<BatteryChargingState> state) {
  if (!state.isAvailable) return 'STATUS UNAVAILABLE';
  return switch (state.value!) {
    BatteryChargingState.charging => 'CHARGING',
    BatteryChargingState.full => 'FULLY CHARGED',
    BatteryChargingState.notCharging => 'NOT CHARGING',
    BatteryChargingState.discharging => 'ON BATTERY',
  };
}

String? formatTileTemperature(TelemetryReading<double> reading) =>
    reading.isAvailable ? '${reading.value!.toStringAsFixed(1)}°C' : null;

/// Device-reported current in whole milliamperes. Positive means charging.
String? formatTileCurrent(TelemetryReading<double> reading) =>
    reading.isAvailable ? '${(reading.value! * 1000).round()} mA' : null;

/// Approximate battery-side power with one decimal.
String? formatTilePower(TelemetryReading<double> reading) =>
    reading.isAvailable ? '${reading.value!.toStringAsFixed(1)} W' : null;

String estimateTileLabel(BatteryEstimateResult? result) =>
    switch (result?.estimate?.kind) {
      BatteryEstimateKind.timeToFull => 'To full',
      BatteryEstimateKind.timeToEmpty => 'To empty',
      null => 'Estimate',
    };

/// Compact form of the stored-sample estimate, rounded to five minutes like
/// the dashboard card to avoid false precision.
String? formatTileEstimate(BatteryEstimateResult? result) {
  final BatteryTimeEstimate? estimate = result?.estimate;
  if (estimate == null) return null;
  if (estimate.targetReached) {
    return estimate.kind == BatteryEstimateKind.timeToFull ? 'Full' : 'Empty';
  }
  final int rounded = (estimate.remaining.inMinutes / 5).round() * 5;
  if (rounded < 5) return '<5m';
  final int hours = rounded ~/ 60;
  final int minutes = rounded.remainder(60);
  if (hours == 0) return '~${minutes}m';
  return minutes == 0 ? '~${hours}h' : '~${hours}h ${minutes}m';
}
