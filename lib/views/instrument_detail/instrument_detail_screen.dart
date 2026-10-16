import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/market/market_bloc.dart';
import '../../blocs/market/market_event.dart';
import '../../blocs/market/market_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/app_bottom_sheet.dart';
import '../../core/widgets/app_button.dart';
import '../../models/candle_model.dart';
import '../../models/instrument_model.dart';
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
  bool _isWatchlisted = false;

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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Simulated $action order ticket queued for ${instrument.symbol}.'),
                  duration: const Duration(seconds: 2),
                ),
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
          IconButton(
            icon: Icon(
              _isWatchlisted ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isWatchlisted ? AppColors.primaryBlue : textSecondary,
            ),
            tooltip: 'Watchlist',
            onPressed: () {
              AppHaptics.light();
              setState(() => _isWatchlisted = !_isWatchlisted);
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
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '52-Week Range',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  '\$${instrument.currentPrice.toStringAsFixed(2)} Current',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final low = instrument!.week52Low;
                                final high = instrument.week52High;
                                final current = instrument.currentPrice;
                                final ratio = high > low
                                    ? ((current - low) / (high - low)).clamp(0.0, 1.0)
                                    : 0.5;

                                return Stack(
                                  children: [
                                    Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkSurfaceSecondary
                                            : AppColors.lightSurfaceSecondary,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: ratio,
                                      child: Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Low: \$${instrument.week52Low.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                                Text(
                                  'High: \$${instrument.week52High.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 11, color: textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Key Financial Statistics Grid
                      Text(
                        'Key Statistics',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _StatTile(
                            label: 'Day Range',
                            value: '\$${instrument.low24h.toStringAsFixed(2)} - \$${instrument.high24h.toStringAsFixed(2)}',
                          ),
                          _StatTile(
                            label: 'Market Cap',
                            value: _formatMarketCap(instrument.marketCap),
                          ),
                          _StatTile(
                            label: 'Volume',
                            value: _formatNumber(instrument.volume),
                          ),
                          _StatTile(
                            label: 'Avg Volume (30D)',
                            value: _formatNumber(instrument.avgVolume),
                          ),
                          _StatTile(
                            label: 'P/E Ratio',
                            value: instrument.peRatio > 0
                                ? instrument.peRatio.toStringAsFixed(1)
                                : 'N/A',
                          ),
                          _StatTile(
                            label: 'EPS (TTM)',
                            value: '\$${instrument.eps.toStringAsFixed(2)}',
                          ),
                          _StatTile(
                            label: 'Beta',
                            value: instrument.beta.toStringAsFixed(2),
                          ),
                          _StatTile(
                            label: 'Dividend Yield',
                            value: '${instrument.dividendYield.toStringAsFixed(2)}%',
                          ),
                        ],
                      ),
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

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
