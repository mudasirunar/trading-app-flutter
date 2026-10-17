import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/alerts/alerts_bloc.dart';
import '../../blocs/alerts/alerts_event.dart';
import '../../blocs/alerts/alerts_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../core/widgets/platform_alerts_tabs_control.dart';
import '../instrument_detail/instrument_detail_screen.dart';
import 'widgets/alert_card.dart';

/// Screen allowing users to manage, toggle, and view all active and triggered Price Alerts
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedTab = 0; // 0 = Active, 1 = Triggered

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue
                    .withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(AppStyles.radius8),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                size: 16,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'PRICE ALERTS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<AlertsBloc, AlertsState>(
        listener: (context, state) {
          if (state is AlertsLoaded && state.message != null) {
            AppSnackBar.show(
              context,
              message: state.message!,
              type: AppSnackBarType.info,
            );
          }
        },
        builder: (context, state) {
          if (state is AlertsLoading || state is AlertsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final alertsState = state is AlertsLoaded
              ? state
              : const AlertsLoaded(alerts: []);

          final activeList = [
            ...alertsState.activeAlerts,
            ...alertsState.disabledAlerts,
          ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final triggeredList = alertsState.triggeredAlerts;

          return Column(
            children: [
              // Platform-Adaptive Segmented Control (Native iOS / Liquid Glass Android)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PlatformAlertsTabsControl(
                  selectedIndex: _selectedTab,
                  activeCount: activeList.length,
                  triggeredCount: triggeredList.length,
                  onTabSelected: (index) {
                    if (_selectedTab != index) {
                      AppHaptics.selection();
                      setState(() => _selectedTab = index);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Tab Content
              Expanded(
                child: _selectedTab == 0
                    ? _buildActiveAlertsList(
                        alerts: activeList,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      )
                    : _buildTriggeredAlertsList(
                        alerts: triggeredList,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveAlertsList({
    required List alerts,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (alerts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue
                      .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Price Alerts',
                style: AppStyles.titleMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Open any stock or crypto detail screen and tap the Bell icon to set real-time price triggers.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return AlertCard(
          alert: alert,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InstrumentDetailScreen(symbol: alert.symbol),
              ),
            );
          },
          onToggle: (enabled) {
            context.read<AlertsBloc>().add(
                  AlertToggled(alertId: alert.id, enabled: enabled),
                );
          },
          onDelete: () {
            context.read<AlertsBloc>().add(AlertDeleted(alert.id));
          },
        );
      },
    );
  }

  Widget _buildTriggeredAlertsList({
    required List alerts,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (alerts.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 40,
                color: textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No Triggered History',
                style: AppStyles.titleMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'When live market prices cross your targets, triggered alerts will appear here.',
                textAlign: TextAlign.center,
                style: AppStyles.caption.copyWith(color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return AlertCard(
          alert: alert,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InstrumentDetailScreen(symbol: alert.symbol),
              ),
            );
          },
          onDelete: () {
            context.read<AlertsBloc>().add(AlertDeleted(alert.id));
          },
        );
      },
    );
  }
}
