import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/sparkline_chart.dart';
import '../../../models/instrument_model.dart';
import '../../instrument_detail/instrument_detail_screen.dart';

/// Institutional asset card in the Watchlist view displaying real-time telemetry,
/// mini sparkline chart, and quick navigation.
class WatchlistCard extends StatelessWidget {
  const WatchlistCard({
    super.key,
    required this.instrument,
    this.onRemove,
  });

  final InstrumentModel instrument;
  final VoidCallback? onRemove;

  String _formatPrice(double price) {
    if (price >= 1000.0) {
      final parts = price.toStringAsFixed(2).split('.');
      final whole = parts[0].replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '\$$whole.${parts[1]}';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isPositive = instrument.change >= 0;
    final trendColor = isPositive ? AppColors.bullGreen : AppColors.bearRed;
    final trendBg = isPositive ? AppColors.bullGreenBackground : AppColors.bearRedBackground;

    Widget cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Symbol, Name & Sector
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      instrument.symbol,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.darkSurfaceSecondary
                                : AppColors.lightSurfaceSecondary)
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        instrument.exchange,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  instrument.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Mini Sparkline
          Expanded(
            flex: 3,
            child: Center(
              child: SparklineChart(
                data: instrument.sparkline,
                width: 58,
                height: 24,
                overrideColor: trendColor,
              ),
            ),
          ),

          // Live Price & 24h Change Pill
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatPrice(instrument.currentPrice),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: trendBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                        color: trendColor,
                        size: 14,
                      ),
                      Text(
                        '${isPositive ? '+' : ''}${instrument.changePercentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Dismissible(
      key: ValueKey('watchlist_${instrument.symbol}'),
      direction: onRemove != null ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (_) {
        AppHaptics.medium();
        onRemove?.call();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.bearRed,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          AppHaptics.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstrumentDetailScreen(
                symbol: instrument.symbol,
                initialInstrument: instrument,
              ),
            ),
          );
        },
        child: cardContent,
      ),
    );
  }
}
