import 'activity_ids.dart';
import 'models/word.dart';
import 'sound_position.dart';

enum PictureSoundGame {
  startsWith(ActivityIds.startsWith, SoundPosition.start, showsSound: true),
  endsWith(ActivityIds.endsWith, SoundPosition.end, showsSound: true),
  contains(ActivityIds.contains, SoundPosition.inside, showsSound: true),
  sameSound(ActivityIds.sameSound, SoundPosition.start, showsSound: false);

  const PictureSoundGame(this.activityId, this.position, {required this.showsSound});

  final String activityId;
  final SoundPosition position;
  final bool showsSound;

  bool matches(Word word, String sound) =>
      position.matches(word, sound) && position.isSpelled(word, sound);

  bool resembles(Word word, String sound) =>
      position.matches(word, sound) || position.isSpelled(word, sound);

  String promptId(String sound) => position.promptId(sound);
}
