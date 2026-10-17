import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';

enum AppButtonVariant { primary, secondary, outline, danger, success, text }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = onPressed == null || isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isDark ? AppColors.primaryBlue : AppColors.primaryBlueLight;
        foregroundColor = Colors.white;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
        foregroundColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        borderSide = BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1);
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        borderSide = BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1);
        break;
      case AppButtonVariant.danger:
        backgroundColor = isDark ? AppColors.bearRed : AppColors.bearRedLight;
        foregroundColor = Colors.white;
        break;
      case AppButtonVariant.success:
        backgroundColor = isDark ? AppColors.bullGreen : AppColors.bullGreenLight;
        foregroundColor = Colors.white;
        break;
      case AppButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = isDark ? AppColors.primaryBlue : AppColors.primaryBlueLight;
        break;
    }

    if (isDisabled && variant != AppButtonVariant.text) {
      backgroundColor = backgroundColor.withValues(alpha: 0.5);
      foregroundColor = foregroundColor.withValues(alpha: 0.6);
    }

    Widget content = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foregroundColor),
                const SizedBox(width: AppStyles.space8),
              ],
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          );

    final buttonWidget = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.radius10),
        side: borderSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isDisabled ? null : onPressed,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppStyles.space16),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}
