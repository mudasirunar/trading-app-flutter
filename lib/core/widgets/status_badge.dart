import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

enum OrderBadgeStatus {
  filled,
  pending,
  partiallyFilled,
  cancelled,
  rejected,
  active,
  triggered,
}

class StatusBadge extends StatelessWidget {
  final OrderBadgeStatus? status;
  final String? customLabel;
  final Color? customColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    this.status,
    this.customLabel,
    this.customColor,
    this.icon,
  }) : assert(status != null || (customLabel != null && customColor != null),
            'Must provide either status or customLabel and customColor');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    String label;

    if (customColor != null && customLabel != null) {
      fg = customColor!;
      bg = customColor!.withValues(alpha: isDark ? 0.18 : 0.10);
      label = customLabel!;
    } else {
      switch (status!) {
        case OrderBadgeStatus.filled:
          bg = AppColors.bullGreenBackground;
          fg = isDark ? AppColors.bullGreen : AppColors.bullGreenLight;
          label = 'Filled';
          break;
        case OrderBadgeStatus.pending:
          bg = AppColors.warningAmberBackground;
          fg = AppColors.warningAmber;
          label = 'Pending';
          break;
        case OrderBadgeStatus.partiallyFilled:
          bg = AppColors.infoCyanBackground;
          fg = AppColors.infoCyan;
          label = 'Partial';
          break;
        case OrderBadgeStatus.cancelled:
          bg = isDark ? const Color(0x228B949E) : const Color(0x2264748B);
          fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          label = 'Cancelled';
          break;
        case OrderBadgeStatus.rejected:
          bg = AppColors.bearRedBackground;
          fg = isDark ? AppColors.bearRed : AppColors.bearRedLight;
          label = 'Rejected';
          break;
        case OrderBadgeStatus.active:
          bg = AppColors.bullGreenBackground;
          fg = isDark ? AppColors.bullGreen : AppColors.bullGreenLight;
          label = 'Active';
          break;
        case OrderBadgeStatus.triggered:
          bg = AppColors.warningAmberBackground;
          fg = AppColors.warningAmber;
          label = 'Triggered';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppStyles.radius6),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3.5),
          ],
          Text(
            customLabel ?? label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
