import 'package:flutter/material.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/app/theme/app_tokens.dart';
import 'package:voltly/core/sessions/charging_session.dart';
import 'package:voltly/core/sessions/session_chart_data.dart';
import 'package:voltly/core/sessions/telemetry_sample.dart';

/// Stored-sample trend card. Lines break at gaps; no interpolation is drawn.
class SessionTrendCard extends StatelessWidget {
  const SessionTrendCard({
    super.key,
    required this.metric,
    required this.samples,
    required this.session,
  });

  final SessionChartMetric metric;
  final List<TelemetrySample> samples;
  final ChargingSession session;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final SessionChartData data = SessionChartData.fromSamples(metric, samples);
    final Color color = switch (metric) {
      SessionChartMetric.batteryLevel => AppColors.mint,
      SessionChartMetric.currentNow => AppColors.warning,
      SessionChartMetric.temperature => AppColors.danger,
      SessionChartMetric.power => AppColors.mint,
    };

    return Semantics(
      container: true,
      label:
          '${data.semanticsLabel}'
          '${session.hasSamplingGaps ? ' This session has telemetry gaps.' : ''}'
          '${session.samplesPruned ? ' Older samples were pruned.' : ''}',
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(metric.label, style: textTheme.titleMedium),
                    Text(
                      data.hasData
                          ? '${data.pointCount} stored '
                                '${data.pointCount == 1 ? 'sample' : 'samples'}'
                          : 'No stored samples',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(data.summary, style: textTheme.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                if (data.hasData)
                  SizedBox(
                    height: 152,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _TrendPainter(
                        data: data,
                        lineColor: color,
                        gridColor: AppColors.outline,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No stored ${metric.label.toLowerCase()} values.',
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (data.hasGaps || data.hasUnavailableSamples) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Line breaks mark sampling gaps or unavailable values. '
                    'No values are interpolated.',
                    style: textTheme.bodySmall,
                  ),
                ],
                if (session.hasSamplingGaps && !data.hasGaps) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'This session has telemetry gaps. Only breaks visible in '
                    'retained samples are drawn.',
                    style: textTheme.bodySmall,
                  ),
                ],
                if (session.samplesPruned) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Older samples were pruned by retention. This chart covers '
                    'retained samples only.',
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter({
    required this.data,
    required this.lineColor,
    required this.gridColor,
  });

  final SessionChartData data;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.points.isEmpty || size.isEmpty) return;

    final Rect plot = Rect.fromLTRB(8, 8, size.width - 8, size.height - 8);
    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final double y = plot.top + (plot.height * i / 3);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    final double minimum = data.minimum!;
    final double maximum = data.maximum!;
    final double range = maximum - minimum;
    final double padding = range == 0
        ? (minimum.abs() == 0 ? 1 : minimum.abs() * 0.1)
        : range * 0.08;
    final double low = minimum - padding;
    final double high = maximum + padding;
    final double valueSpan = high - low;

    final DateTime firstTime = data.points.first.observedAt;
    final DateTime lastTime = data.points.last.observedAt;
    final int timeSpan = lastTime.difference(firstTime).inMilliseconds;
    final int effectiveTimeSpan = timeSpan == 0 ? 1 : timeSpan;

    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final Paint dotPaint = Paint()..color = lineColor;

    Offset offsetFor(SessionChartPoint point) {
      final double x =
          plot.left +
          (point.observedAt.difference(firstTime).inMilliseconds /
                  effectiveTimeSpan) *
              plot.width;
      final double normalized = (point.value - low) / valueSpan;
      final double y = plot.bottom - normalized * plot.height;
      return Offset(x, y);
    }

    for (final List<SessionChartPoint> segment in data.segments) {
      if (segment.isEmpty) continue;
      if (segment.length == 1) {
        canvas.drawCircle(offsetFor(segment.first), 2.5, dotPaint);
        continue;
      }
      final Path path = Path()
        ..moveTo(offsetFor(segment.first).dx, offsetFor(segment.first).dy);
      for (final SessionChartPoint point in segment.skip(1)) {
        final Offset offset = offsetFor(point);
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(path, linePaint);
      for (final SessionChartPoint point in segment) {
        canvas.drawCircle(offsetFor(point), 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.lineColor != lineColor;
}
