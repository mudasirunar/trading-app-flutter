import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'app_button.dart';

enum AppDialogType { info, success, warning, danger }

class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final AppDialogType type;
  final String primaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final Widget? customContent;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = AppDialogType.info,
    this.primaryButtonText = 'OK',
    this.onPrimaryPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.customContent,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    AppDialogType type = AppDialogType.info,
    String primaryButtonText = 'OK',
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    Widget? customContent,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'AppDialog',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppDialog(
              title: title,
              message: message,
              type: type,
              primaryButtonText: primaryButtonText,
              onPrimaryPressed: onPrimaryPressed,
              secondaryButtonText: secondaryButtonText,
              onSecondaryPressed: onSecondaryPressed,
              customContent: customContent,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color badgeBg;
    Color iconColor;
    IconData iconData;

    switch (type) {
      case AppDialogType.success:
        badgeBg = AppColors.bullGreenBackground;
        iconColor = isDark ? AppColors.bullGreen : AppColors.bullGreenLight;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case AppDialogType.danger:
        badgeBg = AppColors.bearRedBackground;
        iconColor = isDark ? AppColors.bearRed : AppColors.bearRedLight;
        iconData = Icons.error_outline_rounded;
        break;
      case AppDialogType.warning:
        badgeBg = AppColors.warningAmberBackground;
        iconColor = AppColors.warningAmber;
        iconData = Icons.warning_amber_rounded;
        break;
      case AppDialogType.info:
        badgeBg = AppColors.infoCyanBackground;
        iconColor = AppColors.primaryBlue;
        iconData = Icons.shield_outlined;
        break;
    }

    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final descColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppStyles.radius16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Centered Circular Icon Badge
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(iconData, size: 28, color: iconColor),
            ),
            const SizedBox(height: AppStyles.space16),

            // Centered Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppStyles.space8),

            // Centered Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: descColor,
                height: 1.45,
              ),
            ),

            if (customContent != null) ...[
              const SizedBox(height: AppStyles.space16),
              customContent!,
            ],

            const SizedBox(height: AppStyles.space24),

            // Aligned Centered Action Buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  text: primaryButtonText,
                  variant: type == AppDialogType.danger ? AppButtonVariant.danger : AppButtonVariant.primary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPrimaryPressed?.call();
                  },
                ),
                if (secondaryButtonText != null) ...[
                  const SizedBox(height: AppStyles.space8),
                  AppButton(
                    text: secondaryButtonText!,
                    variant: AppButtonVariant.outline,
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSecondaryPressed?.call();
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
