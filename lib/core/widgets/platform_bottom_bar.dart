import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'liquid_glass_bottom_bar.dart';

/// Platform-adaptive bottom navigation bar:
/// - iOS: 100% Native UIKit `UITabBar` via `UiKitView` Platform View
/// - Android: Liquid Glass Drag-Physics Floating Bar (`LiquidGlassBottomBar`)
class PlatformBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onSearchTapped;

  const PlatformBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onSearchTapped,
  });

  static const List<LiquidNavItem> _tabs = [
    LiquidNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    LiquidNavItem(
      label: 'Watchlist',
      icon: Icons.star_outline_rounded,
      activeIcon: Icons.star_rounded,
    ),
    LiquidNavItem(
      label: 'Portfolio',
      icon: Icons.work_outline_rounded,
      activeIcon: Icons.work_rounded,
    ),
    LiquidNavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      return _IOSNativeTabBar(
        currentIndex: currentIndex,
        onTabSelected: onTabSelected,
      );
    }

    // Android / Fallback: Liquid Glass Drag-Physics Bar
    return LiquidGlassBottomBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      items: _tabs,
      primaryColor: AppColors.primaryBlue,
    );
  }
}

/// 100% Native Apple UIKit UITabBar embedded via UiKitView
class _IOSNativeTabBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _IOSNativeTabBar({
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  State<_IOSNativeTabBar> createState() => _IOSNativeTabBarState();
}

class _IOSNativeTabBarState extends State<_IOSNativeTabBar> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant _IOSNativeTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _channel?.invokeMethod('setTab', {'index': widget.currentIndex}).catchError((_) {});
    }
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('trading_app/native-tab-bar_$id');
    _channel!.setMethodCallHandler((call) async {
      if (call.method == 'onTabSelected') {
        final index = (call.arguments as Map)['index'] as int;
        widget.onTabSelected(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      height: 49.0 + bottomInset,
      child: UiKitView(
        viewType: 'trading_app/native-tab-bar',
        creationParams: {'selectedIndex': widget.currentIndex},
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }
}
