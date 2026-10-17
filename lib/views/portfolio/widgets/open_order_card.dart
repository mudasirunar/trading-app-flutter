import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../models/order_model.dart';

/// Card rendering an active pending order (Limit or Stop-Loss) with direct Cancel capability.
class OpenOrderCard extends StatelessWidget {
  final OrderModel order;
  final double? currentMarketPrice;
  final VoidCallback onCancelOrder;

  const OpenOrderCard({
    super.key,
    required this.order,
    this.currentMarketPrice,
    required this.onCancelOrder,
  });

  void _confirmCancel(BuildContext context) {
    AppHaptics.warning();
    AppDialog.show(
      context: context,
      type: AppDialogType.warning,
      title: 'Cancel Order?',
      message:
          'Are you sure you want to cancel this ${order.type.label} ${order.side.label} order for ${order.quantity.toStringAsFixed(0)} ${order.symbol}? Any locked virtual cash will be immediately refunded.',
      primaryButtonText: 'Yes, Cancel Order',
      secondaryButtonText: 'Keep Active',
      onPrimaryPressed: () {
        AppHaptics.success();
        onCancelOrder();
      },
      onSecondaryPressed: () {
        AppHaptics.light();
      },
    );
  }

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

    final targetPrice = order.limitPrice ?? order.stopPrice ?? 0.0;
    final formattedTarget = FormatUtils.formatCurrency(targetPrice);
    final formattedTime = FormatUtils.formatDate(order.createdAt);

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top Row: Side + Type badge, Symbol, Placed Time
            Row(
              children: [
                // Side Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sideBg,
                    borderRadius: BorderRadius.circular(AppStyles.radius6),
                  ),
                  child: Text(
                    '${order.side.label.toUpperCase()} · ${order.type.label.toUpperCase()}',
                    style: AppStyles.caption.copyWith(
                      color: sideColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  order.symbol,
                  style: AppStyles.titleMedium.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  formattedTime,
                  style: AppStyles.caption.copyWith(
                    color: textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: borderColor, height: 1),
            const SizedBox(height: 12),

            // Middle Row: Quantity, Target Price, Current Market Price (if available)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity',
                      style: AppStyles.caption.copyWith(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.quantity.toStringAsFixed(order.quantity % 1 == 0 ? 0 : 2)} shares',
                      style: AppStyles.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      order.type == OrderType.limit ? 'Limit Price' : 'Stop Price',
                      style: AppStyles.caption.copyWith(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedTarget,
                      style: AppStyles.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (currentMarketPrice != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Market Price',
                        style: AppStyles.caption.copyWith(
                          color: textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        FormatUtils.formatCurrency(currentMarketPrice!),
                        style: AppStyles.bodyMedium.copyWith(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Action Row: Cancel Order button
            SizedBox(
              width: double.infinity,
              height: 38,
              child: AppButton(
                text: 'Cancel Order',
                icon: Icons.close_rounded,
                variant: AppButtonVariant.danger,
                onPressed: () => _confirmCancel(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
