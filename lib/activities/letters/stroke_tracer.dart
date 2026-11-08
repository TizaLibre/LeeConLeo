import 'dart:math';

import '../../core/content/models/letter_shape.dart';

class StrokeTracer {
  StrokeTracer({required this.strokes, required this.tolerance});

  static const reachShare = 0.75;

  final List<Stroke> strokes;
  final double tolerance;

  int _stroke = 0;
  int _reached = 0;
  bool _isTracing = false;
  Point<double>? _finger;

  int get currentStroke => _stroke;

  int get reached => _reached;

  bool get isComplete => _stroke >= strokes.length;

  Point<double>? get tip => isComplete ? null : strokes[_stroke][_reached];

  double get _reach => tolerance * reachShare;

  int reachedIn(int stroke) {
    if (stroke < _stroke) return strokes[stroke].length - 1;
    if (stroke == _stroke) return _reached;
    return -1;
  }

  void start(Point<double> finger) {
    final tip = this.tip;
    if (tip == null) return;
    _isTracing = finger.distanceTo(tip) <= tolerance;
    _finger = finger;
    if (_isTracing) _finishStrokeIfDone();
  }

  void move(Point<double> finger) {
    final from = _finger;
    _finger = finger;
    if (!_isTracing || isComplete || from == null) return;
    final start = _reached;
    final samples = max(1, (from.distanceTo(finger) / (_reach / 2)).ceil());
    for (var i = 1; i <= samples; i++) {
      _advance(from + (finger - from) * (i / samples));
    }
    if (_reached > start) _finishStrokeIfDone();
  }

  void end() => _isTracing = false;

  void _advance(Point<double> finger) {
    final stroke = strokes[_stroke];
    while (_reached < stroke.length - 1 && finger.distanceTo(stroke[_reached + 1]) <= _reach) {
      _reached++;
    }
  }

  void _finishStrokeIfDone() {
    if (_reached < strokes[_stroke].length - 1) return;
    _stroke++;
    _reached = 0;
    _isTracing = false;
  }
}
