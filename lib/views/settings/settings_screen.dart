import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/alerts/alerts_bloc.dart';
import '../../blocs/alerts/alerts_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/market/market_bloc.dart';
import '../../blocs/market/market_event.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../blocs/trading/trading_bloc.dart';
import '../../blocs/trading/trading_event.dart';
import '../../blocs/trading/trading_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/platform_segmented_tabs_control.dart';
import '../../core/widgets/status_badge.dart';
import '../alerts/alerts_screen.dart';

/// Professional institutional-grade Settings Screen for the Trading Terminal.
///
/// Features:
/// - 3-Theme System (System, Dark, Light) via [PlatformSegmentedTabsControl]
/// - Elevated Price Alerts Hub card with live active badge
/// - Reset Virtual Account to $100,000 cash with confirmation modal
/// - Institutional trading preferences (order type, slippage, confirmation)
/// - Security and terminal session management
/// - Strict haptic discipline: haptics are strictly isolated to theme switching only
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Institutional Trading Preferences (Demonstration & active state)
  String _defaultOrderType = 'Market';
  double _slippageTolerance = 0.5;
  bool _requireOrderConfirmation = true;
  bool _quickTradingEnabled = false;

  // Security Preferences
  bool _biometricsEnabled = true;

  void _showResetAccountDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      type: AppDialogType.warning,
      title: 'Reset Virtual Portfolio?',
      message:
          'This action will permanently liquidate all active holdings, cancel pending orders, and reset your virtual balance to \$100,000.00 cash.',
      primaryButtonText: 'Reset to \$100k',
      secondaryButtonText: 'Cancel',
      onPrimaryPressed: () {
        context.read<TradingBloc>().add(const VirtualAccountReset());
        AppSnackBar.show(
          context,
          message: 'Portfolio successfully reinitialized to \$100,000.00 cash.',
          type: AppSnackBarType.success,
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      type: AppDialogType.warning,
      title: 'Confirm Sign Out',
      message: 'Are you sure you want to terminate your terminal session?',
      primaryButtonText: 'Sign Out',
      secondaryButtonText: 'Cancel',
      onPrimaryPressed: () {
        context.read<MarketBloc>().add(const MarketFeedPaused());
        context.read<AuthBloc>().add(const AuthLogoutRequested());
      },
    );
  }

  int _themeModeToIndex(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 0;
      case ThemeMode.dark:
        return 1;
      case ThemeMode.light:
        return 2;
    }
  }

  ThemeMode _indexToThemeMode(int index) {
    switch (index) {
      case 0:
        return ThemeMode.system;
      case 1:
        return ThemeMode.dark;
      case 2:
      default:
        return ThemeMode.light;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. User Profile & Account Card
            _buildProfileCard(
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: 24),

            // 2. Interface Theme Section (3-Theme System)
            _buildSectionHeader('INTERFACE THEME', textSecondary),
            const SizedBox(height: 8),
            _buildThemeSelectorCard(
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: 24),

            // 3. Elevated Price Alerts Hub Card
            _buildSectionHeader('PRICE ALERTS & TRIGGERS', textSecondary),
            const SizedBox(height: 8),
            _buildPriceAlertsCard(
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: 24),

            // 4. Institutional Trading Preferences
            _buildSectionHeader('TRADING PREFERENCES', textSecondary),
            const SizedBox(height: 8),
            _buildTradingPreferencesCard(
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // 5. Capital & Risk Management
            _buildSectionHeader('CAPITAL & RISK MANAGEMENT', textSecondary),
            const SizedBox(height: 8),
            _buildCapitalManagementCard(
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: 24),

            // 6. Security & Sessions
            _buildSectionHeader('SECURITY & SYSTEM', textSecondary),
            const SizedBox(height: 8),
            _buildSecurityCard(
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: 24),

            // 7. About & Terminal Info
            _buildSectionHeader('TERMINAL INFORMATION', textSecondary),
            const SizedBox(height: 8),
            _buildTerminalInfoCard(
              cardBg: cardBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),

            const SizedBox(height: 32),

            // 8. Sign Out Button
            AppButton(
              text: 'Sign Out of Terminal',
              variant: AppButtonVariant.danger,
              onPressed: () => _showSignOutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textSecondary) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildProfileCard({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is Authenticated ? authState.user : null;
        final displayName = user?.displayName ?? 'Mudasir Ali';
        final email = user?.email ?? 'mudasir@gmail.com';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'M',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          email,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    customLabel:
                        user?.isPro == true ? 'PRO TIER' : 'INSTITUTIONAL DEMO',
                    customColor: user?.isPro == true
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF3B82F6),
                    leading: user?.isPro == true
                        ? const CrownIcon(size: 11, color: Color(0xFFF59E0B))
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bullGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Terminal Session • TLS 1.3 Simulated Brokerage Feed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeSelectorCard({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final selectedIndex = _themeModeToIndex(themeMode);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: PlatformSegmentedTabsControl(
            selectedIndex: selectedIndex,
            tabs: const [
              SegmentTabData(
                label: 'System',
                icon: Icons.brightness_auto_rounded,
                iosIconName: 'circle.lefthalf.filled',
                activePillColor: AppColors.primaryBlue,
                activeIconColor: Color(0xFF38BDF8),
                inactiveIconColor: Color(0xFF38BDF8),
              ),
              SegmentTabData(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                iosIconName: 'moon.fill',
                activePillColor: AppColors.primaryBlue,
                activeIconColor: Color(0xFF60A5FA),
                inactiveIconColor: Color(0xFF60A5FA),
              ),
              SegmentTabData(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                iosIconName: 'sun.max.fill',
                activePillColor: AppColors.primaryBlue,
                activeIconColor: Color(0xFFF59E0B),
                inactiveIconColor: Color(0xFFF59E0B),
              ),
            ],
            onTabSelected: (index) {
              // Haptics strictly isolated to theme switching only
              AppHaptics.selection();
              context.read<ThemeCubit>().setTheme(_indexToThemeMode(index));
            },
          ),
        );
      },
    );
  }

  Widget _buildPriceAlertsCard({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return BlocBuilder<AlertsBloc, AlertsState>(
      builder: (context, aState) {
        final activeCount =
            aState is AlertsLoaded ? aState.activeAlerts.length : 0;
        final triggeredCount =
            aState is AlertsLoaded ? aState.triggeredAlerts.length : 0;

        return Material(
          color: cardBg,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AlertsScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      color: AppColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Price Alerts Hub',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (activeCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bullGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$activeCount ACTIVE',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.bullGreen,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          activeCount > 0
                              ? 'Monitoring $activeCount active price trigger${activeCount == 1 ? "" : "s"} • $triggeredCount history'
                              : 'Configure conditional price rise/drop notifications',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: textSecondary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTradingPreferencesCard({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Default Order Type
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Default Execution Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pre-selected order type in ticket',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Market', 'Limit'].map((type) {
                    final isSelected = _defaultOrderType == type;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _defaultOrderType = type);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : (isDark
                                    ? AppColors.darkSurfaceSecondary
                                    : AppColors.lightSurfaceSecondary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // Slippage Tolerance
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Slippage Tolerance (BPS)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Simulated price tolerance',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [0.1, 0.5, 1.0].map((rate) {
                    final isSelected = _slippageTolerance == rate;
                    return Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _slippageTolerance = rate);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : (isDark
                                    ? AppColors.darkSurfaceSecondary
                                    : AppColors.lightSurfaceSecondary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$rate%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // Require Order Confirmation Modal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Require Order Confirmation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Show verification sheet before executing trades',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: _requireOrderConfirmation,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() => _requireOrderConfirmation = val);
                  },
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // Quick 1-Tap Trading
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick 1-Tap Execution',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bypass quantity slider with default 1-share buy',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: _quickTradingEnabled,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() => _quickTradingEnabled = val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapitalManagementCard({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Current Balance reference
          BlocBuilder<TradingBloc, TradingState>(
            builder: (context, state) {
              final cash = state is TradingLoaded ? state.virtualCash : 100000.0;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Paper Cash',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${cash.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SIMULATED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Divider(height: 1, color: borderColor),

          // Reset Virtual Account action
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              onTap: () => _showResetAccountDialog(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.restart_alt_rounded,
                      color: AppColors.warningAmber,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset Virtual Account to \$100,000',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reinitializes cash balance and liquidates test positions',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.warningAmber,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biometric Authentication',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Require Face ID / Touch ID on app launch',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: _biometricsEnabled,
                  activeTrackColor: AppColors.primaryBlue,
                  onChanged: (val) {
                    setState(() => _biometricsEnabled = val);
                  },
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Inactivity Timeout',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Locks terminal after 30 minutes of background idle',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bullGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '30 MIN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bullGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalInfoCard({
    required Color cardBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terminal Core Version',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'v1.2.0 • Build 4209',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 10),
          Text(
            'Apex Terminal is an institutional-grade market simulator. All real-time market feeds, order routing mechanisms, and portfolio balances operate within a risk-free simulated paper trading sandbox.',
            style: TextStyle(
              fontSize: 11,
              height: 1.45,
              color: textSecondary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
