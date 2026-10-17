import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/market/market_bloc.dart';
import '../../blocs/market/market_event.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/widgets/platform_bottom_bar.dart';
import '../dashboard/dashboard_screen.dart';
import '../portfolio/portfolio_screen.dart';
import '../settings/settings_screen.dart';
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
          const SettingsScreen(),
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
