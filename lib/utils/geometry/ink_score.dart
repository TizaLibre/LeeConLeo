import 'dart:math';

class InkScore {
  const InkScore({required this.coverage, required this.precision});

  factory InkScore.of({
    required List<Point<double>> model,
    required List<Point<double>> ink,
    required double tolerance,
  }) {
    if (model.isEmpty || ink.isEmpty) return const InkScore(coverage: 0, precision: 0);
    final modelCells = _Cells(model, tolerance);
    final inkCells = _Cells(ink, tolerance);
    return InkScore(
      coverage: model.where(inkCells.hasNear).length / model.length,
      precision: ink.where(modelCells.hasNear).length / ink.length,
    );
  }

  static const starThresholds = [0.55, 0.75, 0.88];

  final double coverage;
  final double precision;

  double get value => min(coverage, precision);

  int get stars => starThresholds.where((threshold) => value >= threshold).length;
}

class _Cells {
  _Cells(List<Point<double>> points, this._tolerance) {
    for (final point in points) {
      (_cells[_key(_cell(point.x), _cell(point.y))] ??= []).add(point);
    }
  }

  final double _tolerance;
  final Map<int, List<Point<double>>> _cells = {};

  int _cell(double value) => (value / _tolerance).floor();

  int _key(int column, int row) => column * 100003 + row;

  bool hasNear(Point<double> point) {
    final column = _cell(point.x);
    final row = _cell(point.y);
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (final other in _cells[_key(column + dx, row + dy)] ?? const <Point<double>>[]) {
          if (other.distanceTo(point) <= _tolerance) return true;
        }
      }
    }
    return false;
  }
}
