import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../core/content/models/letter_shape.dart';
import 'stroke_tracer.dart';
import 'trace_path.dart';

class TracePainter extends CustomPainter {
  TracePainter({
    required this.path,
    required this.tracer,
    required this.glow,
    required this.guide,
    required this.ink,
    required this.marker,
  }) : super(repaint: glow);

  static const inkShare = 0.7;
  static const markerShare = 0.75;
  static const haloShare = 1.6;
  static const arrowShare = 0.6;
  static const arrowLookAhead = 3.0;

  final TracePath path;
  final StrokeTracer tracer;
  final Animation<double> glow;
  final Color guide;
  final Color ink;
  final Color marker;

  double get _width => path.strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in path.strokes) {
      _line(canvas, stroke, guide, _width);
    }
    for (final (index, stroke) in path.strokes.indexed) {
      final reached = tracer.reachedIn(index);
      final isDone = index < tracer.currentStroke;
      if (reached > 0 || isDone) {
        _line(canvas, stroke.sublist(0, reached + 1), ink, _width * inkShare);
      }
    }
    if (!tracer.isComplete) _marker(canvas);
  }

  void _line(Canvas canvas, Stroke points, Color color, double width) {
    if (points.length == 1) {
      canvas.drawCircle(_offset(points.first), width / 2, Paint()..color = color);
      return;
    }
    final line = Path()..moveTo(points.first.x, points.first.y);
    for (final point in points.skip(1)) {
      line.lineTo(point.x, point.y);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  void _marker(Canvas canvas) {
    final stroke = path.strokes[tracer.currentStroke];
    final tip = tracer.tip!;
    final radius = _width * markerShare;
    final lookAhead = (arrowLookAhead * _width / path.spacing).round();
    final ahead = stroke[min(tracer.reached + lookAhead, stroke.length - 1)];
    if (ahead != tip) _arrow(canvas, tip, ahead);
    final halo = radius * (1 + (haloShare - 1) * glow.value);
    canvas.drawCircle(
      _offset(tip),
      halo,
      Paint()..color = marker.withValues(alpha: 0.35 * (1 - glow.value) + 0.15),
    );
    canvas.drawCircle(_offset(tip), radius, Paint()..color = marker);
  }

  void _arrow(Canvas canvas, Point<double> from, Point<double> to) {
    final direction = to - from;
    final unit = direction * (1 / direction.magnitude);
    final normal = Point(-unit.y, unit.x);
    final head = _width * arrowShare;
    final base = to - unit * head;
    final left = base + normal * head;
    final right = base - normal * head;
    final arrow = Path()
      ..moveTo(to.x, to.y)
      ..lineTo(left.x, left.y)
      ..lineTo(right.x, right.y)
      ..close();
    canvas.drawPath(arrow, Paint()..color = marker);
  }

  Offset _offset(Point<double> point) => Offset(point.x, point.y);

  @override
  bool shouldRepaint(TracePainter oldDelegate) => true;
}
