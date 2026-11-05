import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:voltly/app/theme/app_colors.dart';
import 'package:voltly/core/telemetry/live_current.dart';

/// Live current trace for the last [window]. Draws only real readings; a
/// missing stretch is left empty rather than interpolated.
class CurrentSparkline extends StatelessWidget {
  const CurrentSparkline({
    super.key,
    required this.points,
    required this.color,
    this.window = LiveCurrentController.historyWindow,
    this.height = 72,
  });

  final List<LiveCurrentPoint> points;
  final Color color;
  final Duration window;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SparklinePainter(
            points: points,
            color: color,
            window: window,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.points,
    required this.color,
    required this.window,
  });

  final List<LiveCurrentPoint> points;
  final Color color;
  final Duration window;

  /// Readings further apart than this are drawn as separate segments.
  static const Duration _maxJoinGap = Duration(seconds: 5);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grid = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1;
    for (int i = 1; i < 3; i++) {
      final double y = size.height * i / 3;
      _dashedLine(canvas, Offset(0, y), Offset(size.width, y), grid);
    }
    if (points.isEmpty) return;

    double minV = points.first.milliamps;
    double maxV = minV;
    for (final LiveCurrentPoint p in points) {
      minV = math.min(minV, p.milliamps);
      maxV = math.max(maxV, p.milliamps);
    }
    final double span = math.max(maxV - minV, 50);
    final double pad = span * 0.18;
    final double lo = minV - pad;
    final double hi = maxV + pad;

    final DateTime end = points.last.observedAt;
    final DateTime start = end.subtract(window);
    final double windowMs = window.inMilliseconds.toDouble();

    Offset toOffset(LiveCurrentPoint p) {
      final double t = p.observedAt.difference(start).inMilliseconds / windowMs;
      final double x = (t.clamp(0.0, 1.0)) * size.width;
      final double y =
          size.height - ((p.milliamps - lo) / (hi - lo)) * size.height;
      return Offset(x, y);
    }

    // Split at gaps so the trace never implies continuous data.
    final List<List<Offset>> segments = <List<Offset>>[<Offset>[]];
    LiveCurrentPoint? previous;
    for (final LiveCurrentPoint p in points) {
      if (previous != null &&
          p.observedAt.difference(previous.observedAt) > _maxJoinGap) {
        segments.add(<Offset>[]);
      }
      segments.last.add(toOffset(p));
      previous = p;
    }

    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0),
        ],
      ).createShader(Offset.zero & size);

    for (final List<Offset> segment in segments) {
      if (segment.isEmpty) continue;
      if (segment.length == 1) {
        canvas.drawCircle(segment.first, 2.2, Paint()..color = color);
        continue;
      }
      final Path path = _smoothPath(segment);
      final Path area = Path.from(path)
        ..lineTo(segment.last.dx, size.height)
        ..lineTo(segment.first.dx, size.height)
        ..close();
      canvas.drawPath(area, fill);
      canvas.drawPath(path, line);
    }

    final Offset head = toOffset(points.last);
    canvas.drawCircle(head, 6, Paint()..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(head, 3, Paint()..color = color);
  }

  static Path _smoothPath(List<Offset> pts) {
    final Path path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final Offset a = pts[i - 1];
      final Offset b = pts[i];
      final double midX = (a.dx + b.dx) / 2;
      path.cubicTo(midX, a.dy, midX, b.dy, b.dx, b.dy);
    }
    return path;
  }

  static void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const double dash = 3;
    const double gap = 5;
    double x = a.dx;
    while (x < b.dx) {
      canvas.drawLine(
        Offset(x, a.dy),
        Offset(math.min(x + dash, b.dx), a.dy),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.points != points || old.color != color || old.window != window;
}

/// Circular battery-level gauge. Decorative; the caller supplies semantics.
class BatteryLevelRing extends StatelessWidget {
  const BatteryLevelRing({
    super.key,
    required this.fraction,
    required this.color,
    required this.child,
    this.size = 120,
  });

  /// 0..1, or null when the level is unavailable.
  final double? fraction;
  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: fraction ?? 0),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double value, Widget? child) =>
            CustomPaint(
              painter: _RingPainter(
                fraction: fraction == null ? null : value,
                color: color,
              ),
              child: child,
            ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.fraction, required this.color});

  final double? fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 10;
    final Rect rect = (Offset.zero & size).deflate(stroke / 2);
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.surfaceHighlight;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    final double? f = fraction;
    if (f == null || f <= 0) return;
    const double startAngle = -math.pi / 2;
    final double sweep = math.pi * 2 * f.clamp(0.0, 1.0);
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: const GradientRotation(startAngle),
        colors: <Color>[color.withValues(alpha: 0.45), color],
        stops: <double>[0, f.clamp(0.01, 1.0)],
      ).createShader(rect);
    canvas.drawArc(rect, startAngle, sweep, false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.color != color;
}
