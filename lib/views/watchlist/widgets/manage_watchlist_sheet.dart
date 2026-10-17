import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../models/watchlist_model.dart';

/// Bottom sheet presenting management actions for the active watchlist.
class ManageWatchlistSheet extends StatelessWidget {
  const ManageWatchlistSheet({
    super.key,
    required this.watchlist,
    required this.totalWatchlists,
    required this.onRename,
    required this.onDelete,
    required this.onResetDefaults,
  });

  final WatchlistModel watchlist;
  final int totalWatchlists;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onResetDefaults;

  static Future<void> show({
    required BuildContext context,
    required WatchlistModel watchlist,
    required int totalWatchlists,
    required VoidCallback onRename,
    required VoidCallback onDelete,
    required VoidCallback onResetDefaults,
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'Manage "${watchlist.name}"',
      child: ManageWatchlistSheet(
        watchlist: watchlist,
        totalWatchlists: totalWatchlists,
        onRename: onRename,
        onDelete: onDelete,
        onResetDefaults: onResetDefaults,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    AppHaptics.heavy();
    AppDialog.show(
      context: context,
      type: AppDialogType.danger,
      title: 'Delete "${watchlist.name}"?',
      message: 'This will permanently remove this watchlist and all its saved assets. This cannot be undone.',
      primaryButtonText: 'Delete List',
      secondaryButtonText: 'Cancel',
      onPrimaryPressed: () {
        AppHaptics.medium();
        onDelete();
      },
    );
  }

  void _confirmReset(BuildContext context) {
    AppHaptics.warning();
    AppDialog.show(
      context: context,
      type: AppDialogType.warning,
      title: 'Reset to Default Watchlists?',
      message: 'This will restore the original institutional lists (Tech Giants, High Beta, Dividend Growth) and clear custom lists.',
      primaryButtonText: 'Reset Lists',
      secondaryButtonText: 'Cancel',
      onPrimaryPressed: () {
        AppHaptics.medium();
        onResetDefaults();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Watchlist Metadata Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star_rounded, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      watchlist.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '${watchlist.symbols.length} tracked equities',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Action 1: Rename
        _ActionTile(
          icon: Icons.edit_outlined,
          iconColor: AppColors.primaryBlue,
          title: 'Rename Watchlist',
          subtitle: 'Change title of this collection',
          onTap: () {
            Navigator.of(context).pop();
            onRename();
          },
        ),

        const SizedBox(height: 8),

        // Action 2: Reset to Defaults
        _ActionTile(
          icon: Icons.restart_alt_rounded,
          iconColor: AppColors.warningAmber,
          title: 'Restore Default Watchlists',
          subtitle: 'Re-seed institutional starter collections',
          onTap: () {
            Navigator.of(context).pop();
            _confirmReset(context);
          },
        ),

        const SizedBox(height: 8),

        // Action 3: Delete
        _ActionTile(
          icon: Icons.delete_outline_rounded,
          iconColor: AppColors.bearRed,
          title: 'Delete Watchlist',
          subtitle: totalWatchlists <= 1
              ? 'Cannot delete the only remaining watchlist'
              : 'Remove this collection permanently',
          enabled: totalWatchlists > 1,
          isDestructive: true,
          onTap: () {
            Navigator.of(context).pop();
            _confirmDelete(context);
          },
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isDestructive ? AppColors.bearRed : iconColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? AppColors.bearRed : iconColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? AppColors.bearRed : textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: textSecondary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
