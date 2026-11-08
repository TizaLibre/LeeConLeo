// Writes content/syllables/*.yaml from the font: each syllable is rendered with its natural
// joins, thinned to a center line, and walked in writing order using the single letters in
// content/letters as a guide. A hand-drawn path in tool/syllables/guides/<text>.yaml replaces
// that guide; a single-letter guide rewrites the letter's lower case.
// Run: flutter test tool/syllables/trace_syllables_test.dart
// Optional: --dart-define=ONLY=ma,pa and --dart-define=PREVIEW=<folder> for overlay images.
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/core/content/models/content_bundle.dart';

const only = String.fromEnvironment('ONLY');
const preview = String.fromEnvironment('PREVIEW');
const fontSize = 420.0;
const unit = 5.0;
const margin = 100.0;
const guides = 'tool/syllables/guides';

typedef Pt = Point<double>;

class Glyphs {
  Glyphs(this.text) : painter = _painter(text);

  final String text;
  final TextPainter painter;

  int get width => (painter.width + 2 * margin).ceil();

  int get height => (painter.height + 2 * margin).ceil();

  Rect box(int index) => painter
      .getBoxesForSelection(TextSelection(baseOffset: index, extentOffset: index + 1))
      .first
      .toRect()
      .shift(const Offset(margin, margin));

  static TextPainter _painter(String text) => TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(fontFamily: 'PlaywriteCL', fontSize: fontSize, color: Colors.black),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
}

class Raster {
  Raster(this.w, this.h, this.ink);

  final int w;
  final int h;
  final List<bool> ink;

  bool at(int x, int y) => x >= 0 && y >= 0 && x < w && y < h && ink[y * w + x];

  bool atPoint(Pt p) => at(p.x.round(), p.y.round());

  static Future<Raster> of(Glyphs glyphs) async {
    final recorder = ui.PictureRecorder();
    glyphs.painter.paint(Canvas(recorder), const Offset(margin, margin));
    final image = await recorder.endRecording().toImage(glyphs.width, glyphs.height);
    final bytes = (await image.toByteData())!;
    final size = glyphs.width * glyphs.height;
    return Raster(glyphs.width, glyphs.height, [
      for (var i = 0; i < size; i++) bytes.getUint8(i * 4 + 3) > 128,
    ]);
  }

  Raster thinned() {
    final img = [...ink];
    bool p(int x, int y) => img[y * w + x];
    var changed = true;
    while (changed) {
      changed = false;
      for (final pass in [0, 1]) {
        final remove = <int>[];
        for (var y = 1; y < h - 1; y++) {
          for (var x = 1; x < w - 1; x++) {
            if (!img[y * w + x]) continue;
            final n = [
              p(x, y - 1),
              p(x + 1, y - 1),
              p(x + 1, y),
              p(x + 1, y + 1),
              p(x, y + 1),
              p(x - 1, y + 1),
              p(x - 1, y),
              p(x - 1, y - 1),
            ];
            final count = n.where((v) => v).length;
            if (count < 2 || count > 6) continue;
            var turns = 0;
            for (var i = 0; i < 8; i++) {
              if (!n[i] && n[(i + 1) % 8]) turns++;
            }
            if (turns != 1) continue;
            final keep = pass == 0
                ? (n[0] && n[2] && n[4]) || (n[2] && n[4] && n[6])
                : (n[0] && n[2] && n[6]) || (n[0] && n[4] && n[6]);
            if (!keep) remove.add(y * w + x);
          }
        }
        for (final i in remove) {
          img[i] = false;
        }
        changed = changed || remove.isNotEmpty;
      }
    }
    return Raster(w, h, img);
  }

  List<Pt> points() => [
    for (var y = 0; y < h; y++)
      for (var x = 0; x < w; x++)
        if (ink[y * w + x]) Point(x.toDouble(), y.toDouble()),
  ];

  List<List<Pt>> components() {
    final label = List<int>.filled(w * h, -1);
    final result = <List<Pt>>[];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (!at(x, y) || label[y * w + x] >= 0) continue;
        final points = <Pt>[];
        final stack = [y * w + x];
        label[y * w + x] = result.length;
        while (stack.isNotEmpty) {
          final i = stack.removeLast();
          final px = i % w, py = i ~/ w;
          points.add(Point(px.toDouble(), py.toDouble()));
          for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
              if (!at(px + dx, py + dy) || label[(py + dy) * w + px + dx] >= 0) continue;
              label[(py + dy) * w + px + dx] = result.length;
              stack.add((py + dy) * w + px + dx);
            }
          }
        }
        result.add(points);
      }
    }
    return result;
  }
}

class Skeleton {
  Skeleton(this.raster) : pixels = raster.points();

  final Raster raster;
  final List<Pt> pixels;

  Iterable<Pt> neighbours(Pt p) sync* {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final q = Point(p.x + dx, p.y + dy);
        if ((dx != 0 || dy != 0) && raster.atPoint(q)) yield q;
      }
    }
  }

  Pt nearest(Pt q) => pixels.reduce((a, b) => a.distanceTo(q) <= b.distanceTo(q) ? a : b);

  List<Pt> route(Pt from, Pt to) {
    final start = nearest(from), goal = nearest(to);
    final parent = <Pt, Pt>{};
    final queue = Queue.of([start]);
    final seen = {start};
    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      if (p == goal) break;
      for (final q in neighbours(p)) {
        if (seen.add(q)) {
          parent[q] = p;
          queue.add(q);
        }
      }
    }
    final path = [goal];
    while (parent[path.last] != null) {
      path.add(parent[path.last]!);
    }
    return path.reversed.toList();
  }

  List<Pt> follow(List<Pt> guide) {
    if (guide.length == 1) return [nearest(guide.single)];
    final index = {for (final (i, p) in pixels.indexed) p: i};
    final links = [
      for (final p in pixels) [for (final q in neighbours(p)) index[q]!],
    ];
    final k = guide.length;
    double distance(int pixel, int g) => pixels[pixel].distanceTo(guide[g]);
    final cost = <int, double>{};
    final parent = <int, int>{};
    final queue = SplayTreeMap<double, List<int>>();
    void push(int state, double c, int? from) {
      if (c >= (cost[state] ?? double.infinity)) return;
      cost[state] = c;
      if (from != null) parent[state] = from;
      (queue[c] ??= []).add(state);
    }

    final start = index[nearest(guide.first)]!;
    final goal = index[nearest(guide.last)]!;
    push(start * k, distance(start, 0), null);
    int? done;
    while (queue.isNotEmpty) {
      final c = queue.firstKey()!;
      final bucket = queue[c]!;
      final state = bucket.removeLast();
      if (bucket.isEmpty) queue.remove(c);
      if (c > cost[state]!) continue;
      final pixel = state ~/ k, g = state % k;
      if (g == k - 1 && pixel == goal) {
        done = state;
        break;
      }
      if (g < k - 1) push(pixel * k + g + 1, c + distance(pixel, g + 1), state);
      for (final next in links[pixel]) {
        push(next * k + g, c + distance(next, g) + 1, state);
        if (g < k - 1) push(next * k + g + 1, c + distance(next, g + 1) + 1, state);
      }
    }
    final states = [done!];
    while (parent[states.last] != null) {
      states.add(parent[states.last]!);
    }
    final path = <Pt>[];
    for (final state in states.reversed) {
      final p = pixels[state ~/ k];
      if (path.isEmpty || path.last != p) path.add(p);
    }
    return path;
  }

  List<Pt> throughCrossings(List<Pt> path, {double radius = 18, Rect? within}) {
    final centres = <Pt>[];
    for (final p in pixels.where(
      (p) => neighbours(p).length >= 3 && (within?.contains(Offset(p.x, p.y)) ?? true),
    )) {
      if (centres.every((c) => c.distanceTo(p) > radius / 2)) centres.add(p);
    }
    var result = path;
    for (final c in centres) {
      final next = <Pt>[];
      var i = 0;
      while (i < result.length) {
        if (result[i].distanceTo(c) >= radius) {
          next.add(result[i++]);
          continue;
        }
        final start = i;
        while (i < result.length && result[i].distanceTo(c) < radius) {
          i++;
        }
        final run = result.sublist(start, i);
        next.addAll(
          run.first.distanceTo(run.last) > radius * 1.5 ? densify([run.first, run.last], 2) : run,
        );
      }
      result = next;
    }
    return result;
  }

  List<List<Pt>> withTips(List<List<Pt>> strokes, {List<List<Pt>> marks = const []}) {
    final paths = [
      for (final s in strokes) [...s],
    ];
    bool covered(Pt q) => paths.any((path) => path.any((m) => m.distanceTo(q) < 6));
    bool marked(Pt q) => marks.any((mark) => densify(mark, 4).any((m) => m.distanceTo(q) < 12));
    final tips = pixels.where((p) => neighbours(p).length == 1).toList();
    for (final tip in tips) {
      if (covered(tip) || marked(tip)) continue;
      final parent = <Pt, Pt>{};
      final queue = Queue.of([tip]);
      final seen = {tip};
      Pt? base;
      while (queue.isNotEmpty && base == null) {
        final p = queue.removeFirst();
        for (final q in neighbours(p)) {
          if (!seen.add(q)) continue;
          parent[q] = p;
          if (covered(q)) {
            base = q;
            break;
          }
          queue.add(q);
        }
      }
      if (base == null) continue;
      final branch = [base];
      while (parent[branch.last] != null) {
        branch.add(parent[branch.last]!);
      }
      if (branch.length > 120) continue;
      var best = (path: paths.first, at: 0);
      for (final path in paths) {
        for (var i = 0; i < path.length; i++) {
          if (path[i].distanceTo(base) < best.path[best.at].distanceTo(base)) {
            best = (path: path, at: i);
          }
        }
      }
      best.path.insertAll(best.at + 1, [...branch, ...branch.reversed.skip(1)]);
    }
    return paths;
  }

  List<Pt> branchBefore(List<Pt> stroke) {
    final start = stroke.first;
    bool covered(Pt q) => stroke.any((m) => m.distanceTo(q) < 8);
    final parent = <Pt, Pt>{};
    final queue = Queue.of([start]);
    final seen = {start};
    Pt? tip;
    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      final around = neighbours(p).toList();
      for (final q in around) {
        if (covered(q) && q.distanceTo(start) > 8) continue;
        if (seen.add(q)) {
          parent[q] = p;
          queue.add(q);
        }
      }
      if (around.length == 1 && p != start && p.distanceTo(start) > 20) tip = p;
    }
    if (tip == null) return const [];
    final path = [tip];
    while (parent[path.last] != null && parent[path.last] != start) {
      path.add(parent[path.last]!);
    }
    return path;
  }
}

List<Pt> densify(List<Pt> points, double step) {
  if (points.length < 2) return points;
  final result = [points.first];
  for (var i = 1; i < points.length; i++) {
    final a = points[i - 1], b = points[i];
    final n = max(1, (a.distanceTo(b) / step).ceil());
    for (var s = 1; s <= n; s++) {
      result.add(a + (b - a) * (s / n));
    }
  }
  return result;
}

List<Pt> simplify(List<Pt> points, double tolerance) {
  if (points.length < 3) return points;
  double offLine(Pt p, Pt a, Pt b) {
    final ab = b - a;
    final length = ab.magnitude;
    if (length == 0) return p.distanceTo(a);
    final t = (((p.x - a.x) * ab.x + (p.y - a.y) * ab.y) / (length * length)).clamp(0.0, 1.0);
    return p.distanceTo(a + ab * t);
  }

  var farthest = 0;
  var distance = 0.0;
  for (var i = 1; i < points.length - 1; i++) {
    final d = offLine(points[i], points.first, points.last);
    if (d > distance) {
      distance = d;
      farthest = i;
    }
  }
  if (distance <= tolerance) return [points.first, points.last];
  final left = simplify(points.sublist(0, farthest + 1), tolerance);
  return [...left.sublist(0, left.length - 1), ...simplify(points.sublist(farthest), tolerance)];
}

Pt fit(Raster ink, List<Pt> template, Pt guess) {
  int score(Pt offset) => template.where((p) => ink.atPoint(p + offset)).length;
  var best = guess;
  var bestScore = score(guess);
  for (final (range, step) in [(90, 5), (6, 1)]) {
    final centre = best;
    for (var dx = -range; dx <= range; dx += step) {
      for (var dy = -range; dy <= range; dy += step) {
        final offset = Point(centre.x + dx, centre.y + dy);
        final s = score(offset);
        if (s > bestScore) {
          bestScore = s;
          best = offset;
        }
      }
    }
  }
  return best;
}

Pt centre(List<Pt> points) => Point(
  points.map((p) => p.x).reduce((a, b) => a + b) / points.length,
  points.map((p) => p.y).reduce((a, b) => a + b) / points.length,
);

Future<List<List<Pt>>> trace(String syllable, ContentBundle bundle) async {
  final glyphs = Glyphs(syllable);
  final ink = await Raster.of(glyphs);
  final skeleton = Skeleton(ink.thinned());
  final letters = [
    for (var i = 0; i < syllable.length; i++)
      () {
        final template = [
          for (final stroke in bundle.letters[syllable[i]]!.lower)
            [for (final p in stroke) Point(p.x * unit, p.y * unit)],
        ];
        final all = densify(template.expand((s) => s).toList(), 4);
        final box = glyphs.box(i).center;
        final offset = fit(ink, all, Point(box.dx, box.dy) - centre(all));
        return [
          for (final s in template) [for (final p in s) p + offset],
        ];
      }(),
  ];
  final guide = <Pt>[];
  for (final letter in letters) {
    final stroke = densify(letter.first, 4);
    if (guide.isNotEmpty) guide.addAll(skeleton.route(guide.last, stroke.first).skip(4));
    guide.addAll(stroke);
  }
  final extras = [for (final letter in letters) ...letter.skip(1)];
  final main = skeleton.follow(guide);
  main.insertAll(0, skeleton.branchBefore(main));
  main.addAll(skeleton.branchBefore(main.reversed.toList()).reversed);
  final traced = [
    for (final piece in skeleton.withTips([main], marks: extras)) skeleton.throughCrossings(piece),
  ];
  final marks = ink.components().where(
    (c) => !c.any((p) => traced.any((path) => path.any((w) => w.distanceTo(p) < 3))),
  );
  List<Pt> mark(List<Pt> extra) {
    if (extra.length == 1 && marks.isNotEmpty) {
      return [
        marks
            .map(centre)
            .reduce((a, b) => a.distanceTo(extra.single) <= b.distanceTo(extra.single) ? a : b),
      ];
    }
    return simplify(skeleton.follow(densify(extra, 4)), 2.5);
  }

  return [simplify(traced.single, 2.5), for (final extra in extras) mark(extra)];
}

List<List<Pt>> readStrokes(String text) => [
  for (final line in text.split('\n').where((l) => l.trim().startsWith('- ')))
    [
      for (final m in RegExp(r'\[(-?\d+), (-?\d+)\]').allMatches(line))
        Point(double.parse(m[1]!) * unit, double.parse(m[2]!) * unit),
    ],
];

Future<({List<List<Pt>> strokes, Pt offset})> snap(String text, List<List<Pt>> guide) async {
  final glyphs = Glyphs(text);
  final ink = await Raster.of(glyphs);
  final skeleton = Skeleton(ink.thinned());
  final all = densify(guide.expand((s) => s).toList(), 4);
  final box = glyphs.box(0).expandToInclude(glyphs.box(text.length - 1)).center;
  final offset = fit(ink, all, Point(box.dx, box.dy) - centre(all));
  final placed = [
    for (final s in guide) [for (final p in s) p + offset],
  ];
  final first = glyphs.box(0);
  final lines = {
    for (final s in placed.where((s) => s.length > 1))
      s: () {
        final top = Rect.fromLTWH(first.left, first.top, first.width, first.height * 0.4);
        final crossed = skeleton.throughCrossings(
          reachCusps(skeleton.throughCrossings(skeleton.follow(densify(s, 4))), ink),
          radius: 32,
          within: first.deflate(first.width / 4),
        );
        return smoothWithin(
          recentreWithin(smoothWithin(crossed, top), ink, top),
          top,
          reach: 4,
          passes: 1,
        );
      }(),
  };
  final marks = ink
      .components()
      .where((c) => !c.any((p) => lines.values.any((l) => l.any((w) => w.distanceTo(p) < 3))))
      .map(centre)
      .toList();
  Pt nearestMark(Pt p) => marks.reduce((a, b) => a.distanceTo(p) <= b.distanceTo(p) ? a : b);
  return (
    strokes: [
      for (final s in placed) s.length > 1 ? simplify(lines[s]!, 2.5) : [nearestMark(s.single)],
    ],
    offset: offset,
  );
}

List<Pt> reachCusps(List<Pt> path, Raster ink) {
  const back = 6;
  final result = <Pt>[];
  for (var i = 0; i < path.length; i++) {
    result.add(path[i]);
    final isCusp =
        i >= back &&
        i + back < path.length &&
        [for (var j = 1; j <= 3; j++) path[i - j] == path[i + j]].every((same) => same);
    if (!isCusp) continue;
    final along = path[i] - path[i - back];
    final d = along * (1 / along.magnitude);
    final across = Point(-d.y, d.x);
    final from = path[i - back];
    final half = (inkRun(ink, from, across) + inkRun(ink, from, across * -1.0)) / 2;
    final reach = inkRun(ink, path[i], d) - half;
    if (reach < 2) continue;
    final tip = path[i] + d * reach;
    result.addAll([
      ...densify([path[i], tip], 2).skip(1),
      ...densify([tip, path[i]], 2).skip(1),
    ]);
  }
  return result;
}

double inkRun(Raster ink, Pt from, Pt step) {
  var t = 0.0;
  while (ink.atPoint(from + step * (t + 1))) {
    t++;
  }
  return t;
}

List<Pt> recentreWithin(List<Pt> path, Raster ink, Rect area) => [
  for (var i = 0; i < path.length; i++)
    () {
      final p = path[i];
      if (i < 3 || i >= path.length - 3 || !area.contains(Offset(p.x, p.y))) return p;
      final t = path[i + 3] - path[i - 3];
      final n = Point(-t.y, t.x) * (1 / t.magnitude);
      var q = p;
      if (!ink.atPoint(q)) {
        final hit = [
          for (var k = 1; k <= 25; k++) ...[p + n * k.toDouble(), p - n * k.toDouble()],
        ].where(ink.atPoint);
        if (hit.isEmpty) return p;
        q = hit.first;
      }
      return q + n * ((inkRun(ink, q, n) - inkRun(ink, q, n * -1.0)) / 2);
    }(),
];

List<Pt> smoothWithin(List<Pt> path, Rect area, {int reach = 12, int passes = 3}) {
  var result = densify(path, 2);
  bool fixed(int i) =>
      i < reach || i >= result.length - reach || !area.contains(Offset(result[i].x, result[i].y));
  for (var pass = 0; pass < passes; pass++) {
    result = [
      for (var i = 0; i < result.length; i++)
        fixed(i) ? result[i] : centre(result.sublist(i - reach, i + reach + 1)),
    ];
  }
  return result;
}

void writeLetter(String letter, List<List<Pt>> lower, Pt offset) {
  final file = File('content/letters/$letter.yaml');
  final upper = file.readAsStringSync().split('upper:')[1];
  final lines = [
    for (final stroke in lower)
      '  - [${[for (final p in stroke) '[${((p.x - offset.x) / unit).round()}, ${((p.y - offset.y) / unit).round()}]'].join(', ')}]',
  ];
  file.writeAsStringSync('lower:\n${lines.join('\n')}\nupper:$upper');
}

String yaml(List<List<Pt>> strokes) {
  final all = strokes.expand((s) => s);
  final left = all.map((p) => p.x).reduce(min);
  final top = all.map((p) => p.y).reduce(min);
  final lines = [
    for (final stroke in strokes)
      [
        for (final p in stroke)
          [((p.x - left) / unit + 20).round(), ((p.y - top) / unit + 20).round()],
      ].fold(
        <List<int>>[],
        (kept, p) =>
            kept.isNotEmpty && kept.last[0] == p[0] && kept.last[1] == p[1] ? kept : [...kept, p],
      ),
  ];
  return 'strokes:\n${[for (final l in lines) '  - ${jsonEncode(l).replaceAll(',', ', ').replaceAll('],  [', '], [')}'].join('\n')}\n';
}

Future<void> writePreview(String syllable, List<List<Pt>> strokes) async {
  final glyphs = Glyphs(syllable);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(
      Rect.fromLTWH(0, 0, glyphs.width.toDouble(), glyphs.height.toDouble()),
      Paint()..color = Colors.white,
    );
  TextPainter(
      text: TextSpan(
        text: syllable,
        style: const TextStyle(
          fontFamily: 'PlaywriteCL',
          fontSize: fontSize,
          color: Color(0xFFBBBBBB),
        ),
      ),
      textDirection: TextDirection.ltr,
    )
    ..layout()
    ..paint(canvas, const Offset(margin, margin));
  final line = Paint()
    ..color = const Color(0xFFDD2828)
    ..strokeWidth = 7
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  for (final stroke in strokes) {
    if (stroke.length > 1) {
      canvas.drawPath(Path()..addPolygon([for (final p in stroke) Offset(p.x, p.y)], false), line);
    }
    canvas.drawCircle(
      Offset(stroke.first.x, stroke.first.y),
      12,
      Paint()..color = const Color(0xFF28A028),
    );
  }
  final image = await recorder.endRecording().toImage(glyphs.width, glyphs.height);
  final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  File('$preview/$syllable.png').writeAsBytesSync(png.buffer.asUint8List());
}

void main() {
  testWidgets('trace the joined syllables from the font', (tester) async {
    await tester.runAsync(() async {
      await (FontLoader(
        'PlaywriteCL',
      )..addFont(rootBundle.load('assets/fonts/PlaywriteCL.ttf'))).load();
      final bundle = ContentBundle.fromJson(
        jsonDecode(File('assets/content/bundle.json').readAsStringSync()) as Map<String, dynamic>,
      );
      bool wanted(String text) => only.isEmpty || only.split(',').contains(text);
      Future<({List<List<Pt>> strokes, Pt offset})?> guided(String text) async {
        final file = File('$guides/$text.yaml');
        return file.existsSync() ? snap(text, readStrokes(file.readAsStringSync())) : null;
      }

      for (final letter in bundle.letters.keys.where(wanted)) {
        final snapped = await guided(letter);
        if (snapped == null) continue;
        writeLetter(letter, snapped.strokes, snapped.offset);
        if (preview.isNotEmpty) await writePreview(letter, snapped.strokes);
      }
      for (final syllable in bundle.syllables.keys.where(wanted)) {
        final strokes = (await guided(syllable))?.strokes ?? await trace(syllable, bundle);
        File('content/syllables/$syllable.yaml').writeAsStringSync(yaml(strokes));
        if (preview.isNotEmpty) await writePreview(syllable, strokes);
      }
    });
  }, timeout: const Timeout(Duration(minutes: 20)));
}
