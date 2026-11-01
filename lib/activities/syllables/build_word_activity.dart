import 'package:flutter/widgets.dart';

import '../../core/content/activity_ids.dart';
import '../../core/content/buildable_words.dart';
import '../../core/content/models/spoken_line.dart';
import '../../core/content/models/word.dart';
import '../../core/content/sound_clips.dart';
import '../../core/content/syllable_prompt_ids.dart';
import '../../utils/spanish/spanish_letters.dart';
import '../common/activity_context.dart';
import '../common/activity_item.dart';
import '../common/activity_spec.dart';
import '../common/item_controller.dart';
import 'build_word_view.dart';

class BuildWordItem extends ActivityItem {
  const BuildWordItem({
    required super.id,
    required super.target,
    required super.promptId,
    required super.options,
    required super.optionNames,
    required this.syllables,
    required this.image,
  });

  final List<String> syllables;
  final String image;
}

class BuildWordActivity implements ActivitySpec {
  const BuildWordActivity({this.rounds = 3, this.extraTiles = 2});

  final int rounds;
  final int extraTiles;

  @override
  String get id => ActivityIds.buildWord;

  @override
  List<ActivityItem> buildItems(ActivityContext context) {
    final random = context.random;
    final words = BuildableWords.of(context.content, context.step);
    if (words.isEmpty) return const [];
    final asked = <Word>[];
    while (asked.length < rounds) {
      asked.addAll([...words]..shuffle(random));
    }
    return [
      for (final (round, word) in asked.take(rounds).indexed)
        _item(
          round,
          word,
          [
            ...word.syllables,
            ...(context.step.sounds.where((sound) => !word.sounds.contains(sound)).toList()
                  ..shuffle(random))
                .take(extraTiles),
          ]..shuffle(random),
        ),
    ];
  }

  BuildWordItem _item(int round, Word word, List<String> tiles) => BuildWordItem(
    id: '$round-${word.text}',
    target: word.text,
    promptId: SyllablePromptIds.buildWord(word.text),
    options: tiles,
    optionNames: {
      word.text: SpokenLine(word.text, clip: word.audio),
      for (final tile in tiles)
        tile: SpokenLine(tile, clip: SoundClips.of(SpanishLetters.plain(tile))),
    },
    syllables: word.syllables,
    image: word.image!,
  );

  @override
  Widget buildItemView(ActivityItem item, ItemController controller) =>
      BuildWordView(item: item as BuildWordItem, controller: controller);
}
