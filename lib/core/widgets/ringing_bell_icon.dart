import 'package:flutter/material.dart';

/// Interactive bell icon featuring a realistic ringing/waving pendulum oscillation.
/// Pivots from [Alignment.topCenter] with natural harmonic damping and scale pulsing.
class RingingBellIcon extends StatefulWidget {
  final double size;
  final Color color;
  final bool isRinging;
  final bool repeat;
  final Duration interval;

  const RingingBellIcon({
    super.key,
    this.size = 22.0,
    required this.color,
    this.isRinging = true,
    this.repeat = true,
    this.interval = const Duration(milliseconds: 2200),
  });

  @override
  State<RingingBellIcon> createState() => _RingingBellIconState();
}

class _RingingBellIconState extends State<RingingBellIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.interval,
    );

    // Natural pendulum harmonic ring sequence (swinging from top pivot)
    _rotationAnim = TweenSequence<double>([
      // First aggressive wave left
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.32)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 6.0,
      ),
      // Swing right
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.32, end: 0.28)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 8.0,
      ),
      // Swing left
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.28, end: -0.22)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 7.0,
      ),
      // Swing right
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.22, end: 0.16)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6.0,
      ),
      // Swing left damping
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.16, end: -0.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5.0,
      ),
      // Return to rest
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.08, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 5.0,
      ),
      // Rest pause before next ring
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 63.0,
      ),
    ]).animate(_controller);

    // Subtle scale vibration during the ringing phase
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.14)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.14, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 27.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 63.0,
      ),
    ]).animate(_controller);

    if (widget.isRinging) {
      if (widget.repeat) {
        _controller.repeat();
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void didUpdateWidget(covariant RingingBellIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRinging != oldWidget.isRinging) {
      if (widget.isRinging) {
        if (widget.repeat) {
          _controller.repeat();
        } else {
          _controller.forward(from: 0.0);
        }
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.rotate(
            angle: _rotationAnim.value,
            alignment: Alignment.topCenter, // Pivots from the top suspension point
            child: Icon(
              Icons.notifications_active_rounded,
              size: widget.size,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}
