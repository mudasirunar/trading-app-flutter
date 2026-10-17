import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/holding_model.dart';

/// Card rendering an active portfolio position with real-time valuation and P&L badge.
class HoldingCard extends StatelessWidget {
  final HoldingModel holding;
  final String? companyName;
  final VoidCallback? onTap;

  const HoldingCard({
    super.key,
    required this.holding,
    this.companyName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isProfit = holding.isProfitable;
    final plColor = isProfit ? AppColors.bullGreen : AppColors.bearRed;
    final plBg = isProfit
        ? AppColors.bullGreenBackground
        : AppColors.bearRedBackground;

    final formattedMarketValue = FormatUtils.formatCurrency(holding.marketValue);
    final formattedPrice = FormatUtils.formatCurrency(holding.currentPrice);
    final formattedAvgCost = FormatUtils.formatCurrency(holding.averageCost);

    final sign = holding.unrealizedPL >= 0 ? '+' : '';
    final plString =
        '$sign${FormatUtils.formatCurrency(holding.unrealizedPL)} ($sign${holding.unrealizedPLPercent.toStringAsFixed(2)}%)';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppStyles.radius16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppStyles.radius16),
          onTap: () {
            AppHaptics.light();
            onTap?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top Row: Symbol, Company & Market Value
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Symbol Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue
                            .withValues(alpha: isDark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(AppStyles.radius12),
                        border: Border.all(
                          color: AppColors.primaryBlue
                              .withValues(alpha: isDark ? 0.35 : 0.20),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        holding.symbol.length > 3
                            ? holding.symbol.substring(0, 3)
                            : holding.symbol,
                        style: AppStyles.bodySemiBold.copyWith(
                          color: isDark
                              ? AppColors.primaryBlueLight
                              : AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Symbol & Company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holding.symbol,
                            style: AppStyles.titleMedium.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            companyName ?? 'Active Equity Position',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Market Value
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formattedMarketValue,
                          style: AppStyles.titleMedium.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$formattedPrice / share',
                          style: AppStyles.caption.copyWith(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 12),

                // Bottom Row: Quantity & Average Cost on Left, P&L badge on Right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: 15,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${holding.quantity.toStringAsFixed(holding.quantity % 1 == 0 ? 0 : 2)} shares · $formattedAvgCost avg',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.bodyMedium.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // P&L Pill Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: plBg,
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusFull),
                        border: Border.all(
                          color:
                              plColor.withValues(alpha: isDark ? 0.35 : 0.20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isProfit
                                ? Icons.arrow_drop_up_rounded
                                : Icons.arrow_drop_down_rounded,
                            size: 16,
                            color: plColor,
                          ),
                          Text(
                            plString,
                            style: AppStyles.caption.copyWith(
                              color: plColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
