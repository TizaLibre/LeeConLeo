import 'package:material_ui/material_ui.dart';

import 'demo_hand.dart';

class DemoOverlay extends StatefulWidget {
  const DemoOverlay({
    super.key,
    required this.show,
    required this.path,
    required this.child,
    this.carrying,
    this.carryingSize = 0,
  });

  static const handKey = ValueKey('demo-hand');
  static const handShare = 0.16;
  static const minHand = 88.0;
  static const maxHand = 150.0;

  final bool show;
  final List<Offset> path;
  final Widget child;
  final Widget? carrying;
  final double carryingSize;

  @override
  State<DemoOverlay> createState() => _DemoOverlayState();
}

class _DemoOverlayState extends State<DemoOverlay> {
  bool _isDismissed = false;

  @override
  void didUpdateWidget(DemoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) _isDismissed = false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            if (!_isDismissed) setState(() => _isDismissed = true);
          },
          child: widget.child,
        ),
        if (widget.show && !_isDismissed && widget.path.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) => DemoHand(
                  key: DemoOverlay.handKey,
                  path: widget.path,
                  size: (constraints.biggest.shortestSide * DemoOverlay.handShare).clamp(
                    DemoOverlay.minHand,
                    DemoOverlay.maxHand,
                  ),
                  carrying: widget.carrying,
                  carryingSize: widget.carryingSize,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
