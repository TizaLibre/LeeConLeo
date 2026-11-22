import 'package:material_ui/material_ui.dart';

class RoutePainter extends CustomPainter {
  const RoutePainter({required this.points, required this.edge, required this.road});

  static const roadWidth = 26.0;
  static const edgeWidth = 8.0;
  static const halfWidth = roadWidth / 2 + edgeWidth;

  static Path through(List<Offset> points) {
    final route = Path();
    if (points.isEmpty) return route;
    route.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final from = points[i - 1];
      final to = points[i];
      final middle = (from.dy + to.dy) / 2;
      route.cubicTo(from.dx, middle, to.dx, middle, to.dx, to.dy);
    }
    return route;
  }

  final List<Offset> points;
  final Color edge;
  final Color road;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final route = through(points);
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(route, stroke(edge, roadWidth + 2 * edgeWidth))
      ..drawPath(route, stroke(road, roadWidth));
  }

  @override
  bool shouldRepaint(RoutePainter oldDelegate) => oldDelegate.points != points;
}
