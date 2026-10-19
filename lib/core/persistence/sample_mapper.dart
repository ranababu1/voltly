import 'dart:convert';

import 'package:voltly/core/persistence/app_database.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';
import 'package:voltly/core/telemetry/telemetry_models.dart';

/// Rebuilds a domain sample from a stored row.
///
/// Scalar values and availability metadata are stored together. If metadata is
/// missing or malformed, the affected reading is returned as invalid with a
/// reason instead of assuming the value was available.
TelemetrySample sampleFromRow(TelemetrySampleRow row) {
  final Map<String, Object?> availability = _decodeMap(
    row.availabilityMetadata,
  );
  final Map<String, Object?> sourceMetadata = _decodeMap(row.sourceMetadata);
  final Map<String, Object?> sources = _asMap(sourceMetadata['readings']);
  final DateTime observedAt = row.observedAt.toUtc();

  final TelemetrySnapshot snapshot = TelemetrySnapshot(
    schemaVersion: row.snapshotSchemaVersion,
    observedAt: observedAt,
    batteryLevel: _doubleReading(
      row: row,
      key: 'batteryLevel',
      value: row.batteryLevelPercent,
      fallbackUnit: TelemetryUnits.percent,
      availability: availability,
      sources: sources,
    ),
    chargingState: _enumReading<BatteryChargingState>(
      key: 'chargingState',
      value: row.chargingState,
      fallbackObservedAt: observedAt,
      availability: availability,
      sources: sources,
    ),
    plugSource: _enumReading<BatteryPlugSource>(
      key: 'plugSource',
      value: row.plugSource,
      fallbackObservedAt: observedAt,
      availability: availability,
      sources: sources,
    ),
    voltage: _doubleReading(
      row: row,
      key: 'voltage',
      value: row.voltageVolts,
      fallbackUnit: TelemetryUnits.volts,
      availability: availability,
      sources: sources,
    ),
    temperature: _doubleReading(
      row: row,
      key: 'temperature',
      value: row.temperatureCelsius,
      fallbackUnit: TelemetryUnits.celsius,
      availability: availability,
      sources: sources,
    ),
    currentNow: _doubleReading(
      row: row,
      key: 'currentNow',
      value: row.currentAmps,
      fallbackUnit: TelemetryUnits.amperes,
      availability: availability,
      sources: sources,
    ),
    currentAverage: _doubleReading(
      row: row,
      key: 'currentAverage',
      value: row.currentAverageAmps,
      fallbackUnit: TelemetryUnits.amperes,
      availability: availability,
      sources: sources,
    ),
    chargeCounter: _doubleReading(
      row: row,
      key: 'chargeCounter',
      value: row.chargeCounterMah,
      fallbackUnit: TelemetryUnits.milliampereHours,
      availability: availability,
      sources: sources,
    ),
  );

  return TelemetrySample(
    snapshot: snapshot,
    id: row.id,
    sessionId: row.sessionId,
  );
}

TelemetryReading<double> _doubleReading({
  required TelemetrySampleRow row,
  required String key,
  required double? value,
  required String fallbackUnit,
  required Map<String, Object?> availability,
  required Map<String, Object?> sources,
}) {
  final _ReadingMeta meta = _meta(
    key: key,
    fallbackObservedAt: row.observedAt.toUtc(),
    availability: availability,
    sources: sources,
  );
  if (meta.availability == TelemetryAvailability.available && value == null) {
    return TelemetryReading<double>(
      availability: TelemetryAvailability.invalid,
      source: meta.source,
      observedAt: meta.observedAt,
      unit: meta.unit ?? fallbackUnit,
      reason: 'Stored value is missing for "$key".',
    );
  }
  return TelemetryReading<double>(
    value: meta.availability == TelemetryAvailability.available ? value : null,
    unit: meta.unit ?? fallbackUnit,
    availability: meta.availability,
    source: meta.source,
    observedAt: meta.observedAt,
    reason: meta.reason,
  );
}

TelemetryReading<T> _enumReading<T extends Object>({
  required String key,
  required T? value,
  required DateTime fallbackObservedAt,
  required Map<String, Object?> availability,
  required Map<String, Object?> sources,
}) {
  final _ReadingMeta meta = _meta(
    key: key,
    fallbackObservedAt: fallbackObservedAt,
    availability: availability,
    sources: sources,
  );
  if (meta.availability == TelemetryAvailability.available && value == null) {
    return TelemetryReading<T>(
      availability: TelemetryAvailability.invalid,
      source: meta.source,
      observedAt: meta.observedAt,
      reason: 'Stored value is missing for "$key".',
    );
  }
  return TelemetryReading<T>(
    value: meta.availability == TelemetryAvailability.available ? value : null,
    availability: meta.availability,
    source: meta.source,
    observedAt: meta.observedAt,
    reason: meta.reason,
  );
}

_ReadingMeta _meta({
  required String key,
  required DateTime fallbackObservedAt,
  required Map<String, Object?> availability,
  required Map<String, Object?> sources,
}) {
  final Map<String, Object?> reading = _asMap(availability[key]);
  final TelemetryAvailability parsedAvailability = _parseAvailability(
    reading['availability'],
  );
  final Object? timestamp = reading['observedAtMillis'];
  final DateTime observedAt = timestamp is int
      ? DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true)
      : fallbackObservedAt;
  final String? reason = reading['reason'] is String
      ? reading['reason']! as String
      : (reading.isEmpty ? 'Stored availability metadata is missing.' : null);

  return (
    availability: parsedAvailability,
    source: _parseSource(sources[key]),
    observedAt: observedAt,
    reason: reason,
    unit: reading['unit'] is String ? reading['unit']! as String : null,
  );
}

TelemetryAvailability _parseAvailability(Object? raw) => switch (raw) {
  'available' => TelemetryAvailability.available,
  'unsupported' => TelemetryAvailability.unsupported,
  'temporarily_unavailable' => TelemetryAvailability.temporarilyUnavailable,
  'temporarilyUnavailable' => TelemetryAvailability.temporarilyUnavailable,
  'invalid' => TelemetryAvailability.invalid,
  'stale' => TelemetryAvailability.stale,
  _ => TelemetryAvailability.invalid,
};

TelemetrySource _parseSource(Object? raw) => switch (raw) {
  'calculated' => TelemetrySource.calculated,
  'estimated' => TelemetrySource.estimated,
  _ => TelemetrySource.device,
};

Map<String, Object?> _decodeMap(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const <String, Object?>{};
  try {
    final Object? decoded = jsonDecode(raw);
    return _asMap(decoded);
  } on FormatException {
    return const <String, Object?>{};
  }
}

Map<String, Object?> _asMap(Object? raw) {
  if (raw is Map<String, Object?>) return raw;
  if (raw is Map<Object?, Object?>) {
    return raw.map<String, Object?>(
      (Object? key, Object? value) => MapEntry<String, Object?>('$key', value),
    );
  }
  return const <String, Object?>{};
}

typedef _ReadingMeta = ({
  TelemetryAvailability availability,
  TelemetrySource source,
  DateTime observedAt,
  String? reason,
  String? unit,
});
