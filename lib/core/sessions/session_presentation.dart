import 'package:voltly/core/sessions/charging_session.dart';

String describeSessionStorageError(Object error) {
  if (error is UnsupportedError) {
    return error.message ?? 'Unsupported session database version.';
  }
  if (error is StateError) {
    return error.message;
  }
  return 'Local session storage is unavailable (${error.runtimeType}).';
}

String formatSessionDateTime(DateTime timestamp) {
  final DateTime local = timestamp.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String formatSessionDuration(Duration duration) {
  if (duration <= Duration.zero) return 'Under a minute';
  if (duration.inMinutes < 1) return 'Under a minute';
  if (duration.inHours < 1) return '${duration.inMinutes} min';
  final int minutes = duration.inMinutes.remainder(60);
  return minutes == 0
      ? '${duration.inHours} h'
      : '${duration.inHours} h $minutes min';
}

String formatSessionLevel(double? value) =>
    value == null ? 'Unavailable' : '${value.toStringAsFixed(0)}%';

String formatSessionLevelChange(ChargingSession session) {
  final double? change = session.levelChangePercent;
  if (change == null) return 'Level change unavailable';
  final String formatted = change.abs().toStringAsFixed(0);
  if (change > 0) return '+$formatted%';
  if (change < 0) return '-$formatted%';
  return '0%';
}

String sessionStateLabel(ChargingSession session) => switch (session.state) {
  ChargingSessionState.active => 'Recording',
  ChargingSessionState.completed => 'Completed',
  ChargingSessionState.interrupted => 'Interrupted',
};

String sessionEndLabel(ChargingSession session) {
  if (session.isActive) return 'In progress';
  if (session.state == ChargingSessionState.interrupted) {
    return 'Ended without a clean charging transition';
  }
  return 'Charged ${formatSessionLevel(session.startLevelPercent)} to '
      '${formatSessionLevel(session.endLevelPercent)}';
}

String? sessionCoverageLabel(ChargingSession session) {
  if (session.samplesPruned) return 'Older samples pruned';
  if (session.hasSamplingGaps) return 'Sampling gaps';
  if (session.state == ChargingSessionState.interrupted) {
    return 'Partial session';
  }
  return null;
}

String sessionSemantics(ChargingSession session) {
  final StringBuffer buffer = StringBuffer(
    'Charging session. ${sessionStateLabel(session)}. '
    'Started ${formatSessionDateTime(session.startedAt)}. ',
  );
  if (session.isActive) {
    buffer.write('In progress. ');
  } else if (session.endedAt != null) {
    buffer.write(
      'Ended ${formatSessionDateTime(session.endedAt!)}. '
      'Duration ${formatSessionDuration(session.duration!)}. ',
    );
  }
  final int sampleCount = session.sampleCount;
  buffer.write(
    'Start level ${formatSessionLevel(session.startLevelPercent)}. '
    'End level ${formatSessionLevel(session.endLevelPercent)}. '
    '$sampleCount sample${sampleCount == 1 ? '' : 's'}. ',
  );
  final String? coverage = sessionCoverageLabel(session);
  if (coverage != null) buffer.write('$coverage. ');
  return buffer.toString();
}
