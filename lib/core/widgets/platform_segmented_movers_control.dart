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
  static const double _lensRise = 8.5; // Outward expansion above borders when raised
  static const double _lensDrop = 8.5; // Outward expansion below borders when raised
  static const _barRadius = BorderRadius.all(Radius.circular(_barHeight / 2));

  // Physics springs directly from LiquidGlassBottomBar
  static final _settleSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.68, // Snap bounce
  );
  static final _pressSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 0.5, // Jelly deformation overshoot
  );

  late final AnimationController _c; // Fractional position (0..2)
  late final AnimationController _press; // 0 = resting, 1 = held/dragged
  late int _target;
  bool _dragging = false;
  bool _pressed = false;
  int _lastHapticIndex = 0;
  double _dragPos = 0;
  double _itemWidth = (_barWidth - _inset * 2) / 3.0;

  static const _tabs = [
    _MoversTabData(
      label: 'Gainers',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF059669), // Rich Emerald (#059669)
    ),
    _MoversTabData(
      label: 'Losers',
      icon: Icons.trending_down_rounded,
      color: Color(0xFFDC2626), // Rich Crimson (#DC2626)
    ),
    _MoversTabData(
      label: 'Active',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFD97706), // Rich Flame Amber (#D97706)
    ),
  ];

  @override
  void initState() {
    super.initState();
    _target = widget.selectedIndex.clamp(0, 2);
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
      SpringSimulation(_pressSpring, _press.value, p ? 1.0 : 0.0, _press.velocity),
    );
  }

  // Unrestricted drag coordinate with natural rubberband outward allowance beyond ends
  double _posFromDx(double dx) =>
      ((dx - _inset) / _itemWidth - 0.5).clamp(-0.20, 2.20).toDouble();

  // Pointer down: If tapping near the current lens, expand immediately
  void _onPointerDown(PointerDownEvent e) {
    if ((_posFromDx(e.localPosition.dx) - _c.value).abs() < 0.7) {
      _setPressed(true);
    }
  }

  void _onPointerUp(PointerEvent e) {
    if (!_dragging) _setPressed(false);
  }

  void _onPointerCancel(PointerEvent e) {
    if (!_dragging) _setPressed(false);
  }

  // Drag start: stop spring simulation and take direct 1:1 manual control
  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _c.stop();
    _dragPos = _posFromDx(d.localPosition.dx);
    _lastHapticIndex = _c.value.round().clamp(0, 2);
    _setPressed(true);
    _c.value = _dragPos;
  }

  // Drag update: 1:1 finger tracking with tactile haptic notch on tab change
  void _onDragUpdate(DragUpdateDetails d) {
    _dragPos = _posFromDx(d.localPosition.dx);
    _c.value = _dragPos;
    final nearest = _dragPos.round().clamp(0, 2);
    if (nearest != _lastHapticIndex) {
      _lastHapticIndex = nearest;
      AppHaptics.selection();
    }
  }

  // Drag end: velocity momentum projection and spring snap
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
    if (index != widget.selectedIndex) {
      _animateTo(index);
      widget.onTabSelected(index);
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
                clipBehavior: Clip.none, // Allows fluid expanding lens to overflow
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_c, _press]),
      builder: (context, _) {
        final p = _press.value.clamp(0.0, 1.3).toDouble();
        final stretch = (_c.velocity.abs() * 0.05).clamp(0.0, 0.4).toDouble();

        // Liquid jelly stretch & vertical expansion overflowing outside the borders
        final w = (_itemWidth - 2) * (1.0 + 0.26 * p + stretch);
        final h = ((_barHeight - _inset * 2) + (_lensRise + _lensDrop) * p) *
            (1.0 - stretch * 0.12);

        final cx = _inset + (_c.value + 0.5) * _itemWidth;
        final cy = _barHeight / 2 - (_lensRise - _lensDrop) / 2 * p;

        // Solid tab color on selected; exact same 3 colors for both modes
        final targetTab = _c.value.round().clamp(0, 2);
        final activeColor = _tabs[targetTab].color;

        return Positioned(
          left: cx - w / 2,
          top: cy - h / 2,
          width: w,
          height: h,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LensPainter(
                press: p,
                activeColor: activeColor,
                isDark: isDark,
              ),
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
        child: SizedBox(
          height: _barHeight,
          child: AnimatedBuilder(
            animation: Listenable.merge([_c, _press]),
            builder: (context, _) {
              final t = (1.0 - (_c.value - index).abs()).clamp(0.0, 1.0).toDouble();
              final press = _press.value.clamp(0.0, 1.3).toDouble();
              final active = t > 0.5;

              Color color;
              if (isDark) {
                // Dark Mode: Keep as is (Active is white, inactive is Slate 400)
                final inactiveColor = const Color(0xFF94A3B8);
                color = Color.lerp(inactiveColor, Colors.white, t)!;
              } else {
                // Light Mode:
                // When pill is raised (dragged or pressed): ALL tabs turn black.
                // No dynamic color changing based on hover!
                // Only when placed at rest on a tab does that tab change to white while others remain black.
                const blackColor = Color(0xFF0F172A);
                final isRaised = _dragging || _press.value > 0.12;

                if (isRaised) {
                  color = blackColor;
                } else {
                  final isPlacedHere = (index == _target) && (_c.value - index).abs() < 0.35;
                  color = isPlacedHere ? Colors.white : blackColor;
                }
              }

              return Center(
                child: Transform.scale(
                  scale: 1.0 + 0.06 * t + 0.04 * t * press,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 13,
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
                                active ? FontWeight.w800 : FontWeight.w600,
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

/// Liquid Glass Lens Painter derived directly from LiquidGlassBottomBar:
/// - Solid tab color when resting on selected tab (matching iOS native UI)
/// - Transparent liquid glass when lifted and dragged
/// - Inverted mask shadow for crystal-clear refraction without muddy dark spots
/// - Specular highlight rim stroke
class _LensPainter extends CustomPainter {
  final double press;
  final Color activeColor;
  final bool isDark;

  const _LensPainter({
    required this.press,
    required this.activeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final q = press.clamp(0.0, 1.0).toDouble();
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(size.shortestSide / 2),
    );

    // 1. Inverted Mask Shadow (Outside only, avoiding dark shadows under transparent glass)
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(40)),
      Path()..addRRect(rrect),
    );
    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
      rrect.shift(Offset(0, 2 + 4 * q)),
      Paint()
        ..color = (isDark ? Colors.black : const Color(0xFF0F172A))
            .withValues(alpha: isDark ? (0.22 + 0.18 * q) : (0.08 + 0.12 * q))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 + 6 * q),
    );
    canvas.restore();

    // 2. Color fill: Pure solid color when on tab, 100% transparent (no color) when sliding/raised!
    final fillOpacity = lerpDouble(1.0, 0.0, (q * 2.0).clamp(0.0, 1.0))!;
    if (fillOpacity > 0.005) {
      canvas.drawRRect(
        rrect,
        Paint()..color = activeColor.withValues(alpha: fillOpacity),
      );
    }

    // 3. Inner Specular Body Glass Gradient (Clear optical glass when sliding, subtle sheen at rest)
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: lerpDouble(0.04, 0.22, q)!),
                  Colors.white.withValues(alpha: lerpDouble(0.0, 0.04, q)!),
                ]
              : [
                  Colors.white.withValues(alpha: lerpDouble(0.04, 0.25, q)!),
                  Colors.white.withValues(alpha: lerpDouble(0.0, 0.04, q)!),
                ],
        ).createShader(rect),
    );

    // 4. Multi-layer Specular Rim Highlight (Liquid glass edge)
    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: lerpDouble(0.60, 0.95, q)!),
            Colors.white.withValues(alpha: lerpDouble(0.10, 0.20, q)!),
            Colors.white.withValues(alpha: lerpDouble(0.30, 0.80, q)!),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _LensPainter old) =>
      old.press != press ||
      old.activeColor != activeColor ||
      old.isDark != isDark;
}
