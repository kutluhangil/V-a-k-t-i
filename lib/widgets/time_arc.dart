import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';
import '../data/models/tip.dart';

/// The brand's signature "zaman yayı" (time arc): a thin half-arc with a saffron
/// dot whose position marks the moment of day a tip belongs to (§3.4).
/// Morning sits left, midday at the top, evening right.
class TimeArc extends StatelessWidget {
  const TimeArc({
    super.key,
    required this.position,
    this.width = 132,
    this.dotColor = AppColors.saffron,
    this.arcColor,
    this.animate = false,
  });

  /// 0.0 = far left (early), 0.5 = top (midday), 1.0 = far right (late).
  final double position;
  final double width;
  final Color dotColor;
  final Color? arcColor;

  /// When true, the moment dot sweeps in from the left on first build —
  /// a subtle "golden hour" reveal.
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final line =
        arcColor ?? Theme.of(context).dividerColor.withValues(alpha: 0.9);
    final target = position.clamp(0.0, 1.0);

    Widget paint(double p) => SizedBox(
      width: width,
      height: width / 2 + 8,
      child: CustomPaint(
        painter: _ArcPainter(position: p, arcColor: line, dotColor: dotColor),
      ),
    );

    if (!animate) return paint(target);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.06, end: target),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => paint(value),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.position,
    required this.arcColor,
    required this.dotColor,
  });

  final double position;
  final Color arcColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 1.5;
    final r = size.width / 2 - stroke;
    final cx = size.width / 2;
    final cy = size.height - 4;
    final center = Offset(cx, cy);
    final rect = Rect.fromCircle(center: center, radius: r);

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    // Top half: from angle pi (left) sweeping pi to 2pi (right).
    canvas.drawArc(rect, math.pi, math.pi, false, arcPaint);

    // Faint end ticks.
    final tickPaint = Paint()
      ..color = arcColor
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - r, cy), Offset(cx - r, cy - 4), tickPaint);
    canvas.drawLine(Offset(cx + r, cy), Offset(cx + r, cy - 4), tickPaint);

    // The moment dot.
    final theta = math.pi + position * math.pi;
    final dot = Offset(cx + r * math.cos(theta), cy + r * math.sin(theta));
    canvas.drawCircle(
      dot,
      5.5,
      Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      dot,
      5.5,
      Paint()
        ..color = dotColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.position != position ||
      old.arcColor != arcColor ||
      old.dotColor != dotColor;
}

/// Deterministic time-of-day position for a tip: a category base (morning /
/// midday / evening) plus a small stable jitter from the id, so each card keeps
/// the same dot position every time it appears.
double arcPositionForTip(Tip tip) {
  const morning = 0.2, midday = 0.5, evening = 0.8;
  const base = <String, double>{
    // wellness
    'energy': morning,
    'immunity': morning,
    'hydration': morning,
    'skin': morning,
    'digestion': midday,
    'sleep': evening,
    // communication
    'cooperation': midday,
    'confidence': midday,
    'boundaries': midday,
    'emotions': evening,
    'earlyYears': evening,
  };
  final b = base[tip.category] ?? midday;
  final h = tip.id.codeUnits.fold<int>(0, (a, c) => (a * 31 + c) & 0x7fffffff);
  final jitter = (h % 1000) / 1000 * 0.16 - 0.08; // ±0.08
  return (b + jitter).clamp(0.06, 0.94);
}
