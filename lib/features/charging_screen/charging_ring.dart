import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:voltly/app/theme/app_colors.dart';

/// A tick-mark gauge for the battery level with a slow, subtle glow sweep.
///
/// The sweep runs only while [animate] is true and the platform has not
/// requested reduced motion. The ring is decorative; the level text inside
/// it carries the meaning for screen readers.
class ChargingRing extends StatefulWidget {
  const ChargingRing({
    super.key,
    required this.levelPercent,
    required this.animate,
    required this.child,
  });

  /// Null when the level is unavailable: every tick is drawn unfilled.
  final double? levelPercent;
  final bool animate;
  final Widget child;

  @override
  State<ChargingRing> createState() => _ChargingRingState();
}

class _ChargingRingState extends State<ChargingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant ChargingRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (widget.animate && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned.fill(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: ChargingRingPainter(
                  fraction: widget.levelPercent == null
                      ? 0
                      : (widget.levelPercent!.clamp(0, 100) / 100).toDouble(),
                  sweep: _controller,
                  sweeping: widget.animate,
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class ChargingRingPainter extends CustomPainter {
  ChargingRingPainter({
    required this.fraction,
    required this.sweep,
    required this.sweeping,
  }) : super(repaint: sweep);

  static const int tickCount = 44;

  /// The arc opens at the bottom, like a gauge: 270° starting at 7:30.
  static const double startAngle = math.pi * 0.75;
  static const double sweepAngle = math.pi * 1.5;

  final double fraction;
  final Animation<double> sweep;
  final bool sweeping;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = math.min(size.width, size.height) / 2;
    final double outer = radius - 2;
    final double tickLength = math.max(6, radius * 0.075);
    final double inner = outer - tickLength;
    final int filled = (fraction * tickCount).round();

    // The glow head travels across the filled ticks, then rests briefly.
    final double head = sweep.value * 1.25 * math.max(filled, 1);

    final Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2.5, radius * 0.022);

    for (int i = 0; i < tickCount; i++) {
      final double t = i / (tickCount - 1);
      final double angle = startAngle + sweepAngle * t;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      final bool isFilled = i < filled;

      if (isFilled) {
        double alpha = 1;
        if (sweeping) {
          final double distance = (head - i).abs();
          final double glow = math.exp(-(distance * distance) / 6);
          alpha = 0.7 + 0.3 * glow;
        }
        paint.color = AppColors.mint.withValues(alpha: alpha);
      } else {
        paint.color = AppColors.outline;
      }

      canvas.drawLine(
        center + direction * inner,
        center + direction * outer,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChargingRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.sweeping != sweeping;
}
