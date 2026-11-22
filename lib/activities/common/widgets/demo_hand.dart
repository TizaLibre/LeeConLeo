import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DemoHand extends StatefulWidget {
  const DemoHand({
    super.key,
    required this.path,
    required this.size,
    this.carrying,
    this.carryingSize = 0,
    this.loops = 3,
  });

  static const asset = 'assets/images/ui/hand.svg';
  static const aspectRatio = 200 / 240;
  static const fingertip = Offset(0.36, 0.05);
  static const tapPeriod = Duration(milliseconds: 1800);
  static const dragPause = Duration(milliseconds: 1400);
  static const dragSpeed = 260.0;
  static const pressedScale = 0.85;

  final List<Offset> path;
  final double size;
  final Widget? carrying;
  final double carryingSize;
  final int loops;

  @override
  State<DemoHand> createState() => _DemoHandState();
}

class _DemoHandState extends State<DemoHand> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: _period());

  bool get _isTap => widget.path.length < 2;

  double get _length {
    var length = 0.0;
    for (var i = 1; i < widget.path.length; i++) {
      length += (widget.path[i] - widget.path[i - 1]).distance;
    }
    return length;
  }

  Duration _period() => _isTap
      ? DemoHand.tapPeriod
      : DemoHand.dragPause + Duration(milliseconds: (_length / DemoHand.dragSpeed * 1000).round());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = _Timeline.pressed;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.repeat(count: widget.loops);
    }
  }

  @override
  void didUpdateWidget(DemoHand oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = _period();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _pointAt(double progress) {
    final path = widget.path;
    if (_isTap) return path.first;
    var remaining = progress * _length;
    for (var i = 1; i < path.length; i++) {
      final segment = (path[i] - path[i - 1]).distance;
      if (remaining <= segment) {
        return Offset.lerp(path[i - 1], path[i], segment == 0 ? 0 : remaining / segment)!;
      }
      remaining -= segment;
    }
    return path.last;
  }

  @override
  Widget build(BuildContext context) {
    final ripple = Theme.of(context).colorScheme.tertiary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final timeline = _Timeline(_controller.value);
        final tip = _pointAt(timeline.travel) + timeline.approach * widget.size * 0.4;
        final height = widget.size;
        final width = height * DemoHand.aspectRatio;
        final rippleSize = height * 0.7 * timeline.ripple;
        final carrying = widget.carrying;
        final carried = widget.carryingSize;
        return Opacity(
          opacity: timeline.opacity,
          child: Stack(
            children: [
              if (carrying != null && timeline.press > 0)
                Positioned(
                  left: tip.dx - carried / 2,
                  top: tip.dy - carried / 2,
                  width: carried,
                  height: carried,
                  child: Opacity(opacity: 0.8 * timeline.press, child: carrying),
                ),
              if (timeline.ripple > 0)
                Positioned(
                  left: tip.dx - rippleSize / 2,
                  top: tip.dy - rippleSize / 2,
                  width: rippleSize,
                  height: rippleSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ripple.withValues(alpha: 0.3 * (1 - timeline.ripple / 2)),
                    ),
                  ),
                ),
              Positioned(
                left: tip.dx - width * DemoHand.fingertip.dx,
                top: tip.dy - height * DemoHand.fingertip.dy,
                width: width,
                height: height,
                child: Transform.scale(
                  scale: lerpDouble(1, DemoHand.pressedScale, timeline.press),
                  alignment: const Alignment(0, -0.9),
                  child: SvgPicture.asset(DemoHand.asset),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Timeline {
  _Timeline(this.t);

  static const appearEnd = 0.15;
  static const pressed = 0.25;
  static const moveEnd = 0.75;
  static const releaseEnd = 0.85;

  final double t;

  double _between(double start, double end) => ((t - start) / (end - start)).clamp(0.0, 1.0);

  double get opacity {
    if (t < appearEnd) return _between(0, appearEnd);
    if (t > releaseEnd) return 1 - _between(releaseEnd, 1);
    return 1;
  }

  Offset get approach =>
      const Offset(1, 1) * (1 - Curves.easeOut.transform(_between(0, appearEnd)));

  double get press =>
      t < moveEnd ? _between(appearEnd, pressed) : 1 - _between(moveEnd, releaseEnd);

  double get travel => Curves.easeInOut.transform(_between(pressed, moveEnd));

  double get ripple => t < appearEnd || t > releaseEnd ? 0 : press;
}
