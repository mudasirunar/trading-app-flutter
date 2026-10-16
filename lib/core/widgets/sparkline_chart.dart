import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// High-performance mini sparkline curve painter.
/// Renders smooth bezier curves with gradient area fill matching the price trend.
class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.data,
    this.width = 72,
    this.height = 32,
    this.lineWidth = 1.8,
    this.showGradient = true,
    this.overrideColor,
  });

  final List<double> data;
  final double width;
  final double height;
  final double lineWidth;
  final bool showGradient;
  final Color? overrideColor;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    final isPositive = data.length >= 2 ? data.last >= data.first : true;
    final color = overrideColor ??
        (isPositive ? AppColors.bullGreen : AppColors.bearRed);

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          data: data,
          lineColor: color,
          lineWidth: lineWidth,
          showGradient: showGradient,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.data,
    required this.lineColor,
    required this.lineWidth,
    required this.showGradient,
  });

  final List<double> data;
  final Color lineColor;
  final double lineWidth;
  final bool showGradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    double minVal = data.reduce(math.min);
    double maxVal = data.reduce(math.max);

    // If all points are identical, add a minimal vertical spread
    if (maxVal == minVal) {
      maxVal += 0.01;
      minVal -= 0.01;
    }

    final double range = maxVal - minVal;
    final double stepX = size.width / (data.length - 1);

    final linePath = Path();
    final areaPath = Path();

    double getY(double val) {
      // Invert Y so highest value is at the top (with 2px padding)
      final normalized = (val - minVal) / range;
      return size.height - (normalized * (size.height - 4)) - 2;
    }

    final firstY = getY(data.first);
    linePath.moveTo(0, firstY);
    areaPath.moveTo(0, size.height);
    areaPath.lineTo(0, firstY);

    for (int i = 0; i < data.length - 1; i++) {
      final x1 = i * stepX;
      final y1 = getY(data[i]);
      final x2 = (i + 1) * stepX;
      final y2 = getY(data[i + 1]);

      final controlX = (x1 + x2) / 2.0;

      linePath.cubicTo(controlX, y1, controlX, y2, x2, y2);
      areaPath.cubicTo(controlX, y1, controlX, y2, x2, y2);
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    // Draw subtle gradient underfill
    if (showGradient) {
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.25),
            lineColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(areaPath, gradientPaint);
    }

    // Draw main stroke line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    if (oldDelegate.data.length != data.length) return true;
    if (oldDelegate.lineColor != lineColor) return true;
    for (int i = 0; i < data.length; i++) {
      if (oldDelegate.data[i] != data[i]) return true;
    }
    return false;
  }
}
