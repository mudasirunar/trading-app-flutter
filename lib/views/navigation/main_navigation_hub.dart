import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/market/market_bloc.dart';
import '../../blocs/market/market_event.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/platform_bottom_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../blocs/alerts/alerts_bloc.dart';
import '../../blocs/alerts/alerts_state.dart';
import '../alerts/alerts_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../watchlist/watchlist_screen.dart';

/// Primary authenticated application navigation hub.
/// Hosts [PlatformBottomBar] and switches between Dashboard, Markets, Portfolio, and Settings.
class MainNavigationHub extends StatefulWidget {
  const MainNavigationHub({super.key});

  @override
  State<MainNavigationHub> createState() => _MainNavigationHubState();
}

class _MainNavigationHubState extends State<MainNavigationHub> {
  int _currentIndex = 0;
  int _watchlistSegment = 0;
  final GlobalKey<WatchlistScreenState> _watchlistKey = GlobalKey<WatchlistScreenState>();

  @override
  void initState() {
    super.initState();
    // Start market ticker feed upon entering the authenticated terminal
    context.read<MarketBloc>().add(const MarketStarted());
  }

  void _navigateToAllMarkets() {
    AppHaptics.selection();
    setState(() {
      _currentIndex = 1;
      _watchlistSegment = 1;
    });
    _watchlistKey.currentState?.selectSegment(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(
            onNavigateToSearch: _navigateToAllMarkets,
          ),
          WatchlistScreen(
            key: _watchlistKey,
            initialSegment: _watchlistSegment,
            onNavigateToSearch: () {
              _watchlistKey.currentState?.selectSegment(1);
            },
          ),
          PortfolioScreen(
            onExploreMarkets: _navigateToAllMarkets,
          ),
          const _SettingsTab(),
        ],
      ),
      bottomNavigationBar: PlatformBottomBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          AppHaptics.selection();
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}


class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  void _showSignOutDialog(BuildContext context) {
    AppHaptics.light();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings & Account',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final user = authState is Authenticated ? authState.user : null;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          user != null && user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'M',
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
                              user?.displayName ?? 'Mudasir Ali',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? 'mudasir@gmail.com',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        customLabel: user?.isPro == true ? 'PRO TIER' : 'PRACTICE',
                        customColor: user?.isPro == true
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF3B82F6),
                        leading: user?.isPro == true
                            ? const CrownIcon(size: 11, color: Color(0xFFF59E0B))
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Preferences Section
            Text(
              'TERMINAL PREFERENCES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),

            Material(
              color: cardBg,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.primaryBlue,
                    ),
                    title: Text(
                      'Interface Theme',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      isDark ? 'Dark Mode (Institutional Slate)' : 'Light Mode (Clean Pearl)',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    trailing: Switch.adaptive(
                      value: isDark,
                      activeTrackColor: AppColors.primaryBlue,
                      onChanged: (_) {
                        AppHaptics.selection();
                        context.read<ThemeCubit>().toggleTheme();
                      },
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  ListTile(
                    leading: const Icon(Icons.bolt_rounded, color: AppColors.bullGreen),
                    title: Text(
                      'Market Feed Venue',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Simulated Exchange Feed • Real-Time',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.bullGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.bullGreen,
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  BlocBuilder<AlertsBloc, AlertsState>(
                    builder: (context, aState) {
                      final activeCount =
                          aState is AlertsLoaded ? aState.activeAlerts.length : 0;
                      return ListTile(
                        leading: const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        title: Text(
                          'Price Alerts & Triggers',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          activeCount > 0
                              ? '$activeCount active price ${activeCount == 1 ? "alert" : "alerts"}'
                              : 'Configure real-time threshold notifications',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (activeCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.bullGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
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
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: textSecondary,
                            ),
                          ],
                        ),
                        onTap: () {
                          AppHaptics.selection();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AlertsScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Sign Out Button
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
}
