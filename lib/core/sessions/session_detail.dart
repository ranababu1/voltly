import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';

/// A stored session with its retained samples, in observation order.
class SessionDetail {
  const SessionDetail({required this.session, required this.samples});

  final ChargingSession session;
  final List<TelemetrySample> samples;
}
