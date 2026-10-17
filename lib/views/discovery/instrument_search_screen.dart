import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/market/market_bloc.dart';
import '../../blocs/market/market_event.dart';
import '../../blocs/market/market_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/market_search_bar.dart';
import '../../core/widgets/sparkline_chart.dart';
import '../../models/instrument_model.dart';
import '../instrument_detail/instrument_detail_screen.dart';

/// Institutional instrument discovery screen with live debounced search and sector filtering.
class InstrumentSearchScreen extends StatefulWidget {
  const InstrumentSearchScreen({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<InstrumentSearchScreen> createState() => _InstrumentSearchScreenState();
}

class _InstrumentSearchScreenState extends State<InstrumentSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedSector;

  static const List<String> _sectors = [
    'All',
    'Technology',
    'Semiconductors',
    'Financial Services',
    'Healthcare',
    'Consumer Cyclical',
    'Consumer Staples',
    'Energy',
    'Automotive',
  ];

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<MarketBloc>().add(
          MarketSearchQueryChanged(
            query: query,
            sector: _selectedSector == 'All' ? null : _selectedSector,
          ),
        );
  }

  void _onSectorSelected(String sector) {
    AppHaptics.selection();
    setState(() {
      _selectedSector = sector == 'All' ? null : sector;
    });
    context.read<MarketBloc>().add(
          MarketSearchQueryChanged(
            query: _searchController.text,
            sector: _selectedSector,
          ),
        );
  }

  void _clearSearchAndResetAll() {
    _searchController.clear();
    setState(() {
      _selectedSector = null;
    });
    context.read<MarketBloc>().add(
          const MarketSearchQueryChanged(
            query: '',
            sector: null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final content = Column(
        children: [
          // Enhanced Rounded Search Input Bar with Dynamic Focus Glow
          MarketSearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            onClear: _clearSearchAndResetAll,
          ),

          // Horizontal Sector Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _sectors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sector = _sectors[index];
                final isSelected = (_selectedSector == null && sector == 'All') ||
                    _selectedSector == sector;

                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _onSectorSelected(sector),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : (isDark
                              ? AppColors.darkSurfaceSecondary
                              : AppColors.lightSurfaceSecondary),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : borderColor,
                      ),
                    ),
                    child: Text(
                      sector,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Filtered Instruments List
          Expanded(
            child: BlocBuilder<MarketBloc, MarketState>(
              builder: (context, state) {
                if (state is MarketLoading) {
                  return const Center(child: CircularProgressIndicator.adaptive());
                }

                if (state is! MarketLoaded) {
                  return const Center(child: Text('Market feed initializing...'));
                }

                final instruments = state.searchResults;

                if (instruments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isDark
                                      ? AppColors.darkSurfaceSecondary
                                      : AppColors.lightSurfaceSecondary)
                                  .withValues(alpha: 0.6),
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              size: 44,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No instruments found',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No ticker symbols, companies, or sectors match your search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Action Button for clearing search & filters CTA
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _clearSearchAndResetAll,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text(
                              'Clear Search & Filters',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  addAutomaticKeepAlives: false,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: instruments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = instruments[index];
                    return _InstrumentCard(
                      key: ValueKey(item.symbol),
                      instrument: item,
                    );
                  },
                );
              },
            ),
          ),
        ],
      );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          'Market Discovery',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
      ),
      body: content,
    );
  }
}

class _InstrumentCard extends StatelessWidget {
  const _InstrumentCard({super.key, required this.instrument});

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

    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Left: Ticker & Name
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          instrument.symbol,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceSecondary
                                : AppColors.lightSurfaceSecondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            instrument.exchange,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      instrument.name,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Center: Mini Sparkline
              Expanded(
                flex: 3,
                child: Center(
                  child: SparklineChart(
                    data: instrument.sparkline,
                    width: 68,
                    height: 28,
                    overrideColor: trendColor,
                  ),
                ),
              ),

              // Right: Price & Change Pill
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${instrument.currentPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${isPositive ? '+' : ''}${instrument.changePercentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
