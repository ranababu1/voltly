/// Thrown when a native telemetry payload cannot be interpreted safely.
///
/// Individual missing or malformed metrics degrade to an explicit
/// unavailable/invalid reading instead. This exception is reserved for a
/// payload-level contract failure, such as an unsupported schema version.
class TelemetryFormatException implements Exception {
  const TelemetryFormatException(this.message);

  final String message;

  @override
  String toString() => 'TelemetryFormatException: $message';
}
