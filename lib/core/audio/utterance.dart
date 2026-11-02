import '../content/models/spoken_line.dart';

class Utterance {
  const Utterance(this.lines, {this.onLine});

  Utterance.text(String text) : lines = [SpokenLine(text)], onLine = null;

  final List<SpokenLine> lines;
  final void Function(SpokenLine line)? onLine;

  String get text => [
    for (final line in lines)
      if (line.text.isNotEmpty) line.text,
  ].join(' ');

  bool get isEmpty => text.isEmpty;

  bool get hasAllClips => lines.isNotEmpty && lines.every((line) => line.clip != null);
}
