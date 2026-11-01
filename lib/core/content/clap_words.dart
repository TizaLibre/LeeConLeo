import 'models/word.dart';
import 'sound_position.dart';

abstract final class ClapWords {
  static const maxSyllables = 4;

  static List<Word> all(Iterable<Word> words) => [
    for (final word in SoundPosition.pictured(words))
      if (word.audio != null &&
          word.syllables.isNotEmpty &&
          word.syllables.length <= maxSyllables &&
          !_hasSoftRSplit(word))
        word,
  ];

  static bool _hasSoftRSplit(Word word) => word.syllables
      .skip(1)
      .any((syllable) => syllable.startsWith('r') && !syllable.startsWith('rr'));
}
