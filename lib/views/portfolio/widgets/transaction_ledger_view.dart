import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/transaction_model.dart';

/// Auditable chronological ledger showing all cash flows (deposits, buys, sells, fees).
class TransactionLedgerView extends StatelessWidget {
  final List<TransactionModel> transactions;

  const TransactionLedgerView({
    super.key,
    required this.transactions,
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

    if (transactions.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue
                      .withValues(alpha: isDark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Transaction History',
                style: AppStyles.titleMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cash deposits and trade executions will appear here in chronological order.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort descending by timestamp
    final sortedList = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final tx = sortedList[index];
        final isInflow = tx.amount >= 0;
        final amountColor = isInflow ? AppColors.bullGreen : textPrimary;
        final sign = isInflow ? '+' : '';

        IconData iconData;
        Color iconBg;
        Color iconColor;

        switch (tx.type) {
          case TransactionType.deposit:
            iconData = Icons.account_balance_wallet_rounded;
            iconBg = AppColors.bullGreenBackground;
            iconColor = AppColors.bullGreen;
            break;
          case TransactionType.buy:
            iconData = Icons.shopping_cart_rounded;
            iconBg =
                AppColors.primaryBlue.withValues(alpha: isDark ? 0.20 : 0.10);
            iconColor = AppColors.primaryBlue;
            break;
          case TransactionType.sell:
            iconData = Icons.sell_rounded;
            iconBg = AppColors.bullGreenBackground;
            iconColor = AppColors.bullGreen;
            break;
          case TransactionType.fee:
            iconData = Icons.receipt_rounded;
            iconBg = AppColors.warningAmberBackground;
            iconColor = AppColors.warningAmber;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppStyles.radius12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppStyles.radius10),
                ),
                child: Icon(iconData, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),

              // Title, Subtitle & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.symbol != null
                          ? '${tx.type.label} · ${tx.symbol}'
                          : tx.type.label,
                      style: AppStyles.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      FormatUtils.formatDateTime(tx.timestamp),
                      style: AppStyles.caption.copyWith(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount Flow & Shares/Price description
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${FormatUtils.formatCurrency(tx.amount)}',
                    style: AppStyles.bodyMedium.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (tx.quantity != null && tx.price != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${tx.quantity!.toStringAsFixed(0)} @ ${FormatUtils.formatCurrency(tx.price!)}',
                      style: AppStyles.caption.copyWith(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
