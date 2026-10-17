import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/order_model.dart';
import 'trade_receipt_dialog.dart';

/// Card rendering an executed, filled, or cancelled historical order with tap-to-inspect receipt.
class CompletedOrderCard extends StatelessWidget {
  final OrderModel order;

  const CompletedOrderCard({
    super.key,
    required this.order,
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

    final isBuy = order.side == OrderSide.buy;
    final sideColor = isBuy ? AppColors.bullGreen : AppColors.bearRed;
    final sideBg = isBuy
        ? AppColors.bullGreenBackground
        : AppColors.bearRedBackground;

    final price =
        order.executionPrice ?? order.limitPrice ?? order.stopPrice ?? 0.0;
    final formattedPrice = FormatUtils.formatCurrency(price);
    final formattedTime = FormatUtils.formatDate(order.executedAt ?? order.createdAt);

    OrderBadgeStatus badgeStatus;
    switch (order.status) {
      case OrderStatus.filled:
        badgeStatus = OrderBadgeStatus.filled;
        break;
      case OrderStatus.partiallyFilled:
        badgeStatus = OrderBadgeStatus.partiallyFilled;
        break;
      case OrderStatus.cancelled:
        badgeStatus = OrderBadgeStatus.cancelled;
        break;
      case OrderStatus.rejected:
        badgeStatus = OrderBadgeStatus.rejected;
        break;
      case OrderStatus.pending:
        badgeStatus = OrderBadgeStatus.pending;
        break;
    }

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
            AppHaptics.selection();
            TradeReceiptDialog.show(context, order);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Side pill badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sideBg,
                    borderRadius: BorderRadius.circular(AppStyles.radius6),
                  ),
                  child: Text(
                    order.side.label.toUpperCase(),
                    style: AppStyles.caption.copyWith(
                      color: sideColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Symbol, Type & Timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            order.symbol,
                            style: AppStyles.titleMedium.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '·  ${order.type.label}',
                            style: AppStyles.caption.copyWith(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formattedTime,
                        style: AppStyles.caption.copyWith(
                          color: textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price & Quantity filled
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${order.filledQuantity > 0 ? order.filledQuantity.toStringAsFixed(0) : order.quantity.toStringAsFixed(0)} shs @ $formattedPrice',
                      style: AppStyles.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(status: badgeStatus),
                  ],
                ),

                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: textSecondary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
