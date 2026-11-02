import '../../utils/spanish/spanish_letters.dart';
import 'models/content_bundle.dart';
import 'models/path_step.dart';
import 'models/word.dart';
import 'sound_position.dart';

abstract final class BuildableWords {
  static Set<String> knownSounds(ContentBundle content, PathStep step) {
    final known = <String>{};
    for (final other in content.steps) {
      known.addAll(other.sounds);
      if (other.id == step.id) break;
    }
    return known;
  }

  static List<Word> of(ContentBundle content, PathStep step) {
    final known = knownSounds(content, step);
    return [
      for (final word in SoundPosition.pictured(content.words))
        if (isSpelledAsSaid(word) &&
            word.sounds.every(known.contains) &&
            word.sounds.any(step.sounds.contains))
          word,
    ];
  }

  static bool isSpelledAsSaid(Word word) =>
      word.syllables.length >= 2 &&
      word.syllables.map(SpanishLetters.plain).join('-') == word.sounds.join('-');
}
