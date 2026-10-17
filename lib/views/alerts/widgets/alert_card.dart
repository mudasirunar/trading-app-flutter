import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/alert_model.dart';

/// Card rendering an active, triggered, or disabled Price Alert
class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onToggle,
    this.onDelete,
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

    final isRisesAbove = alert.condition == AlertCondition.risesAbove;
    final conditionColor =
        isRisesAbove ? AppColors.bullGreen : AppColors.bearRed;

    OrderBadgeStatus badgeStatus;
    switch (alert.status) {
      case AlertStatus.active:
        badgeStatus = OrderBadgeStatus.active;
        break;
      case AlertStatus.triggered:
        badgeStatus = OrderBadgeStatus.triggered;
        break;
      case AlertStatus.disabled:
        badgeStatus = OrderBadgeStatus.cancelled;
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
            AppHaptics.light();
            onTap?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Symbol, Condition Icon & Status Badge
                Row(
                  children: [
                    // Symbol Icon Badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: conditionColor
                            .withValues(alpha: isDark ? 0.18 : 0.10),
                        borderRadius:
                            BorderRadius.circular(AppStyles.radius10),
                        border: Border.all(
                          color: conditionColor.withValues(alpha: 0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isRisesAbove
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 20,
                        color: conditionColor,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Symbol & Condition
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  alert.symbol,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppStyles.titleMedium.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              StatusBadge(status: badgeStatus),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${alert.condition.label} ${FormatUtils.formatCurrency(alert.targetPrice)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.caption.copyWith(
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions: Switch or Delete
                    if (alert.isActive || alert.isDisabled) ...[
                      Transform.scale(
                        scale: 0.8,
                        child: Switch.adaptive(
                          value: alert.isActive,
                          activeTrackColor: AppColors.bullGreen,
                          onChanged: (val) {
                            AppHaptics.selection();
                            onToggle?.call(val);
                          },
                        ),
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      color: textSecondary,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        AppHaptics.warning();
                        onDelete?.call();
                      },
                    ),
                  ],
                ),

                if (alert.note != null && alert.note!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceSecondary
                          : AppColors.lightSurfaceSecondary,
                      borderRadius: BorderRadius.circular(AppStyles.radius8),
                    ),
                    child: Text(
                      'Note: ${alert.note}',
                      style: AppStyles.caption.copyWith(
                        color: textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 8),

                // Footer: Creation or Trigger Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      alert.isTriggered && alert.triggeredAt != null
                          ? 'Triggered ${FormatUtils.formatDate(alert.triggeredAt!)}'
                          : 'Created ${FormatUtils.formatDate(alert.createdAt)}',
                      style: AppStyles.caption.copyWith(
                        color: textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    if (alert.isTriggered && alert.triggeredPrice != null)
                      Text(
                        'Trigger Price: ${FormatUtils.formatCurrency(alert.triggeredPrice!)}',
                        style: AppStyles.caption.copyWith(
                          color: conditionColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
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
