import 'package:flutter/material.dart';
import 'platform_segmented_tabs_control.dart';

export 'platform_segmented_tabs_control.dart';

/// Screen-specific platform-adaptive segmented control for Price Alerts.
/// Delegates to the unified [PlatformSegmentedTabsControl] with pure text (strictly no icons)
/// and dynamic count badges for Active and Triggered alert states.
class PlatformAlertsTabsControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final int activeCount;
  final int triggeredCount;

  const PlatformAlertsTabsControl({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.activeCount = 0,
    this.triggeredCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return PlatformSegmentedTabsControl(
      selectedIndex: selectedIndex,
      tabs: [
        SegmentTabData(
          label: 'Active ($activeCount)',
          // Pure text: icon and iosIconName are null
        ),
        SegmentTabData(
          label: 'Triggered ($triggeredCount)',
          // Pure text: icon and iosIconName are null
        ),
      ],
      onTabSelected: onTabSelected,
    );
  }
}
