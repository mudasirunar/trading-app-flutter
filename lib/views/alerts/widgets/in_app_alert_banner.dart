import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/widgets/ringing_bell_icon.dart';
import '../../../models/alert_model.dart';

/// Real-time in-app dropdown banner displayed when a Price Alert triggers.
class InAppAlertBanner extends StatefulWidget {
  final AlertModel alert;
  final VoidCallback onDismiss;
  final VoidCallback? onTap;

  const InAppAlertBanner({
    super.key,
    required this.alert,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<InAppAlertBanner> createState() => _InAppAlertBannerState();
}

class _InAppAlertBannerState extends State<InAppAlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _animController.forward();
    AppHaptics.alertChime();

    // Auto-dismiss after 6 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 6), _dismiss);
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _animController.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRisesAbove = widget.alert.condition == AlertCondition.risesAbove;
    final alertColor = isRisesAbove ? AppColors.bullGreen : AppColors.bearRed;

    return SlideTransition(
      position: _offsetAnimation,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppStyles.radius16),
            border: Border.all(
              color: alertColor.withValues(alpha: isDark ? 0.6 : 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: alertColor.withValues(alpha: isDark ? 0.35 : 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AppHaptics.light();
                _autoDismissTimer?.cancel();
                widget.onTap?.call();
                _dismiss();
              },
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: alertColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: RingingBellIcon(
                      size: 20,
                      color: alertColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.alert.symbol,
                              style: AppStyles.bodySemiBold.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PRICE ALERT TRIGGERED',
                              style: TextStyle(
                                color: alertColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.alert.condition.label} ${FormatUtils.formatCurrency(widget.alert.targetPrice)}'
                          '${widget.alert.triggeredPrice != null ? ' (Hit ${FormatUtils.formatCurrency(widget.alert.triggeredPrice!)})' : ''}',
                          style: AppStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              'Tap to trade now',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 11,
                              color: AppColors.primaryBlue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    onPressed: () {
                      AppHaptics.light();
                      _dismiss();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
