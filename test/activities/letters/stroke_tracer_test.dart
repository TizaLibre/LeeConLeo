import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/activities/letters/stroke_tracer.dart';

void main() {
  final line = [for (var y = 0; y <= 100; y += 5) Point(0.0, y.toDouble())];
  final loop = [
    for (var degrees = 90; degrees <= 450; degrees += 10)
      Point(50 * cos(degrees * pi / 180), -50 * sin(degrees * pi / 180)),
  ];

  StrokeTracer tracer(List<List<Point<double>>> strokes) =>
      StrokeTracer(strokes: strokes, tolerance: 8);

  void follow(StrokeTracer tracer, List<Point<double>> stroke) {
    tracer.start(stroke.first);
    for (final point in stroke.skip(1)) {
      tracer.move(point + const Point(3.0, 0.0));
    }
    tracer.end();
  }

  test('following the strokes in order completes the letter', () {
    final letter = tracer([line, loop]);

    follow(letter, line);
    expect(letter.currentStroke, 1);
    follow(letter, loop);

    expect(letter.isComplete, isTrue);
  });

  test('a stroke must start at its start point', () {
    final letter = tracer([line]);

    letter.start(line.last);
    for (final point in line.reversed) {
      letter.move(point);
    }

    expect(letter.reached, 0);
    expect(letter.isComplete, isFalse);
  });

  test('a closed loop cannot be finished by staying at the start', () {
    final letter = tracer([loop]);

    letter.start(loop.first);
    letter.move(loop.last);

    expect(letter.isComplete, isFalse);
  });

  test('wandering away pauses the trace until the finger comes back to the tip', () {
    final letter = tracer([line]);
    letter.start(line.first);
    letter.move(line[2]);
    final reached = letter.reached;
    letter.move(const Point(60.0, 50.0));
    letter.move(const Point(60.0, 90.0));
    expect(letter.reached, reached);

    letter.move(line[reached]);
    letter.move(line.last);
    expect(letter.isComplete, isTrue);
  });

  test('jumping ahead along the line does not skip the part in between', () {
    final letter = tracer([line]);
    letter.start(line.first);
    letter.move(const Point(30.0, 0.0));
    letter.move(const Point(30.0, 80.0));
    letter.move(line[16]);

    expect(letter.reached, lessThan(3));
  });

  test('a short bar traced out and back cannot be skipped at its start', () {
    const bar = [
      Point(0.0, 0.0),
      Point(5.0, 0.0),
      Point(10.0, 0.0),
      Point(5.0, 3.0),
      Point(0.0, 3.0),
    ];
    final letter = tracer([bar]);

    letter.start(bar.first);
    letter.move(bar.first);
    expect(letter.isComplete, isFalse);

    for (final point in bar) {
      letter.move(point);
    }
    expect(letter.isComplete, isTrue);
  });

  test('cutting across a small loop does not skip it', () {
    final small = [
      for (var degrees = 0; degrees <= 360; degrees += 20)
        Point(10 * cos(degrees * pi / 180), 10 * sin(degrees * pi / 180)),
    ];
    final letter = tracer([small]);

    letter.start(small.first);
    letter.move(small[small.length ~/ 2]);
    letter.move(small.last);

    expect(letter.isComplete, isFalse);
  });

  test('a finger a little off the line still traces it', () {
    final letter = tracer([line]);

    letter.start(line.first);
    for (final point in line) {
      letter.move(point + const Point(5.0, 0.0));
    }

    expect(letter.isComplete, isTrue);
  });

  test('a fast swipe along the line still counts every part it passes', () {
    final letter = tracer([line]);

    letter.start(line.first);
    letter.move(line[10]);
    letter.move(line.last);

    expect(letter.isComplete, isTrue);
  });

  test('lifting the finger keeps the progress, to continue from there', () {
    final letter = tracer([line]);

    letter.start(line.first);
    letter.move(line[10]);
    letter.end();
    expect(letter.reached, greaterThanOrEqualTo(10));

    letter.start(letter.tip!);
    letter.move(line.last);
    expect(letter.isComplete, isTrue);
  });

  test('a dot is traced with a single touch', () {
    final letter = tracer([
      [const Point(0.0, -40.0)],
    ]);

    letter.start(const Point(4.0, -38.0));

    expect(letter.isComplete, isTrue);
  });
}
