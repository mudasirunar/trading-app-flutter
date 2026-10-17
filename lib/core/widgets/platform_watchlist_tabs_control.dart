import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../utils/app_haptics.dart';

/// Platform-adaptive Watchlist Screen tabs control:
/// - iOS: 100% Native UIKit Apple Liquid Glass Segmented Control via `UiKitView`
/// - Android / Fallback: Custom Flutter Liquid Glass Drag-Physics Control (`_AndroidLiquidGlassWatchlistTabsControl`)
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
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      return _IOSNativeWatchlistTabsControl(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
      );
    }

    // Android / Fallback: Liquid Glass Drag-Physics Segmented Control
    return _AndroidLiquidGlassWatchlistTabsControl(
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
    );
  }
}

/// 100% Native Apple UIKit Liquid Glass Control embedded via UiKitView
class _IOSNativeWatchlistTabsControl extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _IOSNativeWatchlistTabsControl({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_IOSNativeWatchlistTabsControl> createState() =>
      _IOSNativeWatchlistTabsControlState();
}

class _IOSNativeWatchlistTabsControlState
    extends State<_IOSNativeWatchlistTabsControl> {
  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant _IOSNativeWatchlistTabsControl oldWidget) {
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
    _channel = MethodChannel('trading_app/native-watchlist-tabs_$id');
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
      height: 36,
      child: UiKitView(
        viewType: 'trading_app/native-watchlist-tabs',
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

/// Tab metadata for Android Liquid Glass Watchlist Tabs
class _WatchlistTabData {
  final String label;
  final IconData icon;
  final Color color;

  const _WatchlistTabData({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Android / Cross-Platform Liquid Glass Drag-Physics Segmented Watchlist Tabs Control
/// Features:
/// - Real-time 1:1 finger drag tracking across tabs with tactile notch haptics
/// - Wall collision & squish compression physics: when forced against the edge,
///   the front stops dead while the back catches up, visually squishing and bulging like real liquid
/// - Full vertical headroom preventing any sibling component from clipping or overlapping
/// - Momentum fling snapping via SpringSimulation
/// - Dual AnimationController.unbounded (_c position and _press deformation)
/// - Multi-layer frosted glass (inverted shadow mask, rim border refraction, BackdropFilter blur)
/// - Deformable liquid jelly lens with specular highlights and rounded pill geometry
/// - Transparent optical glass when dragged/raised, solid color on placed/rest
/// - In Light Mode: black text and icon when raised, white only once placed
class _AndroidLiquidGlassWatchlistTabsControl extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _AndroidLiquidGlassWatchlistTabsControl({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_AndroidLiquidGlassWatchlistTabsControl> createState() =>
      _AndroidLiquidGlassWatchlistTabsControlState();
}

class _AndroidLiquidGlassWatchlistTabsControlState
    extends State<_AndroidLiquidGlassWatchlistTabsControl>
    with TickerProviderStateMixin {
  static const double _barHeight = 36;
  static const double _verticalHeadroom = 10;
  static const double _totalHeight = _barHeight + _verticalHeadroom * 2; // 56.0
  static const double _inset = 3;
  static const double _lensRise = 8.5; // Outward expansion above borders when raised
  static const double _lensDrop = 8.5; // Outward expansion below borders when raised
  static const _barRadius = BorderRadius.all(Radius.circular(_barHeight / 2));

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

  late final AnimationController _c; // Fractional position (0..1)
  late final AnimationController _press; // 0 = resting, 1 = held/dragged
  AnimationController? _squishController; // Wall bounce impulse controller (shrinks once then springs back)
  Animation<double>? _squishAnimation;
  late int _target;
  bool _dragging = false;
  bool _pressed = false;
  bool _hitLeftWall = false;
  bool _hitRightWall = false;
  bool _animatingTap = false;
  double _startPos = 0;
  double _targetPos = 0;
  int _lastHapticIndex = 0;
  double _dragPos = 0;
  double _itemWidth = 140;
  double _maxWidth = 0;
  double _screenWidth = 0;

  static const _tabs = [
    _WatchlistTabData(
      label: 'My Watchlists',
      icon: Icons.star_rounded,
      color: AppColors.primaryBlue,
    ),
    _WatchlistTabData(
      label: 'All Markets',
      icon: Icons.language_rounded, // Globe / web icon matching iOS SF Symbol globe
      color: AppColors.primaryBlue,
    ),
  ];

  void _ensureSquishController() {
    if (_squishController == null) {
      _squishController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      _squishAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutQuad)),
          weight: 35.0,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 65.0,
        ),
      ]).animate(_squishController!);
    }
  }

  @override
  void initState() {
    super.initState();
    _target = widget.selectedIndex.clamp(0, 1);
    _lastHapticIndex = _target;
    _c = AnimationController.unbounded(
      vsync: this,
      value: _target.toDouble(),
    );
    _press = AnimationController.unbounded(vsync: this, value: 0);
    _ensureSquishController();
  }

  @override
  void didUpdateWidget(covariant _AndroidLiquidGlassWatchlistTabsControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureSquishController();
    final newIdx = widget.selectedIndex.clamp(0, 1);
    if (!_dragging && newIdx != _target) {
      final initialVel = (newIdx - _c.value) * 1.5;
      _animateTo(newIdx, velocity: initialVel, isTap: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _press.dispose();
    _squishController?.dispose();
    super.dispose();
  }

  double _effectivePress() {
    double flightRaise = 0.0;
    if (_animatingTap && (_targetPos - _startPos).abs() > 0.01) {
      final flightProgress = ((_c.value - _startPos) / (_targetPos - _startPos)).clamp(0.0, 1.0);
      flightRaise = math.pow(math.sin(flightProgress * math.pi), 0.7).toDouble();
    }
    return math.max(_press.value, flightRaise).clamp(0.0, 1.3).toDouble();
  }

  void _animateTo(int index, {double velocity = 0, bool isTap = false}) {
    _startPos = _c.value;
    _target = index;
    _targetPos = index.toDouble();
    _animatingTap = isTap;
    _c.animateWith(
      SpringSimulation(_settleSpring, _c.value, index.toDouble(), velocity),
    ).then((_) {
      if (mounted) {
        setState(() {
          _animatingTap = false;
        });
      }
    });
  }

  void _setPressed(bool p) {
    if (_pressed == p) return;
    _pressed = p;
    _press.animateWith(
      SpringSimulation(_pressSpring, _press.value, p ? 1.0 : 0.0, _press.velocity),
    );
  }

  void _triggerSquish() {
    _ensureSquishController();
    AppHaptics.light();
    _squishController?.forward(from: 0.0);
  }

  void _checkWallCollision() {
    if (!_dragging || _maxWidth <= 0 || _screenWidth <= 0) return;
    final screenMargin = ((_screenWidth - _maxWidth) / 2.0).clamp(0.0, 48.0);
    final minLeft = -screenMargin;
    final maxRight = _maxWidth + screenMargin;

    final p = _press.value.clamp(0.0, 1.3).toDouble();
    final stretch = (_c.velocity.abs() * 0.05).clamp(0.0, 0.4).toDouble();
    final wNatural = (_itemWidth - 2) * (1.0 + 0.26 * p + stretch);
    final cxNatural = _inset + (_c.value + 0.5) * _itemWidth;

    final nominalLeft = cxNatural - wNatural / 2;
    final nominalRight = cxNatural + wNatural / 2;

    if (nominalLeft <= minLeft) {
      if (!_hitLeftWall) {
        _hitLeftWall = true;
        _triggerSquish();
      }
    } else if (nominalLeft > minLeft + 8.0) {
      _hitLeftWall = false;
    }

    if (nominalRight >= maxRight) {
      if (!_hitRightWall) {
        _hitRightWall = true;
        _triggerSquish();
      }
    } else if (nominalRight < maxRight - 8.0) {
      _hitRightWall = false;
    }
  }

  // Drag coordinate with elastic overscroll allowance to reach screen edge and drive squish
  double _posFromDx(double dx) =>
      ((dx - _inset) / _itemWidth - 0.5).clamp(-0.45, 1.45).toDouble();

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

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _animatingTap = false;
    _c.stop();
    _setPressed(true);
    _dragPos = _posFromDx(d.localPosition.dx);
    _c.value = _dragPos;
    _hitLeftWall = false;
    _hitRightWall = false;
    _lastHapticIndex = _c.value.round().clamp(0, 1);
    AppHaptics.selection();
    _checkWallCollision();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final target = _posFromDx(d.localPosition.dx);
    _dragPos += (target - _dragPos) * 0.90;
    _c.value = _dragPos;
    _checkWallCollision();

    final nearest = _c.value.round().clamp(0, 1);
    if (nearest != _lastHapticIndex && (_c.value - nearest).abs() < 0.25) {
      _lastHapticIndex = nearest;
      AppHaptics.selection();
    }
  }

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;
    _hitLeftWall = false;
    _hitRightWall = false;
    _setPressed(false);

    final velocity = d.primaryVelocity ?? 0;
    final double tabVelocity = -velocity / _itemWidth;

    int snap = _c.value.round().clamp(0, 1);
    if (velocity.abs() > 400) {
      snap = velocity > 0 ? 1 : 0;
    }

    _animateTo(snap, velocity: tabVelocity);

    if (snap != widget.selectedIndex) {
      AppHaptics.selection();
      widget.onTabSelected(snap);
    }
  }

  void _onDragCancel() {
    _dragging = false;
    _hitLeftWall = false;
    _hitRightWall = false;
    _setPressed(false);
    _animateTo(_target);
  }

  void _onItemTap(int index) {
    if (index == _target && (_c.value - index).abs() < 0.05) {
      // Tap on already-active tab: quick tactile jelly squeeze pulse
      AppHaptics.selection();
      _setPressed(true);
      Future.delayed(const Duration(milliseconds: 140), () {
        if (mounted && !_dragging) {
          _setPressed(false);
        }
      });
      return;
    }

    AppHaptics.selection();
    // Launch authentic liquid flight: lifts in elevation, expands in size,
    // turns into optical liquid glass across tabs, and settles with liquid physics
    final initialVel = (index - _c.value) * 1.5;
    _animateTo(index, velocity: initialVel, isTap: true);

    widget.onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.sizeOf(context).width;

    return SizedBox(
      height: _totalHeight,
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
              _maxWidth = constraints.maxWidth;
              _itemWidth = (constraints.maxWidth - _inset * 2) / 2.0;

              return Stack(
                clipBehavior: Clip.none, // Allows fluid expanding lens to breathe without clipping
                children: [
                  Positioned(
                    top: _verticalHeadroom,
                    left: 0,
                    right: 0,
                    height: _barHeight,
                    child: _buildGlass(),
                  ),
                  _buildLens(constraints.maxWidth),
                  Positioned(
                    top: _verticalHeadroom,
                    left: 0,
                    right: 0,
                    height: _barHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _inset),
                      child: Row(
                        children: List.generate(2, _buildItem),
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

  Widget _buildLens(double maxWidth) {
    _ensureSquishController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_c, _press, _squishController!]),
      builder: (context, _) {
        final p = _effectivePress();
        final stretch = (_c.velocity.abs() * 0.05).clamp(0.0, 0.4).toDouble();

        // 1. Natural dimensions before wall boundary contact
        final hNatural = ((_barHeight - _inset * 2) + (_lensRise + _lensDrop) * p) *
            (1.0 - stretch * 0.12);
        final wNatural = (_itemWidth - 2) * (1.0 + 0.26 * p + stretch);
        final cxNatural = _inset + (_c.value + 0.5) * _itemWidth;

        // 2. Wall bounds collision at the END OF THE SCREEN (not just tabs area)
        final screenWidth = MediaQuery.sizeOf(context).width;
        final screenMargin = ((screenWidth - maxWidth) / 2.0).clamp(0.0, 48.0);
        final minLeft = -screenMargin;
        final maxRight = maxWidth + screenMargin;

        final nominalLeft = cxNatural - wNatural / 2;
        final nominalRight = cxNatural + wNatural / 2;

        // 3. Wall hit squish animation: fires once on contact, decreases vertically and increases horizontally
        final squishImpulse = (_squishAnimation?.value ?? 0.0).clamp(0.0, 1.0).toDouble();
        final squishRatio = 0.15 * squishImpulse; // Squish intensity: 15% deformation

        // Liquid volume conservation: decrease vertically and increase horizontally
        final w = wNatural * (1.0 + squishRatio);
        final h = hNatural * (1.0 - squishRatio);

        // 4. Pill position remains finger-dependent; stops at screen wall
        double cx = cxNatural;
        if (nominalLeft < minLeft) {
          // Stopped at left screen wall
          cx = minLeft + w / 2;
        } else if (nominalRight > maxRight) {
          // Stopped at right screen wall
          cx = maxRight - w / 2;
        }

        final cy = _verticalHeadroom + _barHeight / 2 - (_lensRise - _lensDrop) / 2 * p;

        final targetTab = _c.value.round().clamp(0, 1);
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
              final press = _effectivePress();
              final active = t > 0.5;

              Color color;
              if (isDark) {
                // Dark Mode: Active is white, inactive is Slate 400
                final inactiveColor = const Color(0xFF94A3B8);
                color = Color.lerp(inactiveColor, Colors.white, t)!;
              } else {
                // Light Mode:
                // When pill is raised (dragged or flying): ALL tabs turn black.
                // No dynamic color changing based on hover!
                // Only when placed at rest on a tab does that tab change to white while others remain black.
                const blackColor = Color(0xFF0F172A);
                final isRaised = _dragging || press > 0.12;

                if (isRaised) {
                  color = blackColor;
                } else {
                  final isPlacedHere = (index == _target) && (_c.value - index).abs() < 0.35;
                  color = isPlacedHere ? Colors.white : blackColor;
                }
              }

              return Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Transform.scale(
                    scale: 1.0 + 0.06 * t + 0.04 * t * press,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 15,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                              color: color,
                              letterSpacing: -0.2,
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
      ),
    );
  }
}

/// Inverted Mask Shadow Painter matching PlatformSegmentedMoversControl
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

/// Multi-layer Dual Rim Border Highlight matching PlatformSegmentedMoversControl
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

/// Liquid Glass Lens Painter derived directly from PlatformSegmentedMoversControl:
/// - Fully rounded pill capsule geometry (Radius.circular(size.shortestSide / 2))
/// - Pure solid active color when resting on selected tab
/// - 100% transparent liquid glass when lifted and dragged
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

    // 2. Color fill: Pure solid color when on tab, 100% transparent when sliding/raised!
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
