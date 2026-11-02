import '../core/content/activity_ids.dart';

abstract final class GameIcons {
  static const _icons = {
    ActivityIds.upDown: 'steps/up_down.svg',
    ActivityIds.leftRight: 'steps/left_right.svg',
    ActivityIds.positions: 'steps/positions.svg',
    ActivityIds.clap: 'games/clap.svg',
    ActivityIds.sameSound: 'games/same_sound.svg',
    ActivityIds.meet: 'games/meet.svg',
    ActivityIds.trace: 'games/trace.svg',
    ActivityIds.find: 'games/find.svg',
    ActivityIds.syllableMeet: 'games/syllable_meet.svg',
    ActivityIds.syllableTrace: 'games/trace.svg',
    ActivityIds.syllableFind: 'games/find.svg',
    ActivityIds.startsWith: 'games/starts_with.svg',
    ActivityIds.endsWith: 'games/ends_with.svg',
    ActivityIds.contains: 'games/contains.svg',
    ActivityIds.blend: 'games/blend.svg',
    ActivityIds.buildWord: 'games/build_word.svg',
    ActivityIds.writeWord: 'games/write.svg',
  };

  static String? of(String activityId) => _icons[activityId];
}
