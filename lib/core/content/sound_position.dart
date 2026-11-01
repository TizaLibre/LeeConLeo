import '../../utils/spanish/spanish_letters.dart';
import 'models/word.dart';
import 'sound_prompt_ids.dart';

enum SoundPosition {
  start('starts'),
  end('ends'),
  inside('contains');

  const SoundPosition(this.label);

  final String label;

  bool matches(Word word, String sound) => switch (this) {
    start => word.startsWithSound(sound),
    end => word.endsWithSound(sound),
    inside => word.sounds.contains(sound),
  };

  bool isSpelled(Word word, String sound) {
    final written = [for (final syllable in word.syllables) SpanishLetters.plain(syllable)];
    if (written.isEmpty) return false;
    return switch (this) {
      start => written.first.startsWith(sound),
      end => written.last == sound,
      inside => written.contains(sound),
    };
  }

  String promptId(String sound) => switch (this) {
    start => SoundPromptIds.startsWith(sound),
    end => SoundPromptIds.endsWith(sound),
    inside => SoundPromptIds.contains(sound),
  };

  static List<Word> pictured(Iterable<Word> words) =>
      words.where((word) => word.image != null).toList();
}
