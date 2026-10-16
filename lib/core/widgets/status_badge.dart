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
  final Widget? leading;

  const StatusBadge({
    super.key,
    this.status,
    this.customLabel,
    this.customColor,
    this.icon,
    this.leading,
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
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3.5),
          ],
          Text(
            customLabel ?? label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hand-crafted Golden Crown Icon for PRO Tier status badges
class CrownIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CrownIcon({
    super.key,
    this.size = 11,
    this.color = const Color(0xFFF59E0B),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.85),
      painter: _CrownPainter(color: color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final Color color;
  const _CrownPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Crown silhouette path
    final path = Path()
      ..moveTo(w * 0.12, h * 0.88)
      ..lineTo(0, h * 0.30)
      ..lineTo(w * 0.32, h * 0.52)
      ..lineTo(w * 0.50, h * 0.12)
      ..lineTo(w * 0.68, h * 0.52)
      ..lineTo(w * 1.0, h * 0.30)
      ..lineTo(w * 0.88, h * 0.88)
      ..close();

    canvas.drawPath(path, paint);

    // Crown base bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.86, w * 0.84, h * 0.14),
        const Radius.circular(1.0),
      ),
      paint,
    );

    // 3 jewels on the 3 crown peaks
    final jewelPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.04, h * 0.30), w * 0.07, jewelPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.12), w * 0.08, jewelPaint);
    canvas.drawCircle(Offset(w * 0.96, h * 0.30), w * 0.07, jewelPaint);
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) =>
      oldDelegate.color != color;
}
