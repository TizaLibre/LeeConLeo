import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class WordModel {
  WordModel(String word, this.area) : _painter = _layout(word, area) {
    origin = Offset(
      (area.width - _painter.width) / 2,
      (area.height - _painter.height) / 2 + area.height * baselineDrop,
    );
  }

  static const widthShare = 0.85;
  static const heightShare = 0.5;
  static const baselineDrop = 0.04;
  static const inkShare = 0.07;
  static const toleranceShare = 0.09;
  static const xHeightShare = 0.5;
  static const rasterScale = 0.5;

  final Size area;
  final TextPainter _painter;
  late final Offset origin;

  double get fontSize => _painter.text!.style!.fontSize!;

  double get inkWidth => fontSize * inkShare;

  double get tolerance => fontSize * toleranceShare;

  double get baseline =>
      origin.dy + _painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);

  double get xHeight => fontSize * xHeightShare;

  Rect get bounds => origin & _painter.size;

  void paint(Canvas canvas, Color color) {
    canvas.saveLayer(Offset.zero & area, Paint()..color = color);
    _painter.paint(canvas, origin);
    canvas.restore();
  }

  Future<List<Point<double>>> points() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(rasterScale);
    paint(canvas, Colors.black);
    final width = (area.width * rasterScale).ceil();
    final height = (area.height * rasterScale).ceil();
    final image = await recorder.endRecording().toImage(width, height);
    final bytes = await image.toByteData();
    image.dispose();
    if (bytes == null) return const [];
    return [
      for (var y = 0; y < height; y++)
        for (var x = 0; x < width; x++)
          if (bytes.getUint8((y * width + x) * 4 + 3) > 128)
            Point((x + 0.5) / rasterScale, (y + 0.5) / rasterScale),
    ];
  }

  static TextPainter _layout(String word, Size area) {
    final probe = TextPainter(
      text: TextSpan(text: word, style: _style(100, Colors.black)),
      textDirection: TextDirection.ltr,
    )..layout();
    final fontSize =
        100 *
        min<double>(
          area.width * widthShare / probe.width,
          area.height * heightShare / probe.height,
        );
    probe.dispose();
    return TextPainter(
      text: TextSpan(text: word, style: _style(fontSize, Colors.black)),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static TextStyle _style(double fontSize, Color color) =>
      TextStyle(fontFamily: AppTheme.letterFont, fontSize: fontSize, color: color, height: 1);
}
