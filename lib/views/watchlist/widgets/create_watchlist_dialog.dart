import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// Modal dialog for naming a new watchlist or renaming an existing collection.
class CreateWatchlistDialog extends StatefulWidget {
  const CreateWatchlistDialog({
    super.key,
    this.initialName,
    this.isRename = false,
    required this.onConfirm,
  });

  final String? initialName;
  final bool isRename;
  final ValueChanged<String> onConfirm;

  static Future<void> show({
    required BuildContext context,
    String? initialName,
    bool isRename = false,
    required ValueChanged<String> onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CreateWatchlistDialog',
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
            child: CreateWatchlistDialog(
              initialName: initialName,
              isRename: isRename,
              onConfirm: onConfirm,
            ),
          ),
        );
      },
    );
  }

  @override
  State<CreateWatchlistDialog> createState() => _CreateWatchlistDialogState();
}

class _CreateWatchlistDialogState extends State<CreateWatchlistDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Please enter a watchlist name');
      AppHaptics.error();
      return;
    }

    AppHaptics.medium();
    Navigator.of(context).pop();
    widget.onConfirm(text);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon Badge
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlue.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.playlist_add_rounded,
                  color: AppColors.primaryBlue,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              widget.isRename ? 'Rename Watchlist' : 'Create New Watchlist',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.isRename
                  ? 'Update the display title of this collection.'
                  : 'Curate a custom basket of equities to track in real time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Input
            AppTextField(
              controller: _controller,
              hintText: 'e.g. Semiconductor Plays, Energy...',
              errorText: _error,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      AppHaptics.light();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: widget.isRename ? 'Update' : 'Create',
                    variant: AppButtonVariant.primary,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
