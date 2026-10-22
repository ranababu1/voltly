import 'package:voltly/core/sessions/telemetry_sample.dart';

/// Stored sessions normally receive a snapshot per minute. A longer interval is
/// treated as a chart break so the line never implies uninterrupted sampling.
const Duration sessionChartGapThreshold = Duration(minutes: 5);

enum SessionChartMetric { batteryLevel, currentNow, temperature, power }

extension SessionChartMetricPresentation on SessionChartMetric {
  String get label => switch (this) {
    SessionChartMetric.batteryLevel => 'Battery level',
    SessionChartMetric.currentNow => 'Current now',
    SessionChartMetric.temperature => 'Temperature',
    SessionChartMetric.power => 'Battery-side power',
  };

  String get unit => switch (this) {
    SessionChartMetric.batteryLevel => '%',
    SessionChartMetric.currentNow => 'A',
    SessionChartMetric.temperature => '°C',
    SessionChartMetric.power => 'W',
  };

  String get spokenUnit => switch (this) {
    SessionChartMetric.batteryLevel => 'percent',
    SessionChartMetric.currentNow => 'amperes',
    SessionChartMetric.temperature => 'degrees Celsius',
    SessionChartMetric.power => 'watts',
  };

  int get decimals => switch (this) {
    SessionChartMetric.batteryLevel => 0,
    SessionChartMetric.currentNow => 3,
    SessionChartMetric.temperature => 1,
    SessionChartMetric.power => 2,
  };

  double? valueOf(TelemetrySample sample) => switch (this) {
    SessionChartMetric.batteryLevel => sample.batteryLevelPercent,
    SessionChartMetric.currentNow => sample.currentAmps,
    SessionChartMetric.temperature => sample.temperatureCelsius,
    SessionChartMetric.power => sample.powerWatts,
  };

  String formatValue(double value) =>
      '${value.toStringAsFixed(decimals)} $unit';
}

class SessionChartPoint {
  const SessionChartPoint({required this.observedAt, required this.value});

  final DateTime observedAt;
  final double value;
}

/// Chart-ready stored values split into continuous segments.
///
/// A missing/unavailable value or a gap longer than [gapThreshold] ends the
/// current segment. Values are never interpolated.
class SessionChartData {
  SessionChartData._({
    required this.metric,
    required this.segments,
    required this.points,
    required this.hasUnavailableSamples,
  });

  factory SessionChartData.fromSamples(
    SessionChartMetric metric,
    Iterable<TelemetrySample> samples, {
    Duration gapThreshold = sessionChartGapThreshold,
  }) {
    final List<TelemetrySample> ordered = samples.toList()
      ..sort(
        (TelemetrySample a, TelemetrySample b) =>
            a.observedAt.compareTo(b.observedAt),
      );
    final List<List<SessionChartPoint>> segments = <List<SessionChartPoint>>[];
    final List<SessionChartPoint> points = <SessionChartPoint>[];
    List<SessionChartPoint> current = <SessionChartPoint>[];
    DateTime? lastTime;
    bool hasUnavailable = false;

    void closeSegment() {
      if (current.isNotEmpty) {
        segments.add(List<SessionChartPoint>.unmodifiable(current));
        current = <SessionChartPoint>[];
      }
    }

    for (final TelemetrySample sample in ordered) {
      final double? value = metric.valueOf(sample);
      if (value == null || !value.isFinite) {
        hasUnavailable = true;
        closeSegment();
        lastTime = null;
        continue;
      }
      if (lastTime != null &&
          sample.observedAt.difference(lastTime) > gapThreshold) {
        closeSegment();
      }
      final SessionChartPoint point = SessionChartPoint(
        observedAt: sample.observedAt,
        value: value,
      );
      current.add(point);
      points.add(point);
      lastTime = sample.observedAt;
    }
    closeSegment();

    return SessionChartData._(
      metric: metric,
      segments: List<List<SessionChartPoint>>.unmodifiable(segments),
      points: List<SessionChartPoint>.unmodifiable(points),
      hasUnavailableSamples: hasUnavailable,
    );
  }

  final SessionChartMetric metric;
  final List<List<SessionChartPoint>> segments;
  final List<SessionChartPoint> points;
  final bool hasUnavailableSamples;

  bool get hasData => points.isNotEmpty;
  bool get hasGaps => segments.length > 1;
  int get pointCount => points.length;

  double? get minimum => points.isEmpty
      ? null
      : points.map((SessionChartPoint p) => p.value).reduce(_min);
  double? get maximum => points.isEmpty
      ? null
      : points.map((SessionChartPoint p) => p.value).reduce(_max);
  double? get latest => points.isEmpty ? null : points.last.value;

  String get summary {
    if (!hasData) {
      return 'No stored ${metric.label.toLowerCase()} samples.';
    }
    final String latestText = metric.formatValue(latest!);
    final String rangeText =
        '${metric.formatValue(minimum!)} to ${metric.formatValue(maximum!)}';
    final int breakCount = segments.length - 1;
    final String gapText = breakCount == 0
        ? 'No sampling breaks.'
        : '$breakCount sampling ${breakCount == 1 ? 'break' : 'breaks'}.';
    final String unavailableText = hasUnavailableSamples
        ? ' Some samples had unavailable values.'
        : '';
    return '$pointCount stored samples. Latest $latestText. '
        'Range $rangeText. $gapText$unavailableText';
  }

  String get semanticsLabel =>
      '${metric.label} trend. $summary Values come from stored samples only; '
      'gaps are not interpolated.';

  static double _min(double a, double b) => a < b ? a : b;
  static double _max(double a, double b) => a > b ? a : b;
}
