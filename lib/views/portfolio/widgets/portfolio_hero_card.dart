import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/format_utils.dart';

/// Hero summary card displaying Total Account Value, Overall Unrealized P&L,
/// Available Virtual Cash, Total Invested Basis, and Current Market Value.
class PortfolioHeroCard extends StatelessWidget {
  final double totalValue;
  final double availableCash;
  final double totalInvested;
  final double holdingsMarketValue;
  final double unrealizedPL;
  final double unrealizedPLPercent;

  const PortfolioHeroCard({
    super.key,
    required this.totalValue,
    required this.availableCash,
    required this.totalInvested,
    required this.holdingsMarketValue,
    required this.unrealizedPL,
    required this.unrealizedPLPercent,
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

    final isProfit = unrealizedPL >= 0;
    final plColor = isProfit ? AppColors.bullGreen : AppColors.bearRed;
    final plBg = isProfit
        ? AppColors.bullGreenBackground
        : AppColors.bearRedBackground;

    final formattedTotal = FormatUtils.formatCurrency(totalValue);
    final sign = unrealizedPL >= 0 ? '+' : '';
    final plString =
        '$sign${FormatUtils.formatCurrency(unrealizedPL)} ($sign${unrealizedPLPercent.toStringAsFixed(2)}%)';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppStyles.radius20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Subtitle & Paper Account Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PORTFOLIO VALUE',
                  style: AppStyles.caption.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue
                        .withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(AppStyles.radius6),
                    border: Border.all(
                      color: AppColors.primaryBlue
                          .withValues(alpha: isDark ? 0.30 : 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.bullGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Virtual Live',
                        style: AppStyles.caption.copyWith(
                          color: isDark
                              ? AppColors.primaryBlueLight
                              : AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Large Total Equity
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formattedTotal,
                style: AppStyles.displayLarge.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Unrealized P&L Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: plBg,
                borderRadius: BorderRadius.circular(AppStyles.radiusFull),
                border: Border.all(
                  color: plColor.withValues(alpha: isDark ? 0.35 : 0.20),
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
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'All-Time',
                    style: AppStyles.caption.copyWith(
                      color: plColor.withValues(alpha: 0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 14),

            // Breakdown Grid (Available Cash, Invested Basis, Market Value)
            Row(
              children: [
                // Available Cash (with quick + deposit action)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Cash',
                        style: AppStyles.caption.copyWith(
                          color: textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        FormatUtils.formatCurrency(availableCash),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.bodyMedium.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Invested Basis
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Invested',
                        style: AppStyles.caption.copyWith(
                          color: textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        FormatUtils.formatCurrency(totalInvested),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.bodyMedium.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Market Value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Holdings Value',
                        style: AppStyles.caption.copyWith(
                          color: textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        FormatUtils.formatCurrency(holdingsMarketValue),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.bodyMedium.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
    );
  }
}
