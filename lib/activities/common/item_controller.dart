import '../../core/content/models/spoken_line.dart';

abstract interface class ItemController {
  Stream<SpokenLine> get linesSpoken;

  bool get isHintActive;

  bool get hasMistake;

  bool get isSolved;

  bool get showsDemo;

  void answer(String value);
}
