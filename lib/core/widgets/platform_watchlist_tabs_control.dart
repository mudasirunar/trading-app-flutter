import 'package:flutter/material.dart';
import 'platform_segmented_tabs_control.dart';

export 'platform_segmented_tabs_control.dart';

/// Screen-specific platform-adaptive segmented control for Watchlists screen.
/// Delegates to the unified [PlatformSegmentedTabsControl] with Watchlist tabs ('My Watchlists' and 'All Markets').
class PlatformWatchlistTabsControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const PlatformWatchlistTabsControl({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformSegmentedTabsControl(
      selectedIndex: selectedIndex,
      tabs: const [
        SegmentTabData(
          label: 'My Watchlists',
          icon: Icons.star_rounded,
          iosIconName: 'star.fill',
        ),
        SegmentTabData(
          label: 'All Markets',
          icon: Icons.language_rounded,
          iosIconName: 'globe',
        ),
      ],
      onTabSelected: onTabSelected,
    );
  }
}
