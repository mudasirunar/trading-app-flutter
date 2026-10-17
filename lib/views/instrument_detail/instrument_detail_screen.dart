import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/market/market_bloc.dart';
import '../../blocs/market/market_event.dart';
import '../../blocs/market/market_state.dart';
import '../../blocs/watchlist/watchlist_bloc.dart';
import '../../blocs/watchlist/watchlist_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_snack_bar.dart';
import '../../models/candle_model.dart';
import '../../models/instrument_model.dart';
import '../watchlist/widgets/add_to_watchlist_sheet.dart';
import 'widgets/interactive_financial_chart.dart';

/// Institutional-grade Instrument Detail Screen featuring live candlestick/line charts,
/// financial metrics grid, 52-week position slider, and paper trading execution shortcuts.
class InstrumentDetailScreen extends StatefulWidget {
  const InstrumentDetailScreen({
    super.key,
    required this.symbol,
    this.initialInstrument,
  });

  final String symbol;
  final InstrumentModel? initialInstrument;

  @override
  State<InstrumentDetailScreen> createState() => _InstrumentDetailScreenState();
}

class _InstrumentDetailScreenState extends State<InstrumentDetailScreen> {
  CandleModel? _scrubbedCandle;

  @override
  void initState() {
    super.initState();
    // Request candles for this instrument on load
    context.read<MarketBloc>().add(
          MarketTimeframeSelected(
            symbol: widget.symbol,
            timeframe: MarketTimeframe.oneDay,
          ),
        );
  }

  void _showOrderTicket({required bool isBuy, required InstrumentModel instrument}) {
    AppHaptics.medium();
    final action = isBuy ? 'Buy' : 'Sell';
    final actionColor = isBuy ? AppColors.bullGreen : AppColors.bearRed;

    AppBottomSheet.show(
      context: context,
      title: '$action ${instrument.symbol}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Execution Price (Market)',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                '\$${instrument.currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: actionColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: actionColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: actionColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paper trading order lifecycle engine will be fully connected in Phase 7.',
                    style: TextStyle(
                      fontSize: 12,
                      color: actionColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            text: 'Confirm Paper $action',
            onPressed: () {
              AppHaptics.success();
              Navigator.pop(context);
              AppSnackBar.showSuccess(
                context,
                'Simulated $action order ticket queued for ${instrument.symbol}.',
                title: 'Order Queued',
              );
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
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.symbol,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        actions: [
          BlocBuilder<WatchlistBloc, WatchlistState>(
            builder: (context, watchlistState) {
              final isSaved = watchlistState is WatchlistsLoaded &&
                  watchlistState.isSymbolInAnyWatchlist(widget.symbol);

              return IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: isSaved ? AppColors.primaryBlue : textSecondary,
                ),
                tooltip: 'Save to Watchlist',
                onPressed: () {
                  AppHaptics.light();
                  final currentInstrument = widget.initialInstrument ??
                      InstrumentModel(
                        symbol: widget.symbol,
                        name: widget.symbol,
                        exchange: 'US',
                        sector: 'Equities',
                        currentPrice: 100.0,
                        openPrice: 100.0,
                        high24h: 105.0,
                        low24h: 95.0,
                        previousClose: 100.0,
                        change: 0.0,
                        changePercentage: 0.0,
                        bidPrice: 99.9,
                        askPrice: 100.1,
                        spread: 0.2,
                        bidSize: 100,
                        askSize: 100,
                        volume: 1000000,
                        avgVolume: 1000000,
                        marketCap: 10000000000,
                        peRatio: 20.0,
                        eps: 5.0,
                        beta: 1.0,
                        dividendYield: 0.0,
                        week52High: 120.0,
                        week52Low: 80.0,
                        sparkline: const [100.0, 100.0, 100.0],
                        lastUpdated: DateTime.now(),
                      );
                  AddToWatchlistSheet.show(
                    context: context,
                    instrument: currentInstrument,
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<MarketBloc, MarketState>(
        builder: (context, state) {
          InstrumentModel? instrument;
          List<CandleModel> candles = const [];
          MarketTimeframe activeTimeframe = MarketTimeframe.oneDay;

          if (state is MarketLoaded) {
            try {
              instrument = state.instruments.firstWhere(
                (i) => i.symbol.toUpperCase() == widget.symbol.toUpperCase(),
              );
            } catch (_) {
              instrument = widget.initialInstrument;
            }
            candles = state.selectedCandles;
            activeTimeframe = state.activeTimeframe;
          } else {
            instrument = widget.initialInstrument;
          }

          if (instrument == null) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final displayPrice = _scrubbedCandle != null
              ? _scrubbedCandle!.close
              : instrument.currentPrice;

          final change = _scrubbedCandle != null
              ? _scrubbedCandle!.close - instrument.openPrice
              : instrument.change;

          final changePercent = instrument.openPrice > 0
              ? (change / instrument.openPrice) * 100
              : 0.0;

          final isPositive = change >= 0;
          final trendColor = isPositive ? AppColors.bullGreen : AppColors.bearRed;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: Symbol, Name, Exchange & Sector Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  instrument.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkSurfaceSecondary
                                            : AppColors.lightSurfaceSecondary,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Text(
                                        instrument.exchange,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      instrument.sector,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Live Venue Status Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
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
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  'SIM EXCHANGE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Large Real-Time Price & 24h Metrics
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '\$${displayPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: trendColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.arrow_drop_up_rounded
                                      : Icons.arrow_drop_down_rounded,
                                  color: trendColor,
                                  size: 18,
                                ),
                                Text(
                                  '${isPositive ? '+' : ''}\$${change.abs().toStringAsFixed(2)} (${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: trendColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Order Book Bid/Ask Spread Bar
                      const SizedBox(height: 8),
                      Text(
                        'Bid: \$${instrument.bidPrice.toStringAsFixed(2)} x ${instrument.bidSize}  •  Ask: \$${instrument.askPrice.toStringAsFixed(2)} x ${instrument.askSize}  •  Spread: \$${instrument.spread.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Interactive Financial Chart Widget
                      InteractiveFinancialChart(
                        candles: candles,
                        activeTimeframe: activeTimeframe,
                        onTimeframeChanged: (tf) {
                          context.read<MarketBloc>().add(
                                MarketTimeframeSelected(
                                  symbol: instrument!.symbol,
                                  timeframe: tf,
                                ),
                              );
                        },
                        onCandleScrubbed: (candle) {
                          setState(() => _scrubbedCandle = candle);
                        },
                      ),

                      const SizedBox(height: 24),

                      // 52-Week Range Visual Slider Card
                      _FiftyTwoWeekRangeCard(instrument: instrument),

                      const SizedBox(height: 22),

                      // Key Financial Statistics Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Key Statistics',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceSecondary
                                  : AppColors.lightSurfaceSecondary,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: borderColor.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  size: 12,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Fundamentals',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.62,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _StatCard(
                            label: 'Day Range',
                            value: '\$${instrument.low24h.toStringAsFixed(2)} - \$${instrument.high24h.toStringAsFixed(2)}',
                            icon: Icons.swap_horiz_rounded,
                            iconColor: AppColors.primaryBlue,
                            badgeText: 'Today',
                            badgeColor: AppColors.primaryBlue,
                            subWidget: _buildDayRangeMicroTrack(instrument, isDark),
                          ),
                          _StatCard(
                            label: 'Market Cap',
                            value: _formatMarketCap(instrument.marketCap),
                            icon: Icons.pie_chart_outline_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            badgeText: _getMarketCapCategory(instrument.marketCap),
                            badgeColor: const Color(0xFF8B5CF6),
                            subtitle: 'Total Equity Value',
                          ),
                          _StatCard(
                            label: 'Volume',
                            value: _formatNumber(instrument.volume),
                            icon: Icons.bar_chart_rounded,
                            iconColor: AppColors.bullGreen,
                            badgeText: 'Shares',
                            badgeColor: AppColors.bullGreen,
                            subtitle: instrument.volume >= instrument.avgVolume
                                ? 'Above 30D Avg'
                                : 'Normal Activity',
                          ),
                          _StatCard(
                            label: 'Avg Volume',
                            value: _formatNumber(instrument.avgVolume),
                            icon: Icons.query_stats_rounded,
                            iconColor: AppColors.infoCyan,
                            badgeText: '30D',
                            badgeColor: AppColors.infoCyan,
                            subtitle: '30-Day Mean Flow',
                          ),
                          _StatCard(
                            label: 'P/E Ratio',
                            value: instrument.peRatio > 0
                                ? instrument.peRatio.toStringAsFixed(1)
                                : 'N/A',
                            icon: Icons.calculate_outlined,
                            iconColor: AppColors.warningAmber,
                            badgeText: 'TTM',
                            badgeColor: AppColors.warningAmber,
                            subtitle: 'Valuation Multiple',
                          ),
                          _StatCard(
                            label: 'EPS (TTM)',
                            value: '\$${instrument.eps.toStringAsFixed(2)}',
                            icon: Icons.monetization_on_outlined,
                            iconColor: const Color(0xFF10B981),
                            badgeText: 'Diluted',
                            badgeColor: const Color(0xFF10B981),
                            subtitle: 'Earnings Per Share',
                          ),
                          _StatCard(
                            label: 'Beta',
                            value: instrument.beta.toStringAsFixed(2),
                            icon: Icons.speed_rounded,
                            iconColor: _getBetaColor(instrument.beta),
                            badgeText: _getBetaBadge(instrument.beta),
                            badgeColor: _getBetaColor(instrument.beta),
                            subtitle: 'vs. S&P 500 Index',
                          ),
                          _StatCard(
                            label: 'Dividend Yield',
                            value: '${instrument.dividendYield.toStringAsFixed(2)}%',
                            icon: Icons.savings_outlined,
                            iconColor: const Color(0xFF0D9488),
                            badgeText: 'Annual',
                            badgeColor: const Color(0xFF0D9488),
                            subtitle: 'Distribution Yield',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Buy / Sell Trade Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Buy',
                          variant: AppButtonVariant.primary,
                          onPressed: () => _showOrderTicket(
                            isBuy: true,
                            instrument: instrument!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Sell',
                          variant: AppButtonVariant.danger,
                          onPressed: () => _showOrderTicket(
                            isBuy: false,
                            instrument: instrument!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayRangeMicroTrack(InstrumentModel instrument, bool isDark) {
    final low = instrument.low24h;
    final high = instrument.high24h;
    final current = instrument.currentPrice;
    final ratio = high > low ? ((current - low) / (high - low)).clamp(0.0, 1.0) : 0.5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const dotSize = 8.0;
        final dotLeft = (width - dotSize) * ratio;

        return SizedBox(
          height: 10,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 3,
                width: width,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.primaryBlue,
                        AppColors.infoCyan,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              Positioned(
                left: dotLeft,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMarketCapCategory(double cap) {
    if (cap >= 200e9) {
      return 'Mega Cap';
    } else if (cap >= 10e9) {
      return 'Large Cap';
    } else if (cap >= 2e9) {
      return 'Mid Cap';
    } else {
      return 'Small Cap';
    }
  }

  String _getBetaBadge(double beta) {
    if (beta > 1.3) return 'High Vol';
    if (beta < 0.8) return 'Low Vol';
    return 'Moderate';
  }

  Color _getBetaColor(double beta) {
    if (beta > 1.3) return AppColors.bearRed;
    if (beta < 0.8) return AppColors.bullGreen;
    return AppColors.primaryBlue;
  }

  String _formatMarketCap(double cap) {
    if (cap >= 1e12) {
      return '\$${(cap / 1e12).toStringAsFixed(2)}T';
    } else if (cap >= 1e9) {
      return '\$${(cap / 1e9).toStringAsFixed(2)}B';
    } else if (cap >= 1e6) {
      return '\$${(cap / 1e6).toStringAsFixed(2)}M';
    }
    return '\$${cap.toStringAsFixed(0)}';
  }

  String _formatNumber(double num) {
    if (num >= 1e6) {
      return '${(num / 1e6).toStringAsFixed(1)}M';
    } else if (num >= 1e3) {
      return '${(num / 1e3).toStringAsFixed(1)}K';
    }
    return num.toStringAsFixed(0);
  }
}

/// Institutional 52-Week Range indicator featuring an illuminated position thumb,
/// smooth gradient spread, and clear boundary analytics.
class _FiftyTwoWeekRangeCard extends StatelessWidget {
  const _FiftyTwoWeekRangeCard({required this.instrument});

  final InstrumentModel instrument;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final low = instrument.week52Low;
    final high = instrument.week52High;
    final current = instrument.currentPrice;
    final ratio = high > low
        ? ((current - low) / (high - low)).clamp(0.0, 1.0)
        : 0.5;
    final percentage = (ratio * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.candlestick_chart_rounded,
                      size: 17,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '52-Week Range',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'ANNUAL TRADING SPREAD',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '\$${current.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryBlue,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Visual Range Track with Illuminated Marker
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              const thumbWidth = 14.0;
              const thumbHeight = 16.0;
              final thumbLeft = (trackWidth - thumbWidth) * ratio;

              return SizedBox(
                height: 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Background Track
                    Container(
                      height: 6,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceSecondary
                            : AppColors.lightSurfaceSecondary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // Gradient Fill Track
                    Container(
                      height: 6,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue.withValues(alpha: 0.35),
                            AppColors.infoCyan.withValues(alpha: 0.5),
                            AppColors.bullGreen.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                    // Active Progress Shade
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.infoCyan,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Illuminated Floating Thumb
                    Positioned(
                      left: thumbLeft,
                      top: (24 - thumbHeight) / 2,
                      child: Container(
                        width: thumbWidth,
                        height: thumbHeight,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 2,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // Bottom Stats: Low, Percentile Badge, High
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '52W LOW',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${low.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceSecondary
                      : AppColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: borderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      size: 11,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$percentage% of range',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '52W HIGH',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${high.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Refined institutional key metric card with category badges, iconography,
/// and micro-visual telemetry.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.badgeText,
    this.badgeColor,
    this.subWidget,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? badgeText;
  final Color? badgeColor;
  final Widget? subWidget;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final resolvedBadgeColor = badgeColor ?? textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Row: Icon + Label + Tag
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 13,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: resolvedBadgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: resolvedBadgeColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Main Value
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
            ),
          ),

          // Bottom Context / Micro-Widget
          if (subWidget != null)
            subWidget!
          else if (subtitle != null)
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else
            const SizedBox(height: 2),
        ],
      ),
    );
  }
}
