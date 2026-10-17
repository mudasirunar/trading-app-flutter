import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/order_model.dart';

/// Modal dialog presenting an institutional execution trade receipt.
class TradeReceiptDialog extends StatelessWidget {
  final OrderModel order;

  const TradeReceiptDialog({
    super.key,
    required this.order,
  });

  static Future<void> show(BuildContext context, OrderModel order) {
    AppHaptics.selection();
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => TradeReceiptDialog(order: order),
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

    final price =
        order.executionPrice ?? order.limitPrice ?? order.stopPrice ?? 0.0;
    final grossAmount =
        (order.filledQuantity > 0 ? order.filledQuantity : order.quantity) *
            price;
    final netAmount = isBuy
        ? grossAmount + order.fees
        : (grossAmount - order.fees).clamp(0.0, double.infinity);

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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppStyles.radius20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trade Receipt',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.titleMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: badgeStatus),
                ],
              ),
            ),

            // Body Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Symbol & Notional Headline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.symbol,
                            style: AppStyles.headline.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.type.label} Order',
                            style: AppStyles.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            FormatUtils.formatCurrency(netAmount),
                            style: AppStyles.headline.copyWith(
                              color: textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Net Settled Capital',
                            style: AppStyles.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 14),

                  // Data Rows
                  _buildDataRow(
                    context,
                    label: 'Executed Quantity',
                    value:
                        '${order.filledQuantity.toStringAsFixed(2)} / ${order.quantity.toStringAsFixed(2)} shares',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 10),
                  _buildDataRow(
                    context,
                    label: order.executionPrice != null
                        ? 'Execution Price'
                        : 'Target Limit / Stop',
                    value: FormatUtils.formatCurrency(price),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 10),
                  _buildDataRow(
                    context,
                    label: 'Gross Notional',
                    value: FormatUtils.formatCurrency(grossAmount),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 10),
                  _buildDataRow(
                    context,
                    label: 'Brokerage Commission',
                    value: order.fees > 0
                        ? FormatUtils.formatCurrency(order.fees)
                        : '\$0.00 (Zero Fee)',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  const SizedBox(height: 10),
                  _buildDataRow(
                    context,
                    label: 'Placed At',
                    value: FormatUtils.formatDateTime(order.createdAt),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  if (order.executedAt != null) ...[
                    const SizedBox(height: 10),
                    _buildDataRow(
                      context,
                      label: order.status == OrderStatus.cancelled
                          ? 'Cancelled At'
                          : 'Settled At',
                      value: FormatUtils.formatDateTime(order.executedAt!),
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                    ),
                  ],

                  const SizedBox(height: 14),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 12),

                  // Order Reference ID with copy
                  InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      Clipboard.setData(ClipboardData(text: order.id));
                      AppSnackBar.show(
                        context,
                        message: 'Order ID copied to clipboard',
                        type: AppSnackBarType.info,
                      );
                    },
                    borderRadius: BorderRadius.circular(AppStyles.radius6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order ID',
                            style:
                                AppStyles.caption.copyWith(color: textSecondary),
                          ),
                          Row(
                            children: [
                              Text(
                                order.id.length > 16
                                    ? '${order.id.substring(0, 16)}...'
                                    : order.id,
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.copy_rounded,
                                size: 13,
                                color: AppColors.primaryBlue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer Button
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Close Receipt',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    AppHaptics.light();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context, {
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppStyles.caption.copyWith(
            color: textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
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
    );
  }
}
