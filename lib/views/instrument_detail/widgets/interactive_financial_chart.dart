import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../models/candle_model.dart';

enum ChartDisplayMode { candlestick, lineArea }

/// Institutional-grade interactive financial chart supporting Candlestick and Line Area modes,
/// volume histograms, multi-timeframe selection, and touch scrubbing with crosshair tooltips.
class InteractiveFinancialChart extends StatefulWidget {
  const InteractiveFinancialChart({
    super.key,
    required this.candles,
    required this.activeTimeframe,
    required this.onTimeframeChanged,
    this.onCandleScrubbed,
    this.height = 260,
  });

  final List<CandleModel> candles;
  final MarketTimeframe activeTimeframe;
  final ValueChanged<MarketTimeframe> onTimeframeChanged;
  final ValueChanged<CandleModel?>? onCandleScrubbed;
  final double height;

  @override
  State<InteractiveFinancialChart> createState() =>
      _InteractiveFinancialChartState();
}

class _InteractiveFinancialChartState extends State<InteractiveFinancialChart> {
  ChartDisplayMode _mode = ChartDisplayMode.candlestick;
  int? _scrubbedIndex;

  void _handleTouch(Offset localPosition, double chartWidth) {
    if (widget.candles.isEmpty || chartWidth <= 0) return;

    final count = widget.candles.length;
    final stepX = chartWidth / count;
    final index = (localPosition.dx / stepX).floor().clamp(0, count - 1);

    if (index != _scrubbedIndex) {
      AppHaptics.selection();
      setState(() => _scrubbedIndex = index);
      widget.onCandleScrubbed?.call(widget.candles[index]);
    }
  }

  void _clearTouch() {
    if (_scrubbedIndex != null) {
      setState(() => _scrubbedIndex = null);
      widget.onCandleScrubbed?.call(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Controls Row: Mode Toggle & Active Scrub Information
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Scrub Tooltip or Timeframe Label
              if (_scrubbedIndex != null &&
                  _scrubbedIndex! < widget.candles.length) ...[
                Builder(
                  builder: (_) {
                    final c = widget.candles[_scrubbedIndex!];
                    final isBull = c.isBullish;
                    final color = isBull ? AppColors.bullGreen : AppColors.bearRed;
                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '\$${c.close.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isBull ? '+' : ''}${c.changePercent.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ] else ...[
                Text(
                  '${widget.activeTimeframe.label} Historical Overview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],

              // Chart Mode Switcher (Candles vs Area Line)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _ModeButton(
                      icon: Icons.candlestick_chart_rounded,
                      isSelected: _mode == ChartDisplayMode.candlestick,
                      onTap: () {
                        AppHaptics.selection();
                        setState(() => _mode = ChartDisplayMode.candlestick);
                      },
                    ),
                    _ModeButton(
                      icon: Icons.show_chart_rounded,
                      isSelected: _mode == ChartDisplayMode.lineArea,
                      onTap: () {
                        AppHaptics.selection();
                        setState(() => _mode = ChartDisplayMode.lineArea);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Main Chart Canvas with Gesture Detection
          LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onHorizontalDragStart: (details) =>
                    _handleTouch(details.localPosition, constraints.maxWidth),
                onHorizontalDragUpdate: (details) =>
                    _handleTouch(details.localPosition, constraints.maxWidth),
                onHorizontalDragEnd: (_) => _clearTouch(),
                onTapDown: (details) =>
                    _handleTouch(details.localPosition, constraints.maxWidth),
                onTapUp: (_) => _clearTouch(),
                onTapCancel: () => _clearTouch(),
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: widget.height,
                  child: CustomPaint(
                    painter: _FinancialChartPainter(
                      candles: widget.candles,
                      mode: _mode,
                      scrubbedIndex: _scrubbedIndex,
                      isDark: isDark,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          // Timeframe Selector Row (1D, 1W, 1M, 3M, 1Y)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: MarketTimeframe.values.map((tf) {
              final isSelected = widget.activeTimeframe == tf;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (!isSelected) {
                        AppHaptics.selection();
                        widget.onTimeframeChanged(tf);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : (isDark
                                ? AppColors.darkSurfaceSecondary
                                : AppColors.lightSurfaceSecondary),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : borderColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tf.code,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected
              ? Colors.white
              : (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
        ),
      ),
    );
  }
}

class _FinancialChartPainter extends CustomPainter {
  const _FinancialChartPainter({
    required this.candles,
    required this.mode,
    required this.scrubbedIndex,
    required this.isDark,
  });

  final List<CandleModel> candles;
  final ChartDisplayMode mode;
  final int? scrubbedIndex;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final double volumeHeight = size.height * 0.18;
    final double chartHeight = size.height - volumeHeight - 8;

    double minPrice = candles.map((c) => c.low).reduce(math.min);
    double maxPrice = candles.map((c) => c.high).reduce(math.max);
    double maxVolume = candles.map((c) => c.volume).reduce(math.max);

    if (maxPrice == minPrice) {
      maxPrice += 0.5;
      minPrice -= 0.5;
    }
    if (maxVolume <= 0) maxVolume = 1;

    final double priceRange = maxPrice - minPrice;
    final int count = candles.length;
    final double stepX = size.width / count;

    double getY(double price) {
      final normalized = (price - minPrice) / priceRange;
      return chartHeight - (normalized * chartHeight);
    }

    // 1. Draw subtle background horizontal price grid guidelines
    final gridPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder)
          .withValues(alpha: 0.4)
      ..strokeWidth = 0.8;

    for (int g = 1; g <= 3; g++) {
      final y = (chartHeight / 4.0) * g;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw Volume Histogram at bottom
    final barSpacing = math.max(0.5, stepX * 0.2);
    final barWidth = math.max(1.0, stepX - barSpacing);

    for (int i = 0; i < count; i++) {
      final c = candles[i];
      final isBull = c.isBullish;
      final volColor = (isBull ? AppColors.bullGreen : AppColors.bearRed)
          .withValues(alpha: 0.35);

      final volNormalized = c.volume / maxVolume;
      final barH = math.max(2.0, volNormalized * volumeHeight);
      final x = i * stepX + (stepX - barWidth) / 2.0;
      final y = size.height - barH;

      final rect = Rect.fromLTWH(x, y, barWidth, barH);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        Paint()..color = volColor,
      );
    }

    // 3. Draw Chart according to mode (Candlestick vs Line Area)
    if (mode == ChartDisplayMode.candlestick) {
      for (int i = 0; i < count; i++) {
        final c = candles[i];
        final isBull = c.isBullish;
        final color = isBull ? AppColors.bullGreen : AppColors.bearRed;

        final centerX = i * stepX + (stepX / 2.0);
        final highY = getY(c.high);
        final lowY = getY(c.low);
        final openY = getY(c.open);
        final closeY = getY(c.close);

        // Thin wick line
        final wickPaint = Paint()
          ..color = color
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(centerX, highY), Offset(centerX, lowY), wickPaint);

        // Candle body rectangle
        final bodyTop = math.min(openY, closeY);
        final bodyBottom = math.max(openY, closeY);
        final bodyHeight = math.max(1.8, bodyBottom - bodyTop);

        final candleWidth = math.max(2.0, stepX * 0.72);
        final bodyRect = Rect.fromCenter(
          center: Offset(centerX, bodyTop + bodyHeight / 2.0),
          width: candleWidth,
          height: bodyHeight,
        );

        final bodyPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.5)),
          bodyPaint,
        );
      }
    } else {
      // Line Area Mode
      final linePath = Path();
      final areaPath = Path();

      final firstX = stepX / 2.0;
      final firstY = getY(candles.first.close);

      linePath.moveTo(firstX, firstY);
      areaPath.moveTo(firstX, chartHeight);
      areaPath.lineTo(firstX, firstY);

      for (int i = 0; i < count - 1; i++) {
        final x1 = i * stepX + (stepX / 2.0);
        final y1 = getY(candles[i].close);
        final x2 = (i + 1) * stepX + (stepX / 2.0);
        final y2 = getY(candles[i + 1].close);

        final controlX = (x1 + x2) / 2.0;

        linePath.cubicTo(controlX, y1, controlX, y2, x2, y2);
        areaPath.cubicTo(controlX, y1, controlX, y2, x2, y2);
      }

      final lastX = (count - 1) * stepX + (stepX / 2.0);
      areaPath.lineTo(lastX, chartHeight);
      areaPath.close();

      final isTrendPositive = candles.last.close >= candles.first.open;
      final trendColor =
          isTrendPositive ? AppColors.bullGreen : AppColors.bearRed;

      // Area gradient
      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            trendColor.withValues(alpha: 0.3),
            trendColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
        ..style = PaintingStyle.fill;

      canvas.drawPath(areaPath, areaPaint);

      // Line stroke
      final strokePaint = Paint()
        ..color = trendColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(linePath, strokePaint);
    }

    // 4. Draw Crosshair & Touch Scrubbing Elements
    if (scrubbedIndex != null &&
        scrubbedIndex! >= 0 &&
        scrubbedIndex! < count) {
      final scrubCandle = candles[scrubbedIndex!];
      final scrubX = scrubbedIndex! * stepX + (stepX / 2.0);
      final scrubY = getY(scrubCandle.close);

      // Vertical dashed line
      final crosshairPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.45)
        ..strokeWidth = 1.0;

      double startY = 0;
      while (startY < size.height) {
        canvas.drawLine(
          Offset(scrubX, startY),
          Offset(scrubX, startY + 4),
          crosshairPaint,
        );
        startY += 8;
      }

      // Horizontal price line
      canvas.drawLine(
        Offset(0, scrubY),
        Offset(size.width, scrubY),
        crosshairPaint,
      );

      // Indicator pulse dot on the scrubbed point
      final dotColor =
          scrubCandle.isBullish ? AppColors.bullGreen : AppColors.bearRed;

      canvas.drawCircle(
        Offset(scrubX, scrubY),
        6.0,
        Paint()..color = dotColor.withValues(alpha: 0.3),
      );
      canvas.drawCircle(
        Offset(scrubX, scrubY),
        3.5,
        Paint()..color = dotColor,
      );
      canvas.drawCircle(
        Offset(scrubX, scrubY),
        1.5,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FinancialChartPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.mode != mode ||
        oldDelegate.scrubbedIndex != scrubbedIndex ||
        oldDelegate.isDark != isDark;
  }
}
