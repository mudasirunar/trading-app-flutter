import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/market/market_bloc.dart';
import '../../blocs/market/market_state.dart';
import '../../blocs/trading/trading_bloc.dart';
import '../../blocs/trading/trading_event.dart';
import '../../blocs/trading/trading_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../models/instrument_model.dart';
import '../instrument_detail/instrument_detail_screen.dart';
import 'widgets/completed_order_card.dart';
import 'widgets/holding_card.dart';
import 'widgets/open_order_card.dart';
import 'widgets/portfolio_hero_card.dart';
import 'widgets/transaction_ledger_view.dart';

/// Primary Institutional Portfolio Screen showing real-time equity analytics,
/// active positions (Holdings), pending/completed orders, and transaction audit ledger.
class PortfolioScreen extends StatefulWidget {
  final VoidCallback? onExploreMarkets;

  const PortfolioScreen({
    super.key,
    this.onExploreMarkets,
  });

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  int _selectedTab = 0; // 0 = Holdings, 1 = Orders, 2 = Ledger
  int _orderSubTab = 0; // 0 = Open Orders, 1 = Completed Orders


  void _confirmResetAccount() {
    AppHaptics.warning();
    AppDialog.show(
      context: context,
      type: AppDialogType.danger,
      title: 'Reset Virtual Account?',
      message:
          'This will wipe all active positions, pending orders, and history, resetting your account balance back to \$100,000.00 virtual cash.',
      primaryButtonText: 'Reset Account',
      secondaryButtonText: 'Cancel',
      onPrimaryPressed: () {
        AppHaptics.success();
        context.read<TradingBloc>().add(const VirtualAccountReset());
        AppSnackBar.show(
          context,
          message: 'Account reset to \$100,000.00 virtual cash',
          type: AppSnackBarType.success,
        );
      },
      onSecondaryPressed: () {
        AppHaptics.light();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
                Icons.account_balance_rounded,
                size: 16,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'PORTFOLIO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Portfolio',
            icon: const Icon(Icons.restart_alt_rounded, size: 22),
            onPressed: _confirmResetAccount,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: BlocConsumer<TradingBloc, TradingState>(
        listener: (context, state) {
          if (state is TradingLoaded && state.lastActionMessage != null) {
            AppSnackBar.show(
              context,
              message: state.lastActionMessage!,
              type: AppSnackBarType.info,
            );
          } else if (state is TradingActionFailure) {
            AppSnackBar.show(
              context,
              message: state.errorMessage,
              type: AppSnackBarType.error,
            );
          }
        },
        builder: (context, tradingState) {
          if (tradingState is TradingLoading ||
              tradingState is TradingInitial) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final state = tradingState is TradingLoaded
              ? tradingState
              : const TradingLoaded(
                  virtualCash: 100000.0,
                  holdings: [],
                  orders: [],
                  transactions: [],
                );

          return BlocBuilder<MarketBloc, MarketState>(
            builder: (context, marketState) {
              final instruments = marketState is MarketLoaded
                  ? marketState.instruments
                  : <InstrumentModel>[];

              // Fast instrument lookup helper
              InstrumentModel? findInstrument(String symbol) {
                try {
                  return instruments.firstWhere(
                    (i) => i.symbol.toUpperCase() == symbol.toUpperCase(),
                  );
                } catch (_) {
                  return null;
                }
              }

              return Column(
                children: [
                  // 1. Portfolio Analytics Hero Card
                  PortfolioHeroCard(
                    totalValue: state.totalPortfolioValue,
                    availableCash: state.virtualCash,
                    totalInvested: state.totalInvested,
                    holdingsMarketValue: state.totalHoldingsMarketValue,
                    unrealizedPL: state.overallUnrealizedPL,
                    unrealizedPLPercent: state.overallUnrealizedPLPercent,
                  ),

                  // 2. Main Tab Segment Bar
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(AppStyles.radius12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          _buildTabItem(
                            index: 0,
                            label: 'Holdings (${state.holdings.length})',
                            isSelected: _selectedTab == 0,
                          ),
                          _buildTabItem(
                            index: 1,
                            label: state.pendingOrders.isNotEmpty
                                ? 'Orders (${state.pendingOrders.length})'
                                : 'Orders',
                            isSelected: _selectedTab == 1,
                            badgeCount: state.pendingOrders.length,
                          ),
                          _buildTabItem(
                            index: 2,
                            label: 'Ledger',
                            isSelected: _selectedTab == 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Tab Body
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTab,
                      children: [
                        // Tab 0: Holdings (Positions)
                        _buildHoldingsTab(
                          state: state,
                          findInstrument: findInstrument,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),

                        // Tab 1: Orders (Open & Completed)
                        _buildOrdersTab(
                          state: state,
                          findInstrument: findInstrument,
                          isDark: isDark,
                          surfaceColor: surfaceColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),

                        // Tab 2: Transaction Ledger
                        TransactionLedgerView(
                          transactions: state.transactions,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    required bool isSelected,
    int? badgeCount,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selection();
          setState(() => _selectedTab = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.primaryBlue
                    : AppColors.primaryBlue)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyles.radius8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppStyles.caption.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              if (badgeCount != null && badgeCount > 0 && !isSelected) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: const BoxDecoration(
                    color: AppColors.warningAmber,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoldingsTab({
    required TradingLoaded state,
    required InstrumentModel? Function(String) findInstrument,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (state.holdings.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
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
                  Icons.work_outline_rounded,
                  size: 32,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'No Open Positions Yet',
                style: AppStyles.titleMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Execute market or limit buy orders on any stock or crypto asset using your virtual capital to start building your portfolio.',
                textAlign: TextAlign.center,
                style: AppStyles.bodyMedium.copyWith(
                  color: textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.onExploreMarkets != null)
                AppButton(
                  text: 'Explore Markets',
                  icon: Icons.search_rounded,
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    AppHaptics.light();
                    widget.onExploreMarkets!();
                  },
                ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: state.holdings.length,
      itemBuilder: (context, index) {
        final holding = state.holdings[index];
        final instrument = findInstrument(holding.symbol);

        return HoldingCard(
          holding: holding,
          companyName: instrument?.name,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InstrumentDetailScreen(
                  symbol: holding.symbol,
                  initialInstrument: instrument,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersTab({
    required TradingLoaded state,
    required InstrumentModel? Function(String) findInstrument,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final pendingOrders = state.pendingOrders;
    final completedOrders = state.completedOrders;

    return Column(
      children: [
        // Sub-segmented Tab: Open Orders vs Completed Orders
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildSubTabButton(
                label: 'Open (${pendingOrders.length})',
                isSelected: _orderSubTab == 0,
                onTap: () => setState(() => _orderSubTab = 0),
              ),
              const SizedBox(width: 8),
              _buildSubTabButton(
                label: 'Completed (${completedOrders.length})',
                isSelected: _orderSubTab == 1,
                onTap: () => setState(() => _orderSubTab = 1),
              ),
            ],
          ),
        ),

        // Sub-Tab Content
        Expanded(
          child: _orderSubTab == 0
              ? _buildOpenOrdersList(
                  pendingOrders: pendingOrders,
                  findInstrument: findInstrument,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                )
              : _buildCompletedOrdersList(
                  completedOrders: completedOrders,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.darkSurfaceSecondary
                  : AppColors.lightSurfaceSecondary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppStyles.radiusFull),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppStyles.caption.copyWith(
            color: isSelected
                ? (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary)
                : textSecondaryColor(context),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Color textSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
  }

  Widget _buildOpenOrdersList({
    required List pendingOrders,
    required InstrumentModel? Function(String) findInstrument,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (pendingOrders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pending_actions_rounded,
                size: 40,
                color: textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                'No Pending Orders',
                style: AppStyles.titleMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Active Limit and Stop-Loss orders awaiting target price execution will be displayed here.',
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
      itemCount: pendingOrders.length,
      itemBuilder: (context, index) {
        final order = pendingOrders[index];
        final instrument = findInstrument(order.symbol);

        return OpenOrderCard(
          order: order,
          currentMarketPrice: instrument?.currentPrice,
          onCancelOrder: () {
            context.read<TradingBloc>().add(OrderCancelled(orderId: order.id));
          },
        );
      },
    );
  }

  Widget _buildCompletedOrdersList({
    required List completedOrders,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    if (completedOrders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 40,
                color: textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                'No Order History',
                style: AppStyles.titleMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Filled, partially filled, and cancelled trades will be logged here with complete execution receipts.',
                textAlign: TextAlign.center,
                style: AppStyles.caption.copyWith(color: textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Sort descending by creation/execution time
    final sortedList = List.from(completedOrders)
      ..sort((a, b) {
        final timeA = a.executedAt ?? a.createdAt;
        final timeB = b.executedAt ?? b.createdAt;
        return timeB.compareTo(timeA);
      });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final order = sortedList[index];
        return CompletedOrderCard(order: order);
      },
    );
  }
}
