import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../utils/app_haptics.dart';

/// Semantic types for institutional-grade notification snacks.
enum AppSnackBarType {
  info,
  success,
  warning,
  error,
}

/// Premium theme-adaptive floating SnackBar with sleek compact footprint,
/// clean status iconography, and subtle ambient glow.
class AppSnackBar {
  const AppSnackBar._();

  /// Displays a compact floating snackbar.
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppSnackBarType type = AppSnackBarType.info,
    Duration duration = const Duration(milliseconds: 2500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 14),
      padding: EdgeInsets.zero,
      duration: duration,
      content: _AppSnackBarContent(
        message: message,
        title: title,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () => messenger.hideCurrentSnackBar(),
      ),
    );

    messenger.showSnackBar(snackBar);
  }

  /// Convenience helper for informational feedback.
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppSnackBarType.info,
      duration: duration,
    );
  }

  /// Convenience helper for successful completions.
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppSnackBarType.success,
      duration: duration,
    );
  }

  /// Convenience helper for warning states.
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppSnackBarType.warning,
      duration: duration,
    );
  }

  /// Convenience helper for failure and error alerts.
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppSnackBarType.error,
      duration: duration,
    );
  }
}

class _AppSnackBarContent extends StatelessWidget {
  const _AppSnackBarContent({
    required this.message,
    this.title,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  final String message;
  final String? title;
  final AppSnackBarType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  Color _getAccentColor() {
    switch (type) {
      case AppSnackBarType.success:
        return AppColors.bullGreen;
      case AppSnackBarType.warning:
        return AppColors.warningAmber;
      case AppSnackBarType.error:
        return AppColors.bearRed;
      case AppSnackBarType.info:
        return AppColors.primaryBlue;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case AppSnackBarType.success:
        return Icons.check_circle_rounded;
      case AppSnackBarType.warning:
        return Icons.warning_amber_rounded;
      case AppSnackBarType.error:
        return Icons.error_outline_rounded;
      case AppSnackBarType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final accentColor = _getAccentColor();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.35),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.40)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.16 : 0.10),
                blurRadius: 10,
                spreadRadius: 0.2,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Compact Status Icon Badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  _getIcon(),
                  size: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 10),

              // Message & Title
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title!.isNotEmpty) ...[
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                    ],
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Button or Dismiss
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    AppHaptics.light();
                    onAction!();
                    onDismiss();
                  },
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 15, color: textSecondary),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  tooltip: 'Dismiss',
                  onPressed: () {
                    AppHaptics.light();
                    onDismiss();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
