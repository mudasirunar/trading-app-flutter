import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/market/market_bloc.dart';
import '../../blocs/market/market_state.dart';
import '../../blocs/watchlist/watchlist_bloc.dart';
import '../../blocs/watchlist/watchlist_event.dart';
import '../../blocs/watchlist/watchlist_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/utils/instrument_search_helper.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/market_search_bar.dart';
import '../../core/widgets/platform_watchlist_tabs_control.dart';
import '../../models/instrument_model.dart';
import '../discovery/instrument_search_screen.dart';
import 'widgets/create_watchlist_dialog.dart';
import 'widgets/manage_watchlist_sheet.dart';
import 'widgets/watchlist_card.dart';

/// Full-featured Watchlist tab displaying user-curated asset collections,
/// real-time telemetry, pill tab switching, and collection management.
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({
    super.key,
    this.onNavigateToSearch,
    this.initialSegment = 0,
  });

  final VoidCallback? onNavigateToSearch;
  final int initialSegment;

  @override
  State<WatchlistScreen> createState() => WatchlistScreenState();
}

class WatchlistScreenState extends State<WatchlistScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';
  late int _selectedSegment; // 0: My Watchlists, 1: All Markets

  @override
  void initState() {
    super.initState();
    _selectedSegment = widget.initialSegment;
  }

  @override
  void didUpdateWidget(covariant WatchlistScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSegment != oldWidget.initialSegment) {
      _selectedSegment = widget.initialSegment;
    }
  }

  void selectSegment(int index) {
    if (_selectedSegment != index) {
      setState(() {
        _selectedSegment = index;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateDialog(BuildContext context) {
    AppHaptics.light();
    CreateWatchlistDialog.show(
      context: context,
      onConfirm: (name) {
        context.read<WatchlistBloc>().add(WatchlistCreated(name: name));
      },
    );
  }

  void _showRenameDialog(BuildContext context, String id, String currentName) {
    AppHaptics.light();
    CreateWatchlistDialog.show(
      context: context,
      initialName: currentName,
      isRename: true,
      onConfirm: (newName) {
        context.read<WatchlistBloc>().add(
              WatchlistRenamed(id: id, newName: newName),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocBuilder<WatchlistBloc, WatchlistState>(
      builder: (context, watchlistState) {
        if (watchlistState is WatchlistsLoading || watchlistState is WatchlistsInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (watchlistState is WatchlistsFailure) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.bearRed, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to Load Watchlists',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      watchlistState.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Retry',
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        context.read<WatchlistBloc>().add(const WatchlistsLoadRequested());
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final state = watchlistState as WatchlistsLoaded;
        final watchlists = state.watchlists;
        final activeWatchlist = state.activeWatchlist;

        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            titleSpacing: 16,
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.centerLeft,
                children: <Widget>[
                  ...previousChildren,
                  ?currentChild,
                ],
              ),
              child: Text(
                _selectedSegment == 0 ? 'Watchlists' : 'Market Discovery',
                key: ValueKey<int>(_selectedSegment),
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
              ),
            ),
            actions: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _selectedSegment == 0
                    ? Row(
                        key: const ValueKey('watchlist_actions'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            tooltip: 'Create Watchlist',
                            onPressed: () => _showCreateDialog(context),
                          ),
                          if (activeWatchlist != null)
                            IconButton(
                              icon: const Icon(Icons.more_horiz_rounded),
                              tooltip: 'Manage Watchlist',
                              onPressed: () {
                                AppHaptics.light();
                                ManageWatchlistSheet.show(
                                  context: context,
                                  watchlist: activeWatchlist,
                                  totalWatchlists: watchlists.length,
                                  onRename: () => _showRenameDialog(
                                    context,
                                    activeWatchlist.id,
                                    activeWatchlist.name,
                                  ),
                                  onDelete: () {
                                    context.read<WatchlistBloc>().add(
                                          WatchlistDeleted(id: activeWatchlist.id),
                                        );
                                  },
                                  onResetDefaults: () {
                                    context.read<WatchlistBloc>().add(
                                          const WatchlistsResetRequested(),
                                        );
                                  },
                                );
                              },
                            ),
                          const SizedBox(width: 8),
                        ],
                      )
                    : const SizedBox.shrink(key: ValueKey('empty_actions')),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 0. Top Segmented Switch: Watchlists vs All Markets (Native iOS / Liquid Glass Android)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PlatformWatchlistTabsControl(
                  selectedIndex: _selectedSegment,
                  onTabSelected: (index) {
                    if (_selectedSegment != index) {
                      AppHaptics.selection();
                      setState(() => _selectedSegment = index);
                    }
                  },
                ),
              ),

              if (_selectedSegment == 1)
                const Expanded(
                  child: InstrumentSearchScreen(showAppBar: false),
                )
              else ...[
                // 1. Reusable Market Search Bar (Consistent with All Markets)
                MarketSearchBar(
                  controller: _searchController,
                  hintText: 'Filter ${activeWatchlist?.name ?? 'watchlist'}...',
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  onChanged: (val) => setState(() => _filterQuery = val.trim().toLowerCase()),
                  onClear: () => setState(() => _filterQuery = ''),
                ),

                // 2. Horizontal Watchlist Tabs (Consistent 38dp height with Sector Chips)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: watchlists.length + 1,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == watchlists.length) {
                        // New Watchlist Pill Button
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showCreateDialog(context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded, size: 16, color: AppColors.primaryBlue),
                                const SizedBox(width: 4),
                                Text(
                                  'New List',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final list = watchlists[index];
                      final isSelected = list.id == activeWatchlist?.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          AppHaptics.selection();
                          context.read<WatchlistBloc>().add(WatchlistSelected(watchlistId: list.id));
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : (isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryBlue : borderColor,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  list.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.white : textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : (isDark
                                            ? AppColors.darkSurface
                                            : AppColors.lightSurface),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${list.symbols.length}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Dynamic Instrument List
                Expanded(
                  child: BlocBuilder<MarketBloc, MarketState>(
                    builder: (context, marketState) {
                      if (activeWatchlist == null || activeWatchlist.symbols.isEmpty) {
                        return _buildEmptyState(context, isDark, textPrimary, textSecondary);
                      }

                      final allInstruments = marketState is MarketLoaded
                          ? marketState.instruments
                          : <InstrumentModel>[];

                      final symbols = activeWatchlist.symbols;
                      final matchingInstruments = symbols.map((sym) {
                        return allInstruments.firstWhere(
                          (item) => item.symbol.toUpperCase() == sym.toUpperCase(),
                          orElse: () => InstrumentModel(
                            symbol: sym,
                            name: sym,
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
                          ),
                        );
                      }).toList();

                      final filtered = _filterQuery.isEmpty
                          ? matchingInstruments
                          : InstrumentSearchHelper.filterInstruments(
                              matchingInstruments,
                              _filterQuery,
                            );

                      if (filtered.isEmpty && _filterQuery.isNotEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 54,
                                  color: textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No matching instruments',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No assets in "${activeWatchlist.name}" match "$_filterQuery".',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _filterQuery = '');
                                  },
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text(
                                    'Clear Search',
                                    style: TextStyle(
                                      fontSize: 12.5,
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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return WatchlistCard(
                          instrument: item,
                          onRemove: () {
                            context.read<WatchlistBloc>().add(
                                  WatchlistSymbolToggled(
                                    watchlistId: activeWatchlist.id,
                                    symbol: item.symbol,
                                  ),
                                );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                size: 36,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Assets in this Watchlist',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add symbols from search or instrument detail to track real-time price updates and mini sparklines.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              text: 'Discover All Markets',
              variant: AppButtonVariant.primary,
              onPressed: () {
                AppHaptics.light();
                setState(() => _selectedSegment = 1);
              },
            ),
          ],
        ),
      ),
    );
  }
}
