import 'buildable_words.dart';
import 'models/content_bundle.dart';
import 'models/path_step.dart';
import 'models/word.dart';
import 'sound_position.dart';

abstract final class WritableWords {
  static List<Word> upTo(ContentBundle content, PathStep step) {
    final known = BuildableWords.knownSounds(content, step);
    return [
      for (final word in SoundPosition.pictured(content.words))
        if (BuildableWords.isSpelledAsSaid(word) && word.sounds.every(known.contains)) word,
    ];
  }
}
