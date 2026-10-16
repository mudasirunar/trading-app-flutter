import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/platform_bottom_bar.dart';
import '../../core/widgets/status_badge.dart';

class DesignShowcaseScreen extends StatefulWidget {
  const DesignShowcaseScreen({super.key});

  @override
  State<DesignShowcaseScreen> createState() => _DesignShowcaseScreenState();
}

class _DesignShowcaseScreenState extends State<DesignShowcaseScreen> {
  int _activeNavIndex = 0;
  bool _isPasswordVisible = false;
  final TextEditingController _emailController = TextEditingController(text: 'mudasir@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: 'Test123');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTestDialog(AppDialogType type) {
    String title;
    String message;

    switch (type) {
      case AppDialogType.success:
        title = 'Order Filled';
        message = 'Your simulated market buy order for 10 shares of AAPL was executed at \$234.50.';
        break;
      case AppDialogType.danger:
        title = 'Insufficient Cash';
        message = 'You do not have sufficient virtual funds to place this limit order. Deposit funds or adjust quantity.';
        break;
      case AppDialogType.warning:
        title = 'Market Closed';
        message = 'Standard market hours are closed. Limit orders placed now will queue for next session fill.';
        break;
      case AppDialogType.info:
        title = 'Simulation Notice';
        message = 'This is a practice stock trading environment. All funds, balances, and orders are strictly virtual.';
        break;
    }

    AppDialog.show(
      context: context,
      title: title,
      message: message,
      type: type,
      primaryButtonText: 'Understood',
      secondaryButtonText: type == AppDialogType.danger ? 'Cancel' : null,
    );
  }

  void _showTestBottomSheet() {
    AppBottomSheet.show(
      context: context,
      title: 'Order Preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Instrument', style: TextStyle(color: Colors.grey)),
              const Text('Apple Inc. (AAPL)', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Type', style: TextStyle(color: Colors.grey)),
              const Text('Market Buy', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.bullGreen)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Cost', style: TextStyle(color: Colors.grey)),
              const Text('\$2,345.00', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Confirm Simulation Trade',
            variant: AppButtonVariant.primary,
            onPressed: () {
              Navigator.of(context).pop();
              _showTestDialog(AppDialogType.success);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Trading App Design System'),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 22,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => context.read<ThemeCubit>().toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(AppStyles.space12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppStyles.radius12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.infoCyanBackground,
                      borderRadius: BorderRadius.circular(AppStyles.radius8),
                    ),
                    child: const Icon(Icons.palette_outlined, size: 20, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(width: AppStyles.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phase 2: Design Tokens & Reusable UI',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Active Tab: ${_tabName(_activeNavIndex)} • Theme: ${isDark ? "Dark Brokerage" : "Light"}',
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

            const SizedBox(height: AppStyles.space24),

            // Typography & Color Badges
            Text('FINANCIAL STATUS BADGES', style: AppStyles.micro.copyWith(color: textSecondary)),
            const SizedBox(height: AppStyles.space12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                StatusBadge(status: OrderBadgeStatus.filled),
                StatusBadge(status: OrderBadgeStatus.pending),
                StatusBadge(status: OrderBadgeStatus.partiallyFilled),
                StatusBadge(status: OrderBadgeStatus.cancelled),
                StatusBadge(status: OrderBadgeStatus.rejected),
                StatusBadge(status: OrderBadgeStatus.active),
                StatusBadge(status: OrderBadgeStatus.triggered),
              ],
            ),

            const SizedBox(height: AppStyles.space24),

            // Form Inputs
            Text('REUSABLE INPUT FIELDS', style: AppStyles.micro.copyWith(color: textSecondary)),
            const SizedBox(height: AppStyles.space12),
            AppTextField(
              controller: _emailController,
              label: 'Account Email',
              hintText: 'Enter email address',
              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
            ),
            const SizedBox(height: AppStyles.space12),
            AppTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Enter password',
              obscureText: !_isPasswordVisible,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 18,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),

            const SizedBox(height: AppStyles.space24),

            // Button Variants
            Text('BUTTON COMPONENT VARIANTS', style: AppStyles.micro.copyWith(color: textSecondary)),
            const SizedBox(height: AppStyles.space12),
            AppButton(
              text: 'Primary Trade Action (Market Buy)',
              icon: Icons.trending_up_rounded,
              variant: AppButtonVariant.primary,
              onPressed: () => _showTestDialog(AppDialogType.success),
            ),
            const SizedBox(height: AppStyles.space8),
            AppButton(
              text: 'Secondary Action (Limit Order)',
              variant: AppButtonVariant.secondary,
              onPressed: () => _showTestDialog(AppDialogType.warning),
            ),
            const SizedBox(height: AppStyles.space8),
            AppButton(
              text: 'Outline Button (Open Sheet)',
              variant: AppButtonVariant.outline,
              onPressed: _showTestBottomSheet,
            ),
            const SizedBox(height: AppStyles.space8),
            AppButton(
              text: 'Danger Action (Cancel All Orders)',
              variant: AppButtonVariant.danger,
              icon: Icons.delete_outline_rounded,
              onPressed: () => _showTestDialog(AppDialogType.danger),
            ),

            const SizedBox(height: AppStyles.space24),

            // Centered Dialog Triggers
            Text('CUSTOM CENTERED DIALOGS', style: AppStyles.micro.copyWith(color: textSecondary)),
            const SizedBox(height: AppStyles.space12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Info Modal',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _showTestDialog(AppDialogType.info),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton(
                    text: 'Success Modal',
                    variant: AppButtonVariant.outline,
                    onPressed: () => _showTestDialog(AppDialogType.success),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: PlatformBottomBar(
        currentIndex: _activeNavIndex,
        onTabSelected: (index) {
          setState(() => _activeNavIndex = index);
        },
        onSearchTapped: () {
          AppBottomSheet.show(
            context: context,
            title: 'Search & Discover Instruments',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppTextField(
                  hintText: 'Search ticker (e.g. AAPL, TSLA, NVDA)',
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                ),
                const SizedBox(height: 16),
                Text(
                  'Search satellite pod triggered via Liquid Glass Bar!',
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _tabName(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Watchlist';
      case 2:
        return 'Portfolio';
      case 3:
        return 'Settings';
      default:
        return 'Tab $index';
    }
  }
}
