import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/market/market_bloc.dart';
import '../../blocs/market/market_event.dart';
import '../../blocs/market/market_state.dart';
import '../../blocs/watchlist/watchlist_bloc.dart';
import '../../blocs/watchlist/watchlist_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/sparkline_chart.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/platform_segmented_movers_control.dart';
import '../../models/instrument_model.dart';
import '../discovery/instrument_search_screen.dart';
import '../instrument_detail/instrument_detail_screen.dart';

enum MarketMoversTab { gainers, losers, active }

/// Central executive trading terminal dashboard.
/// Features portfolio balance, live ticker sparkline carousel, and market movers.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.onNavigateToSearch});

  final VoidCallback? onNavigateToSearch;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  MarketMoversTab _selectedMoverTab = MarketMoversTab.gainers;

  @override
  void initState() {
    super.initState();
    final currentMarket = context.read<MarketBloc>().state;
    if (currentMarket is! MarketLoaded || !currentMarket.isFeedLive) {
      context.read<MarketBloc>().add(const MarketStarted());
    }
  }

  void _showDepositDialog() {
    AppHaptics.light();
    AppDialog.show(
      context: context,
      type: AppDialogType.success,
      title: 'Virtual Capital Active',
      message:
          'Your account is funded with \$100,000.00 USD virtual capital in the institutional sandbox. No additional deposit is required.',
      primaryButtonText: 'Understood',
      onPrimaryPressed: () {},
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bullGreen,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'TRADING TERMINAL',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is Authenticated) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: StatusBadge(
                    customLabel: authState.user.isPro ? 'PRO TIER' : 'PRACTICE',
                    customColor: authState.user.isPro
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF3B82F6),
                    leading: authState.user.isPro
                        ? const CrownIcon(size: 11, color: Color(0xFFF59E0B))
                        : null,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<MarketBloc, MarketState>(
        builder: (context, state) {
          final instruments = state is MarketLoaded ? state.instruments : <InstrumentModel>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Virtual Portfolio Summary Card
                _PortfolioSummaryCard(
                  isDark: isDark,
                  instruments: instruments,
                ),

                const SizedBox(height: 18),

                // 2. Quick Action Shortcut Grid
                Row(
                  children: [
                    _QuickActionButton(
                      icon: Icons.search_rounded,
                      label: 'Explore',
                      onTap: () {
                        AppHaptics.light();
                        if (widget.onNavigateToSearch != null) {
                          widget.onNavigateToSearch!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InstrumentSearchScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    _QuickActionButton(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Funds',
                      onTap: _showDepositDialog,
                    ),
                    const SizedBox(width: 10),
                    _QuickActionButton(
                      icon: Icons.notifications_none_rounded,
                      label: 'Alerts',
                      onTap: () {
                        AppHaptics.light();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Price Alerts module will connect in Phase 9.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Watchlist Highlights Header & Carousel
                BlocBuilder<WatchlistBloc, WatchlistState>(
                  builder: (context, watchlistState) {
                    final activeList = watchlistState is WatchlistsLoaded
                        ? watchlistState.activeWatchlist
                        : null;
                    final watchedSymbols = activeList?.symbols ?? const <String>[];
                    final highlightedInstruments = watchedSymbols.isNotEmpty
                        ? watchedSymbols
                            .map((sym) => instruments.where((i) => i.symbol.toUpperCase() == sym.toUpperCase()).firstOrNull)
                            .whereType<InstrumentModel>()
                            .toList()
                        : instruments.take(8).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              activeList != null ? '${activeList.name} Highlights' : 'Watchlist Highlights',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                AppHaptics.light();
                                if (widget.onNavigateToSearch != null) {
                                  widget.onNavigateToSearch!();
                                }
                              },
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (instruments.isEmpty)
                          Container(
                            height: 110,
                            alignment: Alignment.center,
                            child: const CircularProgressIndicator.adaptive(),
                          )
                        else
                          SizedBox(
                            height: 125,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: highlightedInstruments.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final item = highlightedInstruments[index];
                                return _WatchlistHighlightCard(instrument: item);
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 26),

                // 4. Market Movers Section (Stacked with clipBehavior: Clip.none so expanding pill paints ABOVE the cards)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: _buildMoversList(instruments),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Market Movers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        // Movers Platform-Adaptive Segmented Control (Sliding Pill, No Glow)
                        PlatformSegmentedMoversControl(
                          selectedIndex: _selectedMoverTab.index,
                          onTabSelected: (index) {
                            setState(() => _selectedMoverTab = MarketMoversTab.values[index]);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoversList(List<InstrumentModel> all) {
    if (all.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final sorted = List<InstrumentModel>.from(all);
    switch (_selectedMoverTab) {
      case MarketMoversTab.gainers:
        sorted.sort((a, b) => b.changePercentage.compareTo(a.changePercentage));
        break;
      case MarketMoversTab.losers:
        sorted.sort((a, b) => a.changePercentage.compareTo(b.changePercentage));
        break;
      case MarketMoversTab.active:
        sorted.sort((a, b) => b.volume.compareTo(a.volume));
        break;
    }

    final topMovers = sorted.take(5).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topMovers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = topMovers[index];
        final isPositive = item.change >= 0;
        final trendColor = isPositive ? AppColors.bullGreen : AppColors.bearRed;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Material(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              AppHaptics.light();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InstrumentDetailScreen(
                    symbol: item.symbol,
                    initialInstrument: item,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Rank Badge
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (isDark
                              ? AppColors.darkSurfaceSecondary
                              : AppColors.lightSurfaceSecondary),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Symbol & Company
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.symbol,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Mini Sparkline
                  SparklineChart(
                    data: item.sparkline,
                    width: 60,
                    height: 24,
                    overrideColor: trendColor,
                  ),

                  const SizedBox(width: 16),

                  // Price & Change
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${item.currentPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        '${isPositive ? '+' : ''}${item.changePercentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PortfolioSummaryCard extends StatelessWidget {
  const _PortfolioSummaryCard({
    required this.isDark,
    this.instruments = const [],
  });

  final bool isDark;
  final List<InstrumentModel> instruments;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Dynamically calculate composite market performance across live feed
    final double avgChangePct;
    if (instruments.isNotEmpty) {
      final total = instruments.fold<double>(
        0.0,
        (acc, item) => acc + item.changePercentage,
      );
      avgChangePct = total / instruments.length;
    } else {
      avgChangePct = 0.0;
    }

    final dayDollar = 100000.0 * (avgChangePct / 100.0);
    final portfolioValue = 100000.0 + dayDollar;
    final isPositive = dayDollar >= 0;
    final trendColor = isPositive ? AppColors.bullGreen : AppColors.bearRed;

    // Helper for formatting with thousand commas
    String formatCurrency(double val) {
      final parts = val.toStringAsFixed(2).split('.');
      final whole = parts[0];
      final decimal = parts[1];
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      final formattedWhole = whole.replaceAllMapped(reg, (Match m) => '${m[1]},');
      return '\$$formattedWhole.$decimal';
    }

    final formattedValue = formatCurrency(portfolioValue);
    final sign = isPositive ? '+' : '-';
    final formattedDollar = '\$${dayDollar.abs().toStringAsFixed(2)}';
    final formattedPct = '${avgChangePct.abs().toStringAsFixed(2)}%';
    final returnText = '$sign$formattedDollar ($sign$formattedPct) Today';

    // Compute composite sparkline from catalog
    List<double> sparklineData = const [];
    if (instruments.isNotEmpty) {
      final sample = instruments.first.sparkline;
      if (sample.isNotEmpty) {
        final len = sample.length;
        final aggregated = List<double>.filled(len, 0.0);
        for (final inst in instruments) {
          if (inst.sparkline.length == len) {
            for (var i = 0; i < len; i++) {
              aggregated[i] += inst.sparkline[i];
            }
          }
        }
        sparklineData = aggregated.map((v) => v / instruments.length).toList();
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Label & Live Feed Status Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VIRTUAL PORTFOLIO VALUE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bullGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bullGreen,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'LIVE FEED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bullGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Total Equity Value & Trend Sparkline
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              if (sparklineData.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: SparklineChart(
                    data: sparklineData,
                    width: 76,
                    height: 32,
                    overrideColor: trendColor,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Day Return Badge & Buying Power Row (Overflow-proof)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 15,
                        color: trendColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          returnText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: trendColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Power: \$100k',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WatchlistHighlightCard extends StatelessWidget {
  const _WatchlistHighlightCard({required this.instrument});

  final InstrumentModel instrument;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final isPositive = instrument.change >= 0;
    final trendColor = isPositive ? AppColors.bullGreen : AppColors.bearRed;

    String formatPrice(double price) {
      if (price >= 1000.0) {
        final parts = price.toStringAsFixed(2).split('.');
        final whole = parts[0].replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
        return '\$$whole.${parts[1]}';
      }
      return '\$${price.toStringAsFixed(2)}';
    }

    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          AppHaptics.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstrumentDetailScreen(
                symbol: instrument.symbol,
                initialInstrument: instrument,
              ),
            ),
          );
        },
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    instrument.symbol,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  SparklineChart(
                    data: instrument.sparkline,
                    width: 48,
                    height: 20,
                    overrideColor: trendColor,
                  ),
                ],
              ),
              Text(
                instrument.name,
                style: TextStyle(fontSize: 11, color: textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      formatPrice(instrument.currentPrice),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}${instrument.changePercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Expanded(
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


