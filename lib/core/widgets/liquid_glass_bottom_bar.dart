import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

/// Item definition for the bottom bar
class LiquidNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool hasBadge;

  const LiquidNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.hasBadge = false,
  });
}

/// Standalone Liquid Glass Drag-Physics Bottom Navigation Bar (Android)
class LiquidGlassBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidNavItem> items;
  final int badgeCount;
  final Color primaryColor;

  const LiquidGlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.badgeCount = 0,
    this.primaryColor = const Color(0xFF2F68F6),
  });

  @override
  State<LiquidGlassBottomBar> createState() => _LiquidGlassBottomBarState();
}

class _LiquidGlassBottomBarState extends State<LiquidGlassBottomBar>
    with TickerProviderStateMixin {
  static const double _barHeight = 66;
  static const double _inset = 6;
  static const double _lensRise = 10;
  static const double _lensDrop = 10;
  static const _barRadius = BorderRadius.all(Radius.circular(_barHeight / 2));

  // Physics springs
  static final _settleSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.68, // Lower ratio = more bounce on snap
  );
  static final _pressSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 300,
    ratio: 0.5, // Jelly expansion overshoot
  );

  late final AnimationController _c; // Lens position in fractional tab units (0..N-1)
  late final AnimationController _press; // 0 = resting, 1 = held/dragged
  late int _target;
  bool _dragging = false;
  bool _pressed = false;
  int _lastHapticIndex = 0;
  double _dragPos = 0;
  double _itemWidth = 1;

  @override
  void initState() {
    super.initState();
    _target = widget.currentIndex;
    _c = AnimationController.unbounded(
      vsync: this,
      value: widget.currentIndex.toDouble(),
    );
    _press = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void didUpdateWidget(covariant LiquidGlassBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && widget.currentIndex != _target) {
      _animateTo(widget.currentIndex);
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

  void _setPressed(bool v) {
    if (_pressed == v) return;
    _pressed = v;
    _press.animateWith(
      SpringSimulation(_pressSpring, _press.value, v ? 1.0 : 0.0, _press.velocity),
    );
  }

  double _posFromDx(double dx) => ((dx - _inset) / _itemWidth - 0.5)
      .clamp(0.0, widget.items.length - 1.0)
      .toDouble();

  void _onItemTap(int index) {
    HapticFeedback.selectionClick();
    if (index != widget.currentIndex) {
      _animateTo(index);
    }
    widget.onTap(index);
  }

  // Pointer down: If tapping near the current lens, it expands immediately
  void _onPointerDown(PointerDownEvent e) {
    if ((_posFromDx(e.localPosition.dx) - _c.value).abs() < 0.6) {
      _setPressed(true);
    }
  }

  void _onPointerUp(PointerEvent e) {
    if (!_dragging) _setPressed(false);
  }

  // Drag start: stop spring simulation and take manual control
  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _c.stop();
    _dragPos = _posFromDx(d.localPosition.dx);
    _lastHapticIndex = _c.value.round();
    _setPressed(true);
    _c.value = _dragPos;
  }

  // Drag update: 1:1 tracking with finger, haptic click on tab crossing
  void _onDragUpdate(DragUpdateDetails d) {
    _dragPos = _posFromDx(d.localPosition.dx);
    _c.value = _dragPos;
    final nearest = _dragPos.round();
    if (nearest != _lastHapticIndex) {
      _lastHapticIndex = nearest;
      HapticFeedback.selectionClick();
    }
  }

  // Drag end: calculate fling momentum and snap with spring physics
  void _onDragEnd(DragEndDetails d) {
    final vel = d.velocity.pixelsPerSecond.dx / _itemWidth;
    final target = (_dragPos + vel * 0.08)
        .round()
        .clamp(0, widget.items.length - 1)
        .toInt();
    _dragging = false;
    _setPressed(false);
    _animateTo(target, velocity: vel);
    if (target != widget.currentIndex) widget.onTap(target);
  }

  void _onDragCancel() {
    _dragging = false;
    _setPressed(false);
    _animateTo(widget.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final margin = EdgeInsets.fromLTRB(
      20,
      0,
      20,
      bottomInset > 0 ? bottomInset + 4 : 12,
    );

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: margin,
        child: SizedBox(
          height: _barHeight,
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerUp,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onHorizontalDragCancel: _onDragCancel,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _itemWidth = (constraints.maxWidth - _inset * 2) / widget.items.length;
                  return Stack(
                    clipBehavior: Clip.none, // Allows the expanding lens to overflow the bar
                    children: [
                      Positioned.fill(child: _buildGlass()),
                      _buildLens(),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: _inset),
                          child: Row(
                            children: List.generate(widget.items.length, _buildItem),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
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
                        Colors.white.withValues(alpha: 0.85),
                        Colors.white.withValues(alpha: 0.65),
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

        final w = (_itemWidth - 4) * (1 + 0.24 * p + stretch);
        final h = ((_barHeight - _inset * 2) + (_lensRise + _lensDrop) * p) *
            (1 - stretch * 0.15);

        final cx = _inset + (_c.value + 0.5) * _itemWidth;
        final cy = _barHeight / 2 - (_lensRise - _lensDrop) / 2 * p;

        return Positioned(
          left: cx - w / 2,
          top: cy - h / 2,
          width: w,
          height: h,
          child: IgnorePointer(
            child: CustomPaint(
              painter: _LensPainter(p, widget.primaryColor, isDark: isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem(int index) {
    final item = widget.items[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Semantics(
        button: true,
        selected: index == widget.currentIndex,
        label: item.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _onItemTap(index),
          child: SizedBox(
            height: _barHeight,
            child: AnimatedBuilder(
              animation: Listenable.merge([_c, _press]),
              builder: (context, _) {
                final t = (1 - (_c.value - index).abs()).clamp(0.0, 1.0).toDouble();
                final press = _press.value.clamp(0.0, 1.3).toDouble();
                final active = t > 0.5;
                final color = Color.lerp(
                  isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  widget.primaryColor,
                  t,
                )!;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Transform.scale(
                          scale: 1 + 0.08 * t + 0.10 * t * press,
                          child: Icon(
                            active ? item.activeIcon : item.icon,
                            size: 24,
                            color: color,
                          ),
                        ),
                        if (item.hasBadge && widget.badgeCount > 0)
                          Positioned(
                            top: -5,
                            right: -10,
                            child: _Badge(count: widget.badgeCount),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: color,
                        letterSpacing: -0.1,
                        height: 1.1,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Painters & Badges
// -----------------------------------------------------------------------------

class _LensPainter extends CustomPainter {
  final double press;
  final Color primaryColor;
  final bool isDark;

  const _LensPainter(this.press, this.primaryColor, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final q = press.clamp(0.0, 1.0).toDouble();
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.shortestSide / 2));

    // Outer shadow only (avoids dark shadow showing through transparent glass)
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(60)),
      Path()..addRRect(rrect),
    );
    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
      rrect.shift(Offset(0, 3 + 5 * q)),
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? (0.15 + 0.15 * q) : (0.06 + 0.08 * q))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 7 + 7 * q),
    );
    canvas.restore();

    // Primary brand tint at rest
    canvas.drawRRect(
      rrect,
      Paint()..color = primaryColor.withValues(alpha: isDark ? (0.15 * (1 - q)) : (0.08 * (1 - q))),
    );

    // Inner Body Gradient
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: lerpDouble(0.14, 0.22, q)!),
                  Colors.white.withValues(alpha: lerpDouble(0.04, 0.08, q)!),
                ]
              : [
                  Colors.black.withValues(alpha: lerpDouble(0.10, 0.22, q)!),
                  Colors.black.withValues(alpha: lerpDouble(0.04, 0.04, q)!),
                ],
        ).createShader(rect),
    );

    // Rim highlight stroke
    canvas.drawRRect(
      rrect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: lerpDouble(0.7, 1.0, q)!),
            Colors.white.withValues(alpha: lerpDouble(0.1, 0.15, q)!),
            Colors.white.withValues(alpha: lerpDouble(0.4, 0.90, q)!),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _LensPainter old) =>
      old.press != press || old.primaryColor != primaryColor || old.isDark != isDark;
}

class _GlassShadowPainter extends CustomPainter {
  final BorderRadius radius;
  final bool isDark;

  const _GlassShadowPainter(this.radius, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = radius.toRRect(Offset.zero & size);
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(-80, -80, size.width + 160, size.height + 160)),
      Path()..addRRect(rrect),
    );
    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
      rrect.shift(const Offset(0, 8)),
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassShadowPainter old) =>
      old.radius != radius || old.isDark != isDark;
}

class _GlassBorderPainter extends CustomPainter {
  final BorderRadius radius;
  final bool isDark;

  const _GlassBorderPainter(this.radius, {required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect);

    canvas.drawRRect(
      rrect.deflate(0.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.07),
    );

    canvas.drawRRect(
      rrect.deflate(1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.white.withValues(alpha: 0.35),
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.20),
                ]
              : [
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.20),
                  Colors.white.withValues(alpha: 0.70),
                ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassBorderPainter old) =>
      old.radius != radius || old.isDark != isDark;
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
