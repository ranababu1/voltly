import 'package:voltly/core/sessions/battery_time_estimate.dart';
import 'package:voltly/core/sessions/session_presentation.dart';

String estimateTitle(BatteryEstimateKind kind) => switch (kind) {
  BatteryEstimateKind.timeToFull => 'Time to full',
  BatteryEstimateKind.timeToEmpty => 'Time to empty',
};

/// Rounded to five minutes to avoid false precision.
String formatBatteryEstimateTime(BatteryTimeEstimate estimate) {
  if (estimate.targetReached) {
    return estimate.kind == BatteryEstimateKind.timeToFull ? 'Full' : 'Empty';
  }
  final int rounded = (estimate.remaining.inMinutes / 5).round() * 5;
  if (rounded < 5) return 'Under 5 min';
  if (rounded < 60) return 'About $rounded min';
  final int hours = rounded ~/ 60;
  final int minutes = rounded.remainder(60);
  return minutes == 0 ? 'About $hours h' : 'About $hours h $minutes min';
}

String estimateAssumption(BatteryTimeEstimate estimate) =>
    'Approximate, from ${estimate.sampleCount} stored '
    '${estimate.sampleCount == 1 ? 'sample' : 'samples'} over '
    '${formatSessionDuration(estimate.observedWindow)}. Assumes a steady rate.';

String? estimateCoverageNote(BatteryTimeEstimate estimate) {
  if (estimate.sessionSamplesPruned) {
    return 'Older samples were pruned by retention; this estimate uses the '
        'retained recent window.';
  }
  if (estimate.sessionHadSamplingGaps) {
    return 'This session had earlier sampling gaps; only the latest '
        'contiguous window is used.';
  }
  return null;
}

String estimateSemantics(BatteryTimeEstimate estimate) {
  final StringBuffer buffer = StringBuffer(
    '${estimateTitle(estimate.kind)} estimate. '
    '${formatBatteryEstimateTime(estimate)}. '
    '${estimateAssumption(estimate)} ',
  );
  final String? coverage = estimateCoverageNote(estimate);
  if (coverage != null) buffer.write('$coverage ');
  buffer.write('This is not charger input power or battery health.');
  return buffer.toString();
}
