import 'package:voltly/core/errors/telemetry_exception.dart';

/// Whether a reading can be used, and why not when it cannot.
enum TelemetryAvailability {
  available,
  unsupported,
  temporarilyUnavailable,
  invalid,

  /// The value was valid when captured but is too old to present as live.
  /// Native never sends this; UI derives it from the reading timestamp.
  stale,
}

/// Provenance of a reading.
enum TelemetrySource {
  /// Read directly from an Android/device API.
  device,

  /// Derived by Voltly from valid, contemporaneous readings.
  calculated,

  /// Inferred from observations rather than measured or directly calculated.
  estimated,
}

enum BatteryChargingState { charging, discharging, notCharging, full }

enum BatteryPlugSource { none, ac, usb, wireless, dock }

/// Canonical unit identifiers used across the platform contract.
abstract final class TelemetryUnits {
  static const String percent = 'percent';
  static const String volts = 'volts';
  static const String celsius = 'celsius';
  static const String amperes = 'amperes';
  static const String milliampereHours = 'milliampere_hours';
  static const String watts = 'watts';
}

/// An immutable metric reading with explicit availability and provenance.
class TelemetryReading<T extends Object> {
  const TelemetryReading({
    required this.availability,
    required this.source,
    required this.observedAt,
    this.value,
    this.unit,
    this.reason,
  });

  /// Null whenever [availability] is not [TelemetryAvailability.available].
  final T? value;
  final String? unit;
  final TelemetryAvailability availability;
  final TelemetrySource source;

  /// Capture time of the observation, not the hardware sample time.
  final DateTime observedAt;
  final String? reason;

  bool get isAvailable =>
      availability == TelemetryAvailability.available && value != null;
}

/// A complete, validated battery observation from the native adapter.
class TelemetrySnapshot {
  const TelemetrySnapshot({
    required this.schemaVersion,
    required this.observedAt,
    required this.batteryLevel,
    required this.chargingState,
    required this.plugSource,
    required this.voltage,
    required this.temperature,
    required this.currentNow,
    required this.currentAverage,
    required this.chargeCounter,
  });

  static const int supportedSchemaVersion = 1;

  /// Battery broadcasts are not continuous. Five minutes without an update is
  /// old enough that the UI must stop calling the observation live.
  static const Duration staleAfter = Duration(minutes: 5);

  final int schemaVersion;
  final DateTime observedAt;

  final TelemetryReading<double> batteryLevel;
  final TelemetryReading<BatteryChargingState> chargingState;
  final TelemetryReading<BatteryPlugSource> plugSource;
  final TelemetryReading<double> voltage;
  final TelemetryReading<double> temperature;
  final TelemetryReading<double> currentNow;
  final TelemetryReading<double> currentAverage;
  final TelemetryReading<double> chargeCounter;

  bool isStaleAt(DateTime now) => now.difference(observedAt) > staleAfter;

  /// Parses the versioned native payload defensively.
  ///
  /// A malformed individual metric becomes an invalid reading instead of
  /// crashing. Only a malformed top-level payload or unknown schema version
  /// raises [TelemetryFormatException].
  factory TelemetrySnapshot.fromPlatformPayload(Object? payload) {
    if (payload is! Map) {
      throw const TelemetryFormatException('Telemetry payload must be a map.');
    }

    final Map<String, Object?> fields = _stringKeyedMap(payload);
    final int schemaVersion = _readRequiredInt(fields, 'schemaVersion');
    if (schemaVersion != supportedSchemaVersion) {
      throw TelemetryFormatException(
        'Unsupported telemetry schema version $schemaVersion; '
        'this build supports $supportedSchemaVersion.',
      );
    }

    final int observedAtMillis = _readRequiredInt(fields, 'observedAtMillis');
    if (observedAtMillis <= 0) {
      throw const TelemetryFormatException(
        'Telemetry payload field "observedAtMillis" must be positive.',
      );
    }
    final DateTime observedAt = DateTime.fromMillisecondsSinceEpoch(
      observedAtMillis,
      isUtc: true,
    );

    return TelemetrySnapshot(
      schemaVersion: schemaVersion,
      observedAt: observedAt,
      batteryLevel: _readNumeric(
        fields,
        'batteryLevel',
        TelemetryUnits.percent,
        observedAt,
      ),
      chargingState: _readEnum(
        fields,
        'chargingState',
        _chargingStates,
        observedAt,
      ),
      plugSource: _readEnum(fields, 'plugSource', _plugSources, observedAt),
      voltage: _readNumeric(
        fields,
        'voltage',
        TelemetryUnits.volts,
        observedAt,
      ),
      temperature: _readNumeric(
        fields,
        'temperature',
        TelemetryUnits.celsius,
        observedAt,
      ),
      currentNow: _readNumeric(
        fields,
        'currentNow',
        TelemetryUnits.amperes,
        observedAt,
      ),
      currentAverage: _readNumeric(
        fields,
        'currentAverage',
        TelemetryUnits.amperes,
        observedAt,
      ),
      chargeCounter: _readNumeric(
        fields,
        'chargeCounter',
        TelemetryUnits.milliampereHours,
        observedAt,
      ),
    );
  }
}

const Map<String, BatteryChargingState> _chargingStates =
    <String, BatteryChargingState>{
      'charging': BatteryChargingState.charging,
      'discharging': BatteryChargingState.discharging,
      'not_charging': BatteryChargingState.notCharging,
      'full': BatteryChargingState.full,
    };

const Map<String, BatteryPlugSource> _plugSources = <String, BatteryPlugSource>{
  'none': BatteryPlugSource.none,
  'ac': BatteryPlugSource.ac,
  'usb': BatteryPlugSource.usb,
  'wireless': BatteryPlugSource.wireless,
  'dock': BatteryPlugSource.dock,
};

Map<String, Object?> _stringKeyedMap(Map<dynamic, dynamic> map) => map.map(
  (dynamic key, dynamic value) =>
      MapEntry<String, Object?>(key.toString(), value),
);

class _ReadingEnvelope {
  const _ReadingEnvelope({
    required this.fields,
    required this.availability,
    required this.source,
    required this.observedAt,
    required this.reason,
  });

  factory _ReadingEnvelope.invalid(DateTime observedAt, String reason) =>
      _ReadingEnvelope(
        fields: null,
        availability: TelemetryAvailability.invalid,
        source: TelemetrySource.device,
        observedAt: observedAt,
        reason: reason,
      );

  final Map<String, Object?>? fields;
  final TelemetryAvailability availability;
  final TelemetrySource source;
  final DateTime observedAt;
  final String? reason;

  bool get isUsable =>
      fields != null && availability == TelemetryAvailability.available;
}

_ReadingEnvelope _readEnvelope(
  Object? raw,
  String metric,
  DateTime snapshotObservedAt,
) {
  if (raw is! Map) {
    return _ReadingEnvelope.invalid(
      snapshotObservedAt,
      'Metric "$metric" is missing or malformed.',
    );
  }

  final Map<String, Object?> fields = _stringKeyedMap(raw);
  final TelemetryAvailability? availability = _tryParseAvailability(
    fields['availability'],
  );
  final TelemetrySource? source = _tryParseSource(fields['source']);
  final DateTime? observedAt = _tryParseTimestamp(fields['timestampMillis']);
  final String? reason = _readReason(fields['reason']);

  if (availability == null) {
    return _ReadingEnvelope.invalid(
      snapshotObservedAt,
      'Metric "$metric" has an unknown availability.',
    );
  }
  if (source == null) {
    return _ReadingEnvelope.invalid(
      snapshotObservedAt,
      'Metric "$metric" has an unknown source.',
    );
  }
  if (observedAt == null) {
    return _ReadingEnvelope.invalid(
      snapshotObservedAt,
      'Metric "$metric" has no valid timestampMillis.',
    );
  }

  return _ReadingEnvelope(
    fields: fields,
    availability: availability,
    source: source,
    observedAt: observedAt,
    reason: reason,
  );
}

TelemetryReading<double> _readNumeric(
  Map<String, Object?> snapshot,
  String metric,
  String expectedUnit,
  DateTime snapshotObservedAt,
) {
  final _ReadingEnvelope envelope = _readEnvelope(
    snapshot[metric],
    metric,
    snapshotObservedAt,
  );
  if (!envelope.isUsable) {
    return TelemetryReading<double>(
      availability: envelope.availability,
      source: envelope.source,
      observedAt: envelope.observedAt,
      unit: expectedUnit,
      reason: envelope.reason,
    );
  }

  final Map<String, Object?> fields = envelope.fields!;
  final Object? unit = fields['unit'];
  if (unit != expectedUnit) {
    return _invalidNumeric(
      envelope,
      expectedUnit,
      'Metric "$metric" used unit "$unit"; expected "$expectedUnit".',
    );
  }

  final Object? value = fields['value'];
  if (value is! num || !value.isFinite) {
    return _invalidNumeric(
      envelope,
      expectedUnit,
      'Metric "$metric" has no finite numeric value.',
    );
  }

  return TelemetryReading<double>(
    value: value.toDouble(),
    unit: expectedUnit,
    availability: TelemetryAvailability.available,
    source: envelope.source,
    observedAt: envelope.observedAt,
    reason: envelope.reason,
  );
}

TelemetryReading<double> _invalidNumeric(
  _ReadingEnvelope envelope,
  String unit,
  String reason,
) => TelemetryReading<double>(
  availability: TelemetryAvailability.invalid,
  source: envelope.source,
  observedAt: envelope.observedAt,
  unit: unit,
  reason: reason,
);

TelemetryReading<T> _readEnum<T extends Object>(
  Map<String, Object?> snapshot,
  String metric,
  Map<String, T> values,
  DateTime snapshotObservedAt,
) {
  final _ReadingEnvelope envelope = _readEnvelope(
    snapshot[metric],
    metric,
    snapshotObservedAt,
  );
  if (!envelope.isUsable) {
    return TelemetryReading<T>(
      availability: envelope.availability,
      source: envelope.source,
      observedAt: envelope.observedAt,
      reason: envelope.reason,
    );
  }

  final Object? rawValue = envelope.fields!['value'];
  if (rawValue is! String) {
    return _invalidEnum(envelope, 'Metric "$metric" has no textual value.');
  }

  final T? value = values[rawValue];
  if (value == null) {
    return _invalidEnum(
      envelope,
      'Metric "$metric" has unknown value "$rawValue".',
    );
  }

  return TelemetryReading<T>(
    value: value,
    availability: TelemetryAvailability.available,
    source: envelope.source,
    observedAt: envelope.observedAt,
    reason: envelope.reason,
  );
}

TelemetryReading<T> _invalidEnum<T extends Object>(
  _ReadingEnvelope envelope,
  String reason,
) => TelemetryReading<T>(
  availability: TelemetryAvailability.invalid,
  source: envelope.source,
  observedAt: envelope.observedAt,
  reason: reason,
);

int _readRequiredInt(Map<String, Object?> fields, String key) {
  final Object? value = fields[key];
  if (value is int) return value;
  throw TelemetryFormatException(
    'Telemetry payload field "$key" must be an integer.',
  );
}

TelemetryAvailability? _tryParseAvailability(Object? raw) => switch (raw) {
  'available' => TelemetryAvailability.available,
  'unsupported' => TelemetryAvailability.unsupported,
  'temporarily_unavailable' => TelemetryAvailability.temporarilyUnavailable,
  'invalid' => TelemetryAvailability.invalid,
  'stale' => TelemetryAvailability.stale,
  _ => null,
};

TelemetrySource? _tryParseSource(Object? raw) => switch (raw) {
  'device' => TelemetrySource.device,
  'calculated' => TelemetrySource.calculated,
  'estimated' => TelemetrySource.estimated,
  _ => null,
};

DateTime? _tryParseTimestamp(Object? raw) {
  if (raw is! int || raw <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: true);
}

String? _readReason(Object? raw) {
  if (raw is! String) return null;
  final String trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}
