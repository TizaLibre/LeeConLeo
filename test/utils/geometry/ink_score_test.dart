import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/utils/geometry/ink_score.dart';
import 'package:lee_con_leo/utils/geometry/resample_polyline.dart';

List<Point<double>> line(double x1, double y1, double x2, double y2) =>
    resamplePolyline([Point(x1, y1), Point(x2, y2)], 1);

void main() {
  final model = [...line(0, 0, 100, 0), ...line(100, 0, 100, 50)];

  test('ink over the whole model gets three stars', () {
    final ink = [...line(0, 3, 100, 3), ...line(103, 0, 103, 50)];
    final score = InkScore.of(model: model, ink: ink, tolerance: 6);

    expect(score.coverage, 1);
    expect(score.precision, 1);
    expect(score.stars, 3);
  });

  test('writing only half of the model loses coverage', () {
    final score = InkScore.of(model: model, ink: line(0, 0, 60, 0), tolerance: 6);

    expect(score.precision, 1);
    expect(score.coverage, closeTo(0.45, 0.05));
    expect(score.stars, lessThan(2));
  });

  test('scribbling all over the canvas loses precision', () {
    final ink = [...model, for (var y = 10.0; y <= 50; y += 10) ...line(0, y, 90, y)];
    final score = InkScore.of(model: model, ink: ink, tolerance: 6);

    expect(score.coverage, 1);
    expect(score.precision, lessThan(0.45));
    expect(score.stars, 0);
  });

  test('no ink scores nothing', () {
    expect(InkScore.of(model: model, ink: const [], tolerance: 6).stars, 0);
  });
}
