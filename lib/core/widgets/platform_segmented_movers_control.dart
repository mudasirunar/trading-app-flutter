import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../utils/app_haptics.dart';

/// Platform-adaptive segmented movers control:
/// - iOS: 100% Native UIKit Apple Liquid Glass Control via `UiKitView` Platform View
/// - Android / Fallback: Custom Flutter Liquid Glass Drag-Physics Control (`_AndroidLiquidGlassSegmentedControl`)
class PlatformSegmentedMoversControl extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const PlatformSegmentedMoversControl({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      return _IOSNativeSegmentedControl(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      );
    }

    // Android / Fallback: Liquid Glass Drag-Physics Segmented Control
    return _AndroidLiquidGlassSegmentedControl(
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
    );
  }
}

/// 100% Native Apple UIKit Liquid Glass Control embedded via UiKitView
class _IOSNativeSegmentedControl extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _IOSNativeSegmentedControl({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_IOSNativeSegmentedControl> createState() =>
      _IOSNativeSegmentedControlState();
}

class _IOSNativeSegmentedControlState
    extends State<_IOSNativeSegmentedControl> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant _IOSNativeSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _channel?.invokeMethod('setTab', {
        'index': widget.selectedIndex,
      }).catchError((_) {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _channel?.invokeMethod('setTheme', {'isDark': isDark}).catchError((_) {});
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('trading_app/native-segmented-control_$id');
    _channel!.setMethodCallHandler((call) async {
      if (call.method == 'onTabSelected') {
        final index = (call.arguments as Map)['index'] as int;
        widget.onTabSelected(index);
      }
    });
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _channel?.invokeMethod('setTheme', {'isDark': isDark}).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 240,
      height: 36,
      child: UiKitView(
        viewType: 'trading_app/native-segmented-control',
        creationParams: {
          'selectedIndex': widget.selectedIndex,
          'isDark': isDark,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<PanGestureRecognizer>(
            () => PanGestureRecognizer(),
          ),
          Factory<TapGestureRecognizer>(
            () => TapGestureRecognizer(),
          ),
        },
      ),
    );
  }
}

/// Android / Cross-Platform Liquid Glass Drag-Physics Segmented Movers Control
/// Derived directly from the architecture of LiquidGlassBottomBar:
/// - Real-time 1:1 finger drag tracking across tabs with tactile notch haptics
/// - Momentum fling snapping via SpringSimulation
/// - Dual AnimationController.unbounded (_c position and _press deformation)
/// - Authentic multi-layer frosted glass (inverted shadow mask, rim border refraction, BackdropFilter blur)
/// - Deformable liquid jelly lens with specular body highlights and trading color theme
class _AndroidLiquidGlassSegmentedControl extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _AndroidLiquidGlassSegmentedControl({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_AndroidLiquidGlassSegmentedControl> createState() =>
      _AndroidLiquidGlassSegmentedControlState();
}

class _AndroidLiquidGlassSegmentedControlState
    extends State<_AndroidLiquidGlassSegmentedControl>
    with TickerProviderStateMixin {
  static const double _barHeight = 36;
  static const double _barWidth = 240;
  static const double _inset = 3;
  static const double _lensRise = 2;
  static const double _lensDrop = 2;
  static const _barRadius = BorderRadius.all(Radius.circular(_barHeight / 2));

  // Physics springs from LIQUID_GLASS_BOTTOM_BAR_GUIDE.md
  static final _settleSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.68, // Snap bounce
  );
  static final _pressSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 0.5, // Jelly deformation
  );

  late final AnimationController _c; // Fractional position (0..2)
  late final AnimationController _press; // 0 = resting, 1 = held/dragged
  late int _target;
  int _liftedFrom = 0;
  bool _dragging = false;
  bool _pressed = false;
  int _lastHapticIndex = 0;
  double _dragPos = 0;
  double _itemWidth = (_barWidth - _inset * 2) / 3.0;

  static const _tabs = [
    _MoversTabData(
      label: 'Gainers',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF10B981), // Emerald
    ),
    _MoversTabData(
      label: 'Losers',
      icon: Icons.trending_down_rounded,
      color: Color(0xFFEF4444), // Crimson
    ),
    _MoversTabData(
      label: 'Active',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF59E0B), // Flame Amber
    ),
  ];

  @override
  void initState() {
    super.initState();
    _target = widget.selectedIndex.clamp(0, 2);
    _liftedFrom = _target;
    _lastHapticIndex = _target;
    _c = AnimationController.unbounded(
      vsync: this,
      value: _target.toDouble(),
    );
    _press = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void didUpdateWidget(covariant _AndroidLiquidGlassSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIdx = widget.selectedIndex.clamp(0, 2);
    if (!_dragging && newIdx != _target) {
      _animateTo(newIdx);
    }
    if (!_dragging) {
      _liftedFrom = newIdx;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _press.dispose();
    super.dispose();
  }

  void _animateTo(int index, {double velocity = 0}) {
    _target = index;
    _c.animateWith(
      SpringSimulation(_settleSpring, _c.value, index.toDouble(), velocity),
    );
  }

  void _setPressed(bool p) {
    if (_pressed == p) return;
    _pressed = p;
    _press.animateWith(
      SpringSimulation(_pressSpring, _press.value, p ? 1.0 : 0.0, 0),
    );
  }

  double _posFromDx(double dx) =>
      ((dx - _inset) / _itemWidth - 0.5).clamp(0.0, 2.0).toDouble();

  void _onPointerDown(PointerDownEvent e) {
    _liftedFrom = widget.selectedIndex.clamp(0, 2);
    _setPressed(true);
  }

  void _onPointerUp(PointerUpEvent e) {
    if (!_dragging) _setPressed(false);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (!_dragging) _setPressed(false);
  }

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _liftedFrom = widget.selectedIndex.clamp(0, 2);
    _c.stop();
    _dragPos = _posFromDx(d.localPosition.dx);
    _c.value = _dragPos;
    _setPressed(true);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragPos = _posFromDx(d.localPosition.dx);
    _c.value = _dragPos;
    final idx = _dragPos.round().clamp(0, 2);
    if (idx != _lastHapticIndex) {
      _lastHapticIndex = idx;
      AppHaptics.selection();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    final vel = d.velocity.pixelsPerSecond.dx / _itemWidth;
    final target = (_dragPos + vel * 0.08).round().clamp(0, 2).toInt();

    _dragging = false;
    _setPressed(false);
    _animateTo(target, velocity: vel);
    if (target != widget.selectedIndex) {
      widget.onTabSelected(target);
    }
  }

  void _onDragCancel() {
    _dragging = false;
    _setPressed(false);
    _animateTo(_target);
  }

  void _onItemTap(int index) {
    AppHaptics.selection();
    _liftedFrom = index;
    _animateTo(index);
    if (index != widget.selectedIndex) {
      widget.onTabSelected(index);
    }
  }

  Color _computeActiveColor(double pos) {
    final clamped = pos.clamp(0.0, 2.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c0 = isDark ? _tabs[0].color : const Color(0xFF047857);
    final c1 = isDark ? _tabs[1].color : const Color(0xFFB91C1C);
    final c2 = isDark ? _tabs[2].color : const Color(0xFFB45309);

    if (clamped <= 1.0) {
      return Color.lerp(c0, c1, clamped)!;
    } else {
      return Color.lerp(c1, c2, clamped - 1.0)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _barWidth,
      height: _barHeight,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: _onDragCancel,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _itemWidth = (constraints.maxWidth - _inset * 2) / 3.0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: _buildGlass()),
                  _buildLens(),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _inset),
                      child: Row(
                        children: List.generate(3, _buildItem),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGlass() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomPaint(
      painter: _GlassShadowPainter(_barRadius, isDark: isDark),
      foregroundPainter: _GlassBorderPainter(_barRadius, isDark: isDark),
      child: ClipRRect(
        borderRadius: _barRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xD9151B26),
                        const Color(0xCC0F141C),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.88),
                        Colors.white.withValues(alpha: 0.70),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLens() {
    return AnimatedBuilder(
      animation: Listenable.merge([_c, _press]),
      builder: (context, _) {
        final pos = _c.value;
        final pressFactor = _press.value.clamp(0.0, 1.0);
        final baseWidth = _itemWidth;
        final currentWidth = baseWidth * (1.0 + 0.12 * pressFactor);
        final center = _inset + (pos + 0.5) * _itemWidth;
        final left = center - currentWidth / 2;
        final top = _inset - _lensRise * pressFactor;
        final height =
            (_barHeight - _inset * 2) + (_lensRise + _lensDrop) * pressFactor;
        final activeColor = _computeActiveColor(pos);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Positioned(
          left: left,
          top: top,
          width: currentWidth,
          height: height,
          child: CustomPaint(
            painter: _MiniLensPainter(
              height: height,
              activeColor: activeColor,
              pressFactor: pressFactor,
              isDark: isDark,
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(int index) {
    final item = _tabs[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onItemTap(index),
        child: AnimatedBuilder(
          animation: Listenable.merge([_c, _press]),
          builder: (context, _) {
            // Proximity of the sliding lens (0.0 = away, 1.0 = centered)
            final dist = (_c.value - index).abs().clamp(0.0, 1.0);
            final proximity = 1.0 - dist;

            // When dragging: retain the active color on the lifted-from tab
            // until the pill is released and put onto another tab!
            final bool isLiftedFrom = _dragging && (index == _liftedFrom);
            final double active = isLiftedFrom ? 1.0 : proximity;

            // Inactive colors calibrated for environment contrast:
            // Dark Mode: Crisp Slate 400 (#94A3B8)
            // Light Mode: High-contrast Slate 600 (#475569) - NEVER white!
            final inactiveColor = isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF475569);

            // Active colors tailored for perfect visibility and beauty:
            // Dark Mode: Bright luminous trading colors
            // Light Mode: Deep, rich, high-contrast trading colors (Emerald #047857, Crimson #B91C1C, Amber #B45309)
            final activeColor = isDark
                ? item.color
                : (index == 0
                    ? const Color(0xFF047857) // Deep Emerald
                    : index == 1
                        ? const Color(0xFFB91C1C) // Deep Crimson
                        : const Color(0xFFB45309)); // Deep Flame Amber

            // Smooth dynamic transition:
            // Lifted tab keeps its color locked; approaching tab lights up as lens approaches!
            final color = Color.lerp(inactiveColor, activeColor, active)!;

            return Center(
              child: Transform.scale(
                scale: 1.0 + 0.05 * active,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 12.5,
                      color: color,
                    ),
                    const SizedBox(width: 3.5),
                    Flexible(
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight:
                              active > 0.4 ? FontWeight.w800 : FontWeight.w600,
                          color: color,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MoversTabData {
  final String label;
  final IconData icon;
  final Color color;

  const _MoversTabData({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Inverted Mask Shadow Painter for translucent glass capsule
class _GlassShadowPainter extends CustomPainter {
  final BorderRadius radius;
  final bool isDark;

  const _GlassShadowPainter(this.radius, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(Offset.zero & size);
    final outerRect = (Offset.zero & size).inflate(24);
    final clipPath = Path()
      ..addRect(outerRect)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.save();
    canvas.clipPath(clipPath);

    final shadowPaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.35)
          : const Color(0xFF0F172A).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawRRect(rrect.shift(const Offset(0, 3)), shadowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassShadowPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Multi-layer Dual Rim Border Highlight
class _GlassBorderPainter extends CustomPainter {
  final BorderRadius radius;
  final bool isDark;

  const _GlassBorderPainter(this.radius, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(Offset.zero & size);

    // Subtle base stroke
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.70);
    canvas.drawRRect(rrect, basePaint);

    // Beveled rim reflection
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0.0, 0.5, 1.0],
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.04),
                Colors.transparent,
              ]
            : [
                Colors.white.withValues(alpha: 0.90),
                Colors.white.withValues(alpha: 0.20),
                Colors.transparent,
              ],
      ).createShader(Offset.zero & size);

    canvas.drawRRect(rrect, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Deformable Mini Liquid Jelly Lens Painter
class _MiniLensPainter extends CustomPainter {
  final double height;
  final Color activeColor;
  final double pressFactor;
  final bool isDark;

  const _MiniLensPainter({
    required this.height,
    required this.activeColor,
    required this.pressFactor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(height / 2),
    );

    // 1. Soft Lens Shadow via Inverted Mask
    final outerRect = (Offset.zero & size).inflate(16);
    final clipPath = Path()
      ..addRect(outerRect)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    canvas.save();
    canvas.clipPath(clipPath);

    final shadowPaint = Paint()
      ..color = activeColor.withValues(alpha: isDark ? 0.40 : 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 + 3 * pressFactor);

    canvas.drawRRect(rrect.shift(const Offset(0, 1.5)), shadowPaint);
    canvas.restore();

    // 2. Subtle Liquid Glass Tint that adopts the active trading color
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = activeColor.withValues(
          alpha: isDark ? 0.22 : 0.14,
        ),
    );

    // 3. Inner Specular Body Glass Gradient (Reflection & Depth)
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                Colors.white.withValues(alpha: 0.22 + 0.08 * pressFactor),
                Colors.white.withValues(alpha: 0.04 + 0.04 * pressFactor),
              ]
            : [
                Colors.white.withValues(alpha: 0.75 + 0.15 * pressFactor),
                Colors.white.withValues(alpha: 0.20 + 0.10 * pressFactor),
              ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect, shimmerPaint);

    // 4. Multi-stop Specular Rim Highlight (Crisp 3D Glass Edge)
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.95),
          Colors.white.withValues(alpha: 0.20),
          Colors.white.withValues(alpha: 0.70),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(rrect.deflate(0.5), rimPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniLensPainter oldDelegate) =>
      oldDelegate.height != height ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.pressFactor != pressFactor ||
      oldDelegate.isDark != isDark;
}
