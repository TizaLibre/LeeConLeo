import 'dart:math';

abstract final class BeatFinder {
  static const frameSeconds = 0.01;
  static const silenceShare = 0.08;
  static const minGapSeconds = 0.08;
  static const minSyllableSeconds = 0.1;
  static const valleyRadius = 3;

  static List<double>? onsets(List<int> samples, {required int rate, required int count}) {
    final frame = (rate * frameSeconds).round();
    final levels = [
      for (var start = 0; start + frame <= samples.length; start += frame)
        sqrt(samples.sublist(start, start + frame).fold(0, (sum, s) => sum + s * s) / frame),
    ];
    if (levels.isEmpty) return null;
    final threshold = levels.reduce(max) * silenceShare;
    final voiced = [for (final level in levels) level > threshold];
    final first = voiced.indexOf(true);
    final last = voiced.lastIndexOf(true);
    if (first < 0) return null;
    final gaps = <({int start, int end})>[];
    for (var i = first; i <= last; i++) {
      if (voiced[i]) continue;
      final start = i;
      while (!voiced[i]) {
        i++;
      }
      gaps.add((start: start, end: i));
    }
    final minGap = (minGapSeconds / frameSeconds).round();
    final chosen =
        (gaps.where((gap) => gap.end - gap.start >= minGap).toList()
              ..sort((a, b) => (b.end - b.start).compareTo(a.end - a.start)))
            .take(count - 1)
            .toList();
    final boundaries = chosen.length == count - 1
        ? [for (final gap in chosen) gap.end]
        : _valleys(levels, first, last, count - 1);
    if (boundaries == null) return null;
    boundaries.sort();
    return [
      for (final frameIndex in [first, ...boundaries])
        double.parse((frameIndex * frameSeconds).toStringAsFixed(2)),
    ];
  }

  static List<int>? _valleys(List<double> levels, int first, int last, int count) {
    final margin = (minSyllableSeconds / frameSeconds).round();
    final candidates = [
      for (var i = first + margin; i <= last - margin; i++)
        if (_isLowest(levels, i)) i,
    ]..sort((a, b) => levels[a].compareTo(levels[b]));
    final chosen = <int>[];
    for (final candidate in candidates) {
      if (chosen.every((other) => (other - candidate).abs() >= margin)) chosen.add(candidate);
      if (chosen.length == count) return chosen;
    }
    return null;
  }

  static bool _isLowest(List<double> levels, int index) {
    for (
      var i = max(0, index - valleyRadius);
      i <= min(levels.length - 1, index + valleyRadius);
      i++
    ) {
      if (levels[i] < levels[index]) return false;
    }
    return true;
  }
}
