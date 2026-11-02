import 'spanish_letters.dart';

class SoundKeyEncoder {
  const SoundKeyEncoder();

  static const _digraphSounds = {'ch': 'ch', 'll': 'y', 'rr': 'rr', 'qu': 'k'};
  static const _strongRAfter = {'', 'n', 'l', 's'};

  List<String> encodeAll(List<String> syllables) => [
    for (var i = 0; i < syllables.length; i++)
      encode(syllables[i], previousLetter: i == 0 ? '' : _lastLetter(syllables[i - 1])),
  ];

  String encode(String syllable, {String previousLetter = ''}) {
    final lower = syllable.toLowerCase();
    String letterAt(int i) => i < lower.length ? lower[i] : '';
    final sound = StringBuffer();
    var i = 0;
    while (i < lower.length) {
      final letter = letterAt(i);
      final next = letterAt(i + 1);
      final digraph = _digraphSounds[letter + next];
      if (digraph != null) {
        sound.write(digraph);
        i += 2;
      } else if (i == 0 &&
          letter == 'h' &&
          next == 'i' &&
          SpanishLetters.isVowel(letterAt(i + 2))) {
        sound.write('y');
        i += 2;
      } else if (letter == 'g' && next == 'u' && SpanishLetters.isFrontVowel(letterAt(i + 2))) {
        sound.write('g');
        i += 2;
      } else {
        final isSyllableStart = i == 0;
        sound.write(_letterSound(letter, next, isSyllableStart, previousLetter));
        i++;
      }
    }
    return sound.toString();
  }

  String _letterSound(String letter, String next, bool isSyllableStart, String previousLetter) {
    return switch (letter) {
      'c' => SpanishLetters.isFrontVowel(next) ? 's' : 'k',
      'g' => SpanishLetters.isFrontVowel(next) ? 'j' : 'g',
      'z' => 's',
      'v' => 'b',
      'h' => '',
      'x' => 'ks',
      'y' => SpanishLetters.isVowel(next) ? 'y' : 'i',
      'r' when isSyllableStart && _strongRAfter.contains(previousLetter) => 'rr',
      _ => SpanishLetters.withoutAccent(letter),
    };
  }

  String _lastLetter(String syllable) =>
      syllable.isEmpty ? '' : syllable[syllable.length - 1].toLowerCase();
}
