import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../common/item_controller.dart';
import '../common/widgets/demo_overlay.dart';
import '../common/widgets/leo_beside.dart';
import 'stroke_tracer.dart';
import 'trace_activity.dart';
import 'trace_painter.dart';
import 'trace_path.dart';

class TraceView extends StatefulWidget {
  const TraceView({super.key, required this.item, required this.controller});

  static const canvasKey = ValueKey('trace-canvas');
  static const toleranceShare = 1.3;
  static const glowPeriod = Duration(milliseconds: 900);

  final TraceItem item;
  final ItemController controller;

  @override
  State<TraceView> createState() => _TraceViewState();
}

class _TraceViewState extends State<TraceView> with SingleTickerProviderStateMixin {
  late final _glow = AnimationController(vsync: this, duration: TraceView.glowPeriod);
  TracePath? _path;
  StrokeTracer? _tracer;
  Size? _size;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _glow.value = 0;
      _glow.stop();
    } else if (!_glow.isAnimating) {
      _glow.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TraceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) _size = null;
  }

  void _fit(Size size) {
    if (size == _size) return;
    final path = TracePath.fit(widget.item.strokes, width: size.width, height: size.height);
    _size = size;
    _path = path;
    _tracer = StrokeTracer(
      strokes: path.strokes,
      tolerance: path.strokeWidth * TraceView.toleranceShare,
    );
  }

  void _update(void Function(StrokeTracer tracer) action) {
    final tracer = _tracer;
    if (tracer == null || widget.controller.isSolved) return;
    setState(() => action(tracer));
    if (tracer.isComplete) widget.controller.answer(widget.item.target);
  }

  List<Offset> _demoPath() {
    final tracer = _tracer!;
    if (tracer.isComplete) return const [];
    return [for (final point in _path!.strokes[tracer.currentStroke]) Offset(point.x, point.y)];
  }

  Point<double> _point(Offset offset) => Point(offset.dx, offset.dy);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LeoBeside(
      controller: widget.controller,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _fit(constraints.biggest);
            return DemoOverlay(
              key: ValueKey('demo-${widget.item.id}'),
              show: widget.controller.showsDemo,
              path: _demoPath(),
              child: GestureDetector(
                key: TraceView.canvasKey,
                behavior: HitTestBehavior.opaque,
                onPanDown: (details) => _update((t) => t.start(_point(details.localPosition))),
                onPanUpdate: (details) => _update((t) => t.move(_point(details.localPosition))),
                onPanEnd: (_) => _update((t) => t.end()),
                onPanCancel: () => _update((t) => t.end()),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: TracePainter(
                    path: _path!,
                    tracer: _tracer!,
                    glow: _glow,
                    guide: colors.surfaceContainerHighest,
                    ink: colors.primary,
                    marker: colors.tertiary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
